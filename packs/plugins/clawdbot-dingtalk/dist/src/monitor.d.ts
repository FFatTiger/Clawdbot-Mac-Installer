/**
 * DingTalk monitor - starts the stream client and dispatches messages to Clawdbot.
 */
import type { ClawdbotConfig } from "clawdbot/plugin-sdk";
import type { ResolvedDingTalkAccount } from "./accounts.js";
import type { StreamClientHandle, StreamLogger } from "./stream/types.js";
export interface MonitorDingTalkOpts {
    account: ResolvedDingTalkAccount;
    config: ClawdbotConfig;
    abortSignal?: AbortSignal;
    log?: StreamLogger;
}
/**
 * Start monitoring DingTalk for incoming messages.
 */
export declare function monitorDingTalkProvider(opts: MonitorDingTalkOpts): Promise<StreamClientHandle>;
//# sourceMappingURL=monitor.d.ts.map