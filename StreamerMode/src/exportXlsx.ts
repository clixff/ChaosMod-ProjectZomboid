import ExcelJS from "exceljs";
import { join } from "path";
import { getString, getStringOrNull } from "./localization.ts";
import type { EffectEntry } from "./effects.ts";

interface PriceGroup {
  group: string;
  price: number;
}

interface ColumnSpec {
  key: string;
  headerKey: string | null;
  headerLiteral?: string;
  headerColor: string;
  pixelWidth: number;
}

const COLUMNS: ColumnSpec[] = [
  {
    key: "id",
    headerKey: null,
    headerLiteral: "ID",
    headerColor: "FFE35A58",
    pixelWidth: 60,
  },
  {
    key: "name",
    headerKey: "col_name",
    headerColor: "FF4285F4",
    pixelWidth: 270,
  },
  {
    key: "enabled",
    headerKey: "col_enabled",
    headerColor: "FF42B9F4",
    pixelWidth: 100,
  },
  {
    key: "duration",
    headerKey: "col_duration",
    headerColor: "FFF4426E",
    pixelWidth: 100,
  },
  {
    key: "chance",
    headerKey: "col_chance",
    headerColor: "FF38761D",
    pixelWidth: 80,
  },
  {
    key: "price_group",
    headerKey: "col_price_group",
    headerColor: "FF8E7CC3",
    pixelWidth: 120,
  },
  {
    key: "price",
    headerKey: "col_price",
    headerColor: "FF93C47D",
    pixelWidth: 100,
  },
  {
    key: "description",
    headerKey: "col_description",
    headerColor: "FF6C757D",
    pixelWidth: 300,
  },
];

// exceljs column width unit ≈ width of a "0" digit in Calibri 11 (~7px).
function pxToColumnWidth(px: number): number {
  return Math.round((px / 7) * 100) / 100;
}

// exceljs row height is in points; 1 pt ≈ 1.333 px.
function pxToRowHeightPt(px: number): number {
  return Math.round(px * 0.75 * 100) / 100;
}

function formatPriceGroupLabel(rawGroup: string): string {
  if (!rawGroup) return "";
  return rawGroup
    .split("_")
    .filter((part) => part.length > 0)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function extractGroupTier(rawGroup: string): number | null {
  const m = rawGroup.match(/_(\d+)$/);
  if (!m) return null;
  const n = Number.parseInt(m[1] ?? "", 10);
  return Number.isFinite(n) ? n : null;
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

// Linear interpolation green → yellow → red for tiers 1..6.
function priceGroupColor(tier: number): string {
  const minT = 1;
  const maxT = 6;
  const clamped = Math.max(minT, Math.min(maxT, tier));
  const t = (clamped - minT) / (maxT - minT);
  // Green #38761d → Yellow #d6b656 → Red #e35a58
  let r: number;
  let g: number;
  let b: number;
  if (t < 0.5) {
    const k = t / 0.5;
    r = lerp(0x38, 0xd6, k);
    g = lerp(0x76, 0xb6, k);
    b = lerp(0x1d, 0x56, k);
  } else {
    const k = (t - 0.5) / 0.5;
    r = lerp(0xd6, 0xe3, k);
    g = lerp(0xb6, 0x5a, k);
    b = lerp(0x56, 0x58, k);
  }
  const toHex = (n: number) =>
    Math.round(n).toString(16).padStart(2, "0").toUpperCase();
  return `FF${toHex(r)}${toHex(g)}${toHex(b)}`;
}

function setCell(
  cell: ExcelJS.Cell,
  value: ExcelJS.CellValue,
  options: {
    bg?: string;
    fontColor?: string;
    bold?: boolean;
    fontName?: string;
    fontSize?: number;
    wrap?: boolean;
  } = {},
): void {
  cell.value = value;
  cell.alignment = {
    vertical: "middle",
    horizontal: "center",
    wrapText: options.wrap ?? false,
  };
  cell.font = {
    name: options.fontName ?? "Roboto",
    size: options.fontSize ?? 11,
    bold: options.bold ?? false,
    color: options.fontColor ? { argb: options.fontColor } : undefined,
  };
  if (options.bg) {
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: options.bg },
    };
  }
  cell.border = {
    top: { style: "thin", color: { argb: "FFD0D0D0" } },
    left: { style: "thin", color: { argb: "FFD0D0D0" } },
    bottom: { style: "thin", color: { argb: "FFD0D0D0" } },
    right: { style: "thin", color: { argb: "FFD0D0D0" } },
  };
}

