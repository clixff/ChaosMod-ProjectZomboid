import { createClient } from "@supabase/supabase-js";
import crypto from "node:crypto";

const supabaseUrl = process.env["SUPABASE_URL"];
const supabaseKey = process.env["SUPABASE_SERVICE_ROLE_KEY"];

if (!supabaseUrl || !supabaseKey) {
  throw new Error(
    "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY environment variable",
  );
}

export const supabase = createClient(supabaseUrl, supabaseKey);

export const CONFIG_NAME_REGEX = /^[a-zA-Z0-9_-]{3,40}$/;
export const MAX_CONFIG_BYTES = 50_000;
export const MIN_EDIT_TOKEN_LENGTH = 12;
export const MAX_EDIT_TOKEN_LENGTH = 200;

const EFFECT_ALLOWED_KEYS = new Set([
  "enabled",
  "chance",
  "duration",
  "enabled_donate",
  "price_group",
]);

const CURRENCY_REGEX = /^[A-Z]{3,8}$/;

export interface SharedConfigData {
  effects?: Record<string, Record<string, unknown>>;
  prices?: Record<string, number>;
  rewards?: Record<string, { groups: string[] }>;
  currency?: string;
  bits_override?: number;
  donation_enabled?: boolean;
}

export interface CreateSharedConfigBody {
  name: string;
  edit_token: string;
  mod_version: string;
  rewards: boolean;
  bits: boolean;
  donationalerts: boolean;
  last_effect: number;
  data: SharedConfigData;
}

export interface UpdateSharedConfigBody {
  edit_token: string;
  new_name?: string;
  mod_version?: string;
  rewards?: boolean;
  bits?: boolean;
  donationalerts?: boolean;
  last_effect?: number;
  data?: SharedConfigData;
}

export function hashEditToken(editToken: string): string {
  return crypto.createHash("sha256").update(editToken).digest("hex");
}

function getJsonSizeBytes(value: unknown): number {
  return Buffer.byteLength(JSON.stringify(value), "utf8");
}

export function isValidConfigName(name: unknown): name is string {
  return typeof name === "string" && CONFIG_NAME_REGEX.test(name);
}

export function isValidEditToken(token: unknown): token is string {
  return (
    typeof token === "string" &&
    token.length >= MIN_EDIT_TOKEN_LENGTH &&
    token.length <= MAX_EDIT_TOKEN_LENGTH
  );
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return (
    value !== null && typeof value === "object" && !Array.isArray(value)
  );
}

function sanitizeEffectEntry(
  raw: unknown,
): Record<string, unknown> | null {
  if (!isPlainObject(raw)) return null;
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(raw)) {
    if (!EFFECT_ALLOWED_KEYS.has(key)) continue;
    if (key === "enabled" || key === "enabled_donate") {
      if (typeof value === "boolean") out[key] = value;
    } else if (key === "chance" || key === "duration") {
      if (typeof value === "number" && Number.isFinite(value) && value >= 0) {
        out[key] = value;
      }
    } else if (key === "price_group") {
      if (typeof value === "string" && value.length > 0 && value.length <= 40) {
        out[key] = value;
      }
    }
  }
  return Object.keys(out).length > 0 ? out : null;
}

function sanitizePrices(raw: unknown): Record<string, number> | null {
  if (!isPlainObject(raw)) return null;
  const out: Record<string, number> = {};
  for (const [group, price] of Object.entries(raw)) {
    if (typeof group !== "string" || group.length === 0 || group.length > 40) {
      continue;
    }
    if (typeof price !== "number" || !Number.isFinite(price) || price < 0) {
      continue;
    }
    out[group] = price;
  }
  return out;
}

function sanitizeRewards(
  raw: unknown,
): Record<string, { groups: string[] }> | null {
  if (!isPlainObject(raw)) return null;
  const out: Record<string, { groups: string[] }> = {};
  for (const [name, entry] of Object.entries(raw)) {
    if (typeof name !== "string" || name.length === 0 || name.length > 200) {
      continue;
    }
    if (!isPlainObject(entry)) continue;
    const groups = entry["groups"];
    if (!Array.isArray(groups)) continue;
    const cleanGroups: string[] = [];
    for (const g of groups) {
      if (typeof g === "string" && g.length > 0 && g.length <= 40) {
        cleanGroups.push(g);
      }
    }
    out[name] = { groups: cleanGroups };
  }
  return out;
}

