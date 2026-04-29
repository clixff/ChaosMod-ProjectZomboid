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
  modFolder: string | null,
  config: ModConfig | null,
): void {
  app.registerCommand(
    "donate",
    [],
    [
      { name: "on|off|login" },
      { name: "donationalerts" },
      { name: "app_id" },
      { name: "client_secret" },
    ],
    async (args) => {
      const subCmd = args[0]?.toLowerCase();
      const providerName = args[1]?.toLowerCase();

      if (!subCmd) {
        console.log(colors.bold("\nDonation providers:"));
        const hasCreds = !!(await daProvider.loadCredentials());
        const user = daProvider.currentUser;
        const wsStatus = daProvider.isConnected
          ? colors.green("websocket connected")
          : colors.yellow("websocket disconnected");
        const status = user
          ? colors.green(`logged in as ${colors.cyan(user.name)}`) + colors.gray(", ") + wsStatus
          : hasCreds
            ? colors.yellow("credentials saved, not logged in")
            : colors.gray("not configured");
        console.log(`  ${colors.yellow("donationalerts")} — ${status}`);
        console.log("");
        return;
      }

      if (!providerName) {
        logger.warn(
          `Usage: ${colors.cyan("donate on|off|login donationalerts [app_id client_secret]")}`,
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

        if (!appId || !clientSecret) {
          logger.info(`To enable DonationAlerts donations:`);
          logger.info(
            `1. Open ${colors.cyan("https://www.donationalerts.com/application/clients")} and create an application.`,
          );
          logger.info(
            `2. Set the redirect URI to: ${colors.cyan(`http://localhost:${port}/provider/donationalerts/success/`)}`,
          );
          logger.info(
            `3. Run: ${colors.cyan(`donate on donationalerts <app_id> <client_secret>`)}`,
          );
          await open("https://www.donationalerts.com/application/clients");
          return;
        }

        await daProvider.saveCredentials(appId, clientSecret);
        if (config && modFolder) {
          if (!config.streamer_mode.donate_providers.includes("donationalerts")) {
            config.streamer_mode.donate_providers.push("donationalerts");
            saveConfig(modFolder, config);
          }
        }
        logger.info(`[DonationAlerts] App credentials saved. Opening login...`);
        const loginUrl = daProvider.getLoginUrl(port, appId);
        await open(loginUrl);
        return;
      }

      if (subCmd === "off") {
        daProvider.disconnect();
        await daProvider.deleteTokens();
        await daProvider.deleteCredentials();
        if (config && modFolder) {
          config.streamer_mode.donate_providers = config.streamer_mode.donate_providers.filter(
            (p) => p !== "donationalerts",
          );
          saveConfig(modFolder, config);
        }
        logger.info(`[DonationAlerts] Logged out and credentials removed.`);
        return;
      }

      if (subCmd === "login") {
        const creds = await daProvider.loadCredentials();
        if (!creds) {
          logger.warn(
            `[DonationAlerts] No credentials stored. Run: ${colors.cyan("donate on donationalerts <app_id> <client_secret>")}`,
          );
          return;
        }
        const loginUrl = daProvider.getLoginUrl(port, creds.appId);
        logger.info(`[DonationAlerts] Opening login URL...`);
        await open(loginUrl);
        return;
      }

      logger.warn(
        `Usage: ${colors.cyan("donate on|off|login donationalerts [app_id client_secret]")}`,
      );
    },
    "Manage donation provider login",
  );
}
