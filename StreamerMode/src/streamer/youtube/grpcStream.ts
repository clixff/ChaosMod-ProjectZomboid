// NOTE: the actual fix for the protobufjs/Long issue in `bun build --compile`
// lives in `protobufBootstrap.ts`, which `index.ts` imports first so that
// `globalThis.Long` is populated before `@grpc/proto-loader` pulls in
// `protobufjs/util/minimal.js`.
import path from "node:path";
import { writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import grpc from "@grpc/grpc-js";
import protoLoader from "@grpc/proto-loader";
// Embed the proto source directly into the bundle. In `bun build --compile`
// mode `import.meta.url` resolves to a virtual path inside the .exe and
// `fs.readFileSync` of a sibling file fails with ENOENT, so we ship the proto
// as a string and materialize it to a temp file at startup so proto-loader
// (which only accepts filenames) can read it.
import protoSource from "../../grpc/youtube/stream_list.proto" with {
  type: "text",
};
import { logger } from "../../utils/logger.ts";
import { YouTubeApiError, type YouTubeAuth } from "./api.ts";
import type { YouTubeLiveChatMessage } from "./api.ts";

const PROTO_PATH = path.join(tmpdir(), "chaosmod-stream-list.proto");
try {
  writeFileSync(PROTO_PATH, protoSource);
} catch (e) {
  // Surface the failure early; loadClientCtor will report it through
  // YouTubeApiError if/when streaming is attempted.
  logger.warn(
    `[YouTube] Failed to materialize stream_list.proto to ${PROTO_PATH}: ${e instanceof Error ? e.message : String(e)}`,
  );
}

const GRPC_TARGET = "youtube.googleapis.com:443";

interface RawAuthorDetails {
  channelId?: string;
  displayName?: string;
  isChatOwner?: boolean;
  isChatModerator?: boolean;
  isChatSponsor?: boolean;
}

interface RawTextDetails {
  messageText?: string;
}

interface RawSnippet {
  type?: string;
  publishedAt?: string;
  displayMessage?: string;
  textMessageDetails?: RawTextDetails;
}

interface RawItem {
  id?: string;
  snippet?: RawSnippet;
  authorDetails?: RawAuthorDetails;
}

interface RawResponse {
  nextPageToken?: string;
  offlineAt?: string;
  items?: RawItem[];
}

interface ClientReadableStreamLike {
  on(event: "data", listener: (resp: RawResponse) => void): void;
  on(event: "error", listener: (err: grpc.ServiceError) => void): void;
  on(event: "end", listener: () => void): void;
  on(event: "status", listener: (status: grpc.StatusObject) => void): void;
  cancel(): void;
}

type StreamMethod = (
  request: Record<string, unknown>,
  metadata: grpc.Metadata,
) => ClientReadableStreamLike;

type ClientLike = grpc.Client & {
  streamList?: StreamMethod;
  StreamList?: StreamMethod;
  close: () => void;
};

interface CachedClient {
  ctor: new (
    address: string,
    creds: grpc.ChannelCredentials,
  ) => ClientLike;
}

let cachedClient: CachedClient | null = null;
let cachedError: Error | null = null;

function loadClientCtor(): CachedClient {
  if (cachedClient) return cachedClient;
  if (cachedError) throw cachedError;
  try {
    const def = protoLoader.loadSync(PROTO_PATH, {
      keepCase: false,
      longs: String,
      enums: String,
      defaults: true,
      oneofs: true,
    });
    const loaded = grpc.loadPackageDefinition(def) as Record<string, unknown>;
    const yt = loaded["youtube"] as Record<string, unknown> | undefined;
    const api = yt?.["api"] as Record<string, unknown> | undefined;
    const v3 = api?.["v3"] as Record<string, unknown> | undefined;
    const svc = v3?.["V3DataLiveChatMessageService"];
    if (typeof svc !== "function") {
      throw new Error(
        "youtube.api.v3.V3DataLiveChatMessageService not found in stream_list.proto",
      );
    }
    cachedClient = {
      ctor: svc as new (
        address: string,
        creds: grpc.ChannelCredentials,
      ) => ClientLike,
    };
    logger.debug(
      "[YouTube] gRPC client loaded from " + PROTO_PATH,
    );
    return cachedClient;
  } catch (e) {
    cachedError = e instanceof Error ? e : new Error(String(e));
    throw cachedError;
  }
}

export interface GrpcStreamChunk {
  messages: YouTubeLiveChatMessage[];
  nextPageToken: string | null;
  offline: boolean;
}

export interface GrpcStreamParams {
  auth: YouTubeAuth;
  liveChatId: string;
  pageToken?: string | null;
  signal: AbortSignal;
  onConnect: () => void;
  onChunk: (chunk: GrpcStreamChunk) => void;
}

export type GrpcStreamOutcome =
  | { kind: "ended"; userMessage: string }
  | { kind: "offline" }
  | { kind: "aborted" }
  | { kind: "completed" } // server closed normally
  | { kind: "transient"; code: grpc.status; message: string }
  | { kind: "terminal"; code: grpc.status; message: string };

function sanitizeDisplayName(raw: string | undefined): string {
  const trimmed = (raw ?? "").trim();
  if (trimmed.length > 1 && trimmed.startsWith("@")) {
    return trimmed.slice(1).trim();
  }
  return trimmed;
}

function parseGrpcItem(item: RawItem): YouTubeLiveChatMessage | null {
  // protoLoader returns enum values as their string names when enums: String.
  if (item.snippet?.type !== "TEXT_MESSAGE_EVENT") return null;
  const id = item.id;
  const channelId = item.authorDetails?.channelId;
  if (!id || !channelId) return null;
  const text =
    item.snippet?.textMessageDetails?.messageText ??
    item.snippet?.displayMessage ??
    "";
  const publishedAtMs = item.snippet?.publishedAt
    ? Date.parse(item.snippet.publishedAt)
    : Date.now();
  const display = sanitizeDisplayName(item.authorDetails?.displayName);
  return {
    id,
    authorChannelId: channelId,
    authorDisplayName: display || channelId,
    text,
    publishedAtMs: Number.isFinite(publishedAtMs) ? publishedAtMs : Date.now(),
    isOwner: item.authorDetails?.isChatOwner === true,
    isModerator: item.authorDetails?.isChatModerator === true,
    isSponsor: item.authorDetails?.isChatSponsor === true,
  };
}

function classifyCode(code: grpc.status): "transient" | "terminal" {
  switch (code) {
    case grpc.status.UNAVAILABLE:
    case grpc.status.DEADLINE_EXCEEDED:
    case grpc.status.CANCELLED:
    case grpc.status.INTERNAL:
    case grpc.status.UNKNOWN:
      return "transient";
    case grpc.status.UNAUTHENTICATED:
    case grpc.status.PERMISSION_DENIED:
    case grpc.status.NOT_FOUND:
    case grpc.status.INVALID_ARGUMENT:
    case grpc.status.UNIMPLEMENTED:
      return "terminal";
    default:
      return "terminal";
  }
}

/**
 * Opens a single gRPC server-streaming connection to YouTube's
 * V3DataLiveChatMessageService/StreamList and forwards chunks.
 *
 * Resolves with a {@link GrpcStreamOutcome} describing why the connection
 * ended. Throws YouTubeApiError only when the gRPC client cannot be
 * constructed at all (proto load failure).
 */
export function openStreamListConnection(
  params: GrpcStreamParams,
): Promise<GrpcStreamOutcome> {
  let cached: CachedClient;
  try {
    cached = loadClientCtor();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    throw new YouTubeApiError({
      status: 0,
      reason: "other",
      message: `gRPC proto load failed: ${msg}`,
      userMessage:
        "Could not load YouTube streaming proto; falling back to polling.",
    });
  }

  return new Promise<GrpcStreamOutcome>((resolve) => {
    const client = new cached.ctor(
      GRPC_TARGET,
      grpc.credentials.createSsl(),
    );

    const metadata = new grpc.Metadata();
    metadata.set("x-goog-api-key", params.auth.apiKey);
    // Google APIs sometimes require routing parameters as metadata so the
    // request reaches the correct backend shard.
    metadata.set(
      "x-goog-request-params",
      `live_chat_id=${encodeURIComponent(params.liveChatId)}`,
    );

    const request: Record<string, unknown> = {
      liveChatId: params.liveChatId,
      part: ["id", "snippet", "authorDetails"],
    };
    if (params.pageToken) {
      request.pageToken = params.pageToken;
    }

    const stream = client.streamList?.(request, metadata) ??
      client.StreamList?.(request, metadata);

    if (!stream) {
      logger.warn(
        `${"[YouTube]"} gRPC streamList method not found on client; falling back`,
      );
      client.close();
      resolve({
        kind: "terminal",
        code: grpc.status.UNIMPLEMENTED,
        message: "streamList method not found on generated client",
      });
      return;
    }

    let sawAnyChunk = false;
    let settled = false;
    let receivedOffline = false;

    // If the server keeps the connection open without ever yielding a chunk
    // (we've seen this in API-key mode), treat it as a transient failure
    // after this many ms so the orchestrator can try a fresh connection or
    // fall back to polling.
    // If the server keeps the connection open without yielding a first
    // chunk, treat it as a transient failure after this many ms so the
    // orchestrator can fall back to polling instead of hanging.
    //
    // KNOWN ISSUE: on Bun, grpc-js can starve the event loop during stream
    // setup, which prevents this setTimeout from firing in practice. Keeping
    // the watchdog wired up for runtimes that don't have the starvation bug.
    const FIRST_CHUNK_TIMEOUT_MS = 10_000;
    let firstChunkTimer: ReturnType<typeof setTimeout> | null = setTimeout(
      () => {
        if (sawAnyChunk || settled) return;
        logger.debug(
          `[YouTube] gRPC streamList no data within ${FIRST_CHUNK_TIMEOUT_MS}ms; cancelling`,
        );
        try {
          stream.cancel();
        } catch {
          // ignore
        }
        settle({
          kind: "transient",
          code: grpc.status.DEADLINE_EXCEEDED,
          message: "no data within first-chunk deadline",
        });
      },
      FIRST_CHUNK_TIMEOUT_MS,
    );

    const settle = (outcome: GrpcStreamOutcome): void => {
      if (settled) return;
      settled = true;
      if (firstChunkTimer) {
        clearTimeout(firstChunkTimer);
        firstChunkTimer = null;
      }
      params.signal.removeEventListener("abort", onAbort);
      try {
        client.close();
      } catch {
        // ignore
      }
      resolve(outcome);
    };

    const onAbort = (): void => {
      try {
        stream.cancel();
      } catch {
        // ignore
      }
      settle({ kind: "aborted" });
    };

    if (params.signal.aborted) {
      onAbort();
      return;
    }
    params.signal.addEventListener("abort", onAbort, { once: true });

    logger.debug(
      `[YouTube] gRPC streamList connecting (liveChatId=${params.liveChatId}, pageToken=${params.pageToken ? params.pageToken.slice(0, 8) + "..." : "none"})`,
    );

    stream.on("status", (status) => {
      logger.debug(
        `[YouTube] gRPC streamList status: code=${status.code} (${grpc.status[status.code] ?? "?"}) details="${status.details ?? ""}"`,
      );
    });

    stream.on("data", (resp) => {
      if (!sawAnyChunk) {
        sawAnyChunk = true;
        if (firstChunkTimer) {
          clearTimeout(firstChunkTimer);
          firstChunkTimer = null;
        }
        params.onConnect();
      }
      const messages: YouTubeLiveChatMessage[] = [];
      for (const item of resp.items ?? []) {
        const m = parseGrpcItem(item);
        if (m) messages.push(m);
      }
      const offline = typeof resp.offlineAt === "string";
      if (offline) receivedOffline = true;
      logger.debug(
        `[YouTube] gRPC chunk: ${messages.length} text msg(s), ${resp.items?.length ?? 0} raw item(s), nextPageToken=${resp.nextPageToken ? resp.nextPageToken.slice(0, 8) + "..." : "none"}, offline=${offline}`,
      );
      params.onChunk({
        messages,
        nextPageToken: resp.nextPageToken ?? null,
        offline,
      });
    });

    stream.on("error", (err) => {
      const code: grpc.status =
        typeof err.code === "number" ? err.code : grpc.status.UNKNOWN;
      const message = err.message || `gRPC error code=${code}`;
      logger.debug(
        `[YouTube] gRPC streamList error: code=${code} (${grpc.status[code] ?? "?"}) message=${message}`,
      );
      // Map a few terminal-looking responses to user-facing outcomes.
      if (code === grpc.status.UNAUTHENTICATED) {
        settle({ kind: "terminal", code, message });
        return;
      }
      const klass = classifyCode(code);
      settle({ kind: klass, code, message });
    });

    stream.on("end", () => {
      logger.debug(
        `[YouTube] gRPC streamList ended (sawAnyChunk=${sawAnyChunk}, offline=${receivedOffline})`,
      );
      if (receivedOffline) {
        settle({ kind: "offline" });
        return;
      }
      settle({ kind: "completed" });
    });
  });
}
