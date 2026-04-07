# 掌灯人 - 多帐号家庭体系 技术实现方案

> 版本: v1.0 | 日期: 2026-04-07 | 基于: `2026-04-07-family-account-system-design.md`

---

## 一、技术选型

| 能力 | 技术方案 | Kit/模块 | 说明 |
|------|---------|---------|------|
| 跨设备数据同步 | Cloud DB | `@kit.CloudFoundationKit` (`cloudDatabase`) | 离线优先，云端托管，支持结构化查询 |
| 实时消息推送 | Push Kit | `@kit.PushKit` (`pushService`) | 配合 Cloud DB 触发器，配置变更和消息即时送达 |
| 本地数据存储 | RDB（扩展） | `@kit.ArkData` (`relationalStore`) | 新增 accounts/family_groups/messages 表 |
| 常驻通知 | Notification Kit | `@kit.NotificationKit` (`notificationManager`) | 灯律时段内儿童端常驻通知展示家长消息 |
| 邀请码生成 | UUID + 随机截取 | `@kit.ArkTS` (`util`) | 6位字母数字，24小时过期 |
| 密码哈希 | SHA-256 | `@kit.CryptoArchitectureKit` (`cryptoFramework`) | 复用现有 PasswordHelper |
| 系统锁屏验证 | User Authentication | `@kit.UserAuthenticationKit` (`userAuth`) | 找回密码，复用现有实现 |

**AGConnect 前置配置**：
- 在 AppGallery Connect 控制台创建项目，启用 Cloud DB 和 Push Kit
- 下载 `agconnect-services.json` 放入 `entry/` 目录
- 在 AGC 控制台创建 Cloud DB 存储区 `lanternlaw_family`，定义对象类型

---

## 二、数据模型设计

### 2.1 扩展 UserAccount

**文件**: `entry/src/main/ets/models/UserAccount.ets`

```typescript
export enum AccountMode {
  PARENT = 'parent',
  CHILD = 'child'
}

export class UserAccount {
  // 已有字段
  username: string = '';
  avatar: string = '😊';
  passwordHash: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
  // 新增字段
  accountId: string = '';           // UUID，全局唯一标识
  accountMode: AccountMode = AccountMode.PARENT;
  familyGroupId: string = '';       // 所属沟通组ID
  parentAccountId: string = '';     // 儿童专用：绑定的家长accountId
}
```

### 2.2 新增 FamilyGroup

**文件**: `entry/src/main/ets/models/FamilyGroup.ets`（新建）

```typescript
export class FamilyGroup {
  groupId: string = '';             // UUID
  groupName: string = '';           // 如"李家"
  parentAccountId: string = '';     // 创建者（家长）的accountId
  invitationCode: string = '';      // 当前有效邀请码
  invitationExpiresAt: number = 0;  // 邀请码过期时间戳
  createdAt: number = 0;
  updatedAt: number = 0;
}
```

### 2.3 新增 Message

**文件**: `entry/src/main/ets/models/Message.ets`（新建）

```typescript
export enum MessageType {
  ENCOURAGEMENT = 'encouragement',
  REMINDER = 'reminder',
  CUSTOM = 'custom',
  REQUEST = 'request',
  FEEDBACK = 'feedback',
  SYSTEM = 'system'
}

export class FamilyMessage {
  id: string = '';                  // UUID
  senderAccountId: string = '';
  receiverAccountId: string = '';
  messageType: MessageType = MessageType.SYSTEM;
  content: string = '';
  isRead: boolean = false;
  createdAt: number = 0;
}
```

### 2.4 配置隔离策略

当前: `lanternlaw_config` 表 key=`'lanternlaw_config'` 存单个 JSON
改为: key=`'lanternlaw_config_' + accountId`，每个帐号独立配置

家长配置儿童的: key=`'lanternlaw_config_' + childAccountId`，存入本地 RDB（作为缓存），主数据在 Cloud DB。

---

## 三、数据库迁移（v2 → v3）

**文件**: `entry/src/main/ets/database/LanternLawDatabase.ets`

### 3.1 新增 RDB 表

