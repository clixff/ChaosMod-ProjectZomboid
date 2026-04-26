import { logger } from "../utils/logger.ts";
import type { ModConfig } from "../config.ts";
import { TwitchProvider } from "./TwitchProvider.ts";

export type { StreamerUser } from "./TwitchProvider.ts";
export { TwitchProvider };

export type AnyProvider = TwitchProvider;

export function createProvider(config: ModConfig | null): AnyProvider | null {
  const type = config?.streamer_mode?.type ?? "twitch";
  if (type === "twitch") return new TwitchProvider();
  logger.warn(`Unknown streamer provider type: "${type}"`);
  return null;
}
