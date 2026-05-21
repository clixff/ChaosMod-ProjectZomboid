import { logger } from "../../../utils/logger.ts";

export interface CreateRewardParams {
  broadcasterId: string;
  token: string;
  clientId: string;
  title: string;
  cost: number;
  prompt: string;
}

export interface ManageableReward {
  id: string;
  title: string;
  cost: number;
  is_enabled: boolean;
  background_color: string;
}

export interface TwitchApiError {
  status: number;
  message: string;
}

export class TwitchRewardsError extends Error {
  readonly status: number;
  readonly twitchMessage: string;

  constructor(status: number, message: string) {
    super(`Twitch API ${status}: ${message}`);
    this.name = "TwitchRewardsError";
    this.status = status;
    this.twitchMessage = message;
  }
}

interface RawTwitchResponse {
  data?: unknown;
  error?: unknown;
  message?: unknown;
  status?: unknown;
}

const REWARD_BACKGROUND_COLOR = "#9F211F";

async function twitchHelix<T>(
  path: string,
  token: string,
  clientId: string,
  init: RequestInit = {},
): Promise<T> {
  const headers: Record<string, string> = {
    "Client-Id": clientId,
    Authorization: `Bearer ${token}`,
    ...((init.headers as Record<string, string> | undefined) ?? {}),
  };
  if (init.body !== undefined && !headers["Content-Type"]) {
    headers["Content-Type"] = "application/json";
  }
  const res = await fetch(`https://api.twitch.tv/helix${path}`, {
    ...init,
    headers,
  });

  const text = await res.text();
  if (!res.ok) {
    let parsedMessage = text;
    try {
      const json = JSON.parse(text) as RawTwitchResponse;
      if (typeof json.message === "string" && json.message) {
        parsedMessage = json.message;
      } else if (typeof json.error === "string" && json.error) {
        parsedMessage = json.error;
      }
    } catch {
      // Keep raw text as message.
    }
    throw new TwitchRewardsError(res.status, parsedMessage);
  }

  if (!text) return {} as T;
  return JSON.parse(text) as T;
}

export interface TokenValidation {
  client_id: string;
  login?: string;
  user_id?: string;
  scopes: string[];
  expires_in: number;
}

export async function validateTwitchToken(
  accessToken: string,
): Promise<TokenValidation | null> {
  let res: Response;
  try {
    res = await fetch("https://id.twitch.tv/oauth2/validate", {
      headers: { Authorization: `Bearer ${accessToken}` },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.debug(`validateTwitchToken: fetch failed: ${msg}`);
    return null;
  }
  if (!res.ok) return null;
  const json = (await res.json()) as Partial<TokenValidation>;
  if (!Array.isArray(json.scopes) || typeof json.client_id !== "string") {
    return null;
  }
  return {
    client_id: json.client_id,
    login: json.login,
    user_id: json.user_id,
    scopes: json.scopes,
    expires_in: typeof json.expires_in === "number" ? json.expires_in : 0,
  };
}

export async function createCustomReward(
  params: CreateRewardParams,
): Promise<ManageableReward> {
  const response = await twitchHelix<{ data: ManageableReward[] }>(
    `/channel_points/custom_rewards?broadcaster_id=${encodeURIComponent(params.broadcasterId)}`,
    params.token,
    params.clientId,
    {
      method: "POST",
      body: JSON.stringify({
        title: params.title,
        cost: params.cost,
        prompt: params.prompt,
        is_enabled: true,
        is_user_input_required: true,
        background_color: REWARD_BACKGROUND_COLOR,
        should_redemptions_skip_request_queue: false,
        is_global_cooldown_enabled: false,
      }),
    },
  );
  const first = response.data?.[0];
  if (!first || typeof first.id !== "string") {
    throw new TwitchRewardsError(500, "Twitch returned no reward data");
  }
  return first;
}

export async function setRewardEnabled(params: {
  broadcasterId: string;
  token: string;
  clientId: string;
  rewardId: string;
  enabled: boolean;
}): Promise<void> {
  const query = new URLSearchParams({
    broadcaster_id: params.broadcasterId,
    id: params.rewardId,
  });
  await twitchHelix(
    `/channel_points/custom_rewards?${query.toString()}`,
    params.token,
    params.clientId,
    {
      method: "PATCH",
      body: JSON.stringify({ is_enabled: params.enabled }),
    },
  );
}

export async function deleteCustomReward(params: {
  broadcasterId: string;
  token: string;
  clientId: string;
  rewardId: string;
}): Promise<void> {
  const query = new URLSearchParams({
    broadcaster_id: params.broadcasterId,
    id: params.rewardId,
  });
  const res = await fetch(
    `https://api.twitch.tv/helix/channel_points/custom_rewards?${query.toString()}`,
    {
      method: "DELETE",
      headers: {
        "Client-Id": params.clientId,
        Authorization: `Bearer ${params.token}`,
      },
    },
  );
  if (res.status === 204) return;
  if (res.status === 404) return;
  const text = await res.text();
  let parsedMessage = text;
  try {
    const json = JSON.parse(text) as RawTwitchResponse;
    if (typeof json.message === "string" && json.message) {
      parsedMessage = json.message;
    }
  } catch {
    // Keep raw text.
  }
  throw new TwitchRewardsError(res.status, parsedMessage);
}

export async function listManageableRewards(params: {
  broadcasterId: string;
  token: string;
  clientId: string;
}): Promise<ManageableReward[]> {
  const query = new URLSearchParams({
    broadcaster_id: params.broadcasterId,
    only_manageable_rewards: "true",
  });
  const response = await twitchHelix<{ data: ManageableReward[] }>(
    `/channel_points/custom_rewards?${query.toString()}`,
    params.token,
    params.clientId,
  );
  return response.data ?? [];
}

export async function updateRedemptionStatus(params: {
  broadcasterId: string;
  token: string;
  clientId: string;
  rewardId: string;
  redemptionId: string;
  status: "FULFILLED" | "CANCELED";
}): Promise<void> {
  const query = new URLSearchParams({
    broadcaster_id: params.broadcasterId,
    reward_id: params.rewardId,
    id: params.redemptionId,
  });
  await twitchHelix(
    `/channel_points/custom_rewards/redemptions?${query.toString()}`,
    params.token,
    params.clientId,
    {
      method: "PATCH",
      body: JSON.stringify({ status: params.status }),
    },
  );
}

export async function subscribeRewardRedemptions(params: {
  token: string;
  clientId: string;
  broadcasterId: string;
  sessionId: string;
}): Promise<void> {
  await twitchHelix(
    `/eventsub/subscriptions`,
    params.token,
    params.clientId,
    {
      method: "POST",
      body: JSON.stringify({
        type: "channel.channel_points_custom_reward_redemption.add",
        version: "1",
        condition: { broadcaster_user_id: params.broadcasterId },
        transport: { method: "websocket", session_id: params.sessionId },
      }),
    },
  );
}