export async function writeEffectsXlsx(
  luaDir: string,
  effects: EffectEntry[],
  priceGroups: PriceGroup[],
  donateActive: boolean,
): Promise<string> {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet("Effects", {
    views: [{ state: "frozen", ySplit: 2 }],
  });

  // Column widths
  sheet.columns = COLUMNS.map((c) => ({
    key: c.key,
    width: pxToColumnWidth(c.pixelWidth),
  }));

  // Row 1: title
  sheet.mergeCells(1, 1, 1, COLUMNS.length);
  const titleCell = sheet.getCell(1, 1);
  const titleText = getString("export", "title");
  const donateHint = donateActive ? getString("export", "donate_hint") : "";
  if (donateActive) {
    titleCell.value = {
      richText: [
        {
          font: {
            name: "Roboto",
            size: 20,
            bold: true,
            color: { argb: "FFFFFFFF" },
          },
          text: titleText,
        },
        {
          font: {
            name: "Roboto",
            size: 11,
            bold: false,
            color: { argb: "FFFFFFFF" },
          },
          text: `\n${donateHint}`,
        },
      ],
    };
    titleCell.alignment = {
      vertical: "middle",
      horizontal: "center",
      wrapText: true,
    };
    titleCell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFC75C5C" },
    };
    titleCell.border = {
      top: { style: "thin", color: { argb: "FFD0D0D0" } },
      left: { style: "thin", color: { argb: "FFD0D0D0" } },
      bottom: { style: "thin", color: { argb: "FFD0D0D0" } },
      right: { style: "thin", color: { argb: "FFD0D0D0" } },
    };
    sheet.getRow(1).height = pxToRowHeightPt(110);
  } else {
    setCell(titleCell, titleText, {
      bg: "FFC75C5C",
      fontColor: "FFFFFFFF",
      bold: true,
    });
    titleCell.font = {
      name: "Roboto",
      size: 20,
      bold: true,
      color: { argb: "FFFFFFFF" },
    };
    sheet.getRow(1).height = pxToRowHeightPt(70);
  }

  // Row 2: header
  const headerRow = sheet.getRow(2);
  COLUMNS.forEach((col, idx) => {
    const cell = headerRow.getCell(idx + 1);
    const headerText =
      col.headerKey != null
        ? getString("export", col.headerKey)
        : (col.headerLiteral ?? "");
    setCell(cell, headerText, {
      bg: col.headerColor,
      fontColor: "FFFFFFFF",
      bold: true,
      wrap: true,
    });
  });
  headerRow.height = pxToRowHeightPt(45);

  const priceByGroup = new Map<string, number>();
  for (const pg of priceGroups) priceByGroup.set(pg.group, pg.price);

  effects.forEach((e, index) => {
    const rowNumber = index + 3;
    const row = sheet.getRow(rowNumber);
    row.height = pxToRowHeightPt(40);

    // ID
    setCell(row.getCell(1), index + 1, {
      bg: "FFE35A58",
      fontColor: "FFFFFFFF",
      bold: true,
      fontName: "Roboto Mono",
    });

    // Name
    const name = getString("effects", e.id);
    const nameBg = index % 2 === 0 ? "FFFFFFFF" : "FFEFEFEF";
    setCell(row.getCell(2), name, {
      bg: nameBg,
      fontColor: "FF000000",
      wrap: true,
    });

    // Enabled
    const enabled = e.enabled;
    const donate = e.enabled_donate;
    let enabledText: string;
    let enabledBg: string;
    if (!enabled && !donate) {
      enabledText = getString("export", "status_disabled");
      enabledBg = "FFE06666"; // red
    } else if (enabled && donate) {
      enabledText = getString("export", "status_enabled");
      enabledBg = "FF6AA84F"; // green
    } else if (enabled && !donate) {
      enabledText = getString("export", "status_voting_only");
      enabledBg = "FFE69138"; // orange
    } else {
      enabledText = getString("export", "status_donations_only");
      enabledBg = "FFE69138"; // orange
    }
    setCell(row.getCell(3), enabledText, {
      bg: enabledBg,
      fontColor: "FFFFFFFF",
      bold: true,
    });

    // Duration
    const hasDuration = e.withDuration && e.duration != null;
    if (hasDuration) {
      setCell(row.getCell(4), e.duration ?? 0, {
        bg: "FF4A90E2",
        fontColor: "FFFFFFFF",
        wrap: true,
      });
    } else {
      setCell(row.getCell(4), null, { bg: "FFFFFFFF" });
    }

    // Chance
    if (enabled) {
      setCell(row.getCell(5), `${e.chance}%`, {
        bg: "FFFFFFFF",
        fontColor: "FF000000",
      });
    } else {
      setCell(row.getCell(5), null, { bg: "FFFFFFFF" });
    }

    // Price group
    if (e.price_group) {
      const tier = extractGroupTier(e.price_group);
      const bg = tier != null ? priceGroupColor(tier) : "FFCCCCCC";
      setCell(row.getCell(6), formatPriceGroupLabel(e.price_group), {
        bg,
        fontColor: "FFFFFFFF",
        bold: true,
        fontName: "Roboto Serif",
      });
    } else {
      setCell(row.getCell(6), null, {
        bg: "FFFFFFFF",
        fontName: "Roboto Serif",
      });
    }

    // Price
    if (donate && e.price_group && priceByGroup.has(e.price_group)) {
      setCell(row.getCell(7), priceByGroup.get(e.price_group) ?? 0, {
        bg: "FFF6B26B",
        fontColor: "FFFFFFFF",
        bold: true,
      });
    } else {
      setCell(row.getCell(7), null, { bg: "FFFFFFFF" });
    }

    // Description
    const desc = getStringOrNull("descriptions", e.id);
    setCell(row.getCell(8), desc ?? null, {
      bg: "FFFFFFFF",
      fontColor: "FF000000",
      fontSize: 10,
      wrap: true,
    });
  });

  const outputPath = join(luaDir, "export.xlsx");
  await workbook.xlsx.writeFile(outputPath);
  return outputPath;
}
