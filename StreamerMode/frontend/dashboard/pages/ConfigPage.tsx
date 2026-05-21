import { useEffect, useState } from "react";
import { Section, FieldRow } from "../components/Section.tsx";
import { TextInput, NumberInput } from "../components/Input.tsx";
import { Checkbox } from "../components/Checkbox.tsx";
import { Select } from "../components/Select.tsx";
import {
  getConfig,
  updateConfig,
  getLanguages,
  type ModConfig,
  type DonatePriceGroup,
} from "../api.ts";
import { formatLanguageLabel } from "../languageLabels.ts";

const PRICE_GROUP_CATEGORY_ORDER: readonly string[] = [
  "negative",
  "positive",
  "neutral",
];

function formatPriceGroupName(name: string): string {
  return name
    .split("_")
    .filter((part) => part.length > 0)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function parsePriceGroupName(name: string): {
  prefix: string;
  trailingNumber: number | null;
} {
  const match = name.match(/^(.*?)_?(\d+)$/);
  if (match && match[2] != null) {
    return {
      prefix: (match[1] ?? "").toLowerCase(),
      trailingNumber: Number.parseInt(match[2], 10),
    };
  }
  return { prefix: name.toLowerCase(), trailingNumber: null };
}

function categoryRank(prefix: string): number {
  const idx = PRICE_GROUP_CATEGORY_ORDER.indexOf(prefix);
  return idx === -1 ? PRICE_GROUP_CATEGORY_ORDER.length : idx;
}

function getSortedPriceGroupIndices(
  groups: readonly { group: string; price: number }[],
): number[] {
  return groups
    .map((g, idx) => ({ idx, ...parsePriceGroupName(g.group), name: g.group }))
    .sort((a, b) => {
      const aHas = a.trailingNumber != null;
      const bHas = b.trailingNumber != null;
      if (aHas && bHas) {
        if (a.trailingNumber !== b.trailingNumber) {
          return (a.trailingNumber ?? 0) - (b.trailingNumber ?? 0);
        }
      } else if (aHas !== bHas) {
        return aHas ? -1 : 1;
      }
      const ar = categoryRank(a.prefix);
      const br = categoryRank(b.prefix);
      if (ar !== br) return ar - br;
      if (a.prefix !== b.prefix) return a.prefix.localeCompare(b.prefix);
      return a.name.localeCompare(b.name);
    })
    .map((entry) => entry.idx);
}

interface ConfigPageProps {
  onNotify: (message: string, isError?: boolean) => void;
  scrollTarget?: string | null;
}

export function ConfigPage({ onNotify, scrollTarget }: ConfigPageProps) {
  const [config, setConfig] = useState<ModConfig | null>(null);
  const [languages, setLanguages] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [newGroupName, setNewGroupName] = useState("");
  const [newGroupPrice, setNewGroupPrice] = useState(0);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const [cfg, langs] = await Promise.all([getConfig(), getLanguages()]);
        if (!cancelled) {
          setConfig(cfg);
          setLanguages(langs);
        }
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        onNotify(`Failed to load config: ${msg}`, true);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [onNotify]);

  useEffect(() => {
    if (loading || !scrollTarget) return;
    const el = document.getElementById(scrollTarget);
    if (!el) return;
    el.scrollIntoView({ behavior: "smooth", block: "start" });
    el.classList.add("section--highlight");
    const t = setTimeout(() => el.classList.remove("section--highlight"), 1600);
    return () => clearTimeout(t);
  }, [loading, scrollTarget]);

  if (loading) return <div className="loading">Loading config…</div>;
  if (!config) return <div className="loading">Config not available.</div>;

  const save = async (patch: Record<string, unknown>) => {
    try {
      await updateConfig(patch);
      onNotify("Saved");
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onNotify(`Save failed: ${msg}`, true);
    }
  };

  const setField = <K extends keyof ModConfig>(key: K, value: ModConfig[K]) => {
    setConfig((prev) => (prev ? { ...prev, [key]: value } : prev));
    void save({ [key]: value });
  };

  const setStreamer = <K extends keyof ModConfig["streamer_mode"]>(
    key: K,
    value: ModConfig["streamer_mode"][K],
  ) => {
    setConfig((prev) =>
      prev
        ? { ...prev, streamer_mode: { ...prev.streamer_mode, [key]: value } }
        : prev,
    );
    void save({ streamer_mode: { [key]: value } });
  };

  const setUI = <K extends keyof ModConfig["ui"]>(
    key: K,
    value: ModConfig["ui"][K],
  ) => {
    setConfig((prev) =>
      prev ? { ...prev, ui: { ...prev.ui, [key]: value } } : prev,
    );
    void save({ ui: { [key]: value } });
  };

  const setPriceGroups = (groups: DonatePriceGroup[]) => {
    setConfig((prev) =>
      prev
        ? {
            ...prev,
            streamer_mode: {
              ...prev.streamer_mode,
              donate_price_groups: groups,
            },
          }
        : prev,
    );
    void save({ streamer_mode: { donate_price_groups: groups } });
  };

  const sm = config.streamer_mode;
  const ui = config.ui;

  return (
    <>
      <Section title="General" description="Core mod behavior.">
        <FieldRow
          label="Language"
          hint="Localization language used by the mod and OBS overlay."
        >
          <Select
            value={config.lang}
            options={(languages.length > 0 ? languages : [config.lang]).map(
              (code) => ({ value: code, label: formatLanguageLabel(code) }),
            )}
            onChange={(v) => setField("lang", v)}
          />
        </FieldRow>
        <FieldRow label="Effects interval enabled">
          <Checkbox
            checked={config.effects_interval_enabled}
            onChange={(v) => setField("effects_interval_enabled", v)}
          />
        </FieldRow>
        <FieldRow label="Effects interval (seconds)">
          <NumberInput
            value={config.effects_interval}
            min={1}
            onChange={(v) => setField("effects_interval", v)}
          />
        </FieldRow>
        <FieldRow
          label="Effects duration multiplier"
          hint="Multiplies every effect's duration. 1.0 = unchanged, 2.0 = double duration."
        >
          <NumberInput
            value={config.effects_duration_multiplier}
            min={0.1}
            step={0.1}
            onChange={(v) => setField("effects_duration_multiplier", v)}
          />
        </FieldRow>
        <FieldRow
          label="Recent effects block buffer"
          hint={"How many of the most recently triggered effects are blocked from being picked again.\n\nRecommended:\nFor default Chaos - 30-100\nFor 4 options vote - 90-130\nFor 5+ options vote - 150+"}
        >
          <NumberInput
            value={config.recent_effects_block_buffer}
            min={0}
            onChange={(v) => setField("recent_effects_block_buffer", v)}
          />
        </FieldRow>
        <FieldRow label="Vote start time (seconds)">
          <NumberInput
            value={config.vote_start_time}
            min={1}
            onChange={(v) => setField("vote_start_time", v)}
          />
        </FieldRow>
        <FieldRow label="UI sounds enabled">
          <Checkbox
            checked={config.ui_sounds_enabled}
            onChange={(v) => setField("ui_sounds_enabled", v)}
          />
        </FieldRow>
        <FieldRow label="Ignore effect chances">
          <Checkbox
            checked={config.ignore_effect_chances}
            onChange={(v) => setField("ignore_effect_chances", v)}
          />
        </FieldRow>
        <FieldRow label="Hide progress bar">
          <Checkbox
            checked={config.hide_progress_bar}
            onChange={(v) => setField("hide_progress_bar", v)}
          />
        </FieldRow>
        <FieldRow label="Use voting progress bar color">
          <Checkbox
            checked={config.use_voting_progress_bar_color}
            onChange={(v) => setField("use_voting_progress_bar_color", v)}
          />
        </FieldRow>
      </Section>

      <Section
        title="Streamer Mode"
        description="Settings related to streaming integrations."
      >
        <FieldRow label="Streamer mode enabled">
          <Checkbox
            checked={sm.streamer_mode_enabled}
            onChange={(v) => setStreamer("streamer_mode_enabled", v)}
          />
        </FieldRow>
        <FieldRow label="Voting enabled">
          <Checkbox
            checked={sm.voting_enabled}
            onChange={(v) => setStreamer("voting_enabled", v)}
          />
        </FieldRow>
        <FieldRow
          label="Voting mode"
          hint="0 = Most votes wins. 1 = Weighted random based on votes."
        >
          <Select
            value={String(sm.voting_mode)}
            options={[
              { value: "0", label: "Most Votes" },
              { value: "1", label: "Weighted Random" },
            ]}
            onChange={(v) => setStreamer("voting_mode", Number(v))}
          />
        </FieldRow>
        <FieldRow
          label="Number of voting options"
          hint="How many choices viewers can vote for (4-8)."
        >
          <Select
            value={String(sm.voting_options_number)}
            options={[
              { value: "4", label: "4" },
              { value: "5", label: "5" },
              { value: "6", label: "6" },
              { value: "7", label: "7" },
              { value: "8", label: "8" },
            ]}
            onChange={(v) => setStreamer("voting_options_number", Number(v))}
          />
        </FieldRow>
        <FieldRow label="Bind to localhost only">
          <Checkbox
            checked={sm.use_localhost_ip}
            onChange={(v) => setStreamer("use_localhost_ip", v)}
          />
        </FieldRow>
        <FieldRow label="Allow !vote command">
          <Checkbox
            checked={sm.allow_vote_command}
            onChange={(v) => setStreamer("allow_vote_command", v)}
          />
        </FieldRow>
        <FieldRow label="Hide vote counts in OBS">
          <Checkbox
            checked={sm.hide_votes}
            onChange={(v) => setStreamer("hide_votes", v)}
          />
        </FieldRow>
        <FieldRow label="Use zombie nicknames">
          <Checkbox
            checked={sm.use_zombie_nicknames}
            onChange={(v) => setStreamer("use_zombie_nicknames", v)}
          />
        </FieldRow>
        <FieldRow label="Use animal nicknames">
          <Checkbox
            checked={sm.use_animals_nicknames}
            onChange={(v) => setStreamer("use_animals_nicknames", v)}
          />
        </FieldRow>
        <FieldRow label="Render chat messages above zombies">
          <Checkbox
            checked={sm.render_chat_messages}
            onChange={(v) => setStreamer("render_chat_messages", v)}
          />
        </FieldRow>
        <FieldRow label="Say killed zombie name">
          <Checkbox
            checked={sm.say_killed_zombie_name}
            onChange={(v) => setStreamer("say_killed_zombie_name", v)}
          />
        </FieldRow>
        <FieldRow label="Zombie nicknames buffer size">
          <NumberInput
            value={sm.zombie_nicknames_buffer}
            min={1}
            onChange={(v) => setStreamer("zombie_nicknames_buffer", v)}
          />
        </FieldRow>
        <FieldRow label="Donations enabled">
          <Checkbox
            checked={sm.enable_donate}
            onChange={(v) => setStreamer("enable_donate", v)}
          />
        </FieldRow>
      </Section>

      <Section
        id="price-groups"
        title="Donation Price Groups"
        description="Each group sets the minimum donation amount required for effects assigned to it. Effects pick a group on the Effects page."
      >
        {sm.donate_price_groups.length > 0 && (
          <table className="price-groups-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Price</th>
                <th aria-label="Actions" />
              </tr>
            </thead>
            <tbody>
              {getSortedPriceGroupIndices(sm.donate_price_groups).map((idx) => {
                const g = sm.donate_price_groups[idx];
                if (!g) return null;
                return (
                  <tr key={`${g.group}-${idx}`}>
                    <td>{formatPriceGroupName(g.group)}</td>
                    <td>
                      <NumberInput
                        value={g.price}
                        min={0}
                        step={0.5}
                        onChange={(v) => {
                          const next = sm.donate_price_groups.map((x, i) =>
                            i === idx ? { ...x, price: v } : x,
                          );
                          setPriceGroups(next);
                        }}
                      />
                    </td>
                    <td>
                      <button
                        className="btn btn--danger"
                        title={`Remove price group "${g.group}"`}
                        onClick={() => {
                          if (
                            !confirm(
                              `Remove price group "${g.group}"? Effects using it will fall back to no group.`,
                            )
                          ) {
                            return;
                          }
                          setPriceGroups(
                            sm.donate_price_groups.filter((_, i) => i !== idx),
                          );
                        }}
                      >
                        Remove
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
        {sm.donate_price_groups.length === 0 && (
          <span className="field-hint">No price groups configured.</span>
        )}
        <FieldRow label="Add new price group">
          <div className="inline-controls">
            <TextInput
              size="mid"
              value={newGroupName}
              onChange={setNewGroupName}
              placeholder="group name"
            />
            <NumberInput
              value={newGroupPrice}
              min={0}
              step={0.5}
              onChange={setNewGroupPrice}
            />
            <button
              className="btn btn--primary"
              disabled={
                newGroupName.trim().length === 0 ||
                sm.donate_price_groups.some(
                  (g) => g.group === newGroupName.trim(),
                )
              }
              onClick={() => {
                const name = newGroupName.trim();
                if (!name) return;
                if (sm.donate_price_groups.some((g) => g.group === name)) {
                  onNotify(`Price group "${name}" already exists.`, true);
                  return;
                }
                setPriceGroups([
                  ...sm.donate_price_groups,
                  { group: name, price: newGroupPrice },
                ]);
                setNewGroupName("");
                setNewGroupPrice(0);
              }}
            >
              Add
            </button>
          </div>
        </FieldRow>
      </Section>

      <Section title="UI" description="HUD colors, sizes, and positions.">
        <FieldRow label="Progress bar color (hex, no #)">
          <TextInput
            size="small"
            value={ui.progress_bar_color}
            onChange={(v) => setUI("progress_bar_color", v)}
          />
        </FieldRow>
        <FieldRow label="Progress bar opacity">
          <NumberInput
            value={ui.progress_bar_opacity}
            min={0}
            max={1}
            step={0.05}
            onChange={(v) => setUI("progress_bar_opacity", v)}
          />
        </FieldRow>
        <FieldRow label="Progress bar text color (hex, no #)">
          <TextInput
            size="small"
            value={ui.progress_bar_text_color}
            onChange={(v) => setUI("progress_bar_text_color", v)}
          />
        </FieldRow>
        <FieldRow label="Progress bar height (px)">
          <NumberInput
            value={ui.progress_bar_height}
            min={1}
            onChange={(v) => setUI("progress_bar_height", v)}
          />
        </FieldRow>
        <FieldRow label="Effect progress color (hex, no #)">
          <TextInput
            size="small"
            value={ui.effect_progress_color}
            onChange={(v) => setUI("effect_progress_color", v)}
          />
        </FieldRow>
        <FieldRow label="Effect progress text color (hex, no #)">
          <TextInput
            size="small"
            value={ui.effect_progress_text_color}
            onChange={(v) => setUI("effect_progress_text_color", v)}
          />
        </FieldRow>
        <FieldRow label="Effects default X">
          <NumberInput
            value={ui.effects_default_x}
            onChange={(v) => setUI("effects_default_x", v)}
          />
        </FieldRow>
        <FieldRow label="Effects default Y">
          <NumberInput
            value={ui.effects_default_y}
            onChange={(v) => setUI("effects_default_y", v)}
          />
        </FieldRow>
        <FieldRow label="Effects stack bottom-to-top">
          <Checkbox
            checked={ui.effects_from_bottom_to_top}
            onChange={(v) => setUI("effects_from_bottom_to_top", v)}
          />
        </FieldRow>
        <FieldRow label="Progress bar voting color (hex, no #)">
          <TextInput
            size="small"
            value={ui.progress_bar_voting_color}
            onChange={(v) => setUI("progress_bar_voting_color", v)}
          />
        </FieldRow>
        <FieldRow label="Vote background color (hex, no #)">
          <TextInput
            size="small"
            value={ui.vote_background_color}
            onChange={(v) => setUI("vote_background_color", v)}
          />
        </FieldRow>
      </Section>
    </>
  );
}
