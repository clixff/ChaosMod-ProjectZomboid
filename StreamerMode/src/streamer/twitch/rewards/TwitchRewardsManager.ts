import { existsSync, readFileSync, writeFileSync } from "fs";
import { join } from "path";
import colors from "colors";
import { logger } from "../../../utils/logger.ts";
import {
  createCustomReward,
  deleteCustomReward,
  listManageableRewards,
  setRewardEnabled,
  TwitchRewardsError,
  updateRedemptionStatus,
} from "./TwitchRewardsClient.ts";

export interface RewardRow {
  name: string;
  cost: number;
  groups: string[];
}

export interface StoredReward extends RewardRow {
  id: string;
}

interface RewardsFile {
  rewards: StoredReward[];
}

export interface RedemptionEvent {
  redemptionId: string;
  rewardId: string;
  userInput: string;
  userName: string;
}

export interface EffectLookup {
  id: string;
  numericId: number;
  enabled: boolean;
  enabled_donate: boolean;
  price_group: string;
}

export interface RedemptionResolver {
  /**
   * Returns the effect resolved for this redemption, or null when no eligible
   * effect could be matched (which causes a CANCEL/refund).
   */
  resolve(event: RedemptionEvent, reward: StoredReward): EffectLookup | null;
}

export interface ActivateCallback {
  (effect: EffectLookup, nickname: string): Promise<void> | void;
}

const REWARDS_FILE_NAME = "twitch_rewards.json";
const TWITCH_CLIENT_ID = "q72hcurbc7rcns1cefr9nqhmixe7b8";

export class TwitchRewardsManager {
  private readonly coloredName = colors.magenta("[TwitchPoints]");
  private readonly luaFolder: string;
  private rewards: StoredReward[] = [];

  /** Token / broadcaster supplied by index.ts (refreshed on login/logout). */
  private accessToken: string | null = null;
  private broadcasterId: string | null = null;

  /** Provides effect lookup at redemption time. */
  resolver: RedemptionResolver | null = null;
  /** Called with the activation request (FULFILL path). */
  onActivate: ActivateCallback | null = null;
  /** Called when a redemption is refunded (CANCEL path). */
  onRefund: ((event: RedemptionEvent, reason: string) => void) | null = null;

  constructor(luaFolder: string) {
    this.luaFolder = luaFolder;
    this.loadFromDisk();
  }

  get clientId(): string {
    return TWITCH_CLIENT_ID;
  }

  setAuth(broadcasterId: string | null, accessToken: string | null): void {
    this.broadcasterId = broadcasterId;
    this.accessToken = accessToken;
  }

  hasAuth(): boolean {
    return this.accessToken !== null && this.broadcasterId !== null;
  }

  get hasRewards(): boolean {
    return this.rewards.length > 0;
  }

  list(): StoredReward[] {
    return this.rewards.map((r) => ({ ...r, groups: [...r.groups] }));
  }

  /**
   * Reconcile in-memory rewards against Twitch's manageable rewards list. Drops
   * file rows whose id is no longer on Twitch. Orphan Twitch rewards that have
   * no matching file entry are left untouched.
   */
  async bootstrap(): Promise<void> {
    if (!this.hasAuth()) return;
    if (this.rewards.length === 0) return;
    let remote: { id: string }[];
    try {
      remote = await listManageableRewards({
        broadcasterId: this.broadcasterId!,
        token: this.accessToken!,
        clientId: TWITCH_CLIENT_ID,
      });
    } catch (err) {
      this.logErr("bootstrap (list)", err);
      return;
    }
    const remoteIds = new Set(remote.map((r) => r.id));
    const before = this.rewards.length;
    this.rewards = this.rewards.filter((r) => remoteIds.has(r.id));
    if (this.rewards.length !== before) {
      this.writeToDisk();
      logger.info(
        `${this.coloredName} Dropped ${before - this.rewards.length} stale reward(s) missing from Twitch.`,
      );
    }
  }

  /**
   * Create all supplied rows on Twitch. On any failure, rollback every reward
   * already created in this call. Throws TwitchRewardsError on failure.
   */
  async createAll(rows: RewardRow[]): Promise<void> {
    if (!this.hasAuth()) {
      throw new TwitchRewardsError(401, "Not logged in to Twitch");
    }
    if (this.rewards.length > 0) {
      throw new TwitchRewardsError(409, "Rewards already exist");
    }
    const created: StoredReward[] = [];
    try {
      for (const row of rows) {
        const remote = await createCustomReward({
          broadcasterId: this.broadcasterId!,
          token: this.accessToken!,
          clientId: TWITCH_CLIENT_ID,
          title: row.name,
          cost: row.cost,
          prompt: this.buildPrompt(row.groups),
        });
        created.push({
          id: remote.id,
          name: row.name,
          cost: row.cost,
          groups: [...row.groups],
        });
      }
    } catch (err) {
      for (const r of created) {
        await this.safeDelete(r.id);
      }
      throw err;
    }
    this.rewards = created;
    this.writeToDisk();
    logger.info(`${this.coloredName} Created ${created.length} reward(s).`);
  }

