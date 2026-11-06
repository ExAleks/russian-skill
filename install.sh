#!/usr/bin/env bash
# install.sh — install the "always answer in Russian" rule for every tool.
# Usage:
#   ./install.sh                                 global install (skills + instruction files)
#   ./install.sh --force                         overwrite existing files (a .bak-<timestamp> copy is kept)
#   ./install.sh --list-only                     show what would be installed
#   ./install.sh --project-dir /path/to/project  also install project-level rules (Cursor, Windsurf, Cline)
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
rule_source="$repo/shared/language-rule.md"
begin_marker='<!-- russian-skill:begin -->'
end_marker='<!-- russian-skill:end -->'
home_dir="${HOME:?HOME is not set}"
FORCE=0
LIST_ONLY=0
PROJECT_DIR=""

usage() {
  cat <<'EOF'
Usage: ./install.sh [--force] [--list-only] [--project-dir PATH]

  --force              overwrite existing skill/rule files (a .bak-<timestamp> copy is kept)
  --list-only          show what would be installed, write nothing
  --project-dir PATH   also install project-level rules (Cursor, Windsurf, Cline)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --force) FORCE=1 ;;
    --list-only) LIST_ONLY=1 ;;
    --project-dir)
      [ $# -ge 2 ] || { echo "--project-dir requires a path" >&2; exit 1; }
      PROJECT_DIR="$2"
      shift
      ;;
    --project-dir=*) PROJECT_DIR="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

# OpenCode reads its config from $XDG_CONFIG_HOME/opencode when the variable is set.
config_home="${XDG_CONFIG_HOME:-$home_dir/.config}"
opencode_dir="$config_home/opencode"

backup_path() { # path
  local path="$1" stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  cp -R "$path" "$path.bak-$stamp"
  echo "backup: $path.bak-$stamp"
}

install_file() { # src dest label
  local src="$1" dest="$2" label="$3"
  if [ "$LIST_ONLY" = "1" ]; then
    echo "[dry-run] $label: $src -> $dest"
    return
  fi
  if [ -e "$dest" ]; then
    if [ "$FORCE" = "0" ]; then
      echo "skip $label: $dest already exists (use --force)" >&2
      return
    fi
    backup_path "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "installed $label: $dest"
}

install_dir() { # srcdir destdir label
  local srcdir="$1" destdir="$2" label="$3"
  if [ "$LIST_ONLY" = "1" ]; then
    echo "[dry-run] $label: $srcdir -> $destdir"
    return
  fi
  if [ -e "$destdir" ]; then
    if [ "$FORCE" = "0" ]; then
      echo "skip $label: $destdir already exists (use --force)" >&2
      return
    fi
    backup_path "$destdir"
  fi
  mkdir -p "$destdir"
  cp -R "$srcdir"/. "$destdir"/
  echo "installed $label: $destdir"
}

