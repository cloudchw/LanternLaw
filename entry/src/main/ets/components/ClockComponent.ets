/**
 * 高端表盘组件
 * Premium Clock Component
 * 精致的模拟表盘设计，采用多层视觉效果
 */

interface ClockColorScheme {
  gold: string;
  goldLight: string;
  goldDark: string;
  orange: string;
  background: string;
  backgroundDark: string;
  text: string;
  textDim: string;
}

class ClockColors implements ClockColorScheme {
  gold: string = '#ffd166';
  goldLight: string = '#ffe4a0';
  goldDark: string = '#cc9a33';
  orange: string = '#ff9e6d';
  background: string = '#0f1529';
  backgroundDark: string = '#0a0e1f';
  text: string = '#c0c6e9';
  textDim: string = 'rgba(192, 198, 233, 0.3)';
}

@Component
export struct ClockComponent {
  @Prop @Watch('onTimeChanged') currentTime: Date = new Date();
  @Prop @Watch('onStateChanged') isLanternLawActive: boolean = false;
  @Prop @Watch('onRemainingChanged') remainingMinutes: number = 0;
  @Prop clockSize: number = 300;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private readonly COLORS: ClockColors = new ClockColors();

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
   * 绘制表盘背景 - 多层次精致设计
   */
  private drawClockFace(): void {
    const ctx = this.context;
    const centerX = this.clockSize / 2;
    const centerY = this.clockSize / 2;
    const radius = this.clockSize / 2 - 10;

    ctx.clearRect(0, 0, this.clockSize, this.clockSize);

    // 最外层光晕
    const outerGlow = ctx.createRadialGradient(centerX, centerY, radius * 0.9, centerX, centerY, radius + 10);
    outerGlow.addColorStop(0, 'rgba(255, 209, 102, 0)');
    outerGlow.addColorStop(0.5, 'rgba(255, 209, 102, 0.05)');
    outerGlow.addColorStop(1, 'rgba(255, 209, 102, 0)');
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius + 10, 0, 2 * Math.PI);
    ctx.fillStyle = outerGlow;
    ctx.fill();

    // 外圈装饰环
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    const outerRingGradient = ctx.createLinearGradient(0, 0, this.clockSize, this.clockSize);
    outerRingGradient.addColorStop(0, 'rgba(255, 209, 102, 0.4)');
    outerRingGradient.addColorStop(0.5, 'rgba(255, 209, 102, 0.1)');
    outerRingGradient.addColorStop(1, 'rgba(255, 209, 102, 0.3)');
    ctx.strokeStyle = outerRingGradient;
    ctx.lineWidth = 2;
    ctx.stroke();

