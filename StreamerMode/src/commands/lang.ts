import { existsSync, readdirSync } from "fs";
import { join } from "path";
import type { App } from "../cli/App.ts";
import type { ModConfig } from "../config.ts";
import { saveConfig } from "../config.ts";
import { logger } from "../utils/logger.ts";
import { setLang } from "../localization.ts";
import colors from "colors";

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
  luaFolder: string,
  config: ModConfig,
): void {
  app.registerCommand(
    "lang",
    [],
    [
      {
        name: "language",
        description: "Language code to switch to (e.g. en, ru)",
      },
    ],
    (args) => {
      const languages = getAvailableLanguages(modFolder);

      if (args.length === 0) {
        console.log(
          `Current language: ${colors.cyan(config.lang)}\n` +
            `Available: ${languages.map((l) => colors.cyan(l)).join(", ")}`,
        );
        return;
      }

      const target = args[0];
      if (!target) return;

      if (!languages.includes(target)) {
        logger.warn(
          `Language ${colors.yellow(target)} not found. ` +
            `Use ${colors.cyan("lang")} to see available languages.`,
        );
        return;
      }

      config.lang = target;
      saveConfig(luaFolder, config);
      setLang(target);
      logger.info(`Language changed to ${colors.cyan(target)}`);
    },
    "Print current language or switch to another (e.g. lang ru)",
  );
}
