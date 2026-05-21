import colors from "colors";
import { isDebugMode, logger } from "../utils/logger.ts";

const CLIENT_ID = "q72hcurbc7rcns1cefr9nqhmixe7b8";
const EVENTSUB_URL =
  "wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30";
const RECONNECT_DELAY_MS = 5000;

// Twitch auth-related close codes — do not auto-reconnect on these
const AUTH_CLOSE_CODES = new Set([4001, 4002, 4003]);

interface EventSubMetadata {
  message_id: string;
  message_type: string;
  message_timestamp: string;
  subscription_type?: string;
}

interface EventSubSession {
  id: string;
  status: string;
  keepalive_timeout_seconds?: number;
  reconnect_url?: string;
}

interface EventSubMessage {
  metadata: EventSubMetadata;
  payload: {
    session?: EventSubSession;
    subscription?: unknown;
    event?: ChatEvent | RedemptionEvent;
  };
}

export interface ChatEvent {
  broadcaster_user_id: string;
  broadcaster_user_login: string;
  broadcaster_user_name: string;
  chatter_user_id: string;
  chatter_user_login: string;
  chatter_user_name: string;
  message_id: string;
  message: {
    text: string;
    fragments: unknown[];
  };
  color: string;
  badges: unknown[];
  message_type: string;
  timestamp_ms: number;
  cheer?: {
    bits: number;
  };
}

export interface RedemptionEvent {
  id: string;
  broadcaster_user_id: string;
  user_id: string;
  user_login: string;
  user_name: string;
  user_input: string;
  status: "unfulfilled" | "fulfilled" | "canceled";
  reward: {
    id: string;
    title: string;
    cost: number;
    prompt: string;
  };
  redeemed_at: string;
}

export interface TwitchChatParams {
  accessToken: string;
  broadcasterUserId: string;
  readerUserId: string;
  subscribeRedemptions: () => boolean;
}

export class TwitchChat {
  private readonly coloredName = colors.magenta("[Twitch]");
  private readonly params: TwitchChatParams;
  private ws: WebSocket | null = null;
  private shouldReconnect = false;
  private serverReconnect = false;

  onMessage: ((chat: ChatEvent) => void) | null = null;
  onRedemption: ((event: RedemptionEvent) => void) | null = null;
  onConnect: (() => void) | null = null;
  onDisconnect: (() => void) | null = null;

  constructor(params: TwitchChatParams) {
    this.params = params;
  }

  connect(): void {
    if (this.ws !== null) return;
    this.shouldReconnect = true;
    this.openConnection(EVENTSUB_URL, true);
  }

  disconnect(): void {
    this.shouldReconnect = false;
    const ws = this.ws;
    this.ws = null;
    ws?.close();
  }

  private openConnection(url: string, initial: boolean): void {
    const ws = new WebSocket(url);
    this.ws = ws;

    ws.addEventListener("open", () => {
      logger.info(`${this.coloredName} Connected to chat`);
      this.onConnect?.();
    });

    ws.addEventListener("message", (event: MessageEvent) => {
      void this.handleMessage(ws, event, initial);
    });

    ws.addEventListener("close", (event: CloseEvent) => {
      if (this.ws === ws) this.ws = null;
      logger.info(`${this.coloredName} Disconnected from chat`);
      if (!this.serverReconnect) {
        this.onDisconnect?.();
      }

      if (this.serverReconnect) {
        this.serverReconnect = false;
        return;
      }

      if (this.shouldReconnect && !AUTH_CLOSE_CODES.has(event.code)) {
        setTimeout(() => {
          if (this.shouldReconnect && this.ws === null) {
            this.openConnection(EVENTSUB_URL, true);
          }
        }, RECONNECT_DELAY_MS);
      }
    });

    ws.addEventListener("error", (event: Event) => {
      logger.error(`${this.coloredName} WebSocket error: ${String(event)}`);
    });
  }

