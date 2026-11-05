#!/usr/bin/env bash
# install.sh — install the "always answer in Russian" rule for every tool.
# Usage:
#   ./install.sh                                 global install (skills + instruction files)
#   ./install.sh --force                         overwrite existing files
#   ./install.sh --list-only                     show what would be installed
#   ./install.sh --project-dir /path/to/project  also install project-level rules (Cursor, Windsurf, Cline)
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
FORCE=0
LIST_ONLY=0
PROJECT_DIR=""

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --list-only) LIST_ONLY=1 ;;
    --project-dir) shift_next=1 ;;
    *) if [ "${shift_next:-0}" = "1" ]; then PROJECT_DIR="$arg"; shift_next=0; else echo "unknown option: $arg" >&2; exit 1; fi ;;
  esac
done

install_file() { # src dest label
  local src="$1" dest="$2" label="$3"
  if [ "$LIST_ONLY" = "1" ]; then
    echo "[dry-run] $label: $src -> $dest"
    return
  fi
  if [ -e "$dest" ] && [ "$FORCE" = "0" ]; then
    echo "skip $label: $dest already exists (use --force)" >&2
    return
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
  if [ -e "$destdir" ] && [ "$FORCE" = "0" ]; then
    echo "skip $label: $destdir already exists (use --force)" >&2
    return
  fi
  mkdir -p "$destdir"
  cp -R "$srcdir"/. "$destdir"/
  echo "installed $label: $destdir"
}

# --- Claude Code (global skill) ---
install_dir "$repo/claude-code/russian" "$HOME/.claude/skills/russian" "Claude Code skill"

# --- OpenCode (global skill + always-on AGENTS.md) ---
install_dir "$repo/opencode/russian" "$HOME/.config/opencode/skill/russian" "OpenCode skill"
install_file "$repo/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md" "OpenCode AGENTS.md (always-on)"

# --- Codex CLI (global instruction) ---
install_file "$repo/codex/AGENTS.md" "$HOME/.codex/AGENTS.md" "Codex CLI AGENTS.md"

# --- Gemini CLI (global instruction) ---
install_file "$repo/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md" "Gemini CLI GEMINI.md"

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

if [ "$LIST_ONLY" = "1" ]; then echo "dry run — nothing was written (remove --list-only to install)"; fi
