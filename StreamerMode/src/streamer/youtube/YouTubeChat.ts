import { logger } from "../../utils/logger.ts";
import {
  fetchLiveChatPage,
  YouTubeApiError,
  type YouTubeAuth,
  type YouTubeLiveChatMessage,
} from "./api.ts";
import { openStreamListConnection } from "./grpcStream.ts";

const STREAM_BACKOFF_MS = [1000, 2000, 4000, 8000] as const;

const MIN_DELAY_MS = 1500;
const MAX_DELAY_MS = 60_000;
const SEEN_CACHE_SIZE = 1000;

export interface YouTubeChatStopInfo {
  reason: "stopped" | "offline" | "ended" | "fatal";
  userMessage: string | null;
}

export interface YouTubeChatParams {
  coloredName: string;
  liveChatId: string;
  getAuth: () => Promise<YouTubeAuth>;
  /** When true, skip gRPC streamList entirely and use REST polling. */
  getPollingOnly: () => boolean;
  onMessage: (msg: YouTubeLiveChatMessage) => void;
  onConnect: () => void;
  onStop: (info: YouTubeChatStopInfo) => void;
}

class RecentMessageCache {
  private readonly ids = new Set<string>();
  private readonly queue: string[] = [];
  constructor(private readonly maxSize: number) {}
  has(id: string): boolean {
    return this.ids.has(id);
  }
  add(id: string): void {
    if (this.ids.has(id)) return;
    this.ids.add(id);
    this.queue.push(id);
    while (this.queue.length > this.maxSize) {
      const removed = this.queue.shift();
      if (removed) this.ids.delete(removed);
    }
  }
}

export class YouTubeChat {
  private readonly p: YouTubeChatParams;
  private aborted = false;
  private connectedFired = false;
  private pollStartedAtMs = 0;
  private firstPollPage = true;
  private pageToken: string | null = null;
  private currentDelayMs = 5000;
  private loopPromise: Promise<void> | null = null;
  private readonly seen = new RecentMessageCache(SEEN_CACHE_SIZE);
  private streamAbort: AbortController | null = null;

  constructor(params: YouTubeChatParams) {
    this.p = params;
  }

  start(): void {
    if (this.loopPromise) return;
    this.aborted = false;
    this.connectedFired = false;
    this.firstPollPage = true;
    this.pollStartedAtMs = Date.now();
    this.loopPromise = this.runLoop();
  }

  stop(): void {
    this.aborted = true;
    this.streamAbort?.abort();
  }

  isRunning(): boolean {
    return this.loopPromise !== null && !this.aborted;
  }

  private async runLoop(): Promise<void> {
    try {
      const streamed = await this.tryStreaming();
      if (this.aborted) {
        this.p.onStop({ reason: "stopped", userMessage: null });
        return;
      }
      if (streamed.outcome === "offline") {
        this.p.onStop({
          reason: "offline",
          userMessage: "Stream is offline.",
        });
        return;
      }
      if (streamed.outcome === "ended") {
        this.p.onStop({
          reason: "ended",
          userMessage: "This live chat has ended.",
        });
        return;
      }
      // streamed.outcome === "fallback": continue into polling.
      await this.runPolling();
    } catch (err) {
      if (this.aborted) {
        this.p.onStop({ reason: "stopped", userMessage: null });
        return;
      }
      if (err instanceof YouTubeApiError) {
        if (err.reason === "liveChatEnded") {
          this.p.onStop({ reason: "ended", userMessage: err.userMessage });
        } else {
          this.p.onStop({ reason: "fatal", userMessage: err.userMessage });
        }
        logger.warn(
          `${this.p.coloredName} Chat stopped: ${err.userMessage}`,
        );
      } else {
        const msg = err instanceof Error ? err.message : String(err);
        logger.error(`${this.p.coloredName} Chat fatal: ${msg}`);
        this.p.onStop({ reason: "fatal", userMessage: msg });
      }
    } finally {
      this.loopPromise = null;
    }
  }

