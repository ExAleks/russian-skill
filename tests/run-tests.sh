#!/usr/bin/env bash
# Smoke tests for install.sh.
# They exist to catch the regressions that actually bit users:
#   - a wrong destination path (e.g. "skill" instead of "skills")
#   - an existing AGENTS.md being replaced instead of extended
#   - the rule block being duplicated on re-run
set -uo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
installer="$repo/install.sh"
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ok() { echo "ok: $1"; }
bad() { echo "FAIL: $1" >&2; fail=1; }

check_file() { # label path
  if [ -f "$2" ]; then ok "$1"; else bad "$1 ($2 missing)"; fi
}

check_contains() { # label needle path
  if grep -qF "$2" "$3" 2>/dev/null; then ok "$1"; else bad "$1 (\"$2\" not found in $3)"; fi
}

check_count() { # label needle path expected
  local count
  count="$(grep -cF "$2" "$3" 2>/dev/null || true)"
  if [ "$count" = "$4" ]; then ok "$1"; else bad "$1 (expected $4, got ${count:-0})"; fi
}

run_install() { # [args...]
  if ! XDG_CONFIG_HOME="" HOME="$home" "$installer" "$@" >/dev/null 2>&1; then
    bad "install.sh exited non-zero ($*)"
  fi
}

new_home() { # name -> sets $home
  home="$tmp/$1"
  mkdir -p "$home/.config/opencode"
}

# --- existing AGENTS.md must be extended, not replaced -----------------------
new_home existing
printf '# My own rules\n\n- keep me\n' > "$home/.config/opencode/AGENTS.md"

run_install
check_file "OpenCode skill installed" "$home/.config/opencode/skills/russian/SKILL.md"
check_contains "user content preserved" "keep me" "$home/.config/opencode/AGENTS.md"
check_contains "language rule added" "API, deploy, merge, pull request" "$home/.config/opencode/AGENTS.md"
check_count "rule block appears once" "<!-- russian-skill:begin -->" "$home/.config/opencode/AGENTS.md" 1

if [ -d "$home/.config/opencode/skill" ]; then
  bad "singular 'skill' directory was created"
fi

# --- re-running must not duplicate the block --------------------------------
run_install
check_count "no duplicate block on re-run" "<!-- russian-skill:begin -->" "$home/.config/opencode/AGENTS.md" 1

# --- CRLF files are handled too ---------------------------------------------
new_home crlf
printf '# My own rules\r\n\r\n- keep me\r\n' > "$home/.config/opencode/AGENTS.md"
run_install
run_install
check_contains "CRLF: user content preserved" "keep me" "$home/.config/opencode/AGENTS.md"
check_count "CRLF: no duplicate block" "<!-- russian-skill:begin -->" "$home/.config/opencode/AGENTS.md" 1

# --- file without a trailing newline ---------------------------------------
new_home no-eol
printf '# My own rules\n- keep me' > "$home/.config/opencode/AGENTS.md"
run_install
check_contains "no-EOL: user content preserved" "keep me" "$home/.config/opencode/AGENTS.md"
check_count "no-EOL: block appears once" "<!-- russian-skill:begin -->" "$home/.config/opencode/AGENTS.md" 1

# --- fresh home: AGENTS.md is created ---------------------------------------
new_home fresh
run_install
check_file "fresh: AGENTS.md created" "$home/.config/opencode/AGENTS.md"
check_count "fresh: block appears once" "<!-- russian-skill:begin -->" "$home/.config/opencode/AGENTS.md" 1

# --- XDG_CONFIG_HOME is respected ------------------------------------------
home="$tmp/xdg"
mkdir -p "$home"
XDG_CONFIG_HOME="$home/cfg" HOME="$home" "$installer" >/dev/null 2>&1 || bad "install.sh failed with XDG_CONFIG_HOME"
check_file "XDG: skill installed under XDG_CONFIG_HOME" "$home/cfg/opencode/skills/russian/SKILL.md"

if [ "$fail" = "0" ]; then
  echo "all tests passed"
else
  echo "tests failed" >&2
  exit 1
fi
