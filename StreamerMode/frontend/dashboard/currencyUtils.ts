// Mirror of the smart-rounding logic in `src/utils/currencies.ts` so the
// dashboard can format converted prices without a roundtrip. Keep both
// implementations in sync.

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

export function smartRoundAmount(value: number, code: string): number {
  if (!Number.isFinite(value)) return 0;
  const c = code.trim().toUpperCase();
  const isZero = ZERO_DECIMAL_CURRENCIES.has(c);
  const step = isZero ? stepForZeroDecimal(value) : stepForTwoDecimal(value);
  const rounded = roundToStep(value, step);
  if (isZero) return Math.round(rounded);
  return Math.round(rounded * 100) / 100;
}

const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: "$",
  EUR: "€",
  RUB: "₽",
  GBP: "£",
  BRL: "R$",
  TRY: "₺",
  PLN: "zł",
  UAH: "₴",
  KZT: "₸",
  CAD: "CA$",
  AUD: "A$",
  MXN: "Mex$",
  BYN: "Br",
  JPY: "¥",
  KRW: "₩",
  CNY: "¥",
  HUF: "Ft",
  CLP: "CLP$",
  ISK: "kr",
  VND: "₫",
  IDR: "Rp",
};

const CURRENCY_NAMES: Record<string, string> = {
  USD: "US Dollar",
  EUR: "Euro",
  RUB: "Russian Ruble",
  GBP: "British Pound",
  BRL: "Brazilian Real",
  TRY: "Turkish Lira",
  PLN: "Polish Złoty",
  UAH: "Ukrainian Hryvnia",
  KZT: "Kazakhstani Tenge",
  CAD: "Canadian Dollar",
  AUD: "Australian Dollar",
  MXN: "Mexican Peso",
  BYN: "Belarusian Ruble",
  JPY: "Japanese Yen",
  KRW: "South Korean Won",
  CNY: "Chinese Yuan",
  HUF: "Hungarian Forint",
  CLP: "Chilean Peso",
  ISK: "Icelandic Króna",
  VND: "Vietnamese Dong",
  IDR: "Indonesian Rupiah",
};

export function getCurrencySymbol(code: string): string {
  return CURRENCY_SYMBOLS[code.trim().toUpperCase()] ?? "";
}

export function getCurrencyName(code: string): string {
  return CURRENCY_NAMES[code.trim().toUpperCase()] ?? "";
}
