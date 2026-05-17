import colors from "colors";
import { logger } from "../utils/logger.ts";
import {
  buildDonationAlertsLoginUrl,
  exchangeCodeForToken,
  refreshDonationAlertsToken,
} from "./oauth.ts";
import { getCurrentDonationAlertsUser } from "./api.ts";
import { listenDonationAlertsDonations } from "./realtime.ts";
import type { DonationAlertsDonation, DonationAlertsUser } from "./types.ts";

const SERVICE = "chaos-mod-streamer-mode";
const SECRET_NAME = "donationalerts";

const LEGACY_SECRET_NAMES = [
  "donationalerts-app-id",
  "donationalerts-client-secret",
  "donationalerts-currency",
  "donationalerts-access-token",
  "donationalerts-refresh-token",
] as const;

export interface DonationAlertsConfigView {
  app_id: string;
  currency: string;
}

export interface DonationAlertsSecrets {
  clientSecret: string;
  accessToken: string;
  refreshToken: string;
}

export class DonationAlertsProvider {
  readonly name = "DonationAlerts";
  readonly key = "donationalerts";
  readonly coloredName = colors.yellow("[DonationAlerts]");

  private readonly getDonationAlertsConfig: () => DonationAlertsConfigView | null;
  private ws: WebSocket | null = null;
  onDonation: ((donation: DonationAlertsDonation) => void) | null = null;
  onConnect: (() => void) | null = null;
  onDisconnect: (() => void) | null = null;
  currentUser: DonationAlertsUser | null = null;

  constructor(getDonationAlertsConfig: () => DonationAlertsConfigView | null) {
    this.getDonationAlertsConfig = getDonationAlertsConfig;
  }

  get isConnected(): boolean {
    return this.ws !== null && this.ws.readyState === WebSocket.OPEN;
  }

  getAppId(): string {
    return this.getDonationAlertsConfig()?.app_id ?? "";
  }

  getCurrency(): string {
    return this.getDonationAlertsConfig()?.currency ?? "";
  }

  redirectUri(port: number): string {
    return `http://localhost:${port}/provider/donationalerts/success/`;
  }

  /**
   * Delete the 5 pre-v1.1.2 keychain entries unconditionally. Idempotent —
   * deleting an already-deleted key is a no-op. Migration is intentionally
   * not performed: existing users are silently logged out.
   */
  static async cleanupLegacySecrets(): Promise<void> {
    for (const name of LEGACY_SECRET_NAMES) {
      try {
        await Bun.secrets.delete({ service: SERVICE, name });
      } catch {
        // Ignore — key may not exist.
      }
    }
  }

  async loadSecrets(): Promise<DonationAlertsSecrets | null> {
    let raw: string | null;
    try {
      raw = await Bun.secrets.get({ service: SERVICE, name: SECRET_NAME });
    } catch {
      return null;
    }
    if (!raw) return null;
    try {
      const parsed = JSON.parse(raw) as Record<string, unknown>;
      const clientSecret =
        typeof parsed["clientSecret"] === "string"
          ? parsed["clientSecret"]
          : "";
      const accessToken =
        typeof parsed["accessToken"] === "string" ? parsed["accessToken"] : "";
      const refreshToken =
        typeof parsed["refreshToken"] === "string"
          ? parsed["refreshToken"]
          : "";
      if (!clientSecret) return null;
      return { clientSecret, accessToken, refreshToken };
    } catch {
      return null;
    }
  }

  async saveSecrets(secrets: DonationAlertsSecrets): Promise<void> {
    await Bun.secrets.set({
      service: SERVICE,
      name: SECRET_NAME,
      value: JSON.stringify(secrets),
    });
  }

  async updateTokens(accessToken: string, refreshToken: string): Promise<void> {
    const existing = await this.loadSecrets();
    if (!existing) return;
    await this.saveSecrets({
      clientSecret: existing.clientSecret,
      accessToken,
      refreshToken,
    });
  }

  async deleteSecrets(): Promise<void> {
    try {
      await Bun.secrets.delete({ service: SERVICE, name: SECRET_NAME });
    } catch {
      // Ignore.
    }
  }

  getLoginUrl(port: number, appId: string): string {
    return buildDonationAlertsLoginUrl({
      clientId: appId,
      clientSecret: "",
      redirectUri: this.redirectUri(port),
    });
  }

  async handleOAuthCode(
    code: string,
    port: number,
  ): Promise<DonationAlertsUser | null> {
    const appId = this.getAppId();
    const secrets = await this.loadSecrets();
    if (!appId || !secrets) {
      logger.error(
        `[DonationAlerts] Not configured — open the dashboard DonationAlerts card to set up credentials.`,
      );
      return null;
    }

    let user: DonationAlertsUser;
    try {
      const tokenResponse = await exchangeCodeForToken(
        {
          clientId: appId,
          clientSecret: secrets.clientSecret,
          redirectUri: this.redirectUri(port),
        },
        code,
      );
      await this.saveSecrets({
        clientSecret: secrets.clientSecret,
        accessToken: tokenResponse.access_token,
        refreshToken: tokenResponse.refresh_token,
      });
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
    const appId = this.getAppId();
    if (!appId) return null;

    const secrets = await this.loadSecrets();
    if (!secrets || !secrets.accessToken || !secrets.refreshToken) return null;

    let accessToken = secrets.accessToken;
    const refreshToken = secrets.refreshToken;

    const getUser = async (): Promise<DonationAlertsUser> => {
      try {
        return await getCurrentDonationAlertsUser(accessToken);
      } catch {
        const refreshed = await refreshDonationAlertsToken(
          {
            clientId: appId,
            clientSecret: secrets.clientSecret,
            redirectUri: this.redirectUri(port),
          },
          refreshToken,
        );
        accessToken = refreshed.access_token;
        const newRefreshToken = refreshed.refresh_token ?? refreshToken;
        await this.updateTokens(accessToken, newRefreshToken);
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

  private async connectRealtime(
    accessToken: string,
    user: DonationAlertsUser,
  ): Promise<void> {
    if (this.ws) {
      try {
        this.ws.close();
      } catch {
        /* ignore */
      }
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
      if (this.ws) {
        const ws = this.ws;
        ws.addEventListener("close", () => {
          if (this.ws === ws) {
            this.ws = null;
            this.onDisconnect?.();
          }
        });
        this.onConnect?.();
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to connect to realtime: ${msg}`);
    }
  }

  disconnect(): void {
    if (this.ws) {
      try {
        this.ws.close();
      } catch {
        /* ignore */
      }
      this.ws = null;
      this.onDisconnect?.();
    }
    this.currentUser = null;
  }
}
