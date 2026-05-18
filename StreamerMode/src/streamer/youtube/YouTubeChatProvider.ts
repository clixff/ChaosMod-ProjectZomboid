import colors from "colors";
import { logger } from "../../utils/logger.ts";
import type { ChatProvider, NormalizedChatMessage } from "../ChatProvider.ts";
import {
  fetchVideoLiveChat,
  YouTubeApiError,
  type YouTubeAuth,
} from "./api.ts";
import { extractYouTubeVideoId } from "./youtubeUrl.ts";
import { YouTubeChat, type YouTubeChatStopInfo } from "./YouTubeChat.ts";
import { pickColorForUser } from "../../debugNicknames.ts";

const SERVICE = "chaos-mod-streamer-mode";
const API_KEY_KEY = "youtube-api-key";

export interface YouTubeProviderStatus {
  account_connected: boolean;
  channel_name: string | null;
  chat_connected: boolean;
  stream_url: string | null;
  stream_title: string | null;
  chat_message_count: number;
  last_error: string | null;
}

/**
 * Reads YouTube live chat using the user's own YouTube Data API v3 key
 * (`?key=<API_KEY>` on REST calls, `x-goog-api-key` metadata on gRPC).
 */
export class YouTubeChatProvider implements ChatProvider {
  readonly key = "youtube" as const;
  readonly coloredName = colors.red("[YouTube]");

  private apiKey: string | null = null;
  private channelName: string | null = null;
  private streamUrl: string | null = null;
  private streamTitle: string | null = null;
  private chatMessageCount = 0;
  private chat: YouTubeChat | null = null;
  private chatConnected = false;
  private lastError: string | null = null;
  private connectionTypeReader: () => "long_polling" | "message_streaming" =
    () => "long_polling";

  onMessage: ((msg: NormalizedChatMessage) => void) | null = null;
  onChatConnect: (() => void) | null = null;
  onChatDisconnect: (() => void) | null = null;

  setConnectionTypeReader(
    reader: () => "long_polling" | "message_streaming",
  ): void {
    this.connectionTypeReader = reader;
  }

  isAccountConnected(): boolean {
    return this.apiKey !== null;
  }

  isChatConnected(): boolean {
    return this.chatConnected;
  }

  getAccountName(): string | null {
    return this.channelName;
  }

  getStreamUrl(): string | null {
    return this.streamUrl;
  }

  getStatusSnapshot(): YouTubeProviderStatus {
    return {
      account_connected: this.isAccountConnected(),
      channel_name: this.channelName,
      chat_connected: this.chatConnected,
      stream_url: this.streamUrl,
      stream_title: this.streamTitle,
      chat_message_count: this.chatMessageCount,
      last_error: this.lastError,
    };
  }

  async initFromStorage(): Promise<void> {
    const apiKey = await Bun.secrets.get({
      service: SERVICE,
      name: API_KEY_KEY,
    });
    if (apiKey) this.apiKey = apiKey;

    if (!this.apiKey) return;

    logger.info(`${this.coloredName} API key loaded from storage.`);
  }

  async setApiKey(
    rawKey: string,
  ): Promise<{ success: true } | { success: false; error: string }> {
    const trimmed = rawKey.trim();
    if (!trimmed) {
      return { success: false, error: "API key cannot be empty." };
    }
    this.apiKey = trimmed;
    this.lastError = null;
    await Bun.secrets.set({
      service: SERVICE,
      name: API_KEY_KEY,
      value: trimmed,
    });
    logger.info(`${this.coloredName} API key saved.`);
    return { success: true };
  }

  async logout(): Promise<void> {
    this.stopChat();
    this.apiKey = null;
    this.channelName = null;
    this.streamUrl = null;
    this.streamTitle = null;
    this.chatMessageCount = 0;
    this.lastError = null;
    await Bun.secrets.delete({ service: SERVICE, name: API_KEY_KEY });
    logger.info(`${this.coloredName} Disconnected.`);
  }

  async setStreamUrl(
    rawUrl: string,
  ): Promise<{ success: true } | { success: false; error: string }> {
    const trimmed = rawUrl.trim();
    if (!trimmed) {
      this.stopChat();
      this.streamUrl = null;
      this.streamTitle = null;
      this.chatMessageCount = 0;
      this.lastError = null;
      return { success: true };
    }
    const videoId = extractYouTubeVideoId(trimmed);
    if (!videoId) {
      return {
        success: false,
        error: "Could not find a YouTube video id in that URL.",
      };
    }
    this.streamUrl = trimmed;
    if (!this.isAccountConnected()) {
      this.lastError = "Connect YouTube to start chat.";
      return { success: true };
    }
    await this.startChatForCurrentUrl();
    return { success: true };
  }

