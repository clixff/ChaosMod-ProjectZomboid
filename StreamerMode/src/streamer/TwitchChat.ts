import colors from "colors";
import { logger } from "../utils/logger.ts";

const CLIENT_ID = "q72hcurbc7rcns1cefr9nqhmixe7b8";
const EVENTSUB_URL = "wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30";
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
    event?: ChatEvent;
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
}

export interface TwitchChatParams {
  accessToken: string;
  broadcasterUserId: string;
  readerUserId: string;
}

export class TwitchChat {
  private readonly coloredName = colors.magenta("[Twitch]");
  private readonly params: TwitchChatParams;
  private ws: WebSocket | null = null;
  private shouldReconnect = false;
  private serverReconnect = false;

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
    });

    ws.addEventListener("message", (event: MessageEvent) => {
      void this.handleMessage(ws, event, initial);
    });

    ws.addEventListener("close", (event: CloseEvent) => {
      if (this.ws === ws) this.ws = null;
      logger.info(`${this.coloredName} Disconnected from chat`);

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

  private async handleMessage(ws: WebSocket, event: MessageEvent, initial: boolean): Promise<void> {
    let msg: EventSubMessage;
    try {
      msg = JSON.parse(String(event.data)) as EventSubMessage;
    } catch {
      logger.warn(`${this.coloredName} Received unparseable message`);
      return;
    }

    const type = msg.metadata?.message_type;

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
      if (msg.metadata?.subscription_type !== "channel.chat.message") return;
      const chat = msg.payload.event;
      if (!chat) return;
      logger.debug(`${this.coloredName} New chat message: ${chat.chatter_user_name}: ${chat.message.text}`);
      this.onChatMessage(chat);
      return;
    }
  }

  private async createSubscription(sessionId: string): Promise<void> {
    const res = await fetch("https://api.twitch.tv/helix/eventsub/subscriptions", {
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
    });

    if (!res.ok) {
      const json: unknown = await res.json();
      throw new Error(`${res.status} ${JSON.stringify(json)}`);
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  private onChatMessage(_chat: ChatEvent): void {
    // placeholder — chat message processing to be implemented
  }
}
