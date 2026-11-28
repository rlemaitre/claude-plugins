# /// script
# requires-python = ">=3.11"
# dependencies = ["openpyxl==3.1.5"]
# ///
"""Overview of an .xlsx: sheets, sizes, header rows, formulas and cached values.

Read-only. Cached values are the ones the last app saved; a file written by
openpyxl has none (shown as ∅) until an app recalculates and saves it as .xlsx.
Use verify.py to compute formula results instead.

Usage:
    uv run --script inspect_workbook.py <file.xlsx> [--sheet NAME] [--rows N]
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import openpyxl

EMPTY = "∅"


def show(value) -> str:
    if value is None:
        return EMPTY
    text = getattr(value, "text", value)
    return str(text).replace("\n", "⏎")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("workbook", type=Path)
    parser.add_argument("--sheet", help="only this sheet")
    parser.add_argument("--rows", type=int, default=15, help="rows shown per sheet (default 15)")
    args = parser.parse_args()

    with_formulas = openpyxl.load_workbook(args.workbook, data_only=False)
    cached = openpyxl.load_workbook(args.workbook, data_only=True)

    names = [args.sheet] if args.sheet else with_formulas.sheetnames
    for name in names:
        if name not in with_formulas.sheetnames:
            print(f"no sheet named {name!r}; sheets: {with_formulas.sheetnames}", file=sys.stderr)
            return 1
        ws, wc = with_formulas[name], cached[name]
        formula_count = sum(
            1 for row in ws.iter_rows() for c in row
            if isinstance(getattr(c.value, "text", c.value), str) and str(getattr(c.value, "text", c.value)).startswith("=")
        )
        print(f"## {name}")
        print(f"dimensions: {ws.dimensions}  rows: {ws.max_row}  cols: {ws.max_column}  "
              f"formulas: {formula_count}  merged ranges: {len(ws.merged_cells.ranges)}")
        for r in range(1, min(ws.max_row, args.rows) + 1):
            parts = []
            for c in range(1, ws.max_column + 1):
                raw = ws.cell(r, c).value
                if raw is None:
                    continue
                coord = ws.cell(r, c).coordinate
                formula = getattr(raw, "text", raw)
                if isinstance(formula, str) and formula.startswith("="):
                    parts.append(f"{coord}: {formula} → {show(wc.cell(r, c).value)}")
                else:
                    parts.append(f"{coord}: {show(raw)}")
            if parts:
                print("  " + " | ".join(parts))
        if ws.max_row > args.rows:
            print(f"  … {ws.max_row - args.rows} more rows")
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
