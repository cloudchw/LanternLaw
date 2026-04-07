# 掌灯人 - 多帐号家庭体系 分阶段实施计划

> 版本: v1.0 | 日期: 2026-04-07
> 依据: `2026-04-07-family-account-system-design.md` + `2026-04-07-family-account-system-technical.md`

---

## 总体策略

将技术方案中的 9 个 Step 重新组织为 **6 个可独立验证的阶段**。每个阶段交付后应用可正常运行在模拟器上，后续阶段在前序基础上增量开发。

```
Phase 1        Phase 2        Phase 3        Phase 4        Phase 5        Phase 6
数据层+        沟通组        儿童只读      家长管理      消息系统      云端同步
帐号模式      管理UI        模式UI        儿童配置      本地消息      +推送
───────>      ───────>      ───────>      ───────>      ───────>      ───────>
可创建帐号    可管理沟通组   儿童只读可用   家长可远程     家长儿童      跨设备
选家长/儿童    邀请码加入    验证只读限制   配置儿童      可互相发消息  实时同步
```

---

## Phase 1: 数据层基础改造 + 帐号模式选择

**目标**：扩展数据模型支持多帐号，帐号创建后可选择家长/儿童模式。完成后应用可正常创建帐号并选择身份，原有功能不受影响。

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 1.1 | 新增 AccountMode 枚举 | 新建 | `models/AccountMode.ets` |
| 1.2 | 扩展 UserAccount 模型 | 修改 | `models/UserAccount.ets` |
| 1.3 | 新增 FamilyGroup 模型 | 新建 | `models/FamilyGroup.ets` |
| 1.4 | 新增 FamilyMessage 模型 | 新建 | `models/Message.ets` |
| 1.5 | RDB 新增 accounts/family_groups/messages 三张表，DB_VERSION 升至 3 | 修改 | `database/LanternLawDatabase.ets` |
| 1.6 | 编写 v2→v3 迁移逻辑（现有帐号自动生成 accountId，配置 key 重命名） | 修改 | `database/LanternLawDatabase.ets` |
| 1.7 | 新增按 accountId 存取配置的方法（saveAccountConfig/getAccountConfig） | 修改 | `database/LanternLawDatabase.ets` |
| 1.8 | 新增帐号 CRUD 方法（getActiveAccount/saveAccount 等） | 修改 | `database/LanternLawDatabase.ets` |
| 1.9 | 新增沟通组/消息 CRUD 方法 | 修改 | `database/LanternLawDatabase.ets` |
| 1.10 | LanternLawStateManager 支持按 accountId 加载/保存配置 | 修改 | `managers/LanternLawStateManager.ets` |
| 1.11 | ScreenTimeGuardManager 策略名增加 accountId 前缀 | 修改 | `services/ScreenTimeGuardManager.ets` |
| 1.12 | 新建 AccountService（帐号创建/加载/退出） | 新建 | `services/AccountService.ets` |
| 1.13 | 新建帐号模式选择页面 | 新建 | `pages/AccountModeSelectPage.ets` |
| 1.14 | 修改 CreateAccountDialog，创建后跳转模式选择页 | 修改 | `pages/ProfileTab.ets` |
| 1.15 | 修改 EntryAbility 启动流程，无活跃帐号时跳转模式选择 | 修改 | `entryability/EntryAbility.ets` |
| 1.16 | 注册新页面到 main_pages.json | 修改 | `resources/base/profile/main_pages.json` |

### 验证标准

- [ ] 卸载旧版本 → 安装新版本 → 现有帐号自动迁移（accounts 表有数据，config key 已重命名）
- [ ] 卸载重装 → 创建帐号 → 弹出模式选择页 → 选择"家长模式" → 进入主页
- [ ] 选择"儿童模式" → 进入主页（暂时等同家长模式，后续 Phase 3 区分）
- [ ] ProfileTab 帐号卡片正确显示用户名、头像、模式标签
- [ ] 原有功能全部正常：灯律时段增删改、白名单管理、全局开关、密码验证
- [ ] 构建零错误，模拟器安装运行正常

### 风险控制

- 数据库迁移是最核心的改动，必须确保 v2→v3 迁移逻辑正确处理旧数据
- 此阶段不改变任何 UI 交互逻辑，仅扩展数据层，回归风险低
- 新增的 AccountService 暂不接入启动流程，仅作为独立模块存在

---

