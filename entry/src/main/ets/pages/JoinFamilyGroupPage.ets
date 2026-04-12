// entry/src/main/ets/pages/JoinFamilyGroupPage.ets

/**
 * 加入沟通组页面
 * 儿童通过输入家长提供的邀请码加入沟通组
 * 提交后进入等待家长确认流程
 */
import { FamilyGroupService } from '../services/FamilyGroupService';
import { AccountService } from '../services/AccountService';
import { Logger } from '../utils/Logger';
import { router } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';

const TAG = 'JoinFamilyGroupPage';

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

@Entry({ routeName: 'JoinFamilyGroupPage' })
@Component
struct JoinFamilyGroupPage {
  @State invitationCode: string = '';
  @State errorText: string = '';
  @State isJoining: boolean = false;

  private familyGroupService: FamilyGroupService = FamilyGroupService.getInstance();
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

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#0a0e1f', 0.0], ['#0f1529', 0.5], ['#1a1f3a', 1.0]]
        })

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(this.COLORS.text)
            .margin({ right: 16 })
            .onClick(() => {
              this.goToMainPage();
            })
          Text('加入沟通组')
            .fontSize(20)
            .fontColor(this.COLORS.text)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        this.JoinFormContent()
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private JoinFormContent(): void {
    Scroll() {
      Column() {
        Column() {
          Text('🎉')
            .fontSize(48)
            .margin({ bottom: 16 })

          Text('输入家长的邀请码')
            .fontSize(18)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })

          Text('请向家长索取6位邀请码，输入后等待家长确认即可加入')
            .fontSize(14)
            .fontColor(this.COLORS.textDim)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 40 })

          // 邀请码输入
          Text('邀请码')
            .fontSize(14)
            .fontColor(this.COLORS.text)
            .width('100%')
            .margin({ bottom: 6 })

          TextInput({ placeholder: '请输入6位邀请码', text: this.invitationCode })
            .width('100%')
            .height(48)
            .backgroundColor(this.COLORS.background)
            .fontColor(this.COLORS.gold)
            .fontSize(20)
            .textAlign(TextAlign.Center)
            .letterSpacing(8)
            .borderRadius(8)
            .maxLength(6)
            .onChange((value: string) => {
              this.invitationCode = value.toUpperCase();
              this.errorText = '';
            })

          if (this.errorText) {
            Text(this.errorText)
              .fontSize(12)
              .fontColor('#ff4444')
              .margin({ top: 8 })
          }

          Button('提交申请')
            .width('100%')
            .height(48)
            .backgroundColor(this.COLORS.gold)
            .fontColor(this.COLORS.background)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .borderRadius(12)
            .margin({ top: 32 })
            .enabled(!this.isJoining)
            .onClick(() => {
              this.handleJoin();
            })

          // 稍后再说按钮
          Text('稍后再说')
            .fontSize(14)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 24 })
            .onClick(() => {
              this.goToMainPage();
            })

          Text('邀请码24小时内有效，过期后家长需要刷新')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 16 })
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        .width('85%')
        .padding(32)
        .backgroundColor(this.COLORS.card)
        .borderRadius(20)
        .border({ width: 1, color: this.COLORS.border })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .layoutWeight(1)
    .width('100%')
    .scrollable(ScrollDirection.Vertical)
  }

  private async handleJoin(): Promise<void> {
    if (!this.invitationCode || this.invitationCode.length !== 6) {
      this.errorText = '请输入6位邀请码';
      return;
    }
    this.isJoining = true;
    this.errorText = '';

    try {
      const accountService = AccountService.getInstance();
      const accountId = accountService.getActiveAccountId();
      if (!accountId) {
        this.errorText = '帐号未登录';
        return;
      }

      const result = await this.familyGroupService.requestJoinByInvitationCode(
        accountId, this.invitationCode
      );

      if (!result.success) {
        this.errorText = result.reason;
        return;
      }

      // 更新本地活跃帐号状态
      const account = accountService.getActiveAccount();
      if (account) {
        account.joinStatus = 'pending';
        account.pendingGroupId = result.group?.groupId ?? '';
        await accountService.saveActiveAccount();
      }

      Logger.info(TAG, `加入请求已提交，跳转到等待确认页`);
      // 跳转到等待确认页
      const context = getContext(this) as common.UIAbilityContext;
      context.startAbility({
        bundleName: 'com.cloudchw.lanternlaw',
        abilityName: 'EntryAbility',
        parameters: {
          navigateTo: 'WaitingForApprovalPage'
        }
      });
    } catch (error) {
      this.errorText = '提交失败，请重试';
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '提交加入请求失败');
    } finally {
      this.isJoining = false;
    }
  }

  private goToMainPage(): void {
    router.replaceUrl({ url: 'pages/MainPage' });
  }
}
