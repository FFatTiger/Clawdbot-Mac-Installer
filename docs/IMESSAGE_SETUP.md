iMessage setup notes (macOS)

Recommended approach: use a dedicated Apple ID + (optionally) a dedicated macOS user, so the bot’s Messages identity is isolated from your personal one.

Minimum requirements:
- Messages.app is signed in.
- Full Disk Access for the process running Clawdbot (and `imsg`) so it can read ~/Library/Messages/chat.db
- Automation permission prompts may appear on first send.

Install `imsg`:
- brew install steipete/tap/imsg

Typical DB path:
- ~/Library/Messages/chat.db

If things look stuck:
- Run: imsg chats --limit 1
- Approve prompts / grant Full Disk Access, then retry.

Clawdbot docs: /channels/imessage (see official docs).
