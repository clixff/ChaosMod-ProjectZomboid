import { copyFileSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import {
  LEGACY_USER_CONFIG_FILE_NAME,
  migrateLegacyRuntimeFile,
  USER_CONFIG_BACKUP_FILE_NAME,
  USER_CONFIG_FILE_NAME,
} from "./runtimeFiles.ts";
import { logger } from "./utils/logger.ts";

export interface UIConfig {
  progress_bar_color: string;
  progress_bar_opacity: number;
  progress_bar_text_color: string;
  progress_bar_height: number;
  effect_progress_color: string;
  effect_progress_text_color: string;
  effects_default_x: number;
  effects_default_y: number;
  effects_from_bottom_to_top: boolean;
  progress_bar_voting_color: string;
  vote_background_color: string;
}

export interface DonatePriceGroup {
  group: string;
  price: number;
}

export interface DonationSystemDonationAlerts {
  enabled: boolean;
  app_id: string;
  currency: string;
}

export interface DonationSystemTwitchBits {
  enabled: boolean;
  price_multiplier: number;
}

export interface DonationSystemTwitchPoints {
  enabled: boolean;
}

export interface DonationSystemTwitchSubs {
  enabled: boolean;
  threshold: number;
  allow_gift_subs: boolean;
  allow_resubscriptions: boolean;
  sub_tier_multipliers: boolean;
  show_in_obs: boolean;
}

export interface DonationSystemsConfig {
  donationalerts: DonationSystemDonationAlerts;
  twitch_bits: DonationSystemTwitchBits;
  twitch_points: DonationSystemTwitchPoints;
  twitch_subs: DonationSystemTwitchSubs;
}

export interface CurrenciesConfig {
  main: string;
  list: Record<string, number>;
}

export interface StreamerModeConfig {
  streamer_mode_enabled: boolean;
  voting_enabled: boolean;
  voting_mode: number;
  voting_options_number: number;
  use_localhost_ip: boolean;
  use_zombie_nicknames: boolean;
  use_animals_nicknames: boolean;
  render_chat_messages: boolean;
  say_killed_zombie_name: boolean;
  zombie_nicknames_buffer: number;
  enable_donate: boolean;
  donation_systems: DonationSystemsConfig;
  donate_price_groups: DonatePriceGroup[];
  allow_vote_command: boolean;
  hide_votes: boolean;
  youtube_chat_connection_type: "long_polling" | "message_streaming";
  random_effect_in_vote: boolean;
  voting_fake_effects_enabled: boolean;
  voting_fake_effects_chance: number;
  voting_hidden_effects_enabled: boolean;
  voting_hidden_effects_chance: number;
  reveal_hidden_effect_after_delay: boolean;
  reveal_fake_effect_after_delay: boolean;
  currencies: CurrenciesConfig;
}

export interface MetaEffectEntry {
  id: string;
  enabled: boolean;
  voting_only: boolean;
  duration: number;
  chance: number;
  variables: Record<string, unknown>;
}

export interface MetaEffectsConfig {
  enabled: boolean;
  interval_sec: number;
  list: MetaEffectEntry[];
}

export interface ModConfig {
  lang: string;
  effects_interval_enabled: boolean;
  effects_interval: number;
  effects_duration_multiplier: number;
  recent_effects_block_buffer: number;
  persist_recent_effects: boolean;
  vote_start_time: number;
  hide_progress_bar: boolean;
  use_voting_progress_bar_color: boolean;
  hide_effect_names: boolean;
  explosions_damage_items: boolean;
  explosions_destroy_random_item: boolean;
  ui: UIConfig;
  ui_sounds_enabled: boolean;
  ignore_effect_chances: boolean;
  npc_voicelines_enabled: boolean;
  npc_gifts_enabled: boolean;
  context_aware_system: boolean;
  meta_effects: MetaEffectsConfig;
  streamer_mode: StreamerModeConfig;
}

// Safe field extractors — avoid casting unknown directly
function obj(val: unknown): Record<string, unknown> {
  return val !== null && typeof val === "object" && !Array.isArray(val)
    ? (val as Record<string, unknown>)
    : {};
}
function str(val: unknown, def: string): string {
  return typeof val === "string" ? val : def;
}
function bool(val: unknown, def: boolean): boolean {
  return typeof val === "boolean" ? val : def;
}
function num(val: unknown, def: number): number {
  return typeof val === "number" ? val : def;
}
function priceGroupArr(
  val: unknown,
  def: DonatePriceGroup[],
): DonatePriceGroup[] {
  if (!Array.isArray(val)) return def;
  const result: DonatePriceGroup[] = [];
  for (const item of val) {
    if (item !== null && typeof item === "object" && !Array.isArray(item)) {
      const r = item as Record<string, unknown>;
      if (typeof r["group"] === "string" && typeof r["price"] === "number") {
        result.push({ group: r["group"], price: r["price"] });
      }
    }
  }
  return result.length > 0 ? result : def;
}

const DEFAULT_UI: UIConfig = {
  progress_bar_color: "9f211f",
  progress_bar_opacity: 0.9,
  progress_bar_text_color: "ffffff",
  progress_bar_height: 22,
  effect_progress_color: "9f211f",
  effect_progress_text_color: "ffffff",
  effects_default_x: 1620,
  effects_default_y: 720,
  effects_from_bottom_to_top: true,
  progress_bar_voting_color: "3b8eea",
  vote_background_color: "9f211f",
};

const DEFAULT_DONATE_PRICE_GROUPS: DonatePriceGroup[] = [
  { group: "positive_1", price: 1 },
  { group: "positive_2", price: 2.5 },
  { group: "positive_3", price: 5 },
  { group: "positive_4", price: 7.5 },
  { group: "positive_5", price: 8 },
  { group: "positive_6", price: 10 },
  { group: "negative_1", price: 1 },
  { group: "negative_2", price: 2.5 },
  { group: "negative_3", price: 5 },
  { group: "negative_4", price: 7.5 },
  { group: "negative_5", price: 8 },
  { group: "negative_6", price: 10 },
  { group: "neutral_1", price: 1 },
  { group: "neutral_2", price: 2.5 },
  { group: "neutral_3", price: 5 },
  { group: "neutral_4", price: 7.5 },
  { group: "neutral_5", price: 8 },
  { group: "neutral_6", price: 10 },
];

const DEFAULT_DONATION_SYSTEMS: DonationSystemsConfig = {
  donationalerts: { enabled: false, app_id: "", currency: "" },
  twitch_bits: { enabled: false, price_multiplier: 100.0 },
  twitch_points: { enabled: false },
  twitch_subs: {
    enabled: false,
    threshold: 1,
    allow_gift_subs: true,
    allow_resubscriptions: true,
    sub_tier_multipliers: true,
    show_in_obs: true,
  },
};

const DEFAULT_STREAMER_MODE: StreamerModeConfig = {
  streamer_mode_enabled: true,
  voting_enabled: false,
  voting_mode: 0,
  voting_options_number: 4,
  use_localhost_ip: true,
  use_zombie_nicknames: true,
  use_animals_nicknames: true,
  render_chat_messages: true,
  say_killed_zombie_name: true,
  zombie_nicknames_buffer: 150,
  enable_donate: false,
  donation_systems: DEFAULT_DONATION_SYSTEMS,
  donate_price_groups: DEFAULT_DONATE_PRICE_GROUPS,
  allow_vote_command: true,
  hide_votes: false,
  youtube_chat_connection_type: "long_polling",
  random_effect_in_vote: true,
  voting_fake_effects_enabled: true,
  voting_fake_effects_chance: 5.0,
  voting_hidden_effects_enabled: true,
  voting_hidden_effects_chance: 5.0,
  reveal_hidden_effect_after_delay: true,
  reveal_fake_effect_after_delay: true,
  currencies: { main: "", list: {} },
};

const DEFAULT_META_EFFECTS: MetaEffectsConfig = {
  enabled: true,
  interval_sec: 900,
  list: [],
};

const DEFAULT_CONFIG: ModConfig = {
  lang: "en",
  effects_interval_enabled: true,
  effects_interval: 45,
  effects_duration_multiplier: 1.0,
  recent_effects_block_buffer: 90,
  persist_recent_effects: true,
  vote_start_time: 15,
  hide_progress_bar: false,
  use_voting_progress_bar_color: false,
  hide_effect_names: false,
  explosions_damage_items: true,
  explosions_destroy_random_item: true,
  ui: DEFAULT_UI,
  ui_sounds_enabled: true,
  ignore_effect_chances: false,
  npc_voicelines_enabled: true,
  npc_gifts_enabled: true,
  context_aware_system: true,
  meta_effects: DEFAULT_META_EFFECTS,
  streamer_mode: DEFAULT_STREAMER_MODE,
};

function parseMetaEffects(raw: Record<string, unknown>): MetaEffectsConfig {
  const d = DEFAULT_META_EFFECTS;
  const list: MetaEffectEntry[] = [];
  const rawList = raw["list"];
  if (Array.isArray(rawList)) {
    for (const item of rawList) {
      if (item === null || typeof item !== "object" || Array.isArray(item)) {
        continue;
      }
      const r = item as Record<string, unknown>;
      if (typeof r["id"] !== "string" || r["id"] === "") continue;
      const variables =
        r["variables"] !== null &&
        typeof r["variables"] === "object" &&
        !Array.isArray(r["variables"])
          ? (r["variables"] as Record<string, unknown>)
          : {};
      list.push({
        id: r["id"],
        enabled: typeof r["enabled"] === "boolean" ? r["enabled"] : false,
        voting_only:
          typeof r["voting_only"] === "boolean" ? r["voting_only"] : false,
        duration: typeof r["duration"] === "number" ? r["duration"] : 0,
        chance: typeof r["chance"] === "number" ? r["chance"] : 0,
        variables,
      });
    }
  }
  return {
    enabled: bool(raw["enabled"], d.enabled),
    interval_sec: num(raw["interval_sec"], d.interval_sec),
    list,
  };
}

function cloneConfig(config: ModConfig): ModConfig {
  return JSON.parse(JSON.stringify(config)) as ModConfig;
}

function isPlainObject(val: unknown): val is Record<string, unknown> {
  return val !== null && typeof val === "object" && !Array.isArray(val);
}

function mergeDefaultsPreservingUnknowns(
  existing: unknown,
  defaults: unknown,
): unknown {
  if (Array.isArray(defaults)) {
    return JSON.parse(JSON.stringify(defaults));
  }

  if (isPlainObject(defaults)) {
    const source = isPlainObject(existing) ? existing : {};
    const result: Record<string, unknown> = { ...source };
    for (const [key, value] of Object.entries(defaults)) {
      result[key] = mergeDefaultsPreservingUnknowns(source[key], value);
    }
    return result;
  }

  return defaults;
}

function parseUI(raw: Record<string, unknown>): UIConfig {
  const d = DEFAULT_UI;
  return {
    progress_bar_color: str(raw["progress_bar_color"], d.progress_bar_color),
    progress_bar_opacity: num(
      raw["progress_bar_opacity"],
      d.progress_bar_opacity,
    ),
    progress_bar_text_color: str(
      raw["progress_bar_text_color"],
      d.progress_bar_text_color,
    ),
    progress_bar_height: num(raw["progress_bar_height"], d.progress_bar_height),
    effect_progress_color: str(
      raw["effect_progress_color"],
      d.effect_progress_color,
    ),
    effect_progress_text_color: str(
      raw["effect_progress_text_color"],
      d.effect_progress_text_color,
    ),
    effects_default_x: num(raw["effects_default_x"], d.effects_default_x),
    effects_default_y: num(raw["effects_default_y"], d.effects_default_y),
    effects_from_bottom_to_top: bool(
      raw["effects_from_bottom_to_top"],
      d.effects_from_bottom_to_top,
    ),
    progress_bar_voting_color: str(
      raw["progress_bar_voting_color"],
      d.progress_bar_voting_color,
    ),
    vote_background_color: str(
      raw["vote_background_color"],
      d.vote_background_color,
    ),
  };
}

function parseDonationSystems(
  raw: Record<string, unknown>,
): DonationSystemsConfig {
  const d = DEFAULT_DONATION_SYSTEMS;
  const da = obj(raw["donationalerts"]);
  const bits = obj(raw["twitch_bits"]);
  const points = obj(raw["twitch_points"]);
  const subs = obj(raw["twitch_subs"]);
  const multiplier = num(
    bits["price_multiplier"],
    d.twitch_bits.price_multiplier,
  );
  const subsThresholdRaw = num(subs["threshold"], d.twitch_subs.threshold);
  const subsThreshold = Math.max(1, Math.floor(subsThresholdRaw));
  return {
    donationalerts: {
      enabled: bool(da["enabled"], d.donationalerts.enabled),
      app_id: str(da["app_id"], d.donationalerts.app_id),
      currency: str(da["currency"], d.donationalerts.currency),
    },
    twitch_bits: {
      enabled: bool(bits["enabled"], d.twitch_bits.enabled),
      price_multiplier:
        multiplier > 0 ? multiplier : d.twitch_bits.price_multiplier,
    },
    twitch_points: {
      enabled: bool(points["enabled"], d.twitch_points.enabled),
    },
    twitch_subs: {
      enabled: bool(subs["enabled"], d.twitch_subs.enabled),
      threshold: subsThreshold,
      allow_gift_subs: bool(subs["allow_gift_subs"], d.twitch_subs.allow_gift_subs),
      allow_resubscriptions: bool(
        subs["allow_resubscriptions"],
        d.twitch_subs.allow_resubscriptions,
      ),
      sub_tier_multipliers: bool(
        subs["sub_tier_multipliers"],
        d.twitch_subs.sub_tier_multipliers,
      ),
      show_in_obs: bool(subs["show_in_obs"], d.twitch_subs.show_in_obs),
    },
  };
}

function parseCurrencies(raw: Record<string, unknown>): CurrenciesConfig {
  const main = str(raw["main"], "").trim().toUpperCase();
  const rawList = obj(raw["list"]);
  const list: Record<string, number> = {};
  for (const [code, value] of Object.entries(rawList)) {
    const upper = code.trim().toUpperCase();
    if (!/^[A-Z]{3}$/.test(upper)) continue;
    if (typeof value !== "number" || !Number.isFinite(value) || value <= 0) {
      continue;
    }
    if (upper === main) continue;
    list[upper] = value;
  }
  return { main, list };
}

function parseStreamerMode(raw: Record<string, unknown>): StreamerModeConfig {
  const d = DEFAULT_STREAMER_MODE;
  return {
    streamer_mode_enabled: bool(
      raw["streamer_mode_enabled"],
      d.streamer_mode_enabled,
    ),
    voting_enabled: bool(raw["voting_enabled"], d.voting_enabled),
    voting_mode: num(raw["voting_mode"], d.voting_mode),
    voting_options_number: Math.min(
      8,
      Math.max(
        4,
        Math.floor(num(raw["voting_options_number"], d.voting_options_number)),
      ),
    ),
    use_localhost_ip: bool(raw["use_localhost_ip"], d.use_localhost_ip),
    use_zombie_nicknames: bool(
      raw["use_zombie_nicknames"],
      d.use_zombie_nicknames,
    ),
    use_animals_nicknames: bool(
      raw["use_animals_nicknames"],
      d.use_animals_nicknames,
    ),
    render_chat_messages: bool(
      raw["render_chat_messages"],
      d.render_chat_messages,
    ),
    say_killed_zombie_name: bool(
      raw["say_killed_zombie_name"],
      d.say_killed_zombie_name,
    ),
    zombie_nicknames_buffer: num(
      raw["zombie_nicknames_buffer"],
      d.zombie_nicknames_buffer,
    ),
    enable_donate: bool(raw["enable_donate"], d.enable_donate),
    donation_systems: parseDonationSystems(obj(raw["donation_systems"])),
    donate_price_groups: priceGroupArr(
      raw["donate_price_groups"],
      d.donate_price_groups,
    ),
    allow_vote_command: bool(raw["allow_vote_command"], d.allow_vote_command),
    hide_votes: bool(raw["hide_votes"], d.hide_votes),
    youtube_chat_connection_type:
      raw["youtube_chat_connection_type"] === "message_streaming"
        ? "message_streaming"
        : "long_polling",
    random_effect_in_vote: bool(
      raw["random_effect_in_vote"],
      d.random_effect_in_vote,
    ),
    voting_fake_effects_enabled: bool(
      raw["voting_fake_effects_enabled"],
      d.voting_fake_effects_enabled,
    ),
    voting_fake_effects_chance: num(
      raw["voting_fake_effects_chance"],
      d.voting_fake_effects_chance,
    ),
    voting_hidden_effects_enabled: bool(
      raw["voting_hidden_effects_enabled"],
      d.voting_hidden_effects_enabled,
    ),
    voting_hidden_effects_chance: num(
      raw["voting_hidden_effects_chance"],
      d.voting_hidden_effects_chance,
    ),
    reveal_hidden_effect_after_delay: bool(
      raw["reveal_hidden_effect_after_delay"],
      d.reveal_hidden_effect_after_delay,
    ),
    reveal_fake_effect_after_delay: bool(
      raw["reveal_fake_effect_after_delay"],
      d.reveal_fake_effect_after_delay,
    ),
    currencies: parseCurrencies(obj(raw["currencies"])),
  };
}

function userConfigPath(luaFolder: string): string {
  return join(luaFolder, USER_CONFIG_FILE_NAME);
}

function defaultConfigPath(modFolder: string): string {
  return join(modFolder, "common", "default_config.json");
}

function readJsonObject(path: string): Record<string, unknown> | null {
  if (!existsSync(path)) return null;
  try {
    return obj(JSON.parse(readFileSync(path, "utf-8")));
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to parse ${path}: ${msg}`);
    return null;
  }
}

function isPlainObjectVal(val: unknown): val is Record<string, unknown> {
  return val !== null && typeof val === "object" && !Array.isArray(val);
}

/**
 * Recursively add keys from `defaults` into `existing` when missing. Returns
 * true if any key was added. Arrays are treated as opaque values (not merged).
 */
function addMissingKeysDeep(
  existing: Record<string, unknown>,
  defaults: Record<string, unknown>,
): boolean {
  let changed = false;
  for (const [key, defValue] of Object.entries(defaults)) {
    if (!(key in existing)) {
      existing[key] = JSON.parse(JSON.stringify(defValue)) as unknown;
      changed = true;
      continue;
    }
    const cur = existing[key];
    if (isPlainObjectVal(cur) && isPlainObjectVal(defValue)) {
      if (addMissingKeysDeep(cur, defValue)) {
        changed = true;
      }
    }
  }
  return changed;
}

export function saveConfig(luaFolder: string, config: ModConfig): void {
  migrateLegacyRuntimeFile(
    luaFolder,
    LEGACY_USER_CONFIG_FILE_NAME,
    USER_CONFIG_FILE_NAME,
  );
  const configPath = userConfigPath(luaFolder);
  try {
    let existingRaw: Record<string, unknown> = {};
    if (existsSync(configPath)) {
      existingRaw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
    }
    // streamer_mode.currencies is a user-managed list of currency rates;
    // removing an entry must propagate to disk. Drop the existing block so the
    // merge takes the new in-memory value verbatim instead of merging maps.
    const existingSm = existingRaw["streamer_mode"];
    if (isPlainObject(existingSm) && "currencies" in existingSm) {
      delete existingSm["currencies"];
    }
    const merged = mergeDefaultsPreservingUnknowns(existingRaw, config);
    writeFileSync(configPath, JSON.stringify(merged, null, 4), "utf-8");
    logger.debug(`Config saved to ${configPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to save config.json.cfg: ${msg}`);
  }
}

export function loadConfig(modFolder: string, luaFolder: string): ModConfig {
  migrateLegacyRuntimeFile(
    luaFolder,
    LEGACY_USER_CONFIG_FILE_NAME,
    USER_CONFIG_FILE_NAME,
  );
  const configPath = userConfigPath(luaFolder);
  const defaultPath = defaultConfigPath(modFolder);

  const defaultRaw = readJsonObject(defaultPath);

  let raw = readJsonObject(configPath);
  if (!raw) {
    if (defaultRaw) {
      logger.info(
        `config.json.cfg not found at ${configPath}; copying default_config.json`,
      );
      try {
        writeFileSync(configPath, JSON.stringify(defaultRaw, null, 4), "utf-8");
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(`Failed to write config.json.cfg: ${msg}`);
      }
      raw = defaultRaw;
    } else {
      logger.warn(
        `config.json.cfg not found at ${configPath} and default_config.json missing; using built-in defaults`,
      );
      raw = {};
    }
  } else if (defaultRaw) {
    if (addMissingKeysDeep(raw, defaultRaw)) {
      logger.info(
        `Added missing keys from default_config.json; saving config.json.cfg`,
      );
      try {
        writeFileSync(configPath, JSON.stringify(raw, null, 4), "utf-8");
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(`Failed to save merged config.json.cfg: ${msg}`);
      }
    }
  }
  logger.debug(`Loaded config from ${configPath}`);

  const d = DEFAULT_CONFIG;
  return {
    lang: str(raw["lang"], d.lang),
    effects_interval_enabled: bool(
      raw["effects_interval_enabled"],
      d.effects_interval_enabled,
    ),
    effects_interval: num(raw["effects_interval"], d.effects_interval),
    effects_duration_multiplier: num(
      raw["effects_duration_multiplier"],
      d.effects_duration_multiplier,
    ),
    recent_effects_block_buffer: num(
      raw["recent_effects_block_buffer"],
      d.recent_effects_block_buffer,
    ),
    persist_recent_effects: bool(
      raw["persist_recent_effects"],
      d.persist_recent_effects,
    ),
    vote_start_time: num(raw["vote_start_time"], d.vote_start_time),
    hide_progress_bar: bool(raw["hide_progress_bar"], d.hide_progress_bar),
    use_voting_progress_bar_color: bool(
      raw["use_voting_progress_bar_color"],
      d.use_voting_progress_bar_color,
    ),
    hide_effect_names: bool(raw["hide_effect_names"], d.hide_effect_names),
    explosions_damage_items: bool(
      raw["explosions_damage_items"],
      d.explosions_damage_items,
    ),
    explosions_destroy_random_item: bool(
      raw["explosions_destroy_random_item"],
      d.explosions_destroy_random_item,
    ),
    ui: parseUI(obj(raw["ui"])),
    ui_sounds_enabled: bool(raw["ui_sounds_enabled"], d.ui_sounds_enabled),
    ignore_effect_chances: bool(
      raw["ignore_effect_chances"],
      d.ignore_effect_chances,
    ),
    npc_voicelines_enabled: bool(
      raw["npc_voicelines_enabled"],
      d.npc_voicelines_enabled,
    ),
    npc_gifts_enabled: bool(raw["npc_gifts_enabled"], d.npc_gifts_enabled),
    context_aware_system: bool(
      raw["context_aware_system"],
      d.context_aware_system,
    ),
    meta_effects: parseMetaEffects(obj(raw["meta_effects"])),
    streamer_mode: parseStreamerMode(obj(raw["streamer_mode"])),
  };
}

export function resetConfigToDefaultsPreservingUnknowns(
  modFolder: string,
  luaFolder: string,
): ModConfig | null {
  migrateLegacyRuntimeFile(
    luaFolder,
    LEGACY_USER_CONFIG_FILE_NAME,
    USER_CONFIG_FILE_NAME,
  );
  const configPath = userConfigPath(luaFolder);
  const backupPath = join(luaFolder, USER_CONFIG_BACKUP_FILE_NAME);

  let existingRaw: Record<string, unknown> = {};
  if (existsSync(configPath)) {
    try {
      existingRaw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
      copyFileSync(configPath, backupPath);
      logger.debug(`Config backup saved to ${backupPath}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to backup config.json.cfg: ${msg}`);
      return null;
    }
  } else {
    try {
      writeFileSync(
        backupPath,
        JSON.stringify(cloneConfig(DEFAULT_CONFIG), null, 4),
        "utf-8",
      );
      logger.debug(`Config backup saved to ${backupPath}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to create config_backup.json.txt: ${msg}`);
      return null;
    }
  }

  const merged = mergeDefaultsPreservingUnknowns(
    existingRaw,
    cloneConfig(DEFAULT_CONFIG),
  );
  if (!isPlainObject(merged)) {
    logger.error("Failed to build default config payload.");
    return null;
  }

  try {
    writeFileSync(configPath, JSON.stringify(merged, null, 4), "utf-8");
    logger.debug(`Default config saved to ${configPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to save default config.json.cfg: ${msg}`);
    return null;
  }

  return loadConfig(modFolder, luaFolder);
}
