import { logger } from "./utils/logger.ts";

const VERSION_URL =
  "https://raw.githubusercontent.com/clixff/ChaosMod-ProjectZomboid/refs/heads/master/VERSION";
export const RELEASES_URL =
  "https://github.com/clixff/ChaosMod-ProjectZomboid/releases/latest";

export interface VersionStatus {
  current: string;
  latest: string | null;
  update_available: boolean;
  releases_url: string;
}

function parseSemver(input: string): [number, number, number] | null {
  const m = /^(\d+)\.(\d+)\.(\d+)/.exec(input.trim());
  if (!m) return null;
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

function compareVersions(a: string, b: string): number {
  const pa = parseSemver(a);
  const pb = parseSemver(b);
  if (!pa || !pb) return 0;
  for (let i = 0; i < 3; i++) {
    if (pa[i]! < pb[i]!) return -1;
    if (pa[i]! > pb[i]!) return 1;
  }
  return 0;
}

export async function fetchLatestVersion(): Promise<string | null> {
  try {
    const res = await fetch(VERSION_URL, { redirect: "follow" });
    if (!res.ok) {
      logger.debug(`[VersionCheck] HTTP ${res.status} fetching VERSION`);
      return null;
    }
    const text = (await res.text()).trim();
    if (!parseSemver(text)) {
      logger.debug(`[VersionCheck] Unparseable VERSION payload: ${text}`);
      return null;
    }
    return text;
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.debug(`[VersionCheck] fetch failed: ${msg}`);
    return null;
  }
}

export function buildStatus(
  current: string,
  latest: string | null,
): VersionStatus {
  const updateAvailable =
    latest !== null && compareVersions(current, latest) < 0;
  return {
    current,
    latest,
    update_available: updateAvailable,
    releases_url: RELEASES_URL,
  };
}
