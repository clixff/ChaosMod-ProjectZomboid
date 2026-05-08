import type { EffectEntry } from "./effects.ts";

export type EffectPickType = "default" | "donate";

let RECENT_EFFECTS_MAX = 90;
const recentSet = new Set<string>();
const recentQueue: string[] = [];

export function setRecentEffectsMax(n: number): void {
  if (typeof n !== "number" || !isFinite(n) || n < 0) return;
  RECENT_EFFECTS_MAX = Math.floor(n);
  while (recentQueue.length > RECENT_EFFECTS_MAX) {
    const evicted = recentQueue.shift();
    if (evicted !== undefined) recentSet.delete(evicted);
  }
}

function pushToBlocklist(id: string): void {
  if (recentSet.has(id)) return;
  if (RECENT_EFFECTS_MAX <= 0) return;
  if (recentQueue.length >= RECENT_EFFECTS_MAX) {
    const evicted = recentQueue.shift();
    if (evicted !== undefined) recentSet.delete(evicted);
  }
  recentQueue.push(id);
  recentSet.add(id);
}

export function markEffectUsed(id: string): void {
  pushToBlocklist(id);
}

export function getRandomEffects(
  effects: EffectEntry[],
  amount: number,
  pickType: EffectPickType,
  ignoreChances: boolean,
  addToBlocklist: boolean = true,
): string[] {
  interface PoolEntry {
    id: string;
    weight: number;
  }

  const pool: PoolEntry[] = [];
  let totalWeight = 0;

  for (const effect of effects) {
    const eligible =
      pickType === "donate" ? effect.enabled_donate : effect.enabled;
    if (eligible && effect.chance > 0 && !recentSet.has(effect.id)) {
      const weight = ignoreChances ? 1 : effect.chance;
      pool.push({ id: effect.id, weight });
      totalWeight += weight;
    }
  }

  const result: string[] = [];

  for (let i = 0; i < amount; i++) {
    if (totalWeight <= 0) break;

    const roll = Math.random() * totalWeight;
    let cumulative = 0;
    let pickedIndex = -1;

    for (let j = 0; j < pool.length; j++) {
      cumulative += pool[j]!.weight;
      if (roll < cumulative) {
        pickedIndex = j;
        break;
      }
    }

    if (pickedIndex === -1) break;

    const picked = pool[pickedIndex]!;
    result.push(picked.id);
    if (addToBlocklist) pushToBlocklist(picked.id);
    totalWeight -= picked.weight;
    pool.splice(pickedIndex, 1);
  }

  return result;
}
