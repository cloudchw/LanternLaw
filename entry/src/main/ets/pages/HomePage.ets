/**
 * 首页 Tab - LanternLaw
 * 携带底部导航栏的容器页面
 */
import { Logger } from '../utils/Logger';
import { ClockComponent } from '../components/ClockComponent';
import { MotivationText } from '../components/MotivationText';
import {
  LanternLawStateManager,
  LanternLawState
} from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { TimeRangeManager, TimeRange } from '../models/TimeRange';
import { DataStatisticsManager } from '../managers/DataStatisticsManager';
import { AchievementManager } from '../managers/AchievementManager';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import common from '@ohos.app.ability.common';

interface HomeColorScheme {
  background: string;
  backgroundLight: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  card: string;
}

@Component
export struct HomePage {
  // 状态管理
  @State currentTime: Date = new Date();
  @State lanternLawState: LanternLawState = LanternLawState.IDLE;
  @State currentStreak: number = 0;
  @State lanternlawEnabled: boolean = true;
  @State remainingTimeStr: string = '';

  // 管理器实例
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private statsManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 配色方案
  private readonly COLORS: HomeColorScheme = {
    background: '#0f1529',
    backgroundLight: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    card: 'rgba(15, 21, 41, 0.6)'
  };

  aboutToAppear() {
    this.startClockTimer();
    this.initializeManagers();
    this.startStateMonitorTimer();
    Logger.info('HomePage', '首页初始化完成');
  }

