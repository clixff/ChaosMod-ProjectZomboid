import { useMemo, useState } from "react";
import type { ChangeEvent, ReactNode } from "react";
import { Plus, Trash2, X, AlertTriangle } from "lucide-react";
import { Modal } from "./Modal.tsx";
import { Checkbox } from "./Checkbox.tsx";
import { TextInput } from "./Input.tsx";
import {
  createTwitchPointsRewards,
  deleteTwitchPointsRewards,
  setTwitchPointsEnabled,
  type TwitchPointsReward,
  type TwitchPointsStatus,
} from "../api.ts";

interface RowState {
  name: string;
  cost: number;
  groups: string[];
}

interface TwitchPointsSettingsModalProps {
  status: TwitchPointsStatus;
  onClose: () => void;
  onNotify: (message: string, isError?: boolean) => void;
  onRefresh: () => Promise<void>;
}

const DEFAULT_REWARDS: RowState[] = [
  {
    name: "Tier 1 - Chaos Mod Zomboid",
    cost: 35000,
    groups: ["positive_1", "neutral_1", "negative_1"],
  },
  {
    name: "Tier 2 - Chaos Mod Zomboid",
    cost: 50000,
    groups: ["positive_2", "neutral_2", "negative_2"],
  },
  {
    name: "Tier 3 - Chaos Mod Zomboid",
    cost: 70000,
    groups: ["positive_3", "neutral_3", "negative_3"],
  },
  {
    name: "Tier 4 - Chaos Mod Zomboid",
    cost: 100000,
    groups: ["positive_4", "neutral_4", "negative_4"],
  },
  {
    name: "Tier 5 - Chaos Mod Zomboid",
    cost: 150000,
    groups: ["positive_5", "neutral_5", "negative_5"],
  },
  {
    name: "Tier 6 - Chaos Mod Zomboid",
    cost: 200000,
    groups: ["positive_6", "neutral_6", "negative_6"],
  },
];

function formatThousands(value: number): string {
  if (!Number.isFinite(value)) return "";
  return Math.floor(value)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

function parseDigits(input: string): number {
  const digits = input.replace(/\D/g, "");
  if (!digits) return 0;
  const n = Number.parseInt(digits, 10);
  return Number.isFinite(n) ? n : 0;
}

interface FormattedNumberInputProps {
  value: number;
  onChange: (value: number) => void;
  size?: "small" | "mid" | "full";
}

function FormattedNumberInput({
  value,
  onChange,
  size = "mid",
}: FormattedNumberInputProps) {
  const [focused, setFocused] = useState(false);
  const [draft, setDraft] = useState<string>("");
  const cls =
    size === "small"
      ? "input input--small"
      : size === "mid"
        ? "input input--mid"
        : "input";
  const display = focused ? draft : formatThousands(value);
  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    setDraft(raw);
    onChange(parseDigits(raw));
  };
  return (
    <input
      className={cls}
      type="text"
      inputMode="numeric"
      value={display}
      onFocus={() => {
        setDraft(String(value));
        setFocused(true);
      }}
      onBlur={() => setFocused(false)}
      onChange={handleChange}
    />
  );
}

function formatGroupLabel(group: string): string {
  const parts = group.split("_");
  if (parts.length === 2 && parts[0] && parts[1]) {
    const head = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
    return `${head} ${parts[1]}`;
  }
  return group;
}

function toRowState(rewards: TwitchPointsReward[]): RowState[] {
  return rewards.map((r) => ({
    name: r.name,
    cost: r.cost,
    groups: [...r.groups],
  }));
}

function rowsEqual(a: RowState[], b: RowState[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    const x = a[i];
    const y = b[i];
    if (!x || !y) return false;
    if (x.name !== y.name || x.cost !== y.cost) return false;
    if (x.groups.length !== y.groups.length) return false;
    for (let j = 0; j < x.groups.length; j++) {
      if (x.groups[j] !== y.groups[j]) return false;
    }
  }
  return true;
}