# Merge the language rule into an existing instruction file instead of replacing it.
# The block is wrapped in markers, so re-running the installer updates it in place
# and never duplicates it. Everything outside the markers is left untouched.
merge_rule_block() { # dest label
  local dest="$1" label="$2"
  if [ "$LIST_ONLY" = "1" ]; then
    echo "[dry-run] $label (merged block): $rule_source -> $dest"
    return
  fi
  [ -f "$rule_source" ] || { echo "missing rule source: $rule_source" >&2; exit 1; }

  local block_file out_file crlf=0
  if [ -e "$dest" ] && LC_ALL=C grep -q $'\r' "$dest"; then crlf=1; fi

  block_file="$(mktemp)"
  {
    printf '%s\n' "$begin_marker"
    cat "$rule_source"
    printf '%s\n' "$end_marker"
  } > "$block_file"

  # Keep the line endings of the target file so the diff stays clean.
  if [ "$crlf" = "1" ]; then
    awk 'BEGIN { ORS = "\r\n" } { sub(/\r$/, ""); print }' "$block_file" > "$block_file.crlf"
    mv "$block_file.crlf" "$block_file"
  fi

  mkdir -p "$(dirname "$dest")"

  if [ ! -e "$dest" ]; then
    cp "$block_file" "$dest"
    echo "created $label: $dest"
  elif grep -qF "$begin_marker" "$dest" && grep -qF "$end_marker" "$dest"; then
    out_file="$(mktemp)"
    awk -v b="$begin_marker" -v e="$end_marker" -v blockfile="$block_file" '
      { line = $0; sub(/\r$/, "", line) }
      line == b { while ((getline block_line < blockfile) > 0) print block_line; skip = 1; next }
      line == e { skip = 0; next }
      !skip { print }
    ' "$dest" > "$out_file"
    if cmp -s "$out_file" "$dest"; then
      echo "unchanged $label: $dest"
    else
      cat "$out_file" > "$dest"
      echo "updated $label: $dest"
    fi
    rm -f "$out_file"
  else
    # Keep the existing content and append the block below it.
    if [ -s "$dest" ]; then
      if [ -n "$(tail -c 1 "$dest")" ]; then
        printf '\n' >> "$dest"
      fi
      printf '\n' >> "$dest"
    fi
    cat "$block_file" >> "$dest"
    echo "merged $label: $dest (existing content preserved)"
  fi
  rm -f "$block_file"
}

# --- Claude Code (global skill) ---
install_dir "$repo/claude-code/russian" "$home_dir/.claude/skills/russian" "Claude Code skill"

# --- OpenCode (global skill + always-on AGENTS.md) ---
install_dir "$repo/opencode/russian" "$opencode_dir/skills/russian" "OpenCode skill"
merge_rule_block "$opencode_dir/AGENTS.md" "OpenCode AGENTS.md (always-on)"

# --- Codex CLI (global instruction) ---
merge_rule_block "$home_dir/.codex/AGENTS.md" "Codex CLI AGENTS.md"

# --- Gemini CLI (global instruction) ---
merge_rule_block "$home_dir/.gemini/GEMINI.md" "Gemini CLI GEMINI.md"

# --- Cline (global Custom Instructions hint) ---
echo "Cline global: paste cline/user-instructions.txt into Cline Settings -> Custom Instructions"

# --- Project-level rules: Cursor / Windsurf / Cline ---
if [ -n "$PROJECT_DIR" ]; then
  if [ ! -d "$PROJECT_DIR" ]; then
    echo "ProjectDir not found: $PROJECT_DIR" >&2
    exit 1
  fi
  install_file "$repo/cursor/.cursor/rules/russian.mdc" "$PROJECT_DIR/.cursor/rules/russian.mdc" "Cursor rule"
  install_file "$repo/windsurf/.windsurf/rules/russian.md" "$PROJECT_DIR/.windsurf/rules/russian.md" "Windsurf rule"
  install_file "$repo/cline/.clinerules/russian.md" "$PROJECT_DIR/.clinerules/russian.md" "Cline rule"
else
  echo "Project-level rules (Cursor, Windsurf, Cline): re-run with --project-dir /path/to/project"
fi

if [ "$LIST_ONLY" = "1" ]; then
  echo "dry run — nothing was written (remove --list-only to install)"
  exit 0
fi

# --- Verification: catch a wrong destination path instead of silently "succeeding" ---
failed=0
skill_file="$opencode_dir/skills/russian/SKILL.md"
if [ -f "$skill_file" ]; then
  echo "verify: OpenCode skill -> $skill_file"
else
  echo "verify: OpenCode skill is missing at $skill_file" >&2
  failed=1
fi
agents_file="$opencode_dir/AGENTS.md"
if [ -f "$agents_file" ] && grep -qF "$begin_marker" "$agents_file"; then
  echo "verify: OpenCode AGENTS.md -> $agents_file"
else
  echo "verify: language rule is missing in $agents_file" >&2
  failed=1
fi
[ "$failed" = "0" ] || exit 1
