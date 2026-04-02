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
    const obj = JSON.parse(json);
    const account = new UserAccount();
    account.username = obj.username || '';
    account.avatar = obj.avatar || '😊';
    account.passwordHash = obj.passwordHash || '';
    account.createdAt = obj.createdAt || 0;
    account.updatedAt = obj.updatedAt || 0;
    return account;
  }

  clone(): UserAccount {
    return UserAccount.fromJSON(this.toJSON());
  }
}
