import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from "fs";
import { join } from "path";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const RESET = "\x1b[0m";

const USAGE = "Usage: bun scripts/add-new-effect.js <effect_id> [--duration N] [--chance F] [--group G] [--path Subdir]";

function fail(message) {
    console.error(`${RED}${message}${RESET}`);
    process.exit(1);
}

function loadJson(path) {
    try {
        return JSON.parse(readFileSync(path, "utf-8"));
    } catch (error) {
        fail(`Failed to load ${path}: ${error}`);
    }
}

function writeJson(path, data) {
    writeFileSync(path, JSON.stringify(data, null, 4) + "\n", "utf-8");
}

function parseArgs(argv) {
    const args = { id: null, duration: null, chance: null, group: null, path: null };
    const positional = [];
    for (let i = 0; i < argv.length; i++) {
        const a = argv[i];
        if (a === "--duration" || a === "--chance" || a === "--group" || a === "--path") {
            const v = argv[++i];
            if (v === undefined) fail(`Missing value for ${a}\n${USAGE}`);
            args[a.slice(2)] = v;
        } else if (a.startsWith("--")) {
            fail(`Unknown flag: ${a}\n${USAGE}`);
        } else {
            positional.push(a);
        }
    }
    if (positional.length !== 1) fail(USAGE);
    args.id = positional[0];
    return args;
}

function stripEffectPrefix(id) {
    return id.startsWith("effect_") ? id.slice("effect_".length) : id;
}

function toPascalCase(snake) {
    return snake
        .split("_")
        .filter((p) => p.length > 0)
        .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
        .join("");
}

function toTitleCase(snake) {
    return snake
        .split("_")
        .filter((p) => p.length > 0)
        .map((p) => p.charAt(0).toUpperCase() + p.slice(1))
        .join(" ");
}

const argv = process.argv.slice(2);
const args = parseArgs(argv);

if (!/^[a-z][a-z0-9_]*$/.test(args.id)) {
    fail(`Invalid effect id "${args.id}". Must match /^[a-z][a-z0-9_]*$/ (lowercase snake_case).`);
}

let duration = null;
if (args.duration !== null) {
    const n = Number(args.duration);
    if (!Number.isInteger(n) || n <= 0) {
        fail(`--duration must be a positive integer, got "${args.duration}".`);
    }
    duration = n;
}

let chance = 1.0;
let chanceProvided = false;
if (args.chance !== null) {
    const n = Number(args.chance);
    if (!Number.isFinite(n) || n < 0 || n > 1) {
        fail(`--chance must be a number in [0, 1], got "${args.chance}".`);
    }
    chance = n;
    chanceProvided = true;
}

const rootDir = join(import.meta.dir, "..");
const configPath = join(rootDir, "Contents", "mods", "ChaosMod", "common", "default_config.json");
const effectsPath = join(rootDir, "Contents", "mods", "ChaosMod", "common", "default_effects.json");
const langDir = join(rootDir, "Contents", "mods", "ChaosMod", "common", "lang");
const effectsListDir = join(rootDir, "Contents", "mods", "ChaosMod", "42", "media", "lua", "client", "ChaosMod", "Effects", "List");

const config = loadJson(configPath);
const priceGroups = config?.streamer_mode?.donate_price_groups;
if (!Array.isArray(priceGroups)) {
    fail(`Could not read streamer_mode.donate_price_groups from ${configPath}.`);
}
const validGroups = priceGroups.map((g) => g.group);

let group = "neutral_3";
let groupProvided = false;
if (args.group !== null) {
    if (!validGroups.includes(args.group)) {
        fail(`Unknown price group "${args.group}". Valid groups: ${validGroups.join(", ")}.`);
    }
    group = args.group;
    groupProvided = true;
}

let targetDir = effectsListDir;
let targetSubdirLabel = "Effects/List";
if (args.path !== null) {
    targetDir = join(effectsListDir, args.path);
    targetSubdirLabel = `Effects/List/${args.path}`;
    if (!existsSync(targetDir) || !statSync(targetDir).isDirectory()) {
        const subdirs = readdirSync(effectsListDir, { withFileTypes: true })
            .filter((d) => d.isDirectory())
            .map((d) => d.name);
        fail(`Subdirectory "${args.path}" does not exist under Effects/List. Available: ${subdirs.join(", ")}.`);
    }
}

