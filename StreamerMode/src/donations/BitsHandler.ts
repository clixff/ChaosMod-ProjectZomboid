import { parseEffectTag } from "./DonationManager.ts";
import type { ModConfig, DonatePriceGroup } from "../config.ts";
import type { EffectEntry } from "../effects.ts";

export type BitsHandlerResult =
  | {
      type: "ignored";
      reason:
        | "disabled"
        | "not_streamer_mode"
        | "no_master_donate"
        | "no_bits";
    }
  | { type: "no_tag"; nickname: string; bits: number }
  | {
      type: "unknown_effect";
      nickname: string;
      bits: number;
      raw_tag: string;
    }
  | {
      type: "donations_disabled";
      nickname: string;
      bits: number;
      effect_id: string;
    }
  | {
      type: "price_too_low";
      nickname: string;
      bits: number;
      required_bits: number;
      effect_id: string;
    }
  | {
      type: "activate";
      nickname: string;
      bits: number;
      required_bits: number;
      effect_id: string;
      price_group: string;
    };

function resolveEffect(
  rawTag: string,
  effects: EffectEntry[],
): { effect: EffectEntry; effectIndex: number } | null {
  const byString = effects.findIndex((entry) => entry.id === rawTag);
  if (byString >= 0) {
    const eff = effects[byString];
    if (eff) return { effect: eff, effectIndex: byString };
  }

  if (!/^\d+$/.test(rawTag)) return null;
  const numericId = Number.parseInt(rawTag, 10);
  if (
    !Number.isInteger(numericId) ||
    numericId < 1 ||
    numericId > effects.length
  ) {
    return null;
  }
  const eff = effects[numericId - 1];
  return eff ? { effect: eff, effectIndex: numericId - 1 } : null;
}

export function computeBitsRequired(
  effect: EffectEntry,
  priceGroups: DonatePriceGroup[],
  multiplier: number,
): number | null {
  if (!effect.price_group) return null;
  const group = priceGroups.find((g) => g.group === effect.price_group);
  if (!group) return null;
  return Math.ceil(group.price * multiplier);
}

export interface HandleBitsParams {
  message: string;
  bits: number;
  nickname: string;
  config: ModConfig;
  effects: EffectEntry[];
}

export function handleBitsCheer(params: HandleBitsParams): BitsHandlerResult {
  const { message, bits, nickname, config, effects } = params;
  const sm = config.streamer_mode;

  if (bits <= 0) {
    return { type: "ignored", reason: "no_bits" };
  }
  if (!sm.streamer_mode_enabled) {
    return { type: "ignored", reason: "not_streamer_mode" };
  }
  if (!sm.enable_donate) {
    return { type: "ignored", reason: "no_master_donate" };
  }
  if (!sm.donation_systems.twitch_bits.enabled) {
    return { type: "ignored", reason: "disabled" };
  }

  const rawTag = parseEffectTag(message);
  if (!rawTag) {
    return { type: "no_tag", nickname, bits };
  }

  const resolved = resolveEffect(rawTag, effects);
  if (!resolved) {
    return { type: "unknown_effect", nickname, bits, raw_tag: rawTag };
  }

  const effect = resolved.effect;
  if (!effect.enabled_donate) {
    return {
      type: "donations_disabled",
      nickname,
      bits,
      effect_id: effect.id,
    };
  }

  const required = computeBitsRequired(
    effect,
    sm.donate_price_groups,
    sm.donation_systems.twitch_bits.price_multiplier,
  );
  if (required == null) {
    return {
      type: "donations_disabled",
      nickname,
      bits,
      effect_id: effect.id,
    };
  }

  if (bits < required) {
    return {
      type: "price_too_low",
      nickname,
      bits,
      required_bits: required,
      effect_id: effect.id,
    };
  }

  return {
    type: "activate",
    nickname,
    bits,
    required_bits: required,
    effect_id: effect.id,
    price_group: effect.price_group,
  };
}
