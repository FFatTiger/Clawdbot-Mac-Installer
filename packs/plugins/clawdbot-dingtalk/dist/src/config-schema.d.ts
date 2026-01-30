import { z } from "zod";
/**
 * Coalesce configuration for batching small messages before sending.
 */
export declare const CoalesceConfigSchema: z.ZodObject<{
    enabled: z.ZodDefault<z.ZodBoolean>;
    minChars: z.ZodDefault<z.ZodNumber>;
    maxChars: z.ZodDefault<z.ZodNumber>;
    idleMs: z.ZodDefault<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    enabled?: boolean;
    minChars?: number;
    maxChars?: number;
    idleMs?: number;
}, {
    enabled?: boolean;
    minChars?: number;
    maxChars?: number;
    idleMs?: number;
}>;
/**
 * DingTalk channel configuration schema.
 * Maps from YAML config under `channels.dingtalk.*`
 */
export declare const DingTalkConfigSchema: z.ZodObject<{
    /** Enable/disable the channel */
    enabled: z.ZodDefault<z.ZodBoolean>;
    /** DingTalk app client ID (required) */
    clientId: z.ZodOptional<z.ZodString>;
    /** DingTalk app client secret (required) */
    clientSecret: z.ZodOptional<z.ZodString>;
    /** Path to file containing client secret */
    clientSecretFile: z.ZodOptional<z.ZodString>;
    /** Display name for this account */
    name: z.ZodOptional<z.ZodString>;
    /** DingTalk API base URL */
    apiBase: z.ZodDefault<z.ZodString>;
    /** Stream open path */
    openPath: z.ZodDefault<z.ZodString>;
    /** Custom subscriptions JSON for stream */
    subscriptionsJson: z.ZodOptional<z.ZodString>;
    /** Reply mode: text or markdown */
    replyMode: z.ZodDefault<z.ZodEnum<["text", "markdown"]>>;
    /** Maximum characters per message chunk */
    maxChars: z.ZodDefault<z.ZodNumber>;
    /** Allowlist of sender IDs (empty = allow all) */
    allowFrom: z.ZodDefault<z.ZodArray<z.ZodString, "many">>;
    /** Bot's own user ID to skip self-messages */
    selfUserId: z.ZodOptional<z.ZodString>;
    /** Require messages to start with this prefix (for group filtering) */
    requirePrefix: z.ZodOptional<z.ZodString>;
    /** Prefix to add to response messages (supports {model}, {provider} vars) */
    responsePrefix: z.ZodOptional<z.ZodString>;
    /** Table conversion mode for markdown */
    tableMode: z.ZodDefault<z.ZodEnum<["code", "off"]>>;
    /** Message coalescing configuration */
    coalesce: z.ZodOptional<z.ZodObject<{
        enabled: z.ZodDefault<z.ZodBoolean>;
        minChars: z.ZodDefault<z.ZodNumber>;
        maxChars: z.ZodDefault<z.ZodNumber>;
        idleMs: z.ZodDefault<z.ZodNumber>;
    }, "strip", z.ZodTypeAny, {
        enabled?: boolean;
        minChars?: number;
        maxChars?: number;
        idleMs?: number;
    }, {
        enabled?: boolean;
        minChars?: number;
        maxChars?: number;
        idleMs?: number;
    }>>;
    /** Show tool status messages (🔧 正在执行...) */
    showToolStatus: z.ZodDefault<z.ZodBoolean>;
    /** Show tool result messages (✅ ... 完成) */
    showToolResult: z.ZodDefault<z.ZodBoolean>;
    /** Thinking mode for Clawdbot */
    thinking: z.ZodDefault<z.ZodEnum<["off", "minimal", "low", "medium", "high"]>>;
    /** Multi-account configuration */
    accounts: z.ZodOptional<z.ZodRecord<z.ZodString, z.ZodObject<{
        enabled: z.ZodDefault<z.ZodBoolean>;
        clientId: z.ZodOptional<z.ZodString>;
        clientSecret: z.ZodOptional<z.ZodString>;
        clientSecretFile: z.ZodOptional<z.ZodString>;
        name: z.ZodOptional<z.ZodString>;
        apiBase: z.ZodOptional<z.ZodString>;
        openPath: z.ZodOptional<z.ZodString>;
        subscriptionsJson: z.ZodOptional<z.ZodString>;
        replyMode: z.ZodOptional<z.ZodEnum<["text", "markdown"]>>;
        maxChars: z.ZodOptional<z.ZodNumber>;
        allowFrom: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
        selfUserId: z.ZodOptional<z.ZodString>;
        requirePrefix: z.ZodOptional<z.ZodString>;
        responsePrefix: z.ZodOptional<z.ZodString>;
        tableMode: z.ZodOptional<z.ZodEnum<["code", "off"]>>;
        coalesce: z.ZodOptional<z.ZodObject<{
            enabled: z.ZodDefault<z.ZodBoolean>;
            minChars: z.ZodDefault<z.ZodNumber>;
            maxChars: z.ZodDefault<z.ZodNumber>;
            idleMs: z.ZodDefault<z.ZodNumber>;
        }, "strip", z.ZodTypeAny, {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        }, {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        }>>;
        showToolStatus: z.ZodOptional<z.ZodBoolean>;
        showToolResult: z.ZodOptional<z.ZodBoolean>;
        thinking: z.ZodOptional<z.ZodEnum<["off", "minimal", "low", "medium", "high"]>>;
    }, "strip", z.ZodTypeAny, {
        enabled?: boolean;
        maxChars?: number;
        clientId?: string;
        clientSecret?: string;
        clientSecretFile?: string;
        name?: string;
        apiBase?: string;
        openPath?: string;
        subscriptionsJson?: string;
        replyMode?: "text" | "markdown";
        allowFrom?: string[];
        selfUserId?: string;
        requirePrefix?: string;
        responsePrefix?: string;
        tableMode?: "code" | "off";
        coalesce?: {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        };
        showToolStatus?: boolean;
        showToolResult?: boolean;
        thinking?: "off" | "minimal" | "low" | "medium" | "high";
    }, {
        enabled?: boolean;
        maxChars?: number;
        clientId?: string;
        clientSecret?: string;
        clientSecretFile?: string;
        name?: string;
        apiBase?: string;
        openPath?: string;
        subscriptionsJson?: string;
        replyMode?: "text" | "markdown";
        allowFrom?: string[];
        selfUserId?: string;
        requirePrefix?: string;
        responsePrefix?: string;
        tableMode?: "code" | "off";
        coalesce?: {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        };
        showToolStatus?: boolean;
        showToolResult?: boolean;
        thinking?: "off" | "minimal" | "low" | "medium" | "high";
    }>>>;
}, "strip", z.ZodTypeAny, {
    enabled?: boolean;
    maxChars?: number;
    clientId?: string;
    clientSecret?: string;
    clientSecretFile?: string;
    name?: string;
    apiBase?: string;
    openPath?: string;
    subscriptionsJson?: string;
    replyMode?: "text" | "markdown";
    allowFrom?: string[];
    selfUserId?: string;
    requirePrefix?: string;
    responsePrefix?: string;
    tableMode?: "code" | "off";
    coalesce?: {
        enabled?: boolean;
        minChars?: number;
        maxChars?: number;
        idleMs?: number;
    };
    showToolStatus?: boolean;
    showToolResult?: boolean;
    thinking?: "off" | "minimal" | "low" | "medium" | "high";
    accounts?: Record<string, {
        enabled?: boolean;
        maxChars?: number;
        clientId?: string;
        clientSecret?: string;
        clientSecretFile?: string;
        name?: string;
        apiBase?: string;
        openPath?: string;
        subscriptionsJson?: string;
        replyMode?: "text" | "markdown";
        allowFrom?: string[];
        selfUserId?: string;
        requirePrefix?: string;
        responsePrefix?: string;
        tableMode?: "code" | "off";
        coalesce?: {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        };
        showToolStatus?: boolean;
        showToolResult?: boolean;
        thinking?: "off" | "minimal" | "low" | "medium" | "high";
    }>;
}, {
    enabled?: boolean;
    maxChars?: number;
    clientId?: string;
    clientSecret?: string;
    clientSecretFile?: string;
    name?: string;
    apiBase?: string;
    openPath?: string;
    subscriptionsJson?: string;
    replyMode?: "text" | "markdown";
    allowFrom?: string[];
    selfUserId?: string;
    requirePrefix?: string;
    responsePrefix?: string;
    tableMode?: "code" | "off";
    coalesce?: {
        enabled?: boolean;
        minChars?: number;
        maxChars?: number;
        idleMs?: number;
    };
    showToolStatus?: boolean;
    showToolResult?: boolean;
    thinking?: "off" | "minimal" | "low" | "medium" | "high";
    accounts?: Record<string, {
        enabled?: boolean;
        maxChars?: number;
        clientId?: string;
        clientSecret?: string;
        clientSecretFile?: string;
        name?: string;
        apiBase?: string;
        openPath?: string;
        subscriptionsJson?: string;
        replyMode?: "text" | "markdown";
        allowFrom?: string[];
        selfUserId?: string;
        requirePrefix?: string;
        responsePrefix?: string;
        tableMode?: "code" | "off";
        coalesce?: {
            enabled?: boolean;
            minChars?: number;
            maxChars?: number;
            idleMs?: number;
        };
        showToolStatus?: boolean;
        showToolResult?: boolean;
        thinking?: "off" | "minimal" | "low" | "medium" | "high";
    }>;
}>;
export type DingTalkConfig = z.infer<typeof DingTalkConfigSchema>;
export type CoalesceConfig = z.infer<typeof CoalesceConfigSchema>;
/**
 * Default values for coalesce config
 */
export declare const DEFAULT_COALESCE: CoalesceConfig;
/**
 * Default account ID when not using multi-account
 */
export declare const DEFAULT_ACCOUNT_ID = "default";
//# sourceMappingURL=config-schema.d.ts.map