#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ui.sh
source "$ROOT_DIR/lib/ui.sh"

ENV_FILE="$HOME/.clawdbot/.env"

ensure_env_file() {
  mkdir -p "$HOME/.clawdbot"
  (umask 077 && touch "$ENV_FILE")
  chmod 600 "$ENV_FILE" 2>/dev/null || true
}

set_env_var() {
  # set_env_var KEY VALUE  (idempotent)
  local key=$1
  local val=$2
  ensure_env_file

  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    # macOS sed requires an explicit backup suffix
    sed -i '' -E "s|^${key}=.*$|${key}=${val}|" "$ENV_FILE"
  else
    printf "%s=%s\n" "$key" "$val" >> "$ENV_FILE"
  fi
}

require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This installer is for macOS only.";
    exit 1
  fi
}

require_local_terminal() {
  bold "Step 0/5 — Local Terminal requirement"
  info "This setup needs macOS permission grants (Full Disk Access / Automation)."
  info "Do NOT run over SSH. Please run inside Terminal.app on the target Mac."

  # Heuristic detection
  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
    warn "SSH environment detected (SSH_CONNECTION/SSH_TTY is set)."
  fi

  if ! confirm "Are you running this in the local Terminal app on this Mac (NOT SSH)?"; then
    err "Aborting. Re-run locally in Terminal.app."
    exit 2
  fi
}

preflight_network() {
  bold "Step 1/5 — Network preflight"
  info "Checking reachability to Google + Telegram..."

  if "$ROOT_DIR/scripts/network_check.sh" >/dev/null 2>&1; then
    info "Network OK."
  else
    warn "Network check failed. This may break onboarding/login flows."
    warn "You can still continue if you know what you’re doing."
    if ! confirm "Continue anyway?"; then
      exit 3
    fi
  fi
}

install_clawdbot_cli() {
  bold "Step 2/5 — Install / verify Clawdbot CLI"

  if command -v clawdbot >/dev/null 2>&1; then
    info "clawdbot already installed: $(clawdbot --version)"
    return 0
  fi

  warn "clawdbot not found. Installing via official installer: https://clawd.bot/install.sh"
  info "This will install Node (if needed) and the clawdbot CLI."

  if ! confirm "Proceed with installing clawdbot CLI now?"; then
    err "Cannot continue without clawdbot."
    exit 4
  fi

  curl -fsSL https://clawd.bot/install.sh | bash

  if ! command -v clawdbot >/dev/null 2>&1; then
    err "Install finished but clawdbot not on PATH. Open a new terminal and re-run."
    exit 5
  fi

  info "Installed: $(clawdbot --version)"
}

collect_workspace_and_seed() {
  bold "Step 3/5 — Workspace + defaults (no channels yet)"

  ask WORKSPACE "Choose agent workspace directory" "~/clawd"

  info "Seeding workspace + baseline config (no channels, no skills yet)..."
  clawdbot setup --workspace "$WORKSPACE" || true

  info "Workspace is set to: $WORKSPACE"

  if confirm "Apply recommended default MD files (SOUL/USER/TOOLS) into the workspace?"; then
    local user_name user_callme user_tz
    ask user_name "Your name" ""
    ask user_callme "What should the assistant call you" ""
    ask user_tz "Your timezone" "Asia/Shanghai"

    mkdir -p "$WORKSPACE"

    # Simple template substitution
    local soul_tpl="$ROOT_DIR/templates/workspace-defaults/SOUL.md.tpl"
    local user_tpl="$ROOT_DIR/templates/workspace-defaults/USER.md.tpl"
    local tools_tpl="$ROOT_DIR/templates/workspace-defaults/TOOLS.md.tpl"

    cp "$soul_tpl" "$WORKSPACE/SOUL.md"

    sed -e "s/{{USER_NAME}}/${user_name//\//\\/}/g" \
        -e "s/{{USER_CALLME}}/${user_callme//\//\\/}/g" \
        -e "s/{{USER_TIMEZONE}}/${user_tz//\//\\/}/g" \
        "$user_tpl" > "$WORKSPACE/USER.md"

    cp "$tools_tpl" "$WORKSPACE/TOOLS.md"

    info "Wrote defaults: $WORKSPACE/SOUL.md, USER.md, TOOLS.md"
  fi
}

