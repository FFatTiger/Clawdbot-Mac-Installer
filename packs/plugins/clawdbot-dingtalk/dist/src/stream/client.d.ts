/**
 * DingTalk Stream API client.
 * Connects to DingTalk via WebSocket for receiving bot messages.
 */
import type { StreamClientHandle, StreamClientOptions } from "./types.js";
/**
 * Start DingTalk Stream client.
 * Maintains persistent WebSocket connection with auto-reconnect.
 */
export declare function startDingTalkStreamClient(options: StreamClientOptions): Promise<StreamClientHandle>;
//# sourceMappingURL=client.d.ts.map