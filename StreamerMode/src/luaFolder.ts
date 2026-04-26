import { existsSync, mkdirSync, writeFileSync } from "fs";
import { join } from "path";
import { logger } from "./utils/logger.ts";

export function setupLuaFolder(): string | null {
  const userProfile = process.env["USERPROFILE"] ?? process.env["HOME"];
  if (!userProfile) {
    logger.warn("Cannot determine user home directory (USERPROFILE/HOME not set)");
    return null;
  }

  const zomboidDir = join(userProfile, "Zomboid");
  if (!existsSync(zomboidDir)) {
    logger.warn(`Zomboid directory not found at ${zomboidDir} — Lua folder setup skipped`);
    return null;
  }

  const luaChaosModDir = join(zomboidDir, "Lua", "ChaosMod");
  if (!existsSync(luaChaosModDir)) {
    logger.debug(`Creating Lua folder: ${luaChaosModDir}`);
    mkdirSync(luaChaosModDir, { recursive: true });
    logger.info(`Created Lua folder: ${luaChaosModDir}`);
  } else {
    logger.debug(`Lua folder exists: ${luaChaosModDir}`);
  }

  const nicknamesFile = join(luaChaosModDir, "Nicknames.txt");
  if (!existsSync(nicknamesFile)) {
    writeFileSync(nicknamesFile, "", "utf-8");
    logger.debug(`Created empty Nicknames.txt`);
  }

  return luaChaosModDir;
}
