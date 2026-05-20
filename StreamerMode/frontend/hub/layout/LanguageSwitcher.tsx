import { useEffect, useRef, useState } from "react";
import { Languages, ChevronDown } from "lucide-react";
import { useLanguage } from "../i18n/LanguageProvider.tsx";
import {
  LANGUAGE_LABELS,
  SUPPORTED_LANGUAGES,
  type LanguageCode,
} from "../i18n/languages.ts";

function syncEffectsLangParam(code: LanguageCode): void {
  if (typeof window === "undefined") return;
  if (window.location.pathname !== "/effects") return;
  const params = new URLSearchParams(window.location.search);
  params.set("lang", code);
  const url =
    window.location.pathname + `?${params.toString()}` + window.location.hash;
  window.history.replaceState(null, "", url);
}

export function LanguageSwitcher() {
  const { language, setLanguage } = useLanguage();
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

  return (
    <div className="lang-switcher" ref={ref}>
      <button
        type="button"
        className="lang-button"
        aria-haspopup="listbox"
        aria-expanded={open}
        onClick={() => setOpen((v) => !v)}
      >
        <Languages size={16} />
        <span className="lang-button-label">{LANGUAGE_LABELS[language]}</span>
        <ChevronDown size={14} />
      </button>
      {open ? (
        <ul className="lang-menu" role="listbox">
          {SUPPORTED_LANGUAGES.map((code) => (
            <li key={code}>
              <button
                type="button"
                role="option"
                aria-selected={code === language}
                className={`lang-menu-item${code === language ? " is-active" : ""}`}
                onClick={() => {
                  setLanguage(code as LanguageCode);
                  syncEffectsLangParam(code as LanguageCode);
                  setOpen(false);
                }}
              >
                {LANGUAGE_LABELS[code]}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