  /**
   * Delete every reward on Twitch and clear the file. Twitch auto-fulfills
   * any pending redemptions for deleted rewards; we don't iterate them.
   */
  async deleteAll(): Promise<void> {
    if (!this.hasAuth() || this.rewards.length === 0) {
      this.rewards = [];
      this.writeToDisk();
      return;
    }
    const errors: string[] = [];
    for (const r of this.rewards) {
      try {
        await deleteCustomReward({
          broadcasterId: this.broadcasterId!,
          token: this.accessToken!,
          clientId: TWITCH_CLIENT_ID,
          rewardId: r.id,
        });
      } catch (err) {
        if (err instanceof TwitchRewardsError) {
          errors.push(`${r.name}: ${err.status} ${err.twitchMessage}`);
        } else {
          errors.push(`${r.name}: ${err instanceof Error ? err.message : String(err)}`);
        }
      }
    }
    this.rewards = [];
    this.writeToDisk();
    if (errors.length > 0) {
      throw new TwitchRewardsError(502, `Some rewards failed to delete: ${errors.join("; ")}`);
    }
    logger.info(`${this.coloredName} Deleted all rewards.`);
  }

  /** Toggle `is_enabled` for every tracked reward. */
  async setVisible(visible: boolean): Promise<void> {
    if (!this.hasAuth() || this.rewards.length === 0) return;
    for (const r of this.rewards) {
      try {
        await setRewardEnabled({
          broadcasterId: this.broadcasterId!,
          token: this.accessToken!,
          clientId: TWITCH_CLIENT_ID,
          rewardId: r.id,
          enabled: visible,
        });
      } catch (err) {
        this.logErr(`setVisible(${visible}) for ${r.name}`, err);
      }
    }
    logger.debug(
      `${this.coloredName} Set rewards visibility to ${visible ? "enabled" : "disabled"}.`,
    );
  }

  /**
   * Handle a Twitch redemption notification. Looks up the reward, resolves an
   * effect, and either FULFILLs (activates) or CANCELs (refunds) it.
   */
  async handleRedemption(event: RedemptionEvent): Promise<void> {
    const reward = this.rewards.find((r) => r.id === event.rewardId);
    if (!reward) return;
    if (!this.hasAuth() || !this.resolver) return;

    const effect = this.resolver.resolve(event, reward);
    if (!effect) {
      await this.patchRedemption(event, reward.id, "CANCELED");
      this.onRefund?.(event, "no eligible effect");
      logger.debug(
        `${this.coloredName} Refunded redemption from ${event.userName} on "${reward.name}" (input="${event.userInput}").`,
      );
      return;
    }

    try {
      await this.onActivate?.(effect, event.userName);
      await this.patchRedemption(event, reward.id, "FULFILLED");
      logger.info(
        `${this.coloredName} Activated effect ${effect.id} for ${event.userName} via "${reward.name}".`,
      );
    } catch (err) {
      this.logErr("handleRedemption (activate)", err);
      await this.patchRedemption(event, reward.id, "CANCELED");
      this.onRefund?.(event, "activation failed");
    }
  }

  private async patchRedemption(
    event: RedemptionEvent,
    rewardId: string,
    status: "FULFILLED" | "CANCELED",
  ): Promise<void> {
    try {
      await updateRedemptionStatus({
        broadcasterId: this.broadcasterId!,
        token: this.accessToken!,
        clientId: TWITCH_CLIENT_ID,
        rewardId,
        redemptionId: event.redemptionId,
        status,
      });
    } catch (err) {
      this.logErr(`updateRedemptionStatus(${status})`, err);
    }
  }

  private async safeDelete(rewardId: string): Promise<void> {
    if (!this.hasAuth()) return;
    try {
      await deleteCustomReward({
        broadcasterId: this.broadcasterId!,
        token: this.accessToken!,
        clientId: TWITCH_CLIENT_ID,
        rewardId,
      });
    } catch (err) {
      this.logErr(`safeDelete(${rewardId})`, err);
    }
  }

  private buildPrompt(groups: string[]): string {
    const labels = groups.map(formatGroupLabel);
    return `For groups ${labels.join(", ")}. Type the effect number in chat (e.g. 151).`;
  }

  private loadFromDisk(): void {
    const path = join(this.luaFolder, REWARDS_FILE_NAME);
    if (!existsSync(path)) return;
    try {
      const raw = JSON.parse(readFileSync(path, "utf-8")) as unknown;
      if (raw === null || typeof raw !== "object") return;
      const rewardsRaw = (raw as { rewards?: unknown }).rewards;
      if (!Array.isArray(rewardsRaw)) return;
      const parsed: StoredReward[] = [];
      for (const entry of rewardsRaw) {
        if (entry === null || typeof entry !== "object") continue;
        const r = entry as Record<string, unknown>;
        if (
          typeof r["id"] !== "string" ||
          typeof r["name"] !== "string" ||
          typeof r["cost"] !== "number" ||
          !Array.isArray(r["groups"])
        ) {
          continue;
        }
        const groups = (r["groups"] as unknown[]).filter(
          (g): g is string => typeof g === "string",
        );
        parsed.push({
          id: r["id"],
          name: r["name"],
          cost: r["cost"],
          groups,
        });
      }
      this.rewards = parsed;
      logger.debug(
        `${this.coloredName} Loaded ${parsed.length} reward(s) from ${REWARDS_FILE_NAME}.`,
      );
    } catch (err) {
      this.logErr("loadFromDisk", err);
    }
  }

  private writeToDisk(): void {
    const path = join(this.luaFolder, REWARDS_FILE_NAME);
    const payload: RewardsFile = { rewards: this.rewards };
    try {
      writeFileSync(path, JSON.stringify(payload, null, 4), "utf-8");
    } catch (err) {
      this.logErr("writeToDisk", err);
    }
  }

  private logErr(where: string, err: unknown): void {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn(`${this.coloredName} ${where}: ${msg}`);
  }
}

function formatGroupLabel(group: string): string {
  const parts = group.split("_");
  if (parts.length === 2 && parts[0] && parts[1]) {
    const head = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
    return `${head} ${parts[1]}`;
  }
  return group;
}