```sql
-- 帐号表（本地活跃帐号 + 已知家庭成员缓存）
CREATE TABLE IF NOT EXISTS accounts (
  account_id TEXT PRIMARY KEY,
  username TEXT NOT NULL,
  avatar TEXT DEFAULT '😊',
  password_hash TEXT NOT NULL,
  account_mode TEXT NOT NULL DEFAULT 'parent',
  family_group_id TEXT,
  parent_account_id TEXT,
  is_local_active INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 沟通组表
CREATE TABLE IF NOT EXISTS family_groups (
  group_id TEXT PRIMARY KEY,
  group_name TEXT NOT NULL,
  parent_account_id TEXT NOT NULL,
  invitation_code TEXT,
  invitation_expires_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- 消息表
CREATE TABLE IF NOT EXISTS messages (
  id TEXT PRIMARY KEY,
  sender_account_id TEXT NOT NULL,
  receiver_account_id TEXT NOT NULL,
  message_type TEXT NOT NULL,
  content TEXT NOT NULL,
  is_read INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_account_id, is_read);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
```

### 3.2 迁移逻辑

在 `checkAndMigrateDatabase()` 中添加 v2→v3 迁移：

1. 执行上述 CREATE TABLE 语句
2. 读取现有 `key='user_account'` 的值
3. 生成 UUID 作为 `accountId`
4. INSERT 到 `accounts` 表，`is_local_active=1`
5. 将 `key='lanternlaw_config'` 的值复制到 `key='lanternlaw_config_' + accountId`
6. 更新 `db_version` 表为 3

### 3.3 新增数据库方法

在 `LanternLawDatabase` 中新增：

```typescript
// 帐号 CRUD
getActiveAccount(): Promise<UserAccount | null>
getAccountByAccountId(accountId: string): Promise<UserAccount | null>
saveAccount(account: UserAccount): Promise<void>
getAccountsByFamilyGroup(groupId: string): Promise<UserAccount[]>
updateAccountField(accountId: string, field: string, value: string): Promise<void>

// 沟通组 CRUD
getFamilyGroup(groupId: string): Promise<FamilyGroup | null>
saveFamilyGroup(group: FamilyGroup): Promise<void>
getFamilyGroupByInvitationCode(code: string): Promise<FamilyGroup | null>

// 消息 CRUD
saveMessage(msg: FamilyMessage): Promise<void>
getMessagesBetween(accountId1: string, accountId2: string): Promise<FamilyMessage[]>
getUnreadMessageCount(accountId: string): Promise<number>
markMessagesAsRead(receiverAccountId: string): Promise<void>

// 按帐号隔离的配置
saveAccountConfig(accountId: string, configJson: string): Promise<void>
getAccountConfig(accountId: string): Promise<string | null>
```

---

## 四、核心服务层设计

### 4.1 AccountService（新建）

**文件**: `entry/src/main/ets/services/AccountService.ets`

职责：帐号生命周期管理、设备绑定、模式选择

```typescript
export class AccountService {
  private static instance: AccountService;
  private database: LanternLawDatabase;
  private activeAccountId: string = '';

  // 初始化：加载本地活跃帐号
  async initialize(context: Context): Promise<void>

  // 获取当前活跃帐号
  getActiveAccount(): Promise<UserAccount | null>
  getActiveAccountId(): string

  // 创建帐号（含模式选择）
  async createAccount(username, avatar, password, mode: AccountMode): Promise<UserAccount>

  // 儿童加入沟通组（通过邀请码）
  async joinFamilyGroup(invitationCode: string): Promise<FamilyGroup | null>

  // 家长确认/拒绝儿童加入
  async approveChildJoin(childAccountId: string): Promise<void>
  async rejectChildJoin(childAccountId: string): Promise<void>

  // 退出登录
  async logout(): Promise<void>
}
```

### 4.2 FamilyGroupService（新建）

**文件**: `entry/src/main/ets/services/FamilyGroupService.ets`

职责：沟通组管理、邀请码生成、成员管理

