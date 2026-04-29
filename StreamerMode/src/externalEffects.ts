import { appendFileSync, existsSync, writeFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

export class ExternalEffectsManager {
  private readonly luaFolder: string;
  private readonly filePath: string;
  private pending: Array<{ nickname: string; effectId: string }> = [];
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(luaFolder: string, private readonly flushIntervalMs = 3000) {
    this.luaFolder = luaFolder;
    this.filePath = join(luaFolder, "effects_external.txt");
  }

  start(): void {
    if (!existsSync(this.filePath)) {
      writeFileSync(this.filePath, "", "utf-8");
    }
    this.timer = setInterval(() => { this.flush(); }, this.flushIntervalMs);
  }

  stop(): void {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.flush();
  }

  add(nickname: string, effectId: string): void {
    this.pending.push({ nickname, effectId });
    logger.debug(`Queued external effect: ${effectId} (nickname: "${nickname}")`);
  }

  private flush(): void {
    if (this.pending.length === 0) return;
    const lines = this.pending.map((e) => `${e.nickname}/${e.effectId}`).join("\n") + "\n";
    this.pending = [];
    try {
      appendFileSync(this.filePath, lines, "utf-8");
      logger.debug(`Flushed external effects to ${this.filePath}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to append to effects_external.txt: ${msg}`);
    }
  }
}
