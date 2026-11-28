# /// script
# requires-python = ">=3.11"
# dependencies = ["openpyxl==3.1.5", "formulas==1.3.4"]
# ///
"""Recalculate an .xlsx in memory with the `formulas` engine and report.

Never writes to the workbook. Prints a JSON report on stdout.

Usage:
    uv run --script verify.py <file.xlsx> [--whitelist PATH] [--max-values N]

Exit codes:
    0  ok            every formula evaluated, no error, every function validated in Numbers
    1  errors_found  at least one formula evaluates to an error (#DIV/0!, #REF!, ...)
    2  needs_review  no error, but some functions are unknown to the engine
                     or not yet validated in Numbers
    3  failure       the file could not be read or computed
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import warnings
from pathlib import Path

os.environ.setdefault("TQDM_DISABLE", "1")
# formulas 1.3.x triggers SyntaxWarnings on first compile under Python 3.12+
warnings.filterwarnings("ignore", category=SyntaxWarning)

DEFAULT_WHITELIST = Path(__file__).resolve().parent.parent / "references" / "numbers-functions.md"
STRING_LITERAL = re.compile(r'"(?:[^"]|"")*"')
QUOTED_SHEET = re.compile(r"'(?:[^']|'')*'!")
FUNCTION_CALL = re.compile(r"\b((?:_XLFN\.|_XLWS\.)?[A-Z][A-Z0-9]*(?:\.[A-Z0-9]+)*)\s*\(")
ENGINE_KEY = re.compile(r"^'?\[(?P<book>.+?)\](?P<sheet>.+?)'?!(?P<cell>\$?[A-Z]+\$?[0-9]+)$")
ERROR_VALUES = {"#NULL!", "#DIV/0!", "#VALUE!", "#REF!", "#NAME?", "#NUM!", "#N/A", "#GETTING_DATA", "#SPILL!", "#CALC!"}


def formula_text(value) -> str | None:
    """Return the formula string of a cell value, or None if it is not a formula."""
    text = getattr(value, "text", value)  # openpyxl ArrayFormula exposes .text
    if isinstance(text, str) and text.startswith("="):
        return text
    return None


def functions_in(formula: str) -> list[str]:
    cleaned = STRING_LITERAL.sub('""', formula.upper())
    cleaned = QUOTED_SHEET.sub("X!", cleaned)
    names = []
    for raw in FUNCTION_CALL.findall(cleaned):
        name = raw.removeprefix("_XLFN.").removeprefix("_XLWS.")
        if name not in names:
            names.append(name)
    return names


def load_whitelist(path: Path) -> dict[str, str]:
    """Parse `| FUNCTION | status | notes |` rows. Missing file -> empty whitelist."""
    statuses: dict[str, str] = {}
    if not path.is_file():
        return statuses
    for line in path.read_text(encoding="utf-8").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) >= 2 and re.fullmatch(r"[A-Z][A-Z0-9.]*", cells[0]):
            statuses[cells[0]] = cells[1].lower()
    return statuses


def plain(value):
    """Convert engine values (numpy scalars, XlError) to JSON-friendly Python values."""
    if hasattr(value, "item"):
        value = value.item()
    text = str(value)
    if text in ERROR_VALUES:
        return text
    if isinstance(value, (int, float, str, bool)) or value is None:
        return value
    return text


def compute(path: Path, sheet_names: list[str]) -> dict[str, object]:
    import formulas  # imported late so TQDM_DISABLE applies

    by_upper = {name.upper(): name for name in sheet_names}
    model = formulas.ExcelModel().loads(str(path)).finish()
    solution = model.calculate()
    results: dict[str, object] = {}
    for key, ranges in solution.items():
        match = ENGINE_KEY.match(str(key))
        if not match:
            continue  # ranges such as A1:A9 and dangling #REF! nodes
        sheet = by_upper.get(match["sheet"].upper(), match["sheet"])
        cell = match["cell"].replace("$", "")
        raw = getattr(ranges, "value", ranges)
        try:
            raw = raw[0][0]
        except (TypeError, IndexError, KeyError):
            pass
        results[f"{sheet}!{cell}"] = plain(raw)
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("workbook", type=Path)
    parser.add_argument("--whitelist", type=Path, default=DEFAULT_WHITELIST)
    parser.add_argument("--max-values", type=int, default=100,
                        help="how many computed formula values to include (0 = none)")
    args = parser.parse_args()

    if not args.workbook.is_file():
        print(json.dumps({"status": "failure", "error": f"file not found: {args.workbook}"}))
        return 3

    import formulas
    import openpyxl

    supported = {name for name in formulas.get_functions() if isinstance(name, str)}
    whitelist = load_whitelist(args.whitelist)

    try:
        workbook = openpyxl.load_workbook(args.workbook, data_only=False)
    except Exception as exc:  # noqa: BLE001 - report any reader failure
        print(json.dumps({"status": "failure", "error": f"cannot read workbook: {exc}"}))
        return 3

    external_links = bool(getattr(workbook, "_external_links", []))
    formula_cells: list[tuple[str, str]] = []
    for sheet in workbook.worksheets:
        for row in sheet.iter_rows():
            for cell in row:
                text = formula_text(cell.value)
                if text:
                    formula_cells.append((f"{sheet.title}!{cell.coordinate}", text))

    try:
        computed = compute(args.workbook, workbook.sheetnames) if formula_cells else {}
    except Exception as exc:  # noqa: BLE001 - the engine raises many exception types
        print(json.dumps({"status": "failure", "error": f"formulas engine failed: {exc}"}))
        return 3

    errors, engine_unsupported, values = [], [], []
    not_validated: dict[str, list[str]] = {}
    for ref, text in formula_cells:
        names = functions_in(text)
        unknown = [n for n in names if n not in supported]
        value = computed.get(ref, "#NOT_COMPUTED")
        if unknown:
            engine_unsupported.append({"cell": ref, "formula": text, "functions": unknown})
        elif isinstance(value, str) and (value in ERROR_VALUES or value == "#NOT_COMPUTED"):
            errors.append({"cell": ref, "formula": text, "value": value})
        for name in names:
            if whitelist.get(name) != "validated":
                cells = not_validated.setdefault(name, [])
                if len(cells) < 5:
                    cells.append(ref)
        if len(values) < args.max_values:
            values.append({"cell": ref, "formula": text, "value": value})

    if errors:
        status, code = "errors_found", 1
    elif engine_unsupported or not_validated or external_links:
        status, code = "needs_review", 2
    else:
        status, code = "ok", 0

    report = {
        "file": str(args.workbook),
        "status": status,
        "formula_cells": len(formula_cells),
        "errors": errors,
        "engine_unsupported": engine_unsupported,
        "not_validated_in_numbers": {
            name: {"status": whitelist.get(name, "unlisted"), "cells": cells}
            for name, cells in sorted(not_validated.items())
        },
        "external_links": external_links,
        "values": values,
        "values_truncated": len(formula_cells) > len(values),
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return code


if __name__ == "__main__":
    sys.exit(main())
