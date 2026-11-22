# shellcheck shell=bash disable=SC2034 # sets variables for the bin/ws-* scripts
# Shared by bin/ws-*: config, slugs, worktree lookup, the Ghostty tab and IntelliJ. Sourced, not run.

die() { echo "$*" >&2; exit 1; }

# Accents stripped (é -> e) and ligatures expanded (œ -> oe) with perl: macOS iconv mangles both.
slugify() {
  printf '%s' "$1" |
    perl -CS -Mutf8 -MUnicode::Normalize -pe '$_ = NFD($_); s/\p{Mn}//g; s/Œ/OE/g; s/œ/oe/g; s/Æ/AE/g; s/æ/ae/g; s/ß/ss/g' |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' |
    cut -c1-100 |
    sed -E 's/-+$//'
}

# Relative entries of a space-separated list, made absolute against $1.
absolute() {
  local base="$1" paths=() word
  for word in $2; do
    if [[ "${word}" == /* ]]; then paths+=("${word}"); else paths+=("${base}/${word}"); fi
  done
  echo "${paths[*]-}"
}

# Sets TOP (this checkout), NOTES_DIR, BRIEFS_DIR, REVIEWS_DIR, REVIEW_RULES and EXTRA_DIRS, all absolute.
# Values come from the first .worktree-sessions file found walking up from the checkout. The file is read as
# KEY=value lines, never run, so a checked-in config cannot run commands.
load_config() {
  TOP="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Not in a git checkout"
  local common default dir="${TOP}" conf="" line key value
  common="$(git rev-parse --path-format=absolute --git-common-dir)"
  default="${common}/worktree-sessions"
  NOTES_DIR="${default}/notes" BRIEFS_DIR="${default}/briefs" REVIEWS_DIR="${default}/reviews"
  REVIEW_RULES="" EXTRA_DIRS=""

  while [[ "${dir}" != / ]]; do
    if [[ -f "${dir}/.worktree-sessions" ]]; then conf="${dir}/.worktree-sessions"; break; fi
    dir="$(dirname "${dir}")"
  done
  [[ -n "${conf}" ]] || return 0

  dir="$(dirname "${conf}")"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^([A-Z_]+)=(.*)$ ]] || continue
    key="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]}"
    if [[ "${value}" =~ ^\"(.*)\"$ || "${value}" =~ ^\'(.*)\'$ ]]; then value="${BASH_REMATCH[1]}"; fi
    case "${key}" in
      NOTES_DIR) NOTES_DIR="$(absolute "${dir}" "${value}")" ;;
      BRIEFS_DIR) BRIEFS_DIR="$(absolute "${dir}" "${value}")" ;;
      REVIEWS_DIR) REVIEWS_DIR="$(absolute "${dir}" "${value}")" ;;
      REVIEW_RULES) REVIEW_RULES="$(absolute "${dir}" "${value}")" ;;
      EXTRA_DIRS) EXTRA_DIRS="$(absolute "${dir}" "${value}")" ;;
    esac
  done <"${conf}"
}

# "<worktree path> <branch>" for every worktree on a branch.
worktrees() {
  git worktree list --porcelain | awk '/^worktree /{p=$2} /^branch /{sub("refs/heads/", "", $2); print p, $2}'
}

worktree_of() { worktrees | awk -v b="$1" '$2 == b {print $1}'; }

# `--add-dir <dir>` for each directory given, quoted for a shell command line.
add_dirs() {
  local d out=""
  for d in "$@"; do out+=" --add-dir $(printf '%q' "${d}")"; done
  echo "${out}"
}

# Runs $2 in a new Ghostty tab titled $3, in directory $1, when Claude runs inside Ghostty; prints it otherwise.
# The tab runs the command itself: typed as input into a starting shell, Claude would drop its prompt. An
# interactive login zsh gives the usual PATH, and a shell stays open when the command ends.
open_tab() {
  local dir="$1" cmd="$2" title="$3"
  if [[ "${TERM_PROGRAM:-}" != ghostty ]]; then
    echo "Run this in a terminal:"
    echo "  cd $(printf '%q' "${dir}") && ${cmd}"
    return 0
  fi
  osascript - "${dir}" "/bin/zsh -lic '${cmd//\'/\'\\\'\'}; exec zsh -l'" "${title}" <<'APPLESCRIPT' >/dev/null
on run argv
  tell application "Ghostty"
    set cfg to new surface configuration
    set initial working directory of cfg to item 1 of argv
    set command of cfg to item 2 of argv
    set t to new tab in front window with configuration cfg
    perform action ("set_tab_title:" & item 3 of argv) on focused terminal of t
  end tell
end run
APPLESCRIPT
  echo "Opened a new Ghostty tab: ${title}"
}

# IntelliJ on the given worktree and files, in the background. Skipped when the `idea` launcher is missing.
open_idea() {
  command -v idea >/dev/null || { echo "IntelliJ: no idea launcher on PATH, skipped"; return 0; }
  idea "$@" >/dev/null 2>&1 &
  echo "IntelliJ: opening $1"
}
