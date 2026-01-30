import type { ClawdbotConfig } from "clawdbot/plugin-sdk";
import { type CoalesceConfig } from "./config-schema.js";
/**
 * Resolved DingTalk account with normalized configuration.
 */
export type ResolvedDingTalkAccount = {
    accountId: string;
    name?: string;
    enabled: boolean;
    clientId: string;
    clientSecret: string;
    credentialSource: "env" | "config" | "file" | "none";
    apiBase: string;
    openPath: string;
    subscriptionsJson?: string;
    replyMode: "text" | "markdown";
    maxChars: number;
    tableMode: "code" | "off";
    coalesce: CoalesceConfig;
    allowFrom: string[];
    selfUserId?: string;
    requirePrefix?: string;
    responsePrefix?: string;
    showToolStatus: boolean;
    showToolResult: boolean;
    thinking: "off" | "minimal" | "low" | "medium" | "high";
};
/**
 * List all configured account IDs.
 */
export declare function listDingTalkAccountIds(cfg: ClawdbotConfig): string[];
/**
 * Resolve the default account ID.
 */
export declare function resolveDefaultDingTalkAccountId(cfg: ClawdbotConfig): string;
/**
 * Resolve a specific DingTalk account by ID.
 */
export declare function resolveDingTalkAccount(params: {
    cfg: ClawdbotConfig;
    accountId?: string | null;
}): ResolvedDingTalkAccount;
/**
 * Check if account has valid credentials
 */
export declare function isDingTalkAccountConfigured(account: ResolvedDingTalkAccount): boolean;
//# sourceMappingURL=accounts.d.ts.map