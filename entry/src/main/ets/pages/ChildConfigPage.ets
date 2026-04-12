import { Logger } from '../utils/Logger';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';
import { WhitelistApp } from '../models/WhitelistApp';
import { UserAccount } from '../models/UserAccount';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { AccountService } from '../services/AccountService';
import { ConfigSyncService } from '../services/ConfigSyncService';
import { verifyPassword, validatePassword } from '../utils/PasswordHelper';
import { router } from '@kit.ArkUI';

const TAG = 'ChildConfigPage';

interface ColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

const COLORS: ColorScheme = {
  background: '#0a0e1f',
  card: '#1a1f3a',
  gold: '#ffd166',
  orange: '#ff9e6d',
  text: '#e8e8f0',
  textDim: '#8888aa',
  accent: '#2a2f4a',
  border: '#2a2f4a'
};

@Entry
@Component
struct ChildConfigPage {
  @State childAccount: UserAccount | null = null;
  @State childConfig: LanternLawConfig = new LanternLawConfig();
  @State childEnabled: boolean = false;
  @State childTimeRanges: TimeRange[] = [];
  @State childWhitelistApps: WhitelistApp[] = [];
  @State isLoading: boolean = true;

  // 密码验证
  @State showPasswordDialog: boolean = false;
  @State passwordInput: string = '';
  @State passwordError: string = '';
  @State pendingAction: string = '';

  // 时间段编辑
  @State showTimePicker: boolean = false;
  @State editingTimeRange: TimeRange | null = null;
  @State newTimeRangeLabel: string = '';
  @State newStartTime: string = '22:00';
  @State newEndTime: string = '06:00';
  @State startHour: number = 22;
  @State startMinute: number = 0;
  @State endHour: number = 6;
  @State endMinute: number = 0;
  @State timePickerError: string = '';

