const CURRENCY_SYMBOLS: Record<string, string> = {
  USD: "$",
  EUR: "€",
  RUB: "₽",
  UAH: "₴",
  BRL: "R$",
  KZT: "₸",
  BYN: "Br",
};

export function formatCurrency(
  value: number,
  currencyCode: string | null | undefined,
): string {
  const formatted = value.toLocaleString(undefined, {
    maximumFractionDigits: 2,
  });
  if (!currencyCode) return `$${formatted}`;
  const code = currencyCode.toUpperCase();
  const symbol = CURRENCY_SYMBOLS[code];
  if (symbol) {
    // Symbols that read naturally as a suffix could be added here.
    return `${symbol}${formatted}`;
  }
  return `${formatted} ${code}`;
}
