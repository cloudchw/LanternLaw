// entry/src/main/ets/services/FamilyGroupService.ets

/**
 * 沟通组服务
 * 管理沟通组的创建、邀请码、成员管理
 */
import { FamilyGroup } from '../models/FamilyGroup';
import { UserAccount } from '../models/UserAccount';
import { AccountMode } from '../models/AccountMode';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { ConfigSyncService } from './ConfigSyncService';
import { Logger } from '../utils/Logger';

const TAG = 'FamilyGroupService';

export class InvitationCodeValidation {
  valid: boolean = false;
  reason: string = '';
  group: FamilyGroup | null = null;

  constructor(valid: boolean, reason: string, group?: FamilyGroup) {
    this.valid = valid;
    this.reason = reason;
    this.group = group ?? null;
  }
}

export class JoinRequestResult {
  success: boolean = false;
  reason: string = '';
  group: FamilyGroup | null = null;

  constructor(success: boolean, reason: string, group?: FamilyGroup) {
    this.success = success;
    this.reason = reason;
    this.group = group ?? null;
  }
}

export class FamilyGroupService {
  private static instance: FamilyGroupService;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  private constructor() {}

  public static getInstance(): FamilyGroupService {
    if (!FamilyGroupService.instance) {
      FamilyGroupService.instance = new FamilyGroupService();
    }
    return FamilyGroupService.instance;
  }

  /**
   * 创建沟通组
   */
  public async createGroup(groupName: string, parentAccountId: string): Promise<FamilyGroup> {
    const group = new FamilyGroup();
    group.groupId = this.generateUUID();
    group.groupName = groupName;
    group.parentAccountId = parentAccountId;
    group.createdAt = Date.now();
    group.updatedAt = Date.now();

    // 生成初始邀请码
    group.invitationCode = this.generateInvitationCode();
    group.invitationExpiresAt = Date.now() + 24 * 60 * 60 * 1000; // 24小时过期

    await this.database.saveFamilyGroup(group);

    // 更新家长的 familyGroupId
    await this.database.updateAccountField(parentAccountId, 'family_group_id', group.groupId);

    // 同步到云端
    const syncService = ConfigSyncService.getInstance();
    if (syncService.getIsAvailable()) {
      await syncService.uploadFamilyGroup(group);
    }

    Logger.info(TAG, `沟通组创建成功: ${groupName} (${group.groupId})`);
    return group;
  }

  /**
   * 获取我的沟通组
   */
  public async getMyGroup(accountId: string): Promise<FamilyGroup | null> {
    const account = await this.database.getAccountByAccountId(accountId);
    if (!account || !account.familyGroupId) {
      return null;
    }
    return await this.database.getFamilyGroup(account.familyGroupId);
  }

  /**
   * 刷新邀请码
   */
  public async refreshInvitationCode(groupId: string): Promise<string> {
    const group = await this.database.getFamilyGroup(groupId);
    if (!group) {
      throw new Error('沟通组不存在');
    }

    group.invitationCode = this.generateInvitationCode();
    group.invitationExpiresAt = Date.now() + 24 * 60 * 60 * 1000;
    group.updatedAt = Date.now();

    await this.database.saveFamilyGroup(group);
    Logger.info(TAG, `邀请码已刷新: ${group.invitationCode}`);
    return group.invitationCode;
  }

  /**
   * 通过邀请码加入沟通组
   */
  public async joinByInvitationCode(childAccountId: string, code: string): Promise<FamilyGroup | null> {
    // 验证邀请码
    const group = await this.database.getFamilyGroupByInvitationCode(code);
    if (!group) {
      Logger.warn(TAG, `邀请码无效或已过期: ${code}`);
      return null;
    }

    // 更新儿童的 familyGroupId 和 parentAccountId
    await this.database.updateAccountField(childAccountId, 'family_group_id', group.groupId);
    await this.database.updateAccountField(childAccountId, 'parent_account_id', group.parentAccountId);

    Logger.info(TAG, `儿童 ${childAccountId} 加入沟通组 ${group.groupName}`);
    return group;
  }

