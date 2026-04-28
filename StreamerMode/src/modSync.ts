import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

const SYNC_FILE = "mod-sync.txt";
const POLL_INTERVAL_MS = 1000;
const MIN_DELAY_MS = 50; // avoid scheduling < 50ms ahead; snap to next boundary

interface SyncState {
  active: boolean; // true when line 1 timestamp is non-zero
  iterationIndex: number;
  votingActive: boolean;
  timestamp: number; // parsed line 1 value; 0 when mod is off
}

function parseSyncState(raw: string): SyncState | null {
  const lines = raw.split("\n");
  const timestampStr = lines[0]?.trim() ?? "";
  const iterationIndex = parseInt(lines[1]?.trim() ?? "", 10);
  if (isNaN(iterationIndex)) return null;
  const timestamp = parseInt(timestampStr, 10);
  const votingActive = (lines[2]?.trim() ?? "") === "1";
  return {
    active: timestampStr !== "" && timestampStr !== "0",
    iterationIndex,
    votingActive,
    timestamp: isNaN(timestamp) ? 0 : timestamp,
  };
}

export class ModSyncWatcher {
  private modEnabled = false;
  private prevIterationIndex = -1; // -1 = first poll not yet done
  private prevVotingActive: boolean | null = null; // null = first poll not yet done
  private timer: ReturnType<typeof setTimeout> | null = null;
  private lastSyncTimestamp: number | null = null; // ms timestamp from line 1

  onModEnabled: (() => void) | null = null;
  onIterationChanged: ((votingActive: boolean) => void) | null = null;
  onVotingActiveChanged: ((votingActive: boolean) => void) | null = null;

  constructor(private readonly luaFolder: string) {}

  get isModEnabled(): boolean {
    return this.modEnabled;
  }

  get iterationIndex(): number {
    return this.prevIterationIndex === -1 ? 0 : this.prevIterationIndex;
  }

  get isVotingActive(): boolean {
    return this.prevVotingActive ?? false;
  }

  start(): void {
    logger.debug(`ModSync: starting watcher (${SYNC_FILE} in ${this.luaFolder})`);
    this.poll();
    this.scheduleNextPoll();
  }

  stop(): void {
    if (this.timer !== null) {
      clearTimeout(this.timer);
      this.timer = null;
      logger.debug("ModSync: watcher stopped");
    }
  }

  private scheduleNextPoll(): void {
    const delay = this.computeNextDelay();
    this.timer = setTimeout(() => {
      this.poll();
      this.scheduleNextPoll();
    }, delay);
  }

  // Returns ms until the next 1-second boundary aligned to lastSyncTimestamp.
  // Falls back to POLL_INTERVAL_MS when no valid timestamp is known.
  private computeNextDelay(): number {
    const ts = this.lastSyncTimestamp;
    if (ts === null || ts <= 0) {
      return POLL_INTERVAL_MS;
    }
    const now = Date.now();
    const elapsed = now - ts;
    const nextN = Math.ceil(elapsed / 1000);
    const delay = ts + nextN * 1000 - now;
    return delay < MIN_DELAY_MS ? delay + 1000 : delay;
  }

  private poll(): void {
    const filePath = join(this.luaFolder, SYNC_FILE);

    if (!existsSync(filePath)) {
      this.apply(null);
      return;
    }

    let raw: string;
    try {
      raw = readFileSync(filePath, "utf-8").trim();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.debug(`ModSync: failed to read ${SYNC_FILE}: ${msg}`);
      this.apply(null);
      return;
    }

    this.apply(raw);
  }

  private apply(raw: string | null): void {
    const state = raw ? parseSyncState(raw) : null;
    const currentIndex = state?.iterationIndex ?? 0;
    const newEnabled = state?.active ?? false;

    if (state !== null && state.timestamp > 0) {
      this.lastSyncTimestamp = state.timestamp;
    } else if (!newEnabled) {
      this.lastSyncTimestamp = null;
    }

    if (newEnabled && !this.modEnabled) {
      logger.debug(`ModSync: mod enabled (iterationIndex: ${currentIndex})`);
      this.onModEnabled?.();
    } else if (!newEnabled && this.modEnabled) {
      logger.debug(`ModSync: mod disabled`);
    }

    const votingActive = state?.votingActive ?? false;
    const indexChanged = this.prevIterationIndex !== -1 && currentIndex !== this.prevIterationIndex;
    const votingChanged = this.prevVotingActive !== null && votingActive !== this.prevVotingActive;

    if (indexChanged) {
      logger.debug(
        `ModSync: effect interval reset (iterationIndex: ${currentIndex}, votingActive: ${votingActive})`,
      );
      this.onIterationChanged?.(votingActive);
    } else if (votingChanged) {
      logger.debug(`ModSync: voting active changed to ${votingActive}`);
      this.onVotingActiveChanged?.(votingActive);
    }

    this.modEnabled = newEnabled;
    this.prevIterationIndex = currentIndex;
    this.prevVotingActive = votingActive;
  }
}
