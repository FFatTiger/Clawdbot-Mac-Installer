/**
 * DingTalk message types extracted from stream events.
 */
/**
 * Raw stream message envelope (varies across DingTalk versions)
 */
export interface RawStreamMessage {
    type?: string;
    eventType?: string;
    event_type?: string;
    headers?: RawHeaders;
    header?: RawHeaders;
    meta?: RawHeaders;
    data?: unknown;
    payload?: unknown;
    body?: unknown;
    event?: unknown;
    content?: unknown;
    messageId?: string;
    message_id?: string;
    id?: string;
    uuid?: string;
}
export interface RawHeaders {
    eventType?: string;
    event_type?: string;
    type?: string;
    topic?: string;
    messageId?: string;
    message_id?: string;
    contentType?: string;
}
/**
 * Parsed chatbot message with normalized fields.
 */
export interface ChatbotMessage {
    messageId: string;
    eventType: string;
    text: string;
    sessionWebhook: string;
    conversationId: string;
    chatType: string;
    senderId: string;
    senderName: string;
    raw: RawStreamMessage;
}
/**
 * Stream connection info from open API.
 */
export interface StreamConnectionInfo {
    endpoint: string;
    ticket?: string;
    raw: unknown;
}
/**
 * ACK message format for stream protocol.
 */
export interface StreamAck {
    code: number;
    headers: {
        messageId: string;
    };
    message: string;
}
/**
 * Stream client handle for stopping the connection.
 */
export interface StreamClientHandle {
    stop: () => void;
}
/**
 * Options for starting the stream client.
 */
export interface StreamClientOptions {
    clientId: string;
    clientSecret: string;
    apiBase: string;
    openPath: string;
    openBody?: Record<string, unknown>;
    logger?: StreamLogger;
    onChatMessage: (message: ChatbotMessage) => Promise<void>;
}
/**
 * Logger interface for stream client.
 */
export interface StreamLogger {
    debug?: (obj: Record<string, unknown>, msg?: string) => void;
    info?: (obj: Record<string, unknown> | string, msg?: string) => void;
    warn?: (obj: Record<string, unknown> | string, msg?: string) => void;
    error?: (obj: Record<string, unknown>, msg?: string) => void;
}
//# sourceMappingURL=types.d.ts.map