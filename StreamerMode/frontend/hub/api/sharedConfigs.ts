export interface SharedConfigData {
  effects?: Record<string, Record<string, unknown>>;
  prices?: Record<string, number>;
  rewards?: Record<string, { groups: string[] }>;
  currencies?: { main: string; list: Record<string, number> };
  bits_override?: number;
  donation_enabled?: boolean;
}

export interface SharedConfig {
  id: string;
  created_at: string;
  name: string;
  mod_version: string;
  rewards: boolean;
  bits: boolean;
  donationalerts: boolean;
  last_effect: number;
  data: SharedConfigData;
}

export interface CreateSharedConfigBody {
  name: string;
  edit_token: string;
  mod_version: string;
  rewards: boolean;
  bits: boolean;
  donationalerts: boolean;
  last_effect: number;
  data: SharedConfigData;
}

export interface UpdateSharedConfigBody {
  edit_token: string;
  new_name?: string;
  mod_version?: string;
  rewards?: boolean;
  bits?: boolean;
  donationalerts?: boolean;
  last_effect?: number;
  data?: SharedConfigData;
}

export class SharedConfigError extends Error {
  status: number;
  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

async function readError(res: Response, fallback: string): Promise<string> {
  try {
    const body = (await res.json()) as { error?: unknown };
    if (typeof body.error === "string") return body.error;
  } catch {
    // ignore
  }
  return fallback;
}

export async function createSharedConfig(
  body: CreateSharedConfigBody,
): Promise<SharedConfig> {
  const res = await fetch("/api/shared-configs", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    throw new SharedConfigError(
      await readError(res, `Failed to create config (${res.status})`),
      res.status,
    );
  }
  const json = (await res.json()) as { config: SharedConfig };
  return json.config;
}

export async function getSharedConfig(
  name: string,
  options?: { cacheBust?: boolean },
): Promise<SharedConfig> {
  const bust = options?.cacheBust ? `?t=${Date.now()}` : "";
  const res = await fetch(
    `/api/shared-configs/${encodeURIComponent(name)}${bust}`,
  );
  if (!res.ok) {
    throw new SharedConfigError(
      await readError(res, `Failed to load config (${res.status})`),
      res.status,
    );
  }
  const json = (await res.json()) as { config: SharedConfig };
  return json.config;
}

export async function updateSharedConfig(
  name: string,
  body: UpdateSharedConfigBody,
): Promise<SharedConfig> {
  const res = await fetch(
    `/api/shared-configs/${encodeURIComponent(name)}`,
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    },
  );
  if (!res.ok) {
    throw new SharedConfigError(
      await readError(res, `Failed to update config (${res.status})`),
      res.status,
    );
  }
  const json = (await res.json()) as { config: SharedConfig };
  return json.config;
}