  private async tryStreaming(): Promise<{
    outcome: "offline" | "ended" | "fallback";
  }> {
    if (this.p.getPollingOnly()) {
      logger.info(
        `${this.p.coloredName} youtube_chat_polling_only=true; skipping gRPC, using polling`,
      );
      return { outcome: "fallback" };
    }
    const abort = new AbortController();
    this.streamAbort = abort;
    if (this.aborted) abort.abort();

    let everSawChunk = false;
    let transientAttempts = 0;

    try {
      while (!this.aborted) {
        let auth: YouTubeAuth;
        try {
          auth = await this.p.getAuth();
        } catch (e) {
          const msg = e instanceof Error ? e.message : String(e);
          logger.debug(
            `${this.p.coloredName} streamList auth fetch failed: ${msg}; falling back to polling`,
          );
          return { outcome: "fallback" };
        }

        let sawChunkThisAttempt = false;
        let outcome;
        try {
          outcome = await openStreamListConnection({
            auth,
            liveChatId: this.p.liveChatId,
            pageToken: this.pageToken,
            signal: abort.signal,
            onConnect: () => {
              if (!this.connectedFired) {
                this.connectedFired = true;
                this.p.onConnect();
              }
            },
            onChunk: (chunk) => {
              sawChunkThisAttempt = true;
              everSawChunk = true;
              if (chunk.nextPageToken) {
                this.pageToken = chunk.nextPageToken;
              }
              for (const m of chunk.messages) {
                if (this.aborted) break;
                if (this.seen.has(m.id)) continue;
                this.seen.add(m.id);
                this.p.onMessage(m);
              }
            },
          });
        } catch (err) {
          // openStreamListConnection only throws when the gRPC proto cannot
          // be loaded at all — terminal, fall back to polling.
          if (err instanceof YouTubeApiError) {
            logger.warn(
              `${this.p.coloredName} streamList load failed (${err.reason}): ${err.message}; falling back to polling`,
            );
          } else {
            const msg = err instanceof Error ? err.message : String(err);
            logger.debug(
              `${this.p.coloredName} streamList unexpected error: ${msg}; falling back to polling`,
            );
          }
          return { outcome: "fallback" };
        }

        if (this.aborted) return { outcome: "fallback" };

        switch (outcome.kind) {
          case "aborted":
            return { outcome: "fallback" };
          case "ended":
            return { outcome: "ended" };
          case "terminal":
            logger.warn(
              `${this.p.coloredName} streamList terminal failure (code=${outcome.code}, ${outcome.message}); falling back to polling`,
            );
            return { outcome: "fallback" };
          case "offline":
          case "completed":
          case "transient": {
            // YouTube's gRPC streamList delivers a batch then closes the
            // connection cleanly (often with offline=true at the end of the
            // batch even when the broadcast is live). The correct response is
            // to reconnect immediately with the saved pageToken. If we got
            // chunks, that's the happy path — reconnect with no delay. Only
            // empty closes count toward the bounded-reconnect quota that
            // ultimately falls back to polling.
            if (sawChunkThisAttempt) {
              transientAttempts = 0;
              logger.debug(
                `${this.p.coloredName} streamList delivered batch (kind=${outcome.kind}); reconnecting with pageToken=${this.pageToken ? this.pageToken.slice(0, 8) + "..." : "none"}`,
              );
              break;
            }
            transientAttempts++;
            if (transientAttempts >= STREAM_BACKOFF_MS.length) {
              logger.warn(
                `${this.p.coloredName} streamList ${transientAttempts} consecutive empty reconnects; falling back to polling`,
              );
              return { outcome: "fallback" };
            }
            const delay =
              STREAM_BACKOFF_MS[transientAttempts - 1] ?? 8000;
            logger.debug(
              `${this.p.coloredName} streamList ${outcome.kind === "transient" ? `transient (code=${outcome.code})` : "closed without data"}; reconnecting in ${delay}ms (attempt ${transientAttempts}/${STREAM_BACKOFF_MS.length})`,
            );
            await sleep(delay, () => this.aborted);
            break;
          }
        }
      }
      return { outcome: "fallback" };
    } finally {
      this.streamAbort = null;
      void everSawChunk;
    }
  }

  private async runPolling(): Promise<void> {
    while (!this.aborted) {
      const page = await this.fetchPollPageWithAuthRetry();
      if (this.aborted) break;

      if (!this.connectedFired) {
        this.connectedFired = true;
        this.p.onConnect();
      }

      const dropBefore = this.firstPollPage ? this.pollStartedAtMs : 0;
      for (const m of page.messages) {
        if (this.aborted) break;
        if (this.seen.has(m.id)) continue;
        this.seen.add(m.id);
        if (m.publishedAtMs < dropBefore) continue;
        this.p.onMessage(m);
      }
      this.firstPollPage = false;
      this.pageToken = page.nextPageToken;

      if (page.offline) {
        this.p.onStop({
          reason: "offline",
          userMessage: "Stream is offline.",
        });
        return;
      }

      this.currentDelayMs = clamp(
        page.pollingIntervalMs,
        MIN_DELAY_MS,
        MAX_DELAY_MS,
      );
      await sleep(this.currentDelayMs, () => this.aborted);
    }
    this.p.onStop({ reason: "stopped", userMessage: null });
  }

  private async fetchPollPageWithAuthRetry() {
    const auth = await this.p.getAuth();
    try {
      return await fetchLiveChatPage({
        auth,
        liveChatId: this.p.liveChatId,
        pageToken: this.pageToken,
      });
    } catch (err) {
      if (err instanceof YouTubeApiError && err.reason === "rateLimitExceeded") {
        const slowed = Math.min(this.currentDelayMs * 2, MAX_DELAY_MS);
        logger.warn(
          `${this.p.coloredName} Rate limit hit; slowing polling to ${slowed}ms`,
        );
        await sleep(slowed, () => this.aborted);
        return await fetchLiveChatPage({
          auth,
          liveChatId: this.p.liveChatId,
          pageToken: this.pageToken,
        });
      }
      throw err;
    }
  }
}

function clamp(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) return min;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

function sleep(ms: number, isAborted: () => boolean): Promise<void> {
  return new Promise((resolve) => {
    const step = 100;
    const start = Date.now();
    const tick = () => {
      if (isAborted()) return resolve();
      if (Date.now() - start >= ms) return resolve();
      setTimeout(tick, Math.min(step, ms - (Date.now() - start)));
    };
    tick();
  });
}
