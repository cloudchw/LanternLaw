/**
 * 设置页面 - LanternLaw
 * Settings Page
 * 提供灯律时间配置和行为设置
 */
import { Logger } from '../utils/Logger';
import router from '@ohos.router';
import {
  LanternLawStateManager,
  LanternLawState,
  LanternLawConfigUpdate
} from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { DataStatisticsManager } from '../managers/DataStatisticsManager';
import { AchievementManager } from '../managers/AchievementManager';

interface SettingsColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

@Entry
@Component
struct SettingsPage {
  // 状态
  @State bedtime: string = '22:30';
  @State wakeupTime: string = '06:30';
  @State lanternlawEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;
  @State soundEnabled: boolean = false;
  @State remainingEmergencies: number = 3;
  @State remainingTime: number = 0;

  // 管理器
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private statsManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();

  // 配色方案
  private readonly COLORS: SettingsColorScheme = {
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
    this.loadSettings();
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavigationBar()

      Scroll() {
        Column() {
          // 灯律状态卡片
          this.StatusCard()

          // 时间配置区域
          this.TimeConfigurationSection()

          // 行为配置区域
          this.BehaviorConfigurationSection()

          // 统计信息区域
          this.StatisticsSection()

          // 关于区域
          this.AboutSection()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.COLORS.background)
  }

  /**
   * 顶部导航栏
   */
  @Builder
  private TopNavigationBar(): void {
    Row() {
      // 返回按钮
      Button() {
        Text('←')
          .fontSize(24)
          .fontColor(this.COLORS.text)
      }
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.navigateBack();
      })

      Blank()

      // 标题
      Text('设置')
        .fontSize(18)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)

      Blank()

