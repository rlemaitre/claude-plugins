#!/usr/bin/env bash
# Keeps IntelliJ's .idea/ files out of Claude's commits. IntelliJ rewrites tracked .idea files on its own, so a
# worktree often has .idea changes nobody asked for. A commit may include an .idea file only when Claude edited it in
# this session, or when a user prompt in this session mentions ".idea".
# One script for three hooks, told apart by hook_event_name:
# - UserPromptSubmit: a prompt that mentions ".idea" allows every .idea file for the rest of the session
# - PostToolUse on Edit|Write|NotebookEdit: records the .idea files Claude edits
# - PreToolUse on Bash: blocks a git commit that would include any other .idea file
set -euo pipefail

input="$(cat)"
field() { jq -r "$1 // empty" <<<"${input}"; }

state="${XDG_CACHE_HOME:-${HOME}/.cache}/claude-idea-guard/$(field .session_id)"
allowed="${state}.allowed"
edited="${state}.edited"
mkdir -p "$(dirname "${state}")"

case "$(field .hook_event_name)" in
  UserPromptSubmit)
    if [[ "$(field .prompt)" == *.idea* ]]; then touch "${allowed}"; fi
    exit 0
    ;;
  PostToolUse)
    path="$(field '.tool_input.file_path // .tool_input.notebook_path')"
    if [[ "${path}" == */.idea/* ]]; then echo "${path}" >>"${edited}"; fi
    exit 0
    ;;
  PreToolUse) ;;
  *) exit 0 ;;
esac

# Quoted strings dropped, so a commit message saying "-a" or "git add ." is not read as a command.
cmd="$(field .tool_input.command | perl -0pe 's/"[^"]*"//g; s/\x27[^\x27]*\x27//g')"
[[ "${cmd}" =~ git[^\;\&\|]*\ commit ]] || exit 0
[[ -f "${allowed}" ]] && exit 0
top="$(git -C "$(field .cwd)" rev-parse --show-toplevel 2>/dev/null)" || exit 0

# What the commit would take: what is staged now, plus what a `commit -a` or a broad `git add` in the same command
# would stage before it.
candidates="$(git -C "${top}" diff --cached --name-only -- .idea)"
if [[ "${cmd}" =~ commit[^\;\&\|]*\ (-[a-zA-Z]*a[a-zA-Z]*|--all)(\ |$) ]]; then
  candidates+=$'\n'"$(git -C "${top}" diff --name-only -- .idea)"
fi
if [[ "${cmd}" =~ git\ add[^\;\&\|]*\ (-A|--all|-u|--update|\.|:/|\.idea[^\ ]*)(\ |$) ]]; then
  candidates+=$'\n'"$(git -C "${top}" diff --name-only -- .idea)"
  candidates+=$'\n'"$(git -C "${top}" ls-files --others --exclude-standard -- .idea)"
fi

blocked=()
while IFS= read -r file; do
  [[ -n "${file}" ]] || continue
  grep -qxF "${top}/${file}" "${edited}" 2>/dev/null || blocked+=("${file}")
done < <(sort -u <<<"${candidates}")
[[ ${#blocked[@]} -eq 0 ]] && exit 0

{
  echo "Blocked: this commit would include .idea files you did not edit in this session (IntelliJ changes them on its own):"
  printf '  %s\n' "${blocked[@]}"
  echo "Leave them out: stage your files by path in a separate command, and unstage these with git restore --staged."
  echo "Include them only if the user asks; their prompt must mention .idea."
} >&2
exit 2
