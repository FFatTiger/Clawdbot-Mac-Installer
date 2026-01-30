/**
 * DingTalk Channel Plugin for Clawdbot.
 */
import { listDingTalkAccountIds, resolveDingTalkAccount, resolveDefaultDingTalkAccountId, isDingTalkAccountConfigured, } from "./accounts.js";
import { DEFAULT_ACCOUNT_ID } from "./config-schema.js";
import { chunkMarkdownText } from "./send/chunker.js";
import { monitorDingTalkProvider } from "./monitor.js";
import { probeDingTalk } from "./probe.js";
/**
 * Adapt clawdbot SubsystemLogger to StreamLogger interface.
 * Clawdbot uses (message, meta) order, our StreamLogger uses (obj, msg) order.
 */
function adaptLogger(log) {
    if (!log)
        return undefined;
    return {
        info: (obj, msg) => {
            const message = msg ?? (typeof obj === 'string' ? obj : JSON.stringify(obj));
            log.info?.(message, typeof obj === 'object' ? obj : undefined);
        },
        debug: (obj, msg) => {
            const message = msg ?? (typeof obj === 'string' ? obj : JSON.stringify(obj));
            log.debug?.(message, typeof obj === 'object' ? obj : undefined);
        },
        warn: (obj, msg) => {
            const message = msg ?? (typeof obj === 'string' ? obj : JSON.stringify(obj));
            log.warn?.(message, typeof obj === 'object' ? obj : undefined);
        },
        error: (obj, msg) => {
            const message = msg ?? (typeof obj === 'string' ? obj : JSON.stringify(obj));
            log.error?.(message, typeof obj === 'object' ? obj : undefined);
        },
    };
}
/**
 * Channel metadata.
 */
const meta = {
    id: "dingtalk",
    label: "DingTalk",
    selectionLabel: "钉钉 (DingTalk)",
    blurb: "Enterprise messaging platform by Alibaba",
    docsPath: "/docs/channels/dingtalk",
    order: 50,
    aliases: ["dingding", "钉钉"],
    systemImage: "dingtalk",
};
/**
 * Channel capabilities.
 */
const capabilities = {
    chatTypes: ["direct", "group"],
    reactions: false,
    threads: false,
    media: false, // TODO: Add media support later
    nativeCommands: false,
    blockStreaming: true, // Use block-based streaming for DingTalk
};
/**
 * DingTalk channel plugin.
 */
