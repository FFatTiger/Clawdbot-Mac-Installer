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

    ONLY_MACOS) echo "This installer is for macOS only.";;
    SSH_DETECTED) echo "SSH environment detected (SSH_CONNECTION/SSH_TTY is set).";;
    ABORT_LOCAL) echo "Aborting. Re-run locally in Terminal.app.";;

    STEP2_NODE_NOTE) echo "This will install Node (if needed) and the clawdbot CLI.";;
    STEP2_CANNOT_CONTINUE) echo "Cannot continue without clawdbot.";;
    STEP2_INSTALLED) echo "Installed:";;

    STEP3_WS_SET) echo "Workspace is set to:";;

    MODEL_INTRO) echo "We will NOT configure chat channels yet. First we set up model auth + default model.";;
    MODEL_MENU_1) echo "Choose a provider:";;
    MODEL_MENU_OPENAI) echo "1) OpenAI (official API key)";;
    MODEL_MENU_ANTHROPIC) echo "2) Anthropic (official API key)";;
    MODEL_MENU_GEMINI) echo "3) Google Gemini (API key)";;
    MODEL_MENU_OAI_COMPAT) echo "4) OpenAI-compatible (custom baseUrl; Completions or Responses)";;
    MODEL_MENU_ANTH_COMPAT) echo "5) Anthropic-compatible (custom baseUrl; Messages API)";;
    MODEL_MENU_SKIP) echo "6) Skip for now";;
    MODEL_PROMPT_CHOICE) echo "Enter 1-6";;

    MODEL_ASK_OPENAI) echo "Enter OPENAI_API_KEY (will be written to ~/.clawdbot/.env)";;
    MODEL_REQ_OPENAI) echo "OPENAI_API_KEY is required.";;
    MODEL_ASK_ANTHROPIC) echo "Enter ANTHROPIC_API_KEY (will be written to ~/.clawdbot/.env)";;
    MODEL_REQ_ANTHROPIC) echo "ANTHROPIC_API_KEY is required.";;
    MODEL_ASK_GEMINI) echo "Enter GEMINI_API_KEY (will be written to ~/.clawdbot/.env)";;
    MODEL_REQ_GEMINI) echo "GEMINI_API_KEY is required.";;

    MODEL_ASK_OAI_BASEURL) echo "Enter OpenAI-compatible baseUrl (e.g. https://example.com/v1)";;
    MODEL_ASK_OAI_KEY) echo "Enter API key for the custom provider";;
    MODEL_ASK_OAI_MODEL) echo "Enter model id (provider-side)";;
    MODEL_ASK_OAI_API) echo "API variant: openai-completions or openai-responses";;
    MODEL_REQ_OAI_FIELDS) echo "baseUrl/apiKey/model id are required.";;
    MODEL_OAI_WROTE) echo "A custom provider snippet was written to:";;
    MODEL_OAI_INCLUDE1) echo "Please add it to ~/.clawdbot/clawdbot.json via $include, or paste its contents into your config.";;
    MODEL_OAI_INCLUDE2) echo "(This avoids accidentally breaking strict schema validation.)";;

    MODEL_ASK_ANTH_BASEURL) echo "Enter Anthropic-compatible baseUrl (e.g. https://example.com/anthropic)";;
    MODEL_ASK_ANTH_KEY) echo "Enter API key for the Anthropic-compatible provider";;
    MODEL_ASK_ANTH_MODEL) echo "Enter model id";;
    MODEL_REQ_ANTH_FIELDS) echo "baseUrl/apiKey/model id are required.";;
    MODEL_ANTH_WROTE) echo "Wrote:";;
    MODEL_ANTH_INCLUDE) echo "Please include/merge it into ~/.clawdbot/clawdbot.json.";;

    MODEL_SKIPPED) echo "Skipped model config. You can run: clawdbot onboard (or clawdbot configure --section model) later.";;
    MODEL_INVALID) echo "Invalid choice.";;
    MODEL_DONE) echo "Model/provider step complete.";;

    SKILLS_INTRO) echo "You can install optional skills into:";;
    SKILL_INSTALL_AGENT_BROWSER) echo "Install skill: agent-browser (browser automation CLI; already installed separately)?";;
    SKILL_INSTALL_SEARXNG) echo "Install skill: searxng-search (self-hosted web search)?";;
    SKILL_INSTALL_DOUYIN) echo "Install skill: douyin-download (requires your Douyin_TikTok_Download_API server)?";;
    SKILL_INSTALL_PIC) echo "Install skill: pic-api (random images; needs python requests)?";;
    SKILL_INSTALL_STOCK) echo "Install skill: stock-market (A-share index/sector report)?";;
    SKILL_INSTALLED) echo "Installed:";;
    SKILL_PIC_HINT) echo "To enable: python3 -m pip install --user requests";;
    SKILL_SEARXNG_BASE) echo "SEARXNG_BASE_URL (e.g. http://localhost:8888)";;
    SKILL_DOUYIN_BASE) echo "DOYIN_API_BASE_URL (e.g. http://localhost:8030)";;
    SKILL_STOCK_IMSG_Q) echo "Configure optional iMessage recipient for stock report now?";;
    SKILL_STOCK_IMSG_VAR) echo "STOCK_REPORT_IMESSAGE_TO (iMessage handle/email/phone)";;

    CH_MENU_TITLE) echo "Choose your default channel:";;
    CH_MENU_IMSG) echo "1) iMessage (imsg, macOS only)";;
    CH_MENU_TG) echo "2) Telegram (Bot API)";;
    CH_MENU_SKIP) echo "3) Skip for now";;
    CH_PROMPT_CHOICE) echo "Enter 1-3";;

    IMS_PRE1) echo "Before we configure iMessage:";;
    IMS_PRE2) echo "- Messages.app should be signed in.";;
    IMS_PRE3) echo "- Recommended: use a DIFFERENT Apple ID for the bot than your personal one.";;
    IMS_PRE4) echo "- You will need to grant Full Disk Access + Automation permissions.";;
    IMS_NEED_BREW) echo "Homebrew is required to install imsg. Install Homebrew first: https://brew.sh";;
    IMS_INSTALLING) echo "Installing imsg via Homebrew...";;
    IMS_ENABLING) echo "Enabling iMessage channel in Clawdbot config...";;
    IMS_PERM_TITLE) echo "Permissions required (manual):";;
    IMS_PERM_1) echo "1) System Settings -> Privacy & Security -> Full Disk Access: add clawdbot + imsg";;
    IMS_PERM_2) echo "2) If sending prompts appear (Automation), approve them.";;
    IMS_PERM_3) echo "We will now run: imsg chats --limit 1 (to test DB access).";;
    IMS_OK) echo "imsg can read chats (good sign).";;
    IMS_FAIL) echo "imsg chat listing failed. You likely need Full Disk Access.";;
    IMS_FAIL2) echo "After granting permissions, re-run: imsg chats --limit 1";;

    TG_SETUP1) echo "Telegram setup: create a bot with @BotFather, then paste the token here.";;
    TG_TOKEN_PROMPT) echo "TELEGRAM_BOT_TOKEN";;
    TG_TOKEN_REQ) echo "TELEGRAM_BOT_TOKEN is required.";;
    TG_ENABLING) echo "Enabling Telegram channel in Clawdbot config (pairing for DMs)...";;

    GW_RESTARTING) echo "Restarting gateway service (if installed)...";;
    DONE_TEST_IMSG) echo "Done. Test:";;
    DONE_NEXT_TG) echo "Done. Next: DM your bot in Telegram; approve pairing code via:";;
    CH_SKIPPED) echo "Skipped channel setup. You can configure channels later.";;
    CH_INVALID) echo "Invalid choice.";;

    PLUGINS_NOTE) echo "Optional plugins are available (not installed automatically):";;
    PLUGINS_SEE) echo "See:";;

    PRESS_ENTER) echo "Press ENTER to continue...";;
    CONFIRM_DEFAULT) echo "Continue?";;
    CONFIRM_PLEASE) echo "Please answer y or n.";;

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

    ONLY_MACOS) echo "此安装脚本仅支持 macOS。";;
    SSH_DETECTED) echo "检测到 SSH 环境（SSH_CONNECTION/SSH_TTY 已设置）。";;
    ABORT_LOCAL) echo "已取消。请在目标 Mac 的 Terminal.app 中重新运行。";;

    STEP2_NODE_NOTE) echo "将会安装 Node（如缺失）以及 clawdbot CLI。";;
    STEP2_CANNOT_CONTINUE) echo "未安装 clawdbot，无法继续。";;
    STEP2_INSTALLED) echo "已安装：";;

    STEP3_WS_SET) echo "Workspace 已设置为：";;

    MODEL_INTRO) echo "暂不配置沟通渠道；先完成模型鉴权与默认模型设置。";;
    MODEL_MENU_1) echo "选择一个模型提供方：";;
    MODEL_MENU_OPENAI) echo "1) OpenAI（官方 API Key）";;
    MODEL_MENU_ANTHROPIC) echo "2) Anthropic（官方 API Key）";;
    MODEL_MENU_GEMINI) echo "3) Google Gemini（API Key）";;
    MODEL_MENU_OAI_COMPAT) echo "4) OpenAI 兼容（自定义 baseUrl；Completions 或 Responses）";;
    MODEL_MENU_ANTH_COMPAT) echo "5) Anthropic 兼容（自定义 baseUrl；Messages API）";;
    MODEL_MENU_SKIP) echo "6) 先跳过";;
    MODEL_PROMPT_CHOICE) echo "输入 1-6";;

    MODEL_ASK_OPENAI) echo "输入 OPENAI_API_KEY（将写入 ~/.clawdbot/.env）";;
    MODEL_REQ_OPENAI) echo "必须提供 OPENAI_API_KEY。";;
    MODEL_ASK_ANTHROPIC) echo "输入 ANTHROPIC_API_KEY（将写入 ~/.clawdbot/.env）";;
    MODEL_REQ_ANTHROPIC) echo "必须提供 ANTHROPIC_API_KEY。";;
    MODEL_ASK_GEMINI) echo "输入 GEMINI_API_KEY（将写入 ~/.clawdbot/.env）";;
    MODEL_REQ_GEMINI) echo "必须提供 GEMINI_API_KEY。";;

    MODEL_ASK_OAI_BASEURL) echo "输入 OpenAI 兼容 baseUrl（例如 https://example.com/v1）";;
    MODEL_ASK_OAI_KEY) echo "输入该自定义提供方的 API Key";;
    MODEL_ASK_OAI_MODEL) echo "输入模型 id（提供方侧的 model id）";;
    MODEL_ASK_OAI_API) echo "API 类型：openai-completions 或 openai-responses";;
    MODEL_REQ_OAI_FIELDS) echo "baseUrl / apiKey / model id 都是必填。";;
    MODEL_OAI_WROTE) echo "已写入自定义 provider 片段：";;
    MODEL_OAI_INCLUDE1) echo "请将其通过 $include 合并到 ~/.clawdbot/clawdbot.json，或手动复制粘贴进去。";;
    MODEL_OAI_INCLUDE2) echo "（这样做是为了避免误改导致严格 schema 校验失败。）";;

    MODEL_ASK_ANTH_BASEURL) echo "输入 Anthropic 兼容 baseUrl（例如 https://example.com/anthropic）";;
    MODEL_ASK_ANTH_KEY) echo "输入该 Anthropic 兼容提供方的 API Key";;
    MODEL_ASK_ANTH_MODEL) echo "输入模型 id";;
    MODEL_REQ_ANTH_FIELDS) echo "baseUrl / apiKey / model id 都是必填。";;
    MODEL_ANTH_WROTE) echo "已写入：";;
    MODEL_ANTH_INCLUDE) echo "请将其 include/合并到 ~/.clawdbot/clawdbot.json。";;

    MODEL_SKIPPED) echo "已跳过模型配置。后续可运行：clawdbot onboard（或 clawdbot configure --section model）。";;
    MODEL_INVALID) echo "选择无效。";;
    MODEL_DONE) echo "模型配置完成。";;

    SKILLS_INTRO) echo "你可以把可选 skills 安装到：";;
    SKILL_INSTALL_AGENT_BROWSER) echo "安装技能：agent-browser（浏览器自动化 CLI；通常已单独安装）？";;
    SKILL_INSTALL_SEARXNG) echo "安装技能：searxng-search（自建搜索）？";;
    SKILL_INSTALL_DOUYIN) echo "安装技能：douyin-download（需要你自己的下载服务）？";;
    SKILL_INSTALL_PIC) echo "安装技能：pic-api（随机图片；需要 python requests）？";;
    SKILL_INSTALL_STOCK) echo "安装技能：stock-market（指数/板块报表）？";;
    SKILL_INSTALLED) echo "已安装：";;
    SKILL_PIC_HINT) echo "启用提示：python3 -m pip install --user requests";;
    SKILL_SEARXNG_BASE) echo "SEARXNG_BASE_URL（例如 http://localhost:8888）";;
    SKILL_DOUYIN_BASE) echo "DOYIN_API_BASE_URL（例如 http://localhost:8030）";;
    SKILL_STOCK_IMSG_Q) echo "现在配置股市报表的 iMessage 收件人吗？";;
    SKILL_STOCK_IMSG_VAR) echo "STOCK_REPORT_IMESSAGE_TO（iMessage 收件人：邮箱/手机号等）";;

    CH_MENU_TITLE) echo "选择默认沟通渠道：";;
    CH_MENU_IMSG) echo "1) iMessage（imsg，仅 macOS）";;
    CH_MENU_TG) echo "2) Telegram（Bot API）";;
    CH_MENU_SKIP) echo "3) 先跳过";;
    CH_PROMPT_CHOICE) echo "输入 1-3";;

    IMS_PRE1) echo "配置 iMessage 前说明：";;
    IMS_PRE2) echo "- Messages.app 需要已登录。";;
    IMS_PRE3) echo "- 建议为机器人使用不同于个人的 Apple ID。";;
    IMS_PRE4) echo "- 需要授予完全磁盘访问 + 自动化权限。";;
    IMS_NEED_BREW) echo "安装 imsg 需要 Homebrew。请先安装 Homebrew：https://brew.sh";;
    IMS_INSTALLING) echo "正在通过 Homebrew 安装 imsg...";;
    IMS_ENABLING) echo "正在写入 iMessage 渠道配置...";;
    IMS_PERM_TITLE) echo "需要手动授予权限：";;
    IMS_PERM_1) echo "1) 系统设置 -> 隐私与安全性 -> 完全磁盘访问：添加 clawdbot + imsg";;
    IMS_PERM_2) echo "2) 若出现自动化弹窗，请允许。";;
    IMS_PERM_3) echo "接下来会运行：imsg chats --limit 1（测试数据库访问）";;
    IMS_OK) echo "imsg 可以读取聊天（看起来正常）。";;
    IMS_FAIL) echo "imsg 读取聊天失败：大概率还没授予完全磁盘访问。";;
    IMS_FAIL2) echo "授予后可重试：imsg chats --limit 1";;

    TG_SETUP1) echo "Telegram 配置：先在 @BotFather 创建机器人，然后把 token 粘贴到这里。";;
    TG_TOKEN_PROMPT) echo "TELEGRAM_BOT_TOKEN";;
    TG_TOKEN_REQ) echo "必须提供 TELEGRAM_BOT_TOKEN。";;
    TG_ENABLING) echo "正在写入 Telegram 渠道配置（DM 默认 pairing）...";;

    GW_RESTARTING) echo "正在重启网关服务（若已安装）...";;
    DONE_TEST_IMSG) echo "完成。测试命令：";;
    DONE_NEXT_TG) echo "完成。下一步：去 Telegram 私聊机器人；然后通过以下命令批准配对码：";;
    CH_SKIPPED) echo "已跳过渠道配置，后续可再配置。";;
    CH_INVALID) echo "选择无效。";;

    PLUGINS_NOTE) echo "额外插件已打包（不会自动安装）：";;
    PLUGINS_SEE) echo "说明文档：";;

    PRESS_ENTER) echo "按回车继续...";;
    CONFIRM_DEFAULT) echo "继续？";;
    CONFIRM_PLEASE) echo "请输入 y 或 n。";;

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
