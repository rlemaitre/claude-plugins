#!/usr/bin/env bash
# Compares each copied plugin with its upstream folder by git tree hash, so only a real content change counts.
# Metadata in plugins/<name>/.upstream: repo, path (`.` for a plugin that is the whole repository), tree (the upstream
# tree hash the copy was made from).
# Exit 0: all up to date. Exit 10: at least one plugin changed upstream. Exit 1: GitHub could not be read.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GH_BIN="${GH_BIN:-gh}"
changed=0

for meta in "$ROOT"/plugins/*/.upstream; do
  name="$(basename "$(dirname "$meta")")"
  repo="$(sed -n 's/^repo=//p' "$meta")"
  path="$(sed -n 's/^path=//p' "$meta")"
  tree="$(sed -n 's/^tree=//p' "$meta")"
  if [[ "$path" == "." ]]; then
    # The plugin is the whole repository: the contents API cannot name the root, so read the head commit's tree.
    latest="$("$GH_BIN" api "repos/$repo/commits/HEAD" --jq ".commit.tree.sha")"
    link="https://github.com/$repo/commits/HEAD"
  else
    parent="$(dirname "$path")"; [[ "$parent" == "." ]] && parent=""
    latest="$("$GH_BIN" api "repos/$repo/contents/$parent" --jq ".[] | select(.name == \"$(basename "$path")\") | .sha")"
    link="https://github.com/$repo/commits/HEAD/$path"
  fi
  if [[ -z "$latest" ]]; then
    echo "$name: could not read the upstream folder $repo/$path" >&2
    exit 1
  fi
  if [[ "$latest" == "$tree" ]]; then
    echo "$name: up to date (tree ${tree:0:7})"
  else
    echo "$name: upstream tree ${latest:0:7}, copy ${tree:0:7} ($link)"
    changed=1
  fi
done

if [[ $changed -eq 1 ]]; then exit 10; fi