const className = "Effect" + toPascalCase(stripEffectPrefix(args.id));
const luaFileName = `${className}.lua`;
const luaFilePath = join(targetDir, luaFileName);

if (existsSync(luaFilePath)) {
    fail(`Lua file already exists: ${luaFilePath}`);
}

const effectsJson = loadJson(effectsPath);
if (!Array.isArray(effectsJson.effects)) {
    fail(`default_effects.json has no "effects" array.`);
}
if (effectsJson.effects.some((e) => e?.id === args.id)) {
    fail(`Effect id "${args.id}" already exists in default_effects.json.`);
}

const locValue = toTitleCase(stripEffectPrefix(args.id));

const langFiles = readdirSync(langDir)
    .filter((f) => f.endsWith(".json"))
    .sort((a, b) => a.localeCompare(b));

const lines = [];
lines.push(`---@class ${className} : ChaosEffectBase`);
lines.push(`${className} = ChaosEffectBase:derive("${className}", "${args.id}")`);
lines.push("");
lines.push(`function ${className}:OnStart()`);
lines.push(`    ChaosEffectBase:OnStart()`);
lines.push(`end`);
if (duration !== null) {
    lines.push("");
    lines.push(`---@param deltaMs integer`);
    lines.push(`function ${className}:OnTick(deltaMs)`);
    lines.push(`    ChaosEffectBase:OnTick(deltaMs)`);
    lines.push(`end`);
}
lines.push("");
lines.push(`function ${className}:OnEnd()`);
lines.push(`    ChaosEffectBase:OnEnd()`);
lines.push(`end`);
lines.push("");

if (!existsSync(targetDir)) mkdirSync(targetDir, { recursive: true });
writeFileSync(luaFilePath, lines.join("\n"), "utf-8");

const newEntry = {
    id: args.id,
    enabled: true,
    chance: chance,
    withDuration: duration !== null,
};
if (duration !== null) {
    newEntry.duration = duration;
    newEntry.disable_effects = [args.id];
}
newEntry.enabled_donate = true;
newEntry.price_group = group;

effectsJson.effects.push(newEntry);
writeJson(effectsPath, effectsJson);

for (const file of langFiles) {
    const path = join(langDir, file);
    const data = loadJson(path);
    if (!data.effects || typeof data.effects !== "object" || Array.isArray(data.effects)) {
        fail(`${file} has no "effects" object.`);
    }
    if (data.effects[args.id] !== undefined) {
        fail(`Localization key "${args.id}" already exists in ${file}.`);
    }
    data.effects[args.id] = locValue;
    writeJson(path, data);
}

const relLuaPath = luaFilePath.replace(rootDir + "\\", "").replace(rootDir + "/", "");
const durationReportPart = duration !== null ? `duration ${duration}, ` : "";
console.log(`${GREEN}Added effect ID ${args.id} to file ${relLuaPath}${RESET}`);
console.log(`${GREEN}Added effect ID ${args.id} to default_effects.json with ${durationReportPart}chance ${chance}, price group "${group}"${RESET}`);
console.log(`${GREEN}Added localization key "effects.${args.id}" with value "${locValue}" to folder ${langDir.replace(rootDir + "\\", "").replace(rootDir + "/", "")} in files ${langFiles.join(", ")}${RESET}`);

if (!groupProvided && !chanceProvided) {
    console.log(`${YELLOW}Warning: used default with price group "neutral_3" and 1.0 chance.${RESET}`);
} else if (!groupProvided) {
    console.log(`${YELLOW}Warning: used default price group "neutral_3".${RESET}`);
} else if (!chanceProvided) {
    console.log(`${YELLOW}Warning: used default chance 1.0.${RESET}`);
}
console.log(`${YELLOW}Warning: used default English translation for all languages.${RESET}`);
