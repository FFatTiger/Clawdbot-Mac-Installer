/**
 * 飞书长连接网关
 * 负责接收消息
 */

import * as lark from "@larksuiteoapi/node-sdk";
import type { ResolvedFeishuAccount, FeishuMessage } from "./types.js";
import { sendTextMessage } from "./client.js";

// WebSocket 客户端缓存
const wsClientCache = new Map<string, lark.WSClient>();

// 消息去重缓存 (messageId -> timestamp)
const processedMessages = new Map<string, number>();
const MESSAGE_DEDUPE_TTL_MS = 60 * 1000; // 60秒过期

/**
 * 清理过期的去重缓存
 */
function cleanupDedupeCache(): void {
  const now = Date.now();
  for (const [messageId, timestamp] of processedMessages) {
    if (now - timestamp > MESSAGE_DEDUPE_TTL_MS) {
      processedMessages.delete(messageId);
    }
  }
}

/**
 * 检查消息是否已处理过（前置去重）
 */
function isDuplicateMessage(messageId: string): boolean {
  if (processedMessages.has(messageId)) {
    return true;
  }
  processedMessages.set(messageId, Date.now());
  // 定期清理
  if (processedMessages.size > 100) {
    cleanupDedupeCache();
  }
  return false;
}

export interface GatewayOptions {
  account: ResolvedFeishuAccount;
  onMessage: (message: FeishuMessage) => Promise<void>;
  abortSignal?: AbortSignal;
  logger?: {
    info: (msg: string) => void;
    error: (msg: string) => void;
  };
}

/**
 * 启动飞书长连接网关
 */
export function startGateway(options: GatewayOptions): lark.WSClient {
  const { account, onMessage, abortSignal, logger } = options;
  const cacheKey = account.accountId;

  // 如果已存在，先停止
  const existing = wsClientCache.get(cacheKey);
  if (existing) {
    stopGateway(cacheKey);
  }

  const wsClient = new lark.WSClient({
    appId: account.appId,
    appSecret: account.appSecret,
    loggerLevel: lark.LoggerLevel.error,
  });

  // 监听 abortSignal，支持框架优雅停止
  if (abortSignal) {
    abortSignal.addEventListener("abort", () => {
      logger?.info("received abort signal, stopping gateway");
      stopGateway(cacheKey);
    }, { once: true });
  }

  wsClient.start({
    eventDispatcher: new lark.EventDispatcher({}).register({
      "im.message.receive_v1": async (data) => {
        const message = data.message;
        if (!message) return {};

        const messageId = message.message_id || "";

        // 前置去重检查
        if (isDuplicateMessage(messageId)) {
          return {};
        }

        const feishuMessage: FeishuMessage = {
          messageId,
          chatId: message.chat_id || "",
          chatType: message.chat_type === "p2p" ? "p2p" : "group",
          senderId: data.sender?.sender_id?.open_id || "",
          messageType: message.message_type || "",
          content: message.content || "",
        };

        // 解析文本内容
        if (feishuMessage.messageType === "text") {
          try {
            const parsed = JSON.parse(feishuMessage.content);
            feishuMessage.text = parsed.text;
          } catch {
            // ignore
          }
        }

        // 异步处理，不阻塞返回
        setImmediate(async () => {
          try {
            await onMessage(feishuMessage);
          } catch (error) {
            logger?.error(`Error handling message: ${error}`);
          }
        });

        // 立即返回，避免飞书超时重推
        return {};
      },
    }),
  });

  // 登录成功日志
  logger?.info(`logged in to feishu as ${account.appId}`);

  wsClientCache.set(cacheKey, wsClient);
  return wsClient;
}

/**
 * 停止网关
 */
export function stopGateway(accountId: string): void {
  const wsClient = wsClientCache.get(accountId);
  if (wsClient) {
    try {
      // 调用 SDK 提供的关闭方法（如果有的话）
      const client = wsClient as unknown as Record<string, unknown>;
      if (typeof client.close === "function") {
        (client.close as () => void)();
      } else if (typeof client.stop === "function") {
        (client.stop as () => void)();
      }
    } catch {
      // 忽略关闭错误
    }
    wsClientCache.delete(accountId);
  }
}
