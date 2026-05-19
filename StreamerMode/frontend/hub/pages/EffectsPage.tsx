import { useEffect, useMemo, useState } from "react";
import {
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Search,
  Clock,
  ChevronDown,
  ChevronRight,
  X,
  Copy,
  Check,
  Layers,
} from "lucide-react";
import twitchLogoUrl from "../assets/twitch_logo.webp";
import donationAlertsLogoUrl from "../assets/donationalerts_logo.webp";
import {
  useConfigFile,
  useEffectsFile,
  useEnglishLangFile,
  useLangFile,
} from "../api/loaders.ts";
import { useLanguage } from "../i18n/LanguageProvider.tsx";
import { getColumnLabels } from "../i18n/columnLabels.ts";
import { buildEffectRows, priceGroupCompare } from "../api/effectRows.ts";
import type { EffectRow } from "../api/types.ts";

type SortKey = "numericId" | "name" | "priceGroup" | "price" | "twitchBits";
type SortDir = "asc" | "desc";
type GroupBy = "none" | "tiers" | "groups" | "groupType";
type GuideId = "bits" | "points" | "donationalerts";

const DEFAULT_SORT: { key: SortKey; dir: SortDir } = {
  key: "numericId",
  dir: "asc",
};

const GROUP_BY_OPTIONS: { value: GroupBy; label: string }[] = [
  { value: "none", label: "None" },
  { value: "tiers", label: "Tiers" },
  { value: "groups", label: "Groups" },
  { value: "groupType", label: "Group Type" },
];

const GROUP_BY_LABEL: Record<GroupBy, string> = {
  none: "None",
  tiers: "Tiers",
  groups: "Groups",
  groupType: "Group Type",
};

interface GroupedSection {
  key: string;
  label: string;
  rows: EffectRow[];
}

