#!/usr/bin/env bash
set -euo pipefail

# Minimal bootstrapper to enable:
#   curl -fsSL <raw>/bootstrap.sh | bash
#
# It clones the repo (https) to a temp dir and runs install.sh.

REPO_HTTPS_DEFAULT="https://github.com/FFatTiger/Clawdbot-Mac-Installer.git"
REF_DEFAULT="main"

usage() {
  cat <<'USAGE'
Usage:
  curl -fsSL https://raw.githubusercontent.com/FFatTiger/Clawdbot-Mac-Installer/main/bootstrap.sh | bash -s -- [options]

Options:
  --lang zh|en        Force installer language (optional)
  --ref <git-ref>     Git ref/branch/tag to install from (default: main)
  --repo <https-url>  Repo HTTPS URL (default: upstream)
  --dir <path>        Clone into this directory (default: temp dir)
  --no-cleanup        Keep the cloned directory (for debugging)
  -h, --help          Show help
USAGE
}

LANG_ARG=""
REF="$REF_DEFAULT"
REPO_HTTPS="$REPO_HTTPS_DEFAULT"
CLONE_DIR=""
NO_CLEANUP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lang) LANG_ARG=${2:-}; shift 2;;
    --ref) REF=${2:-}; shift 2;;
    --repo) REPO_HTTPS=${2:-}; shift 2;;
    --dir) CLONE_DIR=${2:-}; shift 2;;
    --no-cleanup) NO_CLEANUP=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2;;
  esac
done

# macOS only (this project is macOS-first due to permissions + iMessage)
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[ERR ] This installer is for macOS only." >&2
  exit 1
fi

# Reminder only (no hard enforcement):
# - Please run on the target Mac in a local terminal (not SSH).
# - macOS permission prompts (Full Disk Access / Automation) require local interaction.

if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
  echo "[WARN] SSH environment detected. macOS permission prompts may not work over SSH." >&2
fi

echo "[INFO] Reminder: run this installer on the target Mac in a local terminal (not SSH)." >&2

# deps
for bin in curl git; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "[ERR ] Missing dependency: $bin" >&2
    exit 4
  fi
done

if [[ -z "$CLONE_DIR" ]]; then
  CLONE_DIR="$(mktemp -d -t clawdbot-mac-installer.XXXXXX)"
fi

cleanup() {
  if [[ "$NO_CLEANUP" == "true" ]]; then
    echo "[INFO] Keeping directory: $CLONE_DIR" >&2
    return 0
  fi
  rm -rf "$CLONE_DIR" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "[INFO] Cloning: $REPO_HTTPS (ref: $REF)" >&2
if [[ -d "$CLONE_DIR/.git" ]]; then
  (cd "$CLONE_DIR" && git fetch --all --tags && git checkout "$REF" && git pull --ff-only) 
else
  git clone --depth 1 --branch "$REF" "$REPO_HTTPS" "$CLONE_DIR"
fi

cd "$CLONE_DIR"
chmod +x install.sh install.zh.sh install.en.sh >/dev/null 2>&1 || true

# Run installer
# If /dev/tty is available, attach stdin to it so prompts work even under curl|bash.
if [[ -r /dev/tty ]]; then
  if [[ -n "$LANG_ARG" ]]; then
    exec ./install.sh --lang "$LANG_ARG" < /dev/tty
  else
    exec ./install.sh < /dev/tty
  fi
else
  echo "[WARN] /dev/tty is not readable. Interactive prompts may not work in this environment." >&2
  if [[ -n "$LANG_ARG" ]]; then
    exec ./install.sh --lang "$LANG_ARG"
  else
    exec ./install.sh
  fi
fi
