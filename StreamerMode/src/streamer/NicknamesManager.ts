import { writeFileSync } from "fs";
import { join } from "path";
import { logger } from "../utils/logger.ts";

interface Nickname {
  name: string;
  color: string; // "r,g,b"
  chatMessage: string | null;
  timestampMs: number | null;
}

function parseHexColor(hex: string): string {
  const clean = hex.startsWith("#") ? hex.slice(1) : hex;
  if (clean.length !== 6) return "255,255,255";
  const r = parseInt(clean.slice(0, 2), 16);
  const g = parseInt(clean.slice(2, 4), 16);
  const b = parseInt(clean.slice(4, 6), 16);
  if (isNaN(r) || isNaN(g) || isNaN(b)) return "255,255,255";
  return `${r},${g},${b}`;
}

export class NicknamesManager {
  private readonly nicknames = new Map<string, Nickname>(); // key = userLogin
  private dirty = false;
  private timer: ReturnType<typeof setInterval> | null = null;

  constructor(
    private readonly luaFolder: string,
    private readonly buffer: number,
    private renderChatMessages: boolean,
  ) {}

  start(): void {
    this.timer = setInterval(() => this.saveIfDirty(), 3000);
  }

  setRenderChatMessages(enabled: boolean): void {
    if (this.renderChatMessages === enabled) return;
    this.renderChatMessages = enabled;
    this.dirty = true;
  }

  add(
    userLogin: string,
    userName: string,
    hexColor: string,
    chatMessage?: string | null,
    timestampMs?: number | null,
  ): void {
    const name = userName.toLowerCase() === userLogin ? userName : userLogin;
    const color = hexColor ? parseHexColor(hexColor) : "255,255,255";
    const prev = this.nicknames.get(userLogin);
    const nextMessage =
      chatMessage !== undefined ? chatMessage : (prev?.chatMessage ?? null);
    const nextTimestamp =
      chatMessage !== undefined
        ? (timestampMs ?? Date.now())
        : (prev?.timestampMs ?? null);

    if (this.nicknames.has(userLogin)) {
      // Update in place — don't shift position in the map
      this.nicknames.set(userLogin, {
        name,
        color,
        chatMessage: nextMessage,
        timestampMs: nextTimestamp,
      });
    } else {
      this.nicknames.set(userLogin, {
        name,
        color,
        chatMessage: nextMessage,
        timestampMs: nextTimestamp,
      });
      while (this.nicknames.size > this.buffer) {
        const firstKey = this.nicknames.keys().next().value;
        if (firstKey !== undefined) this.nicknames.delete(firstKey);
      }
    }

    this.dirty = true;
  }

  private saveIfDirty(): void {
    if (!this.dirty) return;
    this.dirty = false;
    const lines = [...this.nicknames.values()].map((n) => {
      if (
        this.renderChatMessages &&
        n.chatMessage !== null &&
        n.timestampMs !== null
      ) {
        return `${n.name}/${n.color}/${n.chatMessage}/${n.timestampMs}`;
      }

      return `${n.name}/${n.color}`;
    });
    try {
      writeFileSync(join(this.luaFolder, "Nicknames.txt"), lines.join("\n"), "utf-8");
    } catch (e) {
      logger.error(`Failed to save Nicknames.txt: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
}
