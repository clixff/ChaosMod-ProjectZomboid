import { useMemo, useState } from "react";
import { Info, LogIn, Plus, RefreshCw, Trash2 } from "lucide-react";
import { Modal } from "./Modal.tsx";
import { TextInput, NumberInput } from "./Input.tsx";
import {
  getCurrencyExchangeRates,
  type CurrenciesConfig,
  type DonatePriceGroup,
} from "../api.ts";

const CURRENCY_ROW_COLORS = [
  "#ef5350",
  "#ff9800",
  "#fbc02d",
  "#66bb6a",
  "#26c6da",
  "#42a5f5",
  "#7e57c2",
  "#ec407a",
];

const DEFAULT_CURRENCY_CODES = [
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

const CURRENCY_NAMES: Record<string, string> = {
  USD: "US Dollar",
  EUR: "Euro",
  RUB: "Russian Ruble",
  GBP: "British Pound",
  BRL: "Brazilian Real",
  TRY: "Turkish Lira",
  PLN: "Polish Zloty",
  UAH: "Ukrainian Hryvnia",
  KZT: "Kazakhstani Tenge",
  CAD: "Canadian Dollar",
  AUD: "Australian Dollar",
  MXN: "Mexican Peso",
  JPY: "Japanese Yen",
  CNY: "Chinese Yuan",
  KRW: "South Korean Won",
  INR: "Indian Rupee",
  CHF: "Swiss Franc",
  SEK: "Swedish Krona",
  NOK: "Norwegian Krone",
  DKK: "Danish Krone",
  CZK: "Czech Koruna",
  HUF: "Hungarian Forint",
  RON: "Romanian Leu",
  BGN: "Bulgarian Lev",
  HKD: "Hong Kong Dollar",
  SGD: "Singapore Dollar",
  NZD: "New Zealand Dollar",
  ZAR: "South African Rand",
  THB: "Thai Baht",
  IDR: "Indonesian Rupiah",
  PHP: "Philippine Peso",
  MYR: "Malaysian Ringgit",
  VND: "Vietnamese Dong",
  ARS: "Argentine Peso",
  CLP: "Chilean Peso",
  COP: "Colombian Peso",
  PEN: "Peruvian Sol",
  ILS: "Israeli Shekel",
  AED: "UAE Dirham",
  SAR: "Saudi Riyal",
  BYN: "Belarusian Ruble",
};

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

// Smart-round the natural-feel side of `1 base = X quote`. When the rate is
// >= 1 we round X directly; when X < 1 we round the inverse in the base's step
// and store rate = 1/round. Keeps the natural-feel direction on a clean
// number while preserving full precision in the small-value direction.
export function smartRoundStoredRate(
  rate: number,
  baseCode: string,
  quoteCode: string,
): number {
  if (!Number.isFinite(rate) || rate <= 0) return 0;
  if (rate >= 1) return smartRoundAmount(rate, quoteCode);
  const inverse = 1 / rate;
  const rounded = smartRoundAmount(inverse, baseCode);
  if (rounded <= 0) return 0;
  return 1 / rounded;
}


interface CurrencyRow {
  code: string;
  rate: number;
}

function buildInitialRows(currencies: CurrenciesConfig): CurrencyRow[] {
  return Object.entries(currencies.list).map(([code, rate]) => ({
    code: code.toUpperCase(),
    rate,
  }));
}

interface CurrenciesModalProps {
  currencies: CurrenciesConfig;
  priceGroups: DonatePriceGroup[];
  daFallbackCurrency: string;
  onClose: () => void;
  onSave: (next: CurrenciesConfig) => void;
  onNotify: (message: string, isError?: boolean) => void;
}

export function CurrenciesModal({
  currencies,
  priceGroups,
  daFallbackCurrency,
  onClose,
  onSave,
  onNotify,
}: CurrenciesModalProps) {
  const initialMain = useMemo(() => {
    const m = currencies.main.trim().toUpperCase();
    if (m) return m;
    const fallback = daFallbackCurrency.trim().toUpperCase();
    if (fallback) return fallback;
    return "USD";
  }, [currencies.main, daFallbackCurrency]);

  const initialRows = useMemo<CurrencyRow[]>(() => {
    const existing = buildInitialRows(currencies);
    if (existing.length > 0) return existing;
    return DEFAULT_CURRENCY_CODES.filter((c) => c !== initialMain).map(
      (code) => ({ code, rate: 1 }),
    );
  }, [currencies, initialMain]);

  const [main, setMain] = useState(initialMain);
  const [rows, setRows] = useState<CurrencyRow[]>(initialRows);
  const [loading, setLoading] = useState(false);
  const [expanded, setExpanded] = useState<Record<number, boolean>>({});

  const mainUpper = main.trim().toUpperCase();
  const mainValid = /^[A-Z]{3}$/.test(mainUpper);

  const duplicateCodes = useMemo(() => {
    const seen = new Set<string>();
    const dups = new Set<string>();
    for (const r of rows) {
      const c = r.code.trim().toUpperCase();
      if (!c) continue;
      if (c === mainUpper) {
        dups.add(c);
        continue;
      }
      if (seen.has(c)) dups.add(c);
      else seen.add(c);
    }
    return dups;
  }, [rows, mainUpper]);

  const allCodesValid = useMemo(
    () =>
      rows.every((r) => /^[A-Z]{3}$/.test(r.code.trim().toUpperCase())) &&
      rows.every((r) => Number.isFinite(r.rate) && r.rate > 0),
    [rows],
  );

  const canSave =
    mainValid && allCodesValid && duplicateCodes.size === 0 && !loading;

  const loadExchangeRates = async () => {
    if (!mainValid) {
      onNotify("Enter a valid 3-letter main currency code first.", true);
      return;
    }
    setLoading(true);
    try {
      const result = await getCurrencyExchangeRates(mainUpper);
      const nextRows = Object.entries(result.rates).map(([code, rate]) => ({
        code,
        rate,
      }));
      setRows(nextRows);
      onNotify(
        `Loaded ${nextRows.length} exchange rates for ${mainUpper}.`,
      );
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onNotify(`Failed to load exchange rates: ${msg}`, true);
    } finally {
      setLoading(false);
    }
  };

  const updateRowCode = (idx: number, code: string) => {
    const cleaned = code.toUpperCase().replace(/[^A-Z]/g, "").slice(0, 3);
    setRows((prev) =>
      prev.map((r, i) => (i === idx ? { ...r, code: cleaned } : r)),
    );
  };

  const updateRowRate = (idx: number, rate: number) => {
    setRows((prev) =>
      prev.map((r, i) => (i === idx ? { ...r, rate } : r)),
    );
  };

  const updateRowInverseRate = (idx: number, inverse: number) => {
    if (!Number.isFinite(inverse) || inverse <= 0) return;
    const row = rows[idx];
    if (!row) return;
    // Inverse is the natural-feel side (1 quote = X main); store rate as the
    // exact inverse so reverse displays land on the clean typed value.
    const forward = 1 / inverse;
    setRows((prev) =>
      prev.map((r, i) => (i === idx ? { ...r, rate: forward } : r)),
    );
  };

  const removeRow = (idx: number) => {
    setRows((prev) => prev.filter((_, i) => i !== idx));
  };

  const addRow = () => {
    setRows((prev) => [...prev, { code: "", rate: 1 }]);
  };

  const handleSave = () => {
    if (!canSave) return;
    const list: Record<string, number> = {};
    for (const r of rows) {
      const code = r.code.trim().toUpperCase();
      if (!/^[A-Z]{3}$/.test(code)) continue;
      if (code === mainUpper) continue;
      list[code] = r.rate;
    }
    onSave({ main: mainUpper, list });
  };

  return (
    <Modal title="Edit Currencies" onClose={onClose} wide>
      <p
        style={{
          marginTop: 0,
          marginBottom: 12,
          fontSize: 13,
          opacity: 0.8,
        }}
      >
        The currencies system works only with DonationAlerts for now.
      </p>

      <div
        style={{
          marginTop: 0,
          marginBottom: 12,
          padding: "8px 10px",
          border: "1px solid rgba(245, 179, 1, 0.4)",
          borderRadius: 6,
          background: "rgba(245, 179, 1, 0.08)",
          color: "#f5b301",
          lineHeight: 1.5,
          display: "flex",
          alignItems: "flex-start",
          gap: 8,
          fontSize: 13,
        }}
      >
        <Info
          size={16}
          aria-hidden="true"
          style={{ marginTop: 2, flexShrink: 0 }}
        />
        <div>
          Note: It is recommended to set prices for effects on the settings
          page first.
        </div>
      </div>

      <div className="form-grid" style={{ marginBottom: 12 }}>
        <label className="form-field">
          <span className="form-label">Main Currency</span>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <TextInput
              size="mid"
              value={main}
              onChange={(v) =>
                setMain(v.toUpperCase().replace(/[^A-Z]/g, "").slice(0, 3))
              }
              placeholder="USD, EUR, RUB, etc."
            />
            {mainValid && CURRENCY_NAMES[mainUpper] && (
              <span style={{ opacity: 0.7, fontSize: 13 }}>
                {CURRENCY_NAMES[mainUpper]}
              </span>
            )}
          </div>
          {!mainValid && (
            <span
              className="field-hint"
              style={{ color: "#f5b301", marginTop: 4 }}
            >
              Enter a valid 3-letter ISO currency code.
            </span>
          )}
        </label>
      </div>

      <div style={{ marginBottom: 16 }}>
        <button
          className="btn"
          onClick={() => void loadExchangeRates()}
          disabled={!mainValid || loading}
          title="Wipe the list and load fresh rates from open.er-api.com"
        >
          <RefreshCw
            size={14}
            aria-hidden="true"
            className={loading ? "spin" : undefined}
          />
          {loading ? "Loading…" : "Load exchange rates"}
        </button>
      </div>

      <div
        style={{ display: "flex", flexDirection: "column", gap: 16 }}
      >
        {rows.length === 0 && (
          <span className="field-hint">No currencies configured yet.</span>
        )}
        {rows.map((row, idx) => {
          const code = row.code.trim().toUpperCase();
          const codeValid = /^[A-Z]{3}$/.test(code);
          const isDuplicate = duplicateCodes.has(code);
          const inverse =
            row.rate > 0 ? smartRoundAmount(1 / row.rate, mainUpper) : 0;
          const open = expanded[idx] ?? false;
          const accentColor =
            CURRENCY_ROW_COLORS[idx % CURRENCY_ROW_COLORS.length];
          return (
            <div
              key={idx}
              style={{
                border: "1px solid #2a2a2a",
                borderLeft: `4px solid ${accentColor}`,
                borderRadius: 6,
                borderTopLeftRadius: 0,
                borderBottomLeftRadius: 0,
                padding: 12,
                background: "#0d0d0d",
              }}
            >
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  marginBottom: 8,
                }}
              >
                <TextInput
                  size="mid"
                  value={row.code}
                  onChange={(v) => updateRowCode(idx, v)}
                  placeholder="EUR"
                />
                {codeValid && CURRENCY_NAMES[code] && (
                  <span style={{ opacity: 0.7, fontSize: 13 }}>
                    {CURRENCY_NAMES[code]}
                  </span>
                )}
                <button
                  className="btn btn--danger"
                  title="Remove this currency"
                  onClick={() => removeRow(idx)}
                  style={{ marginLeft: "auto" }}
                >
                  <Trash2 size={14} aria-hidden="true" />
                  Remove
                </button>
                {!codeValid && (
                  <span
                    className="field-hint"
                    style={{ color: "#f5b301" }}
                  >
                    Invalid 3-letter code
                  </span>
                )}
                {isDuplicate && codeValid && (
                  <span
                    className="field-hint"
                    style={{ color: "#f5b301" }}
                  >
                    Duplicate / same as main
                  </span>
                )}
              </div>

              {codeValid && !isDuplicate && (
                <>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      marginBottom: 6,
                      fontSize: 13,
                    }}
                  >
                    <span style={{ minWidth: 110 }}>
                      1 {mainUpper || "MAIN"} =
                    </span>
                    <NumberInput
                      value={row.rate}
                      min={0}
                      step={0.01}
                      onChange={(v) => updateRowRate(idx, v)}
                    />
                    <span>{code}</span>
                  </div>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      marginBottom: 6,
                      fontSize: 13,
                    }}
                  >
                    <span style={{ minWidth: 110 }}>
                      1 {code} =
                    </span>
                    <NumberInput
                      value={inverse}
                      min={0}
                      step={0.0001}
                      onChange={(v) => updateRowInverseRate(idx, v)}
                    />
                    <span>{mainUpper || "MAIN"}</span>
                  </div>
                  <button
                    type="button"
                    className="btn"
                    style={{ marginTop: 4 }}
                    onClick={() =>
                      setExpanded((prev) => ({
                        ...prev,
                        [idx]: !(prev[idx] ?? false),
                      }))
                    }
                  >
                    {open ? "Hide group prices" : "Show group prices"}
                  </button>
                  {open && (
                    <GroupPricesSpoiler
                      priceGroups={priceGroups}
                      mainCurrency={mainUpper}
                      targetCurrency={code}
                      rate={row.rate}
                    />
                  )}
                </>
              )}
            </div>
          );
        })}
      </div>

      <div style={{ marginTop: 12 }}>
        <button className="btn" onClick={addRow}>
          <Plus size={14} aria-hidden="true" />
          Add new currency
        </button>
      </div>

      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          gap: 8,
          marginTop: 18,
        }}
      >
        <button className="btn" onClick={onClose}>
          Cancel
        </button>
        <button
          className="btn btn--primary"
          disabled={!canSave}
          onClick={handleSave}
        >
          <LogIn size={14} aria-hidden="true" />
          Save
        </button>
      </div>
    </Modal>
  );
}