    // 主表盘背景 - 深邃渐变
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius - 4, 0, 2 * Math.PI);
    const bgGradient = ctx.createRadialGradient(centerX, centerY * 0.8, 0, centerX, centerY, radius);
    if (this.isLanternLawActive) {
      bgGradient.addColorStop(0, '#1a2040');
      bgGradient.addColorStop(0.5, '#141830');
      bgGradient.addColorStop(1, '#0a0e1f');
    } else {
      bgGradient.addColorStop(0, '#1a1f3a');
      bgGradient.addColorStop(0.5, '#0f1529');
      bgGradient.addColorStop(1, '#0a0e1f');
    }
    ctx.fillStyle = bgGradient;
    ctx.fill();

    // 内圈装饰线
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius * 0.85, 0, 2 * Math.PI);
    ctx.strokeStyle = 'rgba(255, 209, 102, 0.08)';
    ctx.lineWidth = 1;
    ctx.stroke();

    // 绘制刻度
    this.drawTicks(centerX, centerY, radius);

    // 绘制品牌标识
    this.drawBrand(centerX, centerY, radius);
  }

  /**
   * 绘制精致刻度
   */
  private drawTicks(centerX: number, centerY: number, radius: number): void {
    const ctx = this.context;

    // 绘制小时刻度和数字
    for (let i = 0; i < 12; i++) {
      const angle = (i * 30 - 90) * Math.PI / 180;

      // 小时刻度 - 粗金色条
      const tickOuterX = centerX + (radius - 8) * Math.cos(angle);
      const tickOuterY = centerY + (radius - 8) * Math.sin(angle);
      const tickInnerX = centerX + (radius - 22) * Math.cos(angle);
      const tickInnerY = centerY + (radius - 22) * Math.sin(angle);

      ctx.beginPath();
      ctx.moveTo(tickInnerX, tickInnerY);
      ctx.lineTo(tickOuterX, tickOuterY);
      ctx.strokeStyle = this.COLORS.gold;
      ctx.lineWidth = 3;
      ctx.lineCap = 'round';
      ctx.stroke();

      // 刻度末端小光点
      ctx.beginPath();
      ctx.arc(tickOuterX, tickOuterY, 2, 0, 2 * Math.PI);
      ctx.fillStyle = this.COLORS.goldLight;
      ctx.fill();
    }

    // 绘制分钟刻度
    for (let i = 0; i < 60; i++) {
      if (i % 5 !== 0) {
        const angle = (i * 6 - 90) * Math.PI / 180;
        const tickOuterX = centerX + (radius - 8) * Math.cos(angle);
        const tickOuterY = centerY + (radius - 8) * Math.sin(angle);
        const tickInnerX = centerX + (radius - 14) * Math.cos(angle);
        const tickInnerY = centerY + (radius - 14) * Math.sin(angle);

        ctx.beginPath();
        ctx.moveTo(tickInnerX, tickInnerY);
        ctx.lineTo(tickOuterX, tickOuterY);
        ctx.strokeStyle = this.COLORS.textDim;
        ctx.lineWidth = 1;
        ctx.lineCap = 'round';
        ctx.stroke();
      }
    }
  }

  /**
   * 绘制品牌标识
   */
  private drawBrand(centerX: number, centerY: number, radius: number): void {
    const ctx = this.context;

    // 品牌名
    ctx.font = '10px sans-serif';
    ctx.fillStyle = 'rgba(255, 209, 102, 0.6)';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('LANTERN', centerX, centerY - radius * 0.35);

    // 装饰线
    ctx.beginPath();
    ctx.moveTo(centerX - 25, centerY - radius * 0.28);
    ctx.lineTo(centerX + 25, centerY - radius * 0.28);
    ctx.strokeStyle = 'rgba(255, 209, 102, 0.2)';
    ctx.lineWidth = 1;
    ctx.stroke();
  }

  /**
   * 绘制精致指针
   */
  private drawClockHands(): void {
    const ctx = this.context;
    const centerX = this.clockSize / 2;
    const centerY = this.clockSize / 2;
    const radius = this.clockSize / 2 - 10;

    const hours = this.currentTime.getHours() % 12;
    const minutes = this.currentTime.getMinutes();
    const seconds = this.currentTime.getSeconds();
    const milliseconds = this.currentTime.getMilliseconds();
    const smoothSeconds = seconds + milliseconds / 1000;

    // 时针角度
    const hourAngle = ((hours * 30 + minutes * 0.5) - 90) * Math.PI / 180;
    // 分针角度
    const minuteAngle = ((minutes * 6 + seconds * 0.1) - 90) * Math.PI / 180;
    // 秒针角度
    const secondAngle = ((smoothSeconds * 6) - 90) * Math.PI / 180;

    // 绘制时针阴影
    ctx.save();
    ctx.shadowColor = 'rgba(255, 209, 102, 0.3)';
    ctx.shadowBlur = 8;
    this.drawPremiumHand(centerX, centerY, hourAngle, radius * 0.45, 5, this.COLORS.gold, this.COLORS.goldDark);
    ctx.restore();

    // 绘制分针阴影
    ctx.save();
    ctx.shadowColor = 'rgba(255, 158, 109, 0.3)';
    ctx.shadowBlur = 6;
    this.drawPremiumHand(centerX, centerY, minuteAngle, radius * 0.65, 3.5, this.COLORS.orange, '#cc7a4d');
    ctx.restore();

    // 绘制秒针（非灯律状态）
    if (!this.isLanternLawActive) {
      ctx.save();
      ctx.shadowColor = 'rgba(255, 209, 102, 0.5)';
      ctx.shadowBlur = 4;
      this.drawSecondHand(centerX, centerY, secondAngle, radius * 0.75);
      ctx.restore();
    }

    // 中心装饰
    this.drawCenterCap(centerX, centerY);
  }

  /**
   * 绘制精致指针
   */
  private drawPremiumHand(
    centerX: number,
    centerY: number,
    angle: number,
    length: number,
    width: number,
    color: string,
    shadowColor: string
  ): void {
    const ctx = this.context;

    // 指针主体 - 渐变效果
    const tipX = centerX + length * Math.cos(angle);
    const tipY = centerY + length * Math.sin(angle);
    const baseX = centerX - length * 0.15 * Math.cos(angle);
    const baseY = centerY - length * 0.15 * Math.sin(angle);

    // 指针形状 - 菱形设计
    ctx.beginPath();
    ctx.moveTo(tipX, tipY);
    ctx.lineTo(
      centerX + width * 0.5 * Math.cos(angle + Math.PI / 2),
      centerY + width * 0.5 * Math.sin(angle + Math.PI / 2)
    );
    ctx.lineTo(baseX, baseY);
    ctx.lineTo(
      centerX + width * 0.5 * Math.cos(angle - Math.PI / 2),
      centerY + width * 0.5 * Math.sin(angle - Math.PI / 2)
    );
    ctx.closePath();

    // 渐变填充
    const gradient = ctx.createLinearGradient(baseX, baseY, tipX, tipY);
    gradient.addColorStop(0, shadowColor);
    gradient.addColorStop(0.5, color);
    gradient.addColorStop(1, color);
    ctx.fillStyle = gradient;
    ctx.fill();
  }

  /**
   * 绘制秒针 - 精致细线
   */
  private drawSecondHand(
    centerX: number,
    centerY: number,
    angle: number,
    length: number
  ): void {
    const ctx = this.context;

    // 秒针尾部
    const tailLength = length * 0.2;
    const tailX = centerX - tailLength * Math.cos(angle);
    const tailY = centerY - tailLength * Math.sin(angle);

    // 秒针主体
    const tipX = centerX + length * Math.cos(angle);
    const tipY = centerY + length * Math.sin(angle);

    ctx.beginPath();
    ctx.moveTo(tailX, tailY);
    ctx.lineTo(tipX, tipY);
    ctx.strokeStyle = this.COLORS.gold;
    ctx.lineWidth = 1.5;
    ctx.lineCap = 'round';
    ctx.stroke();

    // 秒针末端圆点
    ctx.beginPath();
    ctx.arc(tipX, tipY, 3, 0, 2 * Math.PI);
    ctx.fillStyle = this.COLORS.gold;
    ctx.fill();
  }

  /**
   * 绘制中心装饰盖
   */
  private drawCenterCap(centerX: number, centerY: number): void {
    const ctx = this.context;

    // 外圈 - 金色
    ctx.beginPath();
    ctx.arc(centerX, centerY, 10, 0, 2 * Math.PI);
    const capGradient = ctx.createRadialGradient(centerX - 2, centerY - 2, 0, centerX, centerY, 10);
    capGradient.addColorStop(0, this.COLORS.goldLight);
    capGradient.addColorStop(0.5, this.COLORS.gold);
    capGradient.addColorStop(1, this.COLORS.goldDark);
    ctx.fillStyle = capGradient;
    ctx.fill();

    // 内圈 - 深色
    ctx.beginPath();
    ctx.arc(centerX, centerY, 5, 0, 2 * Math.PI);
    ctx.fillStyle = this.COLORS.backgroundDark;
    ctx.fill();

    // 最内圈光点
    ctx.beginPath();
    ctx.arc(centerX - 1, centerY - 1, 2, 0, 2 * Math.PI);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
    ctx.fill();
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
    const radius = this.clockSize / 2 - 25;

    const maxMinutes = 480;
    const progress = Math.min(remainingMinutes / maxMinutes, 1);

    // 背景轨道
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
    ctx.strokeStyle = 'rgba(255, 209, 102, 0.08)';
    ctx.lineWidth = 3;
    ctx.stroke();

    // 进度弧线
    const startAngle = -Math.PI / 2;
    const endAngle = startAngle + (2 * Math.PI * progress);

    ctx.beginPath();
    ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);

    const gradient = ctx.createLinearGradient(
      centerX - radius, centerY,
      centerX + radius, centerY
    );
    gradient.addColorStop(0, this.COLORS.gold);
    gradient.addColorStop(0.5, this.COLORS.goldLight);
    gradient.addColorStop(1, this.COLORS.orange);
    ctx.strokeStyle = gradient;
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.stroke();

    // 进度末端光点
    const dotX = centerX + radius * Math.cos(endAngle);
    const dotY = centerY + radius * Math.sin(endAngle);
    ctx.beginPath();
    ctx.arc(dotX, dotY, 4, 0, 2 * Math.PI);
    ctx.fillStyle = this.COLORS.goldLight;
    ctx.fill();
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
    this.drawClockFace();
    if (this.isLanternLawActive && this.remainingMinutes > 0) {
      this.drawProgressRing(this.remainingMinutes);
    }
    this.drawClockHands();
  }
}
