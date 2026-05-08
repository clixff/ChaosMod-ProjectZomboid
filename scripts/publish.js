import { cp, mkdir, copyFile } from "fs/promises";
import { join } from "path";
import { spawn } from "child_process";

const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const CYAN = "\x1b[36m";
const RESET = "\x1b[0m";

const rootDir = join(import.meta.dir, "..");
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
