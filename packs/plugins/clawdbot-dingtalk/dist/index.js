import { emptyPluginConfigSchema } from "clawdbot/plugin-sdk";
import { dingtalkPlugin } from "./src/channel.js";
import { setDingTalkRuntime } from "./src/runtime.js";
const plugin = {
    id: "clawdbot-dingtalk",
    name: "DingTalk",
    description: "DingTalk (钉钉) channel plugin for enterprise messaging",
    configSchema: emptyPluginConfigSchema(),
    register(api) {
        setDingTalkRuntime(api.runtime);
        api.registerChannel({ plugin: dingtalkPlugin });
    },
};
export default plugin;
//# sourceMappingURL=index.js.map