```typescript
export class FamilyGroupService {
  private static instance: FamilyGroupService;
  private database: LanternLawDatabase;

  // 创建沟通组
  async createGroup(groupName: string, parentAccountId: string): Promise<FamilyGroup>

  // 生成邀请码（6位字母数字，24h过期）
  generateInvitationCode(): string  // 内部调用 util.Random

  // 刷新邀请码（使旧的失效）
  async refreshInvitationCode(groupId: string): Promise<string>

  // 获取沟通组成员列表
  async getMembers(groupId: string): Promise<UserAccount[]>

  // 移除儿童
  async removeChild(childAccountId: string): Promise<void>

  // 获取沟通组信息
  async getMyGroup(): Promise<FamilyGroup | null>
}
```

### 4.3 ConfigSyncService（新建，Phase 2）

**文件**: `entry/src/main/ets/services/ConfigSyncService.ets`

职责：跨设备配置同步

```typescript
export class ConfigSyncService {
  private static instance: ConfigSyncService;

  // 初始化 Cloud DB 连接
  async initialize(): Promise<void>

  // 家长：上传儿童配置到云端
  async uploadChildConfig(childAccountId: string, config: LanternLawConfig): Promise<void>

  // 儿童：从云端拉取最新配置
  async pullLatestConfig(): Promise<LanternLawConfig | null>

  // 儿童：上传每日记录到云端（家长可查看）
  async uploadDailyRecord(record: DailyRecord): Promise<void>

  // 家长：拉取儿童的每日记录
  async pullChildDailyRecords(childAccountId: string): Promise<DailyRecord[]>

  // 启动定时同步（每5分钟）
  startPeriodicSync(): void

  // 停止定时同步
  stopPeriodicSync(): void
}
```

### 4.4 MessageService（新建）

**文件**: `entry/src/main/ets/services/MessageService.ets`

职责：消息发送、接收、本地存储

```typescript
export class MessageService {
  private static instance: MessageService;

  // 发送消息（本地存储 + 云端同步）
  async sendMessage(senderId: string, receiverId: string, type: MessageType, content: string): Promise<void>

  // 获取与某人的消息历史
  async getMessageHistory(otherAccountId: string): Promise<FamilyMessage[]>

  // 获取未读消息数
  async getUnreadCount(): Promise<number>

  // 标记已读
  async markAsRead(messageId: string): Promise<void>

  // 显示家长消息通知（儿童端）
  async showMessageNotification(message: FamilyMessage): Promise<void>
}
```

### 4.5 修改 LanternLawStateManager

**文件**: `entry/src/main/ets/managers/LanternLawStateManager.ets`

关键改动：

```typescript
// 新增字段
private activeAccountId: string = '';

// 修改 initialize：接受 accountId 参数
async initialize(context: Context, accountId: string): Promise<void>

// 修改 loadConfig：按 accountId 加载
private async loadConfig(): Promise<void> {
  const configKey = `lanternlaw_config_${this.activeAccountId}`;
  const configJson = await this.database.getConfig(configKey);
  // ...
}

// 修改 saveConfig：按 accountId 保存
public async saveConfig(config: LanternLawConfig): Promise<void> {
  const configKey = `lanternlaw_config_${this.activeAccountId}`;
  await this.database.saveConfig(configKey, config.toJSON());
  // ...
}

// 新增：为指定帐号保存配置（家长管理儿童时使用）
public async saveConfigForAccount(accountId: string, config: LanternLawConfig): Promise<void>

// 新增：加载指定帐号的配置（只读查看）
public async getConfigForAccount(accountId: string): Promise<LanternLawConfig>
```

### 4.6 修改 ScreenTimeGuardManager

**文件**: `entry/src/main/ets/services/ScreenTimeGuardManager.ets`

关键改动：策略命名增加 accountId 前缀

```typescript
// 修改前
const strategyName = `${STRATEGY_PREFIX}${safeId}`;

// 修改后
const strategyName = `${STRATEGY_PREFIX}${accountId}_${safeId}`;

// 修改 syncStrategies 签名，增加 accountId 参数
async syncStrategies(accountId: string, timeRanges: TimeRange[], whitelistApps: WhitelistApp[]): Promise<void>

// 新增：停止指定帐号的所有策略
async stopAccountStrategies(accountId: string): Promise<void>
```