  /**
   * 通过邀请码请求加入沟通组（待确认流程）
   * 设置 child joinStatus='pending'，添加到 group.pendingMembers
   */
  public async requestJoinByInvitationCode(childAccountId: string, code: string): Promise<JoinRequestResult> {
    // 验证邀请码（先查本地，再查云端）
    let group = await this.database.getFamilyGroupByInvitationCode(code);
    if (!group) {
      const syncService = ConfigSyncService.getInstance();
      if (syncService.getIsAvailable()) {
        group = await syncService.queryFamilyGroupByInvitationCode(code);
        if (group) {
          // 同步到本地
          await this.database.saveFamilyGroup(group);
          Logger.info(TAG, `从云端同步沟通组到本地: ${group.groupName}`);
        }
      }
    }
    if (!group) {
      return new JoinRequestResult(false, '邀请码无效或已过期');
    }

    // 设置儿童帐号为 pending 状态
    await this.database.updateAccountField(childAccountId, 'join_status', 'pending');
    await this.database.updateAccountField(childAccountId, 'pending_group_id', group.groupId);
    await this.database.updateAccountField(childAccountId, 'pending_requested_at', Date.now());

    // 添加到沟通组的 pendingMembers
    const pendingMembers = this.parsePendingMembers(group.pendingMembers);
    if (!pendingMembers.includes(childAccountId)) {
      pendingMembers.push(childAccountId);
    }
    group.pendingMembers = JSON.stringify(pendingMembers);
    await this.database.saveFamilyGroup(group);

    // 同步到云端
    const syncService = ConfigSyncService.getInstance();
    if (syncService.getIsAvailable()) {
      await syncService.uploadFamilyGroup(group);
      const childAccount = await this.database.getAccountByAccountId(childAccountId);
      if (childAccount) {
        await syncService.uploadAccount(childAccount);
      }
    }

    Logger.info(TAG, `儿童 ${childAccountId} 请求加入沟通组 ${group.groupName}，等待确认`);
    return new JoinRequestResult(true, '', group);
  }

  /**
   * 家长同意儿童加入请求
   */
  public async approveJoinRequest(childAccountId: string): Promise<void> {
    const syncService = ConfigSyncService.getInstance();

    // 获取儿童帐号信息（先本地，后云端）
    let childAccount = await this.database.getAccountByAccountId(childAccountId);
    if (!childAccount || !childAccount.pendingGroupId) {
      if (syncService.getIsAvailable()) {
        childAccount = await syncService.queryAccount(childAccountId);
        if (childAccount) {
          // 同步到本地
          await this.database.saveAccount(childAccount);
        }
      }
    }
    if (!childAccount || !childAccount.pendingGroupId) {
      throw new Error('找不到待确认的加入请求');
    }

    const groupId = childAccount.pendingGroupId;

    // 获取沟通组（先本地，后云端）
    let group = await this.database.getFamilyGroup(groupId);
    if (!group && syncService.getIsAvailable()) {
      group = await syncService.queryFamilyGroup(groupId);
      if (group) {
        await this.database.saveFamilyGroup(group);
      }
    }

    const parentAccountId = group?.parentAccountId ?? '';

    // 更新儿童帐号：设置 familyGroupId/parentAccountId，标记 approved
    childAccount.familyGroupId = groupId;
    childAccount.parentAccountId = parentAccountId;
    childAccount.joinStatus = 'approved';
    childAccount.pendingGroupId = '';
    childAccount.pendingRequestedAt = 0;
    await this.database.saveAccount(childAccount);

    // 从沟通组的 pendingMembers 移除
    if (group) {
      let pendingMembers = this.parsePendingMembers(group.pendingMembers);
      pendingMembers = pendingMembers.filter(id => id !== childAccountId);
      group.pendingMembers = JSON.stringify(pendingMembers);
      group.updatedAt = Date.now();
      await this.database.saveFamilyGroup(group);
    }

    // 同步到云端
    if (syncService.getIsAvailable()) {
      if (group) {
        await syncService.uploadFamilyGroup(group);
      }
      await syncService.uploadAccount(childAccount);
    }

    Logger.info(TAG, `家长已同意儿童 ${childAccountId} 加入沟通组 ${groupId}`);
  }

  /**
   * 家长拒绝儿童加入请求
   */
  public async rejectJoinRequest(childAccountId: string): Promise<void> {
    const syncService = ConfigSyncService.getInstance();

    // 获取儿童帐号信息（先本地，后云端）
    let childAccount = await this.database.getAccountByAccountId(childAccountId);
    if (!childAccount || !childAccount.pendingGroupId) {
      if (syncService.getIsAvailable()) {
        childAccount = await syncService.queryAccount(childAccountId);
        if (childAccount) {
          await this.database.saveAccount(childAccount);
        }
      }
    }
    if (!childAccount || !childAccount.pendingGroupId) {
      throw new Error('找不到待确认的加入请求');
    }

    const groupId = childAccount.pendingGroupId;

    // 更新儿童帐号：标记 rejected
    childAccount.joinStatus = 'rejected';
    childAccount.pendingGroupId = '';
    childAccount.pendingRequestedAt = 0;
    await this.database.saveAccount(childAccount);

    // 从沟通组的 pendingMembers 移除
    let group = await this.database.getFamilyGroup(groupId);
    if (!group && syncService.getIsAvailable()) {
      group = await syncService.queryFamilyGroup(groupId);
      if (group) {
        await this.database.saveFamilyGroup(group);
      }
    }
    if (group) {
      let pendingMembers = this.parsePendingMembers(group.pendingMembers);
      pendingMembers = pendingMembers.filter(id => id !== childAccountId);
      group.pendingMembers = JSON.stringify(pendingMembers);
      group.updatedAt = Date.now();
      await this.database.saveFamilyGroup(group);
    }

    // 同步到云端
    if (syncService.getIsAvailable()) {
      if (group) {
        await syncService.uploadFamilyGroup(group);
      }
      await syncService.uploadAccount(childAccount);
    }

    Logger.info(TAG, `家长已拒绝儿童 ${childAccountId} 加入沟通组 ${groupId}`);
  }

