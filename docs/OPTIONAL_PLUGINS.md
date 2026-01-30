Optional channel plugins bundled in this repo

This installer repo may include optional channel plugins for convenience.
They are NOT installed or enabled automatically.

Bundled plugins:
- wecom (WeChat Work / 企业微信)
  - Location in this repo: packs/plugins/wecom
  - Upstream install (recommended):
    clawdbot plugins install @clawdbot/wecom
    clawdbot plugins enable wecom
    clawdbot gateway restart
  - Local link install (development):
    clawdbot plugins install --link <this-repo>/packs/plugins/wecom
    clawdbot plugins enable wecom
    clawdbot gateway restart

Notes
- Webhook-based channels typically require public HTTPS.
- Do not commit your tokens/keys into any git repo.
