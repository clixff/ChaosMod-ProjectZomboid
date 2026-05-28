import { logger } from "../utils/logger.ts";
import type { DonationAlertsProvider } from "../donationalerts/DonationAlertsProvider.ts";
import type { DonationAlertsDonation } from "../donationalerts/types.ts";
import type { CurrenciesConfig } from "../config.ts";
import { requiredPriceInDonationCurrency } from "../utils/currencies.ts";

interface EffectEntry {
  id: number;
  effect_id: string;
  enabled_donate: boolean;
  price_result: number | null | undefined;
}

interface EffectsApiResponse {
  effects: EffectEntry[];
}

export type DonationActivationFailure =
  | {
      type: "price_too_low";
      effect_id: string;
      nickname: string;
      donation_amount: number;
      required_price: number;
    }
  | {
      type: "donations_disabled";
      effect_id: string;
      nickname: string;
      donation_amount: number;
    };

export function parseEffectTag(message: string): string | null {
  const hashMatch = message.match(/#(\w+)/);
  if (hashMatch && hashMatch[1]) return hashMatch[1];

  const prefixedNumberMatch = message.match(/(?:№|!)\s*(\d+)/);
  if (prefixedNumberMatch && prefixedNumberMatch[1])
    return prefixedNumberMatch[1];

  const bareNumberMatch = message.match(/(?:^|\s)(\d+)(?=\s|$|\D)/);
  if (bareNumberMatch && bareNumberMatch[1]) return bareNumberMatch[1];

  return null;
}

export class DonationManager {
  private readonly providers: DonationAlertsProvider[] = [];

  onActivationFailed: ((info: DonationActivationFailure) => void) | null = null;

  constructor(
    private readonly port: number,
    private readonly getCurrencies: () => CurrenciesConfig,
  ) {}

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

    const currencies = this.getCurrencies();
    const daFallback = provider.getCurrency();
    const donationCurrency = donation.currency.toUpperCase();

    const effectTag = parseEffectTag(donation.message);
    if (!effectTag) return;

    logger.debug(`[DonationAlerts] Effect tag found: ${effectTag}`);

    let effectsData: EffectsApiResponse;
    try {
      const res = await fetch(`http://localhost:${this.port}/mod/effects`);
      effectsData = (await res.json()) as EffectsApiResponse;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to fetch effects: ${msg}`);
      return;
    }

    const effect = effectsData.effects.find((entry) => {
      if (entry.effect_id === effectTag) {
        return true;
      }

      if (!/^\d+$/.test(effectTag)) {
        return false;
      }

      return entry.id === Number.parseInt(effectTag, 10);
    });
    if (!effect) return;

    if (!effect.enabled_donate) {
      logger.debug(
        `[DonationAlerts] Effect ${effect.effect_id} has donations disabled (donation amount ${donation.amount} ${donationCurrency} from ${donation.username})`,
      );
      this.onActivationFailed?.({
        type: "donations_disabled",
        effect_id: effect.effect_id,
        nickname: donation.username ?? "",
        donation_amount: donation.amount,
      });
      return;
    }

    if (effect.price_result == null) return;

    const required = requiredPriceInDonationCurrency(
      effect.price_result,
      donation.currency,
      currencies,
      daFallback,
    );
    if (!required) {
      const mainConfigured = currencies.main.trim().toUpperCase();
      const fallbackConfigured = (daFallback ?? "").trim().toUpperCase();
      if (!mainConfigured && !fallbackConfigured) {
        logger.warn(
          `[DonationAlerts] Donation ignored: no main currency or DA fallback configured.`,
        );
      } else {
        logger.debug(
          `[DonationAlerts] Donation ignored: currency ${donationCurrency} has no conversion rate (main=${mainConfigured || fallbackConfigured}).`,
        );
      }
      return;
    }

    if (donation.amount < required.amount) {
      logger.debug(
        `[DonationAlerts] Donation ${donation.amount} ${donationCurrency} < required ${required.amount} ${required.currency} for effect ${effect.effect_id}`,
      );
      this.onActivationFailed?.({
        type: "price_too_low",
        effect_id: effect.effect_id,
        nickname: donation.username ?? "",
        donation_amount: donation.amount,
        required_price: required.amount,
      });
      return;
    }

    try {
      const url = new URL(`http://localhost:${this.port}/mod/activate-effect`);
      url.searchParams.set("effect", effect.effect_id);
      url.searchParams.set("nickname", donation.username ?? "");
      const res = await fetch(url.toString());
      if (!res.ok) {
        const body = await res.text();
        logger.warn(
          `[DonationAlerts] activate-effect returned ${res.status}: ${body}`,
        );
      } else {
        logger.info(
          `[DonationAlerts] Activated effect ${effect.effect_id} (#${effect.id}) for ${donation.username}`,
        );
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      logger.error(`[DonationAlerts] Failed to activate effect: ${msg}`);
    }
  }
}
