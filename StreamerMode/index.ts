import colors from "colors";
import open from "open";
import { writeFileSync } from "fs";
import { join } from "path";
import { networkInterfaces } from "os";
import { App } from "./src/cli/App.ts";
import { logger, setDebugMode } from "./src/utils/logger.ts";
import { getModFolder, STREAMERMODE_ROOT } from "./src/modFolder.ts";
import { setupLuaFolder } from "./src/luaFolder.ts";
import { loadConfig, saveConfig } from "./src/config.ts";
import { registerLangCommand } from "./src/commands/lang.ts";
import { loadEffects } from "./src/effects.ts";
import { startServer } from "./src/server.ts";
import { createProvider, type StreamerUser } from "./src/streamer/index.ts";
import { initLocalization, getString } from "./src/localization.ts";
import { TwitchChat, type ChatEvent } from "./src/streamer/TwitchChat.ts";
import { NicknamesManager } from "./src/streamer/NicknamesManager.ts";
import { VotingManager } from "./src/streamer/VotingManager.ts";
import { startDebugNicknames } from "./src/debugNicknames.ts";
import { startDebugVotes } from "./src/debugVotes.ts";

function getBestLocalIPv4(): { interfaceName: string; address: string; cidr: string | null; mac: string } | null {
  const ifaces = networkInterfaces();
  const badInterfaceName = /loopback|virtual|vmware|vbox|hyper-v|wsl|docker|tailscale|zerotier|vpn/i;
  const candidates: Array<{ interfaceName: string; address: string; cidr: string | null; mac: string }> = [];

  for (const [name, nets] of Object.entries(ifaces)) {
    if (!nets) continue;
    if (badInterfaceName.test(name)) continue;
    for (const net of nets) {
      if (net.family !== "IPv4") continue;
      if (net.internal) continue;
      candidates.push({ interfaceName: name, address: net.address, cidr: net.cidr ?? null, mac: net.mac });
    }
  }

  return (
    candidates.find((x) => x.address.startsWith("192.168.")) ??
    candidates.find((x) => x.address.startsWith("10.")) ??
    candidates.find((x) => /^172\.(1[6-9]|2\d|3[01])\./.test(x.address)) ??
    candidates[0] ??
    null
  );
}

const VERSION = "0.1.0";
const DEFAULT_PORT = 3959;

const KNOWN_ARGS_EXACT = new Set([
  "--version",
  "--debug",
  "--debug-nicknames",
  "--debug-votes",
]);
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
    console.error(
      colors.red(
        `Invalid port "${raw}". Must be an integer between 1 and 65535.`,
      ),
    );
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

