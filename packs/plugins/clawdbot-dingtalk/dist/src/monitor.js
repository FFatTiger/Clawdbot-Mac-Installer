/**
 * DingTalk monitor - starts the stream client and dispatches messages to Clawdbot.
 */
import { getDingTalkRuntime } from "./runtime.js";
import { startDingTalkStreamClient } from "./stream/client.js";
import { buildSessionKey, startsWithPrefix } from "./stream/message-parser.js";
import { sendReplyViaSessionWebhook, resolveResponsePrefix } from "./send/reply.js";
import { convertMarkdownForDingTalk } from "./send/markdown.js";
/**
 * Determine if message is a group chat.
 */
function isGroupChat(chatType) {
    return /group|chat|2|multi/i.test(chatType);
}
/**
 * Derive provider name from model string.
 */
function deriveProvider(model) {
    if (!model)
        return undefined;
    const m = model.toLowerCase();
    if (m.includes("claude") || m.includes("anthropic"))
        return "anthropic";
    if (m.includes("gpt") || m.includes("openai"))
        return "openai";
    if (m.includes("qwen") || m.includes("dashscope"))
        return "dashscope";
    if (m.includes("gemini") || m.includes("google"))
        return "google";
    if (m.includes("/"))
        return model.split("/")[0];
    return undefined;
}
/**
 * Start monitoring DingTalk for incoming messages.
 */
export async function monitorDingTalkProvider(opts) {
    const { account, config, abortSignal, log } = opts;
    const runtime = getDingTalkRuntime();
    // Parse custom subscriptions if provided
    let subscriptionsBody = null;
    if (account.subscriptionsJson?.trim()) {
        try {
            subscriptionsBody = JSON.parse(account.subscriptionsJson);
        }
        catch (err) {
            log?.warn?.({ err: err?.message }, "Invalid subscriptions JSON");
        }
    }
    const openBody = subscriptionsBody ?? {
        clientId: account.clientId,
        clientSecret: account.clientSecret,
        subscriptions: [{ type: "CALLBACK", topic: "/v1.0/im/bot/messages/get" }],
    };
    // Track response prefix per session (only apply once per conversation)
    const prefixApplied = new Set();
    const client = await startDingTalkStreamClient({
        clientId: account.clientId,
        clientSecret: account.clientSecret,
        apiBase: account.apiBase,
        openPath: account.openPath,
        openBody,
        logger: log,
        onChatMessage: async (chat) => {
            try {
                await handleInboundMessage(chat);
            }
            catch (err) {
                log?.error?.({ err: { message: err?.message } }, "Handler error");
            }
        },
    });
    // Handle abort signal
    if (abortSignal) {
        abortSignal.addEventListener("abort", () => {
            log?.info?.("Abort signal received, stopping DingTalk stream");
            client.stop();
        }, { once: true });
    }
    async function handleInboundMessage(chat) {
        // Filter: skip self messages
        if (account.selfUserId && chat.senderId === account.selfUserId) {
            return;
        }
        // Filter: allowlist
        if (account.allowFrom.length > 0 && chat.senderId) {
            if (!account.allowFrom.includes(chat.senderId)) {
                log?.info?.({ senderId: chat.senderId }, "Blocked sender (not in allowlist)");
                return;
            }
        }
        // Filter: require prefix (for group chats)
        if (account.requirePrefix && !startsWithPrefix(chat.text, account.requirePrefix)) {
            return;
        }
        const sessionKey = buildSessionKey(chat);
        const isGroup = isGroupChat(chat.chatType);
        log?.info?.({
            eventType: chat.eventType,
            senderId: chat.senderId,
            senderName: chat.senderName,
            conversationId: chat.conversationId,
            chatType: chat.chatType,
            sessionKey,
        }, "Inbound DingTalk message");
        // Build inbound context for Clawdbot
        const ctx = {
            Body: chat.text,
            RawBody: chat.text,
            CommandBody: chat.text,
            BodyForAgent: chat.text,
            BodyForCommands: chat.text,
            From: chat.senderId,
            To: chat.conversationId,
            SessionKey: sessionKey,
            AccountId: account.accountId,
            MessageSid: chat.messageId,
            ChatType: isGroup ? "group" : "direct",
            SenderName: chat.senderName,
            SenderId: chat.senderId,
            Provider: "dingtalk",
            Surface: "dingtalk",
            OriginatingChannel: "dingtalk",
            OriginatingTo: chat.conversationId,
            Timestamp: Date.now(),
        };
        // Create reply dispatcher that sends to DingTalk
        // The dispatcher uses `deliver` function with ReplyPayload signature
        let firstReply = true;
        const dispatcherOptions = {
            deliver: async (payload, info) => {
                log?.info?.({ kind: info.kind, hasText: !!payload.text, textLength: payload.text?.length ?? 0 }, "deliver called");
                const text = payload.text;
                if (!text?.trim()) {
                    log?.info?.("deliver: empty text, skipping");
                    return;
                }
                // Apply response prefix to first message only
                let processedText = text;
                if (firstReply && account.responsePrefix && !prefixApplied.has(sessionKey)) {
                    const prefix = resolveResponsePrefix(account.responsePrefix, {
                        model: undefined, // Will be filled from agent response
                        provider: undefined,
                    });
                    if (prefix) {
                        processedText = `${prefix} ${text}`;
                    }
                    prefixApplied.add(sessionKey);
                }
                firstReply = false;
                // Convert markdown tables if needed
                if (account.replyMode === "markdown" && account.tableMode !== "off") {
                    processedText = convertMarkdownForDingTalk(processedText, {
                        tableMode: account.tableMode,
                    });
                }
                await sendReplyViaSessionWebhook(chat.sessionWebhook, processedText, {
                    replyMode: account.replyMode,
                    maxChars: account.maxChars,
                    tableMode: account.tableMode,
                    logger: log,
                });
            },
            onError: (err, info) => {
                log?.error?.({ err: { message: err?.message }, kind: info.kind }, "Dispatcher delivery error");
            },
        };
        // Dispatch to Clawdbot agent
        try {
            log?.info?.("Calling dispatchReplyWithBufferedBlockDispatcher");
            const result = await runtime.channel.reply.dispatchReplyWithBufferedBlockDispatcher({
                ctx,
                cfg: config,
                dispatcherOptions,
            });
            log?.info?.({ result: JSON.stringify(result).slice(0, 200) }, "dispatchReplyWithBufferedBlockDispatcher completed");
        }
        catch (err) {
            log?.error?.({ err: { message: err?.message } }, "Agent dispatch error");
            // Send error message to user
            await sendReplyViaSessionWebhook(chat.sessionWebhook, "抱歉，处理您的消息时出现了错误。请稍后重试。", {
                replyMode: account.replyMode,
                maxChars: account.maxChars,
                logger: log,
            });
        }
    }
    return client;
}
//# sourceMappingURL=monitor.js.map