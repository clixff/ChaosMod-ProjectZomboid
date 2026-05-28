import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import {
  loadStoredLanguage,
  persistLanguage,
  type LanguageCode,
} from "./languages.ts";

interface SetLanguageOptions {
  persist?: boolean;
}

interface LanguageContextValue {
  language: LanguageCode;
  setLanguage: (code: LanguageCode, opts?: SetLanguageOptions) => void;
}

const LanguageContext = createContext<LanguageContextValue | null>(null);

export function LanguageProvider({ children }: { children: ReactNode }) {
  const [language, setLanguageState] = useState<LanguageCode>(() =>
    loadStoredLanguage(),
  );

  useEffect(() => {
    document.documentElement.setAttribute("lang", language);
  }, [language]);

  const setLanguage = useCallback(
    (code: LanguageCode, opts?: SetLanguageOptions) => {
      setLanguageState(code);
      if (opts?.persist !== false) persistLanguage(code);
    },
    [],
  );

  const value = useMemo(
    () => ({ language, setLanguage }),
    [language, setLanguage],
  );

  return (
    <LanguageContext.Provider value={value}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage(): LanguageContextValue {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used inside LanguageProvider");
  return ctx;
}