---

## 五、UI 层设计

### 5.1 新增页面

| 页面 | 文件 | 说明 |
|------|------|------|
| 帐号模式选择 | `pages/AccountModeSelectPage.ets` | 创建帐号后选择家长/儿童模式 |
| 沟通组管理 | `pages/FamilyGroupPage.ets` | 成员列表、邀请码生成、移除儿童 |
| 儿童配置管理 | `pages/ChildConfigPage.ets` | 家长为指定儿童配置灯律和白名单 |
| 消息历史 | `pages/MessageHistoryPage.ets` | 与某成员的消息历史列表 |
| 加入沟通组 | `pages/JoinFamilyGroupPage.ets` | 儿童输入邀请码加入 |

所有新页面注册到 `main_pages.json`。

### 5.2 修改 ProfileTab

**文件**: `entry/src/main/ets/pages/ProfileTab.ets`

新增 @State 变量：
```typescript
@State accountMode: AccountMode = AccountMode.PARENT;
@State familyGroup: FamilyGroup | null = null;
@State familyMembers: UserAccount[] = [];
```

#### 家长模式卡片布局（新增2个卡片）

```
build() 中 Scroll 内的卡片顺序：
1. GlobalSwitchCard        ← 已有（标题改为"我的灯律开关"）
2. FamilyGroupCard         ← 新增：沟通组管理入口
3. ChildManagementCard     ← 新增：孩子列表（有孩子时显示）
4. TimeManagementCard      ← 已有（标题改为"我的灯律时段"）
5. WhitelistCard           ← 已有（标题改为"我的白名单应用"）
6. NotificationCard        ← 已有
7. AccountCard             ← 已有（增加显示模式、沟通组信息）
8. AboutCard               ← 已有
```

#### 儿童模式条件渲染

在卡片 builder 中根据 `this.accountMode` 条件渲染：

| 卡片 | 家长模式 | 儿童模式 |
|------|---------|---------|
| GlobalSwitchCard | 完整（开关+密码验证） | 只读状态显示，无开关 |
| TimeManagementCard | 完整（增删改+密码验证） | 只读列表，无增删改按钮 |
| WhitelistCard | 完整（管理+查看） | 只读计数，无按钮 |
| AccountCard | 完整 | 仅头像/密码修改 |
| 其余卡片 | 同上 | 正常显示 |

**新增 ParentMessageCard**（儿童模式）：在 HomePage 中显示，不在 ProfileTab。

### 5.3 修改 HomePage

**文件**: `entry/src/main/ets/pages/HomePage.ets`

儿童模式时，在倒计时下方新增 `ParentMessageCard`：
- 显示家长最新一条未读消息
- 灯律时段内：常驻卡片 + "我知道了"按钮
- 非灯律时段：普通卡片，可点击查看更多

### 5.4 修改 EntryAbility

**文件**: `entry/src/main/ets/entryability/EntryAbility.ets`

启动流程改造：

```
EntryAbility.onWindowStageCreate()
  │
  ├─ AccountService.initialize()
  │    └─ 加载本地活跃帐号
  │
  ├─ 有活跃帐号？
  │    ├─ 是 → LanternLawStateManager.initialize(context, accountId)
  │    │       → loadContent('pages/MainPage')
  │    └─ 否 → loadContent('pages/AccountModeSelectPage')
  │             （首次使用或退出登录后）
  │
  ├─ 初始化 AppBlockingService、ScreenTimeGuardManager（同现有）
  │
  └─ Phase 2: ConfigSyncService.initialize()
               MessageService.initialize()
               Push Kit 注册
```

---

## 六、Cloud DB 对象类型定义

### 6.1 在 AGC 控制台创建的对象类型

**AccountObj**（帐号信息，用于跨设备同步）:
| 字段名 | 类型 | 约束 |
|--------|------|------|
| accountId | String | 主键 |
| username | String | 必填 |
| avatar | String | |
| accountMode | String | 必填 |
| familyGroupId | String | 索引 |
| parentAccountId | String | |
| deviceToken | String | 设备绑定标识 |
| updatedAt | Long | |

