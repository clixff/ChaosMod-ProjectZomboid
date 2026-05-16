import { copyFileSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

function readStoredVersion(versionPath: string): string {
  if (!existsSync(versionPath)) return "";
  try {
    return readFileSync(versionPath, "utf-8").trim();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.warn(`Failed to read VERSION.txt: ${msg}`);
    return "";
  }
}

/**
 * If VERSION.txt in the Lua folder is missing, empty, or differs from the
 * current mod version, replace the user's effects.json with the shipped
 * default_effects.json and rewrite VERSION.txt. Must run before effects.json
 * is loaded into memory.
 */
export function syncEffectsForModVersion(
  modFolder: string,
  luaFolder: string,
  currentVersion: string,
): void {
  const versionPath = join(luaFolder, "VERSION.txt");
  const storedVersion = readStoredVersion(versionPath);

  if (storedVersion === currentVersion) {
    return;
  }

  logger.info(
    `Mod version changed ('${storedVersion}' -> '${currentVersion}'); replacing effects.json with defaults`,
  );

  const defaultsPath = join(modFolder, "common", "default_effects.json");
  const effectsPath = join(luaFolder, "effects.json");
  const backupPath = `${effectsPath}.backup`;
  if (existsSync(defaultsPath)) {
    if (existsSync(effectsPath)) {
      try {
        copyFileSync(effectsPath, backupPath);
        logger.info(`Backed up effects.json to ${backupPath}`);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.warn(`Failed to write effects.json.backup: ${msg}; proceeding with overwrite`);
      }
    }
    try {
      copyFileSync(defaultsPath, effectsPath);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to replace effects.json with defaults: ${msg}`);
    }
  } else {
    logger.warn(
      `default_effects.json not found at ${defaultsPath}; cannot replace effects.json`,
    );
  }

  try {
    writeFileSync(versionPath, currentVersion, "utf-8");
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to write VERSION.txt: ${msg}`);
  }
}