configure_model_provider() {
  bold "Step 4/6 — Model provider + API configuration"
  info "We will NOT configure chat channels yet. First we set up model auth + default model."

  cat <<'TXT'
Choose a provider:
  1) OpenAI (official API key)
  2) Anthropic (official API key)
  3) Google Gemini (API key)
  4) OpenAI-compatible (custom baseUrl; Completions or Responses)
  5) Anthropic-compatible (custom baseUrl; Messages API)
  6) Skip for now
TXT

  local choice
  ask choice "Enter 1-6" "6"

  case "$choice" in
    1)
      ask OPENAI_API_KEY "Enter OPENAI_API_KEY (will be written to ~/.clawdbot/.env)" ""
      if [[ -z "$OPENAI_API_KEY" ]]; then err "OPENAI_API_KEY is required."; exit 6; fi
      set_env_var OPENAI_API_KEY "$OPENAI_API_KEY"
      clawdbot config set agents.defaults.model.primary "openai/gpt-5.2" || true
      ;;
    2)
      ask ANTHROPIC_API_KEY "Enter ANTHROPIC_API_KEY (will be written to ~/.clawdbot/.env)" ""
      if [[ -z "$ANTHROPIC_API_KEY" ]]; then err "ANTHROPIC_API_KEY is required."; exit 6; fi
      set_env_var ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
      clawdbot config set agents.defaults.model.primary "anthropic/claude-sonnet-4-5" || true
      ;;
    3)
      ask GEMINI_API_KEY "Enter GEMINI_API_KEY (will be written to ~/.clawdbot/.env)" ""
      if [[ -z "$GEMINI_API_KEY" ]]; then err "GEMINI_API_KEY is required."; exit 6; fi
      set_env_var GEMINI_API_KEY "$GEMINI_API_KEY"
      clawdbot config set agents.defaults.model.primary "google/gemini-3-flash-preview" || true
      ;;
    4)
      ask CUSTOM_BASE_URL "Enter OpenAI-compatible baseUrl (e.g. https://example.com/v1)" ""
      ask CUSTOM_API_KEY "Enter API key for the custom provider" ""
      ask CUSTOM_MODEL_ID "Enter model id (provider-side)" ""
      ask CUSTOM_API_VARIANT "API variant: openai-completions or openai-responses" "openai-responses"

      if [[ -z "$CUSTOM_BASE_URL" || -z "$CUSTOM_API_KEY" || -z "$CUSTOM_MODEL_ID" ]]; then
        err "baseUrl/apiKey/model id are required."; exit 6
      fi

      mkdir -p "$HOME/.clawdbot/config"
      set_env_var CUSTOM_OPENAI_API_KEY "$CUSTOM_API_KEY"

      # Write a small include file and include it from the main config using $include.
      cat > "$HOME/.clawdbot/config/custom-provider.json5" <<EOF
{
  models: {
    mode: "merge",
    providers: {
      "custom-openai": {
        baseUrl: "${CUSTOM_BASE_URL}",
        apiKey: "\${CUSTOM_OPENAI_API_KEY}",
        api: "${CUSTOM_API_VARIANT}",
        authHeader: true,
        models: [{ id: "${CUSTOM_MODEL_ID}", name: "Custom Model" }]
      }
    }
  },
  agents: {
    defaults: {
      model: { primary: "custom-openai/${CUSTOM_MODEL_ID}" }
    }
  }
}
EOF

      # If the user already uses includes, we avoid being clever; we just ask them to merge manually.
      warn "A custom provider snippet was written to: ~/.clawdbot/config/custom-provider.json5"
      warn "Please add it to ~/.clawdbot/clawdbot.json via $include, or paste its contents into your config."
      warn "(This avoids accidentally breaking strict schema validation.)"
      pause
      ;;
    5)
      ask ACOMP_BASE_URL "Enter Anthropic-compatible baseUrl (e.g. https://example.com/anthropic)" ""
      ask ACOMP_API_KEY "Enter API key for the Anthropic-compatible provider" ""
      ask ACOMP_MODEL_ID "Enter model id" ""

      if [[ -z "$ACOMP_BASE_URL" || -z "$ACOMP_API_KEY" || -z "$ACOMP_MODEL_ID" ]]; then
        err "baseUrl/apiKey/model id are required."; exit 6
      fi

      mkdir -p "$HOME/.clawdbot/config"
      set_env_var CUSTOM_ANTHROPIC_API_KEY "$ACOMP_API_KEY"

      cat > "$HOME/.clawdbot/config/custom-anthropic.json5" <<EOF
{
  models: {
    mode: "merge",
    providers: {
      "custom-anthropic": {
        baseUrl: "${ACOMP_BASE_URL}",
        apiKey: "\${CUSTOM_ANTHROPIC_API_KEY}",
        api: "anthropic-messages",
        models: [{ id: "${ACOMP_MODEL_ID}", name: "Custom Anthropic-Compatible" }]
      }
    }
  },
  agents: {
    defaults: {
      model: { primary: "custom-anthropic/${ACOMP_MODEL_ID}" }
    }
  }
}
EOF

      warn "Wrote: ~/.clawdbot/config/custom-anthropic.json5"
      warn "Please include/merge it into ~/.clawdbot/clawdbot.json."
      pause
      ;;
    6)
      warn "Skipped model config. You can run: clawdbot onboard  (or clawdbot configure --section model) later."
      ;;
    *)
      err "Invalid choice."; exit 6
      ;;
  esac

  info "Model/provider step complete."
}

