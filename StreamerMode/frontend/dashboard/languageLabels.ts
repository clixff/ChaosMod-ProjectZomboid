const LANGUAGE_LABELS: Record<string, string> = {
  de: "German",
  en: "English",
  es: "Spanish",
  fr: "French",
  pl: "Polish",
  pt: "Portuguese",
  ru: "Russian",
  tr: "Turkish",
  zh: "Chinese",
  ko: "Korean",
  ja: "Japanese",
};

export function formatLanguageLabel(code: string): string {
  return LANGUAGE_LABELS[code] ?? code;
}
