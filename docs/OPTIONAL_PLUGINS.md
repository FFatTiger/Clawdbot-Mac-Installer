Optional channel plugins bundled in this repo

This installer repo may include optional channel plugins for convenience.
They are NOT installed or enabled automatically.

Bundled plugins (source snapshots):

1) wecom (WeChat Work / 企业微信)
- Location: packs/plugins/wecom
- See README inside that folder.
- Typical enable flow:
  clawdbot plugins install --link <this-repo>/packs/plugins/wecom
  clawdbot plugins enable wecom
  clawdbot gateway restart

2) feishu (Lark / 飞书)
- Location: packs/plugins/feishu
- May require npm install/build before it can run.
- See plugin folder for details.

3) clawdbot-dingtalk (DingTalk / 钉钉)
- Location: packs/plugins/clawdbot-dingtalk
- May be installable via npm in some setups; this repo includes a local copy.
- See README inside that folder for configuration and build notes.

4) qqbot (QQ Bot)
- Location: packs/plugins/qqbot
- May require npm install/build before it can run.

Notes
- Webhook-based channels typically require public HTTPS.
- Never commit tokens/keys into any git repo.
- If you publish this installer repo publicly, review these plugin folders for licensing/attribution.
