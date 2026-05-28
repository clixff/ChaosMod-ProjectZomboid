import { existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const RESET = "\x1b[0m";

const USAGE = 'Usage: bun scripts/upsert-translation.js <lang> <library.key> "<value>"';

function fail(message) {
    console.error(`${RED}${message}${RESET}`);
    process.exit(1);
}

const argv = process.argv.slice(2);
if (argv.length !== 3) fail(USAGE);

const [lang, dottedKey, value] = argv;

if (!/^[a-z]{2,3}(_[A-Z]{2})?$/.test(lang)) {
    fail(`Invalid language code "${lang}". Expected something like "ru", "en", "zh".`);
}

const parts = dottedKey.split(".");
if (parts.length !== 2 || parts.some((p) => p.length === 0)) {
    fail(`Invalid key "${dottedKey}". Must be exactly "<library>.<key>" (one dot, two non-empty segments).`);
}
const [library, key] = parts;

const rootDir = join(import.meta.dir, "..");
const langDir = join(rootDir, "Contents", "mods", "ChaosMod", "common", "lang");
const filePath = join(langDir, `${lang}.json`);

if (!existsSync(filePath)) {
    fail(`Language file not found: ${filePath}`);
}

let data;
try {
    data = JSON.parse(readFileSync(filePath, "utf-8"));
} catch (error) {
    fail(`Failed to parse ${filePath}: ${error}`);
}

if (typeof data !== "object" || data === null || Array.isArray(data)) {
    fail(`Top-level of ${filePath} must be a JSON object.`);
}

let libraryWasNew = false;
if (data[library] === undefined) {
    data[library] = {};
    libraryWasNew = true;
} else if (typeof data[library] !== "object" || data[library] === null || Array.isArray(data[library])) {
    fail(`Top-level "${library}" in ${filePath} exists but is not an object.`);
}

data[library][key] = value;

writeFileSync(filePath, JSON.stringify(data, null, 4) + "\n", "utf-8");

const relPath = filePath.replace(rootDir + "\\", "").replace(rootDir + "/", "");
console.log(`${GREEN}Key \`${key}\` in object \`${library}\` was updated in ${relPath} with value \`${value}\`${RESET}`);

if (libraryWasNew) {
    console.log(`${YELLOW}Warning: the \`${library}\` library was new for this language file. If this does not match the expected behavior, check the file and edit the key to specify the correct library.${RESET}`);
}
