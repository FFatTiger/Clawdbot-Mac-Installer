/**
 * Markdown table conversion for DingTalk.
 * DingTalk's markdown renderer doesn't support tables well,
 * so we convert them to code blocks.
 */
/**
 * Convert markdown tables to code blocks for DingTalk compatibility.
 */
export function convertMarkdownForDingTalk(text, options = {}) {
    const tableMode = options.tableMode ?? "code";
    if (tableMode === "off")
        return text;
    const lines = text.split("\n");
    let inTable = false;
    let tableLines = [];
    const result = [];
    for (const line of lines) {
        const isTableLine = line.trim().startsWith("|") && line.includes("|");
        if (isTableLine) {
            if (!inTable) {
                inTable = true;
                tableLines = [];
            }
            tableLines.push(line);
        }
        else {
            if (inTable) {
                result.push("```");
                result.push(...tableLines);
                result.push("```");
                tableLines = [];
                inTable = false;
            }
            result.push(line);
        }
    }
    if (inTable) {
        result.push("```");
        result.push(...tableLines);
        result.push("```");
    }
    return result.join("\n");
}
//# sourceMappingURL=markdown.js.map