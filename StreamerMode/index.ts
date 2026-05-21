// MUST be first import — see file header. Sets globalThis.Long so that
// protobufjs (loaded transitively by @grpc/proto-loader) can find the Long
// class in `bun build --compile` output.
import "./src/streamer/youtube/protobufBootstrap.ts";
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
import { syncEffectsForModVersion } from "./src/versionFile.ts";
import { startServer } from "./src/server.ts";
import {
  createChatProviders,
  type NormalizedChatMessage,
} from "./src/streamer/index.ts";
import { initLocalization, getString } from "./src/localization.ts";
import { buildEffectsXlsxBuffer, writeEffectsXlsx } from "./src/exportXlsx.ts";
import { NicknamesManager } from "./src/streamer/NicknamesManager.ts";
import { VotingManager } from "./src/streamer/VotingManager.ts";
import { removeEmojis } from "./src/utils/text.ts";
import {
  startDebugChatMessages,
  startDebugNicknames,
} from "./src/debugNicknames.ts";
import { startDebugVotes } from "./src/debugVotes.ts";
import { Bridge } from "./src/bridge/Bridge.ts";
import { DonationAlertsProvider } from "./src/donationalerts/DonationAlertsProvider.ts";
import { DonationManager } from "./src/donations/DonationManager.ts";
import { handleBitsCheer } from "./src/donations/BitsHandler.ts";
import {
  TwitchRewardsManager,
  type EffectLookup,
  type RewardRow,
} from "./src/streamer/twitch/rewards/TwitchRewardsManager.ts";
import { TwitchRewardsError } from "./src/streamer/twitch/rewards/TwitchRewardsClient.ts";
import type { RedemptionEvent } from "./src/streamer/TwitchChat.ts";
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

