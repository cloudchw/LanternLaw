/**
 * 主页面 - LanternLaw
 * Main page
 * 采用温暖光夜美学设计的灯律界面
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

interface IndexColorScheme {
  background: string;
  backgroundLight: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  card: string;
}

@Entry
@Component
struct Index {
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
  private readonly COLORS: IndexColorScheme = {
    background: '#0f1529',        // 深夜蓝
    backgroundLight: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',             // 暖金
    orange: '#ff9e6d',           // 橙色
    text: '#c0c6e9',            // 淡蓝
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    card: 'rgba(15, 21, 41, 0.6)'
  };

  aboutToAppear() {
    // 启动定时器更新时间
    this.startClockTimer();

    // 初始化管理器
    this.initializeManagers();

    // 启动状态监控定时器
    this.startStateMonitorTimer();

    Logger.info('Index', '主页面初始化完成');
  }

  build() {
    Stack() {
      // 背景渐变层
      this.BackgroundGradient()

      Column() {
        // 顶部状态栏（简洁）
        this.TopStatusBar()

        // 主内容区域
        Column() {
          // 标题和问候
          this.TitleSection()

          // 核心时钟区域
          this.ClockSection()

          // 虚拟提灯系统
          this.LanternSection()

          // 激励文本区域
          this.MotivationSection()

          // 统计面板
          this.StatisticsSection()

          // 底部操作按钮
          this.ActionButtons()
        }
        .layoutWeight(1)
        .width('90%')
      }
      .width('100%')
      .height('100%')
      .padding({ top: 40, bottom: 30 })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 背景渐变效果
   */
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
      .position({ x: 0, y: 0 })
  }

  /**
   * 顶部状态栏
   */
  @Builder
  private TopStatusBar(): void {
    Row() {
      // 应用名称（简洁）
      Text('提灯')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Bold)

      Blank()

      // 时间（右对齐）
      Text(`${this.currentTime.getHours().toString().padStart(2, '0')}:${this.currentTime.getMinutes().toString().padStart(2, '0')}`)
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 8, bottom: 8 })
  }

  /**
   * 标题区域
   */
  @Builder
  private TitleSection(): void {
    Column() {
      // 主标题
      Text('灯律')
        .fontSize(32)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(4)
        .margin({ bottom: 4 })

      // 时间问候
      Text(this.getTimeGreeting())
        .fontSize(13)
        .fontColor(this.COLORS.textDim)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 40 })
  }

  /**
   * 时钟区域
   */
  @Builder
  private ClockSection(): void {
    Column() {
      // 时钟组件
      ClockComponent({
        currentTime: this.currentTime,
        isLanternLawActive: this.lanternLawState === LanternLawState.ACTIVE,
        clockSize: 260
      })
        .margin({ bottom: 24 })

      // 时间显示组件
      TimeDisplay({
        currentTime: this.currentTime,
        showRemainingTime: this.lanternLawState === LanternLawState.ACTIVE,
        remainingMinutes: this.getRemainingMinutes(),
        fontSize: 24
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 32 })
  }

  /**
   * 提灯系统区域
   */
  @Builder
  private LanternSection(): void {
    Column() {
      // 7灯系统
      LanternSystem({
        successDays: this.successDays,
        currentStreak: this.currentStreak,
        lanternSize: 32,
        spacing: 12
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 28 })
  }

  /**
   * 激励文本区域
   */
  @Builder
  private MotivationSection(): void {
    MotivationText({
      lanternLawState: this.lanternLawState,
      currentStreak: this.currentStreak,
      timeUntilWakeup: this.getRemainingMinutes(),
      animated: true
    })
  }

  /**
   * 统计区域
   */
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

  /**
   * 操作按钮区域
   */
  @Builder
  private ActionButtons(): void {
    Column() {
      // 无障碍服务状态提示
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

      // 主要操作按钮
      Button(this.getMainButtonText())
        .width('100%')
        .height(48)
        .backgroundColor(this.getMainButtonColor())
        .fontColor(this.COLORS.background)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .borderRadius(24)
        .onClick(() => {
          this.handleMainButtonClick();
        })
    }
    .width('100%')
  }

  /**
   * 启动时钟定时器
   */
  private startClockTimer(): void {
    setInterval(() => {
      this.currentTime = new Date();
    }, 1000);
  }

  /**
   * 启动状态监控定时器
   */
  private startStateMonitorTimer(): void {
    setInterval(async () => {
      await this.updateStatus();
    }, 60000); // 每分钟更新一次
  }

  /**
   * 初始化管理器
   */
  private async initializeManagers(): Promise<void> {
    try {
      // 先初始化数据库
      const ctx = getContext(this) as common.UIAbilityContext;
      await this.database.initialize(ctx);

      await this.statsManager.initialize();
      await this.achievementManager.initialize();

      // 加载初始数据
      await this.updateStatus();

      Logger.info('Index', '管理器初始化完成');
    } catch (error) {
      Logger.exception('Index', error as Error, '管理器初始化失败');
    }
  }

  /**
   * 更新状态信息
   */
  private async updateStatus(): Promise<void> {
    if (!this.database.isInitialized()) {
      return;
    }
    try {
      // 更新灯律状态
      this.lanternLawState = this.stateManager.getCurrentState();

      // 获取统计数据
      const stats = await this.statsManager.getOverallStatistics(7);
      this.currentStreak = stats.consecutiveSuccessDays;
      this.successRate = stats.successRate;

      // 获取趋势数据
      const trends = await this.statsManager.getWeeklyTrends();
      this.weeklyTrends = trends.map(t => t.duration);

      // 获取今日数据
      const recentRecords = await this.statsManager.getOverallStatistics(1);
      if (recentRecords.totalDays > 0) {
        this.todayDuration = recentRecords.averageDuration;
        this.todaySuccess = recentRecords.successRate > 0;
      }

      // 获取提灯状态
      const lanternProgress = this.achievementManager.getLanternProgress();
      this.successDays = lanternProgress.current;

    } catch (error) {
      Logger.exception('Index', error as Error, '状态更新失败');
    }
  }

  /**
   * 切换统计面板展开/收起
   */
  private toggleStatsPanel(): void {
    this.isStatsExpanded = !this.isStatsExpanded;
  }

  /**
   * 检查无障碍服务是否启用
   */
  private isAccessibilityServiceEnabled(): boolean {
    // TODO: 实现实际的无障碍服务状态检查
    return true;
  }

  /**
   * 打开无障碍设置
   */
  private openAccessibilitySettings(): void {
    Logger.info('Index', '打开无障碍设置');
    // TODO: 实现跳转到无障碍设置页面的逻辑
  }

  /**
   * 获取主按钮文本
   */
  private getMainButtonText(): string {
    switch (this.lanternLawState) {
      case LanternLawState.ACTIVE:
        return '灯律执行中';
      case LanternLawState.OVERRIDDEN:
        return '已越狱';
      default:
        return '前往设置';
    }
  }

  /**
   * 获取主按钮颜色
   */
  private getMainButtonColor(): string {
    switch (this.lanternLawState) {
      case LanternLawState.ACTIVE:
        return this.COLORS.gold;
      case LanternLawState.OVERRIDDEN:
        return this.COLORS.orange;
      default:
        return this.COLORS.accent;
    }
  }

  /**
   * 处理主按钮点击
   */
  private handleMainButtonClick(): void {
    Logger.info('Index', '主按钮点击，当前状态: ' + this.lanternLawState);

    switch (this.lanternLawState) {
      case LanternLawState.ACTIVE:
        // 显示越狱提示
        this.showEscapeDialog();
        break;
      case LanternLawState.OVERRIDDEN:
        // 显示恢复提示
        this.showRecoveryDialog();
        break;
      default:
        // 跳转到设置页面
        this.navigateToSettings();
        break;
    }
  }

  /**
   * 显示越狱对话框
   */
  private showEscapeDialog(): void {
    Logger.info('Index', '显示越狱对话框');
    // TODO: 实现越狱确认对话框
  }

  /**
   * 显示恢复对话框
   */
  private showRecoveryDialog(): void {
    Logger.info('Index', '显示恢复对话框');
    // TODO: 实现恢复确认对话框
  }

  /**
   * 导航到设置页面
   */
  private navigateToSettings(): void {
    Logger.info('Index', '导航到设置页面');
    // TODO: 实现路由跳转
  }

  /**
   * 获取剩余分钟数
   */
  private getRemainingMinutes(): number {
    const config = this.stateManager.getConfig();
    const now = new Date();
    const wakeupHour = parseInt(config.wakeupTime.split(':')[0]);
    const wakeupMinute = parseInt(config.wakeupTime.split(':')[1]);

    let wakeupTime = new Date();
    wakeupTime.setHours(wakeupHour, wakeupMinute, 0, 0);

    // 如果现在已经是第二天，则计算到第三天的起床时间
    if (now > wakeupTime) {
      wakeupTime.setDate(wakeupTime.getDate() + 1);
    }

    return Math.floor((wakeupTime.getTime() - now.getTime()) / (1000 * 60));
  }

  /**
   * 获取时间问候语
   */
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
}