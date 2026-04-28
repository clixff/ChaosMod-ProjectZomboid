import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

export interface EffectEntry {
  id: string;
  enabled: boolean;
  chance: number;
  withDuration: boolean;
  duration?: number;
  enabled_donate: boolean;
  price_group: string;
}

function parseEffect(raw: unknown): EffectEntry | null {
  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) return null;
  const r = raw as Record<string, unknown>;
  if (typeof r["id"] !== "string") return null;
  return {
    id: r["id"],
    enabled: typeof r["enabled"] === "boolean" ? r["enabled"] : true,
    chance: typeof r["chance"] === "number" ? r["chance"] : 50,
    withDuration: typeof r["withDuration"] === "boolean" ? r["withDuration"] : false,
    duration: typeof r["duration"] === "number" ? r["duration"] : undefined,
    enabled_donate: typeof r["enabled_donate"] === "boolean" ? r["enabled_donate"] : false,
    price_group: typeof r["price_group"] === "string"
      ? r["price_group"]
      : typeof r["price_group"] === "number"
        ? String(r["price_group"])
        : "",
  };
}

export function loadEffects(modFolder: string): EffectEntry[] {
  const effectsPath = join(modFolder, "common", "effects.json");

  if (!existsSync(effectsPath)) {
    logger.warn(`effects.json not found at ${effectsPath}`);
    return [];
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(readFileSync(effectsPath, "utf-8"));
    logger.debug(`Loaded effects from ${effectsPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to parse effects.json: ${msg}`);
    return [];
  }

  const root =
    parsed !== null && typeof parsed === "object" && !Array.isArray(parsed)
      ? (parsed as Record<string, unknown>)
      : {};

  const arr = Array.isArray(root["effects"]) ? root["effects"] : [];
  const effects: EffectEntry[] = [];
  for (const item of arr) {
    const entry = parseEffect(item);
    if (entry) effects.push(entry);
  }
  return effects;
}
