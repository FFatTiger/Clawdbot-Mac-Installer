/**
 * DingTalk reply implementation via sessionWebhook.
 */
import { chunkText, chunkMarkdownText, normalizeForTextMessage } from "./chunker.js";
import { convertMarkdownForDingTalk } from "./markdown.js";
/**
 * Mask webhook URL for logging (hide query params).
 */
function maskWebhook(url) {
    if (!url)
        return "";
    try {
        const u = new URL(url);
        return `${u.origin}${u.pathname}`;
    }
    catch {
        return String(url).slice(0, 64) + "...";
    }
}
/**
 * Send reply to DingTalk via sessionWebhook.
 * Automatically chunks long messages.
 */
export async function sendReplyViaSessionWebhook(sessionWebhook, text, options = {}) {
    const { replyMode = "text", maxChars = 1800, tableMode = "code", logger } = options;
    if (!sessionWebhook) {
        logger?.warn?.("No sessionWebhook, cannot reply");
        return { ok: false, reason: "missing_sessionWebhook" };
    }
    let processedText = text;
    if (replyMode === "markdown" && tableMode !== "off") {
        processedText = convertMarkdownForDingTalk(processedText, { tableMode });
    }
    const cleaned = normalizeForTextMessage(processedText);
    const chunks = replyMode === "markdown"
        ? chunkMarkdownText(cleaned, maxChars)
        : chunkText(cleaned, maxChars);
    for (let i = 0; i < chunks.length; i++) {
        const part = chunks[i];
        const payload = replyMode === "markdown"
            ? {
                msgtype: "markdown",
                markdown: {
                    title: "Clawdbot",
                    text: part,
                },
            }
            : {
                msgtype: "text",
                text: {
                    content: part,
                },
            };
        try {
            const resp = await fetch(sessionWebhook, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload),
                signal: AbortSignal.timeout(30_000),
            });
            if (!resp.ok) {
                const data = await resp.text();
                logger?.error?.({ err: { message: `HTTP ${resp.status}`, status: resp.status, data }, webhook: maskWebhook(sessionWebhook) }, "Failed to reply DingTalk");
                return { ok: false, reason: "http_error", status: resp.status, data };
            }
            logger?.debug?.({ webhook: maskWebhook(sessionWebhook), idx: i + 1, total: chunks.length }, "Replied to DingTalk");
        }
        catch (err) {
            const error = err;
            logger?.error?.({ err: { message: error?.message }, webhook: maskWebhook(sessionWebhook) }, "Failed to reply DingTalk");
            return { ok: false, reason: "fetch_error" };
        }
    }
    return { ok: true, chunks: chunks.length };
}
/**
 * Response prefix template variable pattern.
 */
const TEMPLATE_VAR_PATTERN = /\{([a-zA-Z][a-zA-Z0-9.]*)\}/g;
/**
 * Resolve response prefix template with model context.
 */
export function resolveResponsePrefix(template, context) {
    if (template === undefined || template === null)
        return undefined;
    return template.replace(TEMPLATE_VAR_PATTERN, (match, varName) => {
        const normalized = varName.toLowerCase();
        switch (normalized) {
            case "model":
                return context.model ?? match;
            case "provider":
                return context.provider ?? match;
            case "identity":
                return context.identity ?? match;
            default:
                return match;
        }
    });
}
//# sourceMappingURL=reply.js.map