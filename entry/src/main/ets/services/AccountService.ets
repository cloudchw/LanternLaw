// entry/src/main/ets/services/AccountService.ets

/**
 * 帐号服务
 * 管理帐号生命周期：创建、加载、退出、模式选择
 */
import { UserAccount } from '../models/UserAccount';
import { AccountMode } from '../models/AccountMode';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { hashPassword } from '../utils/PasswordHelper';
import { Logger } from '../utils/Logger';
import relationalStore from '@ohos.data.relationalStore';

const TAG = 'AccountService';

export class AccountService {
  private static instance: AccountService;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();
  private activeAccount: UserAccount | null = null;

  private constructor() {}

  public static getInstance(): AccountService {
    if (!AccountService.instance) {
      AccountService.instance = new AccountService();
    }
    return AccountService.instance;
  }

  /**
   * 初始化：加载本地活跃帐号
   * 需要先初始化数据库
   */
  public async initialize(context: Context): Promise<void> {
    try {
      // 确保数据库已初始化
      if (!this.database.isInitialized()) {
        await this.database.initialize(context);
      }

      const account = await this.database.getActiveAccount();
      if (account) {
        this.activeAccount = account;
        Logger.info(TAG, `活跃帐号已加载: ${account.username} (${account.accountMode})`);
      } else {
        // 向后兼容：检查旧版 user_account 数据
        const accountJson = await this.database.getUserAccount();
        if (accountJson) {
          const legacyAccount = UserAccount.fromJSON(accountJson);
          if (legacyAccount.username) {
            // 旧版帐号自动迁移到 accounts 表
            if (!legacyAccount.accountId) {
              legacyAccount.accountId = this.generateUUID();
            }
            legacyAccount.isLocalActive = true;
            await this.database.saveAccount(legacyAccount);
            this.activeAccount = legacyAccount;
            Logger.info(TAG, `旧版帐号已迁移: ${legacyAccount.username}`);
          }
        } else {
          Logger.info(TAG, '无活跃帐号');
        }
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '初始化帐号服务失败');
    }
  }

  /**
   * 获取当前活跃帐号
   */
  public getActiveAccount(): UserAccount | null {
    return this.activeAccount;
  }

  /**
   * 获取当前活跃帐号ID
   */
  public getActiveAccountId(): string {
    return this.activeAccount?.accountId ?? '';
  }

  /**
   * 获取当前帐号模式
   */
  public getActiveAccountMode(): AccountMode {
    return this.activeAccount?.accountMode ?? AccountMode.PARENT;
  }

  /**
   * 是否已有活跃帐号
   */
  public hasActiveAccount(): boolean {
    return this.activeAccount !== null;
  }

  /**
   * 根据 accountId 获取帐号
   */
  public async getAccountById(accountId: string): Promise<UserAccount | null> {
    return await this.database.getAccountByAccountId(accountId);
  }

  /**
   * 创建帐号
   */
  public async createAccount(
    username: string,
    avatar: string,
    password: string,
    mode: AccountMode
  ): Promise<UserAccount> {
    const account = new UserAccount();
    account.accountId = this.generateUUID();
    account.username = username;
    account.avatar = avatar;
    account.passwordHash = await hashPassword(password);
    account.accountMode = mode;
    account.createdAt = Date.now();
    account.updatedAt = Date.now();

    // 保存到 accounts 表
    await this.database.saveAccount(account);

    // 同时保存到旧版 user_account key（向后兼容）
    await this.database.saveUserAccount(account.toJSON());

    // 设为活跃帐号
    await this.setActiveAccount(account.accountId);

    Logger.info(TAG, `帐号创建成功: ${username} (${mode})`);
    return account;
  }

