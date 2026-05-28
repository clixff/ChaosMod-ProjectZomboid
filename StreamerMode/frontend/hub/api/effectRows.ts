import type {
  ConfigFile,
  EffectDef,
  EffectRow,
  LangFile,
} from "./types.ts";

export interface EffectOverrideEntry {
  enabled?: boolean;
  chance?: number;
  duration?: number;
  enabled_donate?: boolean;
  price_group?: string;
}

export interface BuildEffectRowsOverrides {
  groupPriceOverrides?: ReadonlyMap<string, number>;
  bitsMultiplierOverride?: number | null;
  effectOverrides?: ReadonlyMap<string, EffectOverrideEntry>;
}

export function buildEffectRows(
  effects: EffectDef[],
  config: ConfigFile,
  lang: LangFile,
  fallback: LangFile,
  overrides?: BuildEffectRowsOverrides,
): EffectRow[] {
  const priceByGroup = new Map<string, number>();
  for (const entry of config.streamer_mode.donate_price_groups) {
    priceByGroup.set(entry.group, entry.price);
  }
  if (overrides?.groupPriceOverrides) {
    for (const [g, p] of overrides.groupPriceOverrides) {
      priceByGroup.set(g, p);
    }
  }
  const bitsMultiplier =
    overrides?.bitsMultiplierOverride != null
      ? overrides.bitsMultiplierOverride
      : config.streamer_mode.donation_systems.twitch_bits.price_multiplier;

  const langEffects = lang.effects ?? {};
  const langDescriptions = lang.descriptions ?? {};
  const fallbackEffects = fallback.effects ?? {};
  const fallbackDescriptions = fallback.descriptions ?? {};

  return effects.map((effect, index) => {
    const ovr = overrides?.effectOverrides?.get(effect.id);
    const enabled = ovr?.enabled ?? effect.enabled;
    const chance = ovr?.chance ?? effect.chance;
    const enabledDonate = ovr?.enabled_donate ?? effect.enabled_donate;
    const priceGroup = ovr?.price_group ?? effect.price_group;
    // duration override of 0 means "no duration"; positive value means
    // "use this many seconds"; absent means inherit from the base effect.
    const durationOverridden = ovr?.duration !== undefined;
    const duration = durationOverridden
      ? ovr.duration === 0
        ? undefined
        : ovr.duration
      : effect.duration;
    const withDuration = durationOverridden
      ? ovr.duration !== 0
      : effect.withDuration;

    const price = priceByGroup.get(priceGroup) ?? null;
    const twitchBits =
      price != null ? Math.ceil(price * bitsMultiplier) : null;

    const name =
      langEffects[effect.id] ?? fallbackEffects[effect.id] ?? effect.id;
    const description =
      langDescriptions[effect.id] ?? fallbackDescriptions[effect.id] ?? "";

    return {
      numericId: index + 1,
      effectId: effect.id,
      enabled,
      chance,
      withDuration,
      duration,
      enabledDonate,
      priceGroup,
      price,
      twitchBits,
      name,
      description,
    };
  });
}

export function uniquePriceGroups(rows: EffectRow[]): string[] {
  const seen = new Set<string>();
  for (const row of rows) seen.add(row.priceGroup);
  return Array.from(seen).sort(priceGroupCompare);
}

// Sort price groups in a natural order: positive_1..6, neutral_1..6,
// negative_1..6. Falls back to lexicographic when the prefix is unrecognized.
const POLARITY_ORDER: Record<string, number> = {
  positive: 0,
  neutral: 1,
  negative: 2,
};

export function priceGroupCompare(a: string, b: string): number {
  const [polA, numA] = parseGroup(a);
  const [polB, numB] = parseGroup(b);
  const pa = POLARITY_ORDER[polA] ?? 99;
  const pb = POLARITY_ORDER[polB] ?? 99;
  if (pa !== pb) return pa - pb;
  if (numA !== numB) return numA - numB;
  return a.localeCompare(b);
}

function parseGroup(group: string): [string, number] {
  const match = /^([a-z]+)_(\d+)$/.exec(group);
  if (!match) return [group, 0];
  return [match[1]!, Number(match[2]!)];
}