export function EffectsPage() {
  const { language } = useLanguage();
  const effectsQuery = useEffectsFile();
  const configQuery = useConfigFile();
  const langQuery = useLangFile(language);
  const englishQuery = useEnglishLangFile();

  const isLoading =
    effectsQuery.isPending ||
    configQuery.isPending ||
    langQuery.isPending ||
    englishQuery.isPending;
  const error =
    effectsQuery.error ??
    configQuery.error ??
    langQuery.error ??
    englishQuery.error;

  const rows = useMemo<EffectRow[]>(() => {
    if (
      !effectsQuery.data ||
      !configQuery.data ||
      !langQuery.data ||
      !englishQuery.data
    ) {
      return [];
    }
    return buildEffectRows(
      effectsQuery.data.effects,
      configQuery.data,
      langQuery.data,
      englishQuery.data,
    );
  }, [effectsQuery.data, configQuery.data, langQuery.data, englishQuery.data]);

  const labels = useMemo(
    () => getColumnLabels(langQuery.data, englishQuery.data),
    [langQuery.data, englishQuery.data],
  );

  const [query, setQuery] = useState("");
  const [groupBy, setGroupBy] = useState<GroupBy>("none");
  const [collapsedGroups, setCollapsedGroups] = useState<Set<string>>(
    new Set(),
  );
  const [sort, setSort] = useState(DEFAULT_SORT);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [groupByMenuOpen, setGroupByMenuOpen] = useState(false);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [openGuides, setOpenGuides] = useState<Set<GuideId>>(new Set());
  const [toast, setToast] = useState<string | null>(null);

  function toggleGuide(id: GuideId) {
    setOpenGuides((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  const filterKey = `${query}|${groupBy}|${sort.key}|${sort.dir}`;
  const [prevFilterKey, setPrevFilterKey] = useState(filterKey);
  if (prevFilterKey !== filterKey) {
    setPrevFilterKey(filterKey);
    if (expanded !== null) setExpanded(null);
  }

  const [prevGroupBy, setPrevGroupBy] = useState(groupBy);
  if (prevGroupBy !== groupBy) {
    setPrevGroupBy(groupBy);
    if (collapsedGroups.size > 0) setCollapsedGroups(new Set());
  }

  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 1800);
    return () => clearTimeout(timer);
  }, [toast]);

  const filteredSorted = useMemo(() => {
    const q = query.trim().toLowerCase();
    const filtered = rows.filter((row) => {
      if (!q) return true;
      if (row.name.toLowerCase().includes(q)) return true;
      if (row.effectId.toLowerCase().includes(q)) return true;
      if (String(row.numericId) === q || String(row.numericId).startsWith(q)) {
        return true;
      }
      return false;
    });

    const collator = new Intl.Collator(language, {
      sensitivity: "base",
      numeric: true,
    });
    const dir = sort.dir === "asc" ? 1 : -1;
    filtered.sort((a, b) => {
      switch (sort.key) {
        case "numericId":
          return (a.numericId - b.numericId) * dir;
        case "name":
          return collator.compare(a.name, b.name) * dir;
        case "priceGroup":
          return priceGroupCompare(a.priceGroup, b.priceGroup) * dir;
        case "price":
          return (
            (numOrInf(a.price, sort.dir) - numOrInf(b.price, sort.dir)) * dir
          );
        case "twitchBits":
          return (
            (numOrInf(a.twitchBits, sort.dir) -
              numOrInf(b.twitchBits, sort.dir)) *
            dir
          );
        default:
          return 0;
      }
    });
    return filtered;
  }, [rows, query, sort, language]);

  const grouped = useMemo<GroupedSection[]>(() => {
    if (groupBy === "none") {
      return [{ key: "all", label: "", rows: filteredSorted }];
    }
    const map = new Map<string, EffectRow[]>();
    for (const row of filteredSorted) {
      const key = getGroupKey(row.priceGroup, groupBy);
      let bucket = map.get(key);
      if (!bucket) {
        bucket = [];
        map.set(key, bucket);
      }
      bucket.push(row);
    }
    const keys = Array.from(map.keys()).sort((a, b) =>
      groupKeyCompare(a, b, groupBy),
    );
    return keys.map((k) => ({
      key: k,
      label: getGroupLabel(k, groupBy),
      rows: map.get(k)!,
    }));
  }, [filteredSorted, groupBy]);

  function toggleSort(key: SortKey) {
    setSort((prev) =>
      prev.key === key
        ? { key, dir: prev.dir === "asc" ? "desc" : "asc" }
        : { key, dir: "asc" },
    );
  }

  function toggleCollapsed(key: string) {
    setCollapsedGroups((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }

  async function copyEffectId(effectId: string) {
    try {
      await navigator.clipboard.writeText(effectId);
      setToast(`Copied ${effectId}`);
    } catch {
      setToast("Copy failed");
    }
  }

  return (
    <section className={`effects-page${filtersOpen ? " is-filters-open" : ""}`}>
      <header className="effects-header">
        <h1 className="page-title">Effects</h1>
        <p className="page-subtitle">
          <span className="page-subtitle-strong">{rows.length}</span> total
          effects · default prices shown
        </p>
        <div className="effects-guides">
          <GuideSpoiler
            id="bits"
            logo={twitchLogoUrl}
            title="How to Activate with Twitch Bits"
            open={openGuides.has("bits")}
            onToggle={toggleGuide}
          >
            <ol className="guide-list">
              <li>Find the effect you want to activate.</li>
              <li>
                Send a message in Twitch chat using this format:
                <pre className="guide-code">Cheer500 95</pre>
              </li>
              <li>
                In this example:
                <ul className="guide-sublist">
                  <li>
                    <code className="guide-inline-code">500</code> is the Bits
                    price of the effect.
                  </li>
                  <li>
                    <code className="guide-inline-code">95</code> is the effect
                    ID.
                  </li>
                </ul>
              </li>
            </ol>
          </GuideSpoiler>
          <GuideSpoiler
            id="points"
            logo={twitchLogoUrl}
            title="How to Activate with Twitch Points"
            open={openGuides.has("points")}
            onToggle={toggleGuide}
          >
            <ol className="guide-list">
              <li>Find the effect you want to activate and click on it.</li>
              <li>
                Check the effect&apos;s tier. For example, effect{" "}
                <code className="guide-inline-code">18</code> may have{" "}
                <strong>Tier 5</strong>.
              </li>
              <li>
                Open the Twitch reward named:
                <pre className="guide-code">Chaos Mod Zomboid - Tier 5</pre>
              </li>
              <li>
                Activate the reward and enter the effect ID as the message text.
                For example, to activate effect{" "}
                <code className="guide-inline-code">18</code>, enter:
                <pre className="guide-code">18</pre>
                Only enter the number.
              </li>
            </ol>
          </GuideSpoiler>
          <GuideSpoiler
            id="donationalerts"
            logo={donationAlertsLogoUrl}
            title="How to Activate with DonationAlerts"
            open={openGuides.has("donationalerts")}
            onToggle={toggleGuide}
            accentColor="#f59808"
          >
            <ol className="guide-list">
              <li>Find the effect you want to activate.</li>
              <li>Check its price and effect ID.</li>
              <li>Open the streamer&apos;s DonationAlerts page.</li>
              <li>Send a donation with the exact required price.</li>
              <li>
                Put the effect ID in the donation message. For example, to
                activate effect <code className="guide-inline-code">161</code>,
                enter this in the donation message:
                <pre className="guide-code">161</pre>
              </li>
            </ol>
          </GuideSpoiler>
        </div>
      </header>

      <div className="effects-toolbar">
        <div className="effects-search">
          <Search size={16} className="effects-search-icon" />
          <input
            type="search"
            className="effects-search-input"
            placeholder="search by name, id, or number…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          {query ? (
            <button
              type="button"
              className="effects-search-clear"
              aria-label="Clear search"
              onClick={() => setQuery("")}
            >
              <X size={14} />
            </button>
          ) : null}
        </div>
        <button
          type="button"
          className={`effects-filters-toggle${filtersOpen ? " is-open" : ""}`}
          onClick={() => setFiltersOpen((open) => !open)}
          aria-expanded={filtersOpen}
          aria-label="Toggle filters"
        >
          <ChevronDown size={18} className="effects-filters-toggle-icon" />
        </button>
        <div className="effects-toolbar-filters">
          <GroupByDropdown
            value={groupBy}
            onChange={setGroupBy}
            open={groupByMenuOpen}
            setOpen={setGroupByMenuOpen}
          />
        </div>
      </div>

      {error ? (
        <div className="effects-error">
          Failed to load effects: {String(error)}
        </div>
      ) : isLoading ? (
        <SkeletonTable />
      ) : (
        <EffectsTable
          groups={grouped}
          groupBy={groupBy}
          collapsed={collapsedGroups}
          onToggleCollapsed={toggleCollapsed}
          sort={sort}
          onSort={toggleSort}
          expanded={expanded}
          onToggleExpanded={(id) =>
            setExpanded((prev) => (prev === id ? null : id))
          }
          onCopyId={copyEffectId}
          labels={labels}
        />
      )}

      {toast ? (
        <div className="toast" role="status">
          <Check size={14} />
          <span>{toast}</span>
        </div>
      ) : null}
    </section>
  );
}

