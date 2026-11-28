# /// script
# requires-python = ">=3.11"
# dependencies = ["openpyxl==3.1.5", "formulas==1.3.4"]
# ///
"""Build a workbook that tests functions in Numbers (Mac and iPhone).

Each row holds a live formula (Result) and the value the `formulas` engine
computed for it (Expected, static). Open the file in Numbers: Check shows OK,
DIFF or an error. Report the outcome in references/numbers-functions.md.

Usage:
    uv run --script compat_test.py <output.xlsx> [--only FUNC,FUNC,...]
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from datetime import datetime
from pathlib import Path

import openpyxl

sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify import compute  # noqa: E402

D = "Data!"
# (function, formula) or (function, formula, expected) when the engine is known
# to disagree with Excel; the explicit value is the Excel result.
CASES: list[tuple] = [
    ("SUM", f"SUM({D}A1:A5)"),
    ("AVERAGE", f"AVERAGE({D}A1:A5)"),
    ("MIN", f"MIN({D}A1:A5)"),
    ("MAX", f"MAX({D}A1:A5)"),
    ("COUNT", f"COUNT({D}A1:B5)"),
    ("COUNTA", f"COUNTA({D}A1:B5)"),
    ("COUNTBLANK", f"COUNTBLANK({D}A1:A7)"),
    ("COUNTIF", f'COUNTIF({D}C1:C5,"x")'),
    ("COUNTIFS", f'COUNTIFS({D}C1:C5,"x",{D}A1:A5,">15")'),
    ("SUMIF", f'SUMIF({D}C1:C5,"x",{D}A1:A5)'),
    ("SUMIFS", f'SUMIFS({D}A1:A5,{D}C1:C5,"y",{D}A1:A5,">25")'),
    ("AVERAGEIF", f'AVERAGEIF({D}C1:C5,"x",{D}A1:A5)'),
    ("AVERAGEIFS", f'AVERAGEIFS({D}A1:A5,{D}C1:C5,"x",{D}A1:A5,">10")'),
    ("MAXIFS", f'MAXIFS({D}A1:A5,{D}C1:C5,"y")'),
    ("MINIFS", f'MINIFS({D}A1:A5,{D}C1:C5,"x")'),
    ("ROUND", "ROUND(3.14159,2)"),
    ("ROUNDUP", "ROUNDUP(3.141,1)"),
    ("ROUNDDOWN", "ROUNDDOWN(3.19,1)"),
    ("INT", "INT(-3.5)"),
    ("MOD", "MOD(-7,3)"),
    ("ABS", "ABS(-5)"),
    ("IF", f'IF({D}A1>5,"big","small")'),
    ("IFS", f'IFS({D}A1>40,"a",{D}A1>5,"b",TRUE,"c")'),
    ("IFERROR", 'IFERROR(1/0,"err")'),
    ("IFNA", 'IFNA(NA(),"na")'),
    ("AND", f"AND(TRUE,{D}A1>5)"),
    ("OR", f"OR(FALSE,{D}A1<5)"),
    ("NOT", "NOT(FALSE)"),
    ("SWITCH", f'SWITCH({D}C2,"x",1,"y",2,0)'),
    ("VLOOKUP", f"VLOOKUP(30,{D}A1:B5,2,FALSE)"),
    ("HLOOKUP", f'HLOOKUP("b",{D}F1:H2,2,FALSE)'),
    ("INDEX", f"INDEX({D}B1:B5,4)"),
    ("MATCH", f"MATCH(40,{D}A1:A5,0)"),
    ("XLOOKUP", f"XLOOKUP(40,{D}A1:A5,{D}B1:B5)"),
    ("XMATCH", f"XMATCH(40,{D}A1:A5)"),
    ("CHOOSE", 'CHOOSE(2,"a","b","c")'),
    ("LEFT", f"LEFT({D}B2,3)"),
    ("RIGHT", f"RIGHT({D}B2,2)"),
    ("MID", f"MID({D}B2,2,3)"),
    ("LEN", f"LEN({D}B2)"),
    ("UPPER", f"UPPER({D}B1)"),
    ("LOWER", 'LOWER("MiXeD")'),
    ("PROPER", 'PROPER("hello world")'),
    ("TRIM", f"TRIM({D}E1)", "hello world"),  # engine keeps inner spaces
    ("CONCAT", f'CONCAT({D}B1,"-",{D}B2)'),
    ("CONCATENATE", 'CONCATENATE("a","b")'),
    ("TEXTJOIN", f'TEXTJOIN(",",TRUE,{D}B1:B3)'),
    ("SUBSTITUTE", f'SUBSTITUTE({D}B2,"a","o")'),
    ("FIND", f'FIND("an",{D}B2)'),
    ("SEARCH", f'SEARCH("AN",{D}B2)'),
    ("TEXT", f'TEXT({D}A1,"0.00")'),
    ("VALUE", 'VALUE("42")'),
    ("DATE", "MONTH(DATE(2026,2,30))"),
    ("YEAR", f"YEAR({D}D1)"),
    ("MONTH", f"MONTH({D}D2)"),
    ("DAY", f"DAY({D}D2)"),
    ("EOMONTH", f"DAY(EOMONTH({D}D2,0))"),
    ("EDATE", f"DAY(EDATE({D}D1,1))"),
    ("DATEDIF", f'DATEDIF({D}D1,{D}D2,"D")'),  # engine rejects lowercase units
    ("NETWORKDAYS", f"NETWORKDAYS({D}D1,{D}D2)"),
    ("WEEKDAY", f"WEEKDAY({D}D1)"),
    ("SUMPRODUCT", f"SUMPRODUCT({D}A1:A5,{D}A1:A5)"),
    ("MEDIAN", f"MEDIAN({D}A1:A5)"),
    ("STDEV.S", f"ROUND(STDEV.S({D}A1:A5),6)"),
    ("PMT", "ROUND(PMT(0.05/12,240,-200000),2)"),
    ("FV", "ROUND(FV(0.04/12,120,-100),2)"),
    ("NPV", "ROUND(NPV(0.1,-100,50,60,70),4)"),
    ("ISBLANK", f"ISBLANK({D}A7)"),
    ("ISNUMBER", f"ISNUMBER({D}A1)"),
]


def fill_data(ws) -> None:
    for i, (n, fruit, cat) in enumerate(zip([10, 20, 30, 40, 50],
                                            ["apple", "banana", "cherry", "date", "elder"],
                                            ["x", "y", "x", "y", "x"]), start=1):
        ws.cell(i, 1, n)
        ws.cell(i, 2, fruit)
        ws.cell(i, 3, cat)
    ws["D1"] = datetime(2026, 1, 31)
    ws["D2"] = datetime(2026, 3, 15)
    ws["E1"] = "  hello   world  "
    for col, (label, value) in zip("FGH", [("a", 1), ("b", 2), ("c", 3)]):
        ws[f"{col}1"] = label
        ws[f"{col}2"] = value


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--only", help="comma-separated function names")
    args = parser.parse_args()

    if args.output.exists():
        print(f"refusing to overwrite {args.output}", file=sys.stderr)
        return 1
    wanted = {f.strip().upper() for f in args.only.split(",")} if args.only else None
    cases = [c for c in CASES if wanted is None or c[0] in wanted]
    overrides = {row: c[2] for row, c in enumerate(cases, start=2) if len(c) > 2}
    if not cases:
        print("no matching test case", file=sys.stderr)
        return 1

    wb = openpyxl.Workbook()
    tests = wb.active
    tests.title = "Tests"
    fill_data(wb.create_sheet("Data"))
    tests.append(["Function", "Formula", "Result", "Expected", "Check"])
    for row, (name, formula, *_) in enumerate(cases, start=2):
        tests.append([name, formula, f"={formula}", None, f'=IF(C{row}=D{row},"OK","DIFF")'])
    last = len(cases) + 1
    tests["G1"] = "OK"
    tests["H1"] = f'=COUNTIF(E2:E{last},"OK")&" / {len(cases)}"'

    with tempfile.TemporaryDirectory() as tmp:
        draft = Path(tmp) / "draft.xlsx"
        wb.save(draft)
        computed = compute(draft, wb.sheetnames)

    for row in range(2, last + 1):
        value = overrides.get(row, computed.get(f"Tests!C{row}", "#NOT_COMPUTED"))
        tests.cell(row, 4, value)
    for col, width in zip("ABCDE", [14, 52, 16, 16, 8]):
        tests.column_dimensions[col].width = width

    args.output.parent.mkdir(parents=True, exist_ok=True)
    wb.save(args.output)
    print(f"{len(cases)} cases written to {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
