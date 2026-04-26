import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

const SYNC_FILE = "mod-sync.txt";
const POLL_INTERVAL_MS = 1000;

export class ModSyncWatcher {
  private modEnabled = false;
  private validTimestamp = false;
  private lastRawValue: string | null = null;
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly luaFolder: string,
    private readonly effectsInterval: number,
  ) {}

  get isModEnabled(): boolean {
    return this.modEnabled;
  }

  get isTimestampValid(): boolean {
    return this.validTimestamp;
  }

  start(): void {
    logger.debug(
      `ModSync: starting watcher (${SYNC_FILE} in ${this.luaFolder})`,
    );
    this.poll();
    this.timer = setInterval(() => this.poll(), POLL_INTERVAL_MS);
  }

  stop(): void {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
      logger.debug("ModSync: watcher stopped");
    }
  }

  private poll(): void {
    const filePath = join(this.luaFolder, SYNC_FILE);

    if (!existsSync(filePath)) {
      this.applyValue(null);
      return;
    }

    let raw: string;
    try {
      raw = readFileSync(filePath, "utf-8").trim();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.debug(`ModSync: failed to read ${SYNC_FILE}: ${msg}`);
      this.applyValue(null);
      return;
    }

    this.applyValue(raw);
  }

  private applyValue(raw: string | null): void {
    const isZeroOrMissing = raw === null || raw === "0" || raw === "";
    const newEnabled = !isZeroOrMissing;

    if (newEnabled) {
      const timestamp = Number(raw);
      const diffSec = Date.now() / 1000 - timestamp;
      this.validTimestamp = !isNaN(timestamp) && diffSec <= this.effectsInterval + 5;

      if (!this.modEnabled) {
        logger.debug(
          `ModSync: mod enabled (timestamp: ${raw}, valid: ${this.validTimestamp})`,
        );
      } else if (raw !== this.lastRawValue) {
        logger.debug(`ModSync: effect interval reset (timestamp: ${raw})`);
      }
    } else {
      this.validTimestamp = false;
      if (this.modEnabled) {
        const reason =
          raw === null ? `${SYNC_FILE} not found` : `value is "${raw}"`;
        logger.debug(`ModSync: mod disabled (${reason})`);
      }
    }

    this.modEnabled = newEnabled;
    this.lastRawValue = raw;
  }
}