  // 删除时间段
  @State showDeleteTimeRangeConfirm: boolean = false;
  @State deleteTimeRangeId: string = '';

  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private accountId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.accountId = params['accountId'] ?? '';
    this.loadChildData();
  }

  private async loadChildData(): Promise<void> {
    if (!this.accountId) {
      Logger.error(TAG, '缺少儿童 accountId');
      this.isLoading = false;
      return;
    }
    try {
      const accountService = AccountService.getInstance();
      this.childAccount = await accountService.getAccountById(this.accountId);
      if (!this.childAccount) {
        Logger.error(TAG, `未找到帐号: ${this.accountId}`);
        this.isLoading = false;
        return;
      }
      this.childConfig = await this.stateManager.getConfigForAccount(this.accountId);
      this.childEnabled = this.childConfig.lanternlawEnabled;
      this.childTimeRanges = this.childConfig.timeRanges ?? [];
      this.childWhitelistApps = this.childConfig.whitelistApps ?? [];
      Logger.info(TAG, `儿童配置加载完成: ${this.childAccount.username}, 启用=${this.childEnabled}, 时段=${this.childTimeRanges.length}`);
    } catch (error) {
      Logger.error(TAG, `加载儿童配置失败: ${JSON.stringify(error)}`);
    }
    this.isLoading = false;
  }

  private async saveChildConfig(): Promise<void> {
    this.childConfig.lanternlawEnabled = this.childEnabled;
    this.childConfig.timeRanges = this.childTimeRanges;
    this.childConfig.whitelistApps = this.childWhitelistApps;
    await this.stateManager.saveConfigForAccount(this.accountId, this.childConfig);

    // 同步到云端（家长配置儿童时）
    const syncService = ConfigSyncService.getInstance();
    if (syncService.getIsAvailable()) {
      syncService.uploadChildConfig(this.accountId, this.childConfig);
    }

    Logger.info(TAG, `儿童配置已保存: ${this.childAccount?.username}`);
  }

  private requestPassword(action: string): void {
    this.pendingAction = action;
    this.passwordInput = '';
    this.passwordError = '';
    this.showPasswordDialog = true;
  }

  private async handlePasswordVerify(): Promise<void> {
    const parentAccount = AccountService.getInstance().getActiveAccount();
    if (!parentAccount) {
      this.passwordError = '未找到家长帐号';
      return;
    }
    const pwdErr = validatePassword(this.passwordInput);
    if (pwdErr) {
      this.passwordError = pwdErr;
      return;
    }
    const match = await verifyPassword(this.passwordInput, parentAccount.passwordHash);
    if (!match) {
      this.passwordError = '密码不正确';
      return;
    }
    this.showPasswordDialog = false;

    switch (this.pendingAction) {
      case 'toggleSwitch':
        this.childEnabled = !this.childEnabled;
        await this.saveChildConfig();
        break;
      case 'addTimeRange':
        this.openTimePicker();
        break;
      case 'deleteTimeRange':
        this.showDeleteTimeRangeConfirm = true;
        break;
      case 'manageWhitelist':
        // Phase 4: 简化处理，跳过白名单选择（需要系统API）
        Logger.info(TAG, '管理白名单（Phase 4 暂不实现完整选择流程）');
        break;
    }
  }

  private openTimePicker(): void {
    this.editingTimeRange = null;
    this.newTimeRangeLabel = '';
    this.newStartTime = '22:00';
    this.newEndTime = '06:00';
    this.startHour = 22;
    this.startMinute = 0;
    this.endHour = 6;
    this.endMinute = 0;
    this.timePickerError = '';
    this.showTimePicker = true;
  }

  private openTimePickerEdit(range: TimeRange): void {
    this.editingTimeRange = range;
    this.newTimeRangeLabel = range.label;
    this.newStartTime = range.startTime;
    this.newEndTime = range.endTime;
    const startArr: string[] = range.startTime.split(':');
    this.startHour = startArr.length > 0 ? parseInt(startArr[0]) || 22 : 22;
    this.startMinute = startArr.length > 1 ? parseInt(startArr[1]) || 0 : 0;
    const endArr: string[] = range.endTime.split(':');
    this.endHour = endArr.length > 0 ? parseInt(endArr[0]) || 6 : 6;
    this.endMinute = endArr.length > 1 ? parseInt(endArr[1]) || 0 : 0;
    this.timePickerError = '';
    this.showTimePicker = true;
  }

  private closeTimePicker(): void {
    this.showTimePicker = false;
    this.editingTimeRange = null;
  }

  private saveTimeRange(): void {
    if (!this.newTimeRangeLabel) {
      this.timePickerError = '请输入标签';
      return;
    }
    const startTotal = this.startHour * 60 + this.startMinute;
    const endTotal = this.endHour * 60 + this.endMinute;
    if (startTotal === endTotal) {
      this.timePickerError = '开始和结束时间不能相同';
      return;
    }

    if (this.editingTimeRange) {
      const updated: TimeRange[] = [];
      for (const r of this.childTimeRanges) {
        if (r.id === this.editingTimeRange!.id) {
          updated.push({ id: r.id, label: this.newTimeRangeLabel, startTime: this.newStartTime, endTime: this.newEndTime, enabled: r.enabled });
        } else {
          updated.push({ id: r.id, label: r.label, startTime: r.startTime, endTime: r.endTime, enabled: r.enabled });
        }
      }
      this.childTimeRanges = updated;
    } else {
      const newId = `tr_${Date.now()}`;
      const updated: TimeRange[] = [];
      for (const r of this.childTimeRanges) {
        updated.push({ id: r.id, label: r.label, startTime: r.startTime, endTime: r.endTime, enabled: r.enabled });
      }
      updated.push({ id: newId, label: this.newTimeRangeLabel, startTime: this.newStartTime, endTime: this.newEndTime, enabled: true });
      this.childTimeRanges = updated;
    }
    this.closeTimePicker();
    this.saveChildConfig();
  }

  private confirmDeleteTimeRange(): void {
    const remaining: TimeRange[] = [];
    for (const r of this.childTimeRanges) {
      if (r.id !== this.deleteTimeRangeId) {
        remaining.push({ id: r.id, label: r.label, startTime: r.startTime, endTime: r.endTime, enabled: r.enabled });
      }
    }
    this.childTimeRanges = remaining;
    this.showDeleteTimeRangeConfirm = false;
    this.deleteTimeRangeId = '';
    this.saveChildConfig();
  }

  private goBack(): void {
    router.back();
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [COLORS.background, 0.0],
            ['#0f1529', 0.5],
            ['#1a1f3a', 1.0]
          ]
        })

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(COLORS.text)
            .onClick(() => {
              this.goBack();
            })
          Text(this.childAccount ? `管理 - ${this.childAccount.username}` : '管理儿童配置')
            .fontSize(18)
            .fontColor(COLORS.text)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        if (this.isLoading) {
          // 加载中
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor(COLORS.textDim)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (!this.childAccount) {
          Column() {
            Text('未找到儿童帐号')
              .fontSize(14)
              .fontColor(COLORS.textDim)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              // 儿童信息卡
              this.ChildInfoCard()
              // 全局开关
              this.GlobalSwitchCard()
              // 时间管理
              this.TimeManagementCard()
              // 白名单
              this.WhitelistCard()
            }
            .width('90%')
            .padding({ bottom: 100 })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollable(ScrollDirection.Vertical)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })

      // 密码对话框
      if (this.showPasswordDialog) {
        Column() {
          Column() {
            this.PasswordDialogBuilder()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showPasswordDialog = false;
        })
      }

      // 时间段选择器
      if (this.showTimePicker) {
        Column() {
          Column() {
            this.TimePickerDialogBuilder()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.closeTimePicker();
        })
      }

      // 删除确认
      if (this.showDeleteTimeRangeConfirm) {
        Column() {
          Column() {
            this.DeleteTimeRangeConfirmDialogBuilder()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDeleteTimeRangeConfirm = false;
          this.deleteTimeRangeId = '';
        })
      }
    }
    .height('100%')
  }

  @Builder
  private ChildInfoCard(): void {
    Column() {
      Row() {
        Text(this.childAccount?.avatar ?? '😊')
          .fontSize(40)
          .margin({ right: 16 })
        Column({ space: 4 }) {
          Text(this.childAccount?.username ?? '儿童帐号')
            .fontSize(18)
            .fontColor(COLORS.text)
            .fontWeight(FontWeight.Bold)
          Text('儿童模式')
            .fontSize(13)
            .fontColor(COLORS.gold)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: COLORS.border })
    .margin({ bottom: 16 })
  }

  @Builder
  private GlobalSwitchCard(): void {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(this.childEnabled ? '管控中' : '未管控')
            .fontSize(16)
            .fontColor(this.childEnabled ? COLORS.gold : COLORS.textDim)
            .fontWeight(FontWeight.Medium)
          Text(this.childEnabled ? '已为该儿童启用灯律保护' : '点击开关为该儿童启用管控')
            .fontSize(12)
            .fontColor(COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor(this.childEnabled ? COLORS.gold : COLORS.textDim)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          Text(this.childEnabled ? '✓' : '')
            .fontSize(14)
            .fontColor(COLORS.background)
            .fontWeight(FontWeight.Bold)
        }
        .width(50)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.childEnabled ? 'rgba(255, 209, 102, 0.2)' : 'rgba(192, 198, 233, 0.1)')
        .justifyContent(FlexAlign.End)
        .padding({ right: 2 })
        .onClick(() => {
          this.requestPassword('toggleSwitch');
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.childEnabled ? COLORS.gold : COLORS.border })
    .margin({ bottom: 16 })
  }

  @Builder
  private TimeManagementCard(): void {
    Column() {
      Row() {
        Text('⏰')
          .fontSize(18)
          .margin({ right: 12 })
        Text('时间管理')
          .fontSize(16)
          .fontColor(COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('+')
          .fontSize(24)
          .fontColor(COLORS.gold)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.requestPassword('addTimeRange');
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      if (this.childTimeRanges.length === 0) {
        Column() {
          Text('暂无时间段设置')
            .fontSize(13)
            .fontColor(COLORS.textDim)
            .margin({ top: 8, bottom: 8 })
          Text('点击右上角 + 为儿童添加灯律时间段')
            .fontSize(11)
            .fontColor(COLORS.textDim)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.childTimeRanges, (timeRange: TimeRange) => {
          Row() {
            Column({ space: 4 }) {
              Text(timeRange.label)
                .fontSize(14)
                .fontColor(timeRange.enabled ? COLORS.text : COLORS.textDim)
                .fontWeight(FontWeight.Medium)
              Text(TimeRangeManager.formatDisplay(timeRange))
                .fontSize(12)
                .fontColor(COLORS.textDim)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Blank()

            Text('删除')
              .fontSize(11)
              .fontColor('#ff6b6b')
              .onClick(() => {
                this.requestPassword('deleteTimeRange');
                this.deleteTimeRangeId = timeRange.id;
              })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.openTimePickerEdit(timeRange);
          })
        }, (timeRange: TimeRange) => `${timeRange.id}_${timeRange.startTime}_${timeRange.endTime}`)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: COLORS.border })
    .margin({ bottom: 16 })
  }

  @Builder
  private WhitelistCard(): void {
    Column() {
      Row() {
        Text('📱')
          .fontSize(18)
          .margin({ right: 12 })
        Text('白名单应用')
          .fontSize(16)
          .fontColor(COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('管理')
          .fontSize(12)
          .height(28)
          .backgroundColor(COLORS.accent)
          .fontColor(COLORS.gold)
          .borderRadius(14)
          .onClick(() => {
            this.requestPassword('manageWhitelist');
          })
      }
      .width('100%')
      .padding({ bottom: 12 })

      if (this.childWhitelistApps.length > 0) {
        Text(`管控时段内，${this.childWhitelistApps.length}个白名单应用可用`)
          .fontSize(13)
          .fontColor(COLORS.text)
      } else {
        Text('暂无白名单应用')
          .fontSize(13)
          .fontColor(COLORS.textDim)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: COLORS.border })
    .margin({ bottom: 16 })
  }

  private getPasswordDialogTitle(): string {
    if (this.pendingAction === 'toggleSwitch') {
      return this.childEnabled ? '确认停用' : '确认启用';
    } else if (this.pendingAction === 'addTimeRange') {
      return '添加时间段';
    } else if (this.pendingAction === 'deleteTimeRange') {
      return '删除时间段';
    } else if (this.pendingAction === 'manageWhitelist') {
      return '管理白名单';
    }
    return '密码验证';
  }

  @Builder
  private PasswordDialogBuilder(): void {
    Column() {
      Text(this.getPasswordDialogTitle())
        .fontSize(18)
        .fontColor(COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 16 })

      Text('请输入家长密码以继续操作')
        .fontSize(14)
        .fontColor(COLORS.textDim)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      TextInput({ placeholder: '请输入密码', text: this.passwordInput })
        .width('100%')
        .height(40)
        .type(InputType.Password)
        .backgroundColor(COLORS.background)
        .fontColor(COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.passwordInput = value;
          this.passwordError = '';
        })

      if (this.passwordError) {
        Text(this.passwordError)
          .fontSize(12)
          .fontColor('#ff4444')
          .margin({ top: 8 })
      }

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.background)
          .fontColor(COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showPasswordDialog = false;
          })

        Button('确认')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.gold)
          .fontColor(COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.handlePasswordVerify();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('70%')
    .backgroundColor(COLORS.card)
    .borderRadius(16)
    .padding(20)
  }

  @Builder
  private TimePickerDialogBuilder(): void {
    Column() {
      Text(this.editingTimeRange ? '编辑时间段' : '添加管控时间段')
        .fontSize(18)
        .fontColor(COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Row() {
        Text('标签')
          .fontSize(14)
          .fontColor(COLORS.text)
          .width(60)
        TextInput({ placeholder: '如: 夜间休息', text: this.newTimeRangeLabel })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(COLORS.background)
          .fontColor(COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.newTimeRangeLabel = value;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 24 })

      Row() {
        Column() {
          Text('开始时间')
            .fontSize(16)
            .fontColor(COLORS.text)
            .margin({ bottom: 8 })
          TimePicker({
            selected: new Date(1970, 0, 1, this.startHour, this.startMinute)
          })
            .useMilitaryTime(true)
            .selectedTextStyle({ color: COLORS.gold })
            .disappearTextStyle({ color: COLORS.textDim })
            .textStyle({ color: COLORS.text })
            .onChange((value: TimePickerResult) => {
              this.startHour = value.hour;
              this.startMinute = value.minute;
              this.newStartTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column()
          .width(1)
          .height(120)
          .backgroundColor(COLORS.border)
          .margin({ left: 12, right: 12 })

        Column() {
          Text('结束时间')
            .fontSize(16)
            .fontColor(COLORS.text)
            .margin({ bottom: 8 })
          TimePicker({
            selected: new Date(1970, 0, 1, this.endHour, this.endMinute)
          })
            .useMilitaryTime(true)
            .selectedTextStyle({ color: COLORS.gold })
            .disappearTextStyle({ color: COLORS.textDim })
            .textStyle({ color: COLORS.text })
            .onChange((value: TimePickerResult) => {
              this.endHour = value.hour;
              this.endMinute = value.minute;
              this.newEndTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      if (this.timePickerError) {
        Text(this.timePickerError)
          .fontSize(12)
          .fontColor(COLORS.orange)
          .margin({ top: 8, bottom: 8 })
      }

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.background)
          .fontColor(COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.closeTimePicker();
          })

        Button('确认')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(COLORS.gold)
          .fontColor(COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.saveTimeRange();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('88%')
    .backgroundColor(COLORS.card)
    .borderRadius(20)
    .padding(24)
  }

  @Builder
  private DeleteTimeRangeConfirmDialogBuilder(): void {
    Column() {
      Text('确认删除')
        .fontSize(18)
        .fontColor(COLORS.text)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Text('确定要删除这个时间段吗？')
        .fontSize(14)
        .fontColor(COLORS.textDim)
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(COLORS.background)
          .fontColor(COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showDeleteTimeRangeConfirm = false;
            this.deleteTimeRangeId = '';
          })

        Button('删除')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(COLORS.orange)
          .fontColor('#ffffff')
          .borderRadius(8)
          .onClick(() => {
            this.confirmDeleteTimeRange();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('70%')
    .backgroundColor(COLORS.card)
    .borderRadius(16)
    .padding(20)
  }
}
