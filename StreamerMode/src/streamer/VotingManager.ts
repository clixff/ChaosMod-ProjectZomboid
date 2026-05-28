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

export interface VoteWinner {
  optionId: string;
  effectId: string;
  tag: VoteOptionTag;
}

export class VotingManager {
  private active = false;
  private options: VoteOption[] = [];
  private lastOptions: VoteOption[] = [];
  private lastWinner: string | null = null;
  private lastWinnerEffect: string | null = null;
  private lastWinnerTag: VoteOptionTag = null;
  private lastWinners: VoteWinner[] = [];
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

  /**
   * Returns the most recent batch of winners (1 for normal voting, N for
   * combo_time meta-effect cycles). Populated by `stop()`.
   */
  get lastWinnersBatch(): readonly VoteWinner[] {
    return this.lastWinners;
  }

  start(visibleEffectIds: readonly string[], secretEffectId: string | null): void {
    if (!this.config) return;
    this.lastWinner = null;
    this.lastWinnerEffect = null;
    this.lastWinnerTag = null;
    this.lastWinners = [];
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

  /**
   * Closes voting and selects winners. `desiredCount` defaults to 1; pass >1
   * when combo_time meta is active to get up to N winners (clamped to total
   * options). Tie-breaks at the boundary slot are randomized.
   */
  stop(desiredCount?: number): void {
    if (!this.active) return;
    this.active = false;
    this.lastOptions = this.options.map((option) => ({
      id: option.id,
      voters: new Set(option.voters),
      tag: option.tag,
    }));
    const n = Math.max(1, Math.floor(desiredCount ?? 1));
    this.selectWinners(n);
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

  private toWinner(option: VoteOption): VoteWinner {
    const effectId =
      option.id === RANDOM_EFFECT_ID
        ? (this.secretRandomEffect ?? option.id)
        : option.id;
    return {
      optionId: option.id,
      effectId,
      tag: option.tag,
    };
  }

  /** Top-N tie-break: random shuffle of options tied at the cutoff vote count. */
  private pickTopN(n: number): VoteOption[] {
    const sorted = [...this.options].sort(
      (a, b) => b.voters.size - a.voters.size,
    );
    if (n >= sorted.length) return sorted;
    const cutoffVotes = sorted[n - 1]!.voters.size;
    const above = sorted.filter((o) => o.voters.size > cutoffVotes);
    const tied = sorted.filter((o) => o.voters.size === cutoffVotes);
    // Shuffle the tied bucket so ties at the boundary are random.
    for (let i = tied.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [tied[i], tied[j]] = [tied[j]!, tied[i]!];
    }
    const remainingSlots = n - above.length;
    return above.concat(tied.slice(0, remainingSlots));
  }

  /** Weighted-random N distinct winners via sampling without replacement. */
  private pickWeightedN(n: number): VoteOption[] {
    const pool = this.options.map((o) => ({
      option: o,
      weight: o.voters.size,
    }));
    const winners: VoteOption[] = [];
    while (winners.length < n && pool.length > 0) {
      const totalWeight = pool.reduce((sum, p) => sum + p.weight, 0);
      let pickedIdx: number;
      if (totalWeight <= 0) {
        // Remaining options have zero votes; pick uniformly at random.
        pickedIdx = Math.floor(Math.random() * pool.length);
      } else {
        const roll = Math.random() * totalWeight;
        let cumulative = 0;
        pickedIdx = pool.length - 1;
        for (let i = 0; i < pool.length; i++) {
          cumulative += pool[i]!.weight;
          if (roll < cumulative) {
            pickedIdx = i;
            break;
          }
        }
      }
      winners.push(pool[pickedIdx]!.option);
      pool.splice(pickedIdx, 1);
    }
    return winners;
  }

  private selectWinners(n: number): void {
    if (this.options.length === 0 || !this.config) return;

    const slotCount = Math.min(n, this.options.length);
    const totalVotes = this.options.reduce((sum, o) => sum + o.voters.size, 0);

    let winningOptions: VoteOption[];

    if (totalVotes === 0) {
      // No votes — slot 1 is the random_effect option (or whatever the first
      // option happens to be when random is disabled); fill remaining slots
      // by random pick from the rest.
      const random = this.options.find((o) => o.id === RANDOM_EFFECT_ID);
      const others = this.options.filter((o) => o.id !== RANDOM_EFFECT_ID);
      for (let i = others.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [others[i], others[j]] = [others[j]!, others[i]!];
      }
      winningOptions = [];
      if (random) winningOptions.push(random);
      for (const o of others) {
        if (winningOptions.length >= slotCount) break;
        winningOptions.push(o);
      }
      // If random_effect was not in the option set, fall through to the others.
      winningOptions = winningOptions.slice(0, slotCount);
    } else if (this.config.streamer_mode.voting_mode === 1) {
      winningOptions = this.pickWeightedN(slotCount);
    } else {
      winningOptions = this.pickTopN(slotCount);
    }

    this.lastWinners = winningOptions.map((o) => this.toWinner(o));

    // Maintain legacy single-winner fields from the first slot.
    const first = winningOptions[0];
    if (first) {
      this.lastWinner = first.id;
      this.lastWinnerTag = first.tag;
      this.lastWinnerEffect =
        first.id === RANDOM_EFFECT_ID
          ? this.secretRandomEffect
          : first.id;
    }

    logger.debug(
      `Voting winners (${winningOptions.length}): ${winningOptions.map((o) => o.id).join(", ")}`,
    );
  }
}
