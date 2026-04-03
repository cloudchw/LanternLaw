// entry/src/main/ets/models/UserAccount.ets

/**
 * 用户账号模型
 * User Account Model
 */

export class UserAccount {
  username: string = '';
  avatar: string = '😊';
  passwordHash: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;

  toJSON(): string {
    return JSON.stringify({
      username: this.username,
      avatar: this.avatar,
      passwordHash: this.passwordHash,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
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
    return account;
  }

  clone(): UserAccount {
    return UserAccount.fromJSON(this.toJSON());
  }
}
