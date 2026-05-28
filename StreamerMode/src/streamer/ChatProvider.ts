export type ChatProviderKey = "twitch" | "youtube";

export interface NormalizedChatMessage {
  providerKey: ChatProviderKey;
  /** Namespaced user id, unique across providers (e.g. "twitch:123" / "youtube:UCxxx"). */
  userId: string;
  /** Stable handle used as the nickname-buffer key (Twitch login, YouTube channelId). */
  loginName: string;
  /** Human display name shown in chat. */
  displayName: string;
  /** 6-hex chars (no `#`). Providers without per-user color should pass a stable default. */
  colorHex: string;
  /** Trimmed text. */
  text: string;
  /** ms-since-epoch when the app observed the message. */
  timestampMs: number;
  /** ms-since-epoch when the platform recorded the message (used for skipping initial history). */
  publishedAtMs: number;
  /** Twitch Bits cheer info; undefined for non-Twitch and for non-cheer messages. */
  cheer?: { bits: number };
}

export interface ChatProvider {
  readonly key: ChatProviderKey;
  readonly coloredName: string;

  isAccountConnected(): boolean;
  isChatConnected(): boolean;
  getAccountName(): string | null;

  onMessage: ((msg: NormalizedChatMessage) => void) | null;
  onChatConnect: (() => void) | null;
  onChatDisconnect: (() => void) | null;

  /** Restore persisted state and (if applicable) start chat. */
  initFromStorage(): Promise<void>;
  /** Tear down all sockets, pollers, and in-flight work. */
  shutdown(): Promise<void> | void;
}
