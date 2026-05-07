import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  unlinkSync,
  writeFileSync,
  appendFileSync,
} from "fs";
import { dirname, join } from "path";
import { logger } from "../utils/logger.ts";

const PROTOCOL_VERSION = 1;
const MAX_LINES = 15;
const POLL_INTERVAL_MS = 1000;
const SESSION_ID_LEN = 16;
const SESSION_ID_ALPHABET =
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

const EVENTS_SUBDIR = "events";
const NODE_FILE_NAME = "chaos-bridge-node.jsonl";
const LUA_FILE_NAME = "chaos-bridge-lua.jsonl";
const NODE_BACKUP_NAME = `${NODE_FILE_NAME}.backup`;
const LUA_BACKUP_NAME = `${LUA_FILE_NAME}.backup`;

interface HeaderLine {
  sessionId: string;
  start: number;
}

interface EventLine {
  v: number;
  seq: number;
  event: string;
  ts: number;
  payload?: Record<string, unknown>;
}

export type BridgeHandler = (payload: Record<string, unknown>) => void;

function generateSessionId(): string {
  let result = "";
  for (let i = 0; i < SESSION_ID_LEN; i++) {
    result += SESSION_ID_ALPHABET.charAt(
      Math.floor(Math.random() * SESSION_ID_ALPHABET.length),
    );
  }
  return result;
}

function nowSec(): number {
  return Math.floor(Date.now() / 1000);
}

