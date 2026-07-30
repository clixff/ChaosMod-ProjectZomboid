import { copyFileSync, existsSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

export const USER_CONFIG_FILE_NAME = "config.json.cfg";
export const USER_EFFECTS_FILE_NAME = "effects.json.cfg";
export const USER_CONFIG_BACKUP_FILE_NAME = "config_backup.json.txt";
export const USER_EFFECTS_BACKUP_FILE_NAME = "effects.json.backup.txt";

export const LEGACY_USER_CONFIG_FILE_NAME = "config.json";
export const LEGACY_USER_EFFECTS_FILE_NAME = "effects.json";

export const NODE_BRIDGE_FILE_NAME = "chaos-bridge-node.jsonl.txt";
export const LUA_BRIDGE_FILE_NAME = "chaos-bridge-lua.jsonl.txt";
export const NODE_BRIDGE_BACKUP_FILE_NAME =
  "chaos-bridge-node.jsonl.backup.txt";
export const LUA_BRIDGE_BACKUP_FILE_NAME =
  "chaos-bridge-lua.jsonl.backup.txt";

export function migrateLegacyRuntimeFile(
  luaFolder: string,
  legacyFileName: string,
  fileName: string,
): void {
  const path = join(luaFolder, fileName);
  if (existsSync(path)) return;

  const legacyPath = join(luaFolder, legacyFileName);
  if (!existsSync(legacyPath)) return;

  try {
    copyFileSync(legacyPath, path);
    logger.info(`Migrated ${legacyFileName} to ${fileName}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to migrate ${legacyFileName} to ${fileName}: ${msg}`);
  }
}
