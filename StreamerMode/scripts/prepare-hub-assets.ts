import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

const streamerModeRoot = resolve(__dirname, "..");
const repoRoot = resolve(streamerModeRoot, "..");

// Assets are copied into the hub source tree so that the Bun dev server
// (`bun frontend/hub/index.html`) can serve them from the same directory.
// The build step (`build:hub`) copies them again into `dist-hub/mod/`.
const hubRoot = resolve(streamerModeRoot, "frontend/hub");
const targetModDir = resolve(hubRoot, "mod");

const modCommonDir = resolve(repoRoot, "Contents/mods/ChaosMod/common");

await rm(targetModDir, { recursive: true, force: true });
await mkdir(targetModDir, { recursive: true });

await cp(
  resolve(modCommonDir, "default_config.json"),
  resolve(targetModDir, "default_config.json"),
);

await cp(
  resolve(modCommonDir, "default_effects.json"),
  resolve(targetModDir, "default_effects.json"),
);

await cp(resolve(modCommonDir, "lang"), resolve(targetModDir, "lang"), {
  recursive: true,
  force: true,
});

console.log("Prepared Hub mod assets at", targetModDir);