## Phase 2: 沟通组管理

**目标**：家长可创建沟通组、生成邀请码，支持本地模拟的加入/确认/移除流程。

### 前置条件：Phase 1 完成

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 2.1 | 新建 FamilyGroupService（沟通组 CRUD、邀请码生成/验证） | 新建 | `services/FamilyGroupService.ets` |
| 2.2 | 新建沟通组管理页面（成员列表、邀请码显示/复制/刷新、移除儿童） | 新建 | `pages/FamilyGroupPage.ets` |
| 2.3 | ProfileTab 新增 FamilyGroupCard builder（家长模式显示） | 修改 | `pages/ProfileTab.ets` |
| 2.4 | ProfileTab 新增 ChildManagementCard builder（有儿童时显示） | 修改 | `pages/ProfileTab.ets` |
| 2.5 | 新建加入沟通组页面（儿童输入邀请码） | 新建 | `pages/JoinFamilyGroupPage.ets` |
| 2.6 | 注册新页面到 main_pages.json | 修改 | `resources/base/profile/main_pages.json` |

### 验证标准

- [ ] 家长模式 ProfileTab 显示"沟通组管理"卡片
- [ ] 点击进入沟通组管理页 → 创建沟通组（输入组名）→ 创建成功
- [ ] 沟通组管理页显示邀请码（6位），可复制
- [ ] 邀请码 24 小时过期逻辑正确
- [ ] 沟通组管理页可移除儿童成员
- [ ] 儿童帐号在加入沟通组页输入正确邀请码 → 加入成功
- [ ] 输入错误/过期邀请码 → 显示错误提示
- [ ] 加入后沟通组管理页显示儿童成员列表

### 风险控制

- 此阶段所有操作均在本地 RDB 完成，不涉及云端，可完全在模拟器验证
- 邀请码生成使用简单随机算法，无需复杂加密
- 加入/移除操作不影响现有灯律配置功能

---

## Phase 3: 儿童模式只读 UI

**目标**：儿童模式下管控设置变为只读，儿童无法修改灯律时段、白名单和全局开关。

### 前置条件：Phase 1 完成

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 3.1 | ProfileTab 根据 accountMode 条件渲染各卡片 | 修改 | `pages/ProfileTab.ets` |
| 3.2 | GlobalSwitchCard 儿童模式：显示管控状态，隐藏开关 | 修改 | `pages/ProfileTab.ets` |
| 3.3 | TimeManagementCard 儿童模式：只读列表，隐藏 +/删除/编辑 | 修改 | `pages/ProfileTab.ets` |
| 3.4 | WhitelistCard 儿童模式：只读计数，隐藏管理/查看按钮 | 修改 | `pages/ProfileTab.ets` |
| 3.5 | AccountCard 儿童模式：保留头像/密码修改，隐藏用户名/模式相关 | 修改 | `pages/ProfileTab.ets` |
| 3.6 | 儿童模式 ProfileTab 新增"灯律由家长管理"提示卡片 | 修改 | `pages/ProfileTab.ets` |
| 3.7 | EntryAbility 根据 accountMode 限制密码对话框的触发场景 | 修改 | `entryability/EntryAbility.ets` |

### 验证标准

- [ ] 家长帐号：所有卡片功能正常，与 Phase 1 行为一致
- [ ] 切换到儿童帐号（可通过数据库手动切换 is_local_active）：
  - [ ] 全局开关不可操作，显示"管控中/未管控"状态
  - [ ] 灯律时段列表正常显示，但无 + 按钮，点击时间段不进入编辑
  - [ ] 白名单卡片显示应用数量，但无"管理"和"查看"按钮
  - [ ] 通知设置卡片正常（本地偏好设置，儿童可修改）
  - [ ] 帐号卡片仅显示头像、密码修改/找回密码
- [ ] 儿童模式下无法通过密码对话框修改任何管控设置
- [ ] 构建零错误

### 风险控制

- 此阶段仅修改 ProfileTab 的条件渲染逻辑，不改变数据层
- 最安全的验证方式：家长功能不受任何影响，仅新增儿童只读分支
- 可通过手动修改数据库 `account_mode` 字段在家长/儿童之间切换测试

---

## Phase 4: 家长管理儿童配置

**目标**：家长可查看沟通组中的儿童列表，点击"管理"进入专门的配置页面，为儿童设置灯律时段和白名单应用。儿童配置存储在本地 RDB（按儿童 accountId 隔离），Phase 6 才同步到云端。

