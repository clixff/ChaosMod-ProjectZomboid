import { useState } from "react";
import { Modal } from "./Modal.tsx";
import { NumberInput } from "./Input.tsx";
import { Checkbox } from "./Checkbox.tsx";
import type { DonationSystemTwitchSubs } from "../api.ts";

interface TwitchSubsSettingsModalProps {
  value: DonationSystemTwitchSubs;
  onChange: (next: DonationSystemTwitchSubs) => void;
  onClose: () => void;
}

export function TwitchSubsSettingsModal({
  value,
  onChange,
  onClose,
}: TwitchSubsSettingsModalProps) {
  const [draft, setDraft] = useState<DonationSystemTwitchSubs>(value);

  const commit = (patch: Partial<DonationSystemTwitchSubs>) => {
    const next = { ...draft, ...patch };
    setDraft(next);
    onChange(next);
  };

  return (
    <Modal title="Twitch Subs Options" onClose={onClose}>
      <p style={{ marginTop: 0, marginBottom: 12 }}>
        Every {Math.max(1, Math.floor(draft.threshold))} sub will activate a
        random effect.
      </p>

      <div className="form-grid">
        <label className="form-field">
          <span className="form-label">Subs per random effect</span>
          <NumberInput
            value={draft.threshold}
            min={1}
            step={1}
            onChange={(v) => commit({ threshold: Math.max(1, Math.floor(v)) })}
          />
        </label>
      </div>

      <div
        style={{
          marginTop: 14,
          display: "flex",
          flexDirection: "column",
          gap: 10,
        }}
      >
        <Checkbox
          checked={draft.allow_gift_subs}
          label="Allow gift subs"
          onChange={(v) => commit({ allow_gift_subs: v })}
        />
        <Checkbox
          checked={draft.allow_resubscriptions}
          label="Allow resubscriptions"
          onChange={(v) => commit({ allow_resubscriptions: v })}
        />
        <div>
          <Checkbox
            checked={draft.sub_tier_multipliers}
            label="Sub tier multipliers"
            onChange={(v) => commit({ sub_tier_multipliers: v })}
          />
          <div
            className="field-hint"
            style={{ marginTop: 4, marginLeft: 24, fontSize: 12 }}
          >
            When enabled, Tier 2 subs count as 2 and Tier 3 subs count as 3
            toward the threshold. When disabled, every sub counts as 1.
          </div>
        </div>
        <Checkbox
          checked={draft.show_in_obs}
          label="Show in OBS"
          onChange={(v) => commit({ show_in_obs: v })}
        />
      </div>

      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          marginTop: 18,
        }}
      >
        <button className="btn" onClick={onClose}>
          Close
        </button>
      </div>
    </Modal>
  );
}