function numOrInf(value: number | null, dir: SortDir): number {
  if (value != null) return value;
  return dir === "asc" ? Number.POSITIVE_INFINITY : Number.NEGATIVE_INFINITY;
}

interface SortState {
  key: SortKey;
  dir: SortDir;
}

function EffectsTable({
  groups,
  groupBy,
  collapsed,
  onToggleCollapsed,
  sort,
  onSort,
  expanded,
  onToggleExpanded,
  onCopyId,
  labels,
}: {
  groups: GroupedSection[];
  groupBy: GroupBy;
  collapsed: Set<string>;
  onToggleCollapsed: (key: string) => void;
  sort: SortState;
  onSort: (key: SortKey) => void;
  expanded: string | null;
  onToggleExpanded: (id: string) => void;
  onCopyId: (id: string) => void;
  labels: ReturnType<typeof getColumnLabels>;
}) {
  const totalRows = groups.reduce((acc, g) => acc + g.rows.length, 0);
  if (totalRows === 0) {
    return <div className="effects-empty">No effects match your filters.</div>;
  }

  const showGroupHeaders = groupBy !== "none";
  const colCount = 9;

  return (
    <div className="effects-table-wrap">
      <table className="effects-table">
        <thead>
          <tr>
            <SortHeader
              label={labels.id}
              col="id"
              sortKey="numericId"
              sort={sort}
              onSort={onSort}
            />
            <SortHeader
              label={labels.name}
              col="name"
              sortKey="name"
              sort={sort}
              onSort={onSort}
            />
            <th className="col-desc col-desktop-only">{labels.description}</th>
            <th className="col-duration col-desktop-only">{labels.duration}</th>
            <th className="col-chance col-desktop-only">{labels.chance}</th>
            <SortHeader
              label={labels.priceGroup}
              col="group"
              sortKey="priceGroup"
              sort={sort}
              onSort={onSort}
            />
            <SortHeader
              label={labels.price}
              col="price"
              sortKey="price"
              sort={sort}
              onSort={onSort}
            />
            <SortHeader
              label={labels.twitchBits}
              col="bits"
              sortKey="twitchBits"
              sort={sort}
              onSort={onSort}
              icon={
                <img
                  src={twitchLogoUrl}
                  alt=""
                  className="col-icon col-icon-img"
                />
              }
            />
            <th className="col-actions" aria-label="Actions" />
          </tr>
        </thead>
        {groups.map((group) => {
          const isCollapsed = collapsed.has(group.key);
          return (
            <tbody
              key={group.key}
              className={`effects-group${isCollapsed ? " is-collapsed" : ""}`}
            >
              {showGroupHeaders ? (
                <tr className="effects-group-header">
                  <td colSpan={colCount}>
                    <button
                      type="button"
                      className="effects-group-header-button"
                      onClick={() => onToggleCollapsed(group.key)}
                      aria-expanded={!isCollapsed}
                    >
                      {isCollapsed ? (
                        <ChevronRight
                          size={16}
                          className="effects-group-chevron"
                        />
                      ) : (
                        <ChevronDown
                          size={16}
                          className="effects-group-chevron"
                        />
                      )}
                      <span className="effects-group-label">{group.label}</span>
                      <span className="effects-group-count">
                        {group.rows.length}
                      </span>
                    </button>
                  </td>
                </tr>
              ) : null}
              {!isCollapsed
                ? group.rows.map((row, index) => (
                    <EffectRowView
                      key={row.effectId}
                      row={row}
                      index={index}
                      expanded={expanded === row.effectId}
                      onToggle={() => onToggleExpanded(row.effectId)}
                      onCopyId={onCopyId}
                      labels={labels}
                    />
                  ))
                : null}
            </tbody>
          );
        })}
      </table>
    </div>
  );
}

