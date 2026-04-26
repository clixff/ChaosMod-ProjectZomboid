import colors from "colors";
import open from "open";
import { App } from "./src/cli/App.ts";
import { logger, setDebugMode } from "./src/utils/logger.ts";
import { getModFolder, STREAMERMODE_ROOT } from "./src/modFolder.ts";
import { setupLuaFolder } from "./src/luaFolder.ts";
import { loadConfig, saveConfig } from "./src/config.ts";
import { registerLangCommand } from "./src/commands/lang.ts";
import { loadEffects } from "./src/effects.ts";
import { startServer } from "./src/server.ts";
import { createProvider, type StreamerUser } from "./src/streamer/index.ts";
import { TwitchChat } from "./src/streamer/TwitchChat.ts";

const VERSION = "0.1.0";
const DEFAULT_PORT = 3959;

const KNOWN_ARGS_EXACT = new Set(["--version", "--debug"]);
const KNOWN_ARGS_PREFIXES = ["--port=", "--host="];

function isKnownArg(arg: string): boolean {
  if (KNOWN_ARGS_EXACT.has(arg)) return true;
  return KNOWN_ARGS_PREFIXES.some((p) => arg.startsWith(p));
}

function printVersion(): void {
  console.log(`ChaosMod Streamer Mode v${VERSION}`);
}

function parsePortArg(args: string[]): number {
  const portArg = args.find((a) => a.startsWith("--port="));
  if (!portArg) return DEFAULT_PORT;
  const raw = portArg.slice("--port=".length);
  const val = parseInt(raw, 10);
  if (!Number.isInteger(val) || val < 1 || val > 65535) {
    console.error(colors.red(`Invalid port "${raw}". Must be an integer between 1 and 65535.`));
    process.exit(1);
  }
  return val;
}

