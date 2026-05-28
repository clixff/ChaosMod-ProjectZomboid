export interface EffectsFile {
  effects: EffectDef[];
}

export interface EffectDef {
  id: string;
  enabled: boolean;
  chance: number;
  withDuration: boolean;
  duration?: number;
  enabled_donate: boolean;
  price_group: string;
  // disable_effects exists on some entries; not surfaced in the hub.
  disable_effects?: string[];
}

export interface ConfigFile {
  streamer_mode: {
    donate_price_groups: PriceGroupEntry[];
    donation_systems: {
      twitch_bits: {
        enabled: boolean;
        price_multiplier: number;
      };
      // Other donation systems exist but are not surfaced in the hub.
    };
    [key: string]: unknown;
  };
  [key: string]: unknown;
}

export interface PriceGroupEntry {
  group: string;
  price: number;
}

export interface LangFile {
  effects?: Record<string, string>;
  descriptions?: Record<string, string>;
  core?: Record<string, string>;
  misc?: Record<string, string>;
  export?: Record<string, string>;
  [key: string]: unknown;
}

export interface EffectRow {
  numericId: number;
  effectId: string;
  enabled: boolean;
  chance: number;
  withDuration: boolean;
  duration?: number;
  enabledDonate: boolean;
  priceGroup: string;
  price: number | null;
  twitchBits: number | null;
  name: string;
  description: string;
}
