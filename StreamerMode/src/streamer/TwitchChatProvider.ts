import colors from "colors";
import { logger } from "../utils/logger.ts";
import {
  TwitchProvider,
  type StreamerUser,
} from "./TwitchProvider.ts";
import { TwitchChat, type ChatEvent } from "./TwitchChat.ts";
import type {
  ChatProvider,
  NormalizedChatMessage,
} from "./ChatProvider.ts";
import { pickColorForUser } from "../debugNicknames.ts";

function normalizeColorHex(
  input: string | null | undefined,
  fallbackSeed: string,
): string {
  if (!input) return pickColorForUser(fallbackSeed);
  const trimmed = input.startsWith("#") ? input.slice(1) : input;
  if (!/^[0-9a-fA-F]{6}$/.test(trimmed)) return pickColorForUser(fallbackSeed);
  return trimmed.toLowerCase();
}

export class TwitchChatProvider implements ChatProvider {
  readonly key = "twitch" as const;
  readonly coloredName = colors.magenta("[Twitch]");

  private readonly provider = new TwitchProvider();
  private chat: TwitchChat | null = null;
  private user: StreamerUser | null = null;
  private chatConnected = false;

  onMessage: ((msg: NormalizedChatMessage) => void) | null = null;
  onChatConnect: (() => void) | null = null;
  onChatDisconnect: (() => void) | null = null;
  /** Optional hook fired after a successful manual login (token saved + chat connected). */
  onLogin: ((user: StreamerUser, token: string) => void) | null = null;

  get providerName(): string {
    return this.provider.name;
  }

  getLoginUrl(port: number): string {
    return this.provider.getLoginUrl(port);
  }

  async validateAndSaveToken(token: string): Promise<StreamerUser | null> {
    const user = await this.provider.validateToken(token);
    if (!user) return null;
    await this.provider.saveToken(token);
    logger.info(
      `${this.coloredName} Logged in as ${colors.cyan(user.display_name)}`,
    );
    this.connectChatWith(token, user);
    this.onLogin?.(user, token);
    return user;
  }

  isAccountConnected(): boolean {
    return this.user !== null;
  }

  isChatConnected(): boolean {
    return this.chatConnected;
  }

  getAccountName(): string | null {
    return this.user?.display_name ?? null;
  }

  async initFromStorage(): Promise<void> {
    const token = await this.provider.loadToken();
    if (!token) return;
    const user = await this.provider.validateToken(token);
    if (!user) {
      logger.debug(`Stored ${this.provider.name} token is invalid or expired`);
      return;
    }
    logger.info(
      `${this.coloredName} Logged in as ${colors.cyan(user.display_name)}`,
    );
    this.connectChatWith(token, user);
  }

  async logout(): Promise<boolean> {
    if (this.chat) {
      this.chat.disconnect();
      this.chat = null;
    }
    this.user = null;
    this.chatConnected = false;
    const deleted = await this.provider.deleteToken();
    if (deleted) {
      logger.info(`${this.coloredName} Logged out.`);
    }
    return deleted;
  }

  shutdown(): void {
    if (this.chat) {
      this.chat.disconnect();
      this.chat = null;
    }
  }

  private connectChatWith(token: string, user: StreamerUser): void {
    if (this.chat) this.chat.disconnect();
    this.user = user;
    const chat = new TwitchChat({
      accessToken: token,
      broadcasterUserId: user.id,
      readerUserId: user.id,
    });
    chat.onMessage = (ev) => this.handleRaw(ev);
    chat.onConnect = () => {
      this.chatConnected = true;
      this.onChatConnect?.();
    };
    chat.onDisconnect = () => {
      this.chatConnected = false;
      this.onChatDisconnect?.();
    };
    chat.connect();
    this.chat = chat;
  }

  private handleRaw(ev: ChatEvent): void {
    const msg: NormalizedChatMessage = {
      providerKey: "twitch",
      userId: `twitch:${ev.chatter_user_id}`,
      loginName: ev.chatter_user_login,
      displayName: ev.chatter_user_name,
      colorHex: normalizeColorHex(ev.color, ev.chatter_user_id),
      text: ev.message.text.trim(),
      timestampMs: ev.timestamp_ms,
      publishedAtMs: ev.timestamp_ms,
      cheer: ev.cheer && ev.cheer.bits > 0 ? { bits: ev.cheer.bits } : undefined,
    };
    this.onMessage?.(msg);
  }
}
