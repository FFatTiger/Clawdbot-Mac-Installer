#!/usr/bin/env bash
set -euo pipefail

# Very small i18n helper. Keep all user-visible strings behind t <KEY>.
# Language selection order:
# 1) --lang <zh|en>
# 2) CLAWDBOT_INSTALL_LANG
# 3) system locale heuristics

LANG_ID=${LANG_ID:-""}

_i18n_guess_lang() {
  local loc
  loc="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
  case "$loc" in
    zh_*|zh-*) echo "zh";;
    *) echo "en";;
  esac
}

i18n_parse_lang_arg() {
  # consumes args array by reference (bash-ism avoided; just returns lang)
  local args=("$@")
  local i
  for ((i=0;i<${#args[@]};i++)); do
    if [[ "${args[$i]}" == "--lang" && $((i+1)) -lt ${#args[@]} ]]; then
      echo "${args[$((i+1))]}"
      return 0
    fi
  done
  echo ""
}

i18n_init() {
  local arg_lang
  arg_lang="$(i18n_parse_lang_arg "$@")"

  if [[ -n "${arg_lang}" ]]; then
    LANG_ID="$arg_lang"
  elif [[ -n "${CLAWDBOT_INSTALL_LANG:-}" ]]; then
    LANG_ID="$CLAWDBOT_INSTALL_LANG"
  else
    LANG_ID="$(_i18n_guess_lang)"
  fi

  case "$LANG_ID" in
    zh|en) :;;
    *) LANG_ID="en";;
  esac
}

# Translation tables
# shellcheck disable=SC2034
_t_en() {
  case "$1" in
    WELCOME) echo "Clawdbot macOS installer";;
    STEP0_TITLE) echo "Step 0 — Local Terminal requirement";;
    STEP0_BODY1) echo "This setup needs macOS permission grants (Full Disk Access / Automation).";;
    STEP0_BODY2) echo "Do NOT run over SSH. Please run in Terminal.app on the target Mac.";;
    STEP0_Q) echo "Are you running this in local Terminal.app on this Mac (NOT SSH)?";;

    STEP1_TITLE) echo "Step 1 — Network preflight";;
    STEP1_BODY) echo "Checking reachability to Google + Telegram...";;
    STEP1_OK) echo "Network OK.";;
    STEP1_FAIL1) echo "Network check failed. This may break onboarding/login flows.";;
    STEP1_FAIL2) echo "You can still continue if you know what you're doing.";;
    STEP1_Q) echo "Continue anyway?";;

    STEP2_TITLE) echo "Step 2 — Install / verify Clawdbot CLI";;
    STEP2_FOUND) echo "clawdbot already installed:";;
    STEP2_MISSING) echo "clawdbot not found. Installing via official installer: https://clawd.bot/install.sh";;
    STEP2_Q) echo "Proceed with installing clawdbot CLI now?";;
    STEP2_PATH_FAIL) echo "Install finished but clawdbot not on PATH. Open a new terminal and re-run.";;

    STEP3_TITLE) echo "Step 3 — Workspace + defaults (no channels yet)";;
    STEP3_WS_PROMPT) echo "Choose agent workspace directory";;
    STEP3_SEED) echo "Seeding workspace + baseline config (no channels, no skills yet)...";;
    STEP3_APPLY_DEFAULTS_Q) echo "Apply recommended default MD files (SOUL/USER/TOOLS) into the workspace?";;
    STEP3_NAME) echo "Your name";;
    STEP3_CALLME) echo "What should the assistant call you";;
    STEP3_TZ) echo "Your timezone";;
    STEP3_WROTE) echo "Wrote defaults:";;

    STEP4_TITLE) echo "Step 4 — Model provider + API configuration";;
    STEP5_TITLE) echo "Step 5 — Optional skills pack";;
    STEP6_TITLE) echo "Step 6 — Default channel (choose one)";;

    DONE_TITLE) echo "All done.";;
    BEFORE_PUBLISH) echo "Before publishing this repo, run:";;

    *) echo "";;
  esac
}

_t_zh() {
  case "$1" in
    WELCOME) echo "Clawdbot macOS 一键安装";;
    STEP0_TITLE) echo "第 0 步——必须在本机 Terminal 运行";;
    STEP0_BODY1) echo "本安装会触发 macOS 权限授予（完全磁盘访问/自动化等）。";;
    STEP0_BODY2) echo "不要通过 SSH 运行，请在目标 Mac 的 Terminal.app 内运行。";;
    STEP0_Q) echo "你确认正在本机 Terminal.app 里运行（不是 SSH）吗？";;

    STEP1_TITLE) echo "第 1 步——网络连通性检查";;
    STEP1_BODY) echo "检查 Google + Telegram 是否可访问...";;
    STEP1_OK) echo "网络检查通过。";;
    STEP1_FAIL1) echo "网络检查失败：可能会影响登录/初始化流程。";;
    STEP1_FAIL2) echo "如果你确认网络没问题，也可以继续。";;
    STEP1_Q) echo "仍要继续吗？";;

    STEP2_TITLE) echo "第 2 步——安装/检测 Clawdbot CLI";;
    STEP2_FOUND) echo "已检测到 clawdbot：";;
    STEP2_MISSING) echo "未找到 clawdbot，将使用官方安装脚本：https://clawd.bot/install.sh";;
    STEP2_Q) echo "现在安装 clawdbot CLI 吗？";;
    STEP2_PATH_FAIL) echo "安装完成但找不到 clawdbot 命令。请打开新终端后重试。";;

    STEP3_TITLE) echo "第 3 步——Workspace + 默认偏好（暂不配置渠道）";;
    STEP3_WS_PROMPT) echo "选择 workspace 目录";;
    STEP3_SEED) echo "初始化 workspace 和基础配置（不配置渠道/skills）...";;
    STEP3_APPLY_DEFAULTS_Q) echo "是否把推荐的默认 MD（SOUL/USER/TOOLS）写入 workspace？";;
    STEP3_NAME) echo "你的名字";;
    STEP3_CALLME) echo "希望助手怎么称呼你";;
    STEP3_TZ) echo "你的时区";;
    STEP3_WROTE) echo "已写入默认文件：";;

    STEP4_TITLE) echo "第 4 步——模型/接口配置";;
    STEP5_TITLE) echo "第 5 步——可选技能包";;
    STEP6_TITLE) echo "第 6 步——默认渠道（二选一）";;

    DONE_TITLE) echo "完成。";;
    BEFORE_PUBLISH) echo "发布到 GitHub 前建议运行：";;

    *) echo "";;
  esac
}

t() {
  local key=$1
  local out=""
  case "$LANG_ID" in
    zh) out="$(_t_zh "$key")";;
    *) out="$(_t_en "$key")";;
  esac
  if [[ -z "$out" ]]; then
    # Fallback to key for missing strings (visible during development)
    echo "$key"
  else
    echo "$out"
  fi
}
