#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/ui.sh
source "$ROOT_DIR/lib/ui.sh"
# shellcheck source=lib/i18n.sh
source "$ROOT_DIR/lib/i18n.sh"

i18n_init "$@"

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
    err "$(t ONLY_MACOS)";
    exit 1
  fi
}

require_local_terminal() {
  bold "$(t STEP0_TITLE)"
  info "$(t STEP0_BODY1)"
  info "$(t STEP0_BODY2)"

  # Heuristic detection
  if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
    warn "$(t SSH_DETECTED)"
  fi

  if ! confirm "$(t STEP0_Q)"; then
    err "$(t ABORT_LOCAL)"
    exit 2
  fi
}

preflight_network() {
  bold "$(t STEP1_TITLE)"
  info "$(t STEP1_BODY)"

  if "$ROOT_DIR/scripts/network_check.sh" >/dev/null 2>&1; then
    info "$(t STEP1_OK)"
  else
    warn "$(t STEP1_FAIL1)"
    warn "$(t STEP1_FAIL2)"
    if ! confirm "$(t STEP1_Q)"; then
      exit 3
    fi
  fi
}

install_clawdbot_cli() {
  bold "$(t STEP2_TITLE)"

  if command -v clawdbot >/dev/null 2>&1; then
    info "$(t STEP2_FOUND) $(clawdbot --version)"
    return 0
  fi

  warn "$(t STEP2_MISSING)"
  info "$(t STEP2_NODE_NOTE)"

  if ! confirm "$(t STEP2_Q)"; then
    err "$(t STEP2_CANNOT_CONTINUE)"
    exit 4
  fi

  # Use the official installer but explicitly skip onboarding.
  # We want THIS repo's guided flow, not the upstream onboarding wizard.
  curl -fsSL https://clawd.bot/install.sh | bash -s -- --install-method npm --no-onboard --no-prompt

  if ! command -v clawdbot >/dev/null 2>&1; then
    err "$(t STEP2_PATH_FAIL)"
    exit 5
  fi

  info "$(t STEP2_INSTALLED) $(clawdbot --version)"
}

collect_workspace_and_seed() {
  bold "$(t STEP3_TITLE)"

  ask WORKSPACE "$(t STEP3_WS_PROMPT)" "~/clawd"

  info "$(t STEP3_SEED)"
  clawdbot setup --workspace "$WORKSPACE" || true

  info "$(t STEP3_WS_SET) $WORKSPACE"

  if confirm "$(t STEP3_APPLY_DEFAULTS_Q)"; then
    local user_name user_callme user_tz
    ask user_name "$(t STEP3_NAME)" ""
    ask user_callme "$(t STEP3_CALLME)" ""
    ask user_tz "$(t STEP3_TZ)" "Asia/Shanghai"

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

    info "$(t STEP3_WROTE) $WORKSPACE/SOUL.md, USER.md, TOOLS.md"
  fi
}

