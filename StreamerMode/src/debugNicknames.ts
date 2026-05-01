import { logger } from "./utils/logger.ts";
import { NicknamesManager } from "./streamer/NicknamesManager.ts";

const DEBUG_CHAT_INTERVAL_MS = 15000;
const DEBUG_CHAT_OFFSETS_MS = [0, 4000, 9000];

const COLORS: string[] = [
  "#FF0000",
  "#0000FF",
  "#00FF00",
  "#B22222",
  "#FF7F50",
  "#9ACD32",
  "#FF4500",
  "#2E8B57",
  "#DAA520",
  "#D2691E",
  "#5F9EA0",
  "#1E90FF",
  "#FF69B4",
  "#8A2BE2",
  "#00FF7F",
];

const PREFIXES = [
  "Dark",
  "Cool",
  "Epic",
  "Fast",
  "Pro",
  "Mega",
  "Ultra",
  "Super",
  "Hyper",
  "Neo",
  "Shadow",
  "Ghost",
  "Fire",
  "Ice",
  "Storm",
  "Night",
  "Cyber",
  "Toxic",
  "Wild",
  "Rusty",
  "Crazy",
  "Sneaky",
  "Lucky",
  "Spooky",
];

const NOUNS = [
  "Wolf",
  "Fox",
  "Dragon",
  "Ninja",
  "Gamer",
  "Pixel",
  "Cat",
  "Bear",
  "Tiger",
  "Eagle",
  "Lion",
  "Hawk",
  "Shark",
  "Cobra",
  "Panda",
  "Rex",
  "Blade",
  "Frost",
  "Viper",
  "Raven",
  "Skull",
  "Torch",
  "Spike",
  "Dusk",
];

const CHAT_VOCABULARY =
  "Lorem Ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua".split(
    " ",
  );

function randomItem<T>(arr: readonly T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]!;
}

function generateName(): string {
  const prefix = randomItem(PREFIXES);
  const noun = randomItem(NOUNS);
  const suffix =
    Math.random() < 0.4 ? String(Math.floor(Math.random() * 999) + 1) : "";
  return `${prefix}${noun}${suffix}`;
}

function generateChatMessage(): string {
  const wordCount = 3 + Math.floor(Math.random() * 8);
  const words: string[] = [];
  for (let i = 0; i < wordCount; i++) {
    words.push(randomItem(CHAT_VOCABULARY));
  }
  return words.join(" ");
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

export function startDebugChatMessages(manager: NicknamesManager): void {
  logger.info(
    "Debug chat messages mode active — seeded users will send staggered messages every 15 seconds.",
  );

  const groups = DEBUG_CHAT_OFFSETS_MS.map(
    (): Array<{
      login: string;
      name: string;
      color: string;
    }> => [],
  );

  const totalUsers = 18;
  for (let i = 0; i < totalUsers; i++) {
    const name = generateName();
    const groupIndex = i % groups.length;
    groups[groupIndex]?.push({
      login: name.toLowerCase(),
      name,
      color: randomItem(COLORS),
    });
  }

  for (let groupIndex = 0; groupIndex < groups.length; groupIndex++) {
    const users = groups[groupIndex];
    const offsetMs = DEBUG_CHAT_OFFSETS_MS[groupIndex] ?? 0;

    const publishGroupMessages = (): void => {
      const timestampMs = Date.now();
      if (!users) return;
      for (const user of users) {
        manager.add(
          user.login,
          user.name,
          user.color,
          generateChatMessage(),
          timestampMs,
        );
      }
    };

    setTimeout(() => {
      publishGroupMessages();
      setInterval(publishGroupMessages, DEBUG_CHAT_INTERVAL_MS);
    }, offsetMs);
  }
}
