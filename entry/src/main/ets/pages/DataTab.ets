/**
 * 数据 Tab - LanternLaw
 * 历史数据分析报告
 */
import { Logger } from '../utils/Logger';
import { DataStatisticsManager, StatisticsData } from '../managers/DataStatisticsManager';
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
}

@Component
export struct DataTab {
  // 状态
  @State currentStreak: number = 0;
  @State successRate: number = 0;
  @State totalDays: number = 0;
  @State successfulDays: number = 0;
  @State failedDays: number = 0;
  @State longestStreak: number = 0;

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
    backgroundLight: 'rgba(26, 31, 58, 0.6)'
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

            // 统计概览
            this.OverviewCard()
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
      const stats = await this.statsManager.getOverallStatistics(7);
      this.currentStreak = stats.consecutiveSuccessDays;
      this.successRate = stats.successRate;

      const allStats = await this.statsManager.getOverallStatistics();
      this.totalDays = allStats.totalDays;
      this.successfulDays = allStats.successfulDays;
      this.failedDays = allStats.failedDays;
      this.longestStreak = allStats.longestStreak;

      Logger.info('DataTab', `数据加载完成: 连续${this.currentStreak}天, 成功率${this.successRate}%`);
    } catch (error) {
      Logger.exception('DataTab', error instanceof Error ? error : new Error(String(error)), '数据加载失败');
    }
  }
}
