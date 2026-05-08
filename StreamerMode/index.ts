import colors from "colors";
import open from "open";
import { existsSync, statSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";
import { networkInterfaces } from "os";
import { spawnSync, spawn } from "child_process";
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
import {
  registerLangCommand,
  getAvailableLanguages,
} from "./src/commands/lang.ts";
import { loadEffects, saveEffects } from "./src/effects.ts";
import { setRecentEffectsMax } from "./src/effectsRegistry.ts";
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
import { Bridge } from "./src/bridge/Bridge.ts";
import { DonationAlertsProvider } from "./src/donationalerts/DonationAlertsProvider.ts";
import { DonationManager } from "./src/donations/DonationManager.ts";
import { registerDonateCommand } from "./src/commands/donate.ts";
import type { EffectEntry } from "./src/effects.ts";
import { ActivityLog } from "./src/activityLog.ts";
import {
  buildStatus as buildVersionStatus,
  fetchLatestVersion,
  RELEASES_URL,
  type VersionStatus,
} from "./src/versionCheck.ts";

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

const VERSION = "1.1.0";
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

// Open the dashboard at most once per "session". Bun's --watch reruns the
// script on file changes, so a naive call would reopen a tab on every save.
// We stamp a per-port lockfile in the OS temp dir; a fresh stamp means the
// dashboard was already auto-opened recently — skip until it ages out.
const DASHBOARD_OPEN_TTL_MS = 60_000;

function dashboardLockPath(port: number): string {
  return join(tmpdir(), `chaosmod-streamer-dashboard-${port}.lock`);
}

function shouldOpenDashboard(port: number): boolean {
  const lockPath = dashboardLockPath(port);
  try {
    if (existsSync(lockPath)) {
      const ageMs = Date.now() - statSync(lockPath).mtimeMs;
      if (ageMs < DASHBOARD_OPEN_TTL_MS) {
        return false;
      }
    }
  } catch {
    // Ignore — fall through and try to open + restamp.
  }
  try {
    writeFileSync(lockPath, String(Date.now()), "utf-8");
  } catch {
    // If we can't write the stamp, still open it; worst case is reopen on next reload.
  }
  return true;
}

function revealInExplorer(filePath: string): void {
  try {
    if (process.platform === "win32") {
      Bun.spawn({
        cmd: ["explorer.exe", `/select,${filePath}`],
        detached: true,
        stdout: "ignore",
        stderr: "ignore",
        stdin: "ignore",
      }).unref();
    } else if (process.platform === "darwin") {
      spawn("open", ["-R", filePath], {
        detached: true,
        stdio: "ignore",
      }).unref();
    } else {
      const dir = filePath.replace(/[\\/][^\\/]*$/, "");
      spawn("xdg-open", [dir], { detached: true, stdio: "ignore" }).unref();
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.debug(`revealInExplorer failed: ${msg}`);
  }
}

function isPlainObj(val: unknown): val is Record<string, unknown> {
  return val !== null && typeof val === "object" && !Array.isArray(val);
}

function deepMergeInto(
  target: Record<string, unknown>,
  patch: Record<string, unknown>,
): void {
  for (const [key, value] of Object.entries(patch)) {
    const existing = target[key];
    if (isPlainObj(existing) && isPlainObj(value)) {
      deepMergeInto(existing, value);
    } else {
      target[key] = value;
    }
  }
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
  targetConfig.effects_duration_multiplier =
    nextConfig.effects_duration_multiplier;
  targetConfig.recent_effects_block_buffer =
    nextConfig.recent_effects_block_buffer;

  setRecentEffectsMax(targetConfig.recent_effects_block_buffer);

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
          `Invalid mod folder path. Expected a ChaosMod folder containing ${colors.cyan("common/default_config.json")} and ${colors.cyan("common/default_effects.json")}.`,
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
  const config =
    modFolder && luaFolder ? loadConfig(modFolder, luaFolder) : null;
  const effects =
    modFolder && luaFolder ? loadEffects(modFolder, luaFolder) : [];

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

  const votingManager = new VotingManager(effects, config);
  const activityLog = new ActivityLog();

  let versionStatus: VersionStatus = buildVersionStatus(VERSION, null);
  void fetchLatestVersion().then((latest) => {
    versionStatus = buildVersionStatus(VERSION, latest);
    if (versionStatus.update_available && latest) {
      logger.info(
        `${colors.yellow(`New version v${latest} is available.`)} Download: ${colors.cyan(RELEASES_URL)}`,
      );
    }
  });

  const bridge = luaFolder ? new Bridge(luaFolder) : null;
  let modEnabled = false;
  let iterationIndex = 0;

  if (bridge) {
    bridge.on("mod_change_status", (payload) => {
      const enabled = payload.enabled === true;
      modEnabled = enabled;
      logger.debug(`[Bridge] mod_change_status: enabled=${enabled}`);
      if (!enabled) {
        votingManager.stop();
        bridge.rotateOutbound();
      }
    });

    bridge.on("interval_start", (payload) => {
      const iter =
        typeof payload.iteration === "number" ? payload.iteration : 0;
      iterationIndex = iter;
      logger.debug(`[Bridge] interval_start: iteration=${iter}`);
      if (votingManager.isActive) {
        votingManager.stop();
        const winnerEffectId = votingManager.lastWinnerEffectId;
        if (winnerEffectId) {
          bridge.emit("activate_effects", {
            effects: [{ id: winnerEffectId, type: "vote" }],
          });
          activityLog.add({
            type: "vote",
            effect_id: winnerEffectId,
            effect_name: getString("effects", winnerEffectId),
          });
        }
      }
    });

    bridge.on("vote_start", () => {
      logger.debug("[Bridge] vote_start");
      if (config?.streamer_mode.voting_enabled) {
        votingManager.start();
      }
    });

    bridge.on("reload_config", () => {
      logger.debug("[Bridge] reload_config");
      reloadRuntimeConfig();
    });

    bridge.start();
  }

  const daProvider = new DonationAlertsProvider();
  daProvider.onConnect = () => {
    activityLog.add({ type: "donationalerts_connected" });
  };
  daProvider.onDisconnect = () => {
    activityLog.add({ type: "donationalerts_disconnected" });
  };
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
        const n = config.streamer_mode.voting_options_number;
        if (voteNum >= n + 1 && voteNum <= 2 * n) voteNum -= n;
        if (voteNum >= 1 && voteNum <= n) {
          votingManager.addVote(chat.chatter_user_id, voteNum);
        }
      }
    }
  }

  let chat: TwitchChat | null = null;
  let twitchUser: StreamerUser | null = null;
  let chatConnected = false;

  function connectChat(token: string, user: StreamerUser): void {
    if (chat) chat.disconnect();
    twitchUser = user;
    chat = new TwitchChat({
      accessToken: token,
      broadcasterUserId: user.id,
      readerUserId: user.id,
    });
    chat.onMessage = handleChatMessage;
    chat.onConnect = () => {
      chatConnected = true;
      activityLog.add({ type: "chat_connected" });
    };
    chat.onDisconnect = () => {
      chatConnected = false;
      activityLog.add({ type: "chat_disconnected" });
    };
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
    if (config && luaFolder) {
      config.streamer_mode.streamer_mode_enabled = true;
      config.streamer_mode.voting_enabled = true;
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
      logger.info("Streamer mode and voting enabled.");
    }
  }

  function reloadRuntimeConfig(): boolean {
    if (!config || !modFolder || !luaFolder) {
      logger.warn("Config not available.");
      return false;
    }

    const nextConfig = loadConfig(modFolder, luaFolder);
    const nextEffects = loadEffects(modFolder, luaFolder);
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
    onShutdown: () => {
      bridge?.stop();
    },
  });

  function buildServerCtx(serverHost: string) {
    return {
      host: serverHost,
      port,
      provider,
      onLogin,
      getModStatus: () => {
        const optionsCount = config?.streamer_mode.voting_options_number ?? 4;
        const offset = iterationIndex % 2 !== 0 ? optionsCount : 0;
        const options = votingManager.displayOptions;
        const totalVotes = options.reduce((sum, o) => sum + o.voters.size, 0);
        return {
          enabled: modEnabled,
          voting_enabled: votingManager.isActive,
          iteration_index: iterationIndex,
          total_votes: totalVotes,
          total_votes_label: getString("misc", "total_votes"),
          vote_background_color: `#${config?.ui.vote_background_color ?? "9f211f"}`,
          last_winner: votingManager.lastWinnerId,
          vote_options: options.map((opt, i) => {
            const isRandom = opt.id === "random_effect";
            const revealSecret = isRandom && !votingManager.isActive;
            const secretId = votingManager.secretRandomEffectId;
            const effectName =
              revealSecret && secretId
                ? getString("effects", secretId)
                : getString("effects", opt.id);
            return {
              effect_id: opt.id,
              index: i + 1 + offset,
              effect_name: effectName,
              votes: config?.streamer_mode.hide_votes
                ? undefined
                : opt.voters.size,
              hidden: isRandom && votingManager.isActive,
            };
          }),
          donateEnabled: config?.streamer_mode.enable_donate ?? false,
        };
      },
      onDonationAlertsCode: async (code: string) => {
        const user = await daProvider.handleOAuthCode(code, port);
        if (user) {
          logger.info(
            `[DonationProvider] ${daProvider.coloredName} Logged in as ${colors.cyan(user.name)}`,
          );
          if (config && luaFolder && !config.streamer_mode.enable_donate) {
            config.streamer_mode.enable_donate = true;
            saveConfig(luaFolder, config);
            bridge?.emit("reload_config");
            logger.info("Donate mode enabled.");
          }
        }
        return user ? { name: user.name } : null;
      },
      activateEffect: (nickname: string | undefined, effectId: string) => {
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
        if (!bridge) {
          return { success: false, error: "Lua folder not available" };
        }
        bridge.emit("activate_effects", {
          effects: [
            {
              id: effect.id,
              type: "donate",
              nickname: nickname ?? "",
            },
          ],
        });
        const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
        const groupEntry = effect.price_group
          ? priceGroups.find((entry) => entry.group === effect.price_group)
          : undefined;
        activityLog.add({
          type: "donate",
          effect_id: effect.id,
          effect_name: getString("effects", effect.id),
          nickname: nickname ?? "",
          price: groupEntry ? groupEntry.price : null,
          price_group: effect.price_group ?? "",
        });
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
      getConfig: () => config,
      updateConfig: (patch: unknown) => {
        if (!config || !luaFolder) {
          return { success: false, error: "Config not available" };
        }
        if (
          patch === null ||
          typeof patch !== "object" ||
          Array.isArray(patch)
        ) {
          return { success: false, error: "Patch must be an object" };
        }
        const previousUseLocalhost = config.streamer_mode.use_localhost_ip;
        deepMergeInto(
          config as unknown as Record<string, unknown>,
          patch as Record<string, unknown>,
        );
        saveConfig(luaFolder, config);
        if (modFolder) {
          initLocalization(modFolder, config.lang);
        }
        nicknamesManager?.setRenderChatMessages(
          config.streamer_mode.render_chat_messages,
        );
        bridge?.emit("reload_config");
        if (config.streamer_mode.use_localhost_ip !== previousUseLocalhost) {
          restartServerForLocalhostChange();
        }
        return { success: true };
      },
      getEffectsList: () => {
        return effects.map((e) => ({ ...e, name: getString("effects", e.id) }));
      },
      updateEffect: (id: string, patch: unknown) => {
        if (!luaFolder) {
          return { success: false, error: "Lua folder not available" };
        }
        if (
          patch === null ||
          typeof patch !== "object" ||
          Array.isArray(patch)
        ) {
          return { success: false, error: "Patch must be an object" };
        }
        const target = effects.find((e) => e.id === id);
        if (!target) {
          return { success: false, error: `Effect '${id}' not found` };
        }
        const p = patch as Record<string, unknown>;
        if (typeof p["enabled"] === "boolean") target.enabled = p["enabled"];
        if (typeof p["chance"] === "number") target.chance = p["chance"];
        if (typeof p["withDuration"] === "boolean") {
          target.withDuration = p["withDuration"];
        }
        if (typeof p["duration"] === "number") {
          target.duration = p["duration"];
        } else if (p["duration"] === null) {
          target.duration = undefined;
        }
        if (typeof p["enabled_donate"] === "boolean") {
          target.enabled_donate = p["enabled_donate"];
        }
        if (typeof p["price_group"] === "string") {
          target.price_group = p["price_group"];
        }
        saveEffects(luaFolder, effects);
        bridge?.emit("reload_config");
        return { success: true };
      },
      getPriceGroups: () => config?.streamer_mode.donate_price_groups ?? [],
      getLanguages: () => (modFolder ? getAvailableLanguages(modFolder) : []),
      getHomeStatus: () => {
        const useLocalhost = config?.streamer_mode.use_localhost_ip ?? true;
        const lan = !useLocalhost
          ? (getBestLocalIPv4()?.address ?? null)
          : null;
        const localUrl = `http://127.0.0.1:${port}/obs`;
        const lanUrl = lan ? `http://${lan}:${port}/obs` : null;
        return {
          port,
          twitch: {
            configured: provider !== null,
            connected: chat !== null && twitchUser !== null,
            name: twitchUser?.display_name ?? null,
          },
          donationalerts: {
            configured: true,
            connected: daProvider.isConnected,
            name: daProvider.currentUser?.name ?? null,
          },
          obs: {
            use_localhost_ip: useLocalhost,
            local_url: localUrl,
            lan_url: lanUrl,
          },
          mod: {
            enabled: modEnabled,
          },
          voting: {
            active: votingManager.isActive,
          },
          twitch_chat: {
            connected: chatConnected,
          },
          recent_activity: activityLog.list(),
          version: versionStatus,
        };
      },
      twitchLogin: async () => {
        if (!provider) {
          return { success: false, error: "No streamer provider configured" };
        }
        const loginUrl = `http://localhost:${port}/login/${provider.key}`;
        try {
          await open(loginUrl);
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.debug(`twitchLogin: failed to open browser: ${msg}`);
        }
        return { success: true, url: loginUrl };
      },
      twitchLogout: async () => {
        if (!provider) {
          return { success: false, error: "No streamer provider configured" };
        }
        if (chat) {
          chat.disconnect();
          chat = null;
        }
        twitchUser = null;
        chatConnected = false;
        const deleted = await provider.deleteToken();
        if (!deleted) {
          return { success: false, error: "Not logged in" };
        }
        logger.info(`${provider.coloredName} Logged out.`);
        return { success: true };
      },
      donationAlertsLogin: async () => {
        const creds = await daProvider.loadCredentials();
        if (!creds) {
          return {
            success: false,
            error:
              "DonationAlerts credentials not configured. Use the CLI: donate on donationalerts <app_id> <client_secret> <currency>",
          };
        }
        const loginUrl = daProvider.getLoginUrl(port, creds.appId);
        try {
          await open(loginUrl);
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.debug(`donationAlertsLogin: failed to open browser: ${msg}`);
        }
        return { success: true, url: loginUrl };
      },
      donationAlertsLogout: async () => {
        daProvider.disconnect();
        await daProvider.deleteTokens();
        logger.info(`${daProvider.coloredName} Logged out.`);
        return { success: true };
      },
      donationAlertsSetup: async (input: {
        appId: string;
        clientSecret: string;
        currency: string;
      }) => {
        await daProvider.saveCredentials(
          input.appId,
          input.clientSecret,
          input.currency,
        );
        if (config && luaFolder) {
          if (
            !config.streamer_mode.donate_providers.includes("donationalerts")
          ) {
            config.streamer_mode.donate_providers.push("donationalerts");
            saveConfig(luaFolder, config);
            bridge?.emit("reload_config");
          }
        }
        logger.info(
          `[DonationAlerts] App credentials saved with currency ${input.currency}. Opening login...`,
        );
        const loginUrl = daProvider.getLoginUrl(port, input.appId);
        try {
          await open(loginUrl);
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.debug(`donationAlertsSetup: failed to open browser: ${msg}`);
        }
        return { success: true, url: loginUrl };
      },
      exportEffects: (kind: string) => {
        if (kind !== "csv") {
          return { success: false, error: `Unsupported export type: ${kind}` };
        }
        if (!luaFolder) {
          return { success: false, error: "Lua folder not available" };
        }
        const outputPath = writeEffectsCsv(luaFolder);
        revealInExplorer(outputPath);
        logger.info(`Exported to ${colors.cyan(outputPath)}`);
        return { success: true, path: outputPath };
      },
    };
  }

  function writeEffectsCsv(luaDir: string): string {
    const priceGroups = config?.streamer_mode.donate_price_groups ?? [];
    const rows: string[] = [
      "id,name,effect_id,enabled,chance,duration,price_group,price",
    ];
    for (const [index, e] of effects.entries()) {
      const entry = buildEffectResponseEntry(index, e, priceGroups);
      const name = getString("effects", e.id).replace(/,/g, "");
      const duration =
        e.withDuration && e.duration != null ? String(e.duration) : "";
      rows.push(
        [
          String(entry.id),
          name,
          entry.effect_id,
          String(e.enabled),
          `${e.chance}%`,
          duration,
          entry.price_group,
          entry.price_result != null ? String(entry.price_result) : "",
        ].join(","),
      );
    }
    const outputPath = join(luaDir, "export.csv");
    writeFileSync(outputPath, rows.join("\n"), "utf-8");
    return outputPath;
  }

  let activeServer = startServer(buildServerCtx(host));

  function restartServerForLocalhostChange(): void {
    if (!config) return;
    const useLocalhostNew = config.streamer_mode.use_localhost_ip;
    const newHost = hostOverride ?? (useLocalhostNew ? "127.0.0.1" : "0.0.0.0");
    activeServer.stop(true);
    activeServer = startServer(buildServerCtx(newHost));
    logger.info(
      `use_localhost_ip changed. Server restarted on ${colors.cyan(`http://${newHost}:${port}`)}.`,
    );
  }

  const dashboardHost = host === "0.0.0.0" ? "127.0.0.1" : host;
  const dashboardUrl = `http://${dashboardHost}:${port}/dashboard`;
  logger.info(`Dashboard: ${colors.cyan(dashboardUrl)}`);
  if (shouldOpenDashboard(port)) {
    open(dashboardUrl).catch((err: unknown) => {
      const msg = err instanceof Error ? err.message : String(err);
      logger.debug(`Failed to open dashboard in browser: ${msg}`);
    });
  } else {
    logger.debug("Dashboard already opened recently; skipping auto-open.");
  }

  if (modFolder && luaFolder && config) {
    registerLangCommand(app, modFolder, luaFolder, config, () => {
      bridge?.emit("reload_config");
    });
  }

  registerDonateCommand(app, port, daProvider, luaFolder, config, () => {
    bridge?.emit("reload_config");
  });

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
      twitchUser = null;
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
      console.log(`Height = ${colors.cyan("550px")}`);
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
      if (!config || !luaFolder) {
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
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");

      const newHost =
        hostOverride ?? (useLocalhostNew ? "127.0.0.1" : "0.0.0.0");
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
      const outputPath = writeEffectsCsv(luaFolder);
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
      if (reloadRuntimeConfig()) {
        bridge?.emit("reload_config");
      }
    },
    "Reload config and effects from config.json and effects.json",
  );

  app.registerCommand(
    "default_config",
    [],
    [],
    () => {
      if (!config || !modFolder || !luaFolder) {
        logger.warn("Config not available.");
        return;
      }

      const nextConfig = resetConfigToDefaultsPreservingUnknowns(
        modFolder,
        luaFolder,
      );
      if (!nextConfig) {
        logger.warn("Failed to reset config.");
        return;
      }

      applyLoadedConfig(config, nextConfig, modFolder);
      bridge?.emit("reload_config");
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
      if (!config || !luaFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("voting on|off")}`);
        return;
      }
      config.streamer_mode.voting_enabled = val === "on";
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
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
      if (!config || !luaFolder) {
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
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
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
      if (!config || !luaFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("donate_mode on|off")}`);
        return;
      }
      config.streamer_mode.enable_donate = val === "on";
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
      logger.info(`Donate mode ${val === "on" ? "enabled" : "disabled"}.`);
    },
    "Enable or disable donate mode",
  );

  app.registerCommand(
    "streamer_mode",
    [],
    [{ name: "on|off", required: true }],
    (args) => {
      if (!config || !luaFolder) {
        logger.warn("Config not available.");
        return;
      }
      const val = args[0]?.toLowerCase();
      if (val !== "on" && val !== "off") {
        logger.warn(`Usage: ${colors.cyan("streamer_mode on|off")}`);
        return;
      }
      config.streamer_mode.streamer_mode_enabled = val === "on";
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
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