### 前置条件：Phase 2 完成

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 4.1 | 新建儿童配置管理页面 ChildConfigPage | 新建 | `pages/ChildConfigPage.ets` |
| 4.2 | ChildConfigPage 复用 TimePickerDialog 逻辑（增删改灯律时段） | 新建 | `pages/ChildConfigPage.ets` |
| 4.3 | ChildConfigPage 复用白名单选择逻辑（管理儿童白名单） | 新建 | `pages/ChildConfigPage.ets` |
| 4.4 | ChildConfigPage 儿童全局开关（远程启用/停用儿童管控） | 新建 | `pages/ChildConfigPage.ets` |
| 4.5 | ChildConfigPage 修改操作需密码验证 | 新建 | `pages/ChildConfigPage.ets` |
| 4.6 | LanternLawStateManager 新增 saveConfigForAccount/getConfigForAccount | 修改 | `managers/LanternLawStateManager.ets` |
| 4.7 | ProfileTab ChildManagementCard 点击"管理"跳转 ChildConfigPage | 修改 | `pages/ProfileTab.ets` |
| 4.8 | 注册新页面到 main_pages.json | 修改 | `resources/base/profile/main_pages.json` |

### 验证标准

- [ ] 家长 ProfileTab 显示"孩子管理"卡片，列出沟通组内所有儿童
- [ ] 点击儿童"管理"→ 进入 ChildConfigPage
- [ ] ChildConfigPage 顶部显示儿童用户名和头像
- [ ] 可为儿童启用/停用灯律管控（需密码验证）
- [ ] 可为儿童添加/编辑/删除灯律时段（需密码验证）
- [ ] 可为儿童管理白名单应用（需密码验证）
- [ ] 儿童配置保存到 `lanternlaw_config_<childAccountId>` key，与家长配置隔离
- [ ] 儿童帐号登录后加载的是自己的配置（Phase 6 实现跨设备同步前，本地模拟）
- [ ] 家长自己的配置不受影响

### 风险控制

- ChildConfigPage 是独立新页面，不影响现有 ProfileTab 的任何逻辑
- 配置按 accountId 隔离存储，家长和儿童配置互不干扰
- ScreenTimeGuard 策略仍按当前设备活跃帐号同步，Phase 4 中儿童配置仅在本地存储，不应用到系统策略（Phase 6 解决）

---

## Phase 5: 消息系统（本地）

**目标**：家长和儿童可互相发送消息（快捷模板 + 自定义），消息存储在本地 RDB，在 UI 中展示。

### 前置条件：Phase 2 完成

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 5.1 | 新建 MessageService（消息 CRUD、未读计数、标记已读） | 新建 | `services/MessageService.ets` |
| 5.2 | 新建消息历史页面 | 新建 | `pages/MessageHistoryPage.ets` |
| 5.3 | HomePage 儿童模式新增 ParentMessageCard（显示家长最新消息） | 修改 | `pages/HomePage.ets` |
| 5.4 | ProfileTab 儿童模式新增"家长留言"卡片（最近3条消息） | 修改 | `pages/ProfileTab.ets` |
| 5.5 | ProfileTab 家长模式 ChildManagementCard 新增"发消息"入口 | 修改 | `pages/ProfileTab.ets` |
| 5.6 | 快捷消息模板定义（家长→儿童 5条，儿童→家长 3条） | 新建 | `services/MessageService.ets` |
| 5.7 | 新建消息发送弹窗（选择快捷模板或输入自定义消息） | 新建 | `pages/ProfileTab.ets`（builder） |
| 5.8 | 注册新页面到 main_pages.json | 修改 | `resources/base/profile/main_pages.json` |

### 验证标准

- [ ] 家长在 ChildManagementCard 点击某儿童 → 可发送消息
- [ ] 消息弹窗显示 5 个快捷模板 + 自定义输入框
- [ ] 发送成功后消息出现在本地消息列表
- [ ] 儿童 HomePage 显示"来自家长的新消息"卡片
- [ ] 儿童 ProfileTab 显示"家长留言"卡片（最近 3 条）
- [ ] 点击消息卡片 → 进入 MessageHistoryPage 查看完整历史
- [ ] 儿童可从快捷模板选择回复
- [ ] 未读消息数量正确计算
- [ ] 标记已读后未读数归零

### 风险控制