  private async handleMessage(
    ws: WebSocket,
    event: MessageEvent,
    initial: boolean,
  ): Promise<void> {
    let msg: EventSubMessage;
    try {
      msg = JSON.parse(String(event.data)) as EventSubMessage;
    } catch {
      logger.warn(`${this.coloredName} Received unparseable message`);
      return;
    }

    const type = msg.metadata?.message_type;

    logger.debug(`${this.coloredName} New twitch event with type "${type}"`);

    if (type === "session_welcome") {
      if (!initial) return;
      const sessionId = msg.payload.session?.id;
      if (!sessionId) return;
      try {
        await this.createSubscription(sessionId);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        logger.error(`${this.coloredName} Subscription failed: ${message}`);
        if (message.startsWith("401") || message.startsWith("403")) {
          this.shouldReconnect = false;
        }
        ws.close();
        return;
      }
      if (this.params.subscribeRedemptions()) {
        try {
          await this.createRedemptionSubscription(sessionId);
        } catch (err) {
          const message = err instanceof Error ? err.message : String(err);
          logger.warn(
            `${this.coloredName} Redemption subscription failed: ${message}`,
          );
        }
      }
      return;
    }

    if (type === "session_keepalive" || type === "revocation") return;

    if (type === "session_reconnect") {
      const reconnectUrl = msg.payload.session?.reconnect_url;
      if (!reconnectUrl) return;
      this.serverReconnect = true;
      ws.close();
      this.openConnection(reconnectUrl, false);
      return;
    }

    if (type === "notification") {
      const subType = msg.metadata?.subscription_type;
      if (subType === "channel.chat.message") {
        const rawChat = msg.payload.event as ChatEvent | undefined;
        if (!rawChat) return;
        const chat: ChatEvent = {
          ...rawChat,
          timestamp_ms: Date.now(),
        };
        logger.debug(
          `${this.coloredName} New chat message: (${chat.color}) ${chat.chatter_user_name}: ${chat.message.text}`,
        );
        this.onMessage?.(chat);
        return;
      }
      if (subType === "channel.channel_points_custom_reward_redemption.add") {
        const redemption = msg.payload.event as RedemptionEvent | undefined;
        if (!redemption) return;
        logger.debug(
          `${this.coloredName} Reward redemption: ${redemption.user_name} -> "${redemption.reward.title}" (input="${redemption.user_input}")`,
        );
        this.onRedemption?.(redemption);
        return;
      }
    }
  }

  private async createSubscription(sessionId: string): Promise<void> {
    const res = await fetch(
      "https://api.twitch.tv/helix/eventsub/subscriptions",
      {
        method: "POST",
        headers: {
          "Client-Id": CLIENT_ID,
          Authorization: `Bearer ${this.params.accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "channel.chat.message",
          version: "1",
          condition: {
            broadcaster_user_id: this.params.broadcasterUserId,
            user_id: this.params.readerUserId,
          },
          transport: {
            method: "websocket",
            session_id: sessionId,
          },
        }),
      },
    );

    if (!res.ok) {
      const json: unknown = await res.json();
      throw new Error(`${res.status} ${JSON.stringify(json)}`);
    }
  }

  private async createRedemptionSubscription(sessionId: string): Promise<void> {
    const res = await fetch(
      "https://api.twitch.tv/helix/eventsub/subscriptions",
      {
        method: "POST",
        headers: {
          "Client-Id": CLIENT_ID,
          Authorization: `Bearer ${this.params.accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          type: "channel.channel_points_custom_reward_redemption.add",
          version: "1",
          condition: {
            broadcaster_user_id: this.params.broadcasterUserId,
          },
          transport: {
            method: "websocket",
            session_id: sessionId,
          },
        }),
      },
    );

    logger.debug(`${this.coloredName} Subscribing to reward redemptions.`);
    if (isDebugMode()) {
      console.log(res);
    }

    if (!res.ok) {
      const json: unknown = await res.json();
      throw new Error(`${res.status} ${JSON.stringify(json)}`);
    }
  }
}