configure_model_provider() {
  bold "$(t STEP4_TITLE)"
  info "$(t MODEL_INTRO)"

  printf "%s\n" "$(t MODEL_MENU_1)"
  printf "  %s\n" "$(t MODEL_MENU_OPENAI)"
  printf "  %s\n" "$(t MODEL_MENU_ANTHROPIC)"
  printf "  %s\n" "$(t MODEL_MENU_GEMINI)"
  printf "  %s\n" "$(t MODEL_MENU_OAI_COMPAT)"
  printf "  %s\n" "$(t MODEL_MENU_ANTH_COMPAT)"
  printf "  %s\n" "$(t MODEL_MENU_SKIP)"

  local choice
  ask choice "$(t MODEL_PROMPT_CHOICE)" "6"

  case "$choice" in
    1)
      ask OPENAI_API_KEY "$(t MODEL_ASK_OPENAI)" ""
      if [[ -z "$OPENAI_API_KEY" ]]; then err "$(t MODEL_REQ_OPENAI)"; exit 6; fi
      set_env_var OPENAI_API_KEY "$OPENAI_API_KEY"
      clawdbot config set agents.defaults.model.primary "openai/gpt-5.2" || true
      ;;
    2)
      ask ANTHROPIC_API_KEY "$(t MODEL_ASK_ANTHROPIC)" ""
      if [[ -z "$ANTHROPIC_API_KEY" ]]; then err "$(t MODEL_REQ_ANTHROPIC)"; exit 6; fi
      set_env_var ANTHROPIC_API_KEY "$ANTHROPIC_API_KEY"
      clawdbot config set agents.defaults.model.primary "anthropic/claude-sonnet-4-5" || true
      ;;
    3)
      ask GEMINI_API_KEY "$(t MODEL_ASK_GEMINI)" ""
      if [[ -z "$GEMINI_API_KEY" ]]; then err "$(t MODEL_REQ_GEMINI)"; exit 6; fi
      set_env_var GEMINI_API_KEY "$GEMINI_API_KEY"
      clawdbot config set agents.defaults.model.primary "google/gemini-3-flash-preview" || true
      ;;
    4)
      ask CUSTOM_BASE_URL "$(t MODEL_ASK_OAI_BASEURL)" ""
      ask CUSTOM_API_KEY "$(t MODEL_ASK_OAI_KEY)" ""
      ask CUSTOM_MODEL_ID "$(t MODEL_ASK_OAI_MODEL)" ""
      ask CUSTOM_API_VARIANT "$(t MODEL_ASK_OAI_API)" "openai-responses"

      if [[ -z "$CUSTOM_BASE_URL" || -z "$CUSTOM_API_KEY" || -z "$CUSTOM_MODEL_ID" ]]; then
        err "$(t MODEL_REQ_OAI_FIELDS)"; exit 6
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
      warn "$(t MODEL_OAI_WROTE) ~/.clawdbot/config/custom-provider.json5"
      warn "$(t MODEL_OAI_INCLUDE1)"
      warn "$(t MODEL_OAI_INCLUDE2)"
      pause
      ;;
    5)
      ask ACOMP_BASE_URL "$(t MODEL_ASK_ANTH_BASEURL)" ""
      ask ACOMP_API_KEY "$(t MODEL_ASK_ANTH_KEY)" ""
      ask ACOMP_MODEL_ID "$(t MODEL_ASK_ANTH_MODEL)" ""

      if [[ -z "$ACOMP_BASE_URL" || -z "$ACOMP_API_KEY" || -z "$ACOMP_MODEL_ID" ]]; then
        err "$(t MODEL_REQ_ANTH_FIELDS)"; exit 6
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

      warn "$(t MODEL_ANTH_WROTE) ~/.clawdbot/config/custom-anthropic.json5"
      warn "$(t MODEL_ANTH_INCLUDE)"
      pause
      ;;
    6)
      warn "$(t MODEL_SKIPPED)"
      ;;
    *)
      err "$(t MODEL_INVALID)"; exit 6
      ;;
  esac

  info "$(t MODEL_DONE)"
}

install_skill_packs() {
  bold "$(t STEP5_TITLE)"
  info "$(t SKILLS_INTRO) $WORKSPACE/skills"

  mkdir -p "$WORKSPACE/skills"

  if confirm "$(t SKILL_INSTALL_AGENT_BROWSER)"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/agent-browser" "$WORKSPACE/skills/" || true
    info "$(t SKILL_INSTALLED) agent-browser"
  fi

  if confirm "$(t SKILL_INSTALL_SEARXNG)"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/searxng-search" "$WORKSPACE/skills/" || true
    ask SEARXNG_BASE_URL "$(t SKILL_SEARXNG_BASE)" "http://localhost:8888"
    set_env_var SEARXNG_BASE_URL "$SEARXNG_BASE_URL"
    info "$(t SKILL_INSTALLED) searxng-search"
  fi

  if confirm "$(t SKILL_INSTALL_DOUYIN)"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/douyin-download" "$WORKSPACE/skills/" || true
    ask DOYIN_API_BASE_URL "$(t SKILL_DOUYIN_BASE)" "http://localhost:8030"
    set_env_var DOYIN_API_BASE_URL "$DOYIN_API_BASE_URL"
    info "$(t SKILL_INSTALLED) douyin-download"
  fi

  if confirm "$(t SKILL_INSTALL_PIC)"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/pic-api" "$WORKSPACE/skills/" || true
    info "$(t SKILL_PIC_HINT)"
    info "$(t SKILL_INSTALLED) pic-api"
  fi

  if confirm "$(t SKILL_INSTALL_STOCK)"; then
    rsync -a --delete "$ROOT_DIR/packs/skills/stock-market" "$WORKSPACE/skills/" || true
    if confirm "$(t SKILL_STOCK_IMSG_Q)"; then
      ask STOCK_REPORT_IMESSAGE_TO "$(t SKILL_STOCK_IMSG_VAR)" ""
      if [[ -n "$STOCK_REPORT_IMESSAGE_TO" ]]; then
        set_env_var STOCK_REPORT_IMESSAGE_TO "$STOCK_REPORT_IMESSAGE_TO"
      fi
    fi
    info "$(t SKILL_INSTALLED) stock-market"
  fi
}

