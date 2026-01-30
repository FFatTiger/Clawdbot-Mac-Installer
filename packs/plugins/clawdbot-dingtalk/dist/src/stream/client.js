/**
 * DingTalk Stream API client.
 * Connects to DingTalk via WebSocket for receiving bot messages.
 */
import WebSocket from "ws";
import { buildAck, extractChatbotMessage } from "./message-parser.js";
function sleep(ms) {
    return new Promise((r) => setTimeout(r, ms));
}
/**
 * Open stream connection via DingTalk API.
 */
async function openStreamConnection(params) {
    const { apiBase, openPath, openBody, logger } = params;
    const url = `${apiBase.replace(/\/$/, "")}${openPath}`;
    logger?.info?.({ url }, "Opening DingTalk stream connection");
    logger?.debug?.({ openBody: JSON.stringify(openBody).slice(0, 500) }, "Open request body");
    const resp = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(openBody),
        signal: AbortSignal.timeout(30_000),
    });
    if (!resp.ok) {
        throw new Error(`Stream open failed: ${resp.status} ${resp.statusText}`);
    }
    const data = (await resp.json());
    logger?.debug?.({ respData: JSON.stringify(data).slice(0, 500) }, "DingTalk stream open response");
    // Response shapes can vary. Try multiple candidates.
    const endpoint = data.endpoint ??
        data.data?.endpoint ??
        data.result?.endpoint ??
        data.socketUrl ??
        data.url;
    const ticket = data.ticket ??
        data.data?.ticket ??
        data.result?.ticket ??
        data.token;
    if (!endpoint) {
        throw new Error(`Stream open response missing endpoint. data=${JSON.stringify(data).slice(0, 500)}`);
    }
    return { endpoint, ticket, raw: data };
}
/**
 * Build WebSocket URL with ticket parameter.
 */
function buildWsUrl(endpoint, ticket) {
    if (!ticket)
        return endpoint;
    try {
        const u = new URL(endpoint);
        if (!u.searchParams.get("ticket"))
            u.searchParams.set("ticket", ticket);
        return u.toString();
    }
    catch {
        // If it's not a valid URL string, just append.
        const sep = endpoint.includes("?") ? "&" : "?";
        return `${endpoint}${sep}ticket=${encodeURIComponent(ticket)}`;
    }
}
/**
 * Start DingTalk Stream client.
 * Maintains persistent WebSocket connection with auto-reconnect.
 */
export async function startDingTalkStreamClient(options) {
    const { clientId, clientSecret, apiBase, openPath, openBody, logger, onChatMessage } = options;
    let stop = false;
    let attempt = 0;
    const baseOpenBody = openBody ?? {
        clientId,
        clientSecret,
    };
    async function loop() {
        while (!stop) {
            attempt += 1;
            let ws = null;
            try {
                const { endpoint, ticket } = await openStreamConnection({
                    apiBase,
                    openPath,
                    openBody: baseOpenBody,
                    logger,
                });
                const wsUrl = buildWsUrl(endpoint, ticket);
                logger?.info?.({ wsUrl: wsUrl.replace(/ticket=[^&]+/i, "ticket=***") }, "Connecting WebSocket");
                ws = new WebSocket(wsUrl, ticket ? { headers: { "x-dingtalk-ticket": ticket, ticket } } : undefined);
                ws.on("ping", (data) => {
                    logger?.debug?.({ data: data?.toString?.() }, "WebSocket ping received");
                });
                ws.on("pong", (data) => {
                    logger?.debug?.({ data: data?.toString?.() }, "WebSocket pong received");
                });
                ws.on("error", (err) => {
                    logger?.error?.({ err: err?.message }, "WebSocket error");
                });
                // Wait for connection to open
                await new Promise((resolve, reject) => {
                    const onOpen = () => {
                        cleanup();
                        resolve();
                    };
                    const onErr = (e) => {
                        cleanup();
                        reject(e);
                    };
                    const cleanup = () => {
                        ws?.off("open", onOpen);
                        ws?.off("error", onErr);
                    };
                    ws.on("open", onOpen);
                    ws.on("error", onErr);
                });
                logger?.info?.("WebSocket connected successfully");
                attempt = 0;
                // Handle incoming messages
                const currentWs = ws;
                ws.on("message", async (data) => {
                    logger?.debug?.({ rawLength: data?.length }, "WebSocket raw message received");
                    let msg = null;
                    try {
                        msg = JSON.parse(data.toString());
                    }
                    catch {
                        logger?.debug?.({ data: data.toString().slice(0, 200) }, "Non-JSON stream message (ignored)");
                        return;
                    }
                    // ACK early if possible
                    const ack = buildAck(msg);
                    if (ack) {
                        try {
                            currentWs.send(JSON.stringify(ack));
                        }
                        catch (e) {
                            logger?.debug?.({ e: e?.message }, "ACK send failed (ignored)");
                        }
                    }
                    const chat = extractChatbotMessage(msg);
                    if (!chat) {
                        logger?.debug?.({
                            eventType: msg?.headers?.eventType ?? msg?.type,
                            msgPreview: JSON.stringify(msg).slice(0, 500),
                        }, "Stream event ignored (not chatbot message)");
                        return;
                    }
                    await onChatMessage(chat);
                });
                // Wait for connection to close
                await new Promise((resolve) => {
                    ws.on("close", (code, reason) => {
                        logger?.warn?.({ code, reason: reason?.toString?.() }, "WebSocket closed");
                        resolve();
                    });
                });
            }
            catch (err) {
                logger?.error?.({ err: { message: err?.message } }, "Stream loop error");
            }
            finally {
                try {
                    ws?.close?.();
                }
                catch {
                    // ignore
                }
            }
            if (stop)
                break;
            // Reconnect with backoff
            const backoff = Math.min(30_000, 1000 * Math.pow(2, Math.min(attempt, 5)));
            logger?.info?.({ backoffMs: backoff }, "Reconnecting after backoff");
            await sleep(backoff);
        }
    }
    loop().catch((e) => logger?.error?.({ e: e?.message }, "Fatal stream loop error"));
    return {
        stop: () => {
            stop = true;
        },
    };
}
//# sourceMappingURL=client.js.map