import colors from "colors";
import { logger } from "../utils/logger.ts";
import { buildDonationAlertsLoginUrl, exchangeCodeForToken, refreshDonationAlertsToken } from "./oauth.ts";
import { getCurrentDonationAlertsUser } from "./api.ts";
import { listenDonationAlertsDonations } from "./realtime.ts";
import type { DonationAlertsDonation, DonationAlertsUser } from "./types.ts";

const SERVICE = "chaos-mod-streamer-mode";

export class DonationAlertsProvider {
  readonly name = "DonationAlerts";
  readonly key = "donationalerts";
  readonly coloredName = colors.yellow("[DonationAlerts]");

  private ws: WebSocket | null = null;
  onDonation: ((donation: DonationAlertsDonation) => void) | null = null;
  currentUser: DonationAlertsUser | null = null;

  get isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }

  redirectUri(port: number): string {
    return `http://localhost:${port}/provider/donationalerts/success/`;
  }

  async loadCredentials(): Promise<{ appId: string; clientSecret: string; currency: string | null } | null> {
    const appId = await Bun.secrets.get({ service: SERVICE, name: "donationalerts-app-id" });
    const clientSecret = await Bun.secrets.get({ service: SERVICE, name: "donationalerts-client-secret" });
    const currency = await Bun.secrets.get({ service: SERVICE, name: "donationalerts-currency" });
    if (!appId || !clientSecret) return null;
    return { appId, clientSecret, currency };
  }

  async saveCredentials(appId: string, clientSecret: string, currency: string): Promise<void> {
    await Bun.secrets.set({ service: SERVICE, name: "donationalerts-app-id", value: appId });
    await Bun.secrets.set({ service: SERVICE, name: "donationalerts-client-secret", value: clientSecret });
    await Bun.secrets.set({ service: SERVICE, name: "donationalerts-currency", value: currency });
  }

  async deleteCredentials(): Promise<void> {
    await Bun.secrets.delete({ service: SERVICE, name: "donationalerts-app-id" });
    await Bun.secrets.delete({ service: SERVICE, name: "donationalerts-client-secret" });
    await Bun.secrets.delete({ service: SERVICE, name: "donationalerts-currency" });
  }

  async loadTokens(): Promise<{ accessToken: string; refreshToken: string } | null> {
    const accessToken = await Bun.secrets.get({ service: SERVICE, name: "donationalerts-access-token" });
    const refreshToken = await Bun.secrets.get({ service: SERVICE, name: "donationalerts-refresh-token" });
    if (!accessToken || !refreshToken) return null;
    return { accessToken, refreshToken };
  }

  async saveTokens(accessToken: string, refreshToken: string): Promise<void> {
    await Bun.secrets.set({ service: SERVICE, name: "donationalerts-access-token", value: accessToken });
    await Bun.secrets.set({ service: SERVICE, name: "donationalerts-refresh-token", value: refreshToken });
  }

  async deleteTokens(): Promise<void> {
    await Bun.secrets.delete({ service: SERVICE, name: "donationalerts-access-token" });
    await Bun.secrets.delete({ service: SERVICE, name: "donationalerts-refresh-token" });
  }

  getLoginUrl(port: number, appId: string): string {
    return buildDonationAlertsLoginUrl({
      clientId: appId,
      clientSecret: "",
      redirectUri: this.redirectUri(port),
    });
  }

  async handleOAuthCode(code: string, port: number): Promise<DonationAlertsUser | null> {
    const creds = await this.loadCredentials();
    if (!creds) {
      logger.error(`[DonationAlerts] No credentials stored — run: donate on donationalerts <app_id> <client_secret> <currency>`);
      return null;
    }

    let user: DonationAlertsUser;
    try {
      const tokenResponse = await exchangeCodeForToken(
        { clientId: creds.appId, clientSecret: creds.clientSecret, redirectUri: this.redirectUri(port) },
        code,
      );
      await this.saveTokens(tokenResponse.access_token, tokenResponse.refresh_token);
      user = await getCurrentDonationAlertsUser(tokenResponse.access_token);
      this.currentUser = user;
      await this.connectRealtime(tokenResponse.access_token, user);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to login: ${msg}`);
      return null;
    }

    return user;
  }

  async start(port: number): Promise<DonationAlertsUser | null> {
    const creds = await this.loadCredentials();
    if (!creds) return null;

    const tokens = await this.loadTokens();
    if (!tokens) return null;

    let { accessToken } = tokens;
    const { refreshToken } = tokens;

    const getUser = async (): Promise<DonationAlertsUser> => {
      try {
        return await getCurrentDonationAlertsUser(accessToken);
      } catch {
        const refreshed = await refreshDonationAlertsToken(
          { clientId: creds.appId, clientSecret: creds.clientSecret, redirectUri: this.redirectUri(port) },
          refreshToken,
        );
        accessToken = refreshed.access_token;
        const newRefreshToken = refreshed.refresh_token ?? refreshToken;
        await this.saveTokens(accessToken, newRefreshToken);
        return getCurrentDonationAlertsUser(accessToken);
      }
    };

    let user: DonationAlertsUser;
    try {
      user = await getUser();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to login: ${msg}`);
      return null;
    }

    this.currentUser = user;
    await this.connectRealtime(accessToken, user);
    return user;
  }

  private async connectRealtime(accessToken: string, user: DonationAlertsUser): Promise<void> {
    if (this.ws) {
      try { this.ws.close(); } catch { /* ignore */ }
      this.ws = null;
    }
    try {
      this.ws = await listenDonationAlertsDonations({
        accessToken,
        user,
        onDonation: (donation) => {
          this.onDonation?.(donation);
        },
        onLog: (msg) => {
          logger.debug(`[DonationAlerts] ${msg}`);
        },
        onError: (err) => {
          const msg = err instanceof Error ? err.message : String(err);
          logger.error(`[DonationAlerts] WebSocket error: ${msg}`);
        },
      });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to connect to realtime: ${msg}`);
    }
  }

  disconnect(): void {
    if (this.ws) {
      try { this.ws.close(); } catch { /* ignore */ }
      this.ws = null;
    }
    this.currentUser = null;
  }
}
