import { logger } from "../utils/logger.ts";
import type { DonationAlertsProvider } from "../donationalerts/DonationAlertsProvider.ts";
import type { DonationAlertsDonation } from "../donationalerts/types.ts";

interface EffectEntry {
  id: string;
  enabled_donate: boolean;
  price_result: number | null | undefined;
}

interface EffectsApiResponse {
  effects: EffectEntry[];
}

export class DonationManager {
  private readonly providers: DonationAlertsProvider[] = [];

  constructor(private readonly port: number) {}

  addProvider(provider: DonationAlertsProvider): void {
    provider.onDonation = (donation) => {
      this.handleDonation(provider, donation).catch((e: unknown) => {
        const msg = e instanceof Error ? e.message : String(e);
        logger.error(`[DonationManager] Error handling donation: ${msg}`);
      });
    };
    this.providers.push(provider);
  }

  private async handleDonation(
    provider: DonationAlertsProvider,
    donation: DonationAlertsDonation,
  ): Promise<void> {
    logger.debug(
      `[DonationAlerts] Donation from ${donation.username}: amount=${donation.amount} ${donation.currency} message="${donation.message}"`,
    );

    const creds = await provider.loadCredentials();
    const configuredCurrency = creds?.currency?.toUpperCase() ?? null;
    const donationCurrency = donation.currency.toUpperCase();

    if (!configuredCurrency) {
      logger.warn(
        `[DonationAlerts] Donation ignored: no configured currency stored for provider.`,
      );
      return;
    }

    if (donationCurrency !== configuredCurrency) {
      logger.debug(
        `[DonationAlerts] Donation ignored: currency ${donationCurrency} does not match configured ${configuredCurrency}.`,
      );
      return;
    }

    const match = donation.message.match(/#([\w]+)/);
    if (!match) return;
    const effectId = match[1];

    logger.debug(`[DonationAlerts] Effect tag found: #${effectId}`);

    let effectsData: EffectsApiResponse;
    try {
      const res = await fetch(`http://localhost:${this.port}/mod/effects`);
      effectsData = (await res.json()) as EffectsApiResponse;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to fetch effects: ${msg}`);
      return;
    }

    const effect = effectsData.effects.find((e) => e.id === effectId);
    if (!effect || !effect.enabled_donate || effect.price_result == null)
      return;

    if (donation.amount < effect.price_result) {
      logger.debug(
        `[DonationAlerts] Donation amount ${donation.amount} < required ${effect.price_result} for effect ${effectId}`,
      );
      return;
    }

    try {
      const url = new URL(`http://localhost:${this.port}/mod/activate-effect`);
      if (effectId) {
        url.searchParams.set("effect", effectId);
      }
      url.searchParams.set("nickname", donation.username ?? "");
      const res = await fetch(url.toString());
      if (!res.ok) {
        const body = await res.text();
        logger.warn(
          `[DonationAlerts] activate-effect returned ${res.status}: ${body}`,
        );
      } else {
        logger.info(
          `[DonationAlerts] Activated effect ${effectId} for ${donation.username}`,
        );
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to activate effect: ${msg}`);
    }
  }
}
