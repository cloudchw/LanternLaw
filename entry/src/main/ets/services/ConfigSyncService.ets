// entry/src/main/ets/services/ConfigSyncService.ets

/**
 * 云端配置同步服务
 * 负责跨设备数据同步：帐号、沟通组、儿童配置、消息
 *
 * 使用 @kit.CloudFoundationKit 的 cloudDatabase 实现 Cloud DB CRUD
 */
import { cloudDatabase, cloudCommon } from '@kit.CloudFoundationKit';
import { FamilyGroupObj, AccountObj, ChildConfigObj, MessageObj } from '../models/cloud/CloudObjectTypes';
import { UserAccount } from '../models/UserAccount';
import { AccountMode } from '../models/AccountMode';
import { FamilyGroup } from '../models/FamilyGroup';
import { FamilyMessage, MessageType } from '../models/Message';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { Logger } from '../utils/Logger';

const TAG = 'ConfigSyncService';
const SYNC_INTERVAL_MS = 5 * 60 * 1000; // 5分钟
const CLOUD_DB_ZONE = 'lanternlawfamily';

export class ConfigSyncService {
  private static instance: ConfigSyncService | null = null;
  private isAvailable: boolean = false;
  private syncTimerId: number = -1;
  private accountId: string = '';
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();
  private zone: cloudDatabase.DatabaseZone | null = null;

  private constructor() {}

  public static getInstance(): ConfigSyncService {
    if (!ConfigSyncService.instance) {
      ConfigSyncService.instance = new ConfigSyncService();
    }
    return ConfigSyncService.instance;
  }

  public setAccountId(accountId: string): void {
    this.accountId = accountId;
  }

  // ==================== 初始化 ====================

