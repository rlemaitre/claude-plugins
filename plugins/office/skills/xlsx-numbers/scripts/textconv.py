# /// script
# requires-python = ">=3.11"
# dependencies = ["openpyxl==3.1.5"]
# ///
"""Dump an .xlsx as stable text, one cell per line, for `git diff`.

Formulas are shown as written; constants are shown with their Python repr.

Git setup (once per machine):
    git config --global diff.xlsx.textconv "uv run --quiet --script /path/to/textconv.py"
and in the repository's .gitattributes:
    *.xlsx diff=xlsx
"""

from __future__ import annotations

import sys

import openpyxl


def render(value) -> str:
    text = getattr(value, "text", None)  # ArrayFormula
    if isinstance(text, str):
        return f"{text}  [array]"
    if isinstance(value, str) and value.startswith("="):
        return value
    return repr(value)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: textconv.py <file.xlsx>", file=sys.stderr)
        return 2
    workbook = openpyxl.load_workbook(sys.argv[1], data_only=False)
    for sheet in workbook.worksheets:
        print(f"## {sheet.title}  [{sheet.dimensions}]")
        for row in sheet.iter_rows():
            for cell in row:
                if cell.value is not None:
                    print(f"{sheet.title}!{cell.coordinate}\t{render(cell.value)}")
        for merged in sorted(str(r) for r in sheet.merged_cells.ranges):
            print(f"{sheet.title}!merged\t{merged}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
