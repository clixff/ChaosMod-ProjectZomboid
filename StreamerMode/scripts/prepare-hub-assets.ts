import { mkdir, readFile, readdir, rm, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
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

async function copyMinifiedJson(src: string, dst: string): Promise<number> {
  const raw = await readFile(src, "utf-8");
  const parsed: unknown = JSON.parse(raw);
  const minified = JSON.stringify(parsed);
  await writeFile(dst, minified, "utf-8");
  // Byte savings = original size − minified size. Useful for logs.
  return Buffer.byteLength(raw, "utf-8") - Buffer.byteLength(minified, "utf-8");
}

let totalSaved = 0;

totalSaved += await copyMinifiedJson(
  resolve(modCommonDir, "default_config.json"),
  resolve(targetModDir, "default_config.json"),
);

totalSaved += await copyMinifiedJson(
  resolve(modCommonDir, "default_effects.json"),
  resolve(targetModDir, "default_effects.json"),
);

const langSrcDir = resolve(modCommonDir, "lang");
const langDstDir = resolve(targetModDir, "lang");
await mkdir(langDstDir, { recursive: true });
const langFiles = await readdir(langSrcDir);
for (const file of langFiles) {
  if (!file.endsWith(".json")) continue;
  totalSaved += await copyMinifiedJson(
    join(langSrcDir, file),
    join(langDstDir, file),
  );
}

console.log(
  `Prepared Hub mod assets at ${targetModDir} (saved ${(totalSaved / 1024).toFixed(1)} KB by minification)`,
);
