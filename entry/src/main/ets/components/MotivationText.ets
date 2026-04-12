/**
 * 激励文本组件
 * Motivation Text Component
 * 显示状态相关的激励文案，采用优雅的淡入淡出效果
 */

/**
 * 激励文案库接口
 */
interface MessageLibrary {
  idle: string[];
  active: string[];
  overridden: string[];
  success: string[];
  milestone: string[];
}

/**
 * 配色方案接口
 */
interface ColorScheme {
  idle: string;
  active: string;
  overridden: string;
  gold: string;
  accent: string;
  dim: string;
}

@Component
export struct MotivationText {
  @Prop lanternLawState: string = 'idle'; // 'idle' | 'active' | 'overridden'
  @Prop currentStreak: number = 0;
  @Prop timeUntilWakeup: number = 0; // 分钟
  @Prop animated: boolean = true;

  // 配色方案
  private readonly COLORS: ColorScheme = {
    idle: '#c0c6e9',        // 静止状态：淡蓝
    active: '#ffd166',      // 激活状态：暖金
    overridden: '#ff9e6d',  // 越狱状态：橙红
    gold: '#ffd166',        // 金色徽章
    accent: '#ffffff',
    dim: 'rgba(192, 198, 233, 0.4)'
  };

  // 激励文案库
  private readonly MESSAGES: MessageLibrary = {
    idle: [
      '放松一下，美好即將开始',
      '今晚，守护你的专注时光',
      '准备好点亮今晚的灯光了吗？',
      '宁静的夜晚，是你成长的最佳伴侣',
      '每一盏点亮的小灯，都是对自己的承诺'
    ],
    active: [
      '星光已亮，愿今夜宁静而充实',
      '此刻，你在为自己的成长积累光芒',
      '坚持下去，星光会越来越明亮',
      '每一分钟的专注，都是内心的沉淀',
      '夜深人静时，最是成长好时光'
    ],
    overridden: [
      '偶尔的路过也无妨，明日重新来过',
      '熄灭星光，是为了明日更明亮的光芒',
      '今晚的休息，是为了积蓄明天的力量',
      '接受不完美，也是成长的一部分',
      '即使星光熄灭，心中的光依然存在'
    ],
    success: [
      '昨夜的坚持，让你变得更强大',
      '这盏小灯，记录了你的自律时光',
      '每一灯点亮，都是时光的勋章',
      '连续坚持，你的光芒越来越耀眼',
      '你的努力，正在变成星辰'
    ],
    milestone: [
      '恭喜你！这个里程碑值得庆祝',
      '你的坚持让提灯熠熠生辉',
      '这一刻，为你的自律鼓掌'
    ]
  };