  /**
   * 获取沟通组的待确认加入请求
   */
  public async getPendingJoinRequests(groupId: string): Promise<UserAccount[]> {
    // 先从本地获取
    const group = await this.database.getFamilyGroup(groupId);
    if (!group || !group.pendingMembers) {
      // 本地无沟通组，尝试从云端拉取
      const syncService = ConfigSyncService.getInstance();
      if (syncService.getIsAvailable()) {
        const cloudAccounts = await syncService.queryPendingJoinRequests(groupId);
        if (cloudAccounts.length > 0) {
          return cloudAccounts;
        }
      }
      return [];
    }

    const pendingIds = this.parsePendingMembers(group.pendingMembers);
    if (pendingIds.length === 0) {
      return [];
    }

    const accounts: UserAccount[] = [];
    for (const id of pendingIds) {
      const account = await this.database.getAccountByAccountId(id);
      if (account && account.joinStatus === 'pending') {
        accounts.push(account);
      }
    }

    // 如果本地没有，也从云端查
    if (accounts.length === 0) {
      const syncService = ConfigSyncService.getInstance();
      if (syncService.getIsAvailable()) {
        const cloudAccounts = await syncService.queryPendingJoinRequests(groupId);
        if (cloudAccounts.length > 0) {
          // 同步到本地
          for (const ca of cloudAccounts) {
            await this.database.saveAccount(ca);
          }
          // 同步沟通组
          const cloudGroup = await syncService.queryFamilyGroup(groupId);
          if (cloudGroup) {
            await this.database.saveFamilyGroup(cloudGroup);
          }
          return cloudAccounts;
        }
      }
    }

    return accounts;
  }

  /**
   * 解析 pendingMembers JSON
   * @private
   */
  private parsePendingMembers(json: string): string[] {
    if (!json) {
      return [];
    }
    try {
      const arr = JSON.parse(json) as string[];
      return Array.isArray(arr) ? arr : [];
    } catch (e) {
      return [];
    }
  }

  /**
   * 获取沟通组成员列表
   */
  public async getMembers(groupId: string): Promise<UserAccount[]> {
    return await this.database.getAccountsByFamilyGroup(groupId);
  }

  /**
   * 移除儿童成员
   */
  public async removeChild(childAccountId: string): Promise<void> {
    await this.database.updateAccountField(childAccountId, 'family_group_id', '');
    await this.database.updateAccountField(childAccountId, 'parent_account_id', '');
    Logger.info(TAG, `已移除儿童: ${childAccountId}`);
  }

  /**
   * 检查邀请码是否有效
   */
  public async validateInvitationCode(code: string): Promise<InvitationCodeValidation> {
    if (!code || code.length !== 6) {
      return new InvitationCodeValidation(false, '邀请码格式不正确');
    }
    const group = await this.database.getFamilyGroupByInvitationCode(code);
    if (!group) {
      return new InvitationCodeValidation(false, '邀请码无效或已过期');
    }
    return new InvitationCodeValidation(true, '', group);
  }

  /**
   * 生成6位邀请码（大写字母+数字）
   * @private
   */
  private generateInvitationCode(): string {
    const chars: string[] = [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M',
      'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
      '2', '3', '4', '5', '6', '7', '8', '9'
    ];
    let code = '';
    for (let i = 0; i < 6; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
    return code;
  }

  /**
   * 生成 UUID
   * @private
   */
  private generateUUID(): string {
    const charArr: string[] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
    const sections: number[] = [8, 4, 4, 4, 12];
    let uuid = '';
    for (const len of sections) {
      for (let i = 0; i < len; i++) {
        uuid += charArr[Math.floor(Math.random() * charArr.length)];
      }
      if (len !== 12) {
        uuid += '-';
      }
    }
    return uuid;
  }
}
