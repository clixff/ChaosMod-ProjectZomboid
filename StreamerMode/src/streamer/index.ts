import { TwitchProvider } from "./TwitchProvider.ts";
import { TwitchChatProvider } from "./TwitchChatProvider.ts";
import { YouTubeChatProvider } from "./youtube/YouTubeChatProvider.ts";

export type { StreamerUser } from "./TwitchProvider.ts";
export type {
  ChatProvider,
  ChatProviderKey,
  NormalizedChatMessage,
} from "./ChatProvider.ts";
export { TwitchProvider, TwitchChatProvider, YouTubeChatProvider };

export function createChatProviders(): {
  twitch: TwitchChatProvider;
  youtube: YouTubeChatProvider;
} {
  return {
    twitch: new TwitchChatProvider(),
    youtube: new YouTubeChatProvider(),
  };
}
