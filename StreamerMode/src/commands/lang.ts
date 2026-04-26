import { existsSync, readdirSync } from "fs";
import { join } from "path";
import type { App } from "../cli/App.ts";
import { palette } from "../utils/palette.ts";
import type { ModConfig } from "../config.ts";
import { saveConfig } from "../config.ts";
import { logger } from "../utils/logger.ts";

function getAvailableLanguages(modFolder: string): string[] {
  const langDir = join(modFolder, "common", "lang");
  if (!existsSync(langDir)) return [];
  return readdirSync(langDir)
    .filter((f) => f.endsWith(".json"))
    .map((f) => f.slice(0, -5));
}

export function registerLangCommand(
  app: App,
  modFolder: string,
  config: ModConfig
): void {
  app.registerCommand(
    "lang",
    [],
    [{ name: "language", description: "Language code to switch to (e.g. en, ru)" }],
    (args) => {
      const languages = getAvailableLanguages(modFolder);

      if (args.length === 0) {
        console.log(
          `Current language: ${palette.purple(config.lang)}\n` +
          `Available: ${languages.map((l) => palette.purple(l)).join(", ")}`
        );
        return;
      }

      const target = args[0];
      if (!target) return;

      if (!languages.includes(target)) {
        logger.warn(
          `Language ${palette.orange(target)} not found. ` +
          `Use ${palette.purple("lang")} to see available languages.`
        );
        return;
      }

      config.lang = target;
      saveConfig(modFolder, config);
      logger.info(`Language changed to ${palette.purple(target)}`);
    },
    "Print current language or switch to another (e.g. lang ru)"
  );
}
