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

export interface DonationSystemsConfig {
  donationalerts: DonationSystemDonationAlerts;
  twitch_bits: DonationSystemTwitchBits;
}

export interface StreamerModeConfig {
  streamer_mode_enabled: boolean;
  voting_enabled: boolean;
  voting_mode: number;
  voting_options_number: number;
  type: string;
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
  youtube_chat_polling_only: boolean;
}

export interface ModConfig {
  lang: string;
  effects_interval_enabled: boolean;
  effects_interval: number;
  effects_duration_multiplier: number;
  recent_effects_block_buffer: number;
  vote_start_time: number;
  hide_progress_bar: boolean;
  use_voting_progress_bar_color: boolean;
  ui: UIConfig;
  ui_sounds_enabled: boolean;
  ignore_effect_chances: boolean;
  streamer_mode: StreamerModeConfig;
}

export interface EffectEntry {
  id: string;
  name: string;
  enabled: boolean;
  chance: number;
  withDuration: boolean;
  duration?: number;
  enabled_donate: boolean;
  price_group: string;
}

export interface EffectsResponse {
  effects: EffectEntry[];
  price_groups: DonatePriceGroup[];
}

export async function getConfig(): Promise<ModConfig> {
  const res = await fetch("/api/config");
  if (!res.ok) throw new Error(`getConfig: ${res.status}`);
  return (await res.json()) as ModConfig;
}

export async function updateConfig(
  patch: Partial<ModConfig> | Record<string, unknown>,
): Promise<void> {
  const res = await fetch("/api/config", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(patch),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `updateConfig: ${res.status}`);
  }
}

export async function getEffects(): Promise<EffectsResponse> {
  const res = await fetch("/api/effects");
  if (!res.ok) throw new Error(`getEffects: ${res.status}`);
  return (await res.json()) as EffectsResponse;
}

export type ActivityEvent =
  | {
      id: number;
      ts: number;
      type: "vote";
      effect_id: string;
      effect_name: string;
    }
  | {
      id: number;
      ts: number;
      type: "donate";
      effect_id: string;
      effect_name: string;
      nickname: string;
      price: number | null;
      price_group: string;
    }
  | {
      id: number;
      ts: number;
      type: "donate_failed_price";
      effect_id: string;
      effect_name: string;
      nickname: string;
      donation_amount: number;
      required_price: number;
    }
  | {
      id: number;
      ts: number;
      type: "donate_failed_disabled";
      effect_id: string;
      effect_name: string;
      nickname: string;
      donation_amount: number;
    }
  | {
      id: number;
      ts: number;
      type: "bits";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
      required_bits: number;
      price_group: string;
    }
  | {
      id: number;
      ts: number;
      type: "bits_failed_price";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
      required_bits: number;
    }
  | {
      id: number;
      ts: number;
      type: "bits_failed_disabled";
      effect_id: string;
      effect_name: string;
      nickname: string;
      bits: number;
    }
  | {
      id: number;
      ts: number;
      type: "bits_failed_no_tag";
      nickname: string;
      bits: number;
    }
  | { id: number; ts: number; type: "chat_connected" }
  | { id: number; ts: number; type: "chat_disconnected" }
  | { id: number; ts: number; type: "donationalerts_connected" }
  | { id: number; ts: number; type: "donationalerts_disconnected" }
  | { id: number; ts: number; type: "youtube_chat_connected" }
  | { id: number; ts: number; type: "youtube_chat_disconnected" };

export interface HomeStatus {
  port: number;
  twitch: { configured: boolean; connected: boolean; name: string | null };
  donationalerts: { connected: boolean; name: string | null };
  youtube: {
    account_connected: boolean;
    channel_name: string | null;
    chat_connected: boolean;
    stream_url: string | null;
    stream_title: string | null;
    chat_message_count: number;
    last_error: string | null;
  };
  obs: {
    use_localhost_ip: boolean;
    local_url: string;
    lan_url: string | null;
  };
  mod: { enabled: boolean };
  voting: { active: boolean };
  twitch_chat: { connected: boolean };
  recent_activity: ActivityEvent[];
  version: {
    current: string;
    latest: string | null;
    update_available: boolean;
    releases_url: string;
  };
}

export async function getHomeStatus(): Promise<HomeStatus> {
  const res = await fetch("/api/home/status");
  if (!res.ok) throw new Error(`getHomeStatus: ${res.status}`);
  return (await res.json()) as HomeStatus;
}

async function postSimple(path: string): Promise<unknown> {
  const res = await fetch(path, { method: "POST" });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `${path}: ${res.status}`);
  }
  const ct = res.headers.get("Content-Type") ?? "";
  return ct.includes("application/json") ? res.json() : res.text();
}

export async function twitchLogin(): Promise<void> {
  await postSimple("/api/twitch/login");
}
export async function twitchLogout(): Promise<void> {
  await postSimple("/api/twitch/logout");
}
export async function donationAlertsLogin(): Promise<void> {
  await postSimple("/api/donationalerts/login");
}
export async function donationAlertsLogout(): Promise<void> {
  await postSimple("/api/donationalerts/logout");
}
export async function youtubeLogout(): Promise<void> {
  await postSimple("/api/youtube/logout");
}
export async function youtubeSetStreamUrl(url: string): Promise<void> {
  const res = await fetch("/api/youtube/stream-url", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ url }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `youtubeSetStreamUrl: ${res.status}`);
  }
}
export async function youtubeSetApiKey(apiKey: string): Promise<void> {
  const res = await fetch("/api/youtube/api-key", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ apiKey }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `youtubeSetApiKey: ${res.status}`);
  }
}
export async function donationAlertsSetup(input: {
  appId: string;
  clientSecret: string;
  currency: string;
}): Promise<{ url: string | null }> {
  const res = await fetch("/api/donationalerts/setup", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(input),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `donationAlertsSetup: ${res.status}`);
  }
  return (await res.json()) as { url: string | null };
}
export async function exportEffects(
  kind: string,
): Promise<{ path: string | null }> {
  const res = await fetch(`/api/export?type=${encodeURIComponent(kind)}`, {
    method: "POST",
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `export: ${res.status}`);
  }
  return (await res.json()) as { path: string | null };
}

export function downloadEffectsUrl(kind: string): string {
  return `/api/export/download?type=${encodeURIComponent(kind)}`;
}

export async function getLanguages(): Promise<string[]> {
  const res = await fetch("/api/languages");
  if (!res.ok) throw new Error(`getLanguages: ${res.status}`);
  const data = (await res.json()) as { languages: string[] };
  return data.languages;
}

export async function updateEffect(
  id: string,
  patch: Partial<EffectEntry>,
): Promise<void> {
  const res = await fetch(`/api/effects/${encodeURIComponent(id)}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(patch),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `updateEffect: ${res.status}`);
  }
}
