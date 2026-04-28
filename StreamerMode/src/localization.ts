import { existsSync, readFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

// lib → key → value
type LangData = Record<string, Record<string, string>>;
// langCode → lib → key → value
const data: Record<string, LangData> = {};

let currentLang = "en";
let loadedModFolder: string | null = null;

function loadLanguage(modFolder: string, langCode: string): void {
  if (data[langCode]) return;

  const filePath = join(modFolder, "common", "lang", `${langCode}.json`);
  if (!existsSync(filePath)) {
    logger.debug(`Localization: lang file not found: ${filePath}`);
    return;
  }

  let raw: unknown;
  try {
    raw = JSON.parse(readFileSync(filePath, "utf-8"));
  } catch (e) {
    logger.warn(`Localization: failed to parse ${langCode}.json: ${e instanceof Error ? e.message : String(e)}`);
    return;
  }

  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    logger.warn(`Localization: unexpected format in ${langCode}.json`);
    return;
  }

  const langData: LangData = {};
  for (const [lib, strings] of Object.entries(raw as Record<string, unknown>)) {
    if (strings !== null && typeof strings === "object" && !Array.isArray(strings)) {
      const libData: Record<string, string> = {};
      for (const [key, value] of Object.entries(strings as Record<string, unknown>)) {
        if (typeof value === "string") libData[key] = value;
      }
      langData[lib] = libData;
    }
  }

  data[langCode] = langData;
  logger.debug(`Localization: loaded '${langCode}'`);
}

export function initLocalization(modFolder: string, lang: string): void {
  loadedModFolder = modFolder;
  currentLang = lang;
  loadLanguage(modFolder, "en");
  if (lang !== "en") loadLanguage(modFolder, lang);
}

export function setLang(lang: string): void {
  currentLang = lang;
  if (loadedModFolder) loadLanguage(loadedModFolder, lang);
}

export function getString(lib: string, key: string): string {
  if (currentLang !== "en") {
    const val = data[currentLang]?.[lib]?.[key];
    if (val !== undefined) return val;
  }
  const val = data["en"]?.[lib]?.[key];
  if (val !== undefined) return val;
  return `${lib}_${key}`;
}
