import { useEffect, useMemo, useState } from "react";
import { Section, FieldRow } from "../components/Section.tsx";
import { TextInput, NumberInput } from "../components/Input.tsx";
import { Checkbox } from "../components/Checkbox.tsx";
import { Select } from "../components/Select.tsx";
import {
  getConfig,
  getEffects,
  getTwitchPointsStatus,
  updateEffect,
  type EffectEntry,
  type DonatePriceGroup,
  type ModConfig,
  type TwitchPointsStatus,
} from "../api.ts";
import { smartRoundAmount, getCurrencyName } from "../currencyUtils.ts";

interface EffectsPageProps {
  onNotify: (message: string, isError?: boolean) => void;
}

export function EffectsPage({ onNotify }: EffectsPageProps) {
  const [effects, setEffects] = useState<EffectEntry[]>([]);
  const [priceGroups, setPriceGroups] = useState<DonatePriceGroup[]>([]);
  const [config, setConfig] = useState<ModConfig | null>(null);
  const [twitchPoints, setTwitchPoints] = useState<TwitchPointsStatus | null>(
    null,
  );
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [groupFilter, setGroupFilter] = useState<string>("__all__");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const [data, cfg, points] = await Promise.all([
          getEffects(),
          getConfig(),
          getTwitchPointsStatus().catch(() => null),
        ]);
        if (!cancelled) {
          setEffects(data.effects);
          setPriceGroups(data.price_groups);
          setConfig(cfg);
          setTwitchPoints(points);
        }
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        onNotify(`Failed to load effects: ${msg}`, true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [onNotify]);

  const effectiveCurrency = useMemo(() => {
    if (!config) return "";
    const main = config.streamer_mode.currencies.main.trim().toUpperCase();
    if (main) return main;
    return (
      config.streamer_mode.donation_systems.donationalerts.currency
        .trim()
        .toUpperCase() || ""
    );
  }, [config]);

  const indexedEffects = useMemo(
    () => effects.map((effect, i) => ({ effect, index: i + 1 })),
    [effects],
  );

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return indexedEffects.filter(({ effect }) => {
      if (q) {
        if (
          !effect.name.toLowerCase().includes(q) &&
          !effect.id.toLowerCase().includes(q)
        ) {
          return false;
        }
      }
      if (groupFilter === "__all__") return true;
      if (groupFilter === "__none__") return effect.price_group === "";
      return effect.price_group === groupFilter;
    });
  }, [indexedEffects, search, groupFilter]);

  const selected = effects.find((e) => e.id === selectedId) ?? null;

  const patchEffect = (id: string, patch: Partial<EffectEntry>) => {
    setEffects((prev) =>
      prev.map((e) => (e.id === id ? { ...e, ...patch } : e)),
    );
    void (async () => {
      try {
        await updateEffect(id, patch);
        onNotify("Saved");
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        onNotify(`Save failed: ${msg}`, true);
      }
    })();
  };

  if (loading) return <div className="loading">Loading effects…</div>;

  const groupOptions = [
    { value: "", label: "(none)" },
    ...priceGroups.map((g) => ({ value: g.group, label: g.group })),
  ];

  const filterOptions = [
    { value: "__all__", label: "All groups" },
    { value: "__none__", label: "(none)" },
    ...priceGroups.map((g) => ({ value: g.group, label: g.group })),
  ];

  const selectedPrice =
    selected && selected.price_group
      ? (priceGroups.find((g) => g.group === selected.price_group)?.price ??
        null)
      : null;

  const activationSources: { label: string; active: boolean }[] = selected
    ? (() => {
        const sm = config?.streamer_mode;
        const ds = sm?.donation_systems;
        const donateOn = !!sm?.enable_donate;
        const intervalOn = !!config?.effects_interval_enabled;
        const bitsOn = !!ds?.twitch_bits.enabled;
        const pointsOn = !!ds?.twitch_points.enabled;
        const subsOn = !!ds?.twitch_subs.enabled;
        const daOn = !!ds?.donationalerts.enabled;
        const hasRewards = !!twitchPoints?.has_rewards;
        return [
          {
            label: "Interval or Vote",
            active: intervalOn && selected.enabled,
          },
          {
            label: "Twitch Bits",
            active: bitsOn && donateOn && selected.enabled_donate,
          },
          {
            label: "Twitch Rewards",
            active:
              pointsOn && hasRewards && donateOn && selected.enabled_donate,
          },
          {
            label: "Twitch Subs (Random)",
            active: subsOn && donateOn && selected.enabled,
          },
          {
            label: "DonationAlerts",
            active: daOn && donateOn && selected.enabled_donate,
          },
        ];
      })()
    : [];

  return (
    <div className="effects-layout">
      <div className="effects-list">
        <div className="effects-search">
          <TextInput
            value={search}
            onChange={setSearch}
            placeholder="Search effects…"
          />
          <Select
            value={groupFilter}
            options={filterOptions}
            onChange={setGroupFilter}
          />
        </div>
        {filtered.map(({ effect: e, index }) => (
          <div
            key={e.id}
            className={`effect-item${selectedId === e.id ? " is-selected" : ""}`}
            onClick={() => setSelectedId(e.id)}
          >
            <span className={`effect-item-dot${e.enabled ? " is-on" : ""}`} />
            <div style={{ flex: 1, overflow: "hidden" }}>
              <div className="effect-item-name">
                {index}. {e.name}
              </div>
              <div className="effect-item-id">{e.id}</div>
            </div>
          </div>
        ))}
        {filtered.length === 0 && (
          <div className="loading" style={{ padding: 24 }}>
            No effects match.
          </div>
        )}
      </div>
      <div>
        {selected ? (
          <Section title={selected.name} description={selected.id}>
            <div className="effect-activation-list">
              {activationSources.map((s) => (
                <div key={s.label} className="effect-activation-row">
                  <span
                    className="effect-activation-dot"
                    style={{
                      background: s.active
                        ? "var(--success)"
                        : "var(--danger)",
                    }}
                  />
                  <span>{s.label}</span>
                </div>
              ))}
            </div>
            <FieldRow label="Enabled">
              <Checkbox
                checked={selected.enabled}
                onChange={(v) => patchEffect(selected.id, { enabled: v })}
              />
            </FieldRow>
            <FieldRow label="Chance (weight)">
              <NumberInput
                value={selected.chance}
                min={0}
                step={0.1}
                onChange={(v) => patchEffect(selected.id, { chance: v })}
              />
            </FieldRow>
            <FieldRow label="Has duration">
              <Checkbox
                checked={selected.withDuration}
                onChange={() => {
                  /* read-only */
                }}
                disabled
              />
            </FieldRow>
            {selected.withDuration && (
              <FieldRow label="Duration (seconds)">
                <NumberInput
                  value={selected.duration ?? 0}
                  min={0}
                  onChange={(v) => patchEffect(selected.id, { duration: v })}
                />
              </FieldRow>
            )}
            <FieldRow label="Available for donations">
              <Checkbox
                checked={selected.enabled_donate}
                onChange={(v) =>
                  patchEffect(selected.id, { enabled_donate: v })
                }
              />
            </FieldRow>
            <FieldRow label="Price group">
              <Select
                value={selected.price_group}
                options={groupOptions}
                onChange={(v) => patchEffect(selected.id, { price_group: v })}
              />
            </FieldRow>
            <div className="effect-price-block">
              <span className="field-label">Price</span>
              {selectedPrice !== null
                ? (() => {
                    const lines: {
                      amount: number;
                      code: string;
                      name: string;
                    }[] = [
                      {
                        amount: selectedPrice,
                        code: effectiveCurrency,
                        name: getCurrencyName(effectiveCurrency),
                      },
                    ];
                    const bits = config?.streamer_mode.donation_systems
                      .twitch_bits;
                    if (
                      bits?.enabled &&
                      typeof bits.price_multiplier === "number" &&
                      bits.price_multiplier > 0
                    ) {
                      lines.push({
                        amount: Math.ceil(
                          selectedPrice * bits.price_multiplier,
                        ),
                        code: "",
                        name: "Twitch Bits",
                      });
                    }
                    const list = config?.streamer_mode.currencies.list ?? {};
                    for (const [code, rate] of Object.entries(list)) {
                      if (
                        typeof rate !== "number" ||
                        !Number.isFinite(rate) ||
                        rate <= 0
                      ) {
                        continue;
                      }
                      lines.push({
                        amount: smartRoundAmount(selectedPrice * rate, code),
                        code,
                        name: getCurrencyName(code),
                      });
                    }
                    return (
                      <table className="effect-price-table">
                        <thead>
                          <tr>
                            <th>Code</th>
                            <th>Price</th>
                            <th>Currency</th>
                          </tr>
                        </thead>
                        <tbody>
                          {lines.map((line, i) => (
                            <tr key={i}>
                              <td className="effect-price-code">{line.code}</td>
                              <td className="effect-price-value">
                                {line.amount}
                              </td>
                              <td className="effect-price-name">
                                {line.name}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    );
                  })()
                : (
                  <span className="card-row-value">—</span>
                )}
            </div>
          </Section>
        ) : (
          <div className="effect-detail-empty">
            Select an effect from the list to edit its settings.
          </div>
        )}
      </div>
    </div>
  );
}
