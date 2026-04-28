import type { EffectEntry } from "./effects.ts";

export type EffectPickType = "default" | "donate";

const RECENT_EFFECTS_MAX = 30;
const recentSet = new Set<string>();
const recentQueue: string[] = [];

function addToBlocklist(id: string): void {
  if (recentQueue.length >= RECENT_EFFECTS_MAX) {
    const evicted = recentQueue.shift();
    if (evicted !== undefined) recentSet.delete(evicted);
  }
  recentQueue.push(id);
  recentSet.add(id);
}

export function getRandomEffects(
  effects: EffectEntry[],
  amount: number,
  pickType: EffectPickType,
  ignoreChances: boolean,
): string[] {
  interface PoolEntry {
    id: string;
    weight: number;
  }

  const pool: PoolEntry[] = [];
  let totalWeight = 0;

  for (const effect of effects) {
    const eligible = pickType === "donate" ? effect.enabled_donate : effect.enabled;
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
    addToBlocklist(picked.id);
    totalWeight -= picked.weight;
    pool.splice(pickedIndex, 1);
  }

  return result;
}