export function TwitchPointsSettingsModal({
  status,
  onClose,
  onNotify,
  onRefresh,
}: TwitchPointsSettingsModalProps) {
  const initialRows = useMemo(
    () =>
      status.rewards.length > 0
        ? toRowState(status.rewards)
        : DEFAULT_REWARDS.map((r) => ({ ...r, groups: [...r.groups] })),
    [status.rewards],
  );

  const [enabled, setEnabled] = useState(status.enabled);
  const [rows, setRows] = useState<RowState[]>(initialRows);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const availableGroups = status.available_groups;
  const hasRewards = status.has_rewards;

  const validation = useMemo(() => {
    const errors: { row: number; message: string }[] = [];
    const seenNames = new Map<string, number>();
    rows.forEach((row, idx) => {
      const name = row.name.trim();
      if (!name) {
        errors.push({ row: idx, message: "Name is required" });
      } else {
        const prior = seenNames.get(name);
        if (prior !== undefined) {
          errors.push({ row: idx, message: "Name must be unique" });
          if (
            !errors.some((e) => e.row === prior && e.message.includes("unique"))
          ) {
            errors.push({ row: prior, message: "Name must be unique" });
          }
        }
        seenNames.set(name, idx);
      }
      if (!Number.isInteger(row.cost) || row.cost < 1) {
        errors.push({ row: idx, message: "Cost must be a whole number ≥ 1" });
      }
      if (row.groups.length === 0) {
        errors.push({ row: idx, message: "Add at least one price group" });
      }
    });
    return errors;
  }, [rows]);

  const errorByRow = useMemo(() => {
    const map = new Map<number, string[]>();
    for (const e of validation) {
      const list = map.get(e.row) ?? [];
      if (!list.includes(e.message)) list.push(e.message);
      map.set(e.row, list);
    }
    return map;
  }, [validation]);

  const isValid = validation.length === 0 && rows.length > 0;
  const diverged = hasRewards && !rowsEqual(rows, toRowState(status.rewards));

  const updateRow = (idx: number, patch: Partial<RowState>) => {
    setRows((prev) => prev.map((r, i) => (i === idx ? { ...r, ...patch } : r)));
  };

  const addGroup = (idx: number, group: string) => {
    setRows((prev) =>
      prev.map((r, i) =>
        i === idx ? { ...r, groups: [...r.groups, group] } : r,
      ),
    );
  };

  const removeGroup = (idx: number, group: string) => {
    setRows((prev) =>
      prev.map((r, i) =>
        i === idx ? { ...r, groups: r.groups.filter((g) => g !== group) } : r,
      ),
    );
  };

  const removeRow = (idx: number) => {
    setRows((prev) => prev.filter((_, i) => i !== idx));
  };

  const addRow = () => {
    setRows((prev) => [...prev, { name: "", cost: 1000, groups: [] }]);
  };

  const onEnabledChange = (next: boolean) => {
    setEnabled(next);
    void (async () => {
      try {
        await setTwitchPointsEnabled(next);
        await onRefresh();
        if (!next) {
          onNotify("Twitch Points disabled. Rewards removed from Twitch.");
        } else {
          onNotify("Twitch Points enabled.");
        }
      } catch (e) {
        setEnabled(!next);
        const msg = e instanceof Error ? e.message : String(e);
        onNotify(`Failed to update setting: ${msg}`, true);
      }
    })();
  };

  const onCreate = () => {
    if (!isValid) return;
    setBusy(true);
    setError(null);
    void (async () => {
      try {
        await createTwitchPointsRewards(
          rows.map((r) => ({
            name: r.name.trim(),
            cost: Math.floor(r.cost),
            groups: r.groups,
          })),
        );
        await onRefresh();
        onNotify(`Created ${rows.length} reward(s) on Twitch.`);
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        setError(msg);
      } finally {
        setBusy(false);
      }
    })();
  };

  const onDelete = () => {
    setBusy(true);
    setError(null);
    void (async () => {
      try {
        await deleteTwitchPointsRewards();
        await onRefresh();
        onNotify("Deleted all Twitch Points rewards.");
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        setError(msg);
      } finally {
        setBusy(false);
      }
    })();
  };

  return (
    <Modal title="Twitch Points Settings" onClose={onClose} wide>
      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <div className="form-field">
          <Checkbox
            checked={enabled}
            label="Enable Twitch Channel Points rewards"
            onChange={onEnabledChange}
          />
        </div>

        {!status.twitch_connected && (
          <RedBanner>
            Not logged in to Twitch. Log in from the Twitch card first.
          </RedBanner>
        )}

        {status.twitch_connected && !status.has_scope && (
          <RedBanner>
            No channel points access granted. Log in with Twitch again.
          </RedBanner>
        )}

        {error && (
          <RedBanner>
            <b>Twitch error:</b> {error}
          </RedBanner>
        )}

        {diverged && (
          <div className="banner banner--warn" style={bannerStyle("#a76b00")}>
            <AlertTriangle size={14} aria-hidden="true" />
            <span>
              Prices, names or groups changed. Click <b>Delete Reward</b> then{" "}
              <b>Create Reward</b> to apply changes on Twitch.
            </span>
          </div>
        )}

        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {rows.map((row, idx) => {
            const rowErrors = errorByRow.get(idx) ?? [];
            const remaining = availableGroups.filter(
              (g) => !row.groups.includes(g),
            );
            return (
              <div
                key={idx}
                style={{
                  border: "1px solid #2a2a2a",
                  borderRadius: 6,
                  padding: 12,
                  display: "flex",
                  flexDirection: "column",
                  gap: 8,
                }}
              >
                <div
                  style={{
                    display: "flex",
                    gap: 8,
                    alignItems: "center",
                  }}
                >
                  <span style={{ opacity: 0.6, minWidth: 22 }}>{idx + 1}.</span>
                  <TextInput
                    value={row.name}
                    onChange={(v) => updateRow(idx, { name: v })}
                    placeholder="Reward name"
                  />
                  <FormattedNumberInput
                    value={row.cost}
                    onChange={(v) => updateRow(idx, { cost: v })}
                  />
                  <button
                    type="button"
                    className="btn"
                    aria-label="Delete row"
                    title="Delete row"
                    onClick={() => removeRow(idx)}
                  >
                    <X size={14} aria-hidden="true" />
                  </button>
                </div>
                <div
                  style={{
                    display: "flex",
                    flexWrap: "wrap",
                    gap: 6,
                    alignItems: "center",
                  }}
                >
                  <span style={{ opacity: 0.7, fontSize: 12, marginRight: 6 }}>
                    Price groups:
                  </span>
                  {row.groups.map((g) => (
                    <span
                      key={g}
                      style={{
                        display: "inline-flex",
                        alignItems: "center",
                        gap: 4,
                        background: "#222",
                        border: "1px solid #333",
                        borderRadius: 4,
                        padding: "2px 6px",
                        fontSize: 12,
                      }}
                    >
                      {formatGroupLabel(g)}
                      <button
                        type="button"
                        className="icon-btn"
                        onClick={() => removeGroup(idx, g)}
                        aria-label={`Remove ${g}`}
                        title="Remove"
                      >
                        <X size={10} aria-hidden="true" />
                      </button>
                    </span>
                  ))}
                  <select
                    className="input input--small"
                    value=""
                    onChange={(e) => {
                      const v = e.target.value;
                      if (v) addGroup(idx, v);
                    }}
                    disabled={remaining.length === 0}
                  >
                    <option value="">+ Add group…</option>
                    {remaining.map((g) => (
                      <option key={g} value={g}>
                        {formatGroupLabel(g)}
                      </option>
                    ))}
                  </select>
                </div>
                {rowErrors.length > 0 && (
                  <div
                    style={{
                      color: "#ff6b6b",
                      fontSize: 12,
                      display: "flex",
                      flexDirection: "column",
                      gap: 2,
                    }}
                  >
                    {rowErrors.map((m) => (
                      <span key={m}>• {m}</span>
                    ))}
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <div>
          <button type="button" className="btn" onClick={addRow}>
            <Plus size={14} aria-hidden="true" />
            Add Reward
          </button>
        </div>

        <div
          style={{
            display: "flex",
            gap: 8,
            justifyContent: "flex-end",
            borderTop: "1px solid #222",
            paddingTop: 12,
          }}
        >
          <button
            type="button"
            className="btn"
            disabled={busy || !hasRewards}
            onClick={onDelete}
          >
            <Trash2 size={14} aria-hidden="true" />
            Delete Reward
          </button>
          <button
            type="button"
            className="btn btn--primary"
            disabled={
              busy ||
              !isValid ||
              hasRewards ||
              !status.twitch_connected ||
              !status.has_scope
            }
            onClick={onCreate}
          >
            <Plus size={14} aria-hidden="true" />
            Create Reward
          </button>
        </div>
      </div>
    </Modal>
  );
}

function bannerStyle(color: string) {
  return {
    display: "flex",
    gap: 8,
    alignItems: "center",
    border: `1px solid ${color}`,
    background: `${color}22`,
    color,
    padding: "8px 10px",
    borderRadius: 4,
    fontSize: 13,
  } as const;
}

function RedBanner({ children }: { children: ReactNode }) {
  return (
    <div className="banner banner--err" style={bannerStyle("#ff5b5b")}>
      <AlertTriangle size={14} aria-hidden="true" />
      <span>{children}</span>
    </div>
  );
}
