import readline from "readline";
import colors from "colors";
import {
  CommandRegistry,
  type ArgDefinition,
  type CommandCallback,
} from "./CommandRegistry.ts";
import { logger } from "../utils/logger.ts";
import { palette } from "../utils/palette.ts";
import type { ModConfig } from "../config.ts";
import { ModSyncWatcher } from "../modSync.ts";

export interface AppOptions {
  modFolder: string | null;
  luaFolder: string | null;
  config: ModConfig | null;
  effectCount: number;
}

export class App {
  private readonly registry: CommandRegistry;
  private rl: readline.Interface | null = null;
  private isShuttingDown = false;
  private modSyncWatcher: ModSyncWatcher | null = null;

  constructor(private readonly options: AppOptions) {
    this.registry = new CommandRegistry();
    this.registerBuiltins();
  }

  registerCommand(
    name: string,
    synonyms: string[],
    argDefs: ArgDefinition[],
    callback: CommandCallback,
    description?: string,
  ): void {
    this.registry.register(name, synonyms, argDefs, callback, description);
  }

  async start(): Promise<void> {
    logger.info(
      `${colors.yellow("ChaosMod")} ${colors.cyan("Streamer Mode")} initialized. Loaded ${colors.green(this.options.effectCount.toString())} effects.`,
    );

    if (this.options.luaFolder) {
      this.modSyncWatcher = new ModSyncWatcher(
        this.options.luaFolder,
        this.options.config?.effects_interval ?? 45,
      );
      this.modSyncWatcher.start();
    }

    // Tab completion: complete command names at first word, nothing for args
    const completer = (line: string): [string[], string] => {
      const spaceIdx = line.indexOf(" ");
      if (spaceIdx !== -1) return [[], line];

      const allNames = this.registry.getAllNames();
      const hits = allNames.filter((n) => n.startsWith(line.toLowerCase()));
      return [hits.length > 0 ? hits : allNames, line];
    };

    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      completer,
    });

    // Patch console so any log output clears the prompt line first, then redraws it after.
    type ConsoleFn = typeof console.log;
    const wrap =
      (orig: ConsoleFn): ConsoleFn =>
      (...a) => {
        readline.clearLine(process.stdout, 0);
        readline.cursorTo(process.stdout, 0);
        orig(...a);
        this.rl?.prompt(true);
      };
    console.log = wrap(console.log.bind(console));
    console.warn = wrap(console.warn.bind(console));
    console.error = wrap(console.error.bind(console));

    this.rl.setPrompt(colors.gray("> ") + palette.purple("/"));
    this.rl.prompt();

    this.rl.on("line", async (input: string) => {
      const trimmed = input.trim();
      if (trimmed) {
        const found = await this.registry.dispatch(trimmed);
        if (!found) {
          logger.warn(
            `Unknown command: ${palette.orange(trimmed)}. Type ${palette.purple("help")} for available commands.`,
          );
        }
      }
      this.rl?.prompt();
    });

    this.rl.on("SIGINT", () => {
      process.stdout.write("\n");
      this.shutdown();
    });

    this.rl.on("close", () => {
      this.shutdown();
    });
  }

  private shutdown(): void {
    if (this.isShuttingDown) return;
    this.isShuttingDown = true;
    this.modSyncWatcher?.stop();
    console.log(colors.gray("Goodbye!"));
    this.rl?.close();
    process.exit(0);
  }

  private registerBuiltins(): void {
    this.registry.register(
      "help",
      [],
      [],
      () => this.registry.printHelp(),
      "Show available commands",
    );

    this.registry.register(
      "exit",
      ["quit"],
      [],
      () => this.shutdown(),
      "Exit the application",
    );
  }
}