export function sanitizeSharedConfigData(
  raw: unknown,
): SharedConfigData | null {
  if (!isPlainObject(raw)) return null;
  const out: SharedConfigData = {};

  if (raw["effects"] !== undefined) {
    if (!isPlainObject(raw["effects"])) return null;
    const effects: Record<string, Record<string, unknown>> = {};
    for (const [id, entry] of Object.entries(raw["effects"])) {
      if (typeof id !== "string" || id.length === 0 || id.length > 80) {
        continue;
      }
      const cleaned = sanitizeEffectEntry(entry);
      if (cleaned) effects[id] = cleaned;
    }
    out.effects = effects;
  }

  if (raw["prices"] !== undefined) {
    const cleaned = sanitizePrices(raw["prices"]);
    if (cleaned === null) return null;
    out.prices = cleaned;
  }

  if (raw["rewards"] !== undefined) {
    const cleaned = sanitizeRewards(raw["rewards"]);
    if (cleaned === null) return null;
    out.rewards = cleaned;
  }

  if (raw["currency"] !== undefined) {
    if (typeof raw["currency"] !== "string") return null;
    if (raw["currency"] !== "" && !CURRENCY_REGEX.test(raw["currency"])) {
      return null;
    }
    out.currency = raw["currency"];
  }

  if (raw["bits_override"] !== undefined) {
    const v = raw["bits_override"];
    if (typeof v !== "number" || !Number.isFinite(v) || v < 0 || v > 1_000_000) {
      return null;
    }
    out.bits_override = v;
  }

  if (raw["donation_enabled"] !== undefined) {
    if (typeof raw["donation_enabled"] !== "boolean") return null;
    out.donation_enabled = raw["donation_enabled"];
  }

  if (getJsonSizeBytes(out) > MAX_CONFIG_BYTES) {
    return null;
  }

  return out;
}

function isValidModVersion(v: unknown): v is string {
  return typeof v === "string" && v.length >= 1 && v.length <= 40;
}

function isValidLastEffect(v: unknown): v is number {
  return (
    typeof v === "number" &&
    Number.isInteger(v) &&
    v >= 0 &&
    v <= 1_000_000
  );
}

export interface ParsedCreateBody {
  ok: true;
  body: CreateSharedConfigBody;
}

export interface ParsedError {
  ok: false;
  error: string;
}

export function parseCreateBody(
  raw: unknown,
): ParsedCreateBody | ParsedError {
  if (!isPlainObject(raw)) {
    return { ok: false, error: "Body must be an object" };
  }
  if (!isValidConfigName(raw["name"])) {
    return { ok: false, error: "Invalid name (3-40 chars, [A-Za-z0-9_-])" };
  }
  if (!isValidEditToken(raw["edit_token"])) {
    return { ok: false, error: "Invalid edit_token" };
  }
  if (!isValidModVersion(raw["mod_version"])) {
    return { ok: false, error: "Invalid mod_version" };
  }
  if (
    typeof raw["rewards"] !== "boolean" ||
    typeof raw["bits"] !== "boolean" ||
    typeof raw["donationalerts"] !== "boolean"
  ) {
    return { ok: false, error: "rewards/bits/donationalerts must be booleans" };
  }
  if (!isValidLastEffect(raw["last_effect"])) {
    return { ok: false, error: "Invalid last_effect" };
  }
  const data = sanitizeSharedConfigData(raw["data"]);
  if (data === null) {
    return { ok: false, error: "Invalid data payload" };
  }
  return {
    ok: true,
    body: {
      name: raw["name"] as string,
      edit_token: raw["edit_token"] as string,
      mod_version: raw["mod_version"] as string,
      rewards: raw["rewards"] as boolean,
      bits: raw["bits"] as boolean,
      donationalerts: raw["donationalerts"] as boolean,
      last_effect: raw["last_effect"] as number,
      data,
    },
  };
}

export interface ParsedUpdateBody {
  ok: true;
  body: UpdateSharedConfigBody;
}

export function parseUpdateBody(
  raw: unknown,
): ParsedUpdateBody | ParsedError {
  if (!isPlainObject(raw)) {
    return { ok: false, error: "Body must be an object" };
  }
  if (!isValidEditToken(raw["edit_token"])) {
    return { ok: false, error: "Invalid edit_token" };
  }
  const out: UpdateSharedConfigBody = {
    edit_token: raw["edit_token"] as string,
  };
  if (raw["new_name"] !== undefined) {
    if (!isValidConfigName(raw["new_name"])) {
      return { ok: false, error: "Invalid new_name" };
    }
    out.new_name = raw["new_name"];
  }
  if (raw["mod_version"] !== undefined) {
    if (!isValidModVersion(raw["mod_version"])) {
      return { ok: false, error: "Invalid mod_version" };
    }
    out.mod_version = raw["mod_version"];
  }
  if (raw["rewards"] !== undefined) {
    if (typeof raw["rewards"] !== "boolean") {
      return { ok: false, error: "rewards must be a boolean" };
    }
    out.rewards = raw["rewards"];
  }
  if (raw["bits"] !== undefined) {
    if (typeof raw["bits"] !== "boolean") {
      return { ok: false, error: "bits must be a boolean" };
    }
    out.bits = raw["bits"];
  }
  if (raw["donationalerts"] !== undefined) {
    if (typeof raw["donationalerts"] !== "boolean") {
      return { ok: false, error: "donationalerts must be a boolean" };
    }
    out.donationalerts = raw["donationalerts"];
  }
  if (raw["last_effect"] !== undefined) {
    if (!isValidLastEffect(raw["last_effect"])) {
      return { ok: false, error: "Invalid last_effect" };
    }
    out.last_effect = raw["last_effect"];
  }
  if (raw["data"] !== undefined) {
    const data = sanitizeSharedConfigData(raw["data"]);
    if (data === null) {
      return { ok: false, error: "Invalid data payload" };
    }
    out.data = data;
  }
  return { ok: true, body: out };
}

export function publicConfigSelect(): string {
  return [
    "id",
    "created_at",
    "name",
    "mod_version",
    "rewards",
    "bits",
    "donationalerts",
    "last_effect",
    "data",
  ].join(", ");
}
