// entry/src/main/ets/models/UserAccount.ets

/**
 * 用户账号模型
 * User Account Model
 */
import { AccountMode } from './AccountMode';

export class UserAccount {
  username: string = '';
  avatar: string = '😊';
  passwordHash: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
  // 多帐号体系新增字段
  accountId: string = '';
  accountMode: AccountMode = AccountMode.PARENT;
  familyGroupId: string = '';
  parentAccountId: string = '';
  isLocalActive: boolean = false;
  // 儿童加入沟通组流程字段
  joinStatus: string = '';        // '' | 'pending' | 'approved' | 'rejected'
  pendingGroupId: string = '';    // 待加入的沟通组ID
  pendingRequestedAt: number = 0; // 提交请求时间戳

  toJSON(): string {
    return JSON.stringify({
      username: this.username,
      avatar: this.avatar,
      passwordHash: this.passwordHash,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      accountId: this.accountId,
      accountMode: this.accountMode,
      familyGroupId: this.familyGroupId,
      parentAccountId: this.parentAccountId,
      joinStatus: this.joinStatus,
      pendingGroupId: this.pendingGroupId,
      pendingRequestedAt: this.pendingRequestedAt
    });
  }

  static fromJSON(json: string): UserAccount {
    const obj: Record<string, Object> = JSON.parse(json);
    const account = new UserAccount();
    account.username = (obj['username'] as string) ?? '';
    account.avatar = (obj['avatar'] as string) ?? '😊';
    account.passwordHash = (obj['passwordHash'] as string) ?? '';
    account.createdAt = (obj['createdAt'] as number) ?? 0;
    account.updatedAt = (obj['updatedAt'] as number) ?? 0;
    account.accountId = (obj['accountId'] as string) ?? '';
    account.accountMode = (obj['accountMode'] as AccountMode) ?? AccountMode.PARENT;
    account.familyGroupId = (obj['familyGroupId'] as string) ?? '';
    account.parentAccountId = (obj['parentAccountId'] as string) ?? '';
    account.joinStatus = (obj['joinStatus'] as string) ?? '';
    account.pendingGroupId = (obj['pendingGroupId'] as string) ?? '';
    account.pendingRequestedAt = (obj['pendingRequestedAt'] as number) ?? 0;
    return account;
  }

  clone(): UserAccount {
    return UserAccount.fromJSON(this.toJSON());
  }
}
