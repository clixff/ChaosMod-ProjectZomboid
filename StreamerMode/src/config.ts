import { existsSync, readFileSync, writeFileSync } from "fs";
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
}

export interface StreamerModeConfig {
  streamer_mode_enabled: boolean;
  voting_enabled: boolean;
  voting_mode: number;
  type: string;
  use_localhost_ip: boolean;
  advanced_voting_numbers: boolean;
  use_zombie_nicknames: boolean;
  say_killed_zombie_name: boolean;
  zombie_nicknames_buffer: number;
  enable_donate: boolean;
  donate_providers: string[];
  paid_base_price: number;
}

export interface ModConfig {
  lang: string;
  effects_enabled: boolean;
  effects_interval: number;
  vote_start_time: number;
  hide_progress_bar: boolean;
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
};

const DEFAULT_STREAMER_MODE: StreamerModeConfig = {
  streamer_mode_enabled: true,
  voting_enabled: false,
  voting_mode: 0,
  type: "twitch",
  use_localhost_ip: true,
  advanced_voting_numbers: true,
  use_zombie_nicknames: true,
  say_killed_zombie_name: true,
  zombie_nicknames_buffer: 150,
  enable_donate: false,
  donate_providers: [],
  paid_base_price: 5,
};

const DEFAULT_CONFIG: ModConfig = {
  lang: "en",
  effects_enabled: true,
  effects_interval: 45,
  vote_start_time: 15,
  hide_progress_bar: false,
  ui: DEFAULT_UI,
  ui_sounds_enabled: true,
  ignore_effect_chances: false,
  streamer_mode: DEFAULT_STREAMER_MODE,
};

function parseUI(raw: Record<string, unknown>): UIConfig {
  const d = DEFAULT_UI;
  return {
    progress_bar_color: str(raw["progress_bar_color"], d.progress_bar_color),
    progress_bar_opacity: num(raw["progress_bar_opacity"], d.progress_bar_opacity),
    progress_bar_text_color: str(raw["progress_bar_text_color"], d.progress_bar_text_color),
    progress_bar_height: num(raw["progress_bar_height"], d.progress_bar_height),
    effect_progress_color: str(raw["effect_progress_color"], d.effect_progress_color),
    effect_progress_text_color: str(raw["effect_progress_text_color"], d.effect_progress_text_color),
    effects_default_x: num(raw["effects_default_x"], d.effects_default_x),
    effects_default_y: num(raw["effects_default_y"], d.effects_default_y),
    effects_from_bottom_to_top: bool(raw["effects_from_bottom_to_top"], d.effects_from_bottom_to_top),
  };
}

function parseStreamerMode(raw: Record<string, unknown>): StreamerModeConfig {
  const d = DEFAULT_STREAMER_MODE;
  return {
    streamer_mode_enabled: bool(raw["streamer_mode_enabled"], d.streamer_mode_enabled),
    voting_enabled: bool(raw["voting_enabled"], d.voting_enabled),
    voting_mode: num(raw["voting_mode"], d.voting_mode),
    type: str(raw["type"], d.type),
    use_localhost_ip: bool(raw["use_localhost_ip"], d.use_localhost_ip),
    advanced_voting_numbers: bool(raw["advanced_voting_numbers"], d.advanced_voting_numbers),
    use_zombie_nicknames: bool(raw["use_zombie_nicknames"], d.use_zombie_nicknames),
    say_killed_zombie_name: bool(raw["say_killed_zombie_name"], d.say_killed_zombie_name),
    zombie_nicknames_buffer: num(raw["zombie_nicknames_buffer"], d.zombie_nicknames_buffer),
    enable_donate: bool(raw["enable_donate"], d.enable_donate),
    donate_providers: strArr(raw["donate_providers"], d.donate_providers),
    paid_base_price: num(raw["paid_base_price"], d.paid_base_price),
  };
}

export function saveConfig(modFolder: string, config: ModConfig): void {
  const configPath = join(modFolder, "common", "config.json");
  try {
    writeFileSync(configPath, JSON.stringify(config, null, 4), "utf-8");
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
    return DEFAULT_CONFIG;
  }

  let raw: Record<string, unknown> = {};
  try {
    raw = obj(JSON.parse(readFileSync(configPath, "utf-8")));
    logger.debug(`Loaded config from ${configPath}`);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    logger.error(`Failed to parse config.json: ${msg}`);
    return DEFAULT_CONFIG;
  }

  const d = DEFAULT_CONFIG;
  return {
    lang: str(raw["lang"], d.lang),
    effects_enabled: bool(raw["effects_enabled"], d.effects_enabled),
    effects_interval: num(raw["effects_interval"], d.effects_interval),
    vote_start_time: num(raw["vote_start_time"], d.vote_start_time),
    hide_progress_bar: bool(raw["hide_progress_bar"], d.hide_progress_bar),
    ui: parseUI(obj(raw["ui"])),
    ui_sounds_enabled: bool(raw["ui_sounds_enabled"], d.ui_sounds_enabled),
    ignore_effect_chances: bool(raw["ignore_effect_chances"], d.ignore_effect_chances),
    streamer_mode: parseStreamerMode(obj(raw["streamer_mode"])),
  };
}
