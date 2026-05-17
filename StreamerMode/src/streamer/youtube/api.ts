import colors from "colors";
import { logger } from "../../utils/logger.ts";

export interface YouTubeAuth {
  apiKey: string;
}

const TAG = colors.red("[YouTube]");

function applyAuth(url: URL, auth: YouTubeAuth): void {
  url.searchParams.set("key", auth.apiKey);
}

/** Build a log-safe URL string with `key=` redacted. */
function redactUrl(url: URL): string {
  const u = new URL(url.toString());
  if (u.searchParams.has("key")) {
    u.searchParams.set("key", "REDACTED");
  }
  return u.toString();
}

/**
 * YouTube returns display names like "@handle" for channels using the new
 * handle system. Strip the leading "@" so logs, nicknames written into the
 * game, and chat-render bubbles show "handle" instead of "@handle".
 */
function sanitizeYouTubeDisplayName(raw: string | undefined): string {
  const trimmed = (raw ?? "").trim();
  if (trimmed.length > 1 && trimmed.startsWith("@")) {
    return trimmed.slice(1).trim();
  }
  return trimmed;
}

export type YouTubeApiErrorReason =
  | "liveChatDisabled"
  | "liveChatEnded"
  | "liveChatNotFound"
  | "rateLimitExceeded"
  | "forbidden"
  | "unauthenticated"
  | "videoNotFound"
  | "notLive"
  | "other";

export class YouTubeApiError extends Error {
  readonly status: number;
  readonly reason: YouTubeApiErrorReason;
  readonly userMessage: string;
  constructor(opts: {
    status: number;
    reason: YouTubeApiErrorReason;
    message: string;
    userMessage: string;
  }) {
    super(opts.message);
    this.status = opts.status;
    this.reason = opts.reason;
    this.userMessage = opts.userMessage;
  }
}

interface GoogleErrorBody {
  error?: {
    code?: number;
    message?: string;
    errors?: Array<{ reason?: string; message?: string }>;
  };
}

function pickReason(
  status: number,
  body: GoogleErrorBody,
): { reason: YouTubeApiErrorReason; userMessage: string } {
  const inner = body.error?.errors?.[0]?.reason ?? "";
  switch (inner) {
    case "liveChatDisabled":
      return {
        reason: "liveChatDisabled",
        userMessage: "Live chat is disabled for this stream.",
      };
    case "liveChatEnded":
      return {
        reason: "liveChatEnded",
        userMessage: "This live chat has ended.",
      };
    case "liveChatNotFound":
      return {
        reason: "liveChatNotFound",
        userMessage:
          "Could not find live chat for this stream. Make sure the stream is live and chat is enabled.",
      };
    case "rateLimitExceeded":
    case "quotaExceeded":
    case "userRateLimitExceeded":
      return {
        reason: "rateLimitExceeded",
        userMessage:
          "YouTube rate limit hit. Polling will slow down automatically.",
      };
    case "forbidden":
      return {
        reason: "forbidden",
        userMessage: "YouTube refused the request (forbidden).",
      };
    case "videoNotFound":
      return {
        reason: "videoNotFound",
        userMessage: "YouTube video not found.",
      };
  }
  if (status === 401) {
    return {
      reason: "unauthenticated",
      userMessage: "YouTube access token expired.",
    };
  }
  if (status === 403) {
    return {
      reason: "forbidden",
      userMessage: "YouTube refused the request (forbidden).",
    };
  }
  return {
    reason: "other",
    userMessage: `YouTube API error: ${body.error?.message ?? `HTTP ${status}`}`,
  };
}

async function readErrorBody(res: Response): Promise<GoogleErrorBody> {
  try {
    return (await res.json()) as GoogleErrorBody;
  } catch {
    return {};
  }
}

export interface YouTubeVideoInfo {
  liveChatId: string | null;
  title: string | null;
  channelTitle: string | null;
  hasEnded: boolean;
}

export async function fetchVideoLiveChat(params: {
  auth: YouTubeAuth;
  videoId: string;
}): Promise<YouTubeVideoInfo> {
  const url = new URL("https://www.googleapis.com/youtube/v3/videos");
  url.searchParams.set("part", "snippet,liveStreamingDetails");
  url.searchParams.set("id", params.videoId);
  applyAuth(url, params.auth);
  logger.debug(
    `${TAG} GET videos.list (videoId=${params.videoId}) ${redactUrl(url)}`,
  );
  const res = await fetch(url);
  if (!res.ok) {
    const body = await readErrorBody(res);
    const { reason, userMessage } = pickReason(res.status, body);
    logger.debug(
      `${TAG} videos.list failed: ${res.status} reason=${reason} message=${body.error?.message ?? "(none)"}`,
    );
    throw new YouTubeApiError({
      status: res.status,
      reason,
      message: body.error?.message ?? `videos.list HTTP ${res.status}`,
      userMessage,
    });
  }
  const data = (await res.json()) as {
    items?: Array<{
      id?: string;
      snippet?: { title?: string; channelTitle?: string };
      liveStreamingDetails?: {
        activeLiveChatId?: string;
        actualEndTime?: string;
      };
    }>;
  };
  const video = data.items?.[0];
  if (!video) {
    throw new YouTubeApiError({
      status: 404,
      reason: "videoNotFound",
      message: "Video not found",
      userMessage: "YouTube video not found.",
    });
  }
  const info: YouTubeVideoInfo = {
    liveChatId: video.liveStreamingDetails?.activeLiveChatId ?? null,
    title: video.snippet?.title ?? null,
    channelTitle: video.snippet?.channelTitle ?? null,
    hasEnded: typeof video.liveStreamingDetails?.actualEndTime === "string",
  };
  logger.debug(
    `${TAG} videos.list result: liveChatId=${info.liveChatId ? "present" : "none"} hasEnded=${info.hasEnded} title="${info.title ?? "-"}" channel="${info.channelTitle ?? "-"}"`,
  );
  return info;
}

