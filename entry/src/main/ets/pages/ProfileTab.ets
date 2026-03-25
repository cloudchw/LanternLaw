/**
 * 我的 Tab - LanternLaw
 * 个人设置页面
 */
import { Logger } from '../utils/Logger';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';

interface ProfileColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

@Component
export struct ProfileTab {
  @State bedtime: string = '22:30';
  @State wakeupTime: string = '06:30';
  @State lanternlawEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;

  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private static readonly COLORS: ProfileColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)'
  };

  aboutToAppear() {
    Logger.info('ProfileTab', '我的 Tab 初始化');
    this.loadConfig();
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

      // 内容区域
      Column() {
        // 标题栏
        Row() {
          Text('我的设置')
            .fontSize(24)
            .fontColor(ProfileTab.COLORS.text)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        // 可滚动内容
        Scroll() {
          Column() {
            this.TimeManagementCard()
            this.WhitelistCard()
            this.NotificationCard()
            this.AboutCard()
          }
          .width('90%')
          .padding({ bottom: 100 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollable(ScrollDirection.Vertical)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 时间管理卡片
   */
  @Builder
  private TimeManagementCard(): void {
    Column() {
      Row() {
        Text('⏰')
          .fontSize(18)
          .margin({ right: 12 })
        Text('时间管理')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 睡觉时间
      this.TimeSettingRow('睡觉时间', this.bedtime, () => {
        this.showTimePicker('bedtime');
      })

      // 起床时间
      this.TimeSettingRow('起床时间', this.wakeupTime, () => {
        this.showTimePicker('wakeup');
      })

      // 灯律时长
      Row() {
        Column({ space: 4 }) {
          Text('灯律时长')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.text)
          Text('8 小时')
            .fontSize(12)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text('固定')
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.textDim)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .onClick(() => {
        Logger.info('ProfileTab', '点击灯律时长设置');
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 时间设置行
   */
  @Builder
  private TimeSettingRow(label: string, value: string, onClick: () => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.text)
      Blank()
      Row({ space: 8 }) {
        Text(value)
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.gold)
          .fontWeight(FontWeight.Medium)
        Text('›')
          .fontSize(20)
          .fontColor(ProfileTab.COLORS.textDim)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .onClick(onClick)
  }

  /**
   * 白名单卡片
   */
  @Builder
  private WhitelistCard(): void {
    Column() {
      Row() {
        Text('📱')
          .fontSize(18)
          .margin({ right: 12 })
        Text('白名单应用')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('+ 添加')
          .fontSize(12)
          .height(28)
          .backgroundColor(ProfileTab.COLORS.accent)
          .fontColor(ProfileTab.COLORS.gold)
          .borderRadius(14)
          .onClick(() => {
            Logger.info('ProfileTab', '点击添加白名单应用');
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 白名单列表
      this.WhitelistItem('电话', true)
      this.WhitelistItem('短信', true)
      this.WhitelistItem('相册', true)
      this.WhitelistItem('闹钟', false)

      Text('点击应用切换允许/禁止状态，长按删除')
        .fontSize(11)
        .fontColor(ProfileTab.COLORS.textDim)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 白名单应用项
   */
  @Builder
  private WhitelistItem(name: string, enabled: boolean): void {
    Row() {
      Text(name)
        .fontSize(14)
        .fontColor(enabled ? ProfileTab.COLORS.text : ProfileTab.COLORS.textDim)
        .decoration({ type: enabled ? TextDecorationType.None : TextDecorationType.LineThrough })
      Blank()
      Text(enabled ? '✓' : '✗')
        .fontSize(16)
        .fontColor(enabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
    }
    .width('100%')
    .padding({ top: 10, bottom: 10 })
    .onClick(() => {
      Logger.info('ProfileTab', `切换白名单应用: ${name}`);
    })
  }

  /**
   * 提醒设置卡片
   */
  @Builder
  private NotificationCard(): void {
    Column() {
      Row() {
        Text('🔔')
          .fontSize(18)
          .margin({ right: 12 })
        Text('提醒设置')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 睡前提醒
      this.SwitchItem('睡前提醒', '15 分钟', true)
      // 起床后提醒
      this.SwitchItem('起床后提醒', '自动', true)
      // 越狱通知
      this.SwitchItem('越狱通知', '即时', false)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 开关设置项
   */
  @Builder
  private SwitchItem(label: string, description: string, enabled: boolean): void {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
        Text(description)
          .fontSize(11)
          .fontColor(ProfileTab.COLORS.textDim)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 模拟开关
      Column()
        .width(44)
        .height(24)
        .backgroundColor(enabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
        .borderRadius(12)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 2 })
        .onClick(() => {
          Logger.info('ProfileTab', `切换开关: ${label}`);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  /**
   * 关于卡片
   */
  @Builder
  private AboutCard(): void {
    Column() {
      Row() {
        Text('ℹ️')
          .fontSize(18)
          .margin({ right: 12 })
        Text('关于')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      Column({ space: 12 }) {
        this.AboutItem('版本', 'v1.0.0')
        this.AboutItem('开发者', 'cloudchw')
        this.AboutItem('说明', 'LanternLaw - 掌灯人')
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

  /**
   * 关于信息项
   */
  @Builder
  private AboutItem(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(ProfileTab.COLORS.textDim)
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(ProfileTab.COLORS.text)
    }
    .width('100%')
  }

  /**
   * 加载配置
   */
  private loadConfig(): void {
    try {
      const config = this.stateManager.getConfig();
      this.bedtime = config.bedtime;
      this.wakeupTime = config.wakeupTime;
      this.lanternlawEnabled = config.lanternlawEnabled;
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '加载配置失败');
    }
  }

  /**
   * 显示时间选择器
   */
  private showTimePicker(type: string): void {
    Logger.info('ProfileTab', `显示时间选择器: ${type}`);
    // TODO: 实现时间选择器弹窗
  }
}
