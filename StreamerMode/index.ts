import colors from "colors";
import open from "open";
import { writeFileSync } from "fs";
import { join } from "path";
import { networkInterfaces } from "os";
import { spawnSync } from "child_process";
import readline from "readline/promises";
import { stdin as input, stdout as output } from "process";
import { App } from "./src/cli/App.ts";
import { logger, setDebugMode } from "./src/utils/logger.ts";
import {
  getModFolder,
  isValidModFolderPath,
  persistModFolder,
  STREAMERMODE_ROOT,
} from "./src/modFolder.ts";
import { setupLuaFolder } from "./src/luaFolder.ts";
import {
  loadConfig,
  resetConfigToDefaultsPreservingUnknowns,
  saveConfig,
} from "./src/config.ts";
import { registerLangCommand } from "./src/commands/lang.ts";
import { loadEffects } from "./src/effects.ts";
import { startServer } from "./src/server.ts";
import { createProvider, type StreamerUser } from "./src/streamer/index.ts";
import { initLocalization, getString } from "./src/localization.ts";
import { TwitchChat, type ChatEvent } from "./src/streamer/TwitchChat.ts";
import { NicknamesManager } from "./src/streamer/NicknamesManager.ts";
import { VotingManager } from "./src/streamer/VotingManager.ts";
import {
  startDebugChatMessages,
  startDebugNicknames,
} from "./src/debugNicknames.ts";
import { startDebugVotes } from "./src/debugVotes.ts";
import { ExternalEffectsManager } from "./src/externalEffects.ts";
import { DonationAlertsProvider } from "./src/donationalerts/DonationAlertsProvider.ts";
import { DonationManager } from "./src/donations/DonationManager.ts";
import { registerDonateCommand } from "./src/commands/donate.ts";
import type { EffectEntry } from "./src/effects.ts";

