import type {
  ConfigFile,
  EffectDef,
  EffectRow,
  LangFile,
} from "./types.ts";

export interface BuildEffectRowsOverrides {
  groupPriceOverrides?: ReadonlyMap<string, number>;
  bitsMultiplierOverride?: number | null;
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
    const price = priceByGroup.get(effect.price_group) ?? null;
    // Price and bits are always shown — the hub is a public reference so they
    // reflect the value that would apply, regardless of enabled_donate or the
    // bits-system enabled flag.
    const twitchBits =
      price != null ? Math.ceil(price * bitsMultiplier) : null;

    const name =
      langEffects[effect.id] ?? fallbackEffects[effect.id] ?? effect.id;
    const description =
      langDescriptions[effect.id] ?? fallbackDescriptions[effect.id] ?? "";

    return {
      numericId: index + 1,
      effectId: effect.id,
      enabled: effect.enabled,
      chance: effect.chance,
      withDuration: effect.withDuration,
      duration: effect.duration,
      enabledDonate: effect.enabled_donate,
      priceGroup: effect.price_group,
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
