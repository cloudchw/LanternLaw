/**
 * 数据 Tab - LanternLaw
 * 历史数据分析报告 + 逃跑行为分析 + 反思提示
 */
import { Logger } from '../utils/Logger';
import { DataStatisticsManager, StatisticsData, TrendData } from '../managers/DataStatisticsManager';
import { LanternLawDatabase } from '../database/LanternLawDatabase';

interface DataColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
  backgroundLight: string;
  green: string;
  red: string;
  yellow: string;
}

@Component
export struct DataTab {
  // 基础统计状态
  @State currentStreak: number = 0;
  @State successRate: number = 0;
  @State totalDays: number = 0;
  @State successfulDays: number = 0;
  @State failedDays: number = 0;
  @State longestStreak: number = 0;

  // 逃跑分析状态
  @State weeklyEscapeCount: number = 0;
  @State lastWeekEscapeCount: number = 0;
  @State dailyTrends: TrendData[] = [];
  @State reflectionTip: string = '';

  // 管理器实例
  private statsManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 配色方案
  private readonly COLORS: DataColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)',
    backgroundLight: 'rgba(26, 31, 58, 0.6)',
    green: '#4ade80',
    red: '#ff6b6b',
    yellow: '#fbbf24'
  };

  aboutToAppear() {
    Logger.info('DataTab', '数据 Tab 初始化');
    this.loadData();
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
        // 标题栏
        Row() {
          Text('📊 数据分析')
            .fontSize(24)
            .fontColor(this.COLORS.text)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        // 可滚动内容
        Scroll() {
          Column() {
            // 本周数据卡片
            this.WeeklyStreakCard()

            // 逃跑分析卡片
            this.EscapeAnalysisCard()

            // 每日趋势
            this.DailyTrendCard()

            // 统计概览
            this.OverviewCard()

            // 反思提示卡片
            if (this.reflectionTip.length > 0) {
              this.ReflectionCard()
            }
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
   * 逃跑分析卡片
   */
  @Builder
  private EscapeAnalysisCard(): void {
    Column() {
      Text('逃跑行为分析')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      // 本周逃跑次数 + 对比上周
      Row() {
        Column() {
          Text('本周逃跑')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .margin({ bottom: 4 })
          Text(this.weeklyEscapeCount.toString())
            .fontSize(28)
            .fontColor(this.weeklyEscapeCount === 0 ? this.COLORS.green : this.COLORS.orange)
            .fontWeight(FontWeight.Bold)
          Text('次')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        Column()
          .width(1)
          .height(50)
          .backgroundColor(this.COLORS.border)

        Column() {
          Text('对比上周')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .margin({ bottom: 4 })
          Text(this.getEscapeTrendText())
            .fontSize(16)
            .fontColor(this.getEscapeTrendColor())
            .fontWeight(FontWeight.Bold)
          Text(this.getEscapeTrendLabel())
            .fontSize(11)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.COLORS.backgroundLight)
      .borderRadius(12)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 每日趋势卡片
   */
  @Builder
  private DailyTrendCard(): void {
    Column() {
      Text('近7日趋势')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      if (this.dailyTrends.length === 0) {
        Text('暂无趋势数据')
          .fontSize(13)
          .fontColor(this.COLORS.textDim)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 16, bottom: 16 })
      } else {
        ForEach(this.dailyTrends, (trend: TrendData, index: number) => {
          Row() {
            // 日期
            Text(this.formatShortDate(trend.date))
              .fontSize(13)
              .fontColor(this.COLORS.text)
              .width(50)

            // 状态指示
            Column()
              .width(8)
              .height(8)
              .borderRadius(4)
              .backgroundColor(trend.success ? this.COLORS.green : this.COLORS.red)
              .margin({ left: 8, right: 8 })

            // 进度条
            Progress({ value: trend.duration, total: Math.max(trend.duration, 480), type: ProgressType.Linear })
              .layoutWeight(1)
              .height(6)
              .color(trend.success ? this.COLORS.gold : this.COLORS.red)
              .backgroundColor(this.COLORS.backgroundLight)

            // 逃跑次数标签
            Row() {
              Text(trend.escapeCount.toString())
                .fontSize(12)
                .fontColor(this.getEscapeCountColor(trend.escapeCount))
                .fontWeight(FontWeight.Medium)
            }
            .width(36)
            .height(20)
            .borderRadius(10)
            .backgroundColor(this.getEscapeCountBg(trend.escapeCount))
            .justifyContent(FlexAlign.Center)
            .margin({ left: 8 })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
        }, (trend: TrendData, index: number) => trend.date)
      }

      // 图例
      Row() {
        Row() {
          Column().width(8).height(8).borderRadius(4).backgroundColor(this.COLORS.green)
          Text('成功').fontSize(10).fontColor(this.COLORS.textDim).margin({ left: 4 })
        }
        Row() {
          Column().width(8).height(8).borderRadius(4).backgroundColor(this.COLORS.red).margin({ left: 12 })
          Text('失败').fontSize(10).fontColor(this.COLORS.textDim).margin({ left: 4 })
        }
        Blank()
        Text('数字 = 逃跑次数').fontSize(10).fontColor(this.COLORS.textDim)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 反思提示卡片
   */
  @Builder
  private ReflectionCard(): void {
    Column() {
      Row() {
        Text('💡')
          .fontSize(18)
          .margin({ right: 8 })
        Text('反思与建议')
          .fontSize(16)
          .fontColor(this.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text(this.reflectionTip)
        .fontSize(14)
        .fontColor(this.COLORS.text)
        .lineHeight(22)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(255, 209, 102, 0.25)' })
    .margin({ bottom: 16 })
  }

  /**
   * 本周连续天数卡片
   */
  @Builder
  private WeeklyStreakCard(): void {
    Column() {
      Text('本周数据')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      // 连续天数
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
      .padding({ left: 16, right: 16, top: 14, bottom: 14 })
      .backgroundColor(this.COLORS.backgroundLight)
      .borderRadius(12)

      // 进度条
      Progress({ value: this.successRate, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.COLORS.gold)
        .backgroundColor(this.COLORS.backgroundLight)
        .margin({ top: 12 })

      // 成功率文字
      Row() {
        Text('成功率')
          .fontSize(12)
          .fontColor(this.COLORS.textDim)

        Blank()

        Text(`${this.successRate}%`)
          .fontSize(12)
          .fontColor(this.COLORS.gold)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 统计概览卡片
   */
  @Builder
  private OverviewCard(): void {
    Column() {
      Text('统计概览')
        .fontSize(16)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 12 })

      // 统计数据网格
      Column() {
        Row() {
          this.StatItem('总天数', this.totalDays.toString(), '天')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('成功', this.successfulDays.toString(), '天')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('失败', this.failedDays.toString(), '天')
        }
        .width('100%')

        Column()
          .width('100%')
          .height(1)
          .backgroundColor(this.COLORS.border)
          .margin({ top: 12, bottom: 12 })

        Row() {
          this.StatItem('最长连续', this.longestStreak.toString(), '天')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('成功率', `${this.successRate}%`, '')
          Column()
            .width(1)
            .height(40)
            .backgroundColor(this.COLORS.border)
          this.StatItem('状态', this.currentStreak > 0 ? '🔥' : '—', '')
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(this.COLORS.backgroundLight)
      .borderRadius(12)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 单个统计项
   */
  @Builder
  private StatItem(label: string, value: string, unit: string): void {
    Column() {
      Text(value)
        .fontSize(18)
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
   * 加载数据
   */
  private async loadData(): Promise<void> {
    if (!this.database.isInitialized()) {
      Logger.info('DataTab', '数据库未初始化，等待...');
      setTimeout(() => {
        this.loadData();
      }, 500);
      return;
    }

    try {
      // 基础统计
      const stats = await this.statsManager.getOverallStatistics(7);
      this.currentStreak = stats.consecutiveSuccessDays;
      this.successRate = stats.successRate;

      const allStats = await this.statsManager.getOverallStatistics();
      this.totalDays = allStats.totalDays;
      this.successfulDays = allStats.successfulDays;
      this.failedDays = allStats.failedDays;
      this.longestStreak = allStats.longestStreak;

      // 逃跑分析
      this.weeklyEscapeCount = await this.database.getEscapeCountInDays(7);
      this.lastWeekEscapeCount = await this.database.getEscapeCountInDays(14) - this.weeklyEscapeCount;

      // 每日趋势
      this.dailyTrends = await this.statsManager.getWeeklyTrends();

      // 生成反思提示
      this.generateReflectionTip(stats);

      Logger.info('DataTab', `数据加载完成: 连续${this.currentStreak}天, 成功率${this.successRate}%, 本周逃跑${this.weeklyEscapeCount}次`);
    } catch (error) {
      Logger.exception('DataTab', error instanceof Error ? error : new Error(String(error)), '数据加载失败');
    }
  }

  /**
   * 生成反思提示
   */
  private generateReflectionTip(stats: StatisticsData): void {
    const tips: string[] = [];

    if (this.weeklyEscapeCount === 0 && this.totalDays > 0) {
      tips.push('本周零逃跑，自律满分！保持这个节奏，你正在建立坚实的习惯。');
    } else if (this.weeklyEscapeCount > 0 && this.weeklyEscapeCount <= 3) {
      tips.push(`本周你在灯律时段内离开了 ${this.weeklyEscapeCount} 次。适度反思就好，自律不是完美的纪律，而是持续的选择。`);
    } else if (this.weeklyEscapeCount > 3) {
      tips.push(`本周逃跑 ${this.weeklyEscapeCount} 次，似乎遇到了一些挑战。试试在灯律时段到来前，准备好替代活动，比如阅读或冥想。`);
    }

    const diff = this.lastWeekEscapeCount - this.weeklyEscapeCount;
    if (diff > 0) {
      tips.push(`比上周减少了 ${diff} 次，方向正确，继续加油！`);
    } else if (diff < 0 && this.lastWeekEscapeCount > 0) {
      tips.push(`比上周多了 ${Math.abs(diff)} 次，别灰心，每周都是新的开始。`);
    }

    if (this.currentStreak >= 7) {
      tips.push(`连续 ${this.currentStreak} 天成功，你的意志力正在变得越来越强！`);
    }

    if (this.successRate >= 80 && this.totalDays >= 3) {
      tips.push(`成功率 ${this.successRate}%，你已经是优秀的掌灯人了。`);
    }

    this.reflectionTip = tips.length > 0 ? tips.join('\n\n') : '';
  }

  // ==================== 辅助方法 ====================

  private getEscapeTrendText(): string {
    const diff = this.lastWeekEscapeCount - this.weeklyEscapeCount;
    if (this.lastWeekEscapeCount === 0 && this.weeklyEscapeCount === 0) {
      return '--';
    } else if (diff > 0) {
      return `↓${diff}`;
    } else if (diff < 0) {
      return `↑${Math.abs(diff)}`;
    }
    return '持平';
  }

  private getEscapeTrendColor(): string {
    const diff = this.lastWeekEscapeCount - this.weeklyEscapeCount;
    if (diff > 0) {
      return this.COLORS.green;
    } else if (diff < 0) {
      return this.COLORS.red;
    }
    return this.COLORS.textDim;
  }

  private getEscapeTrendLabel(): string {
    const diff = this.lastWeekEscapeCount - this.weeklyEscapeCount;
    if (diff > 0) {
      return '进步了';
    } else if (diff < 0) {
      return '需注意';
    }
    return '稳定';
  }

  private getEscapeCountColor(count: number): string {
    if (count === 0) {
      return this.COLORS.green;
    } else if (count <= 2) {
      return this.COLORS.yellow;
    }
    return this.COLORS.red;
  }

  private getEscapeCountBg(count: number): string {
    if (count === 0) {
      return 'rgba(74, 222, 128, 0.15)';
    } else if (count <= 2) {
      return 'rgba(251, 191, 36, 0.15)';
    }
    return 'rgba(255, 107, 107, 0.15)';
  }

  private formatShortDate(dateStr: string): string {
    if (!dateStr || dateStr.length < 10) {
      return dateStr;
    }
    const parts = dateStr.split('-');
    return `${parts[1]}/${parts[2]}`;
  }
}
