export class HttpError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly body: string,
  ) {
    super(message);
  }
}

export async function readJson<T>(response: Response): Promise<T> {
  const text = await response.text();

  if (!response.ok) {
    throw new HttpError(
      `HTTP ${response.status}: ${response.statusText}`,
      response.status,
      text,
    );
  }

  if (!text) {
    return undefined as T;
  }

  return JSON.parse(text) as T;
}

export async function postForm<T>(
  url: string,
  data: Record<string, string | number>,
): Promise<T> {
  const body = new URLSearchParams();

  for (const [key, value] of Object.entries(data)) {
    body.set(key, String(value));
  }

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body,
  });

  return readJson<T>(response);
}

export async function getBearer<T>(
  url: string,
  accessToken: string,
): Promise<T> {
  const response = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${accessToken}`,
    },
  });

  return readJson<T>(response);
}

export async function postBearerJson<T>(
  url: string,
  accessToken: string,
  body: unknown,
): Promise<T> {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  return readJson<T>(response);
}
