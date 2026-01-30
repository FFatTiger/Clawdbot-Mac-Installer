/**
 * 飞书通道插件定义
 */

import type {
  ChannelPlugin,
  ClawdbotConfig,
  ChannelOnboardingAdapter,
} from "clawdbot/plugin-sdk";
import type { ResolvedFeishuAccount, FeishuChannelConfig } from "./types.js";
import { sendTextMessage } from "./client.js";
import { startGateway } from "./gateway.js";
import { getFeishuRuntime } from "./runtime.js";
import type { MsgContext } from "./msg-context.js";

const DEFAULT_ACCOUNT_ID = "default";
const CHANNEL_ID = "feishu" as const;

/**
 * 获取飞书通道配置
 */
function getFeishuConfig(cfg: ClawdbotConfig): FeishuChannelConfig | undefined {
  return (cfg as any).channels?.feishu as FeishuChannelConfig | undefined;
}

/**
 * 从配置中获取飞书账号列表（单账号模式）
 */
function listFeishuAccountIds(cfg: ClawdbotConfig): string[] {
  const feishuCfg = getFeishuConfig(cfg);
  if (!feishuCfg || feishuCfg.enabled === false) return [];
  if (!feishuCfg.appId || !feishuCfg.appSecret) return [];
  return [DEFAULT_ACCOUNT_ID];
}

/**
 * 解析飞书账号配置（单账号模式）
 */
function resolveFeishuAccount(
  cfg: ClawdbotConfig,
  accountId: string
): ResolvedFeishuAccount | undefined {
  if (accountId !== DEFAULT_ACCOUNT_ID) return undefined;

  const feishuCfg = getFeishuConfig(cfg);
  if (!feishuCfg) return undefined;

  return {
    accountId: DEFAULT_ACCOUNT_ID,
    appId: feishuCfg.appId,
    appSecret: feishuCfg.appSecret,
  };
}

/**
 * 飞书 Onboarding Adapter
 * 用于 clawdbot onboard 交互式配置向导
 */
const feishuOnboardingAdapter: ChannelOnboardingAdapter = {
  channel: CHANNEL_ID,

  getStatus: async ({ cfg }) => {
    const feishuCfg = getFeishuConfig(cfg);
    const configured = !!(feishuCfg?.appId && feishuCfg?.appSecret);
    return {
      channel: CHANNEL_ID,
      configured,
      statusLines: [`Feishu: ${configured ? "configured" : "needs App ID & Secret"}`],
      selectionHint: configured ? "configured" : "needs credentials",
      quickstartScore: configured ? 2 : 1,
    };
  },

  configure: async (ctx) => {
    const { cfg, prompter } = ctx;
    let next = cfg;
    const currentCfg = getFeishuConfig(cfg);
    const hasAppId = !!currentCfg?.appId;
    const hasAppSecret = !!currentCfg?.appSecret;

    // 显示帮助信息
    await prompter.note(
      [
        "1) 登录飞书开放平台 → 创建企业自建应用",
        "2) 获取 App ID 和 App Secret",
        "3) 启用机器人能力，配置消息接收方式为「使用长连接接收消息」",
        "4) 发布应用并授权",
        "Docs: https://open.feishu.cn/document/home/develop-a-bot-in-5-minutes",
      ].join("\n"),
      "飞书机器人配置"
    );

    let appId: string | null = null;
    let appSecret: string | null = null;

    // App ID
    if (hasAppId) {
      const keep = await prompter.confirm({
        message: `App ID 已配置 (${currentCfg!.appId.slice(0, 8)}...)，是否保留？`,
        initialValue: true,
      });
      if (!keep) {
        appId = String(
          await prompter.text({
            message: "请输入飞书 App ID",
            validate: (value) => (value?.trim() ? undefined : "必填"),
          })
        ).trim();
      }
    } else {
      appId = String(
        await prompter.text({
          message: "请输入飞书 App ID",
          validate: (value) => (value?.trim() ? undefined : "必填"),
        })
      ).trim();
    }

    // App Secret
    if (hasAppSecret) {
      const keep = await prompter.confirm({
        message: "App Secret 已配置，是否保留？",
        initialValue: true,
      });
      if (!keep) {
        appSecret = String(
          await prompter.text({
            message: "请输入飞书 App Secret",
            validate: (value) => (value?.trim() ? undefined : "必填"),
          })
        ).trim();
      }
    } else {
      appSecret = String(
        await prompter.text({
          message: "请输入飞书 App Secret",
          validate: (value) => (value?.trim() ? undefined : "必填"),
        })
      ).trim();
    }

    // 更新配置
    next = {
      ...next,
      channels: {
        ...(next as any).channels,
        feishu: {
          ...(next as any).channels?.feishu,
          enabled: true,
          ...(appId ? { appId } : {}),
          ...(appSecret ? { appSecret } : {}),
        },
      },
    } as ClawdbotConfig;

    return { cfg: next, accountId: DEFAULT_ACCOUNT_ID };
  },

  disable: (cfg) => ({
    ...cfg,
    channels: {
      ...(cfg as any).channels,
      feishu: { ...(cfg as any).channels?.feishu, enabled: false },
    },
  } as ClawdbotConfig),
};