install_skill_packs() {
  bold "Step 5/6 — Optional skills pack"
  info "You can install optional skills into: $WORKSPACE/skills"

  mkdir -p "$WORKSPACE/skills"

  if confirm "Install skill: agent-browser (browser automation CLI; already installed separately)?"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/agent-browser" "$WORKSPACE/skills/" || true
    info "Installed: agent-browser"
  fi

  if confirm "Install skill: searxng-search (self-hosted web search)?"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/searxng-search" "$WORKSPACE/skills/" || true
    ask SEARXNG_BASE_URL "SEARXNG_BASE_URL (e.g. http://localhost:8888)" "http://localhost:8888"
    set_env_var SEARXNG_BASE_URL "$SEARXNG_BASE_URL"
    info "Installed: searxng-search"
  fi

  if confirm "Install skill: douyin-download (requires your Douyin_TikTok_Download_API server)?"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/douyin-download" "$WORKSPACE/skills/" || true
    ask DOYIN_API_BASE_URL "DOYIN_API_BASE_URL (e.g. http://localhost:8030)" "http://localhost:8030"
    set_env_var DOYIN_API_BASE_URL "$DOYIN_API_BASE_URL"
    info "Installed: douyin-download"
  fi

  if confirm "Install skill: pic-api (random images; needs python requests)?"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/pic-api" "$WORKSPACE/skills/" || true
    info "To enable: python3 -m pip install --user requests"
    info "Installed: pic-api"
  fi

  if confirm "Install skill: stock-market (A-share index/sector report)?"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/stock-market" "$WORKSPACE/skills/" || true
    if confirm "Configure optional iMessage recipient for stock report now?"; then
      ask STOCK_REPORT_IMESSAGE_TO "STOCK_REPORT_IMESSAGE_TO (iMessage handle/email/phone)" ""
      if [[ -n "$STOCK_REPORT_IMESSAGE_TO" ]]; then
        set_env_var STOCK_REPORT_IMESSAGE_TO "$STOCK_REPORT_IMESSAGE_TO"
      fi
    fi
    info "Installed: stock-market"
  fi
}