function SortHeader({
  label,
  col,
  sortKey,
  sort,
  onSort,
  icon,
}: {
  label: string;
  col: string;
  sortKey: SortKey;
  sort: SortState;
  onSort: (key: SortKey) => void;
  icon?: React.ReactNode;
}) {
  const active = sort.key === sortKey;
  const Indicator = !active
    ? ArrowUpDown
    : sort.dir === "asc"
      ? ArrowUp
      : ArrowDown;
  return (
    <th
      className={`col-${col} sort-header${active ? " is-active" : ""}`}
      aria-sort={
        active ? (sort.dir === "asc" ? "ascending" : "descending") : "none"
      }
    >
      <button
        type="button"
        className="sort-header-button"
        onClick={() => onSort(sortKey)}
      >
        {icon ?? null}
        <span>{label}</span>
        <Indicator size={14} className="sort-indicator" />
      </button>
    </th>
  );
}

function EffectRowView({
  row,
  index,
  expanded,
  onToggle,
  onCopyId,
  labels,
}: {
  row: EffectRow;
  index: number;
  expanded: boolean;
  onToggle: () => void;
  onCopyId: (id: string) => void;
  labels: ReturnType<typeof getColumnLabels>;
}) {
  const disabled = !row.enabled;
  const isAlt = index % 2 === 1;
  const groupColor = getPriceGroupColor(row.priceGroup);
  return (
    <>
      <tr
        className={`effect-row${isAlt ? " is-alt" : ""}${disabled ? " is-disabled" : ""}${expanded ? " is-expanded" : ""}`}
        onClick={onToggle}
        aria-expanded={expanded}
      >
        <td className="col-id">{row.numericId}</td>
        <td className="col-name">
          <div
            className="effect-name"
            style={disabled ? undefined : { color: groupColor }}
          >
            {row.name}
          </div>
          <div className="effect-meta-row col-mobile-only">
            {row.withDuration && row.duration != null ? (
              <span className="effect-meta-chip" title="Duration">
                <Clock size={12} />
                {row.duration}s
              </span>
            ) : null}
            {disabled ? (
              <span className="effect-badge effect-badge--disabled">
                Disabled
              </span>
            ) : null}
          </div>
        </td>
        <td className="col-desc col-desktop-only">
          <div className="effect-desc-clamp">{row.description || ""}</div>
        </td>
        <td className="col-duration col-desktop-only">
          {row.withDuration && row.duration != null ? `${row.duration}s` : ""}
        </td>
        <td className="col-chance col-desktop-only">{row.chance.toFixed(2)}</td>
        <td className="col-group">
          <PriceGroupChip group={row.priceGroup} />
        </td>
        <td className="col-price">{formatPrice(row.price)}</td>
        <td className="col-bits">{formatBits(row.twitchBits)}</td>
        <td className="col-actions">
          <button
            type="button"
            className="row-action"
            aria-label="Copy effect ID"
            title="Copy effect ID"
            onClick={(e) => {
              e.stopPropagation();
              onCopyId(String(row.numericId));
            }}
          >
            <Copy size={14} />
          </button>
        </td>
      </tr>
      {expanded ? (
        <tr className={`effect-row-expand${isAlt ? " is-alt" : ""}`}>
          <td colSpan={9}>
            <div className="effect-expand-body">
              <div className="effect-expand-section">
                <span className="effect-expand-label">Description</span>
                <div className="effect-expand-text">
                  {row.description || "No description available."}
                </div>
              </div>
              <div className="effect-expand-meta">
                {row.withDuration && row.duration != null ? (
                  <div className="effect-expand-meta-item">
                    <span className="effect-expand-label">
                      {labels.duration}
                    </span>
                    <span className="effect-expand-value">{row.duration}s</span>
                  </div>
                ) : null}
                <div className="effect-expand-meta-item">
                  <span className="effect-expand-label">{labels.chance}</span>
                  <span className="effect-expand-value">
                    {row.chance.toFixed(2)}
                  </span>
                </div>
                {getPriceGroupTier(row.priceGroup) != null ? (
                  <div className="effect-expand-meta-item">
                    <span className="effect-expand-label">Tier</span>
                    <span className="effect-expand-value">
                      {getPriceGroupTier(row.priceGroup)}
                    </span>
                  </div>
                ) : null}
                <div className="effect-expand-meta-item">
                  <span className="effect-expand-label">{labels.price}</span>
                  <span className="effect-expand-value">
                    {formatPrice(row.price)}
                  </span>
                </div>
                <div className="effect-expand-meta-item">
                  <span className="effect-expand-label">
                    {labels.twitchBits}
                  </span>
                  <span className="effect-expand-value">
                    {formatBits(row.twitchBits)}
                  </span>
                </div>
              </div>
              <ActivationBlocks row={row} />
            </div>
          </td>
        </tr>
      ) : null}
    </>
  );
}