export interface YouTubeLiveChatMessage {
  id: string;
  authorChannelId: string;
  authorDisplayName: string;
  text: string;
  publishedAtMs: number;
  isOwner: boolean;
  isModerator: boolean;
  isSponsor: boolean;
}

export interface YouTubeLiveChatPage {
  messages: YouTubeLiveChatMessage[];
  nextPageToken: string | null;
  pollingIntervalMs: number;
  offline: boolean;
}

export async function fetchLiveChatPage(params: {
  auth: YouTubeAuth;
  liveChatId: string;
  pageToken?: string | null;
}): Promise<YouTubeLiveChatPage> {
  const url = new URL(
    "https://www.googleapis.com/youtube/v3/liveChat/messages",
  );
  url.searchParams.set("part", "id,snippet,authorDetails");
  url.searchParams.set("liveChatId", params.liveChatId);
  url.searchParams.set("maxResults", "200");
  if (params.pageToken) {
    url.searchParams.set("pageToken", params.pageToken);
  }
  applyAuth(url, params.auth);
  logger.debug(
    `${TAG} GET liveChatMessages.list (pageToken=${params.pageToken ? params.pageToken.slice(0, 8) + "..." : "none"}) ${redactUrl(url)}`,
  );
  const res = await fetch(url);
  if (!res.ok) {
    const body = await readErrorBody(res);
    const { reason, userMessage } = pickReason(res.status, body);
    logger.debug(
      `${TAG} liveChatMessages.list failed: ${res.status} reason=${reason} message=${body.error?.message ?? "(none)"}`,
    );
    throw new YouTubeApiError({
      status: res.status,
      reason,
      message:
        body.error?.message ?? `liveChatMessages.list HTTP ${res.status}`,
      userMessage,
    });
  }
  const data = (await res.json()) as {
    nextPageToken?: string;
    pollingIntervalMillis?: number;
    offlineAt?: string;
    items?: Array<{
      id?: string;
      snippet?: {
        type?: string;
        publishedAt?: string;
        displayMessage?: string;
        textMessageDetails?: { messageText?: string };
      };
      authorDetails?: {
        channelId?: string;
        displayName?: string;
        isChatOwner?: boolean;
        isChatModerator?: boolean;
        isChatSponsor?: boolean;
      };
    }>;
  };
  const out: YouTubeLiveChatMessage[] = [];
  for (const item of data.items ?? []) {
    if (item.snippet?.type !== "textMessageEvent") continue;
    const id = item.id;
    const channelId = item.authorDetails?.channelId;
    if (!id || !channelId) continue;
    const text =
      item.snippet?.textMessageDetails?.messageText ??
      item.snippet?.displayMessage ??
      "";
    const publishedAtMs = item.snippet?.publishedAt
      ? Date.parse(item.snippet.publishedAt)
      : Date.now();
    const displayName = sanitizeYouTubeDisplayName(
      item.authorDetails?.displayName,
    );
    out.push({
      id,
      authorChannelId: channelId,
      authorDisplayName: displayName || channelId,
      text,
      publishedAtMs: Number.isFinite(publishedAtMs)
        ? publishedAtMs
        : Date.now(),
      isOwner: item.authorDetails?.isChatOwner === true,
      isModerator: item.authorDetails?.isChatModerator === true,
      isSponsor: item.authorDetails?.isChatSponsor === true,
    });
  }
  const result: YouTubeLiveChatPage = {
    messages: out,
    nextPageToken: data.nextPageToken ?? null,
    pollingIntervalMs:
      typeof data.pollingIntervalMillis === "number"
        ? data.pollingIntervalMillis
        : 5000,
    offline: typeof data.offlineAt === "string",
  };
  logger.debug(
    `${TAG} liveChatMessages.list result: ${result.messages.length} text msg(s), ${data.items?.length ?? 0} raw item(s), pollMs=${result.pollingIntervalMs}, offline=${result.offline}`,
  );
  return result;
}
