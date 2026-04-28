import colors from "colors";

let debugMode = false;

export function setDebugMode(enabled: boolean): void {
  debugMode = enabled;
}

export function isDebugMode(): boolean {
  return debugMode;
}

const prefixes = {
  info: colors.green("[INFO]"),
  debug: colors.cyan("[DEBUG]"),
  warn: colors.yellow("[WARN]"),
  error: colors.red("[ERROR]"),
};

export const logger = {
  info(msg: string): void {
    console.log(`${prefixes.info} ${msg}`);
  },
  debug(msg: string): void {
    if (debugMode) {
      console.log(`${prefixes.debug} ${msg}`);
    }
  },
  warn(msg: string): void {
    console.warn(`${prefixes.warn} ${msg}`);
  },
  error(msg: string): void {
    console.error(`${prefixes.error} ${msg}`);
  },
};