export const dingtalkPlugin = {
    id: "dingtalk",
    meta,
    capabilities,
    reload: { configPrefixes: ["channels.dingtalk"] },
    // Config schema for Control UI
    configSchema: {
        schema: {
            type: "object",
            properties: {
                enabled: { type: "boolean", default: true },
                clientId: { type: "string" },
                clientSecret: { type: "string" },
                clientSecretFile: { type: "string" },
                replyMode: { type: "string", enum: ["text", "markdown"], default: "markdown" },
                maxChars: { type: "number", default: 1800 },
                tableMode: { type: "string", enum: ["off", "list", "html"], default: "list" },
                responsePrefix: { type: "string" },
                requirePrefix: { type: "string" },
                allowFrom: { type: "array", items: { type: "string" } },
                selfUserId: { type: "string" },
                apiBase: { type: "string" },
                openPath: { type: "string" },
                subscriptionsJson: { type: "string" },
            },
        },
        uiHints: {
            enabled: { label: "启用", help: "是否启用钉钉渠道" },
            clientId: { label: "Client ID", help: "钉钉机器人的 Client ID（AppKey）", placeholder: "dingo..." },
            clientSecret: { label: "Client Secret", help: "钉钉机器人的 Client Secret（AppSecret）", sensitive: true },
            clientSecretFile: { label: "Client Secret 文件", help: "包含 Client Secret 的文件路径（替代直接配置）", advanced: true },
            replyMode: { label: "回复模式", help: "消息格式：text（纯文本）或 markdown" },
            maxChars: { label: "最大字符数", help: "单条消息最大字符数（超出将分段发送）" },
            tableMode: { label: "表格模式", help: "Markdown 表格处理方式：off（保留）、list（转为列表）、html（转为 HTML）", advanced: true },
            responsePrefix: { label: "回复前缀", help: "添加到回复开头的文本（支持 {{model}} 等变量）", advanced: true },
            requirePrefix: { label: "触发前缀", help: "群聊中需要以此前缀开头才会响应", advanced: true },
            allowFrom: { label: "允许发送者", help: "允许发送消息的用户 ID 列表（空表示允许所有）", advanced: true },
            selfUserId: { label: "机器人用户 ID", help: "机器人自身的用户 ID，用于过滤自己的消息", advanced: true },
            apiBase: { label: "API 基础 URL", help: "钉钉 API 基础地址（默认：https://api.dingtalk.com）", advanced: true },
            openPath: { label: "Open Path", help: "Stream 连接路径（默认：/v1.0/gateway/connections/open）", advanced: true },
            subscriptionsJson: { label: "订阅配置 JSON", help: "自定义订阅配置 JSON（高级用法）", advanced: true },
        },
    },
    config: {
        listAccountIds: (cfg) => listDingTalkAccountIds(cfg),
        resolveAccount: (cfg, accountId) => resolveDingTalkAccount({ cfg, accountId }),
        defaultAccountId: (cfg) => resolveDefaultDingTalkAccountId(cfg),
        setAccountEnabled: ({ cfg, accountId, enabled }) => {
            const dingtalk = cfg.channels?.dingtalk;
            if (!dingtalk)
                return cfg;
            if (accountId === DEFAULT_ACCOUNT_ID) {
                return {
                    ...cfg,
                    channels: {
                        ...cfg.channels,
                        dingtalk: { ...dingtalk, enabled },
                    },
                };
            }
            const accounts = (dingtalk.accounts ?? {});
            const account = (accounts[accountId] ?? {});
            return {
                ...cfg,
                channels: {
                    ...cfg.channels,
                    dingtalk: {
                        ...dingtalk,
                        accounts: {
                            ...accounts,
                            [accountId]: { ...account, enabled },
                        },
                    },
                },
            };
        },
        deleteAccount: ({ cfg, accountId }) => {
            const dingtalk = cfg.channels?.dingtalk;
            if (!dingtalk)
                return cfg;
            if (accountId === DEFAULT_ACCOUNT_ID) {
                // Clear base-level credentials
                const { clientId, clientSecret, clientSecretFile, ...rest } = dingtalk;
                return {
                    ...cfg,
                    channels: {
                        ...cfg.channels,
                        dingtalk: rest,
                    },
                };
            }
            const accounts = { ...(dingtalk.accounts ?? {}) };
            delete accounts[accountId];
            return {
                ...cfg,
                channels: {
                    ...cfg.channels,
                    dingtalk: {
                        ...dingtalk,
                        accounts: Object.keys(accounts).length > 0 ? accounts : undefined,
                    },
                },
            };
        },
        isConfigured: (account) => isDingTalkAccountConfigured(account),
        describeAccount: (account) => ({
            accountId: account.accountId,
            name: account.name,
            enabled: account.enabled,
            configured: isDingTalkAccountConfigured(account),
            credentialSource: account.credentialSource,
        }),
        resolveAllowFrom: ({ cfg, accountId }) => {
            const account = resolveDingTalkAccount({ cfg, accountId });
            return account.allowFrom;
        },
        formatAllowFrom: ({ allowFrom }) => allowFrom
            .map((entry) => String(entry).trim())
            .filter(Boolean)
            .map((entry) => entry.replace(/^dingtalk:/i, "")),
    },
    outbound: {
        deliveryMode: "direct",
        chunker: (text, limit) => chunkMarkdownText(text, limit),
        chunkerMode: "markdown",
        textChunkLimit: 1800,
        sendText: async ({ to, text, cfg, accountId }) => {
            // DingTalk requires sessionWebhook for sending, which is only available
            // during active conversations. For proactive messaging, we'd need a
            // different API. For now, return not supported.
            // In practice, replies are sent via the monitor's sendBlock dispatcher.
            return {
                channel: "dingtalk",
                ok: false,
                error: new Error("DingTalk requires active session webhook for sending"),
            };
        },
    },
    status: {
        defaultRuntime: {
            accountId: DEFAULT_ACCOUNT_ID,
            running: false,
            lastStartAt: null,
            lastStopAt: null,
            lastError: null,
        },
        probeAccount: async ({ account, timeoutMs }) => {
            return probeDingTalk(account, timeoutMs);
        },
        buildAccountSnapshot: ({ account, runtime }) => ({
            accountId: account.accountId,
            name: account.name,
            enabled: account.enabled,
            configured: isDingTalkAccountConfigured(account),
            credentialSource: account.credentialSource,
            running: runtime?.running ?? false,
            lastStartAt: runtime?.lastStartAt ?? null,
            lastStopAt: runtime?.lastStopAt ?? null,
            lastError: runtime?.lastError ?? null,
            mode: "stream",
        }),
        buildChannelSummary: ({ snapshot }) => ({
            configured: snapshot.configured ?? false,
            credentialSource: snapshot.credentialSource ?? "none",
            running: snapshot.running ?? false,
            mode: snapshot.mode ?? "stream",
            lastStartAt: snapshot.lastStartAt ?? null,
            lastStopAt: snapshot.lastStopAt ?? null,
            lastError: snapshot.lastError ?? null,
        }),
    },
    gateway: {
        startAccount: async (ctx) => {
            const { account, cfg, abortSignal, log } = ctx;
            if (!isDingTalkAccountConfigured(account)) {
                throw new Error(`DingTalk credentials not configured for account "${account.accountId}". ` +
                    `Set channels.dingtalk.clientId and channels.dingtalk.clientSecret.`);
            }
            log?.info?.(`[${account.accountId}] starting DingTalk stream provider`);
            return monitorDingTalkProvider({
                account,
                config: cfg,
                abortSignal,
                log: adaptLogger(log),
            });
        },
    },
};
//# sourceMappingURL=channel.js.map