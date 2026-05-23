import { useEffect, useRef, useState } from "react";
import { Coins, ChevronDown } from "lucide-react";
import { useCurrency } from "../currency/CurrencyProvider.tsx";

export function CurrencySwitcher() {
  const { selectedCurrency, setSelectedCurrency, availableCurrencies } =
    useCurrency();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    function onClick(e: MouseEvent) {
      if (!ref.current) return;
      if (!ref.current.contains(e.target as Node)) setOpen(false);
    }
    if (open) document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, [open]);

  if (availableCurrencies.length <= 1) return null;

  return (
    <div className="lang-switcher" ref={ref}>
      <button
        type="button"
        className="lang-button"
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <Coins size={16} />
        <span className="lang-button-label">{selectedCurrency}</span>
        <ChevronDown size={14} />
      </button>
      {open ? (
        <ul className="lang-menu" role="listbox">
          {availableCurrencies.map((code) => (
            <li key={code}>
              <button
                type="button"
                role="option"
                aria-selected={code === selectedCurrency}
                className={`lang-menu-item${code === selectedCurrency ? " is-active" : ""}`}
                onClick={() => {
                  setSelectedCurrency(code);
                  setOpen(false);
                }}
              >
                {code}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
