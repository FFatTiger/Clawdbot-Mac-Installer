#!/usr/bin/env bash
set -euo pipefail

# Minimal, dependency-free UI helpers (no whiptail required).

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
info() { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
err()  { printf "[ERR ] %s\n" "$*"; }

confirm() {
  # confirm "Question?"  (returns 0=yes, 1=no)
  local prompt=${1:-""}
  local ans

  if [[ -z "$prompt" ]]; then
    if declare -F t >/dev/null 2>&1; then
      prompt="$(t CONFIRM_DEFAULT)"
    else
      prompt="Continue?"
    fi
  fi

  while true; do
    read -r -p "$prompt [y/N]: " ans || true
    case "${ans:-}" in
      y|Y|yes|YES) return 0;;
      n|N|no|NO|"") return 1;;
      *)
        if declare -F t >/dev/null 2>&1; then
          echo "$(t CONFIRM_PLEASE)"
        else
          echo "Please answer y or n."
        fi
        ;;
    esac
  done
}

ask() {
  # ask VAR "Prompt" [default]
  local __var=$1
  local prompt=$2
  local def=${3:-}
  local ans
  if [[ -n "$def" ]]; then
    read -r -p "$prompt [$def]: " ans || true
    ans=${ans:-$def}
  else
    read -r -p "$prompt: " ans || true
  fi
  printf -v "$__var" '%s' "$ans"
}

pause() {
  local msg="Press ENTER to continue..."
  if declare -F t >/dev/null 2>&1; then
    msg="$(t PRESS_ENTER)"
  fi
  read -r -p "$msg" _ || true
}