  /**
   * 设置活跃帐号
   */
  public async setActiveAccount(accountId: string): Promise<void> {
    // 先取消所有帐号的活跃状态
    const account = await this.database.getAccountByAccountId(accountId);
    if (!account) {
      Logger.warn(TAG, `帐号不存在: ${accountId}`);
      return;
    }

    // 取消当前活跃帐号
    if (this.activeAccount) {
      await this.database.updateAccountField(this.activeAccount.accountId, 'is_local_active', 0);
    }

    // 设置新的活跃帐号
    account.isLocalActive = true;
    await this.database.saveAccount(account);
    this.activeAccount = account;

    Logger.info(TAG, `活跃帐号已切换: ${account.username}`);
  }

  /**
   * 退出登录
   */
  public async logout(): Promise<void> {
    if (this.activeAccount) {
      await this.database.updateAccountField(this.activeAccount.accountId, 'is_local_active', 0);
      Logger.info(TAG, `帐号已退出: ${this.activeAccount.username}`);
      this.activeAccount = null;
    }
  }

  /**
   * 更新活跃帐号信息
   */
  public async updateActiveAccount(updates: Partial<UserAccount>): Promise<void> {
    if (!this.activeAccount) {
      return;
    }
    const updated = this.activeAccount.clone();
    if (updates.username !== undefined) {
      updated.username = updates.username;
    }
    if (updates.avatar !== undefined) {
      updated.avatar = updates.avatar;
    }
    if (updates.passwordHash !== undefined) {
      updated.passwordHash = updates.passwordHash;
    }
    if (updates.accountMode !== undefined) {
      updated.accountMode = updates.accountMode;
    }
    if (updates.familyGroupId !== undefined) {
      updated.familyGroupId = updates.familyGroupId;
    }
    if (updates.parentAccountId !== undefined) {
      updated.parentAccountId = updates.parentAccountId;
    }
    if (updates.joinStatus !== undefined) {
      updated.joinStatus = updates.joinStatus;
    }
    if (updates.pendingGroupId !== undefined) {
      updated.pendingGroupId = updates.pendingGroupId;
    }
    if (updates.pendingRequestedAt !== undefined) {
      updated.pendingRequestedAt = updates.pendingRequestedAt;
    }
    updated.updatedAt = Date.now();
    await this.database.saveAccount(updated);
    // 同时更新旧版 user_account（向后兼容）
    await this.database.saveUserAccount(updated.toJSON());
    this.activeAccount = updated;
  }

  /**
   * 直接保存当前活跃帐号（用于外部修改字段后保存）
   */
  public async saveActiveAccount(): Promise<void> {
    if (!this.activeAccount) {
      return;
    }
    this.activeAccount.updatedAt = Date.now();
    await this.database.saveAccount(this.activeAccount);
    await this.database.saveUserAccount(this.activeAccount.toJSON());
  }

  /**
   * 刷新活跃帐号数据（从数据库重新加载）
   */
  public async reloadActiveAccount(): Promise<void> {
    if (!this.activeAccount) {
      return;
    }
    const fresh = await this.database.getAccountByAccountId(this.activeAccount.accountId);
    if (fresh) {
      this.activeAccount = fresh;
    }
  }

  /**
   * 儿童帐号是否正在等待家长确认加入
   */
  public isChildPendingApproval(): boolean {
    return this.activeAccount !== null &&
      this.activeAccount.accountMode === AccountMode.CHILD &&
      this.activeAccount.joinStatus === 'pending';
  }

  /**
   * 儿童帐号是否已加入沟通组
   */
  public isChildInGroup(): boolean {
    return this.activeAccount !== null &&
      this.activeAccount.accountMode === AccountMode.CHILD &&
      !!this.activeAccount.familyGroupId;
  }

  /**
   * 儿童帐号是否未加入沟通组且不在等待中
   */
  public isChildWithoutGroup(): boolean {
    return this.activeAccount !== null &&
      this.activeAccount.accountMode === AccountMode.CHILD &&
      !this.activeAccount.familyGroupId &&
      this.activeAccount.joinStatus !== 'pending';
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