function ActivationBlocks({ row }: { row: EffectRow }) {
  const tier = getPriceGroupTier(row.priceGroup);
  const bits = row.twitchBits;
  const price = row.price;
  const effectNumber = row.numericId;
  if (bits == null && tier == null && price == null) return null;
  return (
    <div className="effect-activation-list">
      {bits != null ? (
        <div className="effect-activation">
          <div className="effect-activation-header">
            <img
              src={twitchLogoUrl}
              alt=""
              className="effect-activation-logo"
            />
            <span className="effect-activation-name">
              Activate with Twitch Bits
            </span>
          </div>
          <div className="effect-activation-body">
            <p>1. Send chat message:</p>
            <pre className="effect-activation-code">
              Cheer{bits} {effectNumber}
            </pre>
          </div>
        </div>
      ) : null}
      {tier != null ? (
        <div className="effect-activation">
          <div className="effect-activation-header">
            <img
              src={twitchLogoUrl}
              alt=""
              className="effect-activation-logo"
            />
            <span className="effect-activation-name">
              Activate with Twitch Points
            </span>
          </div>
          <div className="effect-activation-body">
            <p>1. Find reward named:</p>
            <pre className="effect-activation-code">
              Chaos Mod Zomboid - Tier {tier}
            </pre>
            <p>2. Activate with message:</p>
            <pre className="effect-activation-code">{effectNumber}</pre>
          </div>
        </div>
      ) : null}
      {price != null ? (
        <div
          className="effect-activation"
          style={{ "--activation-accent": "#f59808" } as React.CSSProperties}
        >
          <div className="effect-activation-header">
            <img
              src={donationAlertsLogoUrl}
              alt=""
              className="effect-activation-logo"
            />
            <span className="effect-activation-name">
              Activate with DonationAlerts
            </span>
          </div>
          <div className="effect-activation-body">
            <p>
              1. Set price to{" "}
              <code className="effect-activation-inline-code">
                {formatPrice(price)}
              </code>{" "}
              and send donation with message:
            </p>
            <pre className="effect-activation-code">{effectNumber}</pre>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function PriceGroupChip({ group }: { group: string }) {
  const hsl = getPriceGroupHSL(group);
  const solid = `hsl(${hsl.h} ${hsl.s}% ${hsl.l}%)`;
  const soft = `hsl(${hsl.h} ${hsl.s}% ${hsl.l}% / 0.14)`;
  return (
    <span
      className="price-group-chip"
      style={{
        color: solid,
        background: soft,
      }}
    >
      {formatPriceGroupLabel(group)}
    </span>
  );
}

function getPriceGroupColor(group: string): string {
  const c = getPriceGroupHSL(group);
  return `hsl(${c.h} ${c.s}% ${c.l}%)`;
}

function getPriceGroupTier(group: string): number | null {
  const match = /^([a-z]+)_(\d+)$/.exec(group);
  if (!match) return null;
  const tier = parseInt(match[2]!, 10);
  return Number.isFinite(tier) ? tier : null;
}

function getPriceGroupHSL(group: string): {
  h: number;
  s: number;
  l: number;
} {
  const match = /^([a-z]+)_(\d+)$/.exec(group);
  if (!match) return { h: 0, s: 0, l: 60 };
  const polarity = match[1]!;
  const raw = Number(match[2]!);
  const tier = Math.min(6, Math.max(1, raw));
  const t = (tier - 1) / 5;

  if (polarity === "positive") {
    return {
      h: Math.round(lerpNum(78, 120, t)),
      s: Math.round(lerpNum(60, 50, t)),
      l: Math.round(lerpNum(55, 50, t)),
    };
  }
  if (polarity === "negative") {
    return {
      h: Math.round(lerpNum(28, 0, t)),
      s: Math.round(lerpNum(80, 65, t)),
      l: Math.round(lerpNum(58, 58, t)),
    };
  }
  return { h: 48, s: 90, l: 58 };
}

function lerpNum(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

function formatPriceGroupLabel(group: string): string {
  return group
    .split("_")
    .map((part) =>
      part.length > 0 ? part[0]!.toUpperCase() + part.slice(1) : part,
    )
    .join(" ");
}

function formatPrice(price: number | null): string {
  if (price == null) return "—";
  return `$${price.toLocaleString(undefined, { maximumFractionDigits: 2 })}`;
}

function formatBits(bits: number | null): string {
  if (bits == null) return "—";
  return bits.toLocaleString();
}

function GroupByDropdown({
  value,
  onChange,
  open,
  setOpen,
}: {
  value: GroupBy;
  onChange: (value: GroupBy) => void;
  open: boolean;
  setOpen: (open: boolean) => void;
}) {
  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      const target = e.target as HTMLElement | null;
      if (!target) return;
      if (target.closest(".groupby-filter")) return;
      setOpen(false);
    }
    if (open) document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, [open, setOpen]);

  return (
    <div className="groupby-filter">
      <button
        type="button"
        className={`groupby-filter-trigger${value !== "none" ? " is-active" : ""}`}
        onClick={() => setOpen(!open)}
        aria-expanded={open}
      >
        <Layers size={14} />
        <span>Group by: {GROUP_BY_LABEL[value]}</span>
        <ChevronDown size={14} />
      </button>
      {open ? (
        <ul className="groupby-filter-menu" role="listbox">
          {GROUP_BY_OPTIONS.map((option) => (
            <li key={option.value}>
              <button
                type="button"
                role="option"
                aria-selected={option.value === value}
                className={`groupby-filter-item${option.value === value ? " is-active" : ""}`}
                onClick={() => {
                  onChange(option.value);
                  setOpen(false);
                }}
              >
                {option.label}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}

function getGroupKey(priceGroup: string, mode: GroupBy): string {
  if (mode === "none") return "all";
  const match = /^([a-z]+)_(\d+)$/.exec(priceGroup);
  if (!match) {
    if (mode === "groups") return priceGroup;
    return "unknown";
  }
  const polarity = match[1]!;
  const tier = match[2]!;
  if (mode === "tiers") return `tier_${tier}`;
  if (mode === "groups") return priceGroup;
  if (mode === "groupType") return polarity;
  return priceGroup;
}

function getGroupLabel(key: string, mode: GroupBy): string {
  if (mode === "tiers") {
    const m = /^tier_(\d+)$/.exec(key);
    return m ? `Tier ${m[1]}` : key;
  }
  if (mode === "groups") {
    return formatPriceGroupLabel(key);
  }
  if (mode === "groupType") {
    return key.charAt(0).toUpperCase() + key.slice(1);
  }
  return key;
}

const GROUP_TYPE_ORDER: Record<string, number> = {
  positive: 0,
  neutral: 1,
  negative: 2,
};

function groupKeyCompare(a: string, b: string, mode: GroupBy): number {
  if (mode === "tiers") {
    const ta = parseInt(a.replace(/^tier_/, ""), 10);
    const tb = parseInt(b.replace(/^tier_/, ""), 10);
    const va = Number.isFinite(ta) ? ta : 99;
    const vb = Number.isFinite(tb) ? tb : 99;
    return va - vb;
  }
  if (mode === "groups") {
    return priceGroupCompare(a, b);
  }
  if (mode === "groupType") {
    return (GROUP_TYPE_ORDER[a] ?? 99) - (GROUP_TYPE_ORDER[b] ?? 99);
  }
  return 0;
}

function GuideSpoiler({
  id,
  logo,
  title,
  open,
  onToggle,
  accentColor,
  children,
}: {
  id: GuideId;
  logo: string;
  title: string;
  open: boolean;
  onToggle: (id: GuideId) => void;
  accentColor?: string;
  children: React.ReactNode;
}) {
  const style = accentColor
    ? ({ "--guide-accent": accentColor } as React.CSSProperties)
    : undefined;
  return (
    <div className={`guide-spoiler${open ? " is-open" : ""}`} style={style}>
      <button
        type="button"
        className="guide-spoiler-header"
        onClick={() => onToggle(id)}
        aria-expanded={open}
      >
        <ChevronDown size={16} className="guide-spoiler-chevron" />
        <img src={logo} alt="" className="guide-spoiler-logo" />
        <span className="guide-spoiler-title">{title}</span>
      </button>
      {open ? <div className="guide-spoiler-body">{children}</div> : null}
    </div>
  );
}

function SkeletonTable() {
  return (
    <div className="effects-skeleton">
      {Array.from({ length: 12 }).map((_, i) => (
        <div className="effects-skeleton-row" key={i} />
      ))}
    </div>
  );
}
