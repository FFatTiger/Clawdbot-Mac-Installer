/**
 * Multi-path field extraction for DingTalk's unstable API schemas.
 * DingTalk stream payloads can have different field names/paths across versions.
 */
/**
 * Safely access nested object property by dot-separated path.
 */
function get(obj, path) {
    if (!obj || typeof obj !== "object")
        return undefined;
    const parts = path.split(".");
    let cur = obj;
    for (const p of parts) {
        if (cur && typeof cur === "object" && p in cur) {
            cur = cur[p];
        }
        else {
            return undefined;
        }
    }
    return cur;
}
/**
 * Try multiple paths and return the first non-empty value.
 */
function first(obj, paths) {
    for (const p of paths) {
        const v = get(obj, p);
        if (v !== undefined && v !== null && v !== "")
            return v;
    }
    return undefined;
}
/**
 * Convert value to string, handling null/undefined.
 */
function asString(v) {
    if (v === undefined || v === null)
        return "";
    if (typeof v === "string")
        return v;
    return String(v);
}
/**
 * Extract chatbot message from raw stream event.
 * Returns null if this doesn't look like a chatbot message.
 */
export function extractChatbotMessage(raw) {
    // Common wrappers: { headers, data } / { header, payload } / etc
    const headers = raw?.headers ?? raw?.header ?? raw?.meta ?? {};
    let data = raw?.data ?? raw?.payload ?? raw?.body ?? raw?.event ?? raw?.content ?? raw;
    // DingTalk Stream may wrap data as a JSON string - parse it
    if (typeof data === "string" && data.startsWith("{")) {
        try {
            data = JSON.parse(data);
        }
        catch {
            // ignore parse errors
        }
    }
    const eventType = asString(first(raw, [
        "type",
        "eventType",
        "event_type",
        "headers.eventType",
        "headers.event_type",
        "header.eventType",
        "header.event_type",
        "headers.type",
    ]));
    const messageId = asString(first(raw, [
        "headers.messageId",
        "headers.message_id",
        "header.messageId",
        "header.message_id",
        "messageId",
        "message_id",
        "id",
        "uuid",
    ]));
    const sessionWebhook = asString(first(data, [
        "sessionWebhook",
        "session_webhook",
        "conversationSessionWebhook",
        "conversation.sessionWebhook",
        "context.sessionWebhook",
        "webhook",
    ]));
    // Try multiple paths for text content
    const text = asString(first(data, [
        "text.content",
        "text",
        "content.text",
        "content",
        "message.text",
        "msg.text",
        "data.text",
        "data.text.content",
    ]));
    const conversationId = asString(first(data, [
        "conversationId",
        "conversation_id",
        "conversation.conversationId",
        "conversation.id",
        "chatId",
        "chat_id",
        "openConversationId",
        "open_conversation_id",
    ]));
    const chatType = asString(first(data, [
        "conversationType",
        "conversation_type",
        "conversation.conversationType",
        "chatType",
        "chat_type",
    ]));
    const senderId = asString(first(data, [
        "senderStaffId",
        "sender.staffId",
        "senderId",
        "sender.id",
        "sender.userid",
        "userId",
        "user_id",
        "staffId",
    ]));
    const senderName = asString(first(data, [
        "senderNick",
        "sender.nick",
        "sender.name",
        "senderName",
        "userName",
        "user_name",
    ]));
    // DingTalk may wrap actual content in a JSON string
    let finalText = text;
    try {
        if (finalText && finalText.startsWith("{") && finalText.endsWith("}")) {
            const parsed = JSON.parse(finalText);
            const maybe = asString(first(parsed, ["text.content", "content", "text"]));
            if (maybe)
                finalText = maybe;
        }
    }
    catch {
        // ignore
    }
    // Decide whether this looks like a chatbot message
    const looksLikeChatbot = Boolean(sessionWebhook) ||
        /chatbot|bot|im\.|message/i.test(eventType) ||
        /chatbot|bot/i.test(asString(first(headers, ["topic", "eventType", "type"])));
    if (!looksLikeChatbot)
        return null;
    if (!finalText)
        return null;
    return {
        messageId,
        eventType,
        text: finalText,
        sessionWebhook,
        conversationId,
        chatType,
        senderId,
        senderName,
        raw,
    };
}
/**
 * Build ACK message for stream protocol.
 */
export function buildAck(raw) {
    const messageId = asString(first(raw, [
        "headers.messageId",
        "headers.message_id",
        "header.messageId",
        "header.message_id",
        "messageId",
        "message_id",
        "id",
        "uuid",
    ]));
    if (!messageId)
        return null;
    return {
        code: 200,
        headers: {
            messageId,
        },
        message: "OK",
    };
}
/**
 * Build session key from chat message.
 * Groups share a conversation key, DMs use sender ID.
 */
export function buildSessionKey(chat) {
    const conv = chat.conversationId || "unknownConv";
    const sender = chat.senderId || "unknownSender";
    const chatType = (chat.chatType || "").toLowerCase();
    const isGroup = /group|chat|2|multi/.test(chatType);
    return isGroup ? `dingtalk:group:${conv}` : `dingtalk:dm:${sender}`;
}
/**
 * Check if message text starts with required prefix (case-insensitive).
 */
export function startsWithPrefix(text, prefix) {
    if (!prefix)
        return true;
    return text.trim().toLowerCase().startsWith(prefix.trim().toLowerCase());
}
//# sourceMappingURL=message-parser.js.map