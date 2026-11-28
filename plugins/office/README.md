# office

Office files without Microsoft or LibreOffice. Skill `xlsx-numbers`: read, write and verify .xlsx files viewed in
Apple Numbers.

## Install

```
/plugin install office --marketplace rlemaitre/claude-plugins
```

## Requirements

[uv](https://docs.astral.sh/uv/) (`brew install uv`). Each script is a standalone uv script that declares and pins its
Python dependencies (PEP 723 header, exact `==` pins). No shared virtualenv, no requirements file.

## Rules for scripts

- Scripts never modify their input file. Output goes to a new path; they refuse to overwrite an existing one.
- Do not name a script after a stdlib module (`inspect.py`, `json.py`...): `uv run --script` puts the script directory
  first on `sys.path`.

## Readable xlsx diffs in git

```bash
git config --global diff.xlsx.textconv \
  "uv run --quiet --script ~/Developer/workspace/03_projects/claude-plugins/repo/plugins/office/skills/xlsx-numbers/scripts/textconv.py"
echo '*.xlsx diff=xlsx' >> .gitattributes   # in each repo holding xlsx files
```

## Tests

```bash
uv run --script plugins/office/skills/xlsx-numbers/scripts/verify.py <file.xlsx>
uv run --script plugins/office/skills/xlsx-numbers/scripts/compat_test.py /tmp/compat.xlsx
```

Before committing a script change, run it on a real workbook and on `compat_test.py` output.