setup_default_channel() {
  bold "Step 6/6 — Default channel (choose one)"

  cat <<'TXT'
Choose your default channel:
  1) iMessage (imsg, macOS only)
  2) Telegram (Bot API)
  3) Skip for now
TXT

  local choice
  ask choice "Enter 1-3" "1"

  case "$choice" in
    1)
      info "Before we configure iMessage:"
      info "- Messages.app should be signed in."
      info "- Recommended: use a DIFFERENT Apple ID for the bot than your personal one."
      info "- You will need to grant Full Disk Access + Automation permissions."

      if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew is required to install imsg. Install Homebrew first: https://brew.sh"
        exit 7
      fi

      info "Installing imsg via Homebrew..."
      brew install steipete/tap/imsg

      local IMSGPATH
      IMSGPATH="$(command -v imsg)"
      local DBPATH="$HOME/Library/Messages/chat.db"

      info "Enabling iMessage channel in Clawdbot config..."
      clawdbot config set channels.imessage.enabled true || true
      clawdbot config set channels.imessage.cliPath "$IMSGPATH" || true
      clawdbot config set channels.imessage.dbPath "$DBPATH" || true
      clawdbot config set channels.imessage.dmPolicy pairing || true

      # Ensure telegram is not enabled by accident.
      clawdbot config set channels.telegram.enabled false || true

      warn "Permissions required (manual):"
      warn "1) System Settings -> Privacy & Security -> Full Disk Access: add clawdbot + imsg"
      warn "2) If sending prompts appear (Automation), approve them."
      warn "We will now run: imsg chats --limit 1  (to test DB access)."
      pause

      if imsg chats --limit 1 >/dev/null 2>&1; then
        info "imsg can read chats (good sign)."
      else
        warn "imsg chat listing failed. You likely need Full Disk Access."
        warn "After granting permissions, re-run: imsg chats --limit 1"
      fi

      info "Restarting gateway service (if installed)..."
      clawdbot gateway restart || true

      info "Done. Test: clawdbot message send --channel imessage --target <handle_or_chat_id> --message \"hello\""
      ;;

    2)
      info "Telegram setup: create a bot with @BotFather, then paste the token here."
      local tg_token
      ask tg_token "TELEGRAM_BOT_TOKEN" ""
      if [[ -z "$tg_token" ]]; then
        err "TELEGRAM_BOT_TOKEN is required."; exit 8
      fi

      # Safer to keep secrets in env file.
      set_env_var TELEGRAM_BOT_TOKEN "$tg_token"

      info "Enabling Telegram channel in Clawdbot config (pairing for DMs)..."
      clawdbot config set channels.telegram.enabled true || true
      clawdbot config set channels.telegram.dmPolicy pairing || true
      clawdbot config set channels.telegram.groups."*".requireMention true || true

      # Ensure imessage isn't enabled by accident.
      clawdbot config set channels.imessage.enabled false || true

      info "Restarting gateway service (if installed)..."
      clawdbot gateway restart || true

      info "Done. Next: DM your bot in Telegram; approve pairing code via: clawdbot pairing approve telegram <CODE>"
      ;;

    3)
      warn "Skipped channel setup. You can configure channels later."
      ;;

    *)
      err "Invalid choice."; exit 8
      ;;
  esac
}

main() {
  require_macos
  require_local_terminal
  preflight_network
  install_clawdbot_cli
  collect_workspace_and_seed
  configure_model_provider
  install_skill_packs
  setup_default_channel

  bold "All done."
  info "Optional plugins are available (not installed automatically):"
  info "  - WeCom plugin: $ROOT_DIR/packs/plugins/wecom"
  info "  See: $ROOT_DIR/docs/OPTIONAL_PLUGINS.md"
  info "Before publishing this repo, run: ./scripts/redaction_check.sh"
}

main "$@"
