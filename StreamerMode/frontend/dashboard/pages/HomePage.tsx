import { useCallback, useEffect, useMemo, useState } from "react";
import {
  Check,
  CircleQuestionMark,
  Copy,
  DollarSign,
  FileDown,
  Info,
  Link as LinkIcon,
  LogIn,
  LogOut,
  Pencil,
  Power,
  PowerOff,
  Settings,
  Star,
  TriangleAlert,
} from "lucide-react";
import twitchLogo from "../assets/twitch_logo.webp";
import donationAlertsLogo from "../assets/donationalerts_logo.webp";
import obsLogo from "../assets/obs_logo.webp";
import googleSheetsLogo from "../assets/google_sheets_logo.webp";
import steamLogo from "../assets/steam_logo.webp";

const STEAM_WORKSHOP_URL =
  "https://steamcommunity.com/sharedfiles/filedetails/?id=3717082142";
import { Modal } from "../components/Modal.tsx";
import { Checkbox } from "../components/Checkbox.tsx";
import { Select } from "../components/Select.tsx";
import { TextInput, NumberInput } from "../components/Input.tsx";
import { Section, FieldRow } from "../components/Section.tsx";
import { formatLanguageLabel } from "../languageLabels.ts";
import {
  getHomeStatus,
  twitchLogin,
  twitchLogout,
  donationAlertsLogout,
  donationAlertsSetup,
  downloadEffectsUrl,
  updateConfig,
  getConfig,
  getLanguages,
  type HomeStatus,
  type ModConfig,
} from "../api.ts";

interface HomePageProps {
  onNotify: (message: string, isError?: boolean) => void;
  onNavigate: (page: "home" | "config" | "effects", target?: string) => void;
}

interface BadgeProps {
  on: boolean;
  labelOn?: string;
  labelOff?: string;
}

function StatusBadge({
  on,
  labelOn = "Connected",
  labelOff = "Disconnected",
}: BadgeProps) {
  return (
    <span className={`badge ${on ? "badge--ok" : "badge--off"}`}>
      <span className="badge-dot" />
      {on ? labelOn : labelOff}
    </span>
  );
}

interface StatusRowProps {
  label: string;
  on: boolean;
  labelOn: string;
  labelOff: string;
}

function StatusRow({ label, on, labelOn, labelOff }: StatusRowProps) {
  return (
    <div className="status-row">
      <span className="status-row-label">{label}</span>
      <StatusBadge on={on} labelOn={labelOn} labelOff={labelOff} />
    </div>
  );
}

