import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

const STORAGE_KEY = "chaosmod-hub-currency";
export const DEFAULT_CURRENCY = "USD";

export interface ConfigCurrencies {
  main: string;
  list: Record<string, number>;
}

interface CurrencyContextValue {
  selectedCurrency: string;
  setSelectedCurrency: (code: string) => void;
  availableCurrencies: string[];
  configCurrencies: ConfigCurrencies | null;
  setConfigCurrencies: (currencies: ConfigCurrencies | null) => void;
  getRateToSelected: (priceInMain: number) => {
    converted: number;
    currency: string;
  };
}

const CurrencyContext = createContext<CurrencyContextValue | null>(null);

function readStored(): string | null {
  if (typeof localStorage === "undefined") return null;
  try {
    const v = localStorage.getItem(STORAGE_KEY);
    return v && v.length > 0 ? v.toUpperCase() : null;
  } catch {
    return null;
  }
}

function persist(code: string): void {
  try {
    localStorage.setItem(STORAGE_KEY, code);
  } catch {
    // Ignore storage errors.
  }
}

function effectiveCurrencyList(config: ConfigCurrencies | null): string[] {
  if (!config) return [DEFAULT_CURRENCY];
  const main = config.main.trim().toUpperCase();
  const codes = new Set<string>();
  if (main) codes.add(main);
  for (const code of Object.keys(config.list)) {
    const upper = code.trim().toUpperCase();
    if (upper.length > 0) codes.add(upper);
  }
  if (codes.size === 0) return [DEFAULT_CURRENCY];
  return Array.from(codes);
}

function defaultForConfig(config: ConfigCurrencies | null): string {
  if (!config) return DEFAULT_CURRENCY;
  const main = config.main.trim().toUpperCase();
  if (main) return main;
  return DEFAULT_CURRENCY;
}

export function CurrencyProvider({ children }: { children: ReactNode }) {
  const [configCurrencies, setConfigCurrencies] =
    useState<ConfigCurrencies | null>(null);
  // `userChoice` is the explicit pick the user made (persisted to
  // localStorage). It overrides the config's main currency. `null` means the
  // user hasn't picked anything yet, so we fall back to the config's main
  // currency once it loads.
  const [userChoice, setUserChoice] = useState<string | null>(() => readStored());

  const availableCurrencies = useMemo(
    () => effectiveCurrencyList(configCurrencies),
    [configCurrencies],
  );

  // Effective currency = user choice when valid for the current config,
  // otherwise the config's main currency (or USD when no config).
  const selectedCurrency = useMemo(() => {
    if (userChoice && availableCurrencies.includes(userChoice)) {
      return userChoice;
    }
    return defaultForConfig(configCurrencies);
  }, [userChoice, availableCurrencies, configCurrencies]);

  const setSelectedCurrency = useCallback((code: string) => {
    const upper = code.trim().toUpperCase();
    setUserChoice(upper);
    persist(upper);
  }, []);

  const getRateToSelected = useCallback(
    (priceInMain: number): { converted: number; currency: string } => {
      if (!configCurrencies) {
        return { converted: priceInMain, currency: DEFAULT_CURRENCY };
      }
      const main = configCurrencies.main.trim().toUpperCase();
      if (!main) {
        return { converted: priceInMain, currency: DEFAULT_CURRENCY };
      }
      if (selectedCurrency === main) {
        return { converted: priceInMain, currency: main };
      }
      const rate = configCurrencies.list[selectedCurrency];
      if (typeof rate !== "number" || !Number.isFinite(rate) || rate <= 0) {
        return { converted: priceInMain, currency: main };
      }
      return {
        converted: smartRoundAmount(priceInMain * rate, selectedCurrency),
        currency: selectedCurrency,
      };
    },
    [configCurrencies, selectedCurrency],
  );

  const value = useMemo(
    () => ({
      selectedCurrency,
      setSelectedCurrency,
      availableCurrencies,
      configCurrencies,
      setConfigCurrencies,
      getRateToSelected,
    }),
    [
      selectedCurrency,
      setSelectedCurrency,
      availableCurrencies,
      configCurrencies,
      getRateToSelected,
    ],
  );

  return (
    <CurrencyContext.Provider value={value}>
      {children}
    </CurrencyContext.Provider>
  );
}

export function useCurrency(): CurrencyContextValue {
  const ctx = useContext(CurrencyContext);
  if (!ctx) throw new Error("useCurrency must be used inside CurrencyProvider");
  return ctx;
}

/**
 * Returns a function that converts a price in the streamer's main currency to
 * the user-selected display currency and returns `{ converted, currency }`.
 * `priceInMain` of `null` short-circuits to `{ converted: null, currency }`.
 */
export function useConvertPrice(): (
  priceInMain: number | null,
) => { converted: number | null; currency: string } {
  const { getRateToSelected, selectedCurrency } = useCurrency();
  return useCallback(
    (priceInMain: number | null) => {
      if (priceInMain == null) {
        return { converted: null, currency: selectedCurrency };
      }
      return getRateToSelected(priceInMain);
    },
    [getRateToSelected, selectedCurrency],
  );
}

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

function roundToStep(value: number, step: number): number {
  if (step <= 0) return value;
  return Math.round(value / step) * step;
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