  build() {
    Column() {
      // 动态文本内容
      Text(this.getCurrentMessage())
        .fontSize(15)
        .fontColor(this.getTextColor())
        .fontWeight(FontWeight.Normal)
        .lineHeight(24)
        .letterSpacing(0.3)
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding({ left: 24, right: 24 })
        .animation({
          duration: 500,
          curve: Curve.EaseInOut,
          iterations: this.animated ? 1 : 0
        })

      // 状态指示器（微妙）
      if (this.lanternLawState !== 'idle') {
        Row() {
          Circle()
            .width(6)
            .height(6)
            .fill(this.getDotColor())
            .opacity(this.lanternLawState === 'active' ? 0.8 : 0.5)

          if (this.lanternLawState === 'active' && this.timeUntilWakeup > 0) {
            Text(`${this.formatTimeRemaining(this.timeUntilWakeup)}后解锁`)
              .fontSize(11)
              .fontColor(this.COLORS.dim)
              .margin({ left: 8 })
          }
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 12 })
        .opacity(0.6)
      }

      // 连续天数徽章（仅在白天或里程碑时显示）
      if (this.shouldShowStreak()) {
        this.StreakBadge(this.currentStreak)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private StreakBadge(streak: number): void {
    Row() {
      Text('🔥')
        .fontSize(12)
        .margin({ right: 4 })

      Text(`连续${streak}天`)
        .fontSize(11)
        .fontColor(this.COLORS.gold)
        .fontWeight(FontWeight.Medium)

      if (streak >= 7) {
        Text('✨')
          .fontSize(12)
          .margin({ left: 4 })
      }
    }
    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
    .backgroundColor('rgba(255, 209, 102, 0.1)')
    .borderRadius(12)
    .margin({ top: 12 })
  }

  /**
   * 获取当前应该显示的消息
   */
  private getCurrentMessage(): string {
    let messages: string[];
    if (this.lanternLawState === 'idle') messages = this.MESSAGES.idle;
    else if (this.lanternLawState === 'active') messages = this.MESSAGES.active;
    else if (this.lanternLawState === 'overridden') messages = this.MESSAGES.overridden;
    else if (this.lanternLawState === 'success') messages = this.MESSAGES.success;
    else if (this.lanternLawState === 'milestone') messages = this.MESSAGES.milestone;
    else messages = this.MESSAGES.idle;
    // 使用哈希值选择固定消息，避免频繁切换
    const index = this.getMessageIndex();
    return messages[index];
  }

  /**
   * 获取消息索引（基于日期的哈希）
   */
  private getMessageIndex(): number {
    const today = new Date();
    const dayStr = `${today.getFullYear()}-${today.getMonth()}-${today.getDate()}`;
    let hash = 0;
    for (let i = 0; i < dayStr.length; i++) {
      hash = ((hash << 5) - hash) + dayStr.charCodeAt(i);
      hash = hash & hash; // 转换为32位整数
    }
    let messages: string[];
    if (this.lanternLawState === 'idle') messages = this.MESSAGES.idle;
    else if (this.lanternLawState === 'active') messages = this.MESSAGES.active;
    else if (this.lanternLawState === 'overridden') messages = this.MESSAGES.overridden;
    else if (this.lanternLawState === 'success') messages = this.MESSAGES.success;
    else if (this.lanternLawState === 'milestone') messages = this.MESSAGES.milestone;
    else messages = this.MESSAGES.idle;
    return Math.abs(hash) % messages.length;
  }

  /**
   * 获取文本颜色
   */
  private getTextColor(): string {
    if (this.lanternLawState === 'idle') return this.COLORS.idle;
    if (this.lanternLawState === 'active') return this.COLORS.active;
    if (this.lanternLawState === 'overridden') return this.COLORS.overridden;
    return this.COLORS.idle;
  }

  /**
   * 获取指示点颜色
   */
  private getDotColor(): string {
    if (this.lanternLawState === 'overridden') {
      return this.COLORS.overridden;
    }
    return this.COLORS.active;
  }

  /**
   * 格式化剩余时间
   */
  private formatTimeRemaining(minutes: number): string {
    if (minutes <= 0) return '';

    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;

    if (hours > 0) {
      return `${hours}小时${mins > 0 ? mins + '分' : ''}`;
    }
    return `${mins}分钟`;
  }

  /**
   * 是否显示连续天数徽章
   */
  private shouldShowStreak(): boolean {
    // 只有在白天（非激活的灯律状态）且有连续天数时显示
    if (this.lanternLawState === 'active') {
      return false;
    }
    return this.currentStreak > 0;
  }
}

/**
 * 简洁状态彩色方案接口
 */
interface SimpleColorScheme {
  idle: string;
  active: string;
  overridden: string;
}

/**
 * 简洁状态标签接口
 */
interface SimpleLabelScheme {
  idle: string;
  active: string;
  overridden: string;
}

/**
 * 简洁状态图标接口
 */
interface SimpleIconScheme {
  idle: string;
  active: string;
  overridden: string;
}

/**
 * 简洁状态文本组件
 * Simple Status Text
 * 用于在标题栏或紧凑区域显示状态
 */
@Component
export struct SimpleStatusText {
  @Prop lanternLawState: string = 'idle';
  @Prop showIcon: boolean = true;

  private readonly COLORS: SimpleColorScheme = {
    idle: '#c0c6e9',
    active: '#ffd166',
    overridden: '#ff9e6d'
  };

  private readonly LABELS: SimpleLabelScheme = {
    idle: '未激活',
    active: '灯律执行中',
    overridden: '已越狱'
  };

  private readonly ICONS: SimpleIconScheme = {
    idle: '○',
    active: '●',
    overridden: '○'
  };

  build() {
    Row() {
      if (this.showIcon) {
        Text(this.getSimpleIcon())
          .fontSize(10)
          .fontColor(this.getSimpleColor())
          .margin({ right: 6 })
      }

      Text(this.getSimpleLabel())
        .fontSize(12)
        .fontColor(this.getSimpleColor())
        .fontWeight(FontWeight.Medium)
    }
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 获取状态颜色
   */
  getStatusColor(): string {
    if (this.lanternLawState === 'idle') return this.COLORS.idle;
    if (this.lanternLawState === 'active') return this.COLORS.active;
    if (this.lanternLawState === 'overridden') return this.COLORS.overridden;
    return this.COLORS.idle;
  }

  /**
   * 获取状态标签
   */
  getStatusLabel(): string {
    return this.getSimpleLabel();
  }

  /**
   * 获取简单的图标
   */
  private getSimpleIcon(): string {
    if (this.lanternLawState === 'idle') return this.ICONS.idle;
    if (this.lanternLawState === 'active') return this.ICONS.active;
    if (this.lanternLawState === 'overridden') return this.ICONS.overridden;
    return this.ICONS.idle;
  }

  /**
   * 获取简单的颜色
   */
  private getSimpleColor(): string {
    if (this.lanternLawState === 'idle') return this.COLORS.idle;
    if (this.lanternLawState === 'active') return this.COLORS.active;
    if (this.lanternLawState === 'overridden') return this.COLORS.overridden;
    return this.COLORS.idle;
  }

  /**
   * 获取简单的标签
   */
  private getSimpleLabel(): string {
    if (this.lanternLawState === 'idle') return this.LABELS.idle;
    if (this.lanternLawState === 'active') return this.LABELS.active;
    if (this.lanternLawState === 'overridden') return this.LABELS.overridden;
    return this.LABELS.idle;
  }
}

/**
 * 时间问候语集合接口
 */
interface GreetingCollection {
  morning: string[];
  afternoon: string[];
  evening: string[];
  night: string[];
}

/**
 * 时间问候组件
 * Time Greeting Component
 * 根据当前时间显示不同的问候语
 */
@Component
export struct TimeGreeting {
  @Prop currentTime: Date = new Date();

  private readonly GREETINGS: GreetingCollection = {
    morning: ['早安', '新的一天开始了', '愿你今日充实'],
    afternoon: ['下午好', '继续加油', '保持专注'],
    evening: ['晚上好', '夜晚是沉淀的好时光', '让心静下来'],
    night: ['夜深了', '注意休息', '愿你安眠']
  };

  build() {
    Column() {
      Text(this.getTimeOfDay())
        .fontSize(13)
        .fontColor('rgba(192, 198, 233, 0.5)')
        .margin({ bottom: 2 })

      Text(this.getGreetingMessage())
        .fontSize(18)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Medium)
        .lineHeight(26)
    }
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 获取时段标签
   */
  private getTimeOfDay(): string {
    const hour = this.currentTime.getHours();

    if (hour >= 5 && hour < 9) {
      return '清晨';
    } else if (hour >= 9 && hour < 12) {
      return '上午';
    } else if (hour >= 12 && hour < 14) {
      return '中午';
    } else if (hour >= 14 && hour < 18) {
      return '下午';
    } else if (hour >= 18 && hour < 22) {
      return '晚上';
    } else {
      return '深夜';
    }
  }

  /**
   * 获取问候语
   */
  private getGreetingMessage(): string {
    const hour = this.currentTime.getHours();
    const greetings = this.getAppropriateGreeting(hour);
    const day = new Date();
    const dateStr = `${day.getFullYear()}-${day.getMonth()}-${day.getDate()}`;
    let hash = 0;
    for (let i = 0; i < dateStr.length; i++) {
      hash = ((hash << 5) - hash) + dateStr.charCodeAt(i);
      hash = hash & hash;
    }
    return greetings[Math.abs(hash) % greetings.length];
  }

  /**
   * 根据小时获取相应的问候语集合
   */
  private getAppropriateGreeting(hour: number): string[] {
    if (hour >= 5 && hour < 12) {
      return this.GREETINGS.morning;
    } else if (hour >= 12 && hour < 18) {
      return this.GREETINGS.afternoon;
    } else if (hour >= 18 && hour < 23) {
      return this.GREETINGS.evening;
    } else {
      return this.GREETINGS.night;
    }
  }
}