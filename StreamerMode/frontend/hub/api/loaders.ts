import { useQuery, type UseQueryResult } from "@tanstack/react-query";
import type { ConfigFile, EffectsFile, LangFile } from "./types.ts";
import type { LanguageCode } from "../i18n/languages.ts";

async function fetchJson<T>(path: string): Promise<T> {
  const response = await fetch(path);
  if (!response.ok) {
    throw new Error(`Failed to load ${path}: ${response.status}`);
  }
  return (await response.json()) as T;
}

export function useEffectsFile(): UseQueryResult<EffectsFile> {
  return useQuery({
    queryKey: ["mod", "effects"],
    queryFn: () => fetchJson<EffectsFile>("/mod/default_effects.json"),
  });
}

export function useConfigFile(): UseQueryResult<ConfigFile> {
  return useQuery({
    queryKey: ["mod", "config"],
    queryFn: () => fetchJson<ConfigFile>("/mod/default_config.json"),
  });
}

export function useLangFile(
  language: LanguageCode,
): UseQueryResult<LangFile> {
  return useQuery({
    queryKey: ["mod", "lang", language],
    queryFn: () => fetchJson<LangFile>(`/mod/lang/${language}.json`),
  });
}

// English fallback is always loaded so that missing translations resolve to
// the canonical names/descriptions.
export function useEnglishLangFile(): UseQueryResult<LangFile> {
  return useQuery({
    queryKey: ["mod", "lang", "en"],
    queryFn: () => fetchJson<LangFile>("/mod/lang/en.json"),
  });
}
