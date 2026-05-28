import type { ModConfig } from "../config.ts";
import type {
  ChatNotificationEvent,
  SubTier,
} from "../streamer/TwitchChat.ts";

export type SubsHandlerResult =
  | {
      type: "ignored";
      reason:
        | "not_streamer_mode"
        | "no_master_donate"
        | "disabled"
        | "notice_type"
        | "gift_subs_disabled"
        | "resubs_disabled"
        | "zero_increment";
    }
  | {
      type: "counted";
      nickname: string;
      increment: number;
      current: number;
      threshold: number;
    }
  | {
      type: "activate";
      nickname: string;
      increment: number;
      current: number;
      threshold: number;
    };

function tierMultiplier(tier: SubTier | undefined, useMultiplier: boolean): number {
  if (!useMultiplier) return 1;
  if (tier === "3000") return 3;
  if (tier === "2000") return 2;
  return 1;
}

export class SubsHandler {
  private current = 0;
  private lastEnabled = false;
  private lastThreshold = 1;

  /** Current counter (capped at threshold) */
  getCurrent(): number {
    return this.current;
  }

  /** Reset counter to 0 (called on disable, restart, threshold change). */
  reset(): void {
    this.current = 0;
  }

  /**
   * Sync the handler's view of config-driven state. Resets the counter when
   * the system flips from disabled to enabled (or vice versa) and when
   * threshold changes.
   */
  syncConfig(enabled: boolean, threshold: number): void {
    if (enabled !== this.lastEnabled) {
      this.current = 0;
      this.lastEnabled = enabled;
    }
    if (threshold !== this.lastThreshold) {
      this.current = 0;
      this.lastThreshold = threshold;
    }
    if (!enabled) {
      this.current = 0;
    }
  }

  handle(event: ChatNotificationEvent, config: ModConfig): SubsHandlerResult {
    const sm = config.streamer_mode;
    const subs = sm.donation_systems.twitch_subs;

    if (!sm.streamer_mode_enabled) {
      return { type: "ignored", reason: "not_streamer_mode" };
    }
    if (!sm.enable_donate) {
      return { type: "ignored", reason: "no_master_donate" };
    }
    if (!subs.enabled) {
      return { type: "ignored", reason: "disabled" };
    }

    const notice = event.notice_type;
    let tier: SubTier | undefined;
    if (notice === "sub") {
      tier = event.sub?.sub_tier;
    } else if (notice === "resub") {
      if (!subs.allow_resubscriptions) {
        return { type: "ignored", reason: "resubs_disabled" };
      }
      tier = event.resub?.sub_tier;
    } else if (notice === "sub_gift") {
      if (!subs.allow_gift_subs) {
        return { type: "ignored", reason: "gift_subs_disabled" };
      }
      tier = event.sub_gift?.sub_tier;
    } else {
      return { type: "ignored", reason: "notice_type" };
    }

    const increment = tierMultiplier(tier, subs.sub_tier_multipliers);
    if (increment <= 0) {
      return { type: "ignored", reason: "zero_increment" };
    }

    const threshold = Math.max(1, Math.floor(subs.threshold));
    const nickname = event.chatter_user_name || event.chatter_user_login || "";

    this.current += increment;

    if (this.current >= threshold) {
      this.current -= threshold;
      // If the increment was big enough to cover more than one activation
      // worth (e.g. tier-3 sub at threshold=1), drop the excess so the
      // counter never displays >= threshold.
      if (this.current >= threshold) this.current = 0;
      return {
        type: "activate",
        nickname,
        increment,
        current: this.current,
        threshold,
      };
    }

    return {
      type: "counted",
      nickname,
      increment,
      current: this.current,
      threshold,
    };
  }
}