function parseHostArg(args: string[]): string | null {
  const hostArg = args.find((a) => a.startsWith("--host="));
  if (!hostArg) return null;
  const val = hostArg.slice("--host=".length);
  if (!val) {
    console.error(colors.red(`--host value cannot be empty.`));
    process.exit(1);
  }
  return val;
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  const unknownArgs = args.filter((a) => !isKnownArg(a));
  if (unknownArgs.length > 0) {
    console.error(
      colors.red(`Unknown argument(s): ${unknownArgs.join(", ")}`)
    );
    console.error(
      colors.gray(
        `Known arguments: ${[...KNOWN_ARGS_EXACT, ...KNOWN_ARGS_PREFIXES.map((p) => `${p}<value>`)].join(", ")}`
      )
    );
    process.exit(1);
  }

  if (args.includes("--version")) {
    printVersion();
    return;
  }

  if (args.includes("--debug")) {
    setDebugMode(true);
    logger.debug("Debug mode enabled");
  }

  const port = parsePortArg(args);
  const hostOverride = parseHostArg(args);

  const modFolder = getModFolder();
  const luaFolder = setupLuaFolder();
  const config = modFolder ? loadConfig(modFolder) : null;
  const effects = modFolder ? loadEffects(modFolder) : [];

  const useLocalhost = config?.streamer_mode.use_localhost_ip ?? true;
  const host = hostOverride ?? (useLocalhost ? "127.0.0.1" : "0.0.0.0");

  const provider = createProvider(config);

  let chat: TwitchChat | null = null;

  function connectChat(token: string, user: StreamerUser): void {
    if (chat) chat.disconnect();
    chat = new TwitchChat({ accessToken: token, broadcasterUserId: user.id, readerUserId: user.id });
    chat.connect();
  }

  // Try loading existing token on startup
  let isLoggedIn = false;
  if (provider) {
    const existingToken = provider.loadToken(STREAMERMODE_ROOT);
    if (existingToken) {
      const user = await provider.validateToken(existingToken);
      if (user) {
        logger.info(`${provider.coloredName} Logged in as ${colors.cyan(user.display_name)}`);
        isLoggedIn = true;
        connectChat(existingToken, user);
      } else {
        logger.debug(`Stored ${provider.name} token is invalid or expired`);
      }
    }
    if (!isLoggedIn) {
      logger.info(`${provider.coloredName} Not logged in. Type ${colors.cyan("login")} to get the login URL.`);
    }
  }

  function onLogin(user: StreamerUser): void {
    if (provider) {
      logger.info(`${provider.coloredName} Logged in as ${colors.cyan(user.display_name)}`);
      const token = provider.loadToken(STREAMERMODE_ROOT);
      if (token) connectChat(token, user);
    }
    if (config && modFolder) {
      config.streamer_mode.streamer_mode_enabled = true;
      config.streamer_mode.voting_enabled = true;
      saveConfig(modFolder, config);
      logger.info("Streamer mode and voting enabled.");
    }
  }

  startServer({ host, port, provider, streamerModeRoot: STREAMERMODE_ROOT, onLogin });

  const app = new App({ modFolder, luaFolder, config, effectCount: effects.length });

  if (modFolder && config) {
    registerLangCommand(app, modFolder, config);
  }

  app.registerCommand(
    "login",
    [],
    [],
    async () => {
      if (!provider) {
        logger.warn("No streamer provider configured.");
        return;
      }
      const loginUrl = `http://localhost:${port}/login/${provider.key}`;
      logger.info(`Opening login URL: ${colors.cyan(loginUrl)}`);
      await open(loginUrl);
    },
    "Open the login URL for the current streaming provider"
  );

  app.registerCommand(
    "logout",
    [],
    [],
    () => {
      if (!provider) {
        logger.warn("No streamer provider configured.");
        return;
      }
      if (chat) { chat.disconnect(); chat = null; }
      const deleted = provider.deleteToken(STREAMERMODE_ROOT);
      if (deleted) {
        logger.info(`${provider.coloredName} Logged out.`);
      } else {
        logger.warn("Not logged in.");
      }
    },
    "Log out from the current streaming provider"
  );

  app.registerCommand(
    "voting",
    [],
    [{ name: "on|off", required: true }],
    (args) => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("voting on|off")}`);
        return;
      }
      config.streamer_mode.voting_enabled = val === "on";
      saveConfig(modFolder, config);
      logger.info(`Voting ${val === "on" ? "enabled" : "disabled"}.`);
    },
    "Enable or disable voting"
  );

  const VOTING_MODES: Record<number, string> = {
    0: "Most Votes — the option with the highest vote count wins.",
    1: "Weighted Random — one option is picked randomly, but options with more votes have a higher chance to win.",
  };

  app.registerCommand(
    "voting_mode",
    [],
    [{ name: "0|1" }],
    (args) => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }

      if (args.length === 0) {
        const current = VOTING_MODES[config.streamer_mode.voting_mode] !== undefined
          ? config.streamer_mode.voting_mode
          : 0;
        logger.info(`Current voting mode: ${colors.cyan(String(current))} — ${VOTING_MODES[current]}`);
        logger.info("Available modes:");
        for (const [key, desc] of Object.entries(VOTING_MODES)) {
          logger.info(`  ${colors.cyan(key)} — ${desc}`);
        }
        return;
      }

      const val = parseInt(args[0] ?? "", 10);
      if (val !== 0 && val !== 1) {
        logger.warn(`Usage: ${colors.cyan("voting_mode 0|1")}`);
        return;
      }
      config.streamer_mode.voting_mode = val;
      saveConfig(modFolder, config);
      logger.info(`Voting mode set to ${colors.cyan(String(val))} — ${VOTING_MODES[val]}`);
    },
    "Show or change the voting mode"
  );

  app.registerCommand(
    "streamer_mode",
    [],
    [{ name: "on|off", required: true }],
    (args) => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("streamer_mode on|off")}`);
        return;
      }
      config.streamer_mode.streamer_mode_enabled = val === "on";
      saveConfig(modFolder, config);
      logger.info(`Streamer Mode ${val === "on" ? "enabled" : "disabled"}.`);
    },
    "Enable or disable streamer mode"
  );

  if (config) {
    const votingOn = config.streamer_mode.voting_enabled;
    const smOn = config.streamer_mode.streamer_mode_enabled;
    logger.info(
      `Voting is ${votingOn ? "enabled" : "disabled"}. To ${votingOn ? "disable" : "enable"} -> ${colors.cyan(`voting ${votingOn ? "off" : "on"}`)}`
    );
    logger.info(
      `Streamer Mode is ${smOn ? "enabled" : "disabled"}. To ${smOn ? "disable" : "enable"} -> ${colors.cyan(`streamer_mode ${smOn ? "off" : "on"}`)}`
    );
  }

  await app.start();
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(colors.red(`Fatal error: ${message}`));
  process.exit(1);
});