function getBestLocalIPv4(): {
  interfaceName: string;
  address: string;
  cidr: string | null;
  mac: string;
} | null {
  const ifaces = networkInterfaces();
  const badInterfaceName =
    /loopback|virtual|vmware|vbox|hyper-v|wsl|docker|tailscale|zerotier|vpn/i;
  const candidates: Array<{
    interfaceName: string;
    address: string;
    cidr: string | null;
    mac: string;
  }> = [];

  for (const [name, nets] of Object.entries(ifaces)) {
    if (!nets) continue;
    if (badInterfaceName.test(name)) continue;
    for (const net of nets) {
      if (net.family !== "IPv4") continue;
      if (net.internal) continue;
      candidates.push({
        interfaceName: name,
        address: net.address,
        cidr: net.cidr ?? null,
        mac: net.mac,
      });
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

const VERSION = "1.0.2";
const DEFAULT_PORT = 3959;

type EffectResponseEntry = Omit<EffectEntry, "id"> & {
  id: number;
  effect_id: string;
  price_group: string;
  price_result: number | null;
};

function buildEffectResponseEntry(
  effectIndex: number,
  effect: EffectEntry,
  priceGroups: Array<{ group: string; price: number }>,
): EffectResponseEntry {
  if (!effect.enabled_donate) {
    return {
      ...effect,
      id: effectIndex + 1,
      effect_id: effect.id,
      price_group: "",
      price_result: null,
    };
  }

  const group = effect.price_group
    ? priceGroups.find((entry) => entry.group === effect.price_group)
    : undefined;

  return {
    ...effect,
    id: effectIndex + 1,
    effect_id: effect.id,
    price_group: effect.price_group,
    price_result: group ? group.price : null,
  };
}

function resolveEffectIdentifier(
  rawEffectId: string,
  effects: EffectEntry[],
): EffectEntry | null {
  const trimmed = rawEffectId.trim();
  if (!trimmed) {
    return null;
  }

  const byStringId = effects.find((entry) => entry.id === trimmed);
  if (byStringId) {
    return byStringId;
  }

  if (!/^\d+$/.test(trimmed)) {
    return null;
  }

  const numericId = Number.parseInt(trimmed, 10);
  if (
    !Number.isInteger(numericId) ||
    numericId < 1 ||
    numericId > effects.length
  ) {
    return null;
  }

  return effects[numericId - 1] ?? null;
}

const KNOWN_ARGS_EXACT = new Set([
  "--version",
  "--debug",
  "--debug-chat-messages",
  "--debug-nicknames",
  "--debug-votes",
]);
const KNOWN_ARGS_PREFIXES = ["--port=", "--host="];
let fatalExitInProgress = false;

function isKnownArg(arg: string): boolean {
  if (KNOWN_ARGS_EXACT.has(arg)) return true;
  return KNOWN_ARGS_PREFIXES.some((p) => arg.startsWith(p));
}

function printVersion(): void {
  console.log(`ChaosMod Streamer Mode v${VERSION}`);
}

async function pauseBeforeExitOnError(): Promise<void> {
  if (process.platform === "win32") {
    try {
      spawnSync("cmd.exe", ["/c", "pause"], {
        stdio: "inherit",
        windowsHide: false,
      });
      return;
    } catch {
      // Fall through to readline-based pause.
    }
  }

  if (!input.isTTY || !output.isTTY) {
    return;
  }

  const rl = readline.createInterface({ input, output });
  try {
    await rl.question(colors.gray("Press Enter to close... "));
  } catch {
    // Ignore prompt errors during shutdown.
  } finally {
    rl.close();
  }
}

async function handleFatalError(err: unknown): Promise<never> {
  if (fatalExitInProgress) {
    process.exit(1);
  }
  fatalExitInProgress = true;

  const message =
    err instanceof Error ? (err.stack ?? err.message) : String(err);
  console.error(colors.red(`Fatal error: ${message}`));
  await pauseBeforeExitOnError();
  process.exit(1);
}

function parsePortArg(args: string[]): number {
  const portArg = args.find((a) => a.startsWith("--port="));
  if (!portArg) return DEFAULT_PORT;
  const raw = portArg.slice("--port=".length);
  const val = parseInt(raw, 10);
  if (!Number.isInteger(val) || val < 1 || val > 65535) {
    throw new Error(
      `Invalid port "${raw}". Must be an integer between 1 and 65535.`,
    );
  }
  return val;
}

function parseHostArg(args: string[]): string | null {
  const hostArg = args.find((a) => a.startsWith("--host="));
  if (!hostArg) return null;
  const val = hostArg.slice("--host=".length);
  if (!val) {
    throw new Error(`--host value cannot be empty.`);
  }
  return val;
}

function applyLoadedConfig(
  targetConfig: NonNullable<ReturnType<typeof loadConfig>>,
  nextConfig: NonNullable<ReturnType<typeof loadConfig>>,
  modFolder: string,
): void {
  targetConfig.lang = nextConfig.lang;
  targetConfig.effects_interval_enabled = nextConfig.effects_interval_enabled;
  targetConfig.effects_interval = nextConfig.effects_interval;
  targetConfig.vote_start_time = nextConfig.vote_start_time;
  targetConfig.hide_progress_bar = nextConfig.hide_progress_bar;
  targetConfig.use_voting_progress_bar_color =
    nextConfig.use_voting_progress_bar_color;
  targetConfig.ui = nextConfig.ui;
  targetConfig.ui_sounds_enabled = nextConfig.ui_sounds_enabled;
  targetConfig.ignore_effect_chances = nextConfig.ignore_effect_chances;
  targetConfig.streamer_mode = nextConfig.streamer_mode;

  initLocalization(modFolder, targetConfig.lang);
}

async function promptForModFolder(dataRoot: string): Promise<string> {
  const rl = readline.createInterface({ input, output });

  try {
    logger.warn("Auto-detection failed — mod folder not found.");
    logger.info("Enter the full path to the ChaosMod mod folder.");

    while (true) {
      const answer = (await rl.question("Mod folder path: ")).trim();
      if (!answer) {
        logger.warn("Mod folder path cannot be empty.");
        continue;
      }

      if (!isValidModFolderPath(answer)) {
        logger.warn(
          `Invalid mod folder path. Expected a ChaosMod folder containing ${colors.cyan("common/config.json")} and ${colors.cyan("common/effects.json")}.`,
        );
        continue;
      }

      const savedPath = persistModFolder(dataRoot, answer);
      if (!savedPath) {
        logger.warn("Failed to save mod folder path.");
        continue;
      }

      logger.info(`Mod folder saved: ${colors.cyan(savedPath)}`);
      return savedPath;
    }
  } finally {
    rl.close();
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  const unknownArgs = args.filter((a) => !isKnownArg(a));
  if (unknownArgs.length > 0) {
    throw new Error(
      `Unknown argument(s): ${unknownArgs.join(", ")}\nKnown arguments: ${[...KNOWN_ARGS_EXACT, ...KNOWN_ARGS_PREFIXES.map((p) => `${p}<value>`)].join(", ")}`,
    );
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
  let modFolder = getModFolder(dataRoot);
  if (!modFolder) {
    modFolder = await promptForModFolder(dataRoot);
  }
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
        config?.streamer_mode.render_chat_messages ?? true,
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

  if (args.includes("--debug-chat-messages")) {
    if (nicknamesManager) {
      startDebugChatMessages(nicknamesManager);
    } else {
      logger.warn(
        "--debug-chat-messages: nicknames manager not available (no Lua folder).",
      );
    }
  }

  const votingManager = new VotingManager(effects, config, luaFolder);

  const externalEffectsManager = luaFolder
    ? new ExternalEffectsManager(luaFolder)
    : null;
  externalEffectsManager?.start();

  const daProvider = new DonationAlertsProvider();
  const donationManager = new DonationManager(port);
  donationManager.addProvider(daProvider);

  // Auto-login donation providers on startup
  const daUser = await daProvider.start(port);
  if (daUser) {
    logger.info(
      `[DonationProvider] ${daProvider.coloredName} Logged in as ${colors.cyan(daUser.name)}`,
    );
  } else {
    const daCreds = await daProvider.loadCredentials();
    if (daCreds) {
      logger.info(
        `${daProvider.coloredName} Not logged in. Type ${colors.cyan("donate login donationalerts")} to authenticate.`,
      );
    }
  }

  if (args.includes("--debug-votes")) {
    startDebugVotes(votingManager);
  }

  function handleChatMessage(chat: ChatEvent): void {
    if (!config?.streamer_mode.streamer_mode_enabled) return;

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

    if (config.streamer_mode.use_zombie_nicknames && nicknamesManager) {
      const sanitizedMessage =
        config.streamer_mode.render_chat_messages && voteNum === null
          ? text.replace(/\\n/g, "").replace(/\r?\n/g, "")
          : undefined;

      nicknamesManager.add(
        chat.chatter_user_login,
        chat.chatter_user_name,
        chat.color,
        sanitizedMessage,
        chat.timestamp_ms,
      );
    }

    if (config.streamer_mode.voting_enabled) {
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
    const nextEffects = loadEffects(modFolder);
    applyLoadedConfig(config, nextConfig, modFolder);
    nicknamesManager?.setRenderChatMessages(
      config.streamer_mode.render_chat_messages,
    );
    effects.splice(0, effects.length, ...nextEffects);
    logger.info(
      `Reloaded ${colors.cyan("config.json")} and ${colors.cyan("effects.json")} (${colors.cyan(String(effects.length))} effects).`,
    );
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

  function buildServerCtx(serverHost: string) {
    return {
      host: serverHost,
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
    onDonationAlertsCode: async (code) => {
      const user = await daProvider.handleOAuthCode(code, port);
      if (user) {
        logger.info(
          `[DonationProvider] ${daProvider.coloredName} Logged in as ${colors.cyan(user.name)}`,
        );
      }
      return user ? { name: user.name } : null;
    },
    activateEffect: (nickname, effectId) => {
      if (
        !config?.streamer_mode.streamer_mode_enabled ||
        !config?.streamer_mode.enable_donate
      ) {
        return { success: false, error: "Not available" };
      }
      const effect = resolveEffectIdentifier(effectId, effects);
      if (!effect?.enabled_donate) {
        return {
          success: false,
          error: "Effect is not available for donations",
        };
      }
      if (!externalEffectsManager) {
        return { success: false, error: "Lua folder not available" };
      }
      externalEffectsManager.add(nickname ?? "", effectId);
      return { success: true };
    },
    getEffectsResponse: () => {
      const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
      return {
        effects: effects.map((e, index) =>
          buildEffectResponseEntry(index, e, priceGroups),
        ),
      };
    },
    };
  }

  let activeServer = startServer(buildServerCtx(host));

  if (modFolder && config) {
    registerLangCommand(app, modFolder, config);
  }

  registerDonateCommand(app, port, daProvider, modFolder, config);

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
      if (useLocalhost) {
        console.log("");
        console.log(
          `Disclaimer: If you have OBS on a different PC, run ${colors.cyan("use_localhost_ip off")} and then ${colors.cyan("obs")} again to get the LAN URL.`,
        );
      }
    },
    "Print OBS Browser source setup instructions",
  );

  app.registerCommand(
    "use_localhost_ip",
    [],
    [{ name: "on|off", required: true }],
    (args) => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("use_localhost_ip on|off")}`);
        return;
      }
      const useLocalhostNew = val === "on";
      config.streamer_mode.use_localhost_ip = useLocalhostNew;
      saveConfig(modFolder, config);

      const newHost = hostOverride ?? (useLocalhostNew ? "127.0.0.1" : "0.0.0.0");
      activeServer.stop(true);
      activeServer = startServer(buildServerCtx(newHost));
      logger.info(
        `use_localhost_ip set to ${colors.cyan(val)}. Server restarted on ${colors.cyan(`http://${newHost}:${port}`)}.`,
      );
    },
    "Set whether the server binds to localhost only (on) or all interfaces (off), and restart the server",
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
      logger.info(
        `Local IP: ${colors.cyan(result.address)} (${result.interfaceName})`,
      );
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
      const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
      const rows: string[] = [
        "id,name,effect_id,enabled,chance,duration,price_group,price",
      ];
      for (const [index, e] of effects.entries()) {
        const effect = buildEffectResponseEntry(index, e, priceGroups);
        const name = getString("effects", e.id).replace(/,/g, "");
        const duration =
          e.withDuration && e.duration != null ? String(e.duration) : "";
        rows.push(
          [
            String(effect.id),
            name,
            effect.effect_id,
            String(e.enabled),
            `${e.chance}%`,
            duration,
            effect.price_group,
            effect.price_result != null ? String(effect.price_result) : "",
          ].join(","),
        );
      }
      const outputPath = join(luaFolder, "export.csv");
      writeFileSync(outputPath, rows.join("\n"), "utf-8");
      logger.info(`Exported to ${colors.cyan(outputPath)}`);
      console.log("");
      logger.info(colors.bold("Google Sheets:"));
      logger.info(
        `1. Open ${colors.cyan("https://docs.google.com/spreadsheets/")}.`,
      );
      logger.info(
        `2. Press ${colors.green("Plus")} to create a new spreadsheet.`,
      );
      logger.info(`3. Open ${colors.yellow("File -> Import -> Upload")}.`);
      logger.info(`4. Upload ${colors.cyan(outputPath)}.`);
      logger.info(`5. Open ${colors.yellow("Format -> Convert to table")}.`);
      logger.info(
        `6. Open ${colors.green("Share")} in the top-right corner, then set ${colors.yellow("General access -> Anyone with the link -> Viewer")}.`,
      );
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
    "Reload config and effects from config.json and effects.json",
  );

  app.registerCommand(
    "default_config",
    [],
    [],
    () => {
      if (!config || !modFolder) {
        logger.warn("Config not available.");
        return;
      }

      const nextConfig = resetConfigToDefaultsPreservingUnknowns(modFolder);
      if (!nextConfig) {
        logger.warn("Failed to reset config.");
        return;
      }

      applyLoadedConfig(config, nextConfig, modFolder);
      logger.info(
        `Config reset to defaults, backup saved as ${colors.cyan("config_backup.json")}. Unknown custom fields were preserved.`,
      );
    },
    "Reset config.json to typed defaults and create config_backup.json",
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

process.on("uncaughtException", (err) => {
  void handleFatalError(err);
});

process.on("unhandledRejection", (reason) => {
  void handleFatalError(reason);
});

main().catch((err: unknown) => {
  void handleFatalError(err);
});