function decodeJsonLine(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function readAllLines(path: string): string[] | null {
  if (!existsSync(path)) return null;
  let content: string;
  try {
    content = readFileSync(path, "utf-8");
  } catch {
    return null;
  }
  if (content === "") return [];
  // Split on \n; trailing empty entry means file ended with newline (good).
  // A non-empty trailing entry means the last line lacks a final \n (partial).
  return content.split("\n");
}

export class Bridge {
  private readonly eventsDir: string;
  private readonly outFile: string;
  private readonly outBackup: string;
  private readonly inFile: string;
  private readonly inBackup: string;

  // Outbound
  private outSessionId: string | null = null;
  private outLineCount = 0;
  private outSeq = 0;
  private pending: EventLine[] = [];

  // Inbound
  private inSessionId: string | null = null;
  private inLineNumber = 0;
  private inLastTs = 0;
  private lastResetEmittedFor: string | null = null;

  // Lifecycle
  private startTime = 0;
  private flushTimer: ReturnType<typeof setInterval> | null = null;
  private pollTimer: ReturnType<typeof setInterval> | null = null;
  private running = false;

  private readonly handlers = new Map<string, BridgeHandler>();

  constructor(private readonly luaFolder: string) {
    this.eventsDir = join(luaFolder, EVENTS_SUBDIR);
    this.outFile = join(this.eventsDir, NODE_FILE_NAME);
    this.outBackup = join(this.eventsDir, NODE_BACKUP_NAME);
    this.inFile = join(this.eventsDir, LUA_FILE_NAME);
    this.inBackup = join(this.eventsDir, LUA_BACKUP_NAME);
  }

  on(eventName: string, handler: BridgeHandler): void {
    this.handlers.set(eventName, handler);
  }

  start(): void {
    if (this.running) return;
    mkdirSync(this.eventsDir, { recursive: true });
    this.startTime = nowSec();
    this.outSessionId = generateSessionId();
    this.outLineCount = 0;
    this.outSeq = 0;
    this.pending = [];
    this.inSessionId = null;
    this.inLineNumber = 0;
    this.inLastTs = 0;
    this.lastResetEmittedFor = null;
    this.writeHeaderTruncate(this.outFile, this.outSessionId, this.startTime);
    this.running = true;
    this.flushTimer = setInterval(() => {
      this.flushPending();
    }, POLL_INTERVAL_MS);
    this.pollTimer = setInterval(() => {
      this.pollIncoming();
    }, POLL_INTERVAL_MS);
    logger.debug(
      `[Bridge] Started, sessionId=${this.outSessionId}, dir=${this.eventsDir}`,
    );
  }

  stop(): void {
    if (!this.running) return;
    if (this.flushTimer) clearInterval(this.flushTimer);
    if (this.pollTimer) clearInterval(this.pollTimer);
    this.flushTimer = null;
    this.pollTimer = null;
    this.flushPending();
    this.running = false;
    logger.debug("[Bridge] Stopped");
  }

  emit(eventName: string, payload?: Record<string, unknown>): void {
    if (!this.running || !this.outSessionId) return;
    this.outSeq += 1;
    const evt: EventLine = {
      v: PROTOCOL_VERSION,
      seq: this.outSeq,
      event: eventName,
      ts: nowSec(),
    };
    if (payload && Object.keys(payload).length > 0) {
      evt.payload = payload;
    }
    this.pending.push(evt);
  }

  private writeHeaderTruncate(
    path: string,
    sessionId: string,
    startTime: number,
  ): void {
    const header: HeaderLine = { sessionId, start: startTime };
    try {
      mkdirSync(dirname(path), { recursive: true });
      writeFileSync(path, `${JSON.stringify(header)}\n`, "utf-8");
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[Bridge] Failed to write header to ${path}: ${msg}`);
    }
  }

  rotateOutbound(): void {
    if (!this.outSessionId) return;
    try {
      if (existsSync(this.outFile)) {
        const tmp = `${this.outBackup}.tmp`;
        copyFileSync(this.outFile, tmp);
        if (existsSync(this.outBackup)) {
          try {
            unlinkSync(this.outBackup);
          } catch {
            // best-effort
          }
        }
        renameSync(tmp, this.outBackup);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[Bridge] Failed to back up outbound file: ${msg}`);
    }
    this.outSessionId = generateSessionId();
    this.outLineCount = 0;
    this.outSeq = 0;
    this.pending = [];
    this.writeHeaderTruncate(this.outFile, this.outSessionId, nowSec());
    logger.debug(
      `[Bridge] Rotated outbound, new sessionId=${this.outSessionId}`,
    );
  }

  private flushPending(): void {
    if (!this.running || this.pending.length === 0) return;
    const lines = this.pending
      .map((evt) => {
        try {
          return JSON.stringify(evt);
        } catch {
          return null;
        }
      })
      .filter((l): l is string => l !== null);
    this.pending = [];
    if (lines.length === 0) return;
    try {
      mkdirSync(this.eventsDir, { recursive: true });
      appendFileSync(this.outFile, `${lines.join("\n")}\n`, "utf-8");
      this.outLineCount += lines.length;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[Bridge] Failed to append to outbound file: ${msg}`);
    }
  }

  private processEvent(evt: EventLine): void {
    const ts = typeof evt.ts === "number" ? evt.ts : 0;
    if (ts < this.startTime) return;
    if (ts < this.inLastTs) return;
    if (ts > this.inLastTs) this.inLastTs = ts;

    if (evt.event === "bridge-reset-session") {
      this.rotateOutbound();
      return;
    }

    const handler = this.handlers.get(evt.event);
    if (handler) {
      try {
        handler(evt.payload ?? {});
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(
          `[Bridge] Handler for '${evt.event}' errored: ${msg}`,
        );
      }
    }
  }

  private drainBackup(oldSessionId: string, oldLineNumber: number): void {
    const lines = readAllLines(this.inBackup);
    if (!lines || lines.length === 0) return;
    const headerRaw = lines[0] ?? "";
    const header = decodeJsonLine(headerRaw);
    if (
      !header ||
      typeof header !== "object" ||
      (header as Partial<HeaderLine>).sessionId !== oldSessionId
    ) {
      return;
    }
    const startIdx = Math.max(1, oldLineNumber);
    for (let i = startIdx; i < lines.length; i++) {
      const raw = lines[i];
      if (raw === undefined || raw === "") continue;
      const evt = decodeJsonLine(raw);
      if (evt && typeof evt === "object") {
        this.processEvent(evt as EventLine);
      }
    }
  }

  private pollIncoming(): void {
    const lines = readAllLines(this.inFile);
    if (!lines || lines.length === 0) return;
    const headerRaw = lines[0] ?? "";
    const header = decodeJsonLine(headerRaw);
    if (!header || typeof header !== "object") return;
    const newSessionId = (header as Partial<HeaderLine>).sessionId;
    if (typeof newSessionId !== "string" || newSessionId === "") return;

    if (newSessionId !== this.inSessionId) {
      const oldSessionId = this.inSessionId;
      const oldLineNumber = this.inLineNumber;
      this.inSessionId = newSessionId;
      this.inLineNumber = 1;
      this.lastResetEmittedFor = null;
      if (oldSessionId) {
        this.drainBackup(oldSessionId, oldLineNumber);
      }
    }

    // split("\n") on "a\nb\n" -> ["a","b",""]; on "a\nb" -> ["a","b"].
    // The element at lines.length-1 is "" iff the file ended with \n.
    // We treat any non-final-\n trailing element as a partial line and skip it.
    const lastIdx = lines.length - 1;
    const trailingPartial = lines[lastIdx] !== "";
    const lastCompleteOneBased = lastIdx; // 0-based lastIdx == 1-based count of complete lines
    // (when trailingPartial, lastIdx is partial -> complete count = lastIdx; when complete, last is "" -> complete count = lastIdx)
    for (
      let lineNum = this.inLineNumber + 1;
      lineNum <= lastCompleteOneBased;
      lineNum++
    ) {
      const raw = lines[lineNum - 1];
      if (raw === undefined || raw === "") {
        this.inLineNumber = lineNum;
        continue;
      }
      const evt = decodeJsonLine(raw);
      if (evt && typeof evt === "object") {
        this.processEvent(evt as EventLine);
        this.inLineNumber = lineNum;
      } else {
        logger.warn(`[Bridge] Skipping malformed line ${lineNum}`);
        this.inLineNumber = lineNum;
      }
    }

    // Total complete lines including the header.
    const totalLines = trailingPartial ? lines.length : lines.length - 1;
    if (totalLines >= MAX_LINES) {
      if (this.lastResetEmittedFor !== newSessionId) {
        this.lastResetEmittedFor = newSessionId;
        this.emit("bridge-reset-session");
      }
    }
  }
}
