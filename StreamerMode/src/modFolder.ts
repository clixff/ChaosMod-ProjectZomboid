import { existsSync, readFileSync, readdirSync, writeFileSync } from "fs";
import { resolve, join } from "path";
import { logger } from "./utils/logger.ts";

export const STREAMERMODE_ROOT = resolve(import.meta.dir, "..");
const MOD_FOLDER_FILE = join(STREAMERMODE_ROOT, "mod-folder");

const USER_MOD_PATH =
  process.env["USERPROFILE"] || process.env["HOME"]
    ? join(process.env["USERPROFILE"] ?? process.env["HOME"] ?? "", "Zomboid", "Workshop", "ChaosModMain", "Contents", "mods", "ChaosMod")
    : null;

const DRIVES = ["C", "D", "E", "F", "G", "H"];
const STEAM_SUBPATHS = [
  "Steam",
  join("Games", "Steam"),
  join("Program Files", "Steam"),
  join("Program Files (x86)", "Steam"),
];
const WORKSHOP_SUFFIX = join("steamapps", "workshop", "content", "108600");

function saveModFolder(modPath: string): void {
  writeFileSync(MOD_FOLDER_FILE, modPath, "utf-8");
  logger.debug(`Saved mod folder to mod-folder file: ${modPath}`);
}

function findInSteam(): string | null {
  for (const drive of DRIVES) {
    const driveRoot = `${drive}:\\`;
    if (!existsSync(driveRoot)) continue;

    for (const steamSub of STEAM_SUBPATHS) {
      const workshopPath = join(driveRoot, steamSub, WORKSHOP_SUFFIX);
      logger.debug(`Checking Steam workshop path: ${workshopPath}`);
      if (!existsSync(workshopPath)) continue;

      let entries;
      try {
        entries = readdirSync(workshopPath, { withFileTypes: true });
      } catch {
        continue;
      }

      for (const entry of entries) {
        if (!entry.isDirectory()) continue;
        const modPath = join(workshopPath, entry.name, "mods", "ChaosMod");
        if (existsSync(modPath)) {
          logger.debug(`Found mod in Steam workshop: ${modPath}`);
          return modPath;
        }
      }
    }
  }
  return null;
}

function autoDetectModFolder(): string | null {
  if (USER_MOD_PATH) {
    logger.debug(`Checking user Zomboid path: ${USER_MOD_PATH}`);
    if (existsSync(USER_MOD_PATH)) {
      saveModFolder(USER_MOD_PATH);
      return USER_MOD_PATH;
    }
  }

  const steamPath = findInSteam();
  if (steamPath) {
    saveModFolder(steamPath);
    return steamPath;
  }

  return null;
}

export function getModFolder(): string | null {
  if (existsSync(MOD_FOLDER_FILE)) {
    const content = readFileSync(MOD_FOLDER_FILE, "utf-8").trim();
    logger.debug(`mod-folder file found, contents: "${content}"`);

    if (content && existsSync(content)) {
      logger.debug(`Mod folder resolved: ${content}`);
      return content;
    }

    if (content) {
      logger.warn(`mod-folder file contains a path that does not exist: "${content}"`);
    }
  } else {
    logger.debug("mod-folder file not found, attempting auto-detection...");
  }

  const detected = autoDetectModFolder();
  if (!detected) {
    logger.warn("Auto-detection failed — mod folder not found. Create a mod-folder file next to the StreamerMode executable.");
  }
  return detected;
}
