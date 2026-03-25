/**
 * 首页 Tab - LanternLaw
 * 携带底部导航栏的容器页面
 */
import { Logger } from '../utils/Logger';
import { ClockComponent } from '../components/ClockComponent';
import { LanternSystem } from '../components/LanternSystem';
import { TimeDisplay } from '../components/TimeDisplay';
import { MotivationText } from '../components/MotivationText';
import { StatsPanel } from '../components/StatsPanel';
import {
  LanternLawStateManager,
  LanternLawState
} from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';
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
  @State isStatsExpanded: boolean = false;
  @State currentStreak: number = 0;
  @State successRate: number = 0;
  @State todayDuration: number = 0;
  @State todaySuccess: boolean = false;
  @State weeklyTrends: number[] = [];
  @State successDays: number = 0;

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
        this.TopStatusBar()

        // 可滚动内容区域
        Scroll() {
          Column() {
            this.TitleSection()
            this.ClockSection()
            this.LanternSection()
            this.MotivationSection()
            this.StatisticsSection()
            this.ActionButtons()
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
  private TopStatusBar(): void {
    Row() {
      Text('掌灯人')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Bold)
      Blank()
      Text(`${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}`)
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 8 })
  }

  @Builder
  private TitleSection(): void {
    Column() {
      Text('灯律')
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
  private LanternSection(): void {
    Column() {
      // 本周连续天数卡片
      Row() {
        Text('本周连续')
          .fontSize(14)
          .fontColor(this.COLORS.textDim)

        Blank()

        Row() {
          Text(this.currentStreak.toString())
            .fontSize(28)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Bold)

          Text(' 天')
            .fontSize(14)
            .fontColor(this.COLORS.text)
            .margin({ left: 4 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .backgroundColor('rgba(26, 31, 58, 0.6)')
      .borderRadius(16)

      // 进度条
      Progress({ value: this.successRate, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.COLORS.gold)
        .backgroundColor(this.COLORS.backgroundLight)
        .margin({ top: 12 })
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
    .margin({ bottom: 28 })
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

  @Builder
  private StatisticsSection(): void {
    StatsPanel({
      isExpanded: this.isStatsExpanded,
      todayDuration: this.todayDuration,
      todaySuccess: this.todaySuccess,
      weeklyTrends: this.weeklyTrends,
      onToggle: () => {
        this.toggleStatsPanel();
      }
    })
      .margin({ bottom: 24 })
  }

  @Builder
  private ActionButtons(): void {
    Column() {
      if (!this.isAccessibilityServiceEnabled()) {
        Row() {
          Column() {
            Text('⚠️ 无障碍服务未启用')
              .fontSize(13)
              .fontColor(this.COLORS.orange)
              .fontWeight(FontWeight.Medium)
            Text('越狱检测功能将无法正常工作')
              .fontSize(11)
              .fontColor(this.COLORS.textDim)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Button('启用服务')
            .fontSize(12)
            .height(32)
            .backgroundColor(this.COLORS.accent)
            .fontColor(this.COLORS.gold)
            .borderRadius(16)
            .margin({ left: 12 })
            .onClick(() => {
              this.openAccessibilitySettings();
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('rgba(255, 158, 109, 0.1)')
        .borderRadius(12)
        .margin({ bottom: 16 })
      }

      Row() {
        Button('启用灯律')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(this.COLORS.gold)
          .fontColor(this.COLORS.background)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(24)
          .margin({ right: 12 })

        Button('设置时间')
          .layoutWeight(1)
          .height(48)
          .backgroundColor(this.COLORS.accent)
          .fontColor(this.COLORS.gold)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(24)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20 })
  }

  private startClockTimer(): void {
    setInterval(() => {
      this.currentTime = new Date();
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
      await this.database.initialize(ctx);
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
      const stats = await this.statsManager.getOverallStatistics(7);
      this.currentStreak = stats.consecutiveSuccessDays;
      this.successRate = stats.successRate;

      const trends = await this.statsManager.getWeeklyTrends();
      this.weeklyTrends = trends.map(t => t.duration);

      const recentRecords = await this.statsManager.getOverallStatistics(1);
      if (recentRecords.totalDays > 0) {
        this.todayDuration = recentRecords.averageDuration;
        this.todaySuccess = recentRecords.successRate > 0;
      }

      const lanternProgress = this.achievementManager.getLanternProgress();
      this.successDays = lanternProgress.current;
    } catch (error) {
      Logger.exception('HomePage', error instanceof Error ? error : new Error(String(error)), '状态更新失败');
    }
  }

  private toggleStatsPanel(): void {
    this.isStatsExpanded = !this.isStatsExpanded;
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
