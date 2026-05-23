import type { CurrenciesConfig } from "../config.ts";

export const DEFAULT_CURRENCY_CODES: readonly string[] = [
  "USD",
  "EUR",
  "RUB",
  "GBP",
  "BRL",
  "TRY",
  "PLN",
  "UAH",
  "KZT",
  "CAD",
  "AUD",
  "MXN",
];

const ZERO_DECIMAL_CURRENCIES = new Set([
  "RUB",
  "KZT",
  "UAH",
  "JPY",
  "HUF",
  "KRW",
  "CLP",
  "ISK",
  "VND",
  "IDR",
]);

function roundToStep(value: number, step: number): number {
  if (step <= 0) return value;
  return Math.round(value / step) * step;
}

function stepForZeroDecimal(value: number): number {
  const abs = Math.abs(value);
  if (abs < 50) return 1;
  if (abs < 200) return 5;
  if (abs < 1000) return 10;
  return 50;
}

function stepForTwoDecimal(value: number): number {
  const abs = Math.abs(value);
  if (abs < 0.5) return 0.01;
  if (abs < 5) return 0.1;
  if (abs < 20) return 0.5;
  if (abs < 100) return 1;
  if (abs < 500) return 5;
  return 50;
}

export function smartRoundAmount(value: number, currencyCode: string): number {
  if (!Number.isFinite(value)) return 0;
  const code = currencyCode.trim().toUpperCase();
  const isZeroDecimal = ZERO_DECIMAL_CURRENCIES.has(code);
  const step = isZeroDecimal
    ? stepForZeroDecimal(value)
    : stepForTwoDecimal(value);
  const rounded = roundToStep(value, step);
  if (isZeroDecimal) return Math.round(rounded);
  return Math.round(rounded * 100) / 100;
}

/**
 * Smart-round a rate stored as `1 base = X quote`. The "natural-feel" direction
 * (whichever side has |value| >= 1) is rounded cleanly; the other direction
 * keeps full precision so the round-trip reverse always lands on the clean
 * number.
 *
 * Returns the rate to store in `currencies.list[quoteCode]`.
 */
export function smartRoundStoredRate(
  rate: number,
  baseCode: string,
  quoteCode: string,
): number {
  if (!Number.isFinite(rate) || rate <= 0) return 0;
  if (rate >= 1) {
    return smartRoundAmount(rate, quoteCode);
  }
  const inverse = 1 / rate;
  const roundedInverse = smartRoundAmount(inverse, baseCode);
  if (roundedInverse <= 0) return 0;
  return 1 / roundedInverse;
}

export function effectiveMain(
  currencies: CurrenciesConfig,
  daFallback: string | null | undefined,
): string {
  const main = currencies.main.trim().toUpperCase();
  if (main) return main;
  const fallback = (daFallback ?? "").trim().toUpperCase();
  return fallback;
}

export interface RequiredPriceResult {
  /** Required donation amount in the donor's currency, smart-rounded. */
  amount: number;
  /** Donor's currency code (uppercased). */
  currency: string;
}

/**
 * Compute the minimum donation amount in the donor's currency required to
 * activate an effect whose price is `priceInMain` (denominated in the
 * streamer's main currency). Returns `null` when the donation should be
 * ignored (no main + no DA fallback, or unknown currency).
 *
 * The result is smart-rounded in the donor's currency so it matches what the
 * dashboard spoiler advertises ("Group prices in USD — 2.8 USD"). This
 * guarantees a donor sending the advertised amount triggers the effect even
 * when the underlying rate has many decimals.
 */
export function requiredPriceInDonationCurrency(
  priceInMain: number,
  donationCurrency: string,
  currencies: CurrenciesConfig,
  daFallback: string | null | undefined,
): RequiredPriceResult | null {
  const main = currencies.main.trim().toUpperCase();
  const fromCode = donationCurrency.trim().toUpperCase();

  if (!main) {
    const fallback = (daFallback ?? "").trim().toUpperCase();
    if (!fallback) return null;
    if (fromCode !== fallback) return null;
    return { amount: priceInMain, currency: fallback };
  }

  if (fromCode === main) {
    return { amount: priceInMain, currency: main };
  }

  const rate = currencies.list[fromCode];
  if (typeof rate !== "number" || !Number.isFinite(rate) || rate <= 0) {
    return null;
  }
  return {
    amount: smartRoundAmount(priceInMain * rate, fromCode),
    currency: fromCode,
  };
}

interface RawExchangeRatesResponse {
  result?: string;
  base_code?: string;
  time_last_update_utc?: string;
  rates?: Record<string, unknown>;
}

export interface ExchangeRatesResult {
  base: string;
  rates: Record<string, number>;
  time_last_update_utc: string;
}

/**
 * Fetch exchange rates from open.er-api.com for `base`, filter to the 12 default
 * currencies, smart-round each rate, and return them. Throws on network or
 * malformed-response errors.
 */
export async function fetchExchangeRates(
  base: string,
): Promise<ExchangeRatesResult> {
  const code = base.trim().toUpperCase();
  if (!/^[A-Z]{3}$/.test(code)) {
    throw new Error(`Invalid base currency code: ${base}`);
  }
  const url = `https://open.er-api.com/v6/latest/${code}`;
  const res = await fetch(url);
  if (!res.ok) {
    throw new Error(`Exchange rate API returned HTTP ${res.status}`);
  }
  const data = (await res.json()) as RawExchangeRatesResponse;
  if (data.result && data.result !== "success") {
    throw new Error(`Exchange rate API result=${data.result}`);
  }
  const rawRates = data.rates ?? {};
  const rates: Record<string, number> = {};
  for (const target of DEFAULT_CURRENCY_CODES) {
    if (target === code) continue;
    const v = rawRates[target];
    if (typeof v !== "number" || !Number.isFinite(v) || v <= 0) continue;
    rates[target] = smartRoundStoredRate(v, code, target);
  }
  return {
    base: code,
    rates,
    time_last_update_utc: data.time_last_update_utc ?? "",
  };
}
