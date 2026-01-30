/**
 * DingTalk health probe utilities.
 */
import type { ResolvedDingTalkAccount } from "./accounts.js";
export interface ProbeResult {
    ok: boolean;
    error?: string;
    status?: number;
    elapsedMs?: number;
}
/**
 * Probe DingTalk API to verify credentials and connectivity.
 */
export declare function probeDingTalk(account: ResolvedDingTalkAccount, timeoutMs?: number): Promise<ProbeResult>;
//# sourceMappingURL=probe.d.ts.map