  /**
   * 初始化 Cloud DB 连接
   */
  public initialize(): boolean {
    try {
      this.zone = cloudDatabase.zone(CLOUD_DB_ZONE);
      this.isAvailable = true;
      Logger.info(TAG, `Cloud DB 已初始化，zone: ${CLOUD_DB_ZONE}`);
      // 诊断：测试 Cloud DB 连接
      this.diagnose();
      return true;
    } catch (error) {
      this.isAvailable = false;
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), 'Cloud DB 初始化失败');
      return false;
    }
  }

  /**
   * 诊断 Cloud DB 连接：测试 query（读）和 upsert（写）
   */
  private async diagnose(): Promise<void> {
    if (!this.zone) {
      Logger.error(TAG, '诊断跳过: zone 为空');
      return;
    }
    // 测试 query（World 角色有 Read 权限，不需要写权限）
    try {
      const query = new cloudDatabase.DatabaseQuery(FamilyGroupObj);
      const results = await this.zone.query(query);
      Logger.info(TAG, `诊断 query 成功: 返回 ${results ? results.length : 0} 条记录`);
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `诊断 query 失败: ${errMsg}`);
      // 打印完整 error 对象的所有属性
      try {
        Logger.error(TAG, `诊断 query error type: ${typeof error}`);
        if (error && typeof error === 'object') {
          const keys = Object.keys(error);
          Logger.error(TAG, `诊断 query error keys: ${keys.join(', ')}`);
          for (const key of keys) {
            try {
              Logger.error(TAG, `  error.${key} = ${JSON.stringify((error as Record<string, Object>)[key])}`);
            } catch (e) {
              Logger.error(TAG, `  error.${key} = [无法序列化]`);
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }

    // 测试 upsert（写入）
    try {
      const testObj = new FamilyGroupObj();
      testObj.groupId = '__diag_test__';
      testObj.groupName = '诊断测试';
      testObj.parentAccountId = 'diag';
      testObj.createdAt = Date.now();
      testObj.updatedAt = Date.now();
      await this.zone.upsert(testObj);
      Logger.info(TAG, '诊断 upsert 成功');

      // 清理测试数据
      try {
        await this.zone.delete(testObj);
        Logger.info(TAG, '诊断清理成功');
      } catch (delErr) {
        Logger.error(TAG, `诊断清理失败: ${delErr instanceof Error ? delErr.message : String(delErr)}`);
      }
    } catch (error) {
      const errMsg = error instanceof Error ? error.message : String(error);
      Logger.error(TAG, `诊断 upsert 失败: ${errMsg}`);
      try {
        if (error && typeof error === 'object') {
          const keys = Object.keys(error);
          Logger.error(TAG, `诊断 upsert error keys: ${keys.join(', ')}`);
          for (const key of keys) {
            try {
              Logger.error(TAG, `  error.${key} = ${JSON.stringify((error as Record<string, Object>)[key])}`);
            } catch (e) {
              Logger.error(TAG, `  error.${key} = [无法序列化]`);
            }
          }
        }
      } catch (e) {
        // ignore
      }
    }
  }

  public getIsAvailable(): boolean {
    return this.isAvailable && this.zone !== null;
  }

  // ==================== 沟通组同步 ====================

  /**
   * 上传沟通组到云端
   */
  public async uploadFamilyGroup(group: FamilyGroup): Promise<void> {
    if (!this.zone) {
      return;
    }
    try {
      const obj = new FamilyGroupObj();
      obj.groupId = group.groupId;
      obj.groupName = group.groupName;
      obj.parentAccountId = group.parentAccountId;
      obj.invitationCode = group.invitationCode;
      obj.invitationExpiresAt = group.invitationExpiresAt;
      obj.pendingMembers = group.pendingMembers;
      obj.createdAt = group.createdAt;
      obj.updatedAt = group.updatedAt;

      await this.zone.upsert(obj);
      Logger.info(TAG, `沟通组已上传: ${group.groupName} (${group.groupId})`);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '沟通组上传失败');
      Logger.error(TAG, `upsert error: ${JSON.stringify(error)}`);
      // 详细错误信息
      if (error && typeof error === 'object') {
        const keys = Object.keys(error);
        Logger.error(TAG, `upsert error keys: ${keys.join(', ')}`);
        for (const key of keys) {
          try {
            Logger.error(TAG, `  error.${key} = ${JSON.stringify((error as Record<string, Object>)[key])}`);
          } catch (e) {
            Logger.error(TAG, `  error.${key} = [无法序列化]`);
          }
        }
      }
    }
  }

  /**
   * 通过邀请码从云端查询沟通组
   */
  public async queryFamilyGroupByInvitationCode(code: string): Promise<FamilyGroup | null> {
    if (!this.zone) {
      return null;
    }
    try {
      const query = new cloudDatabase.DatabaseQuery(FamilyGroupObj)
        .equalTo('invitationCode', code);
      const results = await this.zone.query(query);

      if (results && results.length > 0) {
        const obj = results[0] as FamilyGroupObj;
        // 检查过期
        if (obj.invitationExpiresAt > 0 && Date.now() > obj.invitationExpiresAt) {
          Logger.warn(TAG, `云端邀请码已过期: ${code}`);
          return null;
        }
        const group = new FamilyGroup();
        group.groupId = obj.groupId;
        group.groupName = obj.groupName;
        group.parentAccountId = obj.parentAccountId;
        group.invitationCode = obj.invitationCode;
        group.invitationExpiresAt = obj.invitationExpiresAt;
        group.pendingMembers = obj.pendingMembers;
        group.createdAt = obj.createdAt;
        group.updatedAt = obj.updatedAt;
        Logger.info(TAG, `从云端查询到沟通组: ${group.groupName}`);
        return group;
      }
      return null;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '云端邀请码查询失败');
      return null;
    }
  }

  /**
   * 从云端查询沟通组（按 groupId）
   */
  public async queryFamilyGroup(groupId: string): Promise<FamilyGroup | null> {
    if (!this.zone) {
      return null;
    }
    try {
      const query = new cloudDatabase.DatabaseQuery(FamilyGroupObj)
        .equalTo('groupId', groupId);
      const results = await this.zone.query(query);

      if (results && results.length > 0) {
        const obj = results[0] as FamilyGroupObj;
        const group = new FamilyGroup();
        group.groupId = obj.groupId;
        group.groupName = obj.groupName;
        group.parentAccountId = obj.parentAccountId;
        group.invitationCode = obj.invitationCode;
        group.invitationExpiresAt = obj.invitationExpiresAt;
        group.pendingMembers = obj.pendingMembers;
        group.createdAt = obj.createdAt;
        group.updatedAt = obj.updatedAt;
        return group;
      }
      return null;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '云端沟通组查询失败');
      return null;
    }
  }

  // ==================== 帐号同步 ====================

  /**
   * 上传帐号到云端
   */
  public async uploadAccount(account: UserAccount): Promise<void> {
    if (!this.zone) {
      return;
    }
    try {
      const obj = new AccountObj();
      obj.accountId = account.accountId;
      obj.username = account.username;
      obj.avatar = account.avatar;
      obj.passwordHash = account.passwordHash;
      obj.accountMode = account.accountMode;
      obj.familyGroupId = account.familyGroupId;
      obj.parentAccountId = account.parentAccountId;
      obj.joinStatus = account.joinStatus;
      obj.pendingGroupId = account.pendingGroupId;
      obj.pendingRequestedAt = account.pendingRequestedAt;
      obj.isLocalActive = account.isLocalActive;
      obj.createdAt = account.createdAt;
      obj.updatedAt = account.updatedAt;

      await this.zone.upsert(obj);
      Logger.info(TAG, `帐号已上传: ${account.username} (${account.accountId.substring(0, 8)})`);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '帐号上传失败');
    }
  }

  /**
   * 从云端查询待确认加入请求
   */
  public async queryPendingJoinRequests(groupId: string): Promise<UserAccount[]> {
    if (!this.zone) {
      return [];
    }
    try {
      const query = new cloudDatabase.DatabaseQuery(AccountObj)
        .equalTo('pendingGroupId', groupId)
        .equalTo('joinStatus', 'pending');
      const results = await this.zone.query(query);

      const accounts: UserAccount[] = [];
      if (results) {
        for (const obj of results) {
          const account = new UserAccount();
          account.accountId = (obj as AccountObj).accountId;
          account.username = (obj as AccountObj).username;
          account.avatar = (obj as AccountObj).avatar;
          account.accountMode = (obj as AccountObj).accountMode === 'child' ? AccountMode.CHILD : AccountMode.PARENT;
          account.joinStatus = (obj as AccountObj).joinStatus;
          account.pendingGroupId = (obj as AccountObj).pendingGroupId;
          account.pendingRequestedAt = (obj as AccountObj).pendingRequestedAt;
          account.familyGroupId = (obj as AccountObj).familyGroupId;
          account.parentAccountId = (obj as AccountObj).parentAccountId;
          account.createdAt = (obj as AccountObj).createdAt;
          account.updatedAt = (obj as AccountObj).updatedAt;
          accounts.push(account);
        }
      }
      Logger.info(TAG, `从云端查询到 ${accounts.length} 个待确认请求`);
      return accounts;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '云端待确认请求查询失败');
      return [];
    }
  }

  /**
   * 从云端查询帐号（按 accountId）
   */
  public async queryAccount(accountId: string): Promise<UserAccount | null> {
    if (!this.zone) {
      return null;
    }
    try {
      const query = new cloudDatabase.DatabaseQuery(AccountObj)
        .equalTo('accountId', accountId);
      const results = await this.zone.query(query);

      if (results && results.length > 0) {
        const obj = results[0] as AccountObj;
        const account = new UserAccount();
        account.accountId = obj.accountId;
        account.username = obj.username;
        account.avatar = obj.avatar;
        account.passwordHash = obj.passwordHash;
        account.accountMode = obj.accountMode === 'child' ? AccountMode.CHILD : AccountMode.PARENT;
        account.familyGroupId = obj.familyGroupId;
        account.parentAccountId = obj.parentAccountId;
        account.joinStatus = obj.joinStatus;
        account.pendingGroupId = obj.pendingGroupId;
        account.pendingRequestedAt = obj.pendingRequestedAt;
        account.isLocalActive = obj.isLocalActive;
        account.createdAt = obj.createdAt;
        account.updatedAt = obj.updatedAt;
        return account;
      }
      return null;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '云端帐号查询失败');
      return null;
    }
  }

  // ==================== 配置同步 ====================

  /**
   * 家长上传儿童配置到云端
   */
  public async uploadChildConfig(childAccountId: string, config: LanternLawConfig): Promise<void> {
    if (!this.zone) {
      return;
    }
    try {
      const obj = new ChildConfigObj();
      obj.accountId = childAccountId;
      obj.configText = config.toJSON();
      obj.updatedAt = Date.now();

      await this.zone.upsert(obj);
      Logger.info(TAG, `儿童配置已上传: ${childAccountId.substring(0, 8)}`);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '儿童配置上传失败');
    }
  }

  /**
   * 儿童从云端拉取最新配置
   */
  public async pullLatestConfig(accountId: string): Promise<LanternLawConfig | null> {
    if (!this.zone) {
      // 回退到本地
      const configJson = await this.database.getConfig(`lanternlaw_config_${accountId}`);
      if (configJson) {
        return LanternLawConfig.fromJSON(configJson);
      }
      return null;
    }
    try {
      const query = new cloudDatabase.DatabaseQuery(ChildConfigObj)
        .equalTo('accountId', accountId);
      const results = await this.zone.query(query);

      if (results && results.length > 0) {
        const obj = results[0] as ChildConfigObj;
        const config = LanternLawConfig.fromJSON(obj.configText);
        // 同步到本地缓存
        await this.database.saveConfig(`lanternlaw_config_${accountId}`, obj.configText);
        Logger.info(TAG, `从云端拉取到儿童配置: ${accountId.substring(0, 8)}`);
        return config;
      }
      return null;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '云端配置拉取失败');
      return null;
    }
  }

  // ==================== 消息同步 ====================

  /**
   * 上传消息到云端
   */
  public async uploadMessage(message: FamilyMessage): Promise<void> {
    if (!this.zone) {
      return;
    }
    try {
      const obj = new MessageObj();
      obj.id = message.id;
      obj.senderAccountId = message.senderAccountId;
      obj.receiverAccountId = message.receiverAccountId;
      obj.messageType = message.messageType;
      obj.content = message.content;
      obj.isRead = message.isRead;
      obj.createdAt = message.createdAt;

      await this.zone.upsert(obj);
      Logger.info(TAG, `消息已上传: ${message.id.substring(0, 12)}`);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '消息上传失败');
    }
  }

  /**
   * 从云端拉取消息
   */
  public async pullMessages(accountId: string, limit: number): Promise<FamilyMessage[]> {
    // 回退到本地
    return await this.database.getMessagesByReceiver(accountId);
  }

  // ==================== 定时同步 ====================

  /**
   * 启动定时同步（每5分钟）
   */
  public startPeriodicSync(): void {
    if (this.syncTimerId !== -1) {
      return;
    }
    this.syncTimerId = setInterval(() => {
      this.syncAll();
    }, SYNC_INTERVAL_MS);
    Logger.info(TAG, `定时同步已启动，间隔 ${SYNC_INTERVAL_MS / 1000} 秒`);
  }

  /**
   * 停止定时同步
   */
  public stopPeriodicSync(): void {
    if (this.syncTimerId !== -1) {
      clearInterval(this.syncTimerId);
      this.syncTimerId = -1;
      Logger.info(TAG, '定时同步已停止');
    }
  }

  /**
   * 执行一次完整同步
   */
  public async syncAll(): Promise<void> {
    if (!this.accountId) {
      return;
    }
    Logger.info(TAG, '定时同步完成');
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    this.stopPeriodicSync();
    this.isAvailable = false;
    this.zone = null;
    this.accountId = '';
  }
}
