import { readFileSync } from "fs";
import { join } from "path";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const RESET = "\x1b[0m";

const lang = process.argv[2];
if (!lang) {
    console.error(`${RED}Usage: bun scripts/check_language.js <lang>${RESET}`);
    process.exit(1);
}

const langDir = join(import.meta.dir, "../Contents/mods/ChaosMod/common/lang");

function loadJson(path) {
    try {
        return JSON.parse(readFileSync(path, "utf-8"));
    } catch (e) {
        console.error(`${RED}Failed to load ${path}: ${e}${RESET}`);
        process.exit(1);
    }
}

const en = loadJson(join(langDir, "en.json"));
const target = loadJson(join(langDir, `${lang}.json`));

let missing = 0;

for (const section of Object.keys(en)) {
    for (const key of Object.keys(en[section])) {
        const inTarget = target[section]?.[key] !== undefined;
        if (!inTarget) {
            console.log(`${RED}Key '${section}.${key}' does not exist in ${lang}.json${RESET}`);
            missing++;
        }
    }
}

if (missing === 0) {
    console.log(`${GREEN}${lang}.json is complete — no missing keys.${RESET}`);
} else {
    console.log(`\n${RED}${missing} missing key(s) in ${lang}.json${RESET}`);
    process.exit(1);
}
