import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";
import type { ModConfig } from "./config.ts";
import type { EffectEntry } from "./effects.ts";

export interface HubExportPayload {
  mod_version: string;
  rewards: boolean;
  bits: boolean;
  donationalerts: boolean;
  last_effect: number;
  data: {
    effects: Record<string, Record<string, unknown>>;
    prices: Record<string, number>;
    rewards: Record<string, { groups: string[] }>;
    currency: string;
    bits_override: number;
    donation_enabled: boolean;
  };
}

export interface RewardSummary {
  name: string;
  groups: string[];
}

interface DefaultEffectsFile {
  effects: DefaultEffectEntry[];
}

interface DefaultEffectEntry {
  id: string;
  enabled?: boolean;
  chance?: number;
  withDuration?: boolean;
  duration?: number;
  enabled_donate?: boolean;
  price_group?: string;
}

interface DefaultConfigFile {
  streamer_mode?: {
    donate_price_groups?: { group: string; price: number }[];
    donation_systems?: {
      twitch_bits?: { price_multiplier?: number };
    };
  };
}

const DEFAULT_BITS_MULTIPLIER = 100;

function readJson<T>(path: string): T | null {
  if (!existsSync(path)) return null;
  try {
    return JSON.parse(readFileSync(path, "utf-8")) as T;
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.warn(`hubExport: failed to read ${path}: ${msg}`);
    return null;
  }
}

function loadDefaultEffects(modFolder: string): DefaultEffectEntry[] {
  const path = join(modFolder, "common", "default_effects.json");
  const root = readJson<DefaultEffectsFile>(path);
  if (!root || !Array.isArray(root.effects)) return [];
  return root.effects.filter(
    (e): e is DefaultEffectEntry => typeof e?.id === "string",
  );
}

function loadDefaultConfig(modFolder: string): DefaultConfigFile {
  const path = join(modFolder, "common", "default_config.json");
  return readJson<DefaultConfigFile>(path) ?? {};
}

// "No duration" can be represented as withDuration=false, duration=undefined,
// or duration=0 (some saves leave a leftover 0 when withDuration was toggled
// off). All three are equivalent — collapse them to 0 before comparing.
function normalizeDuration(entry: {
  withDuration?: boolean;
  duration?: number;
}): number {
  if (entry.withDuration === false) return 0;
  if (typeof entry.duration !== "number") return 0;
  return entry.duration;
}

function effectDiff(
  current: EffectEntry,
  base: DefaultEffectEntry | undefined,
): Record<string, unknown> | null {
  const out: Record<string, unknown> = {};
  const baseEnabled = base?.enabled ?? true;
  const baseChance = typeof base?.chance === "number" ? base.chance : 1;
  const baseEnabledDonate = base?.enabled_donate ?? true;
  const basePriceGroup = base?.price_group ?? "";

  const baseDur = base ? normalizeDuration(base) : 0;
  const currentDur = normalizeDuration(current);

  if (current.enabled !== baseEnabled) out["enabled"] = current.enabled;
  if (current.chance !== baseChance) out["chance"] = current.chance;
  if (currentDur !== baseDur) out["duration"] = currentDur;
  if (current.enabled_donate !== baseEnabledDonate) {
    out["enabled_donate"] = current.enabled_donate;
  }
  if (current.price_group !== basePriceGroup) {
    out["price_group"] = current.price_group;
  }

  return Object.keys(out).length > 0 ? out : null;
}

export function buildHubExportPayload(input: {
  version: string;
  modFolder: string | null;
  config: ModConfig;
  effects: EffectEntry[];
  rewards: RewardSummary[];
}): HubExportPayload {
  const { version, modFolder, config, effects, rewards } = input;

  const defaultEffects = modFolder ? loadDefaultEffects(modFolder) : [];
  const defaultConfig = modFolder ? loadDefaultConfig(modFolder) : {};

  const defaultEffectsById = new Map<string, DefaultEffectEntry>();
  for (const e of defaultEffects) defaultEffectsById.set(e.id, e);

  const effectsOut: Record<string, Record<string, unknown>> = {};
  for (const e of effects) {
    const diff = effectDiff(e, defaultEffectsById.get(e.id));
    if (diff) effectsOut[e.id] = diff;
  }

  const defaultPriceByGroup = new Map<string, number>();
  for (const g of defaultConfig.streamer_mode?.donate_price_groups ?? []) {
    if (typeof g.group === "string" && typeof g.price === "number") {
      defaultPriceByGroup.set(g.group, g.price);
    }
  }
  const pricesOut: Record<string, number> = {};
  for (const entry of config.streamer_mode.donate_price_groups) {
    const def = defaultPriceByGroup.get(entry.group);
    if (def === undefined || entry.price !== def) {
      pricesOut[entry.group] = entry.price;
    }
  }

  const rewardsOut: Record<string, { groups: string[] }> = {};
  for (const r of rewards) {
    if (r.name && r.name.length > 0) {
      rewardsOut[r.name] = { groups: [...r.groups] };
    }
  }

  const bitsMultiplier =
    config.streamer_mode.donation_systems.twitch_bits.price_multiplier;

  return {
    mod_version: version,
    rewards: config.streamer_mode.donation_systems.twitch_points.enabled,
    bits: config.streamer_mode.donation_systems.twitch_bits.enabled,
    donationalerts:
      config.streamer_mode.donation_systems.donationalerts.enabled,
    last_effect: defaultEffects.length,
    data: {
      effects: effectsOut,
      prices: pricesOut,
      rewards: rewardsOut,
      currency: config.streamer_mode.donation_systems.donationalerts.currency,
      bits_override: bitsMultiplier,
      donation_enabled: config.streamer_mode.enable_donate,
    },
  };
}

export { DEFAULT_BITS_MULTIPLIER };