const VERSION = "1.1.2";
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
  if (modFolder && luaFolder) {
    syncEffectsForModVersion(modFolder, luaFolder, VERSION);
  }
  const effects =
    modFolder && luaFolder ? loadEffects(modFolder, luaFolder) : [];

  if (modFolder && config) {
    applyLoadedConfig(config, config, modFolder);
  }

  const useLocalhost = config?.streamer_mode.use_localhost_ip ?? true;
  const host = hostOverride ?? (useLocalhost ? "127.0.0.1" : "0.0.0.0");

  const { twitch: twitchProvider, youtube: youtubeProvider } =
    createChatProviders();
  const chatProviders = [twitchProvider, youtubeProvider];

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

  const bridge = luaFolder ? new Bridge(luaFolder) : null;
  let modEnabled = false;
  let iterationIndex = 0;

  type HandshakePayload = {
    streamer_mode_version: string;
    has_new_update: boolean;
    new_update_version: string;
  };
  let lastSentHandshake: HandshakePayload | null = null;

  function buildHandshakePayload(): HandshakePayload {
    const hasNew = versionStatus.update_available && !!versionStatus.latest;
    return {
      streamer_mode_version: VERSION,
      has_new_update: hasNew,
      new_update_version: hasNew ? (versionStatus.latest ?? "") : "",
    };
  }

  function handshakeEquals(
    a: HandshakePayload | null,
    b: HandshakePayload,
  ): boolean {
    if (!a) return false;
    return (
      a.streamer_mode_version === b.streamer_mode_version &&
      a.has_new_update === b.has_new_update &&
      a.new_update_version === b.new_update_version
    );
  }

  function emitHandshakeIfChanged(): void {
    if (!bridge || !modEnabled) return;
    const next = buildHandshakePayload();
    if (handshakeEquals(lastSentHandshake, next)) return;
    lastSentHandshake = next;
    bridge.emit("streamer_handshake", next);
    logger.debug(
      `[Bridge] streamer_handshake: app=${next.streamer_mode_version} update=${next.has_new_update} new=${next.new_update_version || "-"}`,
    );
  }

  void fetchLatestVersion().then((latest) => {
    versionStatus = buildVersionStatus(VERSION, latest);
    if (versionStatus.update_available && latest) {
      logger.info(
        `${colors.yellow(`New version v${latest} is available.`)} Download: ${colors.cyan(RELEASES_URL)}`,
      );
    }
    emitHandshakeIfChanged();
  });

  if (bridge) {
    bridge.on("mod_change_status", (payload) => {
      const enabled = payload.enabled === true;
      modEnabled = enabled;
      logger.debug(`[Bridge] mod_change_status: enabled=${enabled}`);
      if (enabled) {
        lastSentHandshake = null;
        emitHandshakeIfChanged();
      } else {
        votingManager.stop();
        lastSentHandshake = null;
        bridge.rotateOutbound();
      }
      if (
        rewardsManager &&
        (config?.streamer_mode.donation_systems.twitch_points.enabled ?? false)
      ) {
        void rewardsManager.setVisible(enabled);
      }
    });

    bridge.on("open_github", () => {
      logger.debug("[Bridge] open_github");
      void open(RELEASES_URL).catch((err) => {
        const msg = err instanceof Error ? err.message : String(err);
        logger.debug(`[Bridge] open_github: failed to open browser: ${msg}`);
      });
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

    bridge.on("vote_start", (payload) => {
      logger.debug("[Bridge] vote_start");
      if (!config?.streamer_mode.voting_enabled) return;
      const rawEffects = payload["effects"];
      const visibleEffectIds = Array.isArray(rawEffects)
        ? rawEffects.filter((id): id is string => typeof id === "string")
        : [];
      const rawSecret = payload["secret_effect"];
      const secretEffectId =
        typeof rawSecret === "string" && rawSecret !== "" ? rawSecret : null;
      votingManager.start(visibleEffectIds, secretEffectId);
    });

    bridge.on("reload_config", () => {
      logger.debug("[Bridge] reload_config");
      reloadRuntimeConfig();
    });

    bridge.start();
  }

  await DonationAlertsProvider.cleanupLegacySecrets();

  const daProvider = new DonationAlertsProvider(() =>
    config ? config.streamer_mode.donation_systems.donationalerts : null,
  );
  daProvider.onConnect = () => {
    activityLog.add({ type: "donationalerts_connected" });
  };
  daProvider.onDisconnect = () => {
    activityLog.add({ type: "donationalerts_disconnected" });
  };
  const donationManager = new DonationManager(port);
  donationManager.onActivationFailed = (info) => {
    const effectName = getString("effects", info.effect_id);
    if (info.type === "price_too_low") {
      activityLog.add({
        type: "donate_failed_price",
        effect_id: info.effect_id,
        effect_name: effectName,
        nickname: info.nickname,
        donation_amount: info.donation_amount,
        required_price: info.required_price,
      });
    } else {
      activityLog.add({
        type: "donate_failed_disabled",
        effect_id: info.effect_id,
        effect_name: effectName,
        nickname: info.nickname,
        donation_amount: info.donation_amount,
      });
    }
  };
  donationManager.addProvider(daProvider);

  // Auto-login donation providers on startup
  const daUser = await daProvider.start(port);
  if (daUser) {
    logger.info(
      `[DonationProvider] ${daProvider.coloredName} Logged in as ${colors.cyan(daUser.name)}`,
    );
  } else {
    const daAppId = daProvider.getAppId();
    const daSecrets = await daProvider.loadSecrets();
    if (daAppId && daSecrets) {
      logger.info(
        `${daProvider.coloredName} Not logged in. Type ${colors.cyan("donate login donationalerts")} to authenticate.`,
      );
    }
  }

  // Twitch Channel Points rewards manager. Active only while a Lua folder is
  // available; bootstraps from twitch_rewards.json and reconciles against the
  // user's manageable rewards on Twitch.
  const rewardsManager = luaFolder ? new TwitchRewardsManager(luaFolder) : null;

  function parseRedemptionNumber(input: string): number | null {
    const match = input.match(/\d+/);
    if (!match) return null;
    const value = Number.parseInt(match[0], 10);
    return Number.isInteger(value) && value > 0 ? value : null;
  }

  function buildEffectLookup(effect: EffectEntry, index: number): EffectLookup {
    return {
      id: effect.id,
      numericId: index + 1,
      enabled: effect.enabled,
      enabled_donate: effect.enabled_donate,
      price_group: effect.price_group ?? "",
    };
  }

  if (rewardsManager) {
    rewardsManager.resolver = {
      resolve: (event, reward) => {
        const num = parseRedemptionNumber(event.userInput);
        if (num === null) return null;
        const effect = effects[num - 1];
        if (!effect) return null;
        if (!effect.enabled || !effect.enabled_donate) return null;
        const group = effect.price_group ?? "";
        if (!group || !reward.groups.includes(group)) return null;
        return buildEffectLookup(effect, num - 1);
      },
    };
    rewardsManager.onActivate = (effect, nickname) => {
      if (!bridge) return;
      bridge.emit("activate_effects", {
        effects: [{ id: effect.id, type: "donate", nickname: nickname ?? "" }],
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
    };
  }

  twitchProvider.onSessionChange = (token, user) => {
    if (!rewardsManager) return;
    rewardsManager.setAuth(user?.id ?? null, token);
    if (token && user) {
      void rewardsManager.bootstrap();
    }
  };

  twitchProvider.setRedemptionScopeReader(
    () => config?.streamer_mode.donation_systems.twitch_points.enabled ?? false,
  );

  twitchProvider.onRedemption = (ev: RedemptionEvent) => {
    if (!rewardsManager) return;
    void rewardsManager.handleRedemption({
      redemptionId: ev.id,
      rewardId: ev.reward.id,
      userInput: ev.user_input,
      userName: ev.user_name,
    });
  };

  if (args.includes("--debug-votes")) {
    startDebugVotes(votingManager);
  }

  function handleBitsForChat(msg: NormalizedChatMessage): void {
    if (!config) return;
    const bits = msg.cheer?.bits ?? 0;
    if (bits <= 0) return;
    const nickname = msg.displayName || msg.loginName || "";
    const result = handleBitsCheer({
      message: msg.text,
      bits,
      nickname,
      config,
      effects,
    });

    switch (result.type) {
      case "ignored":
        return;
      case "no_tag":
      case "unknown_effect":
        activityLog.add({
          type: "bits_failed_no_tag",
          nickname: result.nickname,
          bits: result.bits,
        });
        return;
      case "donations_disabled":
        activityLog.add({
          type: "bits_failed_disabled",
          effect_id: result.effect_id,
          effect_name: getString("effects", result.effect_id),
          nickname: result.nickname,
          bits: result.bits,
        });
        return;
      case "price_too_low":
        activityLog.add({
          type: "bits_failed_price",
          effect_id: result.effect_id,
          effect_name: getString("effects", result.effect_id),
          nickname: result.nickname,
          bits: result.bits,
          required_bits: result.required_bits,
        });
        return;
      case "activate":
        if (bridge) {
          bridge.emit("activate_effects", {
            effects: [
              {
                id: result.effect_id,
                type: "donate",
                nickname: result.nickname,
              },
            ],
          });
        }
        activityLog.add({
          type: "bits",
          effect_id: result.effect_id,
          effect_name: getString("effects", result.effect_id),
          nickname: result.nickname,
          bits: result.bits,
          required_bits: result.required_bits,
          price_group: result.price_group,
        });
        return;
    }
  }

  function handleChatMessage(msg: NormalizedChatMessage): void {
    if (!config?.streamer_mode.streamer_mode_enabled) return;

    const bits = msg.cheer?.bits ?? 0;
    const isCheer = bits > 0;

    const text = msg.text;
    let voteNum: number | null = null;

    if (!isCheer) {
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
    }

    if (config.streamer_mode.use_zombie_nicknames && nicknamesManager) {
      const cleanedDisplayName =
        removeEmojis(msg.displayName) || msg.displayName;
      let sanitizedMessage: string | undefined;
      if (config.streamer_mode.render_chat_messages && voteNum === null) {
        const stripped = removeEmojis(
          text.replace(/\\n/g, "").replace(/\r?\n/g, " "),
        );
        sanitizedMessage = stripped.length > 0 ? stripped : undefined;
      }

      nicknamesManager.add(
        msg.loginName,
        cleanedDisplayName,
        msg.colorHex,
        sanitizedMessage,
        msg.timestampMs,
      );
    }

    if (!isCheer && config.streamer_mode.voting_enabled) {
      if (voteNum !== null) {
        const n = config.streamer_mode.voting_options_number;
        if (voteNum >= n + 1 && voteNum <= 2 * n) voteNum -= n;
        if (voteNum >= 1 && voteNum <= n) {
          votingManager.addVote(msg.userId, voteNum);
        }
      }
    }

    if (isCheer) {
      handleBitsForChat(msg);
    }
  }

  for (const provider of chatProviders) {
    provider.onMessage = handleChatMessage;
    provider.onChatConnect = () => {
      if (provider.key === "twitch") {
        activityLog.add({ type: "chat_connected" });
      } else if (provider.key === "youtube") {
        activityLog.add({ type: "youtube_chat_connected" });
      }
    };
    provider.onChatDisconnect = () => {
      if (provider.key === "twitch") {
        activityLog.add({ type: "chat_disconnected" });
      } else if (provider.key === "youtube") {
        activityLog.add({ type: "youtube_chat_disconnected" });
      }
    };
  }

  twitchProvider.onLogin = () => {
    if (config && luaFolder) {
      config.streamer_mode.streamer_mode_enabled = true;
      config.streamer_mode.voting_enabled = true;
      saveConfig(luaFolder, config);
      bridge?.emit("reload_config");
      logger.info("Streamer mode and voting enabled.");
    }
  };

  await twitchProvider.initFromStorage();
  if (!twitchProvider.isAccountConnected()) {
    logger.info(
      `${twitchProvider.coloredName} Not logged in. Type ${colors.cyan("login")} to get the login URL.`,
    );
  }

  youtubeProvider.setConnectionTypeReader(
    () => config?.streamer_mode.youtube_chat_connection_type ?? "long_polling",
  );
  await youtubeProvider.initFromStorage();
  if (!youtubeProvider.isAccountConnected()) {
    logger.debug(
      `${youtubeProvider.coloredName} Not logged in. Use the dashboard YouTube card to connect.`,
    );
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
      for (const p of chatProviders) p.shutdown();
    },
  });

  function buildServerCtx(serverHost: string) {
    return {
      host: serverHost,
      port,
      twitch: twitchProvider,
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
            const hidden = isRandom && votingManager.isActive;
            const resolvedId = revealSecret && secretId ? secretId : opt.id;
            const effectName = getString("effects", resolvedId);
            const effectEntry = hidden
              ? null
              : effects.find((e) => e.id === resolvedId);
            const duration =
              effectEntry &&
              effectEntry.withDuration &&
              typeof effectEntry.duration === "number"
                ? effectEntry.duration
                : undefined;
            return {
              effect_id: opt.id,
              index: i + 1 + offset,
              effect_name: effectName,
              votes: config?.streamer_mode.hide_votes
                ? undefined
                : opt.voters.size,
              hidden,
              duration,
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
        const youtubeStatus = youtubeProvider.getStatusSnapshot();
        return {
          port,
          twitch: {
            configured: true,
            connected: twitchProvider.isAccountConnected(),
            name: twitchProvider.getAccountName(),
          },
          donationalerts: {
            connected: daProvider.isConnected,
            name: daProvider.currentUser?.name ?? null,
          },
          youtube: youtubeStatus,
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
            connected: twitchProvider.isChatConnected(),
          },
          recent_activity: activityLog.list(),
          version: versionStatus,
        };
      },
      twitchLogin: async () => {
        const loginUrl = `http://localhost:${port}/login/twitch`;
        try {
          await open(loginUrl);
        } catch (err) {
          const msg = err instanceof Error ? err.message : String(err);
          logger.debug(`twitchLogin: failed to open browser: ${msg}`);
        }
        return { success: true, url: loginUrl };
      },
      twitchLogout: async () => {
        const deleted = await twitchProvider.logout();
        if (!deleted) {
          return { success: false, error: "Not logged in" };
        }
        return { success: true };
      },
      youtubeLogout: async () => {
        await youtubeProvider.logout();
        return { success: true };
      },
      youtubeSetStreamUrl: async (rawUrl: string) => {
        const r = await youtubeProvider.setStreamUrl(rawUrl);
        if (!r.success) {
          return { success: false, error: r.error };
        }
        return { success: true };
      },
      youtubeSetApiKey: async (rawKey: string) => {
        const r = await youtubeProvider.setApiKey(rawKey);
        if (!r.success) {
          return { success: false, error: r.error };
        }
        return { success: true };
      },
      youtubeReconnect: async () => {
        await youtubeProvider.restartChat();
        return { success: true };
      },
      getTwitchPointsStatus: () => {
        const enabled =
          config?.streamer_mode.donation_systems.twitch_points.enabled ?? false;
        const hasScope = twitchProvider.hasRedemptionScope();
        return {
          enabled,
          twitch_connected: twitchProvider.isAccountConnected(),
          has_scope: hasScope,
          has_rewards: rewardsManager?.hasRewards ?? false,
          rewards: rewardsManager?.list() ?? [],
          available_groups: (
            config?.streamer_mode.donate_price_groups ?? []
          ).map((g) => g.group),
        };
      },
      updateTwitchPointsConfig: async (input: { enabled: boolean }) => {
        if (!config || !luaFolder) {
          return { success: false, error: "Config not available" };
        }
        const prev =
          config.streamer_mode.donation_systems.twitch_points.enabled;
        config.streamer_mode.donation_systems.twitch_points.enabled =
          input.enabled;
        saveConfig(luaFolder, config);
        bridge?.emit("reload_config");
        if (prev && !input.enabled && rewardsManager) {
          try {
            await rewardsManager.deleteAll();
          } catch (err) {
            const msg = err instanceof Error ? err.message : String(err);
            logger.warn(`[TwitchPoints] deleteAll on disable failed: ${msg}`);
          }
        }
        return { success: true };
      },
      createTwitchPoints: async (rows: RewardRow[]) => {
        if (!rewardsManager) {
          return { success: false, error: "Lua folder not available" };
        }
        if (!twitchProvider.isAccountConnected()) {
          return { success: false, error: "Not logged in to Twitch" };
        }
        if (!twitchProvider.hasRedemptionScope()) {
          return {
            success: false,
            error:
              "Missing channel:manage:redemptions scope. Log in to Twitch.",
          };
        }
        rewardsManager.setAuth(
          twitchProvider.getBroadcasterId(),
          twitchProvider.getCurrentToken(),
        );
        try {
          await rewardsManager.createAll(rows);
          if (!modEnabled) {
            await rewardsManager.setVisible(false);
          }
          return { success: true };
        } catch (err) {
          if (err instanceof TwitchRewardsError) {
            return {
              success: false,
              error: `${err.status} ${err.twitchMessage}`,
              status: err.status,
            };
          }
          const msg = err instanceof Error ? err.message : String(err);
          return { success: false, error: msg };
        }
      },
      deleteTwitchPoints: async () => {
        if (!rewardsManager) {
          return { success: false, error: "Lua folder not available" };
        }
        if (!twitchProvider.isAccountConnected()) {
          return { success: false, error: "Not logged in to Twitch" };
        }
        rewardsManager.setAuth(
          twitchProvider.getBroadcasterId(),
          twitchProvider.getCurrentToken(),
        );
        try {
          await rewardsManager.deleteAll();
          return { success: true };
        } catch (err) {
          if (err instanceof TwitchRewardsError) {
            return {
              success: false,
              error: `${err.status} ${err.twitchMessage}`,
              status: err.status,
            };
          }
          const msg = err instanceof Error ? err.message : String(err);
          return { success: false, error: msg };
        }
      },
      donationAlertsLogin: async () => {
        const appId = daProvider.getAppId();
        const secrets = await daProvider.loadSecrets();
        if (!appId || !secrets) {
          return {
            success: false,
            error:
              "DonationAlerts is not set up. Open the dashboard DonationAlerts card to enter credentials.",
          };
        }
        const loginUrl = daProvider.getLoginUrl(port, appId);
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
        await daProvider.deleteSecrets();
        if (config && luaFolder) {
          if (config.streamer_mode.donation_systems.donationalerts.enabled) {
            config.streamer_mode.donation_systems.donationalerts.enabled = false;
            saveConfig(luaFolder, config);
            bridge?.emit("reload_config");
          }
        }
        logger.info(`${daProvider.coloredName} Logged out.`);
        return { success: true };
      },
      donationAlertsSetup: async (input: {
        appId: string;
        clientSecret: string;
        currency: string;
      }) => {
        await daProvider.saveSecrets({
          clientSecret: input.clientSecret,
          accessToken: "",
          refreshToken: "",
        });
        if (config && luaFolder) {
          let changed = false;
          const da = config.streamer_mode.donation_systems.donationalerts;
          if (da.app_id !== input.appId) {
            da.app_id = input.appId;
            changed = true;
          }
          if (da.currency !== input.currency) {
            da.currency = input.currency;
            changed = true;
          }
          if (!da.enabled) {
            da.enabled = true;
            changed = true;
          }
          if (!config.streamer_mode.enable_donate) {
            config.streamer_mode.enable_donate = true;
            changed = true;
          }
          if (changed) {
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
      exportEffects: async (kind: string) => {
        if (kind !== "csv" && kind !== "xlsx") {
          return { success: false, error: `Unsupported export type: ${kind}` };
        }
        if (!luaFolder) {
          return { success: false, error: "Lua folder not available" };
        }
        const outputPath =
          kind === "xlsx"
            ? await writeEffectsXlsx(
                luaFolder,
                effects,
                config?.streamer_mode.donate_price_groups ?? [],
                getXlsxExportOptions(),
              )
            : writeEffectsCsv(luaFolder);
        revealInExplorer(outputPath);
        logger.info(`Exported to ${colors.cyan(outputPath)}`);
        return { success: true, path: outputPath };
      },
      downloadEffects: async (kind: string) => {
        if (kind !== "csv" && kind !== "xlsx") {
          return {
            success: false as const,
            error: `Unsupported export type: ${kind}`,
          };
        }
        if (kind === "xlsx") {
          const buffer = await buildEffectsXlsxBuffer(
            effects,
            config?.streamer_mode.donate_price_groups ?? [],
            getXlsxExportOptions(),
          );
          return {
            success: true as const,
            bytes: buffer,
            filename: "chaos_mod_effects.xlsx",
            contentType:
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          };
        }
        const csv = buildEffectsCsvString();
        return {
          success: true as const,
          bytes: new TextEncoder().encode(csv).buffer as ArrayBuffer,
          filename: "chaos_mod_effects.csv",
          contentType: "text/csv; charset=utf-8",
        };
      },
    };
  }

  function buildEffectsCsvString(): string {
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
          String(e.chance),
          duration,
          entry.price_group,
          entry.price_result != null ? String(entry.price_result) : "",
        ].join(","),
      );
    }
    return rows.join("\n");
  }

  function writeEffectsCsv(luaDir: string): string {
    const outputPath = join(luaDir, "export.csv");
    writeFileSync(outputPath, buildEffectsCsvString(), "utf-8");
    return outputPath;
  }

  function getXlsxExportOptions() {
    return {
      donationalertsEnabled:
        config?.streamer_mode.donation_systems.donationalerts.enabled ?? false,
      twitchBitsEnabled:
        config?.streamer_mode.donation_systems.twitch_bits.enabled ?? false,
      bitsMultiplier:
        config?.streamer_mode.donation_systems.twitch_bits.price_multiplier ??
        100,
    };
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
      const loginUrl = `http://localhost:${port}/login/twitch`;
      logger.info(`Opening login URL: ${colors.cyan(loginUrl)}`);
      await open(loginUrl);
    },
    "Open the Twitch login URL",
  );

  app.registerCommand(
    "logout",
    [],
    [],
    async () => {
      const deleted = await twitchProvider.logout();
      if (!deleted) {
        logger.warn("Not logged in.");
      }
    },
    "Log out from Twitch",
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
    [{ name: "csv|xlsx", required: true }],
    async (args) => {
      const kind = args[0]?.toLowerCase();
      if (kind !== "csv" && kind !== "xlsx") {
        logger.warn(`Usage: ${colors.cyan("export csv|xlsx")}`);
        return;
      }
      if (!luaFolder) {
        logger.warn("Lua folder not available.");
        return;
      }
      const outputPath =
        kind === "xlsx"
          ? await writeEffectsXlsx(
              luaFolder,
              effects,
              config?.streamer_mode.donate_price_groups ?? [],
              getXlsxExportOptions(),
            )
          : writeEffectsCsv(luaFolder);
      logger.info(`Exported to ${colors.cyan(outputPath)}`);
      console.log("");
      logger.info(colors.bold("Google Sheets:"));
      logger.info(
        `1. Open ${colors.cyan("https://sheets.new")} to create a new spreadsheet.`,
      );
      logger.info(`2. Open ${colors.yellow("File -> Import -> Upload")}.`);
      logger.info(`3. Upload ${colors.cyan(outputPath)}.`);
      if (kind === "csv") {
        logger.info(`4. Open ${colors.yellow("Format -> Convert to table")}.`);
      } else {
        logger.info(
          `4. In the import dialog choose ${colors.yellow("Replace spreadsheet")} and click ${colors.green("Import data")}.`,
        );
      }
      logger.info(
        `5. Open ${colors.green("Share")} in the top-right corner, then set ${colors.yellow("General access -> Anyone with the link -> Viewer")}.`,
      );
    },
    "Export effects to a CSV or XLSX file in the Lua folder",
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
