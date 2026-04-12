// entry/src/main/ets/pages/WaitingForApprovalPage.ets

/**
 * 等待家长确认页面
 * 儿童提交加入沟通组请求后，轮询数据库等待家长操作
 */
import { AccountService } from '../services/AccountService';
import { ConfigSyncService } from '../services/ConfigSyncService';
import { Logger } from '../utils/Logger';
import router from '@ohos.router';

const TAG = 'WaitingForApprovalPage';

@Entry({ routeName: 'WaitingForApprovalPage' })
@Component
struct WaitingForApprovalPage {
  @State statusText: string = '等待家长确认中...';
  @State isRejected: boolean = false;
  @State pollCount: number = 0;
  private pollTimerId: number = -1;
  private readonly MAX_POLL_COUNT: number = 100; // ~5分钟 (100 * 3s)
  private readonly POLL_INTERVAL_MS: number = 3000;

  async aboutToAppear(): Promise<void> {
    // 立即检查一次当前状态
    await this.checkStatus();

    // 启动轮询
    this.pollTimerId = setInterval(async () => {
      await this.checkStatus();
    }, this.POLL_INTERVAL_MS);
  }

  aboutToDisappear(): void {
    if (this.pollTimerId !== -1) {
      clearInterval(this.pollTimerId);
      this.pollTimerId = -1;
    }
  }

  private async checkStatus(): Promise<void> {
    this.pollCount++;
    if (this.pollCount > this.MAX_POLL_COUNT) {
      clearInterval(this.pollTimerId);
      this.pollTimerId = -1;
      this.statusText = '等待超时，请稍后重试';
      return;
    }

    try {
      const accountService = AccountService.getInstance();
      await accountService.reloadActiveAccount();
      let account = accountService.getActiveAccount();
      if (!account) {
        return;
      }

      // 本地状态仍是 pending 时，从云端查询最新状态
      if (account.joinStatus === 'pending') {
        const syncService = ConfigSyncService.getInstance();
        if (syncService.getIsAvailable()) {
          const cloudAccount = await syncService.queryAccount(account.accountId);
          if (cloudAccount && cloudAccount.joinStatus !== 'pending') {
            // 云端状态已变更，同步到本地
            account.joinStatus = cloudAccount.joinStatus;
            account.familyGroupId = cloudAccount.familyGroupId;
            account.parentAccountId = cloudAccount.parentAccountId;
            account.pendingGroupId = cloudAccount.pendingGroupId;
            account.pendingRequestedAt = cloudAccount.pendingRequestedAt;
            await accountService.saveActiveAccount();
            Logger.info(TAG, `从云端同步到最新状态: ${cloudAccount.joinStatus}`);
          }
        }
      }

      if (!account) {
        return;
      }

      if (account.joinStatus === 'approved') {
        // 家长已同意，跳转主页
        clearInterval(this.pollTimerId);
        this.pollTimerId = -1;
        Logger.info(TAG, '家长已同意加入，跳转主页');
        router.replaceUrl({ url: 'pages/MainPage' });
      } else if (account.joinStatus === 'rejected') {
        // 家长已拒绝
        clearInterval(this.pollTimerId);
        this.pollTimerId = -1;
        this.isRejected = true;
        this.statusText = '家长已拒绝你的加入请求';
        Logger.info(TAG, '家长已拒绝加入请求');
      } else if (account.joinStatus === 'pending') {
        // 计算已等待时间
        const elapsed = Date.now() - account.pendingRequestedAt;
        const minutes = Math.floor(elapsed / 60000);
        if (minutes > 0) {
          this.statusText = `等待家长确认中（已等待 ${minutes} 分钟）...`;
        }
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '检查状态失败');
    }
  }

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

      Column() {
        Column().height(120)

        // 等待动画图标
        Text('⏳')
          .fontSize(64)
          .margin({ bottom: 24 })

        if (this.isRejected) {
          Text('😊')
            .fontSize(64)
            .margin({ bottom: 24 })

          Text('加入请求被拒绝')
            .fontSize(22)
            .fontColor('#ff6b6b')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })

          Text(this.statusText)
            .fontSize(14)
            .fontColor('rgba(192, 198, 233, 0.6)')
            .margin({ bottom: 40 })
        } else {
          Text(this.statusText)
            .fontSize(22)
            .fontColor('#ffd166')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })

          Text('请将手机交给家长，等待家长在沟通组中确认')
            .fontSize(14)
            .fontColor('rgba(192, 198, 233, 0.6)')
            .margin({ bottom: 40 })
        }

        // 返回首页按钮
        Button('返回首页')
          .width('60%')
          .height(48)
          .backgroundColor('rgba(255, 209, 102, 0.15)')
          .fontColor('#ffd166')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .border({ width: 1, color: 'rgba(255, 209, 102, 0.3)' })
          .onClick(() => {
            if (this.pollTimerId !== -1) {
              clearInterval(this.pollTimerId);
              this.pollTimerId = -1;
            }
            router.replaceUrl({ url: 'pages/MainPage' });
          })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
