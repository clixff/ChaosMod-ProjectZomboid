import { readdirSync, readFileSync } from "fs";
import { join } from "path";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

const effectId = process.argv[2];
if (!effectId) {
    console.error(`${RED}Usage: bun scripts/verify-effect.js <effect_name>${RESET}`);
    process.exit(1);
}

const rootDir = join(import.meta.dir, "..");
const effectsPath = join(rootDir, "Contents", "mods", "ChaosMod", "common", "default_effects.json");
const langDir = join(rootDir, "Contents", "mods", "ChaosMod", "common", "lang");

function fail(message) {
    console.error(`${RED}${message}${RESET}`);
}

function loadJson(path) {
    try {
        return JSON.parse(readFileSync(path, "utf-8"));
    } catch (error) {
        fail(`Failed to load ${path}: ${error}`);
        process.exit(1);
    }
}

let hasErrors = false;

const effectsJson = loadJson(effectsPath);
const effects = Array.isArray(effectsJson.effects) ? effectsJson.effects : [];
const effectIndex = effects.findIndex((effect) => effect?.id === effectId);

if (effectIndex === -1) {
    fail(`Effect not found in default_effects.json: ${effectId}`);
    hasErrors = true;
} else if (effectIndex !== effects.length - 1) {
    fail(`Effect is not the latest entry in default_effects.json: ${effectId}`);
    hasErrors = true;
}

const langFiles = readdirSync(langDir)
    .filter((file) => file.endsWith(".json"))
    .sort((a, b) => a.localeCompare(b));

for (const file of langFiles) {
    const langJson = loadJson(join(langDir, file));
    const effectsSection = langJson.effects;
    const hasEffectKey = effectsSection?.[effectId] !== undefined || langJson[`effect.${effectId}`] !== undefined;

    if (!hasEffectKey) {
        fail(`Effect not found in ${file}`);
        hasErrors = true;
        continue;
    }

    if (effectsSection && typeof effectsSection === "object" && !Array.isArray(effectsSection)) {
        const effectKeys = Object.keys(effectsSection);
        if (effectKeys.length === 0 || effectKeys[effectKeys.length - 1] !== effectId) {
            fail(`Effect is not the latest localization entry in ${file}: ${effectId}`);
            hasErrors = true;
        }
    }
}

if (hasErrors) {
    process.exit(1);
}

console.log(`${GREEN}OK${RESET}`);
