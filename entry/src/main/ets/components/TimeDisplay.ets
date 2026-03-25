/**
 * 时间显示组件
 * Time Display Component
 * 显示当前时间或剩余解锁时间
 */
@Component
export struct TimeDisplay {
  @Prop currentTime: Date = new Date();
  @Prop showRemainingTime: boolean = false;
  @Prop remainingMinutes: number = 0;
  @Prop fontSize: number = 32;
  @Prop textColor: string = '#c0c6e9';

  build() {
    Column() {
      if (this.showRemainingTime && this.remainingMinutes > 0) {
        // 显示剩余时间
        Column() {
          Text('剩余解锁时间')
            .fontSize(14)
            .fontColor('#ff9e6d')
            .margin({ bottom: 4 })

          Row() {
            this.TimeUnit(this.getRemainingHours(), '小时')
            Text(':')
              .fontSize(this.fontSize)
              .fontColor(this.textColor)
              .margin({ left: 4, right: 4 })
            this.TimeUnit(this.getRemainingMinutes(), '小时')
          }
          .justifyContent(FlexAlign.Center)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('rgba(26, 31, 58, 0.8)')
        .borderRadius(8)
        .border({ width: 1, color: '#ff9e6d' })
      } else {
        // 显示当前时间
        Column() {
          Text(this.formatTime(this.currentTime))
            .fontSize(this.fontSize)
            .fontColor(this.textColor)
            .fontWeight(FontWeight.Medium)
            .letterSpacing(2)

          Text(this.formatDate(this.currentTime))
            .fontSize(14)
            .fontColor('rgba(192, 198, 233, 0.6)')
            .margin({ top: 4 })
        }
      }
    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private TimeUnit(value: number, unit: string): void {
    Row() {
      Text(this.formatNumber(value))
        .fontSize(this.fontSize)
        .fontColor(this.textColor)

      Text(unit)
        .fontSize(14)
        .fontColor('rgba(192, 198, 233, 0.6)')
        .margin({ left: 4 })
    }
  }

  /**
   * 格式化时间 HH:mm
   */
  private formatTime(date: Date): string {
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const weekdays = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

    return `${year}年${month}月${day}日 ${weekdays[date.getDay()]}`;
  }

  /**
   * 格式化数字（两位数）
   */
  private formatNumber(num: number): string {
    return Math.floor(num).toString().padStart(2, '0');
  }

  /**
   * 获取剩余小时数
   */
  private getRemainingHours(): number {
    return Math.floor(this.remainingMinutes / 60);
  }

  /**
   * 获取剩余分钟数
   */
  private getRemainingMinutes(): number {
    return this.remainingMinutes % 60;
  }
}

/**
 * 数字时钟组件
 * Digital Clock Component
 * 以数字形式显示时间，带有呼吸动画效果
 */
@Component
export struct DigitalClock {
  @Prop currentTime: Date = new Date();
  @Prop isLanternLawActive: boolean = false;

  build() {
    Row() {
      this.Digit(this.currentTime.getHours() / 10)
      this.Digit(this.currentTime.getHours() % 10)
      Text(':')
        .fontSize(32)
        .fontColor(this.isLanternLawActive ? '#ff9e6d' : '#c0c6e9')
        .margin({ left: 4, right: 4 })
      this.Digit(this.currentTime.getMinutes() / 10)
      this.Digit(this.currentTime.getMinutes() % 10)
      Text(':')
        .fontSize(32)
        .fontColor('rgba(192, 198, 233, 0.4)')
        .margin({ left: 4, right: 4 })
      this.Digit(this.currentTime.getSeconds() / 10)
      this.Digit(this.currentTime.getSeconds() % 10)
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  private Digit(value: number): void {
    Text(Math.floor(value).toString())
      .fontSize(32)
      .fontColor(this.isLanternLawActive ? '#ff9e6d' : '#c0c6e9')
      .fontWeight(FontWeight.Bold)
      .width(20)
      .textAlign(TextAlign.Center)
      .animation({
        duration: 1000,
        curve: Curve.EaseInOut,
        iterations: this.isLanternLawActive ? -1 : 0,
        playMode: PlayMode.Alternate
      })
  }
}
