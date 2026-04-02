# 账号管理功能 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在"我的"Tab 中新增账号管理卡片，支持创建账号、修改用户名/头像/密码、通过系统锁屏验证找回密码。

**Architecture:** 新建 `UserAccount` 数据模型和 `PasswordHelper` 工具类，在现有 RDB `lanternlaw_config` 表中以 key `user_account` 存储。UI 层在 `ProfileTab` 中新增 `AccountCard` 和 5 个弹窗 builder。首次启动检测无账号时在 `MainPage` 层展示创建账号弹窗。

**Tech Stack:** ArkTS, @ohos.security.crypto (SHA-256), @ohos.userAuthentication (系统锁屏验证), RDB (lanternlaw_config 表)

**Design doc:** `docs/superpowers/specs/2026-04-03-account-management-design.md`

---

### Task 1: 创建 UserAccount 数据模型

**Files:**
- Create: `entry/src/main/ets/models/UserAccount.ets`

- [ ] **Step 1: 创建 UserAccount 模型文件**

```typescript
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
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/models/UserAccount.ets
git commit -m "feat(account): add UserAccount data model"
```

---

### Task 2: 创建 PasswordHelper 工具类

**Files:**
- Create: `entry/src/main/ets/utils/PasswordHelper.ets`

- [ ] **Step 1: 创建密码工具类**

```typescript
// entry/src/main/ets/utils/PasswordHelper.ets

/**
 * 密码工具类
 * Password Helper - SHA-256 哈希与验证
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';

const SALT = 'LanternLaw_2026_Salt';

/**
 * 对密码进行 SHA-256 哈希
 */
export async function hashPassword(password: string): Promise<string> {
  const data = buffer.from(password + SALT, 'utf-8').buffer;
  const md = cryptoFramework.createMd('SHA256');
  const hashData = await md.compute({ data: new Uint8Array(data) });
  return Array.from(new Uint8Array(hashData.data)).map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * 验证密码是否匹配哈希值
 */
export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  const computedHash = await hashPassword(password);
  return computedHash === hash;
}

/**
 * 验证用户名格式
 * @returns 错误信息，空字符串表示验证通过
 */
export function validateUsername(username: string): string {
  if (!username || username.trim().length === 0) {
    return '请输入用户名';
  }
  if (username.trim().length < 2) {
    return '用户名至少需要2个字符';
  }
  if (username.trim().length > 12) {
    return '用户名最多12个字符';
  }
  return '';
}

/**
 * 验证密码格式
 * @returns 错误信息，空字符串表示验证通过
 */
export function validatePassword(password: string): string {
  if (!password || password.length === 0) {
    return '请输入密码';
  }
  if (password.length < 6) {
    return '密码至少需要6个字符';
  }
  if (password.length > 20) {
    return '密码最多20个字符';
  }
  return '';
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/utils/PasswordHelper.ets
git commit -m "feat(account): add PasswordHelper utility with SHA-256 hashing"
```

---

### Task 3: 在 LanternLawDatabase 中新增账号读写方法

**Files:**
- Modify: `entry/src/main/ets/database/LanternLawDatabase.ets`

- [ ] **Step 1: 在 LanternLawDatabase 类末尾（`close()` 方法之前）新增两个方法**

在 `LanternLawDatabase` 类中 `close()` 方法前添加：

```typescript
  // ==================== 用户账号管理 ====================

  private static readonly KEY_USER_ACCOUNT = 'user_account';

  /**
   * 保存用户账号
   */
  public async saveUserAccount(accountJson: string): Promise<void> {
    await this.saveConfig(LanternLawDatabase.KEY_USER_ACCOUNT, accountJson);
  }

  /**
   * 获取用户账号
   * @returns 账号 JSON 字符串，不存在时返回 null
   */
  public async getUserAccount(): Promise<string | null> {
    return await this.getConfig(LanternLawDatabase.KEY_USER_ACCOUNT);
  }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/database/LanternLawDatabase.ets
git commit -m "feat(account): add saveUserAccount/getUserAccount to database"
```

---

### Task 4: 在 LanternLawStateManager 中新增账号管理方法

**Files:**
- Modify: `entry/src/main/ets/managers/LanternLawStateManager.ets`

