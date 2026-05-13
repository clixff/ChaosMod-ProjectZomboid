import { logger } from "../utils/logger.ts";
import type { EffectEntry } from "../effects.ts";
import type { ModConfig } from "../config.ts";

export const RANDOM_EFFECT_ID = "random_effect";

export interface VoteOption {
  id: string;
  voters: Set<string>;
}

export class VotingManager {
  private active = false;
  private options: VoteOption[] = [];
  private lastOptions: VoteOption[] = [];
  private lastWinner: string | null = null;
  private lastWinnerEffect: string | null = null;
  private secretRandomEffect: string | null = null;

  constructor(
    private readonly effects: EffectEntry[],
    private readonly config: ModConfig | null,
  ) {}

  get isActive(): boolean {
    return this.active;
  }

  get currentOptions(): readonly VoteOption[] {
    return this.options;
  }

  get displayOptions(): readonly VoteOption[] {
    return this.active ? this.options : this.lastOptions;
  }

  get lastWinnerId(): string | null {
    return this.lastWinner;
  }

  get lastWinnerEffectId(): string | null {
    return this.lastWinnerEffect;
  }

  get secretRandomEffectId(): string | null {
    return this.secretRandomEffect;
  }

  start(visibleEffectIds: readonly string[], secretEffectId: string | null): void {
    if (!this.config) return;
    this.lastWinner = null;
    this.lastWinnerEffect = null;
    this.lastOptions = [];
    this.secretRandomEffect = secretEffectId;
    const knownIds = new Set(this.effects.map((e) => e.id));
    const filteredIds = visibleEffectIds.filter((id) => knownIds.has(id));
    this.options = [
      ...filteredIds.map((id) => ({ id, voters: new Set<string>() })),
      { id: RANDOM_EFFECT_ID, voters: new Set<string>() },
    ];
    this.active = true;
    logger.debug(
      `Voting started (options: ${this.options.map((o) => o.id).join(", ")}, secret: ${secretEffectId ?? "none"})`,
    );
  }

  stop(): void {
    if (!this.active) return;
    this.active = false;
    this.lastOptions = this.options.map((option) => ({
      id: option.id,
      voters: new Set(option.voters),
    }));
    this.selectWinner();
    this.options = [];
    logger.debug("Voting ended");
  }

  addVote(userId: string, choice: number): void {
    if (!this.active) return;
    const index = choice - 1;
    if (index < 0 || index >= this.options.length) return;
    for (const option of this.options) option.voters.delete(userId);
    this.options[index]!.voters.add(userId);
  }

  private selectWinner(): void {
    if (this.options.length === 0 || !this.config) return;

    const totalVotes = this.options.reduce((sum, o) => sum + o.voters.size, 0);

    let winnerId: string;

    if (totalVotes === 0) {
      winnerId = RANDOM_EFFECT_ID;
    } else if (this.config.streamer_mode.voting_mode === 1) {
      const roll = Math.floor(Math.random() * totalVotes);
      let cumulative = 0;
      winnerId = RANDOM_EFFECT_ID;
      for (const option of this.options) {
        cumulative += option.voters.size;
        if (roll < cumulative) {
          winnerId = option.id;
          break;
        }
      }
    } else {
      const maxVotes = Math.max(...this.options.map((o) => o.voters.size));
      const tied = this.options.filter((o) => o.voters.size === maxVotes);
      winnerId = tied[Math.floor(Math.random() * tied.length)]!.id;
    }

    logger.debug(`Voting winner: ${winnerId}`);
    this.lastWinner = winnerId;

    if (winnerId === RANDOM_EFFECT_ID) {
      this.lastWinnerEffect = this.secretRandomEffect;
    } else {
      this.lastWinnerEffect = winnerId;
    }
  }
}
