import { logger } from "./utils/logger.ts";
import { VotingManager } from "./streamer/VotingManager.ts";

const RANDOM_USER_COUNT = 80;
const TICK_INTERVAL_MS = 1200;

function randomInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function getRandomUserId(): string {
  return `debug-user-${randomInt(1, RANDOM_USER_COUNT)}`;
}

function buildOptionSignature(optionIds: readonly string[]): string {
  return optionIds.join("|");
}

function generateRoundWeights(optionCount: number): number[] {
  return Array.from({ length: optionCount }, () => {
    // Cubic bias produces clearer "popular" and "unpopular" options each round.
    const factor = Math.random();
    return 0.2 + (factor * factor * factor) * 2.8;
  });
}

function chooseWeightedIndex(weights: readonly number[]): number {
  const totalWeight = weights.reduce((sum, weight) => sum + weight, 0);
  if (totalWeight <= 0) return 0;

  let roll = Math.random() * totalWeight;
  for (let i = 0; i < weights.length; i++) {
    roll -= weights[i] ?? 0;
    if (roll <= 0) return i;
  }

  return Math.max(0, weights.length - 1);
}

export function startDebugVotes(manager: VotingManager): void {
  logger.info("Debug votes mode active — generating random votes while voting is enabled.");

  let currentRoundSignature = "";
  let currentRoundWeights: number[] = [];

  setInterval(() => {
    if (!manager.isActive) {
      currentRoundSignature = "";
      currentRoundWeights = [];
      return;
    }

    const optionIds = manager.currentOptions.map((option) => option.id);
    const optionCount = optionIds.length;
    if (optionCount === 0) return;

    const roundSignature = buildOptionSignature(optionIds);
    if (roundSignature !== currentRoundSignature) {
      currentRoundSignature = roundSignature;
      currentRoundWeights = generateRoundWeights(optionCount);
      logger.debug(
        `Debug votes: new round weights -> ${optionIds.map((id, index) => `${id}:${currentRoundWeights[index]?.toFixed(2) ?? "0.00"}`).join(", ")}`,
      );
    }

    const voteCount = randomInt(10, 30);
    for (let i = 0; i < voteCount; i++) {
      const userId = getRandomUserId();
      const optionIndex = chooseWeightedIndex(currentRoundWeights) + 1;
      manager.addVote(userId, optionIndex);
    }
  }, TICK_INTERVAL_MS);
}
