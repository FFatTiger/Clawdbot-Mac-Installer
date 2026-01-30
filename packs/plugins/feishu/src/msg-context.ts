/**
 * 消息上下文类型定义
 */

export type MsgContext = {
  From: string;
  Body: string;
  AccountId: string;
  Provider: string;
  Surface: string;
  SessionKey: string;
  To: string;
  ChatType: "direct" | "group";
};
