/**
 * 虚拟提灯系统组件
 * Lantern System Component
 * 显示7盏虚拟提灯，代表一周的灯律坚持情况
 */
@Component
export struct LanternSystem {
  @Prop successDays: number = 0;
  @Prop currentStreak: number = 0;
  @Prop lanternSize: number = 40;
  @Prop spacing: number = 15;

  build() {
    Row({ space: this.spacing }) {
      ForEach([0, 1, 2, 3, 4, 5, 6], (index: number) => {
        this.LanternItem(index)
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  private LanternItem(index: number): void {
    Column() {
      // 提灯本体
      Stack() {
        // 光晕效果
        Circle()
          .width(this.lanternSize + 10)
          .height(this.lanternSize + 10)
          .fill(this.getGlowColor(index))
          .opacity(this.isLanternLit(index) ? 0.6 : 0)

        // 提灯主体
        Circle()
          .width(this.lanternSize)
          .height(this.lanternSize)
          .fill(this.getLanternColor(index))
          .shadow({
            radius: this.isLanternLit(index) ? 15 : 5,
            color: this.isLanternLit(index) ? '#ffd166' : '#2a3157',
            offsetX: 0,
            offsetY: 0
          })

        // 提灯纹理
        Circle()
          .width(this.lanternSize * 0.7)
          .height(this.lanternSize * 0.7)
          .fill(this.getTextureColor(index))
      }

      // 星期标签
      Text(this.getWeekdayLabel(index))
        .fontSize(10)
        .fontColor('#c0c6e9')
        .margin({ top: 5 })
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 判断提灯是否点亮
   */
  private isLanternLit(index: number): boolean {
    return index < this.successDays;
  }

  /**
   * 获取提灯光晕颜色
   */
  private getGlowColor(index: number): string {
    if (!this.isLanternLit(index)) {
      return 'transparent';
    }

    // 根据索引创建渐变色效果
    const colors = [
      'radial-gradient(circle, #ffd166 0%, transparent 70%)',  // 周一
      'radial-gradient(circle, #ff9e6d 0%, transparent 70%)',  // 周二
      'radial-gradient(circle, #ffd166 0%, transparent 70%)',  // 周三
      'radial-gradient(circle, #ff9e6d 0%, transparent 70%)',  // 周四
      'radial-gradient(circle, #ffd166 0%, transparent 70%)',  // 周五
      'radial-gradient(circle, #ff9e6d 0%, transparent 70%)',  // 周六
      'radial-gradient(circle, #ffd700 0%, transparent 70%)'   // 周日（金色）
    ];

    return colors[index];
  }

  /**
   * 获取提灯主体颜色
   */
  private getLanternColor(index: number): string {
    if (this.isLanternLit(index)) {
      // 点亮状态：暖色渐变
      const colors = ['#ffd166', '#ff9e6d', '#ffd700'];
      return colors[index % colors.length];
    } else {
      // 熄灭状态：深色
      return '#1a1f3a';
    }
  }

  /**
   * 获取提灯纹理颜色
   */
  private getTextureColor(index: number): string {
    if (!this.isLanternLit(index)) {
      return 'rgba(42, 49, 87, 0.5)';
    }

    // 创建渐变纹理
    return 'radial-gradient(circle at 30% 30%, rgba(255,255,255,0.3) 0%, transparent 50%)';
  }

  /**
   * 获取星期标签
   */
  private getWeekdayLabel(index: number): string {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    return weekdays[index];
  }
}

/**
 * 提灯进度指示器组件
 * 显示提灯系统整体进度
 */
@Component
export struct LanternProgress {
  @Prop current: number = 0;
  @Prop max: number = 7;
  @Prop showLabel: boolean = true;

  build() {
    Column() {
      if (this.showLabel) {
        Text(`本周提灯进度：${this.current}/${this.max}`)
          .fontSize(14)
          .fontColor('#c0c6e9')
          .margin({ bottom: 8 })
      }

      Row({ space: 8 }) {
        ForEach(Array.from<number>({ length: this.max }).map((_, i) => i + 1), (index: number) => {
          Circle()
            .width(8)
            .height(8)
            .fill(index <= this.current ? '#ffd166' : '#1a1f3a')
            .shadow({
              radius: index <= this.current ? 4 : 0,
              color: '#ffd166'
            })
        }, (item: number): string => `dot_${item}`)
      }
      .justifyContent(FlexAlign.Center)
    }
    .alignItems(HorizontalAlign.Center)
  }
}