**FamilyGroupObj**（沟通组）:
| 字段名 | 类型 | 约束 |
|--------|------|------|
| groupId | String | 主键 |
| groupName | String | 必填 |
| parentAccountId | String | 必填 |
| invitationCode | String | 索引 |
| invitationExpiresAt | Long | |
| updatedAt | Long | |

**ChildConfigObj**（儿童配置，家长写入，儿童读取）:
| 字段名 | 类型 | 约束 |
|--------|------|------|
| accountId | String | 主键 |
| configJson | String | 必填 |
| updatedAt | Long | |

**MessageObj**（消息）:
| 字段名 | 类型 | 约束 |
|--------|------|------|
| id | String | 主键 |
| senderAccountId | String | 索引 |
| receiverAccountId | String | 索引 |
| messageType | String | |
| content | String | |
| isRead | Boolean | |
| createdAt | Long | |

---

## 七、Push Kit 集成

### 7.1 module.json5 新增

```json5
{
  "abilities": [
    {
      "name": "PushMessageAbility",
      "srcEntry": "./ets/abilities/PushMessageAbility.ets",
      "launchType": "singleton",
      "exported": false,
      "skills": [{ "actions": ["action.ohos.push.listener"] }]
    }
  ]
}
```

### 7.2 PushMessageAbility（新建）

**文件**: `entry/src/main/ets/abilities/PushMessageAbility.ets`

```typescript
export default class PushMessageAbility extends UIAbility {
  onCreate(): void {
    pushService.receiveMessage('DEFAULT', (data) => {
      // 解析推送数据
      const type = data.payload?.type; // 'config_update' | 'new_message' | 'child_join_request'
      switch (type) {
        case 'config_update':
          ConfigSyncService.getInstance().pullLatestConfig();
          break;
        case 'new_message':
          MessageService.getInstance().showMessageNotification(/*...*/);
          break;
        case 'child_join_request':
          // 显示家长确认对话框
          break;
      }
    });
  }
}
```

### 7.3 EntryAbility 中注册 Push Token

```typescript
// 在 initializeServices() 中
const token = await pushService.getToken();
// 上报 token 到 Cloud DB，关联到当前 accountId
await ConfigSyncService.getInstance().registerPushToken(token);
```

---

## 八、AGC Cloud Functions 详细设计

### 8.1 概述

AGC Cloud Functions 是华为 AppGallery Connect 提供的无服务器计算服务。掌灯人使用云函数实现**事件驱动的推送通知**，无需自建后端服务器。

**费用**：免费档提供 100 万次调用/月，掌灯人预估月调用量 < 1 万次，完全在免费额度内。

**运行方式**：云函数部署在 AGC 控制台，通过 Cloud DB 数据变更触发器自动执行，或通过客户端 SDK 直接调用。

### 8.2 云函数清单

#### 8.2.1 `onChildConfigUpdate` — 儿童配置变更通知

**触发方式**：Cloud DB `ChildConfigObj` 表 INSERT/UPDATE 触发器
**调用方**：家长客户端上传儿童配置时自动触发
**职责**：检测到儿童配置变更后，向儿童设备发送推送通知

```javascript
// 云函数入口（AGC 控制台编写）
const cloud = require('agconnect-clouddb');

exports.myHandler = async function(event, context, callback) {
  // event.data 包含变更的 ChildConfigObj 数据
  const changedRecord = event.data;

  // 查询儿童设备的 pushToken
  // 从 AccountObj 表中根据 accountId 查找 deviceToken
  const pushToken = await queryChildPushToken(changedRecord.accountId);

  if (pushToken) {
    // 调用 Push Kit REST API 发送推送
    await sendPushNotification({
      token: pushToken,
      title: '灯律设置更新',
      body: '家长更新了你的灯律设置',
      data: {
        type: 'config_update',
        accountId: changedRecord.accountId
      },
      foregroundShow: false  // 前台时由 receiveMessage 接收，不显示系统通知
    });
  }

  callback({ code: 0, msg: 'success' });
};
```

