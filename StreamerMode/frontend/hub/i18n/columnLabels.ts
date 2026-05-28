import type { LangFile } from "../api/types.ts";

export interface ColumnLabels {
  id: string;
  name: string;
  description: string;
  duration: string;
  chance: string;
  priceGroup: string;
  price: string;
  twitchBits: string;
}

const ENGLISH_DEFAULTS: ColumnLabels = {
  id: "ID",
  name: "Name",
  description: "Description",
  duration: "Duration",
  chance: "Chance",
  priceGroup: "Price Group",
  price: "Price",
  twitchBits: "Twitch Bits",
};

export function getColumnLabels(
  lang: LangFile | undefined,
  fallback: LangFile | undefined,
): ColumnLabels {
  const exp = lang?.export ?? {};
  const fb = fallback?.export ?? {};
  function pick(key: string, def: string): string {
    return exp[key] ?? fb[key] ?? def;
  }
  return {
    id: pick("col_id", ENGLISH_DEFAULTS.id),
    name: pick("col_name", ENGLISH_DEFAULTS.name),
    description: pick("col_description", ENGLISH_DEFAULTS.description),
    duration: pick("col_duration", ENGLISH_DEFAULTS.duration),
    chance: pick("col_chance", ENGLISH_DEFAULTS.chance),
    priceGroup: pick("col_price_group", ENGLISH_DEFAULTS.priceGroup),
    price: pick("col_price", ENGLISH_DEFAULTS.price),
    twitchBits: pick("col_twitch_bits", ENGLISH_DEFAULTS.twitchBits),
  };
}
