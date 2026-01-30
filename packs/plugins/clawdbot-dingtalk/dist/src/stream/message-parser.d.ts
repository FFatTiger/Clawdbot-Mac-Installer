/**
 * Multi-path field extraction for DingTalk's unstable API schemas.
 * DingTalk stream payloads can have different field names/paths across versions.
 */
import type { ChatbotMessage, RawStreamMessage, StreamAck } from "./types.js";
/**
 * Extract chatbot message from raw stream event.
 * Returns null if this doesn't look like a chatbot message.
 */
export declare function extractChatbotMessage(raw: RawStreamMessage): ChatbotMessage | null;
/**
 * Build ACK message for stream protocol.
 */
export declare function buildAck(raw: RawStreamMessage): StreamAck | null;
/**
 * Build session key from chat message.
 * Groups share a conversation key, DMs use sender ID.
 */
export declare function buildSessionKey(chat: ChatbotMessage): string;
/**
 * Check if message text starts with required prefix (case-insensitive).
 */
export declare function startsWithPrefix(text: string, prefix: string | undefined): boolean;
//# sourceMappingURL=message-parser.d.ts.map