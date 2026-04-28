import colors from "colors";

export type CommandCallback = (args: string[]) => void | Promise<void>;

export interface ArgDefinition {
  name: string;
  description?: string;
  required?: boolean;
}

interface CommandDefinition {
  name: string;
  synonyms: string[];
  argDefs: ArgDefinition[];
  callback: CommandCallback;
  description?: string;
}

export class CommandRegistry {
  private readonly commands = new Map<string, CommandDefinition>();
  private readonly uniqueCommands: CommandDefinition[] = [];

  register(
    name: string,
    synonyms: string[],
    argDefs: ArgDefinition[],
    callback: CommandCallback,
    description?: string,
  ): void {
    const def: CommandDefinition = {
      name,
      synonyms,
      argDefs,
      callback,
      description,
    };
    this.uniqueCommands.push(def);
    this.commands.set(name.toLowerCase(), def);
    for (const syn of synonyms) {
      this.commands.set(syn.toLowerCase(), def);
    }
  }

  async dispatch(input: string): Promise<boolean> {
    const [cmdName, ...args] = input.trim().split(/\s+/);
    if (!cmdName) return false;

    const def = this.commands.get(cmdName.toLowerCase());
    if (!def) return false;

    await def.callback(args);
    return true;
  }

  getAllNames(): string[] {
    return [...this.commands.keys()];
  }

  getUniqueCommandNames(): string[] {
    return this.uniqueCommands.map((d) => d.name);
  }

  printHelp(): void {
    console.log(colors.bold("\nAvailable commands:"));
    for (const def of this.uniqueCommands) {
      const synsStr =
        def.synonyms.length > 0
          ? colors.gray(` (${def.synonyms.join(", ")})`)
          : "";
      const argsStr = def.argDefs
        .map((a) =>
          a.required
            ? colors.yellow(`<${a.name}>`)
            : colors.gray(`[${a.name}]`),
        )
        .join(" ");
      const descStr = def.description
        ? colors.gray(` — ${def.description}`)
        : "";
      const namePart = colors.cyan(def.name);
      console.log(
        `  ${namePart}${synsStr}${argsStr ? " " + argsStr : ""}${descStr}`,
      );
    }
    console.log("");
  }
}
