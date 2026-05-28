import { cp, mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const streamerModeRoot = resolve(__dirname, "..");

const sourceModDir = resolve(streamerModeRoot, "frontend/hub/mod");
const distModDir = resolve(streamerModeRoot, "dist-hub/mod");

await mkdir(distModDir, { recursive: true });
await cp(sourceModDir, distModDir, { recursive: true, force: true });

await cp(
  resolve(streamerModeRoot, "frontend/hub/robots.txt"),
  resolve(streamerModeRoot, "dist-hub/robots.txt"),
);

console.log("Copied hub mod assets to", distModDir);