**触发流程**：
```
家长客户端
  → ConfigSyncService.uploadChildConfig()
  → 写入 Cloud DB ChildConfigObj
  → 触发器自动调用 onChildConfigUpdate 云函数
  → 云函数查询儿童 pushToken
  → 云函数调用 Push API 发送推送
  → 儿童客户端 PushMessageAbility.receiveMessage() 接收
  → ConfigSyncService.pullLatestConfig() 拉取最新配置
```

#### 8.2.2 `onNewMessage` — 新消息通知

**触发方式**：Cloud DB `MessageObj` 表 INSERT 触发器
**调用方**：家长或儿童发送消息时自动触发
**职责**：向接收方设备发送推送通知

```javascript
exports.myHandler = async function(event, context, callback) {
  const message = event.data;

  // 查询接收方的 pushToken
  const receiverToken = await queryPushToken(message.receiverAccountId);

  if (receiverToken) {
    await sendPushNotification({
      token: receiverToken,
      title: getSenderName(message.senderAccountId),
      body: message.content,
      data: {
        type: 'new_message',
        messageId: message.id,
        senderAccountId: message.senderAccountId
      },
      foregroundShow: message.messageType === 'system'  // 系统消息前台也显示通知
    });
  }

  callback({ code: 0, msg: 'success' });
};
```

#### 8.2.3 `onChildJoinRequest` — 儿童加入请求通知

**触发方式**：Cloud DB `AccountObj` 表 INSERT 触发器（当 accountMode='child' 且 familyGroupId 非空时）
**调用方**：儿童加入沟通组时自动触发
**职责**：通知家长设备有儿童请求加入

```javascript
exports.myHandler = async function(event, context, callback) {
  const childAccount = event.data;

  if (childAccount.accountMode !== 'child' || !childAccount.familyGroupId) {
    callback({ code: 0, msg: 'not a child join event' });
    return;
  }

  // 查询家长的 pushToken
  const parentToken = await queryPushToken(childAccount.parentAccountId);

  if (parentToken) {
    await sendPushNotification({
      token: parentToken,
      title: '加入请求',
      body: `${childAccount.username} 请求加入沟通组`,
      data: {
        type: 'child_join_request',
        childAccountId: childAccount.accountId,
        childUsername: childAccount.username
      }
    });
  }

  callback({ code: 0, msg: 'success' });
};
```

#### 8.2.4 `registerPushToken` — 注册推送令牌

**触发方式**：客户端 SDK 直接调用（非触发器）
**调用方**：应用启动时 EntryAbility 调用
**职责**：将设备 pushToken 与 accountId 关联存入 Cloud DB

```javascript
exports.myHandler = async function(event, context, callback) {
  const { accountId, pushToken } = event.data;

  // 更新 AccountObj 中该帐号的 deviceToken 字段
  await cloud.database().collection('AccountObj')
    .doc(accountId)
    .update({ deviceToken: pushToken, updatedAt: Date.now() });

  callback({ code: 0, msg: 'success' });
};
```

### 8.3 触发器配置

在 AGC 控制台为每个云函数配置 Cloud DB 触发器：

| 触发器名称 | 云函数 | 监听表 | 事件类型 |
|-----------|--------|--------|---------|
| `trigger_config_update` | `onChildConfigUpdate` | `ChildConfigObj` | INSERT, UPDATE |
| `trigger_new_message` | `onNewMessage` | `MessageObj` | INSERT |
| `trigger_child_join` | `onChildJoinRequest` | `AccountObj` | INSERT（条件过滤） |

### 8.4 AGC 控制台配置步骤

