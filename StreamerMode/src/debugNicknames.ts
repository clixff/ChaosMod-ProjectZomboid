import { logger } from "./utils/logger.ts";
import { NicknamesManager } from "./streamer/NicknamesManager.ts";

const COLORS: string[] = [
  "#FF0000", "#0000FF", "#00FF00", "#B22222", "#FF7F50",
  "#9ACD32", "#FF4500", "#2E8B57", "#DAA520", "#D2691E",
  "#5F9EA0", "#1E90FF", "#FF69B4", "#8A2BE2", "#00FF7F",
];

const PREFIXES = [
  "Dark", "Cool", "Epic", "Fast", "Pro", "Mega", "Ultra", "Super",
  "Hyper", "Neo", "Shadow", "Ghost", "Fire", "Ice", "Storm", "Night",
  "Cyber", "Toxic", "Wild", "Rusty", "Crazy", "Sneaky", "Lucky", "Spooky",
];

const NOUNS = [
  "Wolf", "Fox", "Dragon", "Ninja", "Gamer", "Pixel", "Cat", "Bear",
  "Tiger", "Eagle", "Lion", "Hawk", "Shark", "Cobra", "Panda", "Rex",
  "Blade", "Frost", "Viper", "Raven", "Skull", "Torch", "Spike", "Dusk",
];

function randomItem<T>(arr: readonly T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]!;
}

function generateName(): string {
  const prefix = randomItem(PREFIXES);
  const noun = randomItem(NOUNS);
  const suffix = Math.random() < 0.4 ? String(Math.floor(Math.random() * 999) + 1) : "";
  return `${prefix}${noun}${suffix}`;
}

export function startDebugNicknames(manager: NicknamesManager): void {
  logger.info("Debug nicknames mode active — adding nicknames every second.");

  setInterval(() => {
    const count = 2 + Math.floor(Math.random() * 3); // 2–4 per tick
    for (let i = 0; i < count; i++) {
      const name = generateName();
      manager.add(name.toLowerCase(), name, randomItem(COLORS));
    }
  }, 1000);
}
