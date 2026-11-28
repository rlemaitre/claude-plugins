# Functions validated in Numbers

Status of each function when an `.xlsx` written by openpyxl is opened in Apple Numbers.
`verify.py` reads this table: only `validated` counts as safe.

Statuses:

- `validated`: tested OK in Numbers on Mac **and** iPhone (note the versions)
- `untested`: not tested yet; usable, but `verify.py` reports it as needing review
- `broken`: Numbers shows an error or a different result; do not use
- `avoid`: known problem with openpyxl-written files; do not use

Update procedure: generate a test workbook with `scripts/compat_test.py`, open it in Numbers on both devices, then change the status here.

| Function | Status | Notes |
|---|---|---|
| SUM | untested | |
| AVERAGE | untested | |
| MIN | untested | |
| MAX | untested | |
| COUNT | untested | |
| COUNTA | untested | |
| COUNTBLANK | untested | |
| COUNTIF | untested | |
| COUNTIFS | untested | |
| SUMIF | untested | |
| SUMIFS | untested | |
| AVERAGEIF | untested | |
| AVERAGEIFS | untested | |
| MAXIFS | untested | |
| MINIFS | untested | |
| ROUND | untested | |
| ROUNDUP | untested | |
| ROUNDDOWN | untested | |
| INT | untested | |
| MOD | untested | |
| ABS | untested | |
| IF | untested | |
| IFS | untested | |
| IFERROR | untested | |
| IFNA | untested | |
| AND | untested | |
| OR | untested | |
| NOT | untested | |
| SWITCH | untested | |
| VLOOKUP | untested | |
| HLOOKUP | untested | |
| INDEX | untested | |
| MATCH | untested | |
| XLOOKUP | untested | |
| XMATCH | untested | |
| CHOOSE | untested | |
| LEFT | untested | |
| RIGHT | untested | |
| MID | untested | |
| LEN | untested | |
| UPPER | untested | |
| LOWER | untested | |
| PROPER | untested | |
| TRIM | untested | engine bug: `formulas` keeps inner spaces, Excel collapses them; verify.py value is wrong |
| CONCAT | untested | |
| CONCATENATE | untested | |
| TEXTJOIN | untested | |
| SUBSTITUTE | untested | |
| FIND | untested | |
| SEARCH | untested | |
| TEXT | untested | |
| VALUE | untested | |
| DATE | untested | |
| YEAR | untested | |
| MONTH | untested | |
| DAY | untested | |
| EOMONTH | untested | |
| EDATE | untested | |
| DATEDIF | untested | engine bug: lowercase unit ("d") gives #NUM!; write units in uppercase ("D") |
| NETWORKDAYS | untested | |
| WEEKDAY | untested | |
| SUMPRODUCT | untested | |
| MEDIAN | untested | |
| STDEV.S | untested | |
| PMT | untested | |
| FV | untested | |
| NPV | untested | |
| ISBLANK | untested | |
| ISNUMBER | untested | |
| UNIQUE | avoid | spilling array: openpyxl writes no spill metadata |
| FILTER | avoid | spilling array: openpyxl writes no spill metadata |
| SORT | avoid | spilling array: openpyxl writes no spill metadata |
| SORTBY | avoid | spilling array: openpyxl writes no spill metadata |
| SEQUENCE | avoid | spilling array: openpyxl writes no spill metadata |
| LET | avoid | not tested; Numbers support uncertain |
| LAMBDA | avoid | not tested; Numbers support uncertain |
