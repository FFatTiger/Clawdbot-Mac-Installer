# Clawdbot Mac Installer (sanitized)

Goal: a **safe, interactive** one-shot installer for macOS users that:

- **Must run in a local Terminal.app** (not over SSH) so macOS permission prompts can be granted.
- Checks network reachability (Google + Telegram).
- Guides the user **step-by-step** through optional features.
- Collects user-specific values interactively (never ships someone else’s personal info).
- Configures model provider/auth (official or 3rd-party, including OpenAI-compatible / Responses API / Anthropic-compatible / Gemini).
- Defaults to setting up **iMessage** (via `imsg`) with explicit permission guidance.
- Emphasizes **redaction / no secrets committed**.

## Quick start

### Option A (curl one-liner)

Chinese:

```bash
curl -fsSL https://raw.githubusercontent.com/FFatTiger/Clawdbot-Mac-Installer/main/bootstrap.sh | bash -s -- --lang zh
```

English:

```bash
curl -fsSL https://raw.githubusercontent.com/FFatTiger/Clawdbot-Mac-Installer/main/bootstrap.sh | bash -s -- --lang en
```

### Option B (local clone)

```bash
./install.sh
```

## Repo contents

- `install.sh` — interactive installer entrypoint
- `lib/` — shared shell helpers
- `templates/` — workspace + config templates (placeholders only)
- `scripts/` — helper scripts (network checks, redaction checks)
- `docs/` — extra setup notes

## Security / redaction

- This repo intentionally contains **no tokens**, **no phone numbers**, **no user IDs**, and **no private endpoints**.
- Anything user-specific is requested at install time and written into local-only files under `~/.clawdbot/`.
- See `scripts/redaction_check.sh`.
