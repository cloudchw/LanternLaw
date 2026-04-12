// entry/src/main/ets/models/cloud/CloudObjectTypes.ets

/**
 * Cloud DB 对象类型定义
 * 与 AGC 控制台中的对象类型一一对应
 * 所有类继承 cloudDatabase.DatabaseObject，实现 naturalbase_ClassName()
 */
import { cloudDatabase } from '@kit.CloudFoundationKit';

/**
 * 沟通组对象
 * AGC 对象类型名: FamilyGroupObj
 */
export class FamilyGroupObj extends cloudDatabase.DatabaseObject {
  groupId: string = '';
  groupName: string = '';
  parentAccountId: string = '';
  invitationCode: string = '';
  invitationExpiresAt: number = 0;
  pendingMembers: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;

  naturalbase_ClassName(): string {
    return 'FamilyGroupObj';
  }
}

/**
 * 帐号对象
 * AGC 对象类型名: AccountObj
 */
export class AccountObj extends cloudDatabase.DatabaseObject {
  accountId: string = '';
  username: string = '';
  avatar: string = '';
  passwordHash: string = '';
  accountMode: string = '';
  familyGroupId: string = '';
  parentAccountId: string = '';
  joinStatus: string = '';
  pendingGroupId: string = '';
  pendingRequestedAt: number = 0;
  isLocalActive: boolean = false;
  createdAt: number = 0;
  updatedAt: number = 0;

  naturalbase_ClassName(): string {
    return 'AccountObj';
  }
}

/**
 * 儿童配置对象（家长写入，儿童读取）
 * AGC 对象类型名: ChildConfigObj
 */
export class ChildConfigObj extends cloudDatabase.DatabaseObject {
  accountId: string = '';
  configText: string = '';
  updatedAt: number = 0;

  naturalbase_ClassName(): string {
    return 'ChildConfigObj';
  }
}

/**
 * 白名单修改请求对象
 * AGC 对象类型名: WhitelistRequestObj
 * 儿童设备发起白名单修改，家长设备审批
 */
export class WhitelistRequestObj extends cloudDatabase.DatabaseObject {
  requestId: string = '';
  childAccountId: string = '';
  appTokensText: string = '';
  appCount: number = 0;
  status: string = '';  // 'pending' | 'approved' | 'rejected'
  createdAt: number = 0;
  respondedAt: number = 0;

  naturalbase_ClassName(): string {
    return 'WhitelistRequestObj';
  }
}

/**
 * 消息对象
 * AGC 对象类型名: MessageObj
 */
export class MessageObj extends cloudDatabase.DatabaseObject {
  id: string = '';
  senderAccountId: string = '';
  receiverAccountId: string = '';
  messageType: string = '';
  content: string = '';
  isRead: boolean = false;
  createdAt: number = 0;

  naturalbase_ClassName(): string {
    return 'MessageObj';
  }
}
