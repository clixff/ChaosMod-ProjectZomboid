const EDIT_TOKEN_KEY = "chaos_edit_token";
const OWNED_CONFIGS_KEY = "chaos_owned_configs";

export interface OwnedConfig {
  name: string;
  created_at: string;
}

function safeLocalStorage(): Storage | null {
  try {
    if (typeof localStorage === "undefined") return null;
    return localStorage;
  } catch {
    return null;
  }
}

export function getOrCreateEditToken(): string {
  const store = safeLocalStorage();
  if (!store) {
    // Fall back to a per-session token if storage is unavailable. The user
    // will not be able to edit configs across sessions, but creation still
    // works for this visit.
    return crypto.randomUUID();
  }
  const existing = store.getItem(EDIT_TOKEN_KEY);
  if (existing && existing.length >= 12) return existing;
  const fresh = crypto.randomUUID();
  try {
    store.setItem(EDIT_TOKEN_KEY, fresh);
  } catch {
    // ignore
  }
  return fresh;
}

export function getOwnedConfigs(): OwnedConfig[] {
  const store = safeLocalStorage();
  if (!store) return [];
  const raw = store.getItem(OWNED_CONFIGS_KEY);
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    const out: OwnedConfig[] = [];
    for (const entry of parsed) {
      if (
        entry !== null &&
        typeof entry === "object" &&
        typeof (entry as { name?: unknown }).name === "string" &&
        typeof (entry as { created_at?: unknown }).created_at === "string"
      ) {
        out.push({
          name: (entry as { name: string }).name,
          created_at: (entry as { created_at: string }).created_at,
        });
      }
    }
    return out;
  } catch {
    return [];
  }
}

export function isOwnedConfig(name: string): boolean {
  return getOwnedConfigs().some((c) => c.name === name);
}

export function addOwnedConfig(name: string, createdAt: string): void {
  const store = safeLocalStorage();
  if (!store) return;
  const list = getOwnedConfigs().filter((c) => c.name !== name);
  list.unshift({ name, created_at: createdAt });
  try {
    store.setItem(OWNED_CONFIGS_KEY, JSON.stringify(list));
  } catch {
    // ignore
  }
}

export function renameOwnedConfig(oldName: string, newName: string): void {
  const store = safeLocalStorage();
  if (!store) return;
  const list = getOwnedConfigs();
  const idx = list.findIndex((c) => c.name === oldName);
  if (idx === -1) return;
  const entry = list[idx]!;
  list[idx] = { name: newName, created_at: entry.created_at };
  try {
    store.setItem(OWNED_CONFIGS_KEY, JSON.stringify(list));
  } catch {
    // ignore
  }
}
