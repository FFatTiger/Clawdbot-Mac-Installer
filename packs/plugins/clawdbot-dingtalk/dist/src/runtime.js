let runtime = null;
export function setDingTalkRuntime(next) {
    runtime = next;
}
export function getDingTalkRuntime() {
    if (!runtime) {
        throw new Error("DingTalk runtime not initialized");
    }
    return runtime;
}
//# sourceMappingURL=runtime.js.map