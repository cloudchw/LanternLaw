// entry/src/main/ets/models/Message.ets

/**
 * 消息类型枚举
 */
export enum MessageType {
  ENCOURAGEMENT = 'encouragement',
  REMINDER = 'reminder',
  CUSTOM = 'custom',
  REQUEST = 'request',
  FEEDBACK = 'feedback',
  SYSTEM = 'system'
}

/**
 * 家庭消息模型
 * Family Message Model
 */
export class FamilyMessage {
  id: string = '';
  senderAccountId: string = '';
  receiverAccountId: string = '';
  messageType: MessageType = MessageType.SYSTEM;
  content: string = '';
  isRead: boolean = false;
  createdAt: number = 0;

  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      senderAccountId: this.senderAccountId,
      receiverAccountId: this.receiverAccountId,
      messageType: this.messageType,
      content: this.content,
      isRead: this.isRead,
      createdAt: this.createdAt
    });
  }

  static fromJSON(json: string): FamilyMessage {
    const obj: Record<string, Object> = JSON.parse(json);
    const msg = new FamilyMessage();
    msg.id = (obj['id'] as string) ?? '';
    msg.senderAccountId = (obj['senderAccountId'] as string) ?? '';
    msg.receiverAccountId = (obj['receiverAccountId'] as string) ?? '';
    msg.messageType = (obj['messageType'] as MessageType) ?? MessageType.SYSTEM;
    msg.content = (obj['content'] as string) ?? '';
    msg.isRead = (obj['isRead'] as boolean) ?? false;
    msg.createdAt = (obj['createdAt'] as number) ?? 0;
    return msg;
  }

  clone(): FamilyMessage {
    return FamilyMessage.fromJSON(this.toJSON());
  }
}