- [ ] **Step 1: 添加 import**

在文件顶部 import 区域添加：

```typescript
import { UserAccount } from '../models/UserAccount';
```

- [ ] **Step 2: 在类末尾 `useEmergencyUnlock()` 方法之后新增账号管理方法**

```typescript
  // ==================== 用户账号管理 ====================

  /**
   * 获取用户账号
   */
  public async getUserAccount(): Promise<UserAccount | null> {
    try {
      const json = await this.database.getUserAccount();
      if (json) {
        return UserAccount.fromJSON(json);
      }
      return null;
    } catch (error) {
      console.error(`获取用户账号失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存用户账号
   */
  public async saveUserAccount(account: UserAccount): Promise<void> {
    try {
      account.updatedAt = Date.now();
      await this.database.saveUserAccount(account.toJSON());
    } catch (error) {
      console.error(`保存用户账号失败: ${JSON.stringify(error)}`);
      throw new Error(`保存用户账号失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/managers/LanternLawStateManager.ets
git commit -m "feat(account): add account management methods to state manager"
```

---

### Task 5: 在 ProfileTab 中新增账号管理卡片和弹窗 — 状态变量与 import

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileTab.ets`

- [ ] **Step 1: 添加 import**

在文件顶部 import 区域添加：

```typescript
import { UserAccount } from '../models/UserAccount';
import { PasswordHelper, hashPassword, verifyPassword } from '../utils/PasswordHelper';
import userAuth from '@ohos.userAuthentication';
```

- [ ] **Step 2: 在 `@Component` struct 内，现有 `@State` 声明之后（约第48行 `deleteTimeRangeId` 之后），添加账号相关状态变量**

```typescript
  // 账号管理状态
  @State currentAccount: UserAccount | null = null;
  @State showCreateAccount: boolean = false;
  @State showAvatarPicker: boolean = false;
  @State showEditUsername: boolean = false;
  @State showChangePassword: boolean = false;
  @State showResetPassword: boolean = false;
  // 创建账号表单
  @State createUsername: string = '';
  @State createAvatar: string = '😊';
  @State createPassword: string = '';
  @State createConfirmPassword: string = '';
  @State createAccountError: string = '';
  // 修改用户名表单
  @State editUsernameInput: string = '';
  // 修改密码表单
  @State oldPassword: string = '';
  @State newPassword: string = '';
  @State confirmNewPassword: string = '';
  @State changePasswordError: string = '';
  // 找回密码表单
  @State resetPassword: string = '';
  @State resetConfirmPassword: string = '';
  @State resetPasswordError: string = '';
  @State resetAuthPassed: boolean = false;
  // 头像选择
  @State selectedAvatar: string = '😊';
  // 头像弹窗来源: 'create' | 'edit'
  @State avatarPickerSource: string = 'create';
```

- [ ] **Step 3: 在 `aboutToAppear()` 方法中加载账号**

在 `this.loadConfig();` 之后添加：

```typescript
    this.loadAccount();
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/pages/ProfileTab.ets
git commit -m "feat(account): add account state variables and imports to ProfileTab"
```

---

### Task 6: 在 ProfileTab 中新增账号管理卡片 builder

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileTab.ets`

- [ ] **Step 1: 在 `NotificationCard()` builder 之后、`AboutCard()` builder 之前，添加 `AccountCard()` builder**

```typescript
  /**
   * 账号管理卡片
   */
  @Builder
  private AccountCard(): void {
    Column() {
      Row() {
        Text('👤')
          .fontSize(18)
          .margin({ right: 12 })
        Text('账号管理')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 操作列表
      Column() {
        Row() {
          Text('修改用户名')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.text)
          Blank()
          Text('>')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          if (this.currentAccount) {
            this.editUsernameInput = this.currentAccount!.username;
            this.showEditUsername = true;
          }
        })

        // 分割线
        Column()
          .width('100%')
          .height(0.5)
          .backgroundColor(ProfileTab.COLORS.border)

        Row() {
          Text('修改头像')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.text)
          Blank()
          Row() {
            Text(this.currentAccount?.avatar ?? '😊')
              .fontSize(18)
              .margin({ right: 4 })
            Text('>')
              .fontSize(14)
              .fontColor(ProfileTab.COLORS.textDim)
          }
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          this.selectedAvatar = this.currentAccount?.avatar ?? '😊';
          this.avatarPickerSource = 'edit';
          this.showAvatarPicker = true;
        })

        Column()
          .width('100%')
          .height(0.5)
          .backgroundColor(ProfileTab.COLORS.border)

        Row() {
          Text('修改密码')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.text)
          Blank()
          Text('>')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          this.oldPassword = '';
          this.newPassword = '';
          this.confirmNewPassword = '';
          this.changePasswordError = '';
          this.showChangePassword = true;
        })

        Column()
          .width('100%')
          .height(0.5)
          .backgroundColor(ProfileTab.COLORS.border)

        Row() {
          Text('找回密码')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.text)
          Blank()
          Text('>')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .onClick(() => {
          this.resetPassword = '';
          this.resetConfirmPassword = '';
          this.resetPasswordError = '';
          this.resetAuthPassed = false;
          this.showResetPassword = true;
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }
```

- [ ] **Step 2: 在 `build()` 方法中的 Scroll Column 里，将卡片顺序调整为正确位置**

将现有的：
```typescript
            this.GlobalSwitchCard()
            this.TimeManagementCard()
            this.WhitelistCard()
            this.NotificationCard()
            this.AboutCard()
```

改为：
```typescript
            this.GlobalSwitchCard()
            this.TimeManagementCard()
            this.WhitelistCard()
            this.NotificationCard()
            this.AccountCard()
            this.AboutCard()
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/pages/ProfileTab.ets
git commit -m "feat(account): add AccountCard builder with menu items"
```

---

### Task 7: 在 ProfileTab 中添加弹窗遮罩（Stack 层）

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileTab.ets`

- [ ] **Step 1: 在 `build()` 方法的 Stack 中，现有弹窗遮罩（`showDeleteTimeRangeConfirm` 的 if 块）之后，添加账号相关弹窗遮罩**

```typescript
      // 创建账号对话框
      if (this.showCreateAccount) {
        Column() {
          Column() {
            this.CreateAccountDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
      }

      // 头像选择对话框
      if (this.showAvatarPicker) {
        Column() {
          Column() {
            this.AvatarPickerDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showAvatarPicker = false;
        })
      }

      // 修改用户名对话框
      if (this.showEditUsername) {
        Column() {
          Column() {
            this.EditUsernameDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showEditUsername = false;
        })
      }

      // 修改密码对话框
      if (this.showChangePassword) {
        Column() {
          Column() {
            this.ChangePasswordDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showChangePassword = false;
        })
      }

      // 找回密码对话框
      if (this.showResetPassword) {
        Column() {
          Column() {
            this.ResetPasswordDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showResetPassword = false;
        })
      }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/ProfileTab.ets
git commit -m "feat(account): add dialog overlay containers for all account dialogs"
```

---

### Task 8: 在 ProfileTab 中添加所有弹窗 builder

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileTab.ets`

- [ ] **Step 1: 在 `AboutCard()` builder 之后、`toggleGlobalSwitch()` 方法之前，添加 5 个弹窗 builder**

```typescript
  // ==================== 账号管理弹窗 ====================

  private readonly AVATAR_LIST: string[] = [
    '😊', '😄', '😎', '🤓', '😇', '🥳',
    '🦊', '🐱', '🐶', '🐼', '🦁', '🐯',
    '🌙', '⭐', '🔥', '💪', '🎯', '🏆',
    '🌸', '🍀', '🎨', '📚', '🧘', '💡'
  ];

  /**
   * 创建账号弹窗
   */
  @Builder
  private CreateAccountDialog(): void {
    Column() {
      Text('创建你的账号')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      // 头像选择区域
      Column()
        .width(64)
        .height(64)
        .borderRadius(32)
        .backgroundColor(ProfileTab.COLORS.background)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.selectedAvatar = this.createAvatar;
          this.avatarPickerSource = 'create';
          this.showAvatarPicker = true;
        }) {
          Text(this.createAvatar)
            .fontSize(32)
          Text('点击选择')
            .fontSize(10)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .margin({ bottom: 20 })

      // 用户名
      Text('用户名')
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.text)
        .width('100%')
        .margin({ bottom: 6 })
      TextInput({ placeholder: '请输入用户名', text: this.createUsername })
        .width('100%')
        .height(40)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.createUsername = value;
          this.createAccountError = '';
        })

      // 密码
      Text('设置密码')
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.text)
        .width('100%')
        .margin({ top: 16, bottom: 6 })
      TextInput({ placeholder: '请设置密码(6-20位)', text: this.createPassword })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.createPassword = value;
          this.createAccountError = '';
        })

      // 确认密码
      Text('确认密码')
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.text)
        .width('100%')
        .margin({ top: 16, bottom: 6 })
      TextInput({ placeholder: '请再次输入密码', text: this.createConfirmPassword })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.createConfirmPassword = value;
          this.createAccountError = '';
        })

      // 错误提示
      if (this.createAccountError) {
        Text(this.createAccountError)
          .fontSize(12)
          .fontColor('#ff4444')
          .margin({ top: 8 })
      }

      // 按钮
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showCreateAccount = false;
          })

        Button('创建')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.handleCreateAccount();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('88%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(20)
    .padding(24)
    .onClick((event: ClickEvent) => {
      event.stopPropagation();
    })
  }

  /**
   * 选择头像弹窗
   */
  @Builder
  private AvatarPickerDialog(): void {
    Column() {
      Text('选择头像')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })

      // 4行6列网格
      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceAround }) {
        ForEach(this.AVATAR_LIST, (emoji: string) => {
          Column() {
            Text(emoji)
              .fontSize(28)
          }
          .width('15%')
          .height(56)
          .borderRadius(12)
          .backgroundColor(this.selectedAvatar === emoji ? 'rgba(255, 209, 102, 0.2)' : 'transparent')
          .border({
            width: this.selectedAvatar === emoji ? 2 : 0,
            color: ProfileTab.COLORS.gold,
            radius: 12
          })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.selectedAvatar = emoji;
          })
        }, (emoji: string) => emoji)
      }
      .width('100%')
      .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showAvatarPicker = false;
          })

        Button('确认')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            if (this.avatarPickerSource === 'create') {
              this.createAvatar = this.selectedAvatar;
            } else {
              this.handleUpdateAvatar(this.selectedAvatar);
            }
            this.showAvatarPicker = false;
          })
      }
      .width('100%')
    }
    .width('88%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(20)
    .padding(24)
    .onClick((event: ClickEvent) => {
      event.stopPropagation();
    })
  }

  /**
   * 修改用户名弹窗
   */
  @Builder
  private EditUsernameDialog(): void {
    Column() {
      Text('修改用户名')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      TextInput({ placeholder: '请输入新用户名', text: this.editUsernameInput })
        .width('100%')
        .height(40)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.editUsernameInput = value;
        })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showEditUsername = false;
          })

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.handleUpdateUsername();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('70%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(16)
    .padding(20)
    .onClick((event: ClickEvent) => {
      event.stopPropagation();
    })
  }

  /**
   * 修改密码弹窗
   */
  @Builder
  private ChangePasswordDialog(): void {
    Column() {
      Text('修改密码')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      TextInput({ placeholder: '请输入旧密码', text: this.oldPassword })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.oldPassword = value;
          this.changePasswordError = '';
        })

      TextInput({ placeholder: '请输入新密码(6-20位)', text: this.newPassword })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.newPassword = value;
          this.changePasswordError = '';
        })

      TextInput({ placeholder: '请再次输入新密码', text: this.confirmNewPassword })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.confirmNewPassword = value;
          this.changePasswordError = '';
        })

      if (this.changePasswordError) {
        Text(this.changePasswordError)
          .fontSize(12)
          .fontColor('#ff4444')
          .margin({ top: 8 })
      }

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showChangePassword = false;
          })

        Button('保存')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.handleChangePassword();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('88%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(20)
    .padding(24)
    .onClick((event: ClickEvent) => {
      event.stopPropagation();
    })
  }

  /**
   * 找回密码弹窗
   */
  @Builder
  private ResetPasswordDialog(): void {
    Column() {
      Text('找回密码')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 })

      Text('忘记密码？将通过系统锁屏验证你的身份后重置密码。')
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.textDim)
        .width('100%')
        .margin({ bottom: 20 })

      if (!this.resetAuthPassed) {
        Button('🔐 验证系统锁屏密码')
          .width('100%')
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .onClick(() => {
            this.handleSystemAuth();
          })
      } else {
        // 验证通过后显示重置密码表单
        TextInput({ placeholder: '请设置新密码(6-20位)', text: this.resetPassword })
          .width('100%')
          .height(40)
          .type(InputType.Password)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .margin({ bottom: 16 })
          .onChange((value: string) => {
            this.resetPassword = value;
            this.resetPasswordError = '';
          })

        TextInput({ placeholder: '请再次输入新密码', text: this.resetConfirmPassword })
          .width('100%')
          .height(40)
          .type(InputType.Password)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.resetConfirmPassword = value;
            this.resetPasswordError = '';
          })

        if (this.resetPasswordError) {
          Text(this.resetPasswordError)
            .fontSize(12)
            .fontColor('#ff4444')
            .margin({ top: 8 })
        }

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(ProfileTab.COLORS.background)
            .fontColor(ProfileTab.COLORS.text)
            .borderRadius(8)
            .onClick(() => {
              this.showResetPassword = false;
            })

          Button('重置密码')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(ProfileTab.COLORS.gold)
            .fontColor(ProfileTab.COLORS.background)
            .fontWeight(FontWeight.Medium)
            .borderRadius(8)
            .margin({ left: 16 })
            .onClick(() => {
              this.handleResetPassword();
            })
        }
        .width('100%')
        .margin({ top: 24 })
      }
    }
    .width('88%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(20)
    .padding(24)
    .onClick((event: ClickEvent) => {
      event.stopPropagation();
    })
  }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/ProfileTab.ets
git commit -m "feat(account): add all 5 account dialog builders"
```

---

### Task 9: 在 ProfileTab 中添加账号管理业务方法

**Files:**
- Modify: `entry/src/main/ets/pages/ProfileTab.ets`

- [ ] **Step 1: 在 `confirmDeleteApp()` 方法之后、文件末尾 `}` 之前，添加所有账号管理方法**

```typescript
  // ==================== 账号管理方法 ====================

  /**
   * 加载用户账号
   */
  private async loadAccount(): Promise<void> {
    try {
      const account = await this.stateManager.getUserAccount();
      this.currentAccount = account;
      if (account) {
        Logger.info('ProfileTab', `账号已加载: ${account.username}`);
      } else {
        Logger.info('ProfileTab', '尚未创建账号');
        this.showCreateAccount = true;
      }
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '加载账号失败');
    }
  }

  /**
   * 处理创建账号
   */
  private async handleCreateAccount(): Promise<void> {
    // 验证
    const usernameError = validateUsername(this.createUsername);
    if (usernameError) {
      this.createAccountError = usernameError;
      return;
    }

    const passwordError = validatePassword(this.createPassword);
    if (passwordError) {
      this.createAccountError = passwordError;
      return;
    }

    if (this.createPassword !== this.createConfirmPassword) {
      this.createAccountError = '两次输入的密码不一致';
      return;
    }

    try {
      const account = new UserAccount();
      account.username = this.createUsername.trim();
      account.avatar = this.createAvatar;
      account.passwordHash = await hashPassword(this.createPassword);
      account.createdAt = Date.now();
      account.updatedAt = Date.now();

      await this.stateManager.saveUserAccount(account);
      this.currentAccount = account;
      this.showCreateAccount = false;
      Logger.info('ProfileTab', `账号创建成功: ${account.username}`);
    } catch (error) {
      this.createAccountError = '创建账号失败，请重试';
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '创建账号失败');
    }
  }

  /**
   * 处理修改用户名
   */
  private async handleUpdateUsername(): Promise<void> {
    const error = validateUsername(this.editUsernameInput);
    if (error) {
      return;
    }

    try {
      if (!this.currentAccount) {
        return;
      }
      const account = this.currentAccount.clone();
      account.username = this.editUsernameInput.trim();
      await this.stateManager.saveUserAccount(account);
      this.currentAccount = account;
      this.showEditUsername = false;
      Logger.info('ProfileTab', `用户名已更新: ${account.username}`);
    } catch (err) {
      Logger.exception('ProfileTab', err instanceof Error ? err : new Error(String(err)), '修改用户名失败');
    }
  }

  /**
   * 处理修改头像
   */
  private async handleUpdateAvatar(avatar: string): Promise<void> {
    try {
      if (!this.currentAccount) {
        return;
      }
      const account = this.currentAccount.clone();
      account.avatar = avatar;
      await this.stateManager.saveUserAccount(account);
      this.currentAccount = account;
      Logger.info('ProfileTab', `头像已更新: ${avatar}`);
    } catch (err) {
      Logger.exception('ProfileTab', err instanceof Error ? err : new Error(String(err)), '修改头像失败');
    }
  }

  /**
   * 处理修改密码
   */
  private async handleChangePassword(): Promise<void> {
    if (!this.currentAccount) {
      return;
    }

    const passwordError = validatePassword(this.newPassword);
    if (passwordError) {
      this.changePasswordError = passwordError;
      return;
    }

    if (this.newPassword !== this.confirmNewPassword) {
      this.changePasswordError = '两次输入的密码不一致';
      return;
    }

    try {
      const oldMatch = await verifyPassword(this.oldPassword, this.currentAccount.passwordHash);
      if (!oldMatch) {
        this.changePasswordError = '旧密码不正确';
        return;
      }

      const account = this.currentAccount.clone();
      account.passwordHash = await hashPassword(this.newPassword);
      await this.stateManager.saveUserAccount(account);
      this.currentAccount = account;
      this.showChangePassword = false;
      Logger.info('ProfileTab', '密码已修改');
    } catch (err) {
      this.changePasswordError = '修改密码失败，请重试';
      Logger.exception('ProfileTab', err instanceof Error ? err : new Error(String(err)), '修改密码失败');
    }
  }

  /**
   * 处理系统锁屏验证
   */
  private handleSystemAuth(): void {
    try {
      const authInstance = userAuth.getUserAuthInstance({
        challenge: new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]),
        authType: [userAuth.UserAuthType.PIN, userAuth.UserAuthType.FINGERPRINT, userAuth.UserAuthType.FACE],
        trustLevel: userAuth.AuthTrustLevel.ATL3
      });

      authInstance.start();
      authInstance.on('result', (result: userAuth.UserAuthResult) => {
        try {
          if (result.result === userAuth.UserAuthResultCode.SUCCESS) {
            this.resetAuthPassed = true;
            Logger.info('ProfileTab', '系统锁屏验证通过');
          } else {
            Logger.warn('ProfileTab', `系统锁屏验证失败: ${result.result}`);
          }
        } finally {
          authInstance.off('result');
          authInstance.cancel();
        }
      });
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '系统锁屏验证失败');
    }
  }

  /**
   * 处理找回密码（重置密码）
   */
  private async handleResetPassword(): Promise<void> {
    const passwordError = validatePassword(this.resetPassword);
    if (passwordError) {
      this.resetPasswordError = passwordError;
      return;
    }

    if (this.resetPassword !== this.resetConfirmPassword) {
      this.resetPasswordError = '两次输入的密码不一致';
      return;
    }

    try {
      if (!this.currentAccount) {
        return;
      }
      const account = this.currentAccount.clone();
      account.passwordHash = await hashPassword(this.resetPassword);
      await this.stateManager.saveUserAccount(account);
      this.currentAccount = account;
      this.showResetPassword = false;
      Logger.info('ProfileTab', '密码已重置');
    } catch (err) {
      this.resetPasswordError = '重置密码失败，请重试';
      Logger.exception('ProfileTab', err instanceof Error ? err : new Error(String(err)), '重置密码失败');
    }
  }
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/pages/ProfileTab.ets
git commit -m "feat(account): add all account management business logic methods"
```

---

### Task 10: 构建验证

**Files:** 无修改

- [ ] **Step 1: 运行构建验证**

Run: `cd D:/GitHub/LanternLaw && hvigorw assembleHap --no-daemon` (或使用 DevEco Studio 构建)

Expected: 构建成功，无编译错误

- [ ] **Step 2: 如有编译错误，修复后重新构建**