1. **创建项目**：登录 [AppGallery Connect](https://developer.huawei.com/consumer/cn/service/josp/agc/index.html)，创建项目，选择 HarmonyOS 平台
2. **下载配置文件**：项目设置 → 常规信息 → 下载 `agconnect-services.json`，放入 `entry/` 目录
3. **启用 Cloud DB**：
   - 开发与服务 → Cloud DB → 立即开通
   - 创建存储区 `lanternlaw_family`
   - 创建对象类型：`AccountObj`、`FamilyGroupObj`、`ChildConfigObj`、`MessageObj`（见第六节定义）
4. **启用云函数**：
   - 开发与服务 → Cloud Functions → 立即开通
   - 创建函数 `onChildConfigUpdate`、`onNewMessage`、`onChildJoinRequest`、`registerPushToken`
   - 编写函数代码并部署
5. **配置触发器**：每个云函数 → 触发器 → 创建 Cloud DB 触发器，关联对应的表和事件
6. **启用 Push Kit**：
   - 开发与服务 → Push Kit → 立即开通
   - 记录 `projectId` 和 `pushToken`（云函数调用推送 API 时需要）

### 8.5 客户端调用云函数的方式

客户端通过 `@kit.CloudFoundationKit` 调用云函数：

```typescript
import { cloudDatabase } from '@kit.CloudFoundationKit';

// 调用 registerPushToken 云函数
const zone = cloudDatabase.zone('lanternlaw_family');
const result = await zone.callFunction('registerPushToken', {
  accountId: this.activeAccountId,
  pushToken: pushToken
});
```

### 8.6 免费额度评估

| 计费项 | 免费配额 | 掌灯人预估用量 |
|--------|---------|--------------|
| 云函数调用次数 | 100 万次/月 | < 1 万次/月（家庭日均几十次事件） |
| Cloud DB 存储 | 1 GB | < 1 MB/月 |
| Cloud DB 读操作 | 5 万次/天 | < 5000 次/天 |
| Cloud DB 写操作 | 10 次/秒 | < 1 次/秒 |
| Push Kit 推送 | 免费 | < 100 条/天 |

**结论**：掌灯人作为家庭级应用，所有 AGC 服务用量远低于免费额度，无需付费。

---

## 九、实施步骤（按依赖顺序）

### Step 1: 数据层基础改造
**文件**:
- `models/UserAccount.ets` — 新增 accountId, accountMode, familyGroupId, parentAccountId 字段
- `models/AccountMode.ets` — 新建枚举
- `models/FamilyGroup.ets` — 新建模型
- `models/Message.ets` — 新建模型
- `database/LanternLawDatabase.ets` — 新增3张表，DB_VERSION 升为3，添加迁移逻辑，新增按 accountId 存取配置的方法

### Step 2: 帐号服务层
**文件**:
- `services/AccountService.ets` — 新建，帐号创建/加载/切换/退出
- `services/FamilyGroupService.ets` — 新建，沟通组CRUD、邀请码
- `managers/LanternLawStateManager.ets` — 修改，支持按 accountId 加载/保存配置
- `services/ScreenTimeGuardManager.ets` — 修改，策略名增加 accountId 前缀

### Step 3: 帐号创建流程 + 模式选择
**文件**:
- `pages/AccountModeSelectPage.ets` — 新建，选择家长/儿童模式
- `pages/JoinFamilyGroupPage.ets` — 新建，儿童输入邀请码
- `pages/ProfileTab.ets` — 修改 CreateAccountDialog，创建后跳转模式选择页
- `entryability/EntryAbility.ets` — 修改启动流程，无活跃帐号时跳转模式选择
- `resources/base/profile/main_pages.json` — 注册新页面

### Step 4: 沟通组管理 UI
**文件**:
- `pages/FamilyGroupPage.ets` — 新建，成员列表、邀请码、移除儿童
- `pages/ProfileTab.ets` — 新增 FamilyGroupCard、ChildManagementCard builder

### Step 5: 儿童模式只读 UI
**文件**:
- `pages/ProfileTab.ets` — GlobalSwitchCard/TimeManagementCard/WhitelistCard 条件渲染（家长/儿童）

### Step 6: 家长管理儿童配置
**文件**:
- `pages/ChildConfigPage.ets` — 新建，复用灯律/白名单配置组件
- `pages/ProfileTab.ets` — 点击儿童"管理"跳转 ChildConfigPage

### Step 7: 消息系统
**文件**:
- `services/MessageService.ets` — 新建，消息 CRUD + 通知展示
- `pages/MessageHistoryPage.ets` — 新建，消息历史列表
- `pages/HomePage.ets` — 儿童模式新增 ParentMessageCard
- `pages/ProfileTab.ets` — 儿童模式新增家长留言卡片

### Step 8: Cloud DB + Push Kit 接入（Phase 2）
**文件**:
- `services/ConfigSyncService.ets` — 新建，云端同步
- `abilities/PushMessageAbility.ets` — 新建，推送接收
- `entryability/EntryAbility.ets` — 注册 Push Token
- `module.json5` — 新增 PushMessageAbility、通知权限
- `entry/agconnect-services.json` — AGConnect 配置（不入 Git）

### Step 9: 数据迁移 + 用户引导
**文件**:
- `database/LanternLawDatabase.ets` — v2→v3 迁移逻辑
- `entryability/EntryAbility.ets` — 升级后首次启动检测 accountMode，弹出模式选择引导

---

## 十、关键文件清单

### 新建文件（12个）

| 文件 | 行数估算 | 说明 |
|------|---------|------|
| `models/AccountMode.ets` | ~10 | 枚举定义 |
| `models/FamilyGroup.ets` | ~40 | 沟通组模型 |
| `models/Message.ets` | ~50 | 消息模型 + 枚举 |
| `services/AccountService.ets` | ~200 | 帐号生命周期管理 |
| `services/FamilyGroupService.ets` | ~150 | 沟通组管理 |
| `services/MessageService.ets` | ~180 | 消息发送接收 |
| `services/ConfigSyncService.ets` | ~250 | 云端同步（Phase 2） |
| `abilities/PushMessageAbility.ets` | ~60 | 推送接收（Phase 2） |
| `pages/AccountModeSelectPage.ets` | ~150 | 模式选择页 |
| `pages/JoinFamilyGroupPage.ets` | ~120 | 加入沟通组页 |
| `pages/FamilyGroupPage.ets` | ~200 | 沟通组管理页 |
| `pages/ChildConfigPage.ets` | ~300 | 儿童配置管理页 |
| `pages/MessageHistoryPage.ets` | ~150 | 消息历史页 |

### 修改文件（8个）

| 文件 | 改动范围 | 说明 |
|------|---------|------|
| `models/UserAccount.ets` | 小 | 新增4个字段 + 枚举 |
| `database/LanternLawDatabase.ets` | 大 | 新增3张表 + 迁移 + 10+ 新方法 |
| `managers/LanternLawStateManager.ets` | 中 | 按 accountId 加载/保存配置 |
| `services/ScreenTimeGuardManager.ets` | 小 | 策略名增加 accountId 前缀 |
| `pages/ProfileTab.ets` | 大 | 条件渲染 + 新增2个卡片builder + 大量@State |
| `pages/HomePage.ets` | 中 | 儿童模式消息卡片 |
| `entryability/EntryAbility.ets` | 中 | 启动流程改造 |
| `resources/base/profile/main_pages.json` | 小 | 注册新页面 |

---

## 十一、验证方案

### Phase 1 验证（本地多帐号）

1. **数据库迁移**：安装旧版本 → 创建帐号 → 安装新版本 → 验证帐号数据已迁移到 accounts 表，config key 已重命名
2. **帐号创建 + 模式选择**：卸载重装 → 创建帐号 → 选择家长模式 → 验证 ProfileTab 显示家长模式卡片
3. **儿童模式只读**：创建儿童帐号 → 验证灯律/白名单卡片只读，开关不可操作
4. **沟通组创建**：家长创建沟通组 → 生成邀请码 → 验证邀请码显示和复制
5. **儿童加入**：儿童输入邀请码 → 家长确认 → 验证成员列表更新
6. **家长配置儿童**：家长点击儿童"管理" → 配置灯律/白名单 → 验证儿童端配置更新
7. **消息功能**：家长发送消息 → 儿童收到 → 回复 → 验证消息历史
8. **密码保护**：所有管控配置修改操作仍需密码验证

### Phase 2 验证（跨设备）

1. **Cloud DB 同步**：家长设备配置儿童灯律 → 儿童设备在线拉取 → 验证策略生效
2. **离线同步**：儿童离线时家长更新配置 → 儿童上线后自动同步
3. **推送通知**：家长发送消息 → 儿童设备收到推送 → 验证常驻通知展示
4. **设备绑定**：同一帐号不能在两台设备同时登录
