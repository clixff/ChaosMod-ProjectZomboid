export const DONATIONALERTS_API_BASE = "https://www.donationalerts.com/api/v1";
export const DONATIONALERTS_AUTH_URL = "https://www.donationalerts.com/oauth/authorize";
export const DONATIONALERTS_TOKEN_URL = "https://www.donationalerts.com/oauth/token";
export const DONATIONALERTS_CENTRIFUGO_WS_URL =
  "wss://centrifugo.donationalerts.com/connection/websocket";

export const DONATIONALERTS_SCOPES = [
  "oauth-user-show",
  "oauth-donation-subscribe",
  "oauth-donation-index",
] as const;
