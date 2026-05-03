import { logger } from "./utils/logger.ts";
import type { AnyProvider, StreamerUser } from "./streamer/index.ts";
import obsHtmlFile from "../frontend/obs/index.html";

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