interface GroupPricesSpoilerProps {
  priceGroups: DonatePriceGroup[];
  mainCurrency: string;
  targetCurrency: string;
  rate: number;
}

function GroupPricesSpoiler({
  priceGroups,
  mainCurrency,
  targetCurrency,
  rate,
}: GroupPricesSpoilerProps) {
  const rows = useMemo(() => {
    const byPrice = new Map<number, string[]>();
    for (const pg of priceGroups) {
      const converted = smartRoundAmount(pg.price * rate, targetCurrency);
      const list = byPrice.get(converted) ?? [];
      list.push(formatGroupName(pg.group));
      byPrice.set(converted, list);
    }
    return Array.from(byPrice.entries())
      .map(([price, groups]) => ({ price, groups }))
      .sort((a, b) => a.price - b.price);
  }, [priceGroups, rate, targetCurrency]);

  if (rows.length === 0) {
    return (
      <div
        style={{
          marginTop: 8,
          fontSize: 13,
          opacity: 0.7,
        }}
      >
        No price groups configured.
      </div>
    );
  }

  const exampleN = rows.length > 0 ? rows[0]?.price ?? 0 : 0;

  return (
    <div
      style={{
        marginTop: 8,
        display: "flex",
        flexDirection: "column",
        gap: 4,
        fontFamily: "Roboto Mono, monospace",
        fontSize: 13,
      }}
    >
      <div style={{ opacity: 0.65, marginBottom: 4 }}>
        Group prices in {targetCurrency} (converted from {mainCurrency}):
      </div>
      {rows.map((row) => (
        <div key={row.price}>
          {row.groups.join(", ")} — {row.price} {targetCurrency}
        </div>
      ))}
      {exampleN > 0 && (
        <div
          style={{
            marginTop: 8,
            padding: "8px 10px",
            border: "1px solid rgba(245, 179, 1, 0.4)",
            borderRadius: 6,
            background: "rgba(245, 179, 1, 0.08)",
            color: "#f5b301",
            lineHeight: 1.5,
            display: "flex",
            alignItems: "flex-start",
            gap: 8,
          }}
        >
          <Info
            size={16}
            aria-hidden="true"
            style={{ marginTop: 2, flexShrink: 0 }}
          />
          <div>
            Note: These are minimum prices. If an effect costs {exampleN}{" "}
            {targetCurrency}, any donation of {exampleN} {targetCurrency} or
            more can activate it.
          </div>
        </div>
      )}
    </div>
  );
}

function formatGroupName(name: string): string {
  return name
    .split("_")
    .filter((p) => p.length > 0)
    .map((p) => p.charAt(0).toUpperCase() + p.slice(1).toLowerCase())
    .join(" ");
}
