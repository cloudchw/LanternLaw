/**
 * 统计面板组件
 * Stats Panel Component
 * 展示今日统计概览和本周趋势，采用优雅的轻量化设计
 */

interface StatsPanelColors {
  background: string;
  border: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  success: string;
  fail: string;
}

interface MiniStatsColors {
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  border: string;
}

@Component
export struct StatsPanel {
  @Prop isExpanded: boolean = false;
  @Prop todayDuration: number = 0;
  @Prop todaySuccess: boolean = false;
  @Prop weeklyTrends: number[] = [];
  onToggle: () => void = () => {};

  // 配色方案
  private readonly COLORS: StatsPanelColors = {
    background: 'rgba(26, 31, 58, 0.6)',
    border: 'rgba(255, 209, 102, 0.2)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.5)',
    success: 'rgba(255, 209, 102, 0.15)',
    fail: 'rgba(255, 158, 109, 0.15)'
  };

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('本周数据')
          .fontSize(14)
          .fontColor(this.COLORS.text)
          .fontWeight(FontWeight.Medium)

        Row() {
          Text(this.isExpanded ? '收起' : '展开')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)

          // 替换Icon为Text
          Text(this.isExpanded ? '▲' : '▼')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .width(16)
            .height(16)
            .textAlign(TextAlign.Center)
            .margin({ left: 4 })
        }
        .onClick(() => {
          this.onToggle();
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 今日统计概览
      Row() {
        Column() {
          Text(this.formatDuration(this.todayDuration))
            .fontSize(28)
            .fontColor(this.todaySuccess ? this.COLORS.gold : this.COLORS.orange)
            .fontWeight(FontWeight.Bold)
            .letterSpacing(-0.5)

          Text('今日时长')
            .fontSize(11)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)

        // 垂直分隔线
        Column() {
          Text('|')
            .fontColor(this.COLORS.textDim)
            .fontSize(10)
        }
        .height(40)

        Column() {
          Text(this.todaySuccess ? '✓' : '✗')
            .fontSize(28)
            .fontColor(this.todaySuccess ? this.COLORS.gold : this.COLORS.orange)
            .fontWeight(FontWeight.Bold)

          Text('今日状态')
            .fontSize(11)
            .fontColor(this.COLORS.textDim)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Center)
        .layoutWeight(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .padding({ top: 16, bottom: 16 })

      // 展开的周趋势图（使用条件渲染）
      if (this.isExpanded) {
        Column() {
          Text('本周趋势')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
            .width('100%')
            .textAlign(TextAlign.Start)
            .margin({ bottom: 12 })

          // 简化的周趋势可视化（不使用复杂图表）
          Row() {
            ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, index: number) => {
              Column() {
                // 进度条
                Column()
                  .width(4)
                  .height(this.getBarHeight(this.weeklyTrends[index] || 0))
                  .borderRadius(2)
                  .backgroundColor(this.getBarColor(this.weeklyTrends[index] || 0, index))
                  .margin({ bottom: 6 })

                // 星期标签
                Text(day)
                  .fontSize(9)
                  .fontColor(this.COLORS.textDim)
              }
              .alignItems(HorizontalAlign.Center)
              .layoutWeight(1)
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
          .padding({ top: 8, bottom: 8 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .width('100%')
    .backgroundColor(this.COLORS.background)
    .borderRadius(12)
    .border({
      width: 1,
      color: this.COLORS.border,
      style: BorderStyle.Solid
    })
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.3)',
      offsetX: 0,
      offsetY: 4
    })
    .clip(true)
    .animation({
      duration: 300,
      curve: Curve.FastOutSlowIn
    })
  }

  /**
   * 格式化时长（分钟 → 时分）
   */
  private formatDuration(minutes: number): string {
    if (minutes <= 0) return '0分钟';

    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    if (hours > 0) {
      return `${hours}小时${mins > 0 ? mins + '分' : ''}`;
    }
    return `${mins}分钟`;
  }

  /**
   * 获取进度条高度（最大80）
   */
  private getBarHeight(value: number): number {
    // 假设最大时长为480分钟（8小时）
    const maxDuration = 480;
    const percentage = Math.min(value / maxDuration, 1);
    // 基础高度4 + 动态高度
    return 4 + (percentage * 50);
  }

  /**
   * 获取进度条颜色
   */
  private getBarColor(value: number, index: number): string {
    if (value <= 0) {
      return this.COLORS.fail;
    }

    // 根据索引创建渐变效果，配合提灯颜色
    const weekColors = [
      'rgba(255, 209, 102, 0.8)',   // 周一
      'rgba(255, 158, 109, 0.8)',   // 周二
      'rgba(255, 209, 102, 0.8)',   // 周三
      'rgba(255, 158, 109, 0.8)',   // 周四
      'rgba(255, 209, 102, 0.8)',   // 周五
      'rgba(255, 158, 109, 0.8)',   // 周六
      'rgba(255, 215, 0, 0.9)'      // 周日（更亮的金色）
    ];

    return weekColors[index];
  }
}

/**
 * 迷你统计指示器
 * Mini Stats Indicator
 * 用于在主页面显示简洁的统计概览
 */
@Component
export struct MiniStatsIndicator {
  @Prop consecutiveDays: number = 0;
  @Prop successRate: number = 0;
  @Prop showBorder: boolean = true;

  private readonly COLORS: MiniStatsColors = {
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    border: 'rgba(255, 209, 102, 0.15)'
  };

  build() {
    Row() {
      // 连续天数
      Row() {
        Text('🔥')
          .fontSize(14)
          .margin({ right: 6 })

        Column() {
          Text(this.consecutiveDays.toString())
            .fontSize(16)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Medium)

          Text('连续天数')
            .fontSize(10)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })

      // 垂直分隔线
      Column()
        .width(1)
        .height(24)
        .backgroundColor(this.COLORS.textDim)
        .margin({ left: 12, right: 12 })

      // 成功率
      Row() {
        Text('📊')
          .fontSize(14)
          .margin({ right: 6 })

        Column() {
          Text(`${this.successRate}%`)
            .fontSize(16)
            .fontColor(this.COLORS.orange)
            .fontWeight(FontWeight.Medium)

          Text('成功率')
            .fontSize(10)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}