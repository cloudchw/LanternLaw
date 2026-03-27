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
