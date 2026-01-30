#!/usr/bin/env bash
set -euo pipefail

# Best-effort redaction / secret scan (lightweight).
# This is NOT a full security audit, but it catches common accidents.

cd "$(dirname "$0")/.."

fail=0

RG_IGNORE_GIT=(-g '!**/.git/**')

check() {
  local pattern=$1
  local label=$2
  if rg -n --hidden --no-ignore-vcs -S "$pattern" . "${RG_IGNORE_GIT[@]}" >/dev/null 2>&1; then
    echo "[FAIL] Found potential secret pattern: $label ($pattern)" >&2
    rg -n --hidden --no-ignore-vcs -S "$pattern" . "${RG_IGNORE_GIT[@]}" | sed -n '1,120p' >&2
    fail=1
  else
    echo "[OK]   $label"
  fi
}

# Common API key prefixes
check "sk-[A-Za-z0-9]{20,}" "OpenAI-style sk-* tokens"
check "xox[baprs]-[A-Za-z0-9-]{10,}" "Slack token patterns"
check "AIza[0-9A-Za-z\-_]{30,}" "Google API key patterns"
# NOTE: The patterns below are WARNING-only (they catch docs/strings, not actual secrets).
warn_only() {
  local pattern=$1
  local label=$2
  if rg -n --hidden --no-ignore-vcs -S "$pattern" . "${RG_IGNORE_GIT[@]}" >/dev/null 2>&1; then
    echo "[WARN] Found sensitive-keyword mention: $label ($pattern)" >&2
    rg -n --hidden --no-ignore-vcs -S "$pattern" . "${RG_IGNORE_GIT[@]}" | sed -n '1,40p' >&2
  else
    echo "[OK]   $label"
  fi
}

warn_only "(?i)anthropic.*(sk|key)" "Anthropic key mention"
warn_only "(?i)telegram.*bot.*token" "Telegram bot token mention"
warn_only "(?i)password\s*[:=]" "Password assignments (heuristic)"

# Personal identifiers (heuristics) — examples in docs are common; treat as WARN.
warn_only "\+?[0-9]{11,15}" "Phone-number-like strings (heuristic)"
warn_only "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "Email-like strings (heuristic)"
warn_only "192\.168\.[0-9.]+" "Private LAN IPs (heuristic)"

if [[ $fail -ne 0 ]]; then
  echo "\nRedaction check FAILED. Remove secrets/PII before publishing." >&2
  exit 1
fi

echo "\nRedaction check PASSED. (Still review manually before publishing.)"
