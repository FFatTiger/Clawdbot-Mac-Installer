#!/usr/bin/env bash
set -euo pipefail

# Network preflight: DNS + HTTPS reachability to Google and Telegram.
# Exits non-zero if either check fails.

curl_ok() {
  local url=$1
  curl -fsSL --max-time 8 --connect-timeout 5 "$url" >/dev/null
}

# Basic DNS sanity
if ! command -v dig >/dev/null 2>&1; then
  # dig not guaranteed; use scutil as fallback.
  :
fi

# Google (generate_204 is tiny and reliable)
if ! curl_ok "https://www.google.com/generate_204"; then
  echo "Google connectivity check failed: https://www.google.com/generate_204" >&2
  exit 2
fi

# Telegram (use api endpoint because telegram.org may be blocked differently)
if ! curl_ok "https://api.telegram.org"; then
  echo "Telegram connectivity check failed: https://api.telegram.org" >&2
  exit 3
fi

echo "OK"
