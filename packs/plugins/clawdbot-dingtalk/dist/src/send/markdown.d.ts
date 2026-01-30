/**
 * Markdown table conversion for DingTalk.
 * DingTalk's markdown renderer doesn't support tables well,
 * so we convert them to code blocks.
 */
export interface MarkdownOptions {
    tableMode?: "code" | "off";
}
/**
 * Convert markdown tables to code blocks for DingTalk compatibility.
 */
export declare function convertMarkdownForDingTalk(text: string, options?: MarkdownOptions): string;
//# sourceMappingURL=markdown.d.ts.map