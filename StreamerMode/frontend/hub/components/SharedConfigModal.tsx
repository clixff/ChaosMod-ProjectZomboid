import { useState } from "react";
import { Modal } from "./Modal.tsx";
import {
  createSharedConfig,
  updateSharedConfig,
  SharedConfigError,
  type SharedConfig,
} from "../api/sharedConfigs.ts";
import {
  addOwnedConfig,
  getOrCreateEditToken,
  renameOwnedConfig,
} from "../api/editToken.ts";

interface SharedConfigModalProps {
  mode: "create" | "edit";
  existing?: SharedConfig;
  onClose: () => void;
  onSuccess: (cfg: SharedConfig) => void;
}

const NAME_REGEX = /^[a-zA-Z0-9_-]{3,40}$/;

interface ParsedJsonOk {
  ok: true;
  mod_version: string;
  rewards: boolean;
  bits: boolean;
  donationalerts: boolean;
  last_effect: number;
  data: Record<string, unknown>;
}

interface ParsedJsonErr {
  ok: false;
  error: string;
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

function parseConfigJson(text: string): ParsedJsonOk | ParsedJsonErr {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return { ok: false, error: `Invalid JSON: ${msg}` };
  }
  if (!isPlainObject(raw)) {
    return { ok: false, error: "JSON must be an object" };
  }
  if (typeof raw["mod_version"] !== "string" || raw["mod_version"].length < 1) {
    return { ok: false, error: "mod_version must be a non-empty string" };
  }
  for (const key of ["rewards", "bits", "donationalerts"] as const) {
    if (typeof raw[key] !== "boolean") {
      return { ok: false, error: `${key} must be a boolean` };
    }
  }
  if (
    typeof raw["last_effect"] !== "number" ||
    !Number.isInteger(raw["last_effect"]) ||
    raw["last_effect"] < 0
  ) {
    return { ok: false, error: "last_effect must be a non-negative integer" };
  }
  if (!isPlainObject(raw["data"])) {
    return { ok: false, error: "data must be an object" };
  }
  return {
    ok: true,
    mod_version: raw["mod_version"],
    rewards: raw["rewards"] as boolean,
    bits: raw["bits"] as boolean,
    donationalerts: raw["donationalerts"] as boolean,
    last_effect: raw["last_effect"],
    data: raw["data"] as Record<string, unknown>,
  };
}

export function SharedConfigModal({
  mode,
  existing,
  onClose,
  onSuccess,
}: SharedConfigModalProps) {
  const [name, setName] = useState<string>(existing?.name ?? "");
  const [json, setJson] = useState<string>("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const nameValid = NAME_REGEX.test(name);
  const submitLabel = mode === "create" ? "Create" : "Save";
  const title = mode === "create" ? "Create config" : "Edit config";

  async function handleSubmit() {
    setError(null);

    if (!nameValid) {
      setError("Name must be 3-40 characters: letters, digits, _ or -");
      return;
    }
    const parsed = parseConfigJson(json);
    if (!parsed.ok) {
      setError(parsed.error);
      return;
    }

    const editToken = getOrCreateEditToken();
    setBusy(true);
    try {
      if (mode === "create") {
        const cfg = await createSharedConfig({
          name,
          edit_token: editToken,
          mod_version: parsed.mod_version,
          rewards: parsed.rewards,
          bits: parsed.bits,
          donationalerts: parsed.donationalerts,
          last_effect: parsed.last_effect,
          data: parsed.data,
        });
        addOwnedConfig(cfg.name, cfg.created_at);
        onSuccess(cfg);
      } else if (existing) {
        const renamed = name !== existing.name;
        const cfg = await updateSharedConfig(existing.name, {
          edit_token: editToken,
          ...(renamed ? { new_name: name } : {}),
          mod_version: parsed.mod_version,
          rewards: parsed.rewards,
          bits: parsed.bits,
          donationalerts: parsed.donationalerts,
          last_effect: parsed.last_effect,
          data: parsed.data,
        });
        if (renamed) renameOwnedConfig(existing.name, cfg.name);
        onSuccess(cfg);
      }
    } catch (e) {
      if (e instanceof SharedConfigError) {
        if (e.status === 409) {
          setError(`Name "${name}" is already taken. Pick another.`);
        } else if (e.status === 403) {
          setError(
            "You don't own this config in this browser. Edit token mismatch.",
          );
        } else {
          setError(e.message);
        }
      } else {
        setError(e instanceof Error ? e.message : String(e));
      }
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title={title} onClose={onClose} wide>
      <ol className="hub-modal-steps">
        <li>
          {mode === "create"
            ? "Open the StreamerApp dashboard and click Export → copy the JSON."
            : "Open the StreamerApp dashboard and copy a fresh JSON payload."}
        </li>
        <li>Pick a public name (this becomes part of the share URL).</li>
        <li>Paste the JSON below and submit.</li>
      </ol>

      <label className="hub-form-field">
        <span className="hub-form-label">Public name</span>
        <input
          type="text"
          className="hub-form-input"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="nickname-131"
          maxLength={40}
          autoFocus={mode === "create"}
        />
        <span className="hub-form-hint">
          3–40 chars · letters, digits, underscore, hyphen
        </span>
      </label>

      <label className="hub-form-field">
        <span className="hub-form-label">Config JSON</span>
        <textarea
          className="hub-form-textarea"
          value={json}
          onChange={(e) => setJson(e.target.value)}
          rows={12}
          placeholder='{"mod_version":"1.1.2","rewards":true,"bits":true,...}'
          spellCheck={false}
        />
      </label>

      {error ? (
        <div className="hub-form-error" role="alert">
          {error}
        </div>
      ) : null}

      <div className="hub-modal-actions">
        <button
          type="button"
          className="hub-btn"
          onClick={onClose}
          disabled={busy}
        >
          Cancel
        </button>
        <button
          type="button"
          className="hub-btn hub-btn--primary"
          onClick={() => void handleSubmit()}
          disabled={busy || !nameValid || json.trim().length === 0}
        >
          {busy ? "Working…" : submitLabel}
        </button>
      </div>
    </Modal>
  );
}
