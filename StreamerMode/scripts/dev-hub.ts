import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import indexHtml from "../frontend/hub/index.html" with { type: "html" };

const __dirname = dirname(fileURLToPath(import.meta.url));
const hubModDir = resolve(__dirname, "../frontend/hub/mod");

const host = "0.0.0.0";
const port = Number(process.env.PORT ?? 9139);

async function serveModAsset(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const relative = url.pathname.replace(/^\/mod\//, "");
  const filePath = resolve(hubModDir, relative);
  if (!filePath.startsWith(hubModDir)) {
    return new Response("Forbidden", { status: 403 });
  }
  const file = Bun.file(filePath);
  if (!(await file.exists())) {
    return new Response("Not found", { status: 404 });
  }
  const contentType = filePath.endsWith(".json")
    ? "application/json; charset=utf-8"
    : "application/octet-stream";
  return new Response(file, {
    headers: { "Content-Type": contentType, "Cache-Control": "no-store" },
  });
}

const server = Bun.serve({
  hostname: host,
  port,
  development: true,
  routes: {
    "/mod/*": serveModAsset,
    "/*": indexHtml,
  },
});

console.log(`Hub dev server: http://localhost:${server.port}`);
