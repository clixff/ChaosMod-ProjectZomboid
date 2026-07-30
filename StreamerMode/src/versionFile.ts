import { copyFileSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import {
  LEGACY_USER_EFFECTS_FILE_NAME,
  migrateLegacyRuntimeFile,
  USER_EFFECTS_BACKUP_FILE_NAME,
  USER_EFFECTS_FILE_NAME,
} from "./runtimeFiles.ts";
import { logger } from "./utils/logger.ts";
import { compareVersions } from "./versionCheck.ts";

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
 * current mod version, replace the user's effects.json.cfg with the shipped
 * default_effects.json and rewrite VERSION.txt. Must run before effects.json.cfg
 * is loaded into memory.
 */
export function syncEffectsForModVersion(
  modFolder: string,
  luaFolder: string,
  currentVersion: string,
): void {
  migrateLegacyRuntimeFile(
    luaFolder,
    LEGACY_USER_EFFECTS_FILE_NAME,
    USER_EFFECTS_FILE_NAME,
  );
  const versionPath = join(luaFolder, "VERSION.txt");
  const storedVersion = readStoredVersion(versionPath);

  if (storedVersion === currentVersion) {
    return;
  }

  // If VERSION.txt is newer than the current version (the user downgraded the
  // mod/app), keep the user's effects.json.cfg untouched and leave VERSION.txt as
  // the newer marker. Only an upgrade (or unparseable/missing stored version)
  // resets effects.json.cfg to the shipped defaults.
  if (compareVersions(storedVersion, currentVersion) > 0) {
    logger.info(
      `Stored version '${storedVersion}' is newer than current '${currentVersion}'; keeping effects.json.cfg (downgrade)`,
    );
    return;
  }

  logger.info(
    `Mod version changed ('${storedVersion}' -> '${currentVersion}'); replacing effects.json.cfg with defaults`,
  );

  const defaultsPath = join(modFolder, "common", "default_effects.json");
  const effectsPath = join(luaFolder, USER_EFFECTS_FILE_NAME);
  const backupPath = join(luaFolder, USER_EFFECTS_BACKUP_FILE_NAME);
  if (existsSync(defaultsPath)) {
    if (existsSync(effectsPath)) {
      try {
        copyFileSync(effectsPath, backupPath);
        logger.info(`Backed up effects.json.cfg to ${backupPath}`);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.warn(`Failed to write effects.json.backup.txt: ${msg}; proceeding with overwrite`);
      }
    }
    try {
      copyFileSync(defaultsPath, effectsPath);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to replace effects.json.cfg with defaults: ${msg}`);
    }
  } else {
    logger.warn(
      `default_effects.json not found at ${defaultsPath}; cannot replace effects.json.cfg`,
    );
  }

  try {
    writeFileSync(versionPath, currentVersion, "utf-8");
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to write VERSION.txt: ${msg}`);
  }
}
