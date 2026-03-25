/**
 * 统计页面 - LanternLaw
 * Statistics Page
 * 展示历史记录、成就列表和数据导出功能
 */
import { Logger } from '../utils/Logger';
import router from '@ohos.router';
import { DataStatisticsManager, StatisticsData, TrendData, WeeklyStatistics } from '../managers/DataStatisticsManager';
import { AchievementManager } from '../managers/AchievementManager';
import type { Achievement } from '../models/Achievement';
import { LanternLawDatabase } from '../database/LanternLawDatabase';

interface StatsColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
  success: string;
  fail: string;
}

@Entry
@Component
struct StatsPage {
  // 状态
  @State overallStats: StatisticsData = this.getEmptyStats();
  @State weeklyTrends: TrendData[] = [];
  @State monthlyTrends: TrendData[] = [];
  @State achievements: Achievement[] = [];
  @State unlockedAchievements: Achievement[] = [];
  @State selectedPeriod: string = 'week'; // 'week' | 'month' | 'all'
  @State isExportMode: boolean = false;

  // 管理器实例
  private statsManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 配色方案
  private readonly COLORS: StatsColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)',
    success: 'rgba(76, 217, 100, 0.8)',
    fail: 'rgba(255, 158, 109, 0.8)'
  };

  aboutToAppear() {
    this.loadData();
  }

  build() {
    Column() {
      // 顶部导航栏
      this.TopNavigationBar()

      Scroll() {
        Column() {
          // 总体统计卡片
          this.OverviewStatistics()

          // 趋势分析区域
          this.TrendSection()

          // 连续统计卡片
          this.StreakStatistics()

          // 成就列表区域
          this.AchievementSection()

          // 数据导出区域
          this.ExportSection()
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
      Text('统计与成就')
        .fontSize(18)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)

      Blank()

      // 导出按钮
      Button() {
        Text('⬆')
          .fontSize(20)
          .fontColor(this.COLORS.textDim)
      }
      .type(ButtonType.Normal)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.showExportDialog();
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 12, right: 12 })
    .backgroundColor(this.COLORS.background)
  }

  /**
   * 总体统计概览
   */
  @Builder
  private OverviewStatistics(): void {
    Column() {
      Text('总体概览')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          this.StatItem('总天数', this.overallStats.totalDays.toString(), '天')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('成功天数', this.overallStats.successfulDays.toString(), '天')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('失败天数', this.overallStats.failedDays.toString(), '天')
        }
        .width('100%')

        Column()
          .width('100%')
          .height(1)
          .backgroundColor(this.COLORS.border)
          .margin({ top: 12, bottom: 12 })

        Row() {
          this.StatItem('平均时长', this.overallStats.averageDuration.toString(), '分钟')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('成功率', `${this.overallStats.successRate}%`, '')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('越狱次数', this.overallStats.totalEscapeAttempts.toString(), '次')
        }
        .width('100%')
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
   * 单个统计项
   */
  @Builder
  private StatItem(label: string, value: string, unit: string): void {
    Column() {
      Text(value)
        .fontSize(20)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Bold)

      Text(label)
        .fontSize(11)
        .fontColor(this.COLORS.textDim)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /**
   * 趋势分析区域
   */
  @Builder
  private TrendSection(): void {
    Column() {
      Text('趋势分析')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      // 周期选择器
      Row() {
        ForEach(['week', 'month', 'all'], (period: string) => {
          Text(period === 'week' ? '7天' : period === 'month' ? '30天' : '全部')
            .fontSize(13)
            .fontColor(this.selectedPeriod === period ? this.COLORS.background : this.COLORS.textDim)
            .backgroundColor(this.selectedPeriod === period ? this.COLORS.gold : Color.Transparent)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .margin({ right: 8 })
            .onClick(() => {
              this.selectedPeriod = period;
              this.loadTrendData();
            })
        })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 趋势列表
      if (this.selectedPeriod === 'week') {
        this.TrendList(this.weeklyTrends)
      } else if (this.selectedPeriod === 'month') {
        this.TrendList(this.monthlyTrends)
      }
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 趋势列表
   */
  @Builder
  private TrendList(trends: TrendData[]): void {
    Column() {
      if (trends.length === 0) {
        Text('暂无趋势数据')
          .fontSize(13)
          .fontColor(this.COLORS.textDim)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(20)
      } else {
        ForEach(trends, (trend: TrendData, index: number) => {
          Column() {
            Row() {
              Text(trend.date)
                .fontSize(13)
                .fontColor(this.COLORS.text)

              Blank()

              Text(`${trend.duration}分钟`)
                .fontSize(13)
                .fontColor(trend.success ? this.COLORS.gold : this.COLORS.orange)

              Text(trend.success ? '✓' : '✗')
                .fontSize(14)
                .fontColor(trend.success ? this.COLORS.success : this.COLORS.fail)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })

            if (index < trends.length - 1) {
              Column()
                .width('100%')
                .height(1)
                .backgroundColor(this.COLORS.border)
                .margin({ top: 10 })
            }
          }
        })
      }
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

  /**
   * 连续统计区域
   */
  @Builder
  private StreakStatistics(): void {
    Column() {
      Text('连续统计')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          this.StreakStatItem('当前连续',
            this.overallStats.consecutiveSuccessDays.toString(),
            '天',
            this.overallStats.consecutiveSuccessDays > 0
          )

          Column()
            .width(1)
            .height(50)
            .backgroundColor(this.COLORS.border)

          this.StreakStatItem('最长连续',
            this.overallStats.longestStreak.toString(),
            '天',
            this.overallStats.longestStreak > 0
          )
        }
        .width('100%')
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
   * 连续统计项
   */
  @Builder
  private StreakStatItem(label: string, value: string, unit: string, hasValue: boolean): void {
    Column() {
      Row() {
        Text(value)
          .fontSize(24)
          .fontColor(hasValue ? this.COLORS.gold : this.COLORS.textDim)
          .fontWeight(FontWeight.Bold)

        if (hasValue) {
          Text('🔥')
            .fontSize(16)
            .margin({ left: 4 })
        }
      }
      .alignItems(VerticalAlign.Top)

      Text(label)
        .fontSize(11)
        .fontColor(this.COLORS.textDim)
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)
  }

  /**
   * 成就列表区域
   */
  @Builder
  private AchievementSection(): void {
    Column() {
      Text('成就系统')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        Text(`已解锁 ${this.unlockedAchievements.length}/${this.achievements.length}`)
          .fontSize(12)
          .fontColor(this.COLORS.textDim)

        Blank()

        Text('查看全部成就')
          .fontSize(12)
          .fontColor(this.COLORS.gold)
          .onClick(() => {
            this.showAllAchievements();
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      // 成就列表
      ForEach(this.achievements.slice(0, 3), (achievement: Achievement) => {
        this.AchievementItem(achievement)
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 单个成就项
   */
  @Builder
  private AchievementItem(achievement: Achievement): void {
    Row() {
      // 成就图标
      Column() {
        Text(achievement.icon)
          .fontSize(28)
          .opacity(achievement.unlocked ? 1.0 : 0.3)
      }
      .width(56)
      .height(56)
      .backgroundColor(achievement.unlocked ? this.COLORS.accent : Color.Transparent)
      .borderRadius(28)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({
        radius: achievement.unlocked ? 8 : 0,
        color: achievement.unlocked ? this.COLORS.gold : 'transparent'
      })

      // 成就信息
      Column() {
        Text(achievement.name)
          .fontSize(14)
          .fontColor(achievement.unlocked ? this.COLORS.text : this.COLORS.textDim)
          .fontWeight(achievement.unlocked ? FontWeight.Medium : FontWeight.Normal)

        Text(achievement.description)
          .fontSize(11)
          .fontColor(this.COLORS.textDim)
          .margin({ top: 4 })

        if (achievement.unlocked) {
          Text(`解锁于 ${this.formatDate(achievement.unlockedAt)}`)
            .fontSize(10)
            .fontColor(this.COLORS.gold)
            .margin({ top: 4 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .width('100%')
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .margin({ bottom: 8 })
    .border({
      width: achievement.unlocked ? 1 : 0,
      color: this.COLORS.border
    })
    .opacity(achievement.unlocked ? 1.0 : 0.6)
  }

  /**
   * 数据导出区域
   */
  @Builder
  private ExportSection(): void {
    Column() {
      Text('数据管理')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      Row() {
        // JSON导出
        Button('导出为JSON')
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.COLORS.accent)
          .fontColor(this.COLORS.text)
          .borderRadius(12)
          .margin({ right: 8 })
          .onClick(() => {
            this.exportData('json');
          })

        // CSV导出
        Button('导出为CSV')
          .type(ButtonType.Normal)
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.COLORS.accent)
          .fontColor(this.COLORS.text)
          .borderRadius(12)
          .onClick(() => {
            this.exportData('csv');
          })
      }
      .width('100%')

      // 清除数据按钮
      Button('清除所有数据')
        .type(ButtonType.Normal)
        .width('100%')
        .height(44)
        .backgroundColor(this.COLORS.card)
        .fontColor(this.COLORS.fail)
        .borderRadius(12)
        .margin({ top: 12 })
        .border({
          width: 1,
          color: this.COLORS.fail
        })
        .onClick(() => {
          this.showClearDataDialog();
        })
    }
    .width('100%')
    .margin({ bottom: 32 })
  }

  /**
   * 显示导出对话框
   */
  private showExportDialog(): void {
    Logger.info('StatsPage', '显示导出对话框');
    // TODO: 实现导出格式选择对话框
  }

  /**
   * 显示全部成就对话框
   */
  private showAllAchievements(): void {
    Logger.info('StatsPage', '显示全部成就对话框');
    // TODO: 实现成就列表详情对话框
  }

  /**
   * 显示清除数据对话框
   */
  private showClearDataDialog(): void {
    Logger.info('StatsPage', '显示清除数据确认对话框');
    // TODO: 实现确认清除数据对话框
  }

  /**
   * 导出数据
   */
  private async exportData(format: string): Promise<void> {
    try {
      const data = await this.statsManager.exportStatisticsData(format);

      if (data) {
        Logger.info('StatsPage', `数据导出成功 (${format})`);
        // TODO: 显示成功消息，提供文件保存选项
      }
    } catch (error) {
      Logger.exception('StatsPage', error as Error, '数据导出失败');
    }
  }

  /**
   * 加载数据
   */
  private async loadData(): Promise<void> {
    try {
      await Promise.all([
        this.loadOverallStats(),
        this.loadTrendData(),
        this.loadAchievements()
      ]);

      Logger.info('StatsPage', '统计数据加载完成');
    } catch (error) {
      Logger.exception('StatsPage', error as Error, '数据加载失败');
    }
  }

  /**
   * 加载总体统计
   */
  private async loadOverallStats(): Promise<void> {
    this.overallStats = await this.statsManager.getOverallStatistics();
  }

  /**
   * 加载趋势数据
   */
  private async loadTrendData(): Promise<void> {
    if (this.selectedPeriod === 'week') {
      this.weeklyTrends = await this.statsManager.getWeeklyTrends();
    } else if (this.selectedPeriod === 'month') {
      this.monthlyTrends = await this.statsManager.getMonthlyTrends();
    }
  }

  /**
   * 加载成就数据
   */
  private async loadAchievements(): Promise<void> {
    this.achievements = this.achievementManager.getAllAchievements();
    this.unlockedAchievements = this.achievementManager.getUnlockedAchievements();
  }

  /**
   * 格式化日期
   */
  private formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getMonth() + 1}/${date.getDate()}`;
  }

  /**
   * 获取空统计数据
   */
  private getEmptyStats(): StatisticsData {
    return {
      totalDays: 0,
      successfulDays: 0,
      failedDays: 0,
      totalDuration: 0,
      averageDuration: 0,
      totalEscapeAttempts: 0,
      successRate: 0,
      consecutiveSuccessDays: 0,
      longestStreak: 0
    };
  }

  /**
   * 导航返回
   */
  private navigateBack(): void {
    try {
      router.back();
    } catch (error) {
      Logger.exception('StatsPage', error as Error, '导航返回失败');
    }
  }
}