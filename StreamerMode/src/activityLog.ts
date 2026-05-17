const MAX_ACTIVITY_EVENTS = 300;

export type ActivityEventInput =
  | { type: "vote"; effect_id: string; effect_name: string }
  | {
      type: "donate";
      effect_id: string;
      effect_name: string;
      nickname: string;
      price: number | null;
      price_group: string;
    }
  | {
      type: "donate_failed_price";
      effect_id: string;
      effect_name: string;
      nickname: string;
      donation_amount: number;
      required_price: number;
    }
  | {
      type: "donate_failed_disabled";
      effect_id: string;
      effect_name: string;
      nickname: string;
      donation_amount: number;
    }
  | {
      type: "bits";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
      required_bits: number;
      price_group: string;
    }
  | {
      type: "bits_failed_price";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
      required_bits: number;
    }
  | {
      type: "bits_failed_disabled";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
    }
  | {
      type: "bits_failed_no_tag";
      nickname: string;
      bits: number;
    }
  | { type: "chat_connected" }
  | { type: "chat_disconnected" }
  | { type: "donationalerts_connected" }
  | { type: "donationalerts_disconnected" }
  | { type: "youtube_chat_connected" }
  | { type: "youtube_chat_disconnected" };

export type ActivityEvent = ActivityEventInput & { id: number; ts: number };

export class ActivityLog {
  private buffer: ActivityEvent[] = [];
  private nextId = 1;

  add(event: ActivityEventInput): ActivityEvent {
    const last = this.buffer[this.buffer.length - 1];
    if (
      last &&
      (event.type === "chat_connected" ||
        event.type === "chat_disconnected" ||
        event.type === "donationalerts_connected" ||
        event.type === "donationalerts_disconnected" ||
        event.type === "youtube_chat_connected" ||
        event.type === "youtube_chat_disconnected") &&
      last.type === event.type
    ) {
      return last;
    }

    const entry: ActivityEvent = {
      ...event,
      id: this.nextId++,
      ts: Date.now(),
    };
    this.buffer.push(entry);
    if (this.buffer.length > MAX_ACTIVITY_EVENTS) {
      this.buffer.splice(0, this.buffer.length - MAX_ACTIVITY_EVENTS);
    }
    return entry;
  }

  list(): ActivityEvent[] {
    return this.buffer.slice();
  }
}
