import { rm } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const streamerModeRoot = resolve(__dirname, "..");
const distHubDir = resolve(streamerModeRoot, "dist-hub");

await rm(distHubDir, { recursive: true, force: true });

console.log("Cleaned", distHubDir);
