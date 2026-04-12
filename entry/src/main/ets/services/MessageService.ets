import { FamilyMessage, MessageType } from '../models/Message';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { ConfigSyncService } from './ConfigSyncService';
import { Logger } from '../utils/Logger';

const TAG = 'MessageService';

/**
 * 家长→儿童快捷消息模板
 */
export const PARENT_TEMPLATES: string[] = [
  '早点休息，明天还要上学呢',
  '你今天表现很棒，继续加油！',
  '记得先完成作业再玩手机',
  '屏幕时间快到了，准备放下手机吧',
  '我爱你，晚安！'
];

/**
 * 儿童→家长快捷消息模板
 */
export const CHILD_TEMPLATES: string[] = [
  '我知道了，我会注意的',
  '作业写完了！',
  '晚安，明天见！'
];

export class MessageService {
  private static instance: MessageService | null = null;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  private constructor() {}

  public static getInstance(): MessageService {
    if (!MessageService.instance) {
      MessageService.instance = new MessageService();
    }
    return MessageService.instance;
  }

  /**
   * 发送消息
   */
  public async sendMessage(
    senderId: string,
    receiverId: string,
    content: string,
    messageType: MessageType = MessageType.CUSTOM
  ): Promise<FamilyMessage> {
    const msg = new FamilyMessage();
    msg.id = `msg_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    msg.senderAccountId = senderId;
    msg.receiverAccountId = receiverId;
    msg.messageType = messageType;
    msg.content = content;
    msg.isRead = false;
    msg.createdAt = Date.now();

    await this.database.saveMessage(msg);

    // 同步到云端
    const syncService = ConfigSyncService.getInstance();
    if (syncService.getIsAvailable()) {
      syncService.uploadMessage(msg);
    }

    Logger.info(TAG, `消息已发送: ${senderId.substring(0, 6)} → ${receiverId.substring(0, 6)}: ${content.substring(0, 20)}`);
    return msg;
  }

  /**
   * 获取两个帐号之间的消息历史
   */
  public async getMessagesBetween(accountId1: string, accountId2: string): Promise<FamilyMessage[]> {
    return await this.database.getMessagesBetween(accountId1, accountId2);
  }

  /**
   * 获取某个帐号的未读消息数
   */
  public async getUnreadCount(accountId: string): Promise<number> {
    return await this.database.getUnreadMessageCount(accountId);
  }

  /**
   * 获取某个帐号收到的最新消息（用于卡片展示）
   */
  public async getLatestMessages(accountId: string, limit: number = 3): Promise<FamilyMessage[]> {
    if (!this.database.isInitialized()) {
      return [];
    }
    try {
      const allMessages = await this.database.getMessagesByReceiver(accountId);
      const unread = allMessages.filter((m: FamilyMessage) => !m.isRead);
      if (unread.length > 0) {
        return unread.slice(0, limit);
      }
      return allMessages.slice(0, limit);
    } catch (error) {
      Logger.error(TAG, `获取最新消息失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 标记消息为已读
   */
  public async markAsRead(receiverAccountId: string, senderAccountId?: string): Promise<void> {
    await this.database.markMessagesAsRead(receiverAccountId, senderAccountId);
    Logger.info(TAG, `消息已标记为已读: receiver=${receiverAccountId.substring(0, 6)}`);
  }
}
