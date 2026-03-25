/**
 * 时钟表盘组件
 * Clock Component
 * 使用Canvas绘制类似手表的表盘，支持动画效果
 */
@Component
export struct ClockComponent {
  @Prop @Watch('onTimeChanged') currentTime: Date = new Date();
  @Prop @Watch('onStateChanged') isLanternLawActive: boolean = false;
  @Prop @Watch('onRemainingChanged') remainingMinutes: number = 0;
  @Prop clockSize: number = 300;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  onTimeChanged(): void {
    this.updateClock();
  }

  onStateChanged(): void {
    this.updateClock();
  }

  onRemainingChanged(): void {
    this.updateClock();
  }

  /**
   * 绘制表盘背景
   */
  private drawClockFace(): void {
    const ctx = this.context;
    const centerX = this.clockSize / 2;
    const centerY = this.clockSize / 2;
    const radius = this.clockSize / 2 - 10;

    // 清空画布
    ctx.clearRect(0, 0, this.clockSize, this.clockSize);

    // 绘制表盘背景
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);

    // 根据灯律状态设置不同的背景色
    if (this.isLanternLawActive) {
      // 灯律激活时：深色背景
      ctx.fillStyle = '#1a1f3a';
    } else {
      // 正常状态：午夜蓝背景
      ctx.fillStyle = '#0f1529';
    }
    ctx.fill();

    // 绘制渐变边框
    const gradient = ctx.createRadialGradient(centerX, centerY, radius * 0.8, centerX, centerY, radius);
    gradient.addColorStop(0, 'rgba(255, 209, 102, 0.1)'); // 金色
    gradient.addColorStop(1, 'rgba(255, 209, 102, 0.3)');
    ctx.strokeStyle = gradient;
    ctx.lineWidth = 3;
    ctx.stroke();

    // 绘制刻度
    this.drawTicks(centerX, centerY, radius);
  }

  /**
   * 绘制刻度
   */
  private drawTicks(centerX: number, centerY: number, radius: number): void {
    const ctx = this.context;

    for (let i = 0; i < 60; i++) {
      const angle = (i * 6) * Math.PI / 180;
      const isHour = i % 5 === 0;
      const tickLength = isHour ? 15 : 8;
      const tickWidth = isHour ? 3 : 1;

      const x1 = centerX + (radius - tickLength) * Math.cos(angle);
      const y1 = centerY + (radius - tickLength) * Math.sin(angle);
      const x2 = centerX + radius * Math.cos(angle);
      const y2 = centerY + radius * Math.sin(angle);

      ctx.beginPath();
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.lineWidth = tickWidth;
      ctx.lineCap = 'round';

      if (isHour) {
        // 小时刻度：金色
        ctx.strokeStyle = '#ffd166';
      } else {
        // 分钟刻度：深灰色
        ctx.strokeStyle = 'rgba(192, 198, 233, 0.3)';
      }
      ctx.stroke();
    }
  }

  /**
   * 绘制时钟指针
   */
  private drawClockHands(): void {
    const ctx = this.context;
    const centerX = this.clockSize / 2;
    const centerY = this.clockSize / 2;

    const hours = this.currentTime.getHours() % 12;
    const minutes = this.currentTime.getMinutes();
    const seconds = this.currentTime.getSeconds();
    const milliseconds = this.currentTime.getMilliseconds();

    // 平滑秒针（包含毫秒）
    const smoothSeconds = seconds + milliseconds / 1000;

    // 绘制时针（金色）
    const hourAngle = ((hours * 30 + minutes * 0.5) - 90) * Math.PI / 180;
    this.drawHand(centerX, centerY, hourAngle, this.clockSize * 0.25, 6, '#ffd166');

    // 绘制分针（橙色）
    const minuteAngle = ((minutes * 6 + seconds * 0.1) - 90) * Math.PI / 180;
    this.drawHand(centerX, centerY, minuteAngle, this.clockSize * 0.35, 4, '#ff9e6d');

    // 绘制秒针（透明微光）
    if (!this.isLanternLawActive) {
      const secondAngle = ((smoothSeconds * 6) - 90) * Math.PI / 180;
      this.drawHand(centerX, centerY, secondAngle, this.clockSize * 0.4, 2, 'rgba(255, 158, 109, 0.8)');
    }

    // 绘制中心圆点
    ctx.beginPath();
    ctx.arc(centerX, centerY, 8, 0, 2 * Math.PI);
    ctx.fillStyle = '#ffd166';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(centerX, centerY, 4, 0, 2 * Math.PI);
    ctx.fillStyle = '#1a1f3a';
    ctx.fill();
  }

  /**
   * 绘制指针
   */
  private drawHand(
    centerX: number,
    centerY: number,
    angle: number,
    length: number,
    width: number,
    color: string
  ): void {
    const ctx = this.context;

    ctx.beginPath();
    ctx.moveTo(centerX, centerY);
    ctx.lineTo(
      centerX + length * Math.cos(angle),
      centerY + length * Math.sin(angle)
    );
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.lineCap = 'round';
    ctx.stroke();

    // 阴影效果
    ctx.shadowColor = color;
    ctx.shadowBlur = 10;
    ctx.shadowOffsetX = 0;
    ctx.shadowOffsetY = 0;
  }

  /**
   * 绘制进度环（灯律激活时）
   */
  private drawProgressRing(remainingMinutes: number): void {
    if (!this.isLanternLawActive || remainingMinutes <= 0) {
      return;
    }

    const ctx = this.context;
    const centerX = this.clockSize / 2;
    const centerY = this.clockSize / 2;
    const radius = this.clockSize / 2 - 20;

    // 假设最大时间为8小时（480分钟）
    const maxMinutes = 480;
    const progress = Math.min(remainingMinutes / maxMinutes, 1);

    // 绘制背景环
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    ctx.strokeStyle = 'rgba(192, 198, 233, 0.1)';
    ctx.lineWidth = 4;
    ctx.stroke();

    // 绘制进度环（从12点方向开始，逆时针）
    const startAngle = -Math.PI / 2;
    const endAngle = startAngle - (2 * Math.PI * progress);

    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
    ctx.strokeStyle = '#ffd166';
    ctx.lineWidth = 4;
    ctx.lineCap = 'round';

    // 渐变效果
    const gradient = ctx.createLinearGradient(0, 0, this.clockSize, this.clockSize);
    gradient.addColorStop(0, '#ffd166');
    gradient.addColorStop(1, '#ff9e6d');
    ctx.strokeStyle = gradient;

    ctx.stroke();
  }

  build() {
    Column() {
      Canvas(this.context)
        .width(this.clockSize)
        .height(this.clockSize)
        .onReady(() => {
          this.updateClock();
        })
    }
    .width(this.clockSize)
    .height(this.clockSize)
  }

  /**
   * 更新时钟显示
   */
  updateClock(): void {
    // 清空画布
    this.drawClockFace();
    this.drawClockHands();
    if (this.isLanternLawActive && this.remainingMinutes > 0) {
      this.drawProgressRing(this.remainingMinutes);
    }
  }
}
