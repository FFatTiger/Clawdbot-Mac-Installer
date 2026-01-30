/**
 * 飞书通道配置类型（单账号模式）
 */

export interface FeishuChannelConfig {
  /** 是否启用 */
  enabled?: boolean;
  /** 飞书应用 App ID */
  appId: string;
  /** 飞书应用 App Secret */
  appSecret: string;
}

export interface ResolvedFeishuAccount {
  accountId: string;
  appId: string;
  appSecret: string;
}

export interface FeishuMessage {
  messageId: string;
  chatId: string;
  chatType: "p2p" | "group";
  senderId: string;
  messageType: string;
  content: string;
  text?: string;
}
