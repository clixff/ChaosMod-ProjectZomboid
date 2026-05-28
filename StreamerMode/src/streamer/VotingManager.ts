import { logger } from "../utils/logger.ts";
import type { EffectEntry } from "../effects.ts";
import type { ModConfig } from "../config.ts";

export const RANDOM_EFFECT_ID = "random_effect";

/** Display/activation tag rolled per visible vote option. */
export type VoteOptionTag = "fake" | "hidden" | null;

export interface VoteOption {
  id: string;
  voters: Set<string>;
  tag: VoteOptionTag;
}

export class VotingManager {
  private active = false;
  private options: VoteOption[] = [];
  private lastOptions: VoteOption[] = [];
  private lastWinner: string | null = null;
  private lastWinnerEffect: string | null = null;
  private lastWinnerTag: VoteOptionTag = null;
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

  get lastWinnerOptionTag(): VoteOptionTag {
    return this.lastWinnerTag;
  }

  get secretRandomEffectId(): string | null {
    return this.secretRandomEffect;
  }

  start(visibleEffectIds: readonly string[], secretEffectId: string | null): void {
    if (!this.config) return;
    this.lastWinner = null;
    this.lastWinnerEffect = null;
    this.lastWinnerTag = null;
    this.lastOptions = [];
    this.secretRandomEffect = secretEffectId;
    const knownIds = new Set(this.effects.map((e) => e.id));
    const filteredIds = visibleEffectIds.filter((id) => knownIds.has(id));
    const includeRandom =
      this.config.streamer_mode.random_effect_in_vote !== false;
    // Fake/Hidden tags only apply to visible (non-hidden) effect options, never
    // the hidden Random/Secret option.
    const sm = this.config.streamer_mode;
    const fakeEnabled = sm.voting_fake_effects_enabled === true;
    const fakeChance = sm.voting_fake_effects_chance;
    const hiddenEnabled = sm.voting_hidden_effects_enabled === true;
    const hiddenChance = sm.voting_hidden_effects_chance;
    this.options = filteredIds.map((id) => ({
      id,
      voters: new Set<string>(),
      tag: this.rollOptionTag(
        fakeEnabled,
        fakeChance,
        hiddenEnabled,
        hiddenChance,
      ),
    }));
    if (includeRandom) {
      this.options.push({
        id: RANDOM_EFFECT_ID,
        voters: new Set<string>(),
        tag: null,
      });
    }
    this.active = true;
    logger.debug(
      `Voting started (options: ${this.options.map((o) => o.id).join(", ")}, secret: ${secretEffectId ?? "none"})`,
    );
  }

  // Roll the per-option tag. Fake is rolled first; only if it loses do we roll
  // Hidden. Tags are mutually exclusive.
  private rollOptionTag(
    fakeEnabled: boolean,
    fakeChance: number,
    hiddenEnabled: boolean,
    hiddenChance: number,
  ): VoteOptionTag {
    if (fakeEnabled && Math.random() * 100 < fakeChance) {
      return "fake";
    }
    if (hiddenEnabled && Math.random() * 100 < hiddenChance) {
      return "hidden";
    }
    return null;
  }

  stop(): void {
    if (!this.active) return;
    this.active = false;
    this.lastOptions = this.options.map((option) => ({
      id: option.id,
      voters: new Set(option.voters),
      tag: option.tag,
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

    const winningOption = this.options.find((o) => o.id === winnerId);
    this.lastWinnerTag = winningOption?.tag ?? null;

    if (winnerId === RANDOM_EFFECT_ID) {
      this.lastWinnerEffect = this.secretRandomEffect;
    } else {
      this.lastWinnerEffect = winnerId;
    }
  }
}
