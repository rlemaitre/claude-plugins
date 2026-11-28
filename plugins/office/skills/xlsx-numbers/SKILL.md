---
name: xlsx-numbers
description: Read, write and verify .xlsx workbooks that are viewed in Apple Numbers, without Excel or LibreOffice. Use for any .xlsx task on this machine - inspecting a workbook, adding or fixing formulas, building a sheet from data, checking formula results - and to generate Numbers compatibility tests.
---

# xlsx for Apple Numbers

The `.xlsx` file is the source of truth. Apple Numbers is only the viewer, on Mac and iPhone.
Formulas are written with `openpyxl` and checked with the `formulas` Python engine.
Nothing here needs Excel or LibreOffice.

All scripts are in `scripts/` next to this file. Run them with `uv run --script <path>`.
They declare and pin their own dependencies. The first run downloads numpy and scipy; later runs are fast.

## 1. Look before you touch

```bash
uv run --script scripts/inspect_workbook.py book.xlsx [--sheet NAME] [--rows 30]
```

The output lists sheets, sizes, header rows, and each formula next to its cached value.
`∅` means no cached value. That is normal for a file written by openpyxl, and for any file Numbers never exported.
To know what a formula evaluates to, run `verify.py` (step 3). Do not trust cached values.

## 2. Write

Write with `openpyxl`, then follow these rules.

**Never overwrite the input.**
- Save to a new file next to it. If the folder has a naming rule (for example `YYYY-MM-DD_topic_status.xlsx`), follow it.
- The only exception is a file tracked by git with no uncommitted changes (`git status --porcelain <file>` prints nothing). Then overwriting is fine, because git keeps the previous version.

**Formulas, not results.**
- Write `ws["B10"] = "=SUM(B2:B9)"`. Never write a total computed in Python.
- The sheet must recalculate in Numbers when an input changes.

**Function names and syntax.**
- Use English function names, commas as argument separators, and dots for decimals in formulas. That is how xlsx stores them, whatever the Numbers locale.
- Check every function against `references/numbers-functions.md` before using it:
  - `validated`: use freely.
  - `untested`: usable. List it in your report to the user so they can test it in Numbers.
  - `broken`, `avoid`: do not use. Find another formulation.
- Never use spilling array functions (`UNIQUE`, `FILTER`, `SORT`, `SORTBY`, `SEQUENCE`). openpyxl writes no spill metadata. Sort, filter and de-duplicate in Python and write the resulting cells.

**Data types.**
- Write dates as `datetime`, not as text. Write numbers as numbers.
- Set number formats with `cell.number_format`.

**Structure.**
- No links to other workbooks.
- No pivot tables.
- Keep one table per sheet, starting at A1 with a header row. Numbers maps that layout cleanly.

## 3. Verify every write that contains formulas

```bash
uv run --script scripts/verify.py new.xlsx
```

The script computes every formula in memory. It never modifies the file. It prints JSON and exits with:

| Exit | `status` | Meaning | What to do |
|---|---|---|---|
| 0 | `ok` | No error; all functions validated in Numbers | Done |
| 1 | `errors_found` | Some formulas evaluate to `#DIV/0!`, `#REF!`, `#NAME?`... | Fix and verify again. Never deliver with errors |
| 2 | `needs_review` | No error, but some functions are `untested`/unlisted, unknown to the engine, or the file links to other workbooks | Deliver, and tell the user which ones |
| 3 | `failure` | File unreadable or engine crash | Report the error; do not guess values |

- `values` lists computed results. Spot-check a few against the source data.
- A clean run proves that formulas *evaluate*, not that they are *right*.
- An error you introduced looks the same as one you inherited. To check, run `verify.py` on the original file.

**Known engine bugs.** The `formulas` engine is not Excel. Read the Notes column of `references/numbers-functions.md` before trusting a value for a function listed there. For example, `TRIM` keeps inner spaces, and `DATEDIF` with a lowercase unit returns `#NUM!`. When the engine and Excel disagree, Numbers is the judge.

## 4. Report

Tell the user:
- the file written and where;
- the `verify.py` status;
- every function that is not `validated`.

Do not describe the contents of a file they can open.

## Maintaining the function list

To test functions in Numbers:

```bash
uv run --script scripts/compat_test.py ~/Desktop/numbers-compat.xlsx [--only XLOOKUP,TEXTJOIN]
```

- The workbook has one row per function: the live formula (`Result`), the value Excel should give (`Expected`), and a `Check` column showing `OK`, `DIFF` or an error.
- The user opens it in Numbers on the Mac and on the iPhone, then tells you the outcome.
- Update `references/numbers-functions.md`: `validated` only when both devices show `OK`; note the Numbers versions.
- To test a new function, add a row to `CASES` in `compat_test.py`. If the engine is wrong for it, give the expected Excel value explicitly as a third tuple element.

## Round trips through Numbers

- Numbers does not edit an `.xlsx` in place. It imports it as a `.numbers` document.
- After any hand edit in Numbers, the user must use *File → Export To → Excel* over the source file. Otherwise the `.xlsx` and the Numbers copy diverge.
- If the user mentions editing in Numbers, ask whether they exported before you build on the `.xlsx`.
- Files under `~/Library/Mobile Documents/` (iCloud Drive) may not be downloaded yet. Run `brctl download <path>` before reading them.

## Readable git diffs

`scripts/textconv.py` prints one line per cell (formula or value), so a git diff shows what changed.

Setup, once per machine:

```bash
git config --global diff.xlsx.textconv "uv run --quiet --script <absolute path>/scripts/textconv.py"
```

Then add `*.xlsx diff=xlsx` to the repository's `.gitattributes`.