      // 空占位符（对称布局）
      Button()
        .type(ButtonType.Normal)
        .backgroundColor(Color.Transparent)
        .width(40)
        .height(40)
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.COLORS.background)
  }

  /**
   * 灯律状态卡片
   */
  @Builder
  private StatusCard(): void {
    Row() {
      Column() {
        Text('灯律状态')
          .fontSize(14)
          .fontColor(this.COLORS.textDim)
          .margin({ bottom: 4 })

        Text(this.getStatusText())
          .fontSize(24)
          .fontColor(this.getStatusColor())
          .fontWeight(FontWeight.Bold)

        if (this.stateManager.getCurrentState() === LanternLawState.ACTIVE && this.remainingTime > 0) {
          Text(`${this.formatMinutesToTime(this.remainingTime)}后解锁`)
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 状态指示器
      Circle()
        .width(8)
        .height(8)
        .fill(this.getStatusColor())
        .shadow({
          radius: 8,
          color: this.getStatusColor()
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({
      width: 1,
      color: this.COLORS.border
    })
    .margin({ bottom: 16 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 时间配置区域
   */
  @Builder
  private TimeConfigurationSection(): void {
    Column() {
      Text('时间配置')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        // 就寝时间
        this.TimeSettingRow(
          '就寝时间',
          this.bedtime,
          () => {
            this.showBedtimeSelector();
          }
        )

        // 解锁时间
        this.TimeSettingRow(
          '解锁时间',
          this.wakeupTime,
          () => {
            this.showWakeTimeSelector();
          }
        )

        // 启用开关
        Row() {
          Row() {
            Text('启用灯律')
              .fontSize(15)
              .fontColor(this.COLORS.text)

            Text('开启后将按设定时间执行')
              .fontSize(12)
              .fontColor(this.COLORS.textDim)
              .margin({ left: 8 })
          }
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.lanternlawEnabled })
            .selectedColor(this.COLORS.gold)
            .onChange((isOn: boolean) => {
              this.lanternlawEnabled = isOn;
              this.saveSettings();
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .alignItems(VerticalAlign.Center)

        // 底边框
        Column()
          .width('100%')
          .height(1)
          .backgroundColor(this.COLORS.border)
          .margin({ top: 12 })
      }
      .width('100%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(12)
      .padding(16)
      .border({
        width: 1,
        color: this.COLORS.border
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 时间设置行
   */
  @Builder
  private TimeSettingRow(label: string, value: string, callback: () => void): void {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor(this.COLORS.text)

        Blank()

        Text(value)
          .fontSize(15)
          .fontColor(this.COLORS.gold)
          .fontWeight(FontWeight.Medium)
          .margin({ right: 8 })

        Text('→')
          .fontSize(16)
          .fontColor(this.COLORS.textDim)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })
      .onClick(callback)
      .alignItems(VerticalAlign.Center)

      // 底边框
      Column()
        .width('100%')
        .height(1)
        .backgroundColor(this.COLORS.border)
        .margin({ top: 12 })
    }
    .width('100%')
  }

  /**
   * 行为配置区域
   */
  @Builder
  private BehaviorConfigurationSection(): void {
    Column() {
      Text('行为配置')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        // 振动提示
        this.ToggleRow('越狱时震动提示', this.vibrationEnabled, (isOn: boolean) => {
          this.vibrationEnabled = isOn;
          this.saveSettings();
        })

        // 声音提示
        this.ToggleRow('越狱时声音提示', this.soundEnabled, (isOn: boolean) => {
          this.soundEnabled = isOn;
          this.saveSettings();
        })
      }
      .width('100%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(12)
      .padding(16)
      .border({
        width: 1,
        color: this.COLORS.border
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 开关行
   */
  @Builder
  private ToggleRow(label: string, isOn: boolean, callback: (isOn: boolean) => void): void {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.COLORS.text)

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.COLORS.gold)
        .onChange(callback)
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 统计信息区域
   */
  @Builder
  private StatisticsSection(): void {
    Column() {
      Text('使用统计')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        // 紧急解锁次数
        this.StatisticRow('紧急解锁', `${this.remainingEmergencies} 次`, true)

        // 连续成功天数
        this.StatisticRow('连续成功', `${this.currentStreak} 天`, false)

        // 总体成功率
        this.StatisticRow('成功率', `${this.successRate}%`, false)
      }
      .width('100%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(12)
      .padding(16)
      .border({
        width: 1,
        color: this.COLORS.border
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 统计行
   */
  @Builder
  private StatisticRow(label: string, value: string, hasAction: boolean): void {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.COLORS.text)

      Blank()

      Text(value)
        .fontSize(15)
        .fontColor(hasAction ? this.COLORS.orange : this.COLORS.gold)
        .fontWeight(FontWeight.Medium)

      if (hasAction) {
        Button('重置')
          .type(ButtonType.Normal)
          .fontSize(12)
          .height(28)
          .backgroundColor(this.COLORS.accent)
          .fontColor(this.COLORS.textDim)
          .borderRadius(14)
          .margin({ left: 8 })
          .onClick(() => {
            this.resetEmergencyCount();
          })
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 关于区域
   */
  @Builder
  private AboutSection(): void {
    Column() {
      Text('关于')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        // 应用信息
        Column() {
          Text('LanternLaw - 提灯')
            .fontSize(18)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Bold)

          Text('灯律 v1.0.0')
            .fontSize(13)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 4 })

          Text('每一次坚持，都是星光')
            .fontSize(12)
            .fontColor(this.COLORS.text)
            .margin({ top: 8 })
            .fontStyle(FontStyle.Italic)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding(20)
      }
      .width('100%')
      .backgroundColor(this.COLORS.card)
      .borderRadius(12)
      .border({
        width: 1,
        color: this.COLORS.border
      })
    }
    .width('100%')
    .margin({ bottom: 32 })
  }

  /**
   * 加载设置
   */
  private async loadSettings(): Promise<void> {
    try {
      const config = this.stateManager.getConfig();
      this.bedtime = config.bedtime;
      this.wakeupTime = config.wakeupTime;
      this.lanternlawEnabled = config.lanternlawEnabled;

      // 获取剩余紧急解锁次数
      this.remainingEmergencies = config.emergencyUnlocks - config.emergencyUsed;

      // 获取剩余时间
      if (this.stateManager.getCurrentState() === LanternLawState.ACTIVE) {
        this.remainingTime = this.calculateRemainingTime();
      }

      Logger.info('SettingsPage', '设置加载完成');
    } catch (error) {
      Logger.exception('SettingsPage', error as Error, '设置加载失败');
    }
  }

  /**
   * 保存设置
   */
  private async saveSettings(): Promise<void> {
    try {
      const update: LanternLawConfigUpdate = {
        bedtime: this.bedtime,
        wakeupTime: this.wakeupTime,
        lanternlawEnabled: this.lanternlawEnabled
      };
      await this.stateManager.updateConfig(update);
      Logger.info('SettingsPage', '设置保存完成');
    } catch (error) {
      Logger.exception('SettingsPage', error as Error, '设置保存失败');
    }
  }

  /**
   * 显示就寝时间选择器
   */
  private showBedtimeSelector(): void {
    Logger.info('SettingsPage', '显示就寝时间选择器');
    // TODO: 实现时间选择器对话框
  }

  /**
   * 显示起床时间选择器
   */
  private showWakeTimeSelector(): void {
    Logger.info('SettingsPage', '显示起床时间选择器');
    // TODO: 实现时间选择器对话框
  }

  /**
   * 重置紧急解锁次数
   */
  private async resetEmergencyCount(): Promise<void> {
    try {
      this.remainingEmergencies = 3;
      Logger.info('SettingsPage', '紧急解锁次数重置');
      // TODO: 显示确认消息
    } catch (error) {
      Logger.exception('SettingsPage', error as Error, '重置紧急解锁失败');
    }
  }

  /**
   * 计算剩余时间
   */
  private calculateRemainingTime(): number {
    const config = this.stateManager.getConfig();
    const now = new Date();
    const wakeupHour = parseInt(config.wakeupTime.split(':')[0]);
    const wakeupMinute = parseInt(config.wakeupTime.split(':')[1]);

    let wakeupTime = new Date();
    wakeupTime.setHours(wakeupHour, wakeupMinute, 0, 0);

    if (now > wakeupTime) {
      wakeupTime.setDate(wakeupTime.getDate() + 1);
    }

    return Math.floor((wakeupTime.getTime() - now.getTime()) / (1000 * 60));
  }

  /**
   * 格式化分钟数为时分
   */
  private formatMinutesToTime(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    if (hours > 0) {
      return `${hours}小时${mins > 0 ? mins + '分' : ''}`;
    }
    return `${mins}分钟`;
  }

  /**
   * 获取状态文本
   */
  private getStatusText(): string {
    const state = this.stateManager.getCurrentState();
    switch (state) {
      case LanternLawState.ACTIVE:
        return '执行中';
      case LanternLawState.OVERRIDDEN:
        return '已越狱';
      default:
        return '未激活';
    }
  }

  /**
   * 获取状态颜色
   */
  private getStatusColor(): string {
    const state = this.stateManager.getCurrentState();
    switch (state) {
      case LanternLawState.ACTIVE:
        return this.COLORS.gold;
      case LanternLawState.OVERRIDDEN:
        return this.COLORS.orange;
      default:
        return this.COLORS.textDim;
    }
  }

  /**
   * 导航返回
   */
  private navigateBack(): void {
    try {
      router.back();
    } catch (error) {
      Logger.exception('SettingsPage', error as Error, '导航返回失败');
    }
  }

  /**
   * 获取连续天数
   */
  get currentStreak(): number {
    // TODO: 实现实际的连续天数获取
    return 0;
  }

  /**
   * 获取成功率
   */
  get successRate(): number {
    // TODO: 实现实际的成功率获取
    return 0;
  }
}