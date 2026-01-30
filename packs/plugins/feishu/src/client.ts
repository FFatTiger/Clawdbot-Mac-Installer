/**
 * 飞书消息客户端
 * 负责发送消息
 */

import * as lark from "@larksuiteoapi/node-sdk";
import type { ResolvedFeishuAccount } from "./types.js";

// 客户端缓存
const clientCache = new Map<string, lark.Client>();

/**
 * 获取或创建飞书客户端
 */
export function getFeishuClient(account: ResolvedFeishuAccount): lark.Client {
  // 只使用 appId 作为缓存 key，避免敏感信息泄露
  const cacheKey = account.appId;
  
  let client = clientCache.get(cacheKey);
  if (!client) {
    client = new lark.Client({
      appId: account.appId,
      appSecret: account.appSecret,
    });
    clientCache.set(cacheKey, client);
  }
  
  return client;
}

/**
 * 发送文本消息到会话
 */
export async function sendTextMessage(
  account: ResolvedFeishuAccount,
  chatId: string,
  text: string
): Promise<{ ok: boolean; error?: string }> {
  const client = getFeishuClient(account);
  
  try {
    const result = await client.im.v1.message.create({
      params: {
        receive_id_type: "chat_id",
      },
      data: {
        receive_id: chatId,
        msg_type: "text",
        content: JSON.stringify({ text }),
      },
    });
    
    if (result.code === 0) {
      return { ok: true };
    } else {
      return { ok: false, error: result.msg };
    }
  } catch (error) {
    return { ok: false, error: String(error) };
  }
}

/**
 * 回复指定消息
 */
export async function replyTextMessage(
  account: ResolvedFeishuAccount,
  messageId: string,
  text: string
): Promise<{ ok: boolean; error?: string }> {
  const client = getFeishuClient(account);
  
  try {
    const result = await client.im.v1.message.reply({
      path: {
        message_id: messageId,
      },
      data: {
        msg_type: "text",
        content: JSON.stringify({ text }),
      },
    });
    
    if (result.code === 0) {
      return { ok: true };
    } else {
      return { ok: false, error: result.msg };
    }
  } catch (error) {
    return { ok: false, error: String(error) };
  }
}
