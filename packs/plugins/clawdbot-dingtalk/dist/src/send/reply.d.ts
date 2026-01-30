/**
 * DingTalk reply implementation via sessionWebhook.
 */
export interface ReplyOptions {
    replyMode?: "text" | "markdown";
    maxChars?: number;
    tableMode?: "code" | "off";
    logger?: ReplyLogger;
}
export interface ReplyResult {
    ok: boolean;
    reason?: string;
    status?: number;
    data?: unknown;
    chunks?: number;
}
export interface ReplyLogger {
    debug?: (obj: Record<string, unknown>, msg?: string) => void;
    warn?: (obj: Record<string, unknown> | string, msg?: string) => void;
    error?: (obj: Record<string, unknown>, msg?: string) => void;
}
/**
 * Send reply to DingTalk via sessionWebhook.
 * Automatically chunks long messages.
 */
export declare function sendReplyViaSessionWebhook(sessionWebhook: string, text: string, options?: ReplyOptions): Promise<ReplyResult>;
/**
 * Resolve response prefix template with model context.
 */
export declare function resolveResponsePrefix(template: string | undefined, context: {
    model?: string;
    provider?: string;
    identity?: string;
}): string | undefined;
//# sourceMappingURL=reply.d.ts.map