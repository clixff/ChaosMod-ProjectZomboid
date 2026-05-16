import { logger } from "./utils/logger.ts";
import type { AnyProvider, StreamerUser } from "./streamer/index.ts";
import type { ModConfig } from "./config.ts";
import type { EffectEntry } from "./effects.ts";
import type { ActivityEvent } from "./activityLog.ts";
import obsHtmlFile from "../frontend/obs/index.html";
import dashboardHtmlFile from "../frontend/dashboard/index.html";

const AUTH_CALLBACK_HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>ChaosMod — Login</title>
  <style>
    body { font-family: sans-serif; background: #0e0e10; color: #efeff1; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
  </style>
</head>
<body>
  <p id="msg">Completing login…</p>
  <script>
    const params = new URLSearchParams(location.hash.slice(1));
    const token = params.get('access_token');
    const msg = document.getElementById('msg');
    if (token) {
      history.replaceState(null, '', location.pathname);
      fetch(location.origin + '/auth/token?provider=twitch&token=' + encodeURIComponent(token), { method: 'POST' })
        .then(r => r.ok ? r.text() : Promise.reject())
        .then(t => { msg.textContent = t; })
        .catch(() => { msg.textContent = 'Login failed. Please try again.'; });
    } else {
      msg.textContent = 'No access token found. Please try again.';
    }
  </script>
</body>
</html>`;

export interface VoteOptionStatus {
  effect_id: string;
  index: number;
  effect_name: string;
  votes: number | undefined;
  hidden?: boolean;
}

export interface ModStatus {
  enabled: boolean;
  voting_enabled: boolean;
  iteration_index: number;
  total_votes: number;
  total_votes_label: string;
  vote_background_color: string;
  last_winner: string | null;
  vote_options: VoteOptionStatus[];
  donateEnabled: boolean;
}

export interface ServerContext {
  host: string;
  port: number;
  provider: AnyProvider | null;
  onLogin: (user: StreamerUser, token: string) => void | Promise<void>;
  getModStatus: () => ModStatus;
  getEffectsResponse: () => unknown;
  activateEffect: (nickname: string | undefined, effectId: string) => { success: boolean; error?: string };
  onDonationAlertsCode?: (code: string) => Promise<{ name: string } | null>;
  getConfig?: () => ModConfig | null;
  updateConfig?: (patch: unknown) => { success: boolean; error?: string };
  getEffectsList?: () => Array<EffectEntry & { name: string }>;
  updateEffect?: (id: string, patch: unknown) => { success: boolean; error?: string };
  getPriceGroups?: () => Array<{ group: string; price: number }>;
  getLanguages?: () => string[];
  getHomeStatus?: () => HomeStatus;
  twitchLogin?: () => Promise<{ success: boolean; error?: string; url?: string }>;
  twitchLogout?: () => Promise<{ success: boolean; error?: string }>;
  donationAlertsLogin?: () => Promise<{ success: boolean; error?: string; url?: string }>;
  donationAlertsLogout?: () => Promise<{ success: boolean; error?: string }>;
  donationAlertsSetup?: (input: {
    appId: string;
    clientSecret: string;
    currency: string;
  }) => Promise<{ success: boolean; error?: string; url?: string }>;
  exportEffects?: (
    kind: string,
  ) =>
    | { success: boolean; error?: string; path?: string }
    | Promise<{ success: boolean; error?: string; path?: string }>;
  downloadEffects?: (kind: string) => Promise<
    | { success: false; error: string }
    | {
        success: true;
        bytes: ArrayBuffer;
        filename: string;
        contentType: string;
      }
  >;
}

export interface HomeStatus {
  port: number;
  twitch: {
    configured: boolean;
    connected: boolean;
    name: string | null;
  };
  donationalerts: {
    configured: boolean;
    connected: boolean;
    name: string | null;
  };
  obs: {
    use_localhost_ip: boolean;
    local_url: string;
    lan_url: string | null;
  };
  mod: {
    enabled: boolean;
  };
  voting: {
    active: boolean;
  };
  twitch_chat: {
    connected: boolean;
  };
  recent_activity: ActivityEvent[];
  version: {
    current: string;
    latest: string | null;
    update_available: boolean;
    releases_url: string;
  };
}

export function startServer(ctx: ServerContext): ReturnType<typeof Bun.serve> {
  const { host, port, provider } = ctx;

  const server = Bun.serve({
    hostname: host,
    port,
    routes: {
      "/login/twitch": () => {
        if (!provider)
          return new Response("No provider configured", { status: 503 });
        return Response.redirect(provider.getLoginUrl(port), 302);
      },

      "/auth/result/twitch": new Response(AUTH_CALLBACK_HTML, {
        headers: { "Content-Type": "text/html; charset=utf-8" },
      }),

      "/auth/token": {
        POST: async (req: Request) => {
          const url = new URL(req.url);
          const providerParam = url.searchParams.get("provider");
          const token = url.searchParams.get("token");

          if (!token || !providerParam) {
            return new Response("Missing parameters", { status: 400 });
          }
          if (!provider || providerParam !== provider.key) {
            return new Response("Unknown provider", { status: 400 });
          }

          const user = await provider.validateToken(token);
          if (!user) {
            return new Response("Invalid or expired token", { status: 401 });
          }

          await provider.saveToken(token);
          await ctx.onLogin(user, token);
          return new Response(
            `Logged in as ${user.display_name}. You can close this tab.`,
          );
        },
      },

      "/obs": obsHtmlFile,
      "/obs/": obsHtmlFile,
      "/dashboard": dashboardHtmlFile,
      "/dashboard/": dashboardHtmlFile,

      "/api/config": {
        GET: () => {
          const cfg = ctx.getConfig?.();
          if (!cfg) return new Response("Config not available", { status: 503 });
          return Response.json(cfg);
        },
        PUT: async (req: Request) => {
          if (!ctx.updateConfig) {
            return new Response("Not available", { status: 503 });
          }
          let body: unknown;
          try {
            body = await req.json();
          } catch {
            return new Response("Invalid JSON", { status: 400 });
          }
          const result = ctx.updateConfig(body);
          if (!result.success) {
            return new Response(result.error ?? "Update failed", { status: 400 });
          }
          return new Response("OK");
        },
      },

      "/api/home/status": {
        GET: () => {
          if (!ctx.getHomeStatus) {
            return new Response("Not available", { status: 503 });
          }
          return Response.json(ctx.getHomeStatus());
        },
      },

      "/api/twitch/login": {
        POST: async () => {
          if (!ctx.twitchLogin) return new Response("Not available", { status: 503 });
          const r = await ctx.twitchLogin();
          if (!r.success) {
            return new Response(r.error ?? "Login failed", { status: 400 });
          }
          return Response.json({ url: r.url ?? null });
        },
      },

      "/api/twitch/logout": {
        POST: async () => {
          if (!ctx.twitchLogout) return new Response("Not available", { status: 503 });
          const r = await ctx.twitchLogout();
          if (!r.success) {
            return new Response(r.error ?? "Logout failed", { status: 400 });
          }
          return new Response("OK");
        },
      },

      "/api/donationalerts/login": {
        POST: async () => {
          if (!ctx.donationAlertsLogin) {
            return new Response("Not available", { status: 503 });
          }
          const r = await ctx.donationAlertsLogin();
          if (!r.success) {
            return new Response(r.error ?? "Login failed", { status: 400 });
          }
          return Response.json({ url: r.url ?? null });
        },
      },

      "/api/donationalerts/setup": {
        POST: async (req: Request) => {
          if (!ctx.donationAlertsSetup) {
            return new Response("Not available", { status: 503 });
          }
          let body: unknown;
          try {
            body = await req.json();
          } catch {
            return new Response("Invalid JSON", { status: 400 });
          }
          if (body === null || typeof body !== "object" || Array.isArray(body)) {
            return new Response("Body must be an object", { status: 400 });
          }
          const b = body as Record<string, unknown>;
          const appId = typeof b["appId"] === "string" ? b["appId"].trim() : "";
          const clientSecret =
            typeof b["clientSecret"] === "string" ? b["clientSecret"] : "";
          const currencyRaw =
            typeof b["currency"] === "string" ? b["currency"].trim() : "";
          if (!appId || !clientSecret || !currencyRaw) {
            return new Response(
              "Missing fields: appId, clientSecret, currency",
              { status: 400 },
            );
          }
          const currency = currencyRaw.toUpperCase();
          if (!/^[A-Z]{3}$/.test(currency)) {
            return new Response(
              "Currency must be exactly 3 letters (e.g. RUB)",
              { status: 400 },
            );
          }
          const r = await ctx.donationAlertsSetup({
            appId,
            clientSecret,
            currency,
          });
          if (!r.success) {
            return new Response(r.error ?? "Setup failed", { status: 400 });
          }
          return Response.json({ url: r.url ?? null });
        },
      },

      "/api/donationalerts/logout": {
        POST: async () => {
          if (!ctx.donationAlertsLogout) {
            return new Response("Not available", { status: 503 });
          }
          const r = await ctx.donationAlertsLogout();
          if (!r.success) {
            return new Response(r.error ?? "Logout failed", { status: 400 });
          }
          return new Response("OK");
        },
      },

      "/api/export": {
        POST: async (req: Request) => {
          if (!ctx.exportEffects) return new Response("Not available", { status: 503 });
          const url = new URL(req.url);
          const kind = url.searchParams.get("type") ?? "csv";
          const r = await ctx.exportEffects(kind);
          if (!r.success) {
            return new Response(r.error ?? "Export failed", { status: 400 });
          }
          return Response.json({ path: r.path ?? null });
        },
      },

      "/api/export/download": {
        GET: async (req: Request) => {
          if (!ctx.downloadEffects) {
            return new Response("Not available", { status: 503 });
          }
          const url = new URL(req.url);
          const kind = url.searchParams.get("type") ?? "csv";
          const r = await ctx.downloadEffects(kind);
          if (!r.success) {
            return new Response(r.error, { status: 400 });
          }
          return new Response(r.bytes, {
            headers: {
              "Content-Type": r.contentType,
              "Content-Disposition": `attachment; filename="${r.filename}"`,
              "Content-Length": String(r.bytes.byteLength),
              "Cache-Control": "no-store",
            },
          });
        },
      },

      "/api/languages": {
        GET: () => {
          const langs = ctx.getLanguages?.() ?? [];
          return Response.json({ languages: langs });
        },
      },

      "/api/effects": {
        GET: () => {
          if (!ctx.getEffectsList) {
            return new Response("Not available", { status: 503 });
          }
          return Response.json({
            effects: ctx.getEffectsList(),
            price_groups: ctx.getPriceGroups?.() ?? [],
          });
        },
      },

      "/api/effects/:id": {
        PUT: async (req: Request) => {
          if (!ctx.updateEffect) {
            return new Response("Not available", { status: 503 });
          }
          const url = new URL(req.url);
          const id = decodeURIComponent(url.pathname.split("/").pop() ?? "");
          if (!id) return new Response("Missing effect id", { status: 400 });
          let body: unknown;
          try {
            body = await req.json();
          } catch {
            return new Response("Invalid JSON", { status: 400 });
          }
          const result = ctx.updateEffect(id, body);
          if (!result.success) {
            return new Response(result.error ?? "Update failed", { status: 400 });
          }
          return new Response("OK");
        },
      },

      "/mod/status": () => Response.json(ctx.getModStatus()),
      "/mod/effects": () => Response.json(ctx.getEffectsResponse()),
      "/provider/donationalerts/success/": async (req: Request) => {
        if (!ctx.onDonationAlertsCode) {
          return new Response("Donation provider not configured", { status: 503 });
        }
        const url = new URL(req.url);
        const code = url.searchParams.get("code");
        if (!code) {
          return new Response("Missing code parameter", { status: 400 });
        }
        const user = await ctx.onDonationAlertsCode(code);
        if (!user) {
          return new Response("Login failed. Please try again.", {
            status: 401,
            headers: { "Content-Type": "text/html; charset=utf-8" },
          });
        }
        return new Response(`Logged in as ${user.name}. You can close this tab.`);
      },

      "/mod/activate-effect": {
        GET: (req: Request) => {
          const url = new URL(req.url);
          const effectId = url.searchParams.get("effect");
          if (!effectId) {
            return new Response("Missing 'effect' query parameter", { status: 400 });
          }
          const nickname = url.searchParams.get("nickname") ?? undefined;
          const result = ctx.activateEffect(nickname, effectId);
          if (!result.success) {
            return new Response(result.error ?? "Not available", { status: 403 });
          }
          return new Response("OK");
        },
      },
    },
    fetch() {
      return new Response("Not Found", { status: 404 });
    },
  });

  logger.debug(`HTTP server listening on http://${host}:${port}`);
  return server;
}
