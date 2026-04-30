import { cp, mkdir, readFile, copyFile } from "fs/promises";
import { join } from "path";
import { spawn } from "child_process";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const CYAN = "\x1b[36m";
const RESET = "\x1b[0m";

const rootDir = join(import.meta.dir, "..");
const configPath = join(rootDir, "Contents", "mods", "ChaosMod", "common", "config.json");
const defaultConfigPath = join(rootDir, "default-config.json");
const contentsDir = join(rootDir, "Contents");
const streamerModeDir = join(rootDir, "StreamerMode");
const streamerExePath = join(streamerModeDir, "dist", "ChaosModStreamerApp.exe");

function formatTimestamp(date) {
    const pad = (value) => String(value).padStart(2, "0");

    return [
        date.getFullYear(),
        pad(date.getMonth() + 1),
        pad(date.getDate()),
    ].join("-") + "_" + [
        pad(date.getHours()),
        pad(date.getMinutes()),
        pad(date.getSeconds()),
    ].join("-");
}

function describeType(value) {
    if (Array.isArray(value)) return "array";
    if (value === null) return "null";
    return typeof value;
}

function findFirstDifference(actual, expected, path = "") {
    if (Object.is(actual, expected)) {
        return null;
    }

    const actualIsArray = Array.isArray(actual);
    const expectedIsArray = Array.isArray(expected);
    if (actualIsArray || expectedIsArray) {
        if (!actualIsArray || !expectedIsArray) {
            return {
                path,
                reason: `type mismatch: actual=${describeType(actual)} expected=${describeType(expected)}`,
                actual,
                expected,
            };
        }

        if (actual.length !== expected.length) {
            return {
                path,
                reason: `array length mismatch: actual=${actual.length} expected=${expected.length}`,
                actual,
                expected,
            };
        }

        for (let index = 0; index < expected.length; index++) {
            const diff = findFirstDifference(actual[index], expected[index], `${path}[${index}]`);
            if (diff) {
                return diff;
            }
        }

        return null;
    }

    const actualIsObject = actual !== null && typeof actual === "object";
    const expectedIsObject = expected !== null && typeof expected === "object";
    if (actualIsObject || expectedIsObject) {
        if (!actualIsObject || !expectedIsObject) {
            return {
                path,
                reason: `type mismatch: actual=${describeType(actual)} expected=${describeType(expected)}`,
                actual,
                expected,
            };
        }

        const actualKeys = Object.keys(actual).sort();
        const expectedKeys = Object.keys(expected).sort();
        const allKeys = Array.from(new Set([...actualKeys, ...expectedKeys])).sort();

        for (const key of allKeys) {
            if (!(key in actual)) {
                return {
                    path: path ? `${path}.${key}` : key,
                    reason: "missing key in config.json",
                    actual: undefined,
                    expected: expected[key],
                };
            }

            if (!(key in expected)) {
                return {
                    path: path ? `${path}.${key}` : key,
                    reason: "extra key in config.json",
                    actual: actual[key],
                    expected: undefined,
                };
            }

            const diff = findFirstDifference(actual[key], expected[key], path ? `${path}.${key}` : key);
            if (diff) {
                return diff;
            }
        }

        return null;
    }

    return {
        path,
        reason: "value mismatch",
        actual,
        expected,
    };
}

async function loadJson(path) {
    return JSON.parse(await readFile(path, "utf-8"));
}

async function runCompile() {
    await new Promise((resolve, reject) => {
        const child = spawn("bun", ["run", "compile"], {
            cwd: streamerModeDir,
            stdio: "inherit",
            shell: true,
        });

        child.on("error", reject);
        child.on("exit", (code) => {
            if (code === 0) {
                resolve();
                return;
            }
            reject(new Error(`bun run compile exited with code ${code}`));
        });
    });
}

async function main() {
    const actualConfig = await loadJson(configPath);
    const defaultConfig = await loadJson(defaultConfigPath);
    const diff = findFirstDifference(actualConfig, defaultConfig);

    if (diff) {
        const diffPath = diff.path || "<root>";
        console.error(`${RED}Publish aborted: config.json differs from default-config.json at ${diffPath}.${RESET}`);
        console.error(`${RED}${diff.reason}${RESET}`);
        console.error(`${RED}actual: ${JSON.stringify(diff.actual)}${RESET}`);
        console.error(`${RED}expected: ${JSON.stringify(diff.expected)}${RESET}`);
        process.exit(1);
    }

    const timestamp = formatTimestamp(new Date());
    const releaseDir = join(rootDir, "releases", timestamp);
    const chaosModDir = join(releaseDir, "ChaosModPZ");
    const releaseExePath = join(releaseDir, "ZomboidStreamerApp.exe");

    console.log(`${CYAN}Creating release folder ${releaseDir}${RESET}`);
    await mkdir(chaosModDir, { recursive: true });

    console.log(`${CYAN}Copying Contents -> ${chaosModDir}${RESET}`);
    await cp(contentsDir, chaosModDir, { recursive: true });

    console.log(`${CYAN}Running StreamerMode compile${RESET}`);
    await runCompile();

    console.log(`${CYAN}Copying StreamerMode executable -> ${releaseExePath}${RESET}`);
    await copyFile(streamerExePath, releaseExePath);

    console.log(`${GREEN}Release created successfully: ${releaseDir}${RESET}`);
}

main().catch((error) => {
    console.error(`${RED}${error instanceof Error ? error.message : String(error)}${RESET}`);
    process.exit(1);
});
