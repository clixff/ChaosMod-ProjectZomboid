import colors from "colors";
import open from "open";
import { logger } from "../utils/logger.ts";
import { saveConfig, type ModConfig } from "../config.ts";
import type { App } from "../cli/App.ts";
import type { DonationAlertsProvider } from "../donationalerts/DonationAlertsProvider.ts";

export function registerDonateCommand(
  app: App,
  port: number,
  daProvider: DonationAlertsProvider,
  luaFolder: string | null,
  config: ModConfig | null,
  onConfigSaved?: () => void,
): void {
  app.registerCommand(
    "donate",
    [],
    [
      { name: "on|off|login" },
      { name: "donationalerts" },
      { name: "app_id" },
      { name: "client_secret" },
      { name: "currency" },
    ],
    async (args) => {
      const subCmd = args[0]?.toLowerCase();
      const providerName = args[1]?.toLowerCase();

      if (!subCmd) {
        console.log(colors.bold("\nDonation providers:"));
        const appId = daProvider.getAppId();
        const secrets = await daProvider.loadSecrets();
        const hasConfig = !!appId && !!secrets;
        const user = daProvider.currentUser;
        const wsStatus = daProvider.isConnected
          ? colors.green("websocket connected")
          : colors.yellow("websocket disconnected");
        const status = user
          ? colors.green(`logged in as ${colors.cyan(user.name)}`) +
            colors.gray(", ") +
            wsStatus
          : hasConfig
            ? colors.yellow("credentials saved, not logged in")
            : colors.gray("not configured");
        console.log(`  ${colors.yellow("donationalerts")} — ${status}`);
        console.log("");
        return;
      }

      if (!providerName) {
        logger.warn(
          `Usage: ${colors.cyan("donate on|off|login donationalerts [app_id client_secret currency]")}`,
        );
        return;
      }

      if (providerName !== "donationalerts") {
        logger.warn(`Unknown donate provider: ${colors.cyan(providerName)}`);
        return;
      }

      if (subCmd === "on") {
        const appId = args[2];
        const clientSecret = args[3];
        const currency = args[4]?.toUpperCase();

        if (!appId || !clientSecret || !currency) {
          logger.info(`To enable DonationAlerts donations:`);
          logger.info(
            `1. Open ${colors.cyan("https://www.donationalerts.com/application/clients")} and create an application.`,
          );
          logger.info(
            `2. Set the redirect URI to: ${colors.cyan(`http://localhost:${port}/provider/donationalerts/success/`)}`,
          );
          logger.info(
            `3. Run: ${colors.cyan(`donate on donationalerts <app_id> <client_secret> <currency>`)}`,
          );
          logger.info(
            `   Example: ${colors.cyan(`donate on donationalerts 123456 your_secret RUB`)}`,
          );
          await open("https://www.donationalerts.com/application/clients");
          return;
        }

        if (!/^[A-Z]{3}$/.test(currency)) {
          logger.warn(
            `[DonationAlerts] Currency must be exactly 3 letters, for example ${colors.cyan("RUB")}.`,
          );
          return;
        }

        await daProvider.saveSecrets({
          clientSecret,
          accessToken: "",
          refreshToken: "",
        });
        if (config && luaFolder) {
          let changed = false;
          const da = config.streamer_mode.donation_systems.donationalerts;
          if (da.app_id !== appId) {
            da.app_id = appId;
            changed = true;
          }
          if (da.currency !== currency) {
            da.currency = currency;
            changed = true;
          }
          if (!da.enabled) {
            da.enabled = true;
            changed = true;
          }
          if (!config.streamer_mode.enable_donate) {
            config.streamer_mode.enable_donate = true;
            changed = true;
          }
          if (changed) {
            saveConfig(luaFolder, config);
            onConfigSaved?.();
          }
        }
        logger.info(
          `[DonationAlerts] App credentials saved with currency ${currency}. Opening login...`,
        );
        const loginUrl = daProvider.getLoginUrl(port, appId);
        await open(loginUrl);
        return;
      }

      if (subCmd === "off") {
        daProvider.disconnect();
        await daProvider.deleteSecrets();
        if (config && luaFolder) {
          if (config.streamer_mode.donation_systems.donationalerts.enabled) {
            config.streamer_mode.donation_systems.donationalerts.enabled = false;
            saveConfig(luaFolder, config);
            onConfigSaved?.();
          }
        }
        logger.info(`[DonationAlerts] Logged out and client secret removed.`);
        return;
      }

      if (subCmd === "login") {
        const appId = daProvider.getAppId();
        const secrets = await daProvider.loadSecrets();
        if (!appId || !secrets) {
          logger.warn(
            `[DonationAlerts] Not configured. Run: ${colors.cyan("donate on donationalerts <app_id> <client_secret> <currency>")}`,
          );
          return;
        }
        const loginUrl = daProvider.getLoginUrl(port, appId);
        logger.info(`[DonationAlerts] Opening login URL...`);
        await open(loginUrl);
        return;
      }

      logger.warn(
        `Usage: ${colors.cyan("donate on|off|login donationalerts [app_id client_secret currency]")}`,
      );
    },
    "Manage donation provider login",
  );
}
