import colors from "colors";

export interface StreamerUser {
  id: string;
  login: string;
  display_name: string;
}

const CLIENT_ID = "q72hcurbc7rcns1cefr9nqhmixe7b8";

export class TwitchProvider {
  readonly name = "Twitch";
  readonly key = "twitch";
  readonly coloredName = colors.magenta("[Twitch]");

  getLoginUrl(port: number): string {
    const params = new URLSearchParams({
      client_id: CLIENT_ID,
      redirect_uri: `http://localhost:${port}/auth/result/twitch`,
      response_type: "token",
      scope: "user:read:chat",
      force_verify: "true",
    });
    return `https://id.twitch.tv/oauth2/authorize?${params}`;
  }

  async validateToken(accessToken: string): Promise<StreamerUser | null> {
    let res: Response;
    try {
      res = await fetch("https://api.twitch.tv/helix/users", {
        headers: {
          "Client-Id": CLIENT_ID,
          Authorization: `Bearer ${accessToken}`,
        },
      });
    } catch {
      return null;
    }
    if (!res.ok) return null;
    const json = (await res.json()) as { data?: unknown[] };
    const raw = json.data?.[0];
    if (!raw || typeof raw !== "object") return null;
    const u = raw as Record<string, unknown>;
    if (
      typeof u["id"] !== "string" ||
      typeof u["login"] !== "string" ||
      typeof u["display_name"] !== "string"
    ) return null;
    return { id: u["id"], login: u["login"], display_name: u["display_name"] };
  }

  async loadToken(): Promise<string | null> {
    const val = await Bun.secrets.get({ service: "chaos-mod-streamer-mode", name: "twitch-oauth-token" });
    return val || null;
  }

  async saveToken(token: string): Promise<void> {
    await Bun.secrets.set({ service: "chaos-mod-streamer-mode", name: "twitch-oauth-token", value: token });
  }

  async deleteToken(): Promise<boolean> {
    return Bun.secrets.delete({ service: "chaos-mod-streamer-mode", name: "twitch-oauth-token" });
  }
}