  /**
   * Restart the chat reader against the current in-memory URL (e.g. after
   * the user changes the connection type). No-op if no URL or no API key.
   */
  async restartChat(): Promise<void> {
    if (!this.streamUrl || !this.isAccountConnected()) return;
    await this.startChatForCurrentUrl();
  }

  shutdown(): void {
    this.stopChat();
  }

  private stopChat(): void {
    if (this.chat) {
      this.chat.stop();
      this.chat = null;
    }
    if (this.chatConnected) {
      this.chatConnected = false;
      this.onChatDisconnect?.();
    }
  }

  private getAuth(): YouTubeAuth {
    if (!this.apiKey) {
      throw new Error("Not connected to YouTube (no API key).");
    }
    return { apiKey: this.apiKey };
  }

  private async startChatForCurrentUrl(): Promise<void> {
    if (!this.streamUrl || !this.isAccountConnected()) return;
    const videoId = extractYouTubeVideoId(this.streamUrl);
    if (!videoId) {
      this.lastError = "Stored stream URL is invalid.";
      return;
    }
    this.stopChat();
    let videoInfo;
    try {
      videoInfo = await fetchVideoLiveChat({ auth: this.getAuth(), videoId });
    } catch (e) {
      if (e instanceof YouTubeApiError) {
        this.lastError = e.userMessage;
        logger.warn(`${this.coloredName} ${e.userMessage}`);
      } else {
        const msg = e instanceof Error ? e.message : String(e);
        this.lastError = msg;
        logger.warn(`${this.coloredName} Failed to fetch video info: ${msg}`);
      }
      return;
    }
    if (!videoInfo.liveChatId) {
      this.lastError = videoInfo.hasEnded
        ? "This live chat has ended."
        : "This video has no active live chat. Make sure the stream is live and chat is enabled.";
      logger.warn(`${this.coloredName} ${this.lastError}`);
      return;
    }
    // Show the broadcaster's channel name in the dashboard.
    this.channelName = videoInfo.channelTitle ?? null;
    this.streamTitle = videoInfo.title ?? null;
    this.chatMessageCount = 0;
    this.lastError = null;
    logger.info(
      `${this.coloredName} Reading live chat from "${videoInfo.title ?? "(unknown title)"}" by ${videoInfo.channelTitle ?? "(unknown channel)"}`,
    );
    const chat = new YouTubeChat({
      coloredName: this.coloredName,
      liveChatId: videoInfo.liveChatId,
      getAuth: () => Promise.resolve(this.getAuth()),
      getPollingOnly: () => this.connectionTypeReader() === "long_polling",
      onMessage: (m) => {
        const text = m.text.trim();
        if (!text) return;
        const msg: NormalizedChatMessage = {
          providerKey: "youtube",
          userId: `youtube:${m.authorChannelId}`,
          // NicknamesManager keys by loginName and writes displayName to
          // Nicknames.txt only when displayName.toLowerCase() === loginName.
          // Use the lowercased displayName so the formatted (no-@) display
          // name reaches the file instead of the raw channel id.
          loginName: m.authorDisplayName.toLowerCase(),
          displayName: m.authorDisplayName,
          colorHex: pickColorForUser(m.authorChannelId),
          text,
          timestampMs: Date.now(),
          publishedAtMs: m.publishedAtMs,
        };
        logger.debug(
          `${this.coloredName} New chat message: ${m.authorDisplayName} (${m.authorChannelId}): ${text}`,
        );
        this.chatMessageCount++;
        this.onMessage?.(msg);
      },
      onConnect: () => {
        this.chatConnected = true;
        this.onChatConnect?.();
      },
      onStop: (info: YouTubeChatStopInfo) => {
        if (this.chat === chat) this.chat = null;
        if (this.chatConnected) {
          this.chatConnected = false;
          this.onChatDisconnect?.();
        }
        if (info.userMessage) this.lastError = info.userMessage;
      },
    });
    this.chat = chat;
    chat.start();
  }

}
