// entry/src/main/ets/pages/AccountModeSelectPage.ets

/**
 * 帐号模式选择页面
 * 创建帐号后选择家长/儿童模式
 */
import { AccountMode } from '../models/AccountMode';
import { UserAccount } from '../models/UserAccount';
import { AccountService } from '../services/AccountService';
import { hashPassword, validateUsername, validatePassword } from '../utils/PasswordHelper';
import { Logger } from '../utils/Logger';
import common from '@ohos.app.ability.common';

const TAG = 'AccountModeSelectPage';

interface PageColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

@Entry({ routeName: 'AccountModeSelectPage' })
@Component
struct AccountModeSelectPage {
  @State currentPage: string = 'create'; // 'create' | 'select'
  // 创建帐号表单
  @State createUsername: string = '';
  @State createAvatar: string = '😊';
  @State createPassword: string = '';
  @State createConfirmPassword: string = '';
  @State createAccountError: string = '';
  // 头像选择
  @State showAvatarPicker: boolean = false;
  @State selectedAvatar: string = '😊';
  // 加载状态
  @State isCreating: boolean = false;

  private accountService: AccountService = AccountService.getInstance();
  private readonly COLORS: PageColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)'
  };

  private readonly AVATAR_LIST: string[] = [
    '😊', '😄', '😎', '🤓', '😇', '🥳',
    '🦊', '🐱', '🐶', '🐼', '🦁', '🐯',
    '🌙', '⭐', '🔥', '💪', '🎯', '🏆',
    '🌸', '🍀', '🎨', '📚', '🧘', '💡'
  ];

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#0a0e1f', 0.0],
            ['#0f1529', 0.5],
            ['#1a1f3a', 1.0]
          ]
        })

      // 内容
      if (this.currentPage === 'create') {
        this.CreateAccountContent()
      } else {
        this.SelectModeContent()
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
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private CreateAccountContent(): void {
    Column() {
      // 顶部间距
      Column().height(80)

      // Logo 和标题
      Text('🏮')
        .fontSize(48)
        .margin({ bottom: 16 })

      Text('创建你的帐号')
        .fontSize(24)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text('开始你的灯律之旅')
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
        .margin({ bottom: 40 })

      // 创建表单
      Column() {
        // 头像选择
        Column()
          .width(72)
          .height(72)
          .borderRadius(36)
          .backgroundColor(this.COLORS.background)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ bottom: 24 })
          .onClick(() => {
            this.selectedAvatar = this.createAvatar;
            this.showAvatarPicker = true;
          }) {
          Text(this.createAvatar)
            .fontSize(36)
          Text('选择头像')
            .fontSize(10)
            .fontColor(this.COLORS.textDim)
        }

        // 用户名
        Text('用户名')
          .fontSize(14)
          .fontColor(this.COLORS.text)
          .width('100%')
          .margin({ bottom: 6 })
        TextInput({ placeholder: '请输入用户名', text: this.createUsername })
          .width('100%')
          .height(44)
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.createUsername = value;
            this.createAccountError = '';
          })

        // 密码
        Text('设置密码')
          .fontSize(14)
          .fontColor(this.COLORS.text)
          .width('100%')
          .margin({ top: 20, bottom: 6 })
        TextInput({ placeholder: '请设置密码(6-20位)', text: this.createPassword })
          .width('100%')
          .height(44)
          .type(InputType.Password)
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.createPassword = value;
            this.createAccountError = '';
          })

        // 确认密码
        Text('确认密码')
          .fontSize(14)
          .fontColor(this.COLORS.text)
          .width('100%')
          .margin({ top: 20, bottom: 6 })
        TextInput({ placeholder: '请再次输入密码', text: this.createConfirmPassword })
          .width('100%')
          .height(44)
          .type(InputType.Password)
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
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

        // 下一步按钮
        Button('下一步')
          .width('100%')
          .height(48)
          .backgroundColor(this.COLORS.gold)
          .fontColor(this.COLORS.background)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(12)
          .margin({ top: 32 })
          .enabled(!this.isCreating)
          .onClick(() => {
            this.handleCreateAccount();
          })
      }
      .width('85%')
      .padding(24)
      .backgroundColor(this.COLORS.card)
      .borderRadius(20)
      .border({ width: 1, color: this.COLORS.border })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20 })
  }

  @Builder
  private SelectModeContent(): void {
    Column() {
      // 顶部间距
      Column().height(80)

      Text(`你好，${this.createUsername}`)
        .fontSize(24)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text('请选择你的身份')
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
        .margin({ bottom: 40 })

      // 家长模式卡片
      Column() {
        Row() {
          Text('👨‍👩‍👧')
            .fontSize(32)
            .margin({ right: 16 })
          Column({ space: 6 }) {
            Text('家长模式')
              .fontSize(18)
              .fontColor(this.COLORS.gold)
              .fontWeight(FontWeight.Bold)
            Text('管理自己的灯律配置，也可以为儿童设置管控')
              .fontSize(13)
              .fontColor(this.COLORS.textDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(20)
      }
      .width('85%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(16)
      .border({ width: 1, color: this.COLORS.gold })
      .margin({ bottom: 20 })
      .hitTestBehavior(HitTestMode.Default)
      .onClick(() => {
        this.handleSelectMode(AccountMode.PARENT);
      })

      // 儿童模式卡片
      Column() {
        Row() {
          Text('👧')
            .fontSize(32)
            .margin({ right: 16 })
          Column({ space: 6 }) {
            Text('儿童模式')
              .fontSize(18)
              .fontColor(this.COLORS.orange)
              .fontWeight(FontWeight.Bold)
            Text('灯律由家长管理，你可以给家长发送消息')
              .fontSize(13)
              .fontColor(this.COLORS.textDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .padding(20)
      }
      .width('85%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(16)
      .border({ width: 1, color: this.COLORS.border })
      .margin({ bottom: 20 })
      .hitTestBehavior(HitTestMode.Default)
      .onClick(() => {
        this.handleSelectMode(AccountMode.CHILD);
      })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private AvatarPickerDialog(): void {
    Column() {
      Text('选择头像')
        .fontSize(18)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })

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
            color: this.COLORS.gold,
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
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showAvatarPicker = false;
          })

        Button('确认')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.COLORS.gold)
          .fontColor(this.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.createAvatar = this.selectedAvatar;
            this.showAvatarPicker = false;
          })
      }
      .width('100%')
    }
    .width('88%')
    .backgroundColor(this.COLORS.card)
    .borderRadius(20)
    .padding(24)
  }

  /**
   * 处理创建帐号
   */
  private async handleCreateAccount(): Promise<void> {
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

    this.isCreating = true;
    this.createAccountError = '';

    try {
      // 验证通过，跳转到模式选择页
      this.currentPage = 'select';
      Logger.info(TAG, '帐号信息验证通过，进入模式选择');
    } catch (error) {
      this.createAccountError = '创建帐号失败，请重试';
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '创建帐号失败');
    } finally {
      this.isCreating = false;
    }
  }

  /**
   * 处理选择模式
   */
  private async handleSelectMode(mode: AccountMode): Promise<void> {
    this.isCreating = true;
    try {
      await this.accountService.createAccount(
        this.createUsername.trim(),
        this.createAvatar,
        this.createPassword,
        mode
      );
      Logger.info(TAG, `帐号创建完成: ${this.createUsername} (${mode})`);

      // 根据模式跳转到不同页面
      const context = getContext(this) as common.UIAbilityContext;
      const targetPage = mode === AccountMode.CHILD ? 'JoinFamilyGroupPage' : 'MainPage';
      context.startAbility({
        bundleName: 'com.cloudchw.lanternlaw',
        abilityName: 'EntryAbility',
        parameters: {
          navigateTo: targetPage
        }
      });
    } catch (error) {
      this.createAccountError = '创建帐号失败，请重试';
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '选择模式后创建帐号失败');
      this.currentPage = 'create';
    } finally {
      this.isCreating = false;
    }
  }
}
