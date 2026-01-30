# clawdbot-dingtalk

DingTalk (钉钉) channel plugin for [Clawdbot](https://github.com/anthropics/claude-code) - enables AI agent messaging via DingTalk Stream API.

## Installation

```bash
# Install Clawdbot globally
npm install -g clawdbot

# Install DingTalk plugin
npm install -g clawdbot-dingtalk
```

## Configuration

Edit `~/.clawdbot/clawdbot.json`:

```json
{
  "extensions": ["clawdbot-dingtalk"],
  "channels": {
    "dingtalk": {
      "enabled": true,
      "clientId": "your-dingtalk-client-id",
      "clientSecret": "your-dingtalk-client-secret"
    }
  },
  "models": {
    "providers": {
      "dashscope": {
        "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "apiKey": "YOUR_API_KEY",
        "api": "openai-completions",
        "models": [
          { "id": "qwen3-coder-plus", "contextWindow": 1000000, "maxTokens": 65536 }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": { "primary": "dashscope/qwen3-coder-plus" }
    }
  }
}
```

## Start Gateway

```bash
clawdbot gateway
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable/disable the channel |
| `clientId` | string | - | DingTalk app Client ID (required) |
| `clientSecret` | string | - | DingTalk app Client Secret (required) |
| `clientSecretFile` | string | - | Path to file containing client secret |
| `replyMode` | `"text"` \| `"markdown"` | `"text"` | Message format |
| `maxChars` | number | `1800` | Max characters per message chunk |
| `allowFrom` | string[] | `[]` | Allowlist of sender IDs (empty = allow all) |
| `requirePrefix` | string | - | Require messages to start with prefix |
| `responsePrefix` | string | - | Prefix added to responses |
| `tableMode` | `"code"` \| `"off"` | `"code"` | Table rendering mode |
| `showToolStatus` | boolean | `false` | Show tool execution status |
| `showToolResult` | boolean | `false` | Show tool results |
| `thinking` | string | `"off"` | Thinking mode (off/minimal/low/medium/high) |

### Multi-account Configuration

```json
{
  "channels": {
    "dingtalk": {
      "accounts": {
        "bot1": {
          "enabled": true,
          "clientId": "client-id-1",
          "clientSecret": "secret-1",
          "name": "Support Bot"
        },
        "bot2": {
          "enabled": true,
          "clientId": "client-id-2",
          "clientSecret": "secret-2",
          "name": "Dev Bot"
        }
      }
    }
  }
}
```

### Message Coalescing

Control how streaming messages are batched before sending:

```json
{
  "channels": {
    "dingtalk": {
      "coalesce": {
        "enabled": true,
        "minChars": 800,
        "maxChars": 1200,
        "idleMs": 1000
      }
    }
  }
}
```

## Running as a Service

### Using systemd (Linux)

Create `/etc/systemd/system/clawdbot.service`:

```ini
[Unit]
Description=Clawdbot Gateway
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/clawdbot gateway
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable clawdbot
sudo systemctl start clawdbot
```

### Using PM2

```bash
npm install -g pm2
pm2 start "clawdbot gateway" --name clawdbot
pm2 save
pm2 startup
```

## DingTalk Setup

1. Go to [DingTalk Open Platform](https://open.dingtalk.com/)
2. Create an Enterprise Internal Application
3. Enable "Robot" capability
4. Get Client ID and Client Secret from "Credentials & Basic Info"
5. Configure the robot's messaging subscription

## License

MIT