export function HomePage({ onNotify, onNavigate }: HomePageProps) {
  const [status, setStatus] = useState<HomeStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [obsModal, setObsModal] = useState(false);
  const [exportModal, setExportModal] = useState(false);
  const [exportDoneKind, setExportDoneKind] = useState<"csv" | "xlsx" | null>(
    null,
  );
  const [exportType, setExportType] = useState("xlsx");
  const [busy, setBusy] = useState(false);
  const [daModal, setDaModal] = useState(false);
  const [daAppId, setDaAppId] = useState("");
  const [daSecret, setDaSecret] = useState("");
  const [daCurrency, setDaCurrency] = useState("RUB");
  const [config, setConfig] = useState<ModConfig | null>(null);
  const [languages, setLanguages] = useState<string[]>([]);
  const [bitsOptionsModal, setBitsOptionsModal] = useState(false);

  const refresh = useCallback(async () => {
    try {
      const s = await getHomeStatus();
      setStatus(s);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onNotify(`Failed to load status: ${msg}`, true);
    }
  }, [onNotify]);

  useEffect(() => {
    void (async () => {
      await refresh();
      setLoading(false);
    })();
    const t = setInterval(() => {
      void refresh();
    }, 3000);
    return () => clearInterval(t);
  }, [refresh]);

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
        onNotify(`Failed to load quick settings: ${msg}`, true);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [onNotify]);

  const saveConfigPatch = async (patch: Record<string, unknown>) => {
    try {
      await updateConfig(patch);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onNotify(`Save failed: ${msg}`, true);
    }
  };

  const setConfigField = <K extends keyof ModConfig>(
    key: K,
    value: ModConfig[K],
  ) => {
    setConfig((prev) => (prev ? { ...prev, [key]: value } : prev));
    void saveConfigPatch({ [key]: value });
  };

  const setStreamerField = <K extends keyof ModConfig["streamer_mode"]>(
    key: K,
    value: ModConfig["streamer_mode"][K],
  ) => {
    setConfig((prev) =>
      prev
        ? { ...prev, streamer_mode: { ...prev.streamer_mode, [key]: value } }
        : prev,
    );
    void saveConfigPatch({ streamer_mode: { [key]: value } });
  };

  const wrap = async (fn: () => Promise<void>, successMessage?: string) => {
    setBusy(true);
    try {
      await fn();
      if (successMessage) onNotify(successMessage);
      await refresh();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onNotify(msg, true);
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <div className="loading">Loading…</div>;
  if (!status) return <div className="loading">Status unavailable.</div>;

  const obsUrl = status.obs.use_localhost_ip
    ? status.obs.local_url
    : (status.obs.lan_url ?? status.obs.local_url);

  return (
    <>
      {status.version.update_available && status.version.latest && (
        <div className="cards cards--top">
          <div className="card">
            <div className="card-head">
              <h3 className="card-title">
                <span className="card-title-icon">
                  <TriangleAlert size={18} color="#f5b301" aria-hidden="true" />
                </span>
                New Update Available
              </h3>
            </div>
            <div className="card-row">
              <span className="card-row-value">
                Update {status.version.latest} is available
              </span>
            </div>
            <div className="card-actions">
              <a
                className="btn btn--primary"
                href={status.version.releases_url}
                target="_blank"
                rel="noreferrer"
              >
                <LinkIcon size={14} aria-hidden="true" />
                Download
              </a>
            </div>
          </div>
        </div>
      )}
      <div className="top-row">
        {config && (
          <Section
            title="Quick Settings"
            icon={<Settings size={16} color="#ffffff" aria-hidden="true" />}
          >
            <div className="quick-grid quick-grid--single">
              <FieldRow label="Language">
                <Select
                  value={config.lang}
                  options={(languages.length > 0
                    ? languages
                    : [config.lang]
                  ).map((code) => ({
                    value: code,
                    label: formatLanguageLabel(code),
                  }))}
                  onChange={(v) => setConfigField("lang", v)}
                />
              </FieldRow>
              <FieldRow label="Effects interval enabled">
                <Checkbox
                  checked={config.effects_interval_enabled}
                  onChange={(v) =>
                    setConfigField("effects_interval_enabled", v)
                  }
                />
              </FieldRow>
              <FieldRow label="Effects interval (seconds)">
                <NumberInput
                  value={config.effects_interval}
                  min={1}
                  onChange={(v) => setConfigField("effects_interval", v)}
                />
              </FieldRow>
              <FieldRow
                label="Vote start time (seconds)"
                hint={`Users have ${Math.max(0, config.effects_interval - config.vote_start_time)} seconds to vote`}
              >
                <NumberInput
                  value={config.vote_start_time}
                  min={1}
                  onChange={(v) => setConfigField("vote_start_time", v)}
                />
              </FieldRow>
              <FieldRow label="Voting enabled">
                <Checkbox
                  checked={config.streamer_mode.voting_enabled}
                  onChange={(v) => setStreamerField("voting_enabled", v)}
                />
              </FieldRow>
              <FieldRow label="Donations enabled">
                <Checkbox
                  checked={config.streamer_mode.enable_donate}
                  onChange={(v) => setStreamerField("enable_donate", v)}
                />
              </FieldRow>
            </div>
          </Section>
        )}
        <Section
          title="Status"
          icon={<Info size={16} color="#ffffff" aria-hidden="true" />}
        >
          <div className="status-list">
            <StatusRow
              label="Mod Status"
              on={status.mod.enabled}
              labelOn="Enabled"
              labelOff="Disabled"
            />
            <StatusRow
              label="Voting Status"
              on={status.voting.active}
              labelOn="Started"
              labelOff="Not Started"
            />
            <StatusRow
              label="Twitch Chat"
              on={status.twitch_chat.connected}
              labelOn="Connected"
              labelOff="Not connected"
            />
          </div>
        </Section>
      </div>
      <div className="cards">
        <div className="card">
          <div className="card-head">
            <h3 className="card-title">
              <img src={twitchLogo} alt="" className="card-title-logo" />
              Twitch
            </h3>
            <StatusBadge on={status.twitch.connected} />
          </div>
          <div className="card-row">
            <span className="card-row-label">Account</span>
            <span className="card-row-value">{status.twitch.name ?? "—"}</span>
          </div>
          <div className="card-actions">
            {status.twitch.connected ? (
              <button
                className="btn"
                disabled={busy}
                onClick={() =>
                  void wrap(() => twitchLogout(), "Logged out from Twitch.")
                }
              >
                <LogOut size={14} aria-hidden="true" />
                Logout
              </button>
            ) : (
              <button
                className="btn btn--primary"
                disabled={busy || !status.twitch.configured}
                onClick={() =>
                  void wrap(
                    () => twitchLogin(),
                    "Login URL opened in your browser.",
                  )
                }
              >
                <LogIn size={14} aria-hidden="true" />
                Login
              </button>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <h3 className="card-title">
              <span className="card-title-icon">
                <DollarSign size={18} aria-hidden="true" />
              </span>
              Donation Services
            </h3>
          </div>
          <div className="card-row-label" style={{ fontSize: 12 }}>
            Supported services
          </div>
          <div className="provider-row">
            <div className="provider-row-main">
              <span className="provider-row-name">
                <img
                  src={twitchLogo}
                  alt=""
                  className="provider-row-logo"
                />
                Twitch Bits
              </span>
              {(() => {
                const twitchAuthorized =
                  status.twitch.configured && status.twitch.name !== null;
                const bitsEnabled =
                  config?.streamer_mode.donation_systems.twitch_bits.enabled ??
                  false;
                if (!twitchAuthorized) {
                  return (
                    <span className="badge badge--off">
                      <span className="badge-dot" />
                      Not Authorized
                    </span>
                  );
                }
                return <StatusBadge on={bitsEnabled} labelOn="Enabled" labelOff="Disabled" />;
              })()}
            </div>
            {config && (
              <div className="provider-row-sub">
                <span className="card-row-label">1.0 effect cost</span>
                <span className="card-row-value">
                  {Math.ceil(
                    1.0 *
                      config.streamer_mode.donation_systems.twitch_bits
                        .price_multiplier,
                  )}{" "}
                  bits
                </span>
              </div>
            )}
            {(() => {
              const twitchAuthorized =
                status.twitch.configured && status.twitch.name !== null;
              if (!twitchAuthorized) return null;
              const bitsEnabled =
                config?.streamer_mode.donation_systems.twitch_bits.enabled ??
                false;
              return (
                <div className="card-actions">
                  {bitsEnabled ? (
                    <button
                      className="btn"
                      disabled={busy}
                      onClick={() =>
                        void wrap(async () => {
                          await updateConfig({
                            streamer_mode: {
                              donation_systems: {
                                twitch_bits: { enabled: false },
                              },
                            },
                          });
                          setConfig((prev) =>
                            prev
                              ? {
                                  ...prev,
                                  streamer_mode: {
                                    ...prev.streamer_mode,
                                    donation_systems: {
                                      ...prev.streamer_mode.donation_systems,
                                      twitch_bits: {
                                        ...prev.streamer_mode.donation_systems
                                          .twitch_bits,
                                        enabled: false,
                                      },
                                    },
                                  },
                                }
                              : prev,
                          );
                          onNotify("Twitch Bits disabled.");
                        })
                      }
                    >
                      <PowerOff size={14} aria-hidden="true" />
                      Disable
                    </button>
                  ) : (
                    <button
                      className="btn btn--primary"
                      disabled={busy}
                      onClick={() =>
                        void wrap(async () => {
                          await updateConfig({
                            streamer_mode: {
                              enable_donate: true,
                              donation_systems: {
                                twitch_bits: { enabled: true },
                              },
                            },
                          });
                          setConfig((prev) =>
                            prev
                              ? {
                                  ...prev,
                                  streamer_mode: {
                                    ...prev.streamer_mode,
                                    enable_donate: true,
                                    donation_systems: {
                                      ...prev.streamer_mode.donation_systems,
                                      twitch_bits: {
                                        ...prev.streamer_mode.donation_systems
                                          .twitch_bits,
                                        enabled: true,
                                      },
                                    },
                                  },
                                }
                              : prev,
                          );
                          onNotify("Twitch Bits enabled.");
                        })
                      }
                    >
                      <Power size={14} aria-hidden="true" />
                      Enable
                    </button>
                  )}
                  <button
                    className="btn"
                    disabled={busy}
                    onClick={() => setBitsOptionsModal(true)}
                  >
                    <Settings size={14} aria-hidden="true" />
                    Options
                  </button>
                </div>
              );
            })()}
          </div>
          <div className="provider-row">
            <div className="provider-row-main">
              <span className="provider-row-name">
                <img
                  src={donationAlertsLogo}
                  alt=""
                  className="provider-row-logo"
                />
                DonationAlerts
              </span>
              <StatusBadge on={status.donationalerts.connected} />
            </div>
            <div className="provider-row-sub">
              <span className="card-row-label">Account</span>
              <span className="card-row-value">
                {status.donationalerts.name ?? "—"}
              </span>
            </div>
            <div className="card-actions">
              {status.donationalerts.connected ? (
                <button
                  className="btn"
                  disabled={busy}
                  onClick={() =>
                    void wrap(
                      () => donationAlertsLogout(),
                      "Logged out from DonationAlerts.",
                    )
                  }
                >
                  <LogOut size={14} aria-hidden="true" />
                  Logout
                </button>
              ) : (
                <button
                  className="btn btn--primary"
                  disabled={busy}
                  onClick={() => {
                    setDaAppId("");
                    setDaSecret("");
                    setDaCurrency("RUB");
                    setDaModal(true);
                  }}
                >
                  <LogIn size={14} aria-hidden="true" />
                  Login
                </button>
              )}
            </div>
          </div>
          <div className="card-actions">
            <button
              className="btn"
              onClick={() => onNavigate("config", "price-groups")}
            >
              <Pencil size={14} aria-hidden="true" />
              Edit Price Groups
            </button>
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <h3 className="card-title">
              <img src={obsLogo} alt="" className="card-title-logo" />
              OBS Browser Source
            </h3>
          </div>
          <div className="card-row card-row-inline">
            <span className="card-row-label">URL</span>
            <span className="card-link card-link--with-copy">
              <span className="card-link-text">{obsUrl}</span>
              <CopyButton
                value={obsUrl}
                onCopied={() => onNotify("OBS URL copied to clipboard.")}
                onError={(msg) => onNotify(msg, true)}
              />
            </span>
          </div>
          <div className="card-row">
            <span className="card-row-label">Size</span>
            <span className="card-row-value">480 × 550 px</span>
          </div>
          <Checkbox
            checked={!status.obs.use_localhost_ip}
            label="OBS runs on a different PC (use LAN address)"
            onChange={(v) =>
              void wrap(async () => {
                await updateConfig({
                  streamer_mode: { use_localhost_ip: !v },
                });
                onNotify(
                  "Saved. Restart the StreamerApp for the new bind to take effect.",
                );
              })
            }
          />
          <div className="card-actions">
            <button className="btn" onClick={() => setObsModal(true)}>
              <CircleQuestionMark size={14} aria-hidden="true" />
              Setup instructions
            </button>
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <h3 className="card-title">
              <img src={googleSheetsLogo} alt="" className="card-title-logo" />
              Export effects to Google Sheets
            </h3>
          </div>
          <div className="card-row card-row-inline">
            <span className="card-row-label">Format</span>
            <Select
              value={exportType}
              options={[
                { value: "xlsx", label: "Excel (.xlsx)" },
                { value: "csv", label: "CSV (.csv)" },
              ]}
              onChange={setExportType}
            />
          </div>
          <div className="card-actions">
            <button
              className="btn btn--primary"
              disabled={busy}
              onClick={() => {
                const kind: "csv" | "xlsx" =
                  exportType === "csv" ? "csv" : "xlsx";
                const a = document.createElement("a");
                a.href = downloadEffectsUrl(kind);
                a.rel = "noopener";
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                setExportDoneKind(kind);
              }}
            >
              <FileDown size={14} aria-hidden="true" />
              Export
            </button>
            <button className="btn" onClick={() => setExportModal(true)}>
              <CircleQuestionMark size={14} aria-hidden="true" />
              Show instructions
            </button>
          </div>
        </div>
        <div className="card">
          <div className="card-head" style={{ marginBottom: 20 }}>
            <h3 className="card-title">
              <img src={steamLogo} alt="" className="card-title-logo" />
              Rate Mod On Steam
            </h3>
          </div>
          <div className="card-actions">
            <a
              className="btn btn--primary"
              href={STEAM_WORKSHOP_URL}
              target="_blank"
              rel="noreferrer"
            >
              <Star size={16} strokeWidth={3} aria-hidden="true" />
              Open Steam Workshop
            </a>
          </div>
        </div>
      </div>

      {obsModal && (
        <Modal
          title="OBS Setup Instructions"
          onClose={() => setObsModal(false)}
        >
          <ol>
            <li>
              In OBS Studio, open your scene and add a new <b>Browser</b>{" "}
              source.
            </li>
            <li>
              Set <b>URL</b> to <code>{obsUrl}</code>.
            </li>
            <li>
              Set <b>Width</b> to <code>480</code> and <b>Height</b> to{" "}
              <code>550</code>.
            </li>
            <li>
              Enable <b>Refresh browser when scene becomes active</b>.
            </li>
            <li>Click OK and position the source where you want it.</li>
          </ol>
          <p>
            <b>OBS on a different PC?</b> Enable the checkbox{" "}
            <i>"OBS runs on a different PC" </i>
            and use the new LAN URL shown on the OBS card.
          </p>
        </Modal>
      )}

      {exportModal && (
        <Modal
          title="Google Sheets import"
          onClose={() => setExportModal(false)}
        >
          <GoogleSheetsInstructions kind={exportType === "csv" ? "csv" : "xlsx"} />
          <div
            style={{
              display: "flex",
              justifyContent: "flex-end",
              marginTop: 16,
            }}
          >
            <a
              className="btn btn--success"
              href="https://sheets.new"
              target="_blank"
              rel="noreferrer"
            >
              <img
                src={googleSheetsLogo}
                alt=""
                style={{ width: 14, height: 14 }}
              />
              Open Google Sheets
            </a>
          </div>
        </Modal>
      )}

      {daModal && (
        <DonationAlertsLoginModal
          port={status.port}
          busy={busy}
          appId={daAppId}
          secret={daSecret}
          currency={daCurrency}
          onAppId={setDaAppId}
          onSecret={setDaSecret}
          onCurrency={setDaCurrency}
          onClose={() => setDaModal(false)}
          onSubmit={() =>
            void wrap(async () => {
              await donationAlertsSetup({
                appId: daAppId.trim(),
                clientSecret: daSecret,
                currency: daCurrency.trim().toUpperCase(),
              });
              setDaModal(false);
              onNotify(
                "DonationAlerts credentials saved. Login URL opened in your browser.",
              );
            })
          }
        />
      )}

      {bitsOptionsModal && config && (
        <TwitchBitsOptionsModal
          multiplier={
            config.streamer_mode.donation_systems.twitch_bits.price_multiplier
          }
          priceGroups={config.streamer_mode.donate_price_groups}
          onChangeMultiplier={(v) => {
            setConfig((prev) =>
              prev
                ? {
                    ...prev,
                    streamer_mode: {
                      ...prev.streamer_mode,
                      donation_systems: {
                        ...prev.streamer_mode.donation_systems,
                        twitch_bits: {
                          ...prev.streamer_mode.donation_systems.twitch_bits,
                          price_multiplier: v,
                        },
                      },
                    },
                  }
                : prev,
            );
            void saveConfigPatch({
              streamer_mode: {
                donation_systems: {
                  twitch_bits: { price_multiplier: v },
                },
              },
            });
          }}
          onClose={() => setBitsOptionsModal(false)}
        />
      )}

      {exportDoneKind !== null && (
        <Modal title="Export complete" onClose={() => setExportDoneKind(null)}>
          <p>
            The effects file is being downloaded by your browser. Use it
            directly or import it into Google Sheets:
          </p>
          <GoogleSheetsInstructions kind={exportDoneKind} />
          <div
            style={{
              display: "flex",
              justifyContent: "flex-end",
              gap: 8,
              marginTop: 16,
            }}
          >
            <button className="btn" onClick={() => setExportDoneKind(null)}>
              Close
            </button>
            <a
              className="btn btn--success"
              href="https://sheets.new"
              target="_blank"
              rel="noreferrer"
            >
              <img
                src={googleSheetsLogo}
                alt=""
                style={{ width: 14, height: 14 }}
              />
              Open Google Sheets
            </a>
          </div>
        </Modal>
      )}
    </>
  );
}

interface GoogleSheetsInstructionsProps {
  kind: "csv" | "xlsx";
}

function GoogleSheetsInstructions({ kind }: GoogleSheetsInstructionsProps) {
  const fileLabel = kind === "csv" ? "CSV" : "XLSX";
  return (
    <ol>
      <li>
        Open{" "}
        <a href="https://sheets.new" target="_blank" rel="noreferrer">
          sheets.new
        </a>{" "}
        to create a new spreadsheet.
      </li>
      <li>
        Open <code>File → Import → Upload</code>.
      </li>
      <li>Upload the exported {fileLabel} file.</li>
      {kind === "csv" ? (
        <li>
          Open <code>Format → Convert to table</code>.
        </li>
      ) : (
        <li>
          In the import dialog, choose <b>Replace spreadsheet</b> (or{" "}
          <b>Insert new sheet</b>) and click <b>Import data</b>; column widths,
          colors, and merged cells are preserved.
        </li>
      )}
      <li>
        Open <b>Share</b> in the top-right corner, then set{" "}
        <i>General access → Anyone with the link → Viewer</i>.
      </li>
    </ol>
  );
}

interface CopyButtonProps {
  value: string;
  onCopied: () => void;
  onError: (message: string) => void;
}

function CopyButton({ value, onCopied, onError }: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  const handleClick = async () => {
    try {
      await navigator.clipboard.writeText(value);
      setCopied(true);
      onCopied();
      setTimeout(() => setCopied(false), 1500);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      onError(`Failed to copy: ${msg}`);
    }
  };

  return (
    <button
      type="button"
      className="icon-btn"
      title={copied ? "Copied!" : "Copy to clipboard"}
      aria-label="Copy to clipboard"
      onClick={() => void handleClick()}
    >
      {copied ? <Check size={14} /> : <Copy size={14} />}
    </button>
  );
}

interface TwitchBitsOptionsModalProps {
  multiplier: number;
  priceGroups: { group: string; price: number }[];
  onChangeMultiplier: (v: number) => void;
  onClose: () => void;
}

function TwitchBitsOptionsModal({
  multiplier,
  priceGroups,
  onChangeMultiplier,
  onClose,
}: TwitchBitsOptionsModalProps) {
  const safeMultiplier =
    Number.isFinite(multiplier) && multiplier > 0 ? multiplier : 100;

  const groupedHint = useMemo(() => {
    const byBits = new Map<number, string[]>();
    for (const pg of priceGroups) {
      const bits = Math.ceil(pg.price * safeMultiplier);
      const list = byBits.get(bits) ?? [];
      list.push(pg.group);
      byBits.set(bits, list);
    }
    const rows = Array.from(byBits.entries())
      .map(([bits, groups]) => ({ bits, groups }))
      .sort((a, b) => a.bits - b.bits);
    return rows;
  }, [priceGroups, safeMultiplier]);

  return (
    <Modal title="Twitch Bits Options" onClose={onClose}>
      <div className="form-grid">
        <label className="form-field">
          <span className="form-label">Twitch Bits Multiplier</span>
          <NumberInput
            value={multiplier}
            min={1}
            step={1}
            onChange={(v) => onChangeMultiplier(v)}
          />
        </label>
      </div>
      <p style={{ marginTop: 16, marginBottom: 8, fontWeight: 600 }}>
        Effect Groups:
      </p>
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: 4,
          fontFamily: "Roboto Mono, monospace",
          fontSize: 13,
        }}
      >
        {groupedHint.length === 0 ? (
          <span style={{ opacity: 0.7 }}>No price groups configured.</span>
        ) : (
          groupedHint.map((row) => (
            <div key={row.bits}>
              {row.groups.join(", ")} — {row.bits} Bits
            </div>
          ))
        )}
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

interface DonationAlertsLoginModalProps {
  port: number;
  busy: boolean;
  appId: string;
  secret: string;
  currency: string;
  onAppId: (v: string) => void;
  onSecret: (v: string) => void;
  onCurrency: (v: string) => void;
  onClose: () => void;
  onSubmit: () => void;
}

function DonationAlertsLoginModal({
  port,
  busy,
  appId,
  secret,
  currency,
  onAppId,
  onSecret,
  onCurrency,
  onClose,
  onSubmit,
}: DonationAlertsLoginModalProps) {
  const redirectUri = `http://localhost:${port}/provider/donationalerts/success/`;
  const trimmedAppId = appId.trim();
  const trimmedCurrency = currency.trim().toUpperCase();
  const currencyValid = /^[A-Z]{3}$/.test(trimmedCurrency);
  const canSubmit =
    !busy && trimmedAppId.length > 0 && secret.length > 0 && currencyValid;

  return (
    <Modal title="Connect DonationAlerts" onClose={onClose}>
      <p>
        To enable DonationAlerts donations, create an OAuth application and
        paste its credentials below.
      </p>
      <ol>
        <li>
          Open{" "}
          <a
            href="https://www.donationalerts.com/application/clients"
            target="_blank"
            rel="noreferrer"
          >
            donationalerts.com/application/clients
          </a>{" "}
          and create a new application.
        </li>
        <li>
          Set the <b>Redirect URI</b> to exactly:
          <div className="card-link" style={{ marginTop: 4 }}>
            {redirectUri}
          </div>
        </li>
        <li>
          Copy the <b>Application ID</b> and <b>Client Secret</b> into the
          fields below.
        </li>
        <li>
          Choose the donation <b>Currency</b> code (3 letters, e.g.{" "}
          <code>RUB</code>, <code>USD</code>, <code>EUR</code>).
        </li>
        <li>
          Click <b>Login</b> — credentials are saved and a DonationAlerts
          authorization page opens in your browser.
        </li>
      </ol>

      <div className="form-grid" style={{ marginTop: 16 }}>
        <label className="form-field">
          <span className="form-label">Application ID</span>
          <TextInput value={appId} onChange={onAppId} placeholder="123456" />
        </label>
        <label className="form-field">
          <span className="form-label">Client Secret</span>
          <TextInput
            value={secret}
            onChange={onSecret}
            type="password"
            placeholder="••••••••"
          />
        </label>
        <label className="form-field">
          <span className="form-label">Currency</span>
          <TextInput
            value={currency}
            onChange={(v) => onCurrency(v.toUpperCase().slice(0, 3))}
            size="mid"
            placeholder="RUB"
          />
        </label>
      </div>

      <div
        style={{
          display: "flex",
          justifyContent: "flex-end",
          gap: 8,
          marginTop: 18,
        }}
      >
        <button className="btn" onClick={onClose} disabled={busy}>
          Cancel
        </button>
        <button
          className="btn btn--primary"
          disabled={!canSubmit}
          onClick={onSubmit}
        >
          <LogIn size={14} aria-hidden="true" />
          Login
        </button>
      </div>
    </Modal>
  );
}