function applyLoadedConfig(
  targetConfig: NonNullable<ReturnType<typeof loadConfig>>,
  nextConfig: NonNullable<ReturnType<typeof loadConfig>>,
  modFolder: string,
): void {
  targetConfig.lang = nextConfig.lang;
  targetConfig.effects_enabled = nextConfig.effects_enabled;
  targetConfig.effects_interval = nextConfig.effects_interval;
  targetConfig.vote_start_time = nextConfig.vote_start_time;
  targetConfig.hide_progress_bar = nextConfig.hide_progress_bar;
  targetConfig.use_voting_progress_bar_color = nextConfig.use_voting_progress_bar_color;
  targetConfig.ui = nextConfig.ui;
  targetConfig.ui_sounds_enabled = nextConfig.ui_sounds_enabled;
  targetConfig.ignore_effect_chances = nextConfig.ignore_effect_chances;
  targetConfig.streamer_mode = nextConfig.streamer_mode;

  initLocalization(modFolder, targetConfig.lang);
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  const unknownArgs = args.filter((a) => !isKnownArg(a));
  if (unknownArgs.length > 0) {
    console.error(colors.red(`Unknown argument(s): ${unknownArgs.join(", ")}`));
    console.error(
      colors.gray(
        `Known arguments: ${[...KNOWN_ARGS_EXACT, ...KNOWN_ARGS_PREFIXES.map((p) => `${p}<value>`)].join(", ")}`,
      ),
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

  const luaFolder = setupLuaFolder();
  const dataRoot = luaFolder ?? STREAMERMODE_ROOT;
  const modFolder = getModFolder(dataRoot);
  const config = modFolder ? loadConfig(modFolder) : null;
  const effects = modFolder ? loadEffects(modFolder) : [];

  if (modFolder && config) {
    applyLoadedConfig(config, config, modFolder);
  }

  const useLocalhost = config?.streamer_mode.use_localhost_ip ?? true;
  const host = hostOverride ?? (useLocalhost ? "127.0.0.1" : "0.0.0.0");

  const provider = createProvider(config);

  const nicknamesManager = luaFolder
    ? new NicknamesManager(
        luaFolder,
        config?.streamer_mode.zombie_nicknames_buffer ?? 150,
      )
    : null;
  nicknamesManager?.start();

  if (args.includes("--debug-nicknames")) {
    if (nicknamesManager) {
      startDebugNicknames(nicknamesManager);
    } else {
      logger.warn(
        "--debug-nicknames: nicknames manager not available (no Lua folder).",
      );
    }
  }

  const votingManager = new VotingManager(effects, config, luaFolder);

  if (args.includes("--debug-votes")) {
    startDebugVotes(votingManager);
  }

  function handleChatMessage(chat: ChatEvent): void {
    if (!config?.streamer_mode.streamer_mode_enabled) return;

    if (config.streamer_mode.use_zombie_nicknames && nicknamesManager) {
      nicknamesManager.add(
        chat.chatter_user_login,
        chat.chatter_user_name,
        chat.color,
      );
    }

    if (config.streamer_mode.voting_enabled) {
      const text = chat.message.text.trim();
      let voteNum: number | null = null;

      const direct = Number(text);
      if (Number.isInteger(direct) && text !== "") {
        voteNum = direct;
      }

      if (voteNum === null && config.streamer_mode.allow_vote_command) {
        const parts = text.split(/\s+/);
        if (parts[0]?.toLowerCase() === "!vote" && parts.length === 2) {
          const n = Number(parts[1]);
          if (Number.isInteger(n)) voteNum = n;
        }
      }

      if (voteNum !== null) {
        if (voteNum >= 5 && voteNum <= 8) voteNum -= 4;
        if (voteNum >= 1 && voteNum <= 4) {
          votingManager.addVote(chat.chatter_user_id, voteNum);
        }
      }
    }
  }

  let chat: TwitchChat | null = null;

  function connectChat(token: string, user: StreamerUser): void {
    if (chat) chat.disconnect();
    chat = new TwitchChat({
      accessToken: token,
      broadcasterUserId: user.id,
      readerUserId: user.id,
    });
    chat.onMessage = handleChatMessage;
    chat.connect();
  }

  // Try loading existing token on startup
  let isLoggedIn = false;
  if (provider) {
    const existingToken = await provider.loadToken();
    if (existingToken) {
      const user = await provider.validateToken(existingToken);
      if (user) {
        logger.info(
          `${provider.coloredName} Logged in as ${colors.cyan(user.display_name)}`,
        );
        isLoggedIn = true;
        connectChat(existingToken, user);
      } else {
        logger.debug(`Stored ${provider.name} token is invalid or expired`);
      }
    }
    if (!isLoggedIn) {
      logger.info(
        `${provider.coloredName} Not logged in. Type ${colors.cyan("login")} to get the login URL.`,
      );
    }
  }

  function onLogin(user: StreamerUser, token: string): void {
    if (provider) {
      logger.info(
        `${provider.coloredName} Logged in as ${colors.cyan(user.display_name)}`,
      );
      connectChat(token, user);
    }
    if (config && modFolder) {
      config.streamer_mode.streamer_mode_enabled = true;
      config.streamer_mode.voting_enabled = true;
      saveConfig(modFolder, config);
      logger.info("Streamer mode and voting enabled.");
    }
  }

  function reloadRuntimeConfig(): boolean {
    if (!config || !modFolder) {
      logger.warn("Config not available.");
      return false;
    }

    const nextConfig = loadConfig(modFolder);
    applyLoadedConfig(config, nextConfig, modFolder);
    logger.info(`Config reloaded from ${colors.cyan("config.json")}.`);
    return true;
  }

  const app = new App({
    modFolder,
    luaFolder,
    config,
    effectCount: effects.length,
    onIterationChanged: (votingActive) => {
      votingManager.stop();
      if (votingActive && config?.streamer_mode.voting_enabled) {
        votingManager.start();
      }
    },
    onVotingActiveChanged: (votingActive) => {
      if (votingActive && config?.streamer_mode.voting_enabled) {
        votingManager.start();
      } else {
        votingManager.stop();
      }
    },
  });

  startServer({
    host,
    port,
    provider,
    onLogin,
    getModStatus: () => {
      const watcher = app?.getModSyncWatcher();
      const iterationIndex = watcher?.iterationIndex ?? 0;
      const offset = iterationIndex % 2 !== 0 ? 4 : 0;
      const options = votingManager.displayOptions;
      const totalVotes = options.reduce((sum, o) => sum + o.voters.size, 0);
      return {
        enabled: watcher?.isModEnabled ?? false,
        voting_enabled: votingManager.isActive,
        iteration_index: iterationIndex,
        total_votes: totalVotes,
        total_votes_label: getString("misc", "total_votes"),
        vote_background_color: `#${config?.ui.vote_background_color ?? "9f211f"}`,
        last_winner: votingManager.lastWinnerId,
        vote_options: options.map((opt, i) => ({
          effect_id: opt.id,
          index: i + 1 + offset,
          effect_name: getString("effects", opt.id),
          votes: config?.streamer_mode.hide_votes ? undefined : opt.voters.size,
        })),
        donateEnabled: config?.streamer_mode.enable_donate ?? false,
      };
    },
    getEffectsResponse: () => {
      const donateEnabled = config?.streamer_mode.enable_donate ?? false;
      if (!donateEnabled) {
        return { effects };
      }
      const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
      return {
        effects: effects.map((e) => {
          let price_result: number | null = null;
          if (e.enabled_donate && e.price_group) {
            const group = priceGroups.find((g) => g.group === e.price_group);
            price_result = group ? group.price : null;
          }
          return { ...e, price_result };
        }),
      };
    },
  });

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
    "Open the login URL for the current streaming provider",
  );

  app.registerCommand(
    "logout",
    [],
    [],
    async () => {
      if (!provider) {
        logger.warn("No streamer provider configured.");
        return;
      }
      if (chat) {
        chat.disconnect();
        chat = null;
      }
      const deleted = await provider.deleteToken();
      if (deleted) {
        logger.info(`${provider.coloredName} Logged out.`);
      } else {
        logger.warn("Not logged in.");
      }
    },
    "Log out from the current streaming provider",
  );

  app.registerCommand(
    "obs",
    [],
    [],
    () => {
      const useLocalhost = config?.streamer_mode.use_localhost_ip ?? true;
      const obsHost = !useLocalhost
        ? (getBestLocalIPv4()?.address ?? "127.0.0.1")
        : "127.0.0.1";
      console.log(`Add ${colors.cyan("Browser")} source in OBS Studio.`);
      console.log(`URL = ${colors.cyan(`http://${obsHost}:${port}/obs`)}`);
      console.log(`Width = ${colors.cyan("480px")}`);
      console.log(`Height = ${colors.cyan("300px")}`);
      console.log(
        `Refresh Browser When Scene Becomes Active = ${colors.cyan("On")}`,
      );
      console.log("");
      console.log(
        `Disclaimer: If you have OBS in different PC, you need to set ${colors.cyan("streamer_mode.use_localhost_ip")} to ${colors.cyan("false")}. ` +
          `Then restart Streamer App and use ${colors.cyan("ip")} command to get your local IP, and use it instead of ${colors.cyan("127.0.0.1")}.`,
      );
    },
    "Print OBS Browser source setup instructions",
  );

  app.registerCommand(
    "ip",
    [],
    [],
    () => {
      const result = getBestLocalIPv4();
      if (!result) {
        logger.warn("Could not find a local IPv4 address.");
        return;
      }
      logger.info(`Local IP: ${colors.cyan(result.address)} (${result.interfaceName})`);
    },
    "Print your local IPv4 address",
  );

  app.registerCommand(
    "folder",
    [],
    [],
    async () => {
      if (!modFolder) {
        logger.warn("Mod folder not found.");
        return;
      }
      logger.info(`Mod folder: ${colors.cyan(modFolder)}`);
      await open(modFolder);
    },
    "Open the mod folder in Explorer and print its path",
  );

  app.registerCommand(
    "export",
    [],
    [{ name: "csv", required: true }],
    (args) => {
      if (args[0]?.toLowerCase() !== "csv") {
        logger.warn(`Usage: ${colors.cyan("export csv")}`);
        return;
      }
      if (!luaFolder) {
        logger.warn("Lua folder not available.");
        return;
      }
      const donateEnabled = config?.streamer_mode.enable_donate ?? false;
      const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
      const rows: string[] = ["name,id,enabled,chance(percent),duration,price_group,price"];
      for (const e of effects) {
        const name = getString("effects", e.id).replace(/,/g, "");
        const duration = e.withDuration && e.duration != null ? String(e.duration) : "";
        const group = donateEnabled && e.price_group ? priceGroups.find((g) => g.group === e.price_group) : undefined;
        const priceGroup = donateEnabled ? e.price_group : "";
        const price = donateEnabled && e.enabled_donate && group ? String(group.price) : "";
        rows.push([
          name,
          e.id,
          String(e.enabled),
          String(e.chance),
          duration,
          priceGroup,
          price,
        ].join(","));
      }
      const outputPath = join(luaFolder, "export.csv");
      writeFileSync(outputPath, rows.join("\n"), "utf-8");
      logger.info(`Exported to ${colors.cyan(outputPath)}`);
    },
    "Export effects to a CSV file in the Lua folder",
  );

  app.registerCommand(
    "reload",
    [],
    [],
    () => {
      reloadRuntimeConfig();
    },
    "Reload config from config.json",
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
    "Enable or disable voting",
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
        const current =
          VOTING_MODES[config.streamer_mode.voting_mode] !== undefined
            ? config.streamer_mode.voting_mode
            : 0;
        logger.info(
          `Current voting mode: ${colors.cyan(String(current))} — ${VOTING_MODES[current]}`,
        );
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
      logger.info(
        `Voting mode set to ${colors.cyan(String(val))} — ${VOTING_MODES[val]}`,
      );
    },
    "Show or change the voting mode",
  );

  app.registerCommand(
    "donate_mode",
    [],
    [{ name: "on|off", required: true }],
    (args) => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("donate_mode on|off")}`);
        return;
      }
      config.streamer_mode.enable_donate = val === "on";
      saveConfig(modFolder, config);
      logger.info(`Donate mode ${val === "on" ? "enabled" : "disabled"}.`);
    },
    "Enable or disable donate mode",
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
    "Enable or disable streamer mode",
  );

  if (config) {
    const votingOn = config.streamer_mode.voting_enabled;
    const smOn = config.streamer_mode.streamer_mode_enabled;
    if (!votingOn) {
      logger.info(
        `Voting is disabled. To enable -> ${colors.cyan("voting on")}`,
      );
    }
    if (!smOn) {
      logger.info(
        `Streamer Mode is disabled. To enable -> ${colors.cyan("streamer_mode on")}`,
      );
    }
  }

  await app.start();
}

main().catch((err: unknown) => {
  const message = err instanceof Error ? err.message : String(err);
  console.error(colors.red(`Fatal error: ${message}`));
  process.exit(1);
});
