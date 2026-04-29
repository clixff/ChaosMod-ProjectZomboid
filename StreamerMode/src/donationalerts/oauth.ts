import {
  DONATIONALERTS_AUTH_URL,
  DONATIONALERTS_SCOPES,
  DONATIONALERTS_TOKEN_URL,
} from "./constants.ts";
import { postForm } from "./http.ts";
import type {
  DonationAlertsRefreshTokenResponse,
  DonationAlertsTokenResponse,
} from "./types.ts";

export type DonationAlertsOAuthConfig = {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
};

export function buildDonationAlertsLoginUrl(config: DonationAlertsOAuthConfig): string {
  const url = new URL(DONATIONALERTS_AUTH_URL);
  url.searchParams.set("client_id", config.clientId);
  url.searchParams.set("redirect_uri", config.redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", DONATIONALERTS_SCOPES.join(" "));
  return url.toString();
}

export async function exchangeCodeForToken(
  config: DonationAlertsOAuthConfig,
  code: string,
): Promise<DonationAlertsTokenResponse> {
  return postForm<DonationAlertsTokenResponse>(DONATIONALERTS_TOKEN_URL, {
    grant_type: "authorization_code",
    client_id: config.clientId,
    client_secret: config.clientSecret,
    redirect_uri: config.redirectUri,
    code,
  });
}

export async function refreshDonationAlertsToken(
  config: DonationAlertsOAuthConfig,
  refreshToken: string,
): Promise<DonationAlertsRefreshTokenResponse> {
  return postForm<DonationAlertsRefreshTokenResponse>(DONATIONALERTS_TOKEN_URL, {
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    client_id: config.clientId,
    client_secret: config.clientSecret,
    scope: DONATIONALERTS_SCOPES.join(" "),
  });
}