  build() {
    Stack() {
      this.BackgroundGradient()

      Column() {
        // 可滚动内容区域
        Scroll() {
          Column() {
            this.TitleSection()
            this.ClockSection()
            this.MotivationSection()

            // 倒计时区域
            if (this.lanternLawState === LanternLawState.ACTIVE) {
              Column() {
                Text('距离解锁还有')
                  .fontSize(14)
                  .fontColor('rgba(192, 198, 233, 0.7)')
                  .margin({ bottom: 8 })

                Text(this.remainingTimeStr)
                  .fontSize(36)
                  .fontColor('#ffd166')
                  .fontWeight(FontWeight.Bold)
                  .fontFamily('monospace')
                  .margin({ bottom: 4 })

                Text('灯律时段进行中')
                  .fontSize(12)
                  .fontColor('rgba(255, 209, 102, 0.6)')
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
            } else if (this.remainingTimeStr.length > 0) {
              Column() {
                Text(this.remainingTimeStr)
                  .fontSize(16)
                  .fontColor('rgba(192, 198, 233, 0.6)')
              }
              .width('100%')
              .padding({ top: 12 })
            }
          }
          .width('90%')
          .padding({ bottom: 20 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollable(ScrollDirection.Vertical)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .padding({ top: 40, bottom: 80 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private BackgroundGradient(): void {
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
  }

  @Builder
  private TitleSection(): void {
    Column() {
      Text('掌灯人')
        .fontSize(32)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(4)
        .margin({ bottom: 4 })
      Text(this.getTimeGreeting())
        .fontSize(13)
        .fontColor(this.COLORS.textDim)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 40 })
  }

  @Builder
  private ClockSection(): void {
    Column() {
      ClockComponent({
        currentTime: this.currentTime,
        isLanternLawActive: this.lanternLawState === LanternLawState.ACTIVE,
        remainingMinutes: this.getRemainingMinutes(),
        clockSize: 220
      })
        .margin({ bottom: 20 })

      // 日期时间显示
      Column() {
        Text(this.formatDateFull(this.currentTime))
          .fontSize(14)
          .fontColor(this.COLORS.text)
          .fontWeight(FontWeight.Medium)

        Text(`${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}:${this.currentTime.getSeconds().toString().padStart(2, '0')}`)
          .fontSize(28)
          .fontColor(this.COLORS.gold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(2)
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 32 })
  }

  @Builder
  private MotivationSection(): void {
    MotivationText({
      lanternLawState: this.lanternLawState,
      currentStreak: this.currentStreak,
      timeUntilWakeup: this.getRemainingMinutes(),
      animated: true
    })
  }

  private updateCountdown(config: LanternLawConfig): void {
    const now = this.currentTime;
    const nowMinutes = now.getHours() * 60 + now.getMinutes();
    const nowSeconds = now.getSeconds();
    const enabledRanges = config.timeRanges.filter((r: TimeRange) => r.enabled);

    if (this.lanternLawState === LanternLawState.ACTIVE) {
      // Find the first enabled timeRange that covers the current time
      for (const range of enabledRanges) {
        const startMin = TimeRangeManager.timeToMinutes(range.startTime);
        const endMin = TimeRangeManager.timeToMinutes(range.endTime);

        let inRange = false;
        if (endMin >= startMin) {
          // Normal range (e.g. 08:00-22:00)
          inRange = nowMinutes >= startMin && nowMinutes < endMin;
        } else {
          // Cross-midnight range (e.g. 22:00-06:00)
          inRange = nowMinutes >= startMin || nowMinutes < endMin;
        }

        if (inRange) {
          let remainingMin: number;
          if (endMin >= startMin) {
            remainingMin = endMin - nowMinutes;
          } else {
            // Cross-midnight: if after start, remaining = (1440 - nowMinutes) + endMin
            // if before end, remaining = endMin - nowMinutes
            if (nowMinutes >= startMin) {
              remainingMin = (1440 - nowMinutes) + endMin;
            } else {
              remainingMin = endMin - nowMinutes;
            }
          }
          // Subtract current seconds for precision
          const totalSeconds = remainingMin * 60 - nowSeconds;
          const hours = Math.floor(totalSeconds / 3600);
          const minutes = Math.floor((totalSeconds % 3600) / 60);
          const seconds = totalSeconds % 60;
          this.remainingTimeStr = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
          return;
        }
      }
      // If no matching range found (edge case), clear
      this.remainingTimeStr = '';
    } else {
      // IDLE state: calculate time until the next enabled timeRange starts
      let closestStartMin = -1;
      for (const range of enabledRanges) {
        const startMin = TimeRangeManager.timeToMinutes(range.startTime);
        // How many minutes until this range starts from now?
        let diff = startMin - nowMinutes;
        if (diff <= 0) {
          // It starts tomorrow (add 24h)
          diff = diff + 1440;
        }
        if (closestStartMin === -1 || diff < closestStartMin) {
          closestStartMin = diff;
        }
      }

      if (closestStartMin > 0) {
        // Subtract seconds for precision
        const adjustedMin = closestStartMin - 1;
        const totalSeconds = adjustedMin * 60 + (60 - nowSeconds);
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        if (hours > 0) {
          this.remainingTimeStr = `${hours}小时${minutes.toString().padStart(2, '0')}分后开始`;
        } else {
          this.remainingTimeStr = `${minutes}分钟后开始`;
        }
      } else {
        this.remainingTimeStr = '';
      }
    }
  }

  private showStopDialog(): void {
    Logger.info('HomePage', '显示停止灯律对话框');
    // TODO: 实现停止灯律确认对话框
  }

  private showRecoveryDialog(): void {
    Logger.info('HomePage', '显示恢复灯律对话框');
    // TODO: 实现恢复灯律确认对话框
  }

  private navigateToSettings(): void {
    Logger.info('HomePage', '导航到设置页面');
    // TODO: 实现导航到设置页面
  }

  private startClockTimer(): void {
    setInterval(() => {
      this.currentTime = new Date();
      this.updateCountdown(this.stateManager.getConfig());
    }, 1000);
  }

  private startStateMonitorTimer(): void {
    setInterval(async () => {
      await this.updateStatus();
    }, 60000);
  }

  private async initializeManagers(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      // 初始化状态管理器（会自动初始化数据库并加载配置，包括 timeRanges）
      await this.stateManager.initialize(ctx);
      await this.statsManager.initialize();
      await this.achievementManager.initialize();
      await this.updateStatus();
      Logger.info('HomePage', '管理器初始化完成');
    } catch (error) {
      Logger.exception('HomePage', error instanceof Error ? error : new Error(String(error)), '管理器初始化失败');
    }
  }

  private async updateStatus(): Promise<void> {
    if (!this.database.isInitialized()) {
      return;
    }
    try {
      this.lanternLawState = this.stateManager.getCurrentState();
      const config = this.stateManager.getConfig();
      this.lanternlawEnabled = config.lanternlawEnabled;

      const stats = await this.statsManager.getOverallStatistics(7);
      this.currentStreak = stats.consecutiveSuccessDays;

      // 更新倒计时
      this.updateCountdown(config);
    } catch (error) {
      Logger.exception('HomePage', error instanceof Error ? error : new Error(String(error)), '状态更新失败');
    }
  }

  private isAccessibilityServiceEnabled(): boolean {
    return true;
  }

  private openAccessibilitySettings(): void {
    Logger.info('HomePage', '打开无障碍设置');
  }

  private getRemainingMinutes(): number {
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

  private getTimeGreeting(): string {
    const hour = this.currentTime.getHours();
    if (hour >= 5 && hour < 12) {
      return '清晨，新的一天';
    } else if (hour >= 12 && hour < 18) {
      return '下午，持续专注';
    } else if (hour >= 18 && hour < 23) {
      return '夜晚，点亮人生';
    } else {
      return '深夜，安息时光';
    }
  }

  private formatDateFull(date: Date): string {
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];
    return `${date.getMonth() + 1}月${date.getDate()}日 ${weekdays[date.getDay()]}`;
  }
}
