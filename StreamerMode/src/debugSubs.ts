import { logger } from "./utils/logger.ts";
import type {
  ChatNotificationEvent,
  ChatNotificationNoticeType,
  SubTier,
} from "./streamer/TwitchChat.ts";

const TICK_INTERVAL_MS = 15000;

const NOTICE_TYPES: ChatNotificationNoticeType[] = ["sub", "resub", "sub_gift"];
const TIERS: SubTier[] = ["1000", "2000", "3000"];
const RANDOM_USER_COUNT = 40;

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick<T>(arr: readonly T[]): T {
  const idx = randomInt(0, arr.length - 1);
  return arr[idx] as T;
}

function buildEvent(broadcasterUserId: string): ChatNotificationEvent {
  const notice = pick(NOTICE_TYPES);
  const tier = pick(TIERS);
  const userIndex = randomInt(1, RANDOM_USER_COUNT);
  const login = `debug_subber_${userIndex}`;
  const name = `DebugSubber${userIndex}`;

  const event: ChatNotificationEvent = {
    broadcaster_user_id: broadcasterUserId,
    chatter_user_id: `debug-${userIndex}`,
    chatter_user_login: login,
    chatter_user_name: name,
    notice_type: notice,
  };

  if (notice === "sub") {
    event.sub = { sub_tier: tier };
  } else if (notice === "resub") {
    event.resub = { sub_tier: tier, cumulative_months: randomInt(1, 24) };
  } else if (notice === "sub_gift") {
    event.sub_gift = {
      sub_tier: tier,
      recipient_user_name: `Recipient${randomInt(1, 100)}`,
    };
  }

  return event;
}

export function startDebugSubs(
  emit: (ev: ChatNotificationEvent) => void,
): void {
  logger.info(
    "Debug subs mode active — emitting a simulated Twitch sub event every 15s.",
  );

  setInterval(() => {
    const ev = buildEvent("debug-broadcaster");
    const tier =
      ev.notice_type === "sub"
        ? ev.sub?.sub_tier
        : ev.notice_type === "resub"
          ? ev.resub?.sub_tier
          : ev.sub_gift?.sub_tier;
    logger.info(
      `[debug-subs] Emitting ${ev.notice_type} (tier ${tier ?? "?"}) from ${ev.chatter_user_name}`,
    );
    try {
      emit(ev);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[debug-subs] emit failed: ${msg}`);
    }
  }, TICK_INTERVAL_MS);
}