setup_default_channel() {
  bold "$(t STEP6_TITLE)"

  printf "%s\n" "$(t CH_MENU_TITLE)"
  printf "  %s\n" "$(t CH_MENU_IMSG)"
  printf "  %s\n" "$(t CH_MENU_TG)"
  printf "  %s\n" "$(t CH_MENU_SKIP)"

  local choice
  ask choice "$(t CH_PROMPT_CHOICE)" "1"

  case "$choice" in
    1)
      info "$(t IMS_PRE1)"
      info "$(t IMS_PRE2)"
      info "$(t IMS_PRE3)"
      info "$(t IMS_PRE4)"

      if ! command -v brew >/dev/null 2>&1; then
        err "$(t IMS_NEED_BREW)"
        exit 7
      fi

      info "$(t IMS_INSTALLING)"
      brew install steipete/tap/imsg

      local IMSGPATH
      IMSGPATH="$(command -v imsg)"
      local DBPATH="$HOME/Library/Messages/chat.db"

      info "$(t IMS_ENABLING)"
      clawdbot config set channels.imessage.enabled true || true
      clawdbot config set channels.imessage.cliPath "$IMSGPATH" || true
      clawdbot config set channels.imessage.dbPath "$DBPATH" || true
      clawdbot config set channels.imessage.dmPolicy pairing || true

      # Ensure telegram is not enabled by accident.
      clawdbot config set channels.telegram.enabled false || true

      warn "$(t IMS_PERM_TITLE)"
      warn "$(t IMS_PERM_1)"
      warn "$(t IMS_PERM_2)"
      warn "$(t IMS_PERM_3)"
      pause

      if imsg chats --limit 1 >/dev/null 2>&1; then
        info "$(t IMS_OK)"
      else
        warn "$(t IMS_FAIL)"
        warn "$(t IMS_FAIL2)"
      fi

      info "$(t GW_RESTARTING)"
      clawdbot gateway restart || true

      info "$(t DONE_TEST_IMSG) clawdbot message send --channel imessage --target <handle_or_chat_id> --message \"hello\""
      ;;

    2)
      info "$(t TG_SETUP1)"
      local tg_token
      ask tg_token "$(t TG_TOKEN_PROMPT)" ""
      if [[ -z "$tg_token" ]]; then
        err "$(t TG_TOKEN_REQ)"; exit 8
      fi

      # Safer to keep secrets in env file.
      set_env_var TELEGRAM_BOT_TOKEN "$tg_token"

      info "$(t TG_ENABLING)"
      clawdbot config set channels.telegram.enabled true || true
      clawdbot config set channels.telegram.dmPolicy pairing || true
      clawdbot config set channels.telegram.groups."*".requireMention true || true

      # Ensure imessage isn't enabled by accident.
      clawdbot config set channels.imessage.enabled false || true

      info "$(t GW_RESTARTING)"
      clawdbot gateway restart || true

      info "$(t DONE_NEXT_TG) clawdbot pairing approve telegram <CODE>"
      ;;

    3)
      warn "$(t CH_SKIPPED)"
      ;;

    *)
      err "$(t CH_INVALID)"; exit 8
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

  bold "$(t DONE_TITLE)"
  info "$(t PLUGINS_NOTE)"
  info "  - wecom:      $ROOT_DIR/packs/plugins/wecom"
  info "  - feishu:    $ROOT_DIR/packs/plugins/feishu"
  info "  - dingtalk:  $ROOT_DIR/packs/plugins/clawdbot-dingtalk"
  info "  - qqbot:     $ROOT_DIR/packs/plugins/qqbot"
  info "$(t PLUGINS_SEE) $ROOT_DIR/docs/OPTIONAL_PLUGINS.md"
  info "$(t BEFORE_PUBLISH) ./scripts/redaction_check.sh"
}

main "$@"