export const feishuPlugin: ChannelPlugin<ResolvedFeishuAccount> = {
  id: "feishu",

  meta: {
    id: "feishu",
    label: "Feishu",
    selectionLabel: "飞书 (Feishu/Lark)",
    docsPath: "https://open.feishu.cn/document",
    blurb: "飞书机器人通道，支持私聊和群聊",
  },

  capabilities: {
    chatTypes: ["direct", "group"],
    reactions: false,
    reply: true,
    media: true,
  },

  // Onboarding 配置向导
  onboarding: feishuOnboardingAdapter,

  config: {
    listAccountIds: (cfg) => listFeishuAccountIds(cfg),
    resolveAccount: (cfg, accountId) => resolveFeishuAccount(cfg, accountId),
    isConfigured: async (account) => !!(account.appId && account.appSecret),
  },

  outbound: {
    deliveryMode: "gateway",
    textChunkLimit: 4000,
    sendText: async (ctx) => {
      const account = ctx.account as ResolvedFeishuAccount;
      const result = await sendTextMessage(account, ctx.to, ctx.text);
      return {
        ok: result.ok,
        error: result.error ? new Error(result.error) : undefined,
      };
    },
  },

  gateway: {
    startAccount: async (ctx) => {
      const runtime = getFeishuRuntime();
      const account = ctx.account;
      const cfg = ctx.cfg;

      startGateway({
        account,
        abortSignal: ctx.abortSignal,
        onMessage: async (message) => {
          // 只处理文本消息
          if (message.messageType !== "text" || !message.text) {
            return;
          }

          // 打印收到的消息内容
          console.log(`[feishu:${account.accountId}] 收到消息: ${message.text}`);

          // 构建消息上下文
          const msgCtx: MsgContext = {
            From: message.senderId,
            Body: message.text,
            AccountId: account.accountId,
            Provider: "feishu",
            Surface: "feishu",
            SessionKey: `feishu:${account.accountId}:${message.chatId}`,
            To: message.chatId,
            ChatType: message.chatType === "p2p" ? "direct" : "group",
          };

          // 使用 dispatchReplyWithBufferedBlockDispatcher
          await runtime.channel.reply.dispatchReplyWithBufferedBlockDispatcher({
            ctx: msgCtx,
            cfg,
            dispatcherOptions: {
              deliver: async (payload) => {
                // 发送 AI 回复（普通发送，非回复）
                const text = payload.text ?? "";
                if (text) {
                  await sendTextMessage(account, message.chatId, text);
                }
              },
            },
          });
        },
        logger: {
          info: (msg) => console.log(`[feishu:${account.accountId}] ${msg}`),
          error: (msg) => console.error(`[feishu:${account.accountId}] ${msg}`),
        },
      });
    },
  },
};
