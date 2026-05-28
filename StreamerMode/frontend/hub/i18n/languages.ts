export const SUPPORTED_LANGUAGES = [
  "en",
  "ru",
  "de",
  "es",
  "fr",
  "pl",
  "pt",
  "tr",
  "zh",
  "ja",
  "ko",
] as const;

export type LanguageCode = (typeof SUPPORTED_LANGUAGES)[number];

export const LANGUAGE_LABELS: Record<LanguageCode, string> = {
  en: "English",
  ru: "Русский",
  de: "Deutsch",
  es: "Español",
  fr: "Français",
  pl: "Polski",
  pt: "Português",
  tr: "Türkçe",
  zh: "中文",
  ja: "日本語",
  ko: "한국어",
};

const LANG_STORAGE_KEY = "chaosmod-hub-language";

// Browser locales like "en-US" / "pt-BR" / "zh-CN" / "zh-TW" are mapped to the
// supported short codes. zh-TW maps to zh (the file is Simplified Chinese, not
// ideal for Traditional readers — documented limitation). pt-PT maps to pt
// (the file contains Brazilian Portuguese).
function isSupported(code: string): code is LanguageCode {
  return (SUPPORTED_LANGUAGES as readonly string[]).includes(code);
}

export function isLanguageSupported(code: string | null | undefined): code is LanguageCode {
  return typeof code === "string" && isSupported(code);
}

export function resolveLanguageFromBrowser(): LanguageCode {
  if (typeof navigator === "undefined") return "en";
  const candidates = navigator.languages?.length
    ? [...navigator.languages]
    : navigator.language
      ? [navigator.language]
      : [];
  for (const raw of candidates) {
    const lower = raw.toLowerCase();
    const short = lower.split("-")[0] ?? "";
    if (isSupported(short)) return short;
  }
  return "en";
}

export function loadStoredLanguage(): LanguageCode {
  if (typeof localStorage === "undefined") return resolveLanguageFromBrowser();
  try {
    const stored = localStorage.getItem(LANG_STORAGE_KEY);
    if (stored && isSupported(stored)) return stored;
  } catch {
    // Ignore storage errors (private mode, disabled storage, etc.).
  }
  return resolveLanguageFromBrowser();
}

export function persistLanguage(code: LanguageCode): void {
  try {
    localStorage.setItem(LANG_STORAGE_KEY, code);
  } catch {
    // Ignore storage errors.
  }
}
