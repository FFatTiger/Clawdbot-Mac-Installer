/**
 * Text chunking utilities for DingTalk message limits.
 * Preserves markdown code fences and tries to break on natural boundaries.
 */
/**
 * Split long text into chunks under maxChars.
 * Tries to split on paragraph boundaries first, then lines, then punctuation.
 */
export declare function chunkText(text: string, maxChars: number): string[];
/**
 * Split markdown text into chunks, never breaking inside code fences.
 * Uses same chunking strategy as chunkText() but respects ``` and ~~~ blocks.
 */
export declare function chunkMarkdownText(text: string, maxChars: number): string[];
/**
 * Convert value to clean string.
 */
export declare function toCleanString(v: unknown): string;
/**
 * Normalize text for DingTalk messages.
 */
export declare function normalizeForTextMessage(text: string): string;
//# sourceMappingURL=chunker.d.ts.map