import { existsSync, readFileSync, writeFileSync } from "fs";
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

interface EffectsRoot {
  effects: unknown[];
  [key: string]: unknown;
}

function readEffectsRoot(path: string): EffectsRoot | null {
  if (!existsSync(path)) return null;
  let parsed: unknown;
  try {
    parsed = JSON.parse(readFileSync(path, "utf-8"));
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to parse ${path}: ${msg}`);
    return null;
  }
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    return null;
  }
  const root = parsed as Record<string, unknown>;
  const effects = Array.isArray(root["effects"]) ? root["effects"] : [];
  return { ...root, effects };
}

export function loadEffects(modFolder: string, luaFolder: string): EffectEntry[] {
  const userPath = join(luaFolder, "effects.json");
  const defaultPath = join(modFolder, "common", "default_effects.json");

  const defaultRoot = readEffectsRoot(defaultPath);

  let userRoot = readEffectsRoot(userPath);
  if (!userRoot) {
    if (defaultRoot) {
      logger.info(
        `effects.json not found at ${userPath}; copying default_effects.json`,
      );
      try {
        writeFileSync(
          userPath,
          JSON.stringify(defaultRoot, null, 4),
          "utf-8",
        );
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(`Failed to write effects.json: ${msg}`);
      }
      userRoot = defaultRoot;
    } else {
      logger.warn(
        `effects.json not found at ${userPath} and default_effects.json missing`,
      );
      return [];
    }
  } else if (defaultRoot) {
    const existingIds = new Set<string>();
    for (const item of userRoot.effects) {
      if (item !== null && typeof item === "object" && !Array.isArray(item)) {
        const r = item as Record<string, unknown>;
        if (typeof r["id"] === "string") existingIds.add(r["id"]);
      }
    }
    let added = 0;
    for (const item of defaultRoot.effects) {
      if (item !== null && typeof item === "object" && !Array.isArray(item)) {
        const r = item as Record<string, unknown>;
        if (typeof r["id"] === "string" && !existingIds.has(r["id"])) {
          userRoot.effects.push(item);
          existingIds.add(r["id"]);
          added++;
        }
      }
    }
    if (added > 0) {
      logger.info(
        `Added ${added} missing effect(s) from default_effects.json; saving effects.json`,
      );
      try {
        writeFileSync(
          userPath,
          JSON.stringify(userRoot, null, 4),
          "utf-8",
        );
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(`Failed to save merged effects.json: ${msg}`);
      }
    }
  }

  const effects: EffectEntry[] = [];
  for (const item of userRoot.effects) {
    const entry = parseEffect(item);
    if (entry) effects.push(entry);
  }
  logger.debug(`Loaded ${effects.length} effects from ${userPath}`);
  return effects;
}