- 消息系统完全独立于灯律管控功能，互不影响
- 此阶段消息仅在本地存储，Phase 6 才实现跨设备传递
- 可通过在同一设备上切换帐号模拟家长→儿童的消息收发

---

## Phase 6: 云端同步 + 推送通知

**目标**：接入 AGC Cloud DB 和 Push Kit，实现跨设备配置同步和消息推送。

### 前置条件：Phase 1-5 全部完成，AGC 控制台已配置

### 交付物

| # | 任务 | 类型 | 涉及文件 |
|---|------|------|---------|
| 6.1 | AGC 控制台配置：创建项目、启用 Cloud DB/Push Kit/Cloud Functions | 运维 | AGC 控制台 |
| 6.2 | 下载 agconnect-services.json 放入 entry/ 目录 | 配置 | `entry/agconnect-services.json` |
| 6.3 | AGC 控制台创建 Cloud DB 存储区和 4 个对象类型 | 运维 | AGC 控制台 |
| 6.4 | 新建 ConfigSyncService（Cloud DB 读写、定时同步） | 新建 | `services/ConfigSyncService.ets` |
| 6.5 | 新建 PushMessageAbility（接收推送消息） | 新建 | `abilities/PushMessageAbility.ets` |
| 6.6 | AGC 控制台编写 4 个云函数并部署 | 运维 | AGC 控制台 |
| 6.7 | AGC 控制台配置 3 个 Cloud DB 触发器 | 运维 | AGC 控制台 |
| 6.8 | EntryAbility 注册 Push Token，初始化 ConfigSyncService | 修改 | `entryability/EntryAbility.ets` |
| 6.9 | module.json5 新增 PushMessageAbility 和通知权限 | 修改 | `module.json5` |
| 6.10 | 家长修改儿童配置后自动同步到云端 | 修改 | `services/ConfigSyncService.ets` |
| 6.11 | 儿童设备拉取云端最新配置并应用到 ScreenTimeGuard | 修改 | `services/ConfigSyncService.ets` |
| 6.12 | 消息发送同步到 Cloud DB，触发云函数推送 | 修改 | `services/MessageService.ets` |
| 6.13 | 儿童端收到推送后展示常驻通知（灯律时段内） | 修改 | `services/MessageService.ets` |
| 6.14 | 儿童加入沟通组时通知家长 | 修改 | `services/FamilyGroupService.ets` |

### 验证标准

- [ ] 家长设备 A 配置儿童灯律 → 儿童设备 B 自动拉取最新配置
- [ ] 儿童设备 B 离线 → 家长更新配置 → 儿童 B 上线后自动同步
- [ ] 家长发送消息 → 儿童设备收到推送通知
- [ ] 灯律时段内儿童收到常驻通知（不可划走）
- [ ] 儿童发送消息 → 家长设备收到推送通知
- [ ] 儿童输入邀请码加入 → 家长设备收到"请求加入"通知
- [ ] 设备绑定：同一帐号不能在两台设备同时活跃
- [ ] 免费配额监控：AGC 控制台查看各项用量未超过免费额度

### 风险控制

- 此阶段依赖 AGC 控制台配置，必须先完成 AGC 项目创建和服务开通
- 建议先在 AGC 控制台手动测试 Cloud DB 和 Push Kit 基础功能
- Cloud DB 离线优先设计保证儿童设备离线时仍按最新配置运行
- 保留本地 RDB 作为缓存，云端不可用时降级为本地模式
- 此阶段改动集中在新建的 Service 层和 Ability 层，不改变 UI 层

---

## 阶段依赖关系

```
Phase 1 ───┬── Phase 2 ───┬── Phase 3
  (数据层)  │  (沟通组)   │  (儿童只读)
           │              │
           ├── Phase 4 ───┤
           │  (管理儿童)   │
           │              │
           ├── Phase 5 ───┘
           │  (消息系统)
           │
           └── Phase 6 (云端同步)
              依赖 Phase 1-5 全部完成
```

## 质量门禁

每个阶段提交前必须通过以下检查：

1. **编译检查**：`hvigorw assembleHap` 零错误零警告
2. **冒烟测试**：模拟器安装运行，核心流程走通
3. **回归测试**：上一阶段的功能仍然正常
4. **代码审查**：确保不引入死代码、不破坏现有架构
5. **Git 提交**：每个阶段一个独立 commit，便于回滚
