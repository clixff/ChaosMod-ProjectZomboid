import { copyFileSync, existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
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

export interface StreamerModeConfig {
  streamer_mode_enabled: boolean;
  voting_enabled: boolean;
  voting_mode: number;
  type: string;
  use_localhost_ip: boolean;
  advanced_voting_numbers: boolean;
  use_zombie_nicknames: boolean;
  use_animals_nicknames: boolean;
  render_chat_messages: boolean;
  say_killed_zombie_name: boolean;
  zombie_nicknames_buffer: number;
  enable_donate: boolean;
  donate_providers: string[];
  donate_price_groups: DonatePriceGroup[];
  allow_vote_command: boolean;
  hide_votes: boolean;
}

export interface ModConfig {
  lang: string;
  effects_interval_enabled: boolean;
  effects_interval: number;
  vote_start_time: number;
  hide_progress_bar: boolean;
  use_voting_progress_bar_color: boolean;
  ui: UIConfig;
  ui_sounds_enabled: boolean;
  ignore_effect_chances: boolean;
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
function strArr(val: unknown, def: string[]): string[] {
  return Array.isArray(val)
    ? val.filter((v): v is string => typeof v === "string")
    : def;
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

const DEFAULT_STREAMER_MODE: StreamerModeConfig = {
  streamer_mode_enabled: true,
  voting_enabled: false,
  voting_mode: 0,
  type: "twitch",
  use_localhost_ip: true,
  advanced_voting_numbers: true,
  use_zombie_nicknames: true,
  use_animals_nicknames: true,
  render_chat_messages: true,
  say_killed_zombie_name: true,
  zombie_nicknames_buffer: 150,
  enable_donate: false,
  donate_providers: [],
  donate_price_groups: DEFAULT_DONATE_PRICE_GROUPS,
  allow_vote_command: true,
  hide_votes: false,
};

const DEFAULT_CONFIG: ModConfig = {
  lang: "en",
  effects_interval_enabled: true,
  effects_interval: 45,
  vote_start_time: 15,
  hide_progress_bar: false,
  use_voting_progress_bar_color: false,
  ui: DEFAULT_UI,
  ui_sounds_enabled: true,
  ignore_effect_chances: false,
  streamer_mode: DEFAULT_STREAMER_MODE,
};

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

function parseStreamerMode(raw: Record<string, unknown>): StreamerModeConfig {
  const d = DEFAULT_STREAMER_MODE;
  return {
    streamer_mode_enabled: bool(
      raw["streamer_mode_enabled"],
      d.streamer_mode_enabled,
    ),
    voting_enabled: bool(raw["voting_enabled"], d.voting_enabled),
    voting_mode: num(raw["voting_mode"], d.voting_mode),
    type: str(raw["type"], d.type),
    use_localhost_ip: bool(raw["use_localhost_ip"], d.use_localhost_ip),
    advanced_voting_numbers: bool(
      raw["advanced_voting_numbers"],
      d.advanced_voting_numbers,
    ),
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
    donate_providers: strArr(raw["donate_providers"], d.donate_providers),
    donate_price_groups: priceGroupArr(
      raw["donate_price_groups"],
      d.donate_price_groups,
    ),
    allow_vote_command: bool(raw["allow_vote_command"], d.allow_vote_command),
    hide_votes: bool(raw["hide_votes"], d.hide_votes),
  };
}

export function saveConfig(modFolder: string, config: ModConfig): void {
  const configPath = join(modFolder, "common", "config.json");
  try {
    let existingRaw: Record<string, unknown> = {};
    if (existsSync(configPath)) {
      existingRaw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
    }
    const merged = mergeDefaultsPreservingUnknowns(existingRaw, config);
    writeFileSync(configPath, JSON.stringify(merged, null, 4), "utf-8");
    logger.debug(`Config saved to ${configPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to save config.json: ${msg}`);
  }
}

export function loadConfig(modFolder: string): ModConfig {
  const configPath = join(modFolder, "common", "config.json");

  if (!existsSync(configPath)) {
    logger.warn(`config.json not found at ${configPath}, using defaults`);
    return cloneConfig(DEFAULT_CONFIG);
  }

  let raw: Record<string, unknown>;
  try {
    raw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
    logger.debug(`Loaded config from ${configPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to parse config.json: ${msg}`);
    return cloneConfig(DEFAULT_CONFIG);
  }

  const d = DEFAULT_CONFIG;
  return {
    lang: str(raw["lang"], d.lang),
    effects_interval_enabled: bool(
      raw["effects_interval_enabled"],
      d.effects_interval_enabled,
    ),
    effects_interval: num(raw["effects_interval"], d.effects_interval),
    vote_start_time: num(raw["vote_start_time"], d.vote_start_time),
    hide_progress_bar: bool(raw["hide_progress_bar"], d.hide_progress_bar),
    use_voting_progress_bar_color: bool(
      raw["use_voting_progress_bar_color"],
      d.use_voting_progress_bar_color,
    ),
    ui: parseUI(obj(raw["ui"])),
    ui_sounds_enabled: bool(raw["ui_sounds_enabled"], d.ui_sounds_enabled),
    ignore_effect_chances: bool(
      raw["ignore_effect_chances"],
      d.ignore_effect_chances,
    ),
    streamer_mode: parseStreamerMode(obj(raw["streamer_mode"])),
  };
}

export function resetConfigToDefaultsPreservingUnknowns(
  modFolder: string,
): ModConfig | null {
  const configPath = join(modFolder, "common", "config.json");
  const backupPath = join(modFolder, "common", "config_backup.json");

  let existingRaw: Record<string, unknown> = {};
  if (existsSync(configPath)) {
    try {
      existingRaw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
      copyFileSync(configPath, backupPath);
      logger.debug(`Config backup saved to ${backupPath}`);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`Failed to backup config.json: ${msg}`);
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
      logger.error(`Failed to create config_backup.json: ${msg}`);
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
    logger.error(`Failed to save default config.json: ${msg}`);
    return null;
  }

  return loadConfig(modFolder);
}
