/**
 * 我的 Tab - LanternLaw
 * 个人设置页面
 */
import { Logger } from '../utils/Logger';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { WhitelistApp } from '../models/WhitelistApp';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';
import { ScreenTimeGuardManager } from '../services/ScreenTimeGuardManager';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';

interface ProfileColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

@Component
export struct ProfileTab {
  @State lanternlawEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;
  // 时间段状态
  @State timeRanges: TimeRange[] = [];
  @State showTimePicker: boolean = false;
  @State editingTimeRange: TimeRange | null = null;
  @State newTimeRangeLabel: string = '';
  @State newStartTime: string = '22:00';
  @State newEndTime: string = '06:00';
  @State timePickerError: string = '';
  // TimePicker 选中值
  @State startHour: number = 22;
  @State startMinute: number = 0;
  @State endHour: number = 6;
  @State endMinute: number = 0;
  // 白名单应用状态
  @State whitelistApps: WhitelistApp[] = [];
  @State showDeleteConfirm: boolean = false;
  @State deleteAppIndex: number = -1;
  @State showDeleteTimeRangeConfirm: boolean = false;
  @State deleteTimeRangeId: string = '';

  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private static readonly COLORS: ProfileColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)'
  };

  aboutToAppear() {
    Logger.info('ProfileTab', '我的 Tab 初始化');
    this.loadConfig();
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

      // 内容区域
      Column() {
        // 标题栏
        Row() {
          Text('我的设置')
            .fontSize(24)
            .fontColor(ProfileTab.COLORS.text)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        // 可滚动内容
        Scroll() {
          Column() {
            this.GlobalSwitchCard()
            this.TimeManagementCard()
            this.WhitelistCard()
            this.NotificationCard()
            this.AboutCard()
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

      // 删除确认对话框
      if (this.showDeleteConfirm) {
        Column() {
          Column() {
            this.DeleteConfirmDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDeleteConfirm = false;
          this.deleteAppIndex = -1;
        })
      }

      // 时间段选择器对话框
      if (this.showTimePicker) {
        Column() {
          Column() {
            this.TimePickerDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.closeTimePicker();
        })
      }

      // 删除时间段确认对话框
      if (this.showDeleteTimeRangeConfirm) {
        Column() {
          Column() {
            this.DeleteTimeRangeConfirmDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showDeleteTimeRangeConfirm = false;
          this.deleteTimeRangeId = '';
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 全局开关卡片
   */
  @Builder
  private GlobalSwitchCard(): void {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text(this.lanternlawEnabled ? '启用掌灯人' : '停用掌灯人')
            .fontSize(16)
            .fontColor(this.lanternlawEnabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
            .fontWeight(FontWeight.Medium)
          Text(this.lanternlawEnabled ? '灯律保护已开启' : '点击右侧开关启用')
            .fontSize(12)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 开关按钮
        Row() {
          Column()
            .width(24)
            .height(24)
            .borderRadius(12)
            .backgroundColor(this.lanternlawEnabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            Text(this.lanternlawEnabled ? '✓' : '')
              .fontSize(14)
              .fontColor(ProfileTab.COLORS.background)
              .fontWeight(FontWeight.Bold)
        }
        .width(50)
        .height(28)
        .borderRadius(14)
        .backgroundColor(this.lanternlawEnabled ? 'rgba(255, 209, 102, 0.2)' : 'rgba(192, 198, 233, 0.1)')
        .justifyContent(FlexAlign.End)
        .padding({ right: 2 })
        .onClick(() => {
          this.toggleGlobalSwitch();
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.lanternlawEnabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 时间管理卡片
   */
  @Builder
  private TimeManagementCard(): void {
    Column() {
      Row() {
        Text('⏰')
          .fontSize(18)
          .margin({ right: 12 })
        Text('时间管理')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        // 添加时间段按钮
        Text('+')
          .fontSize(24)
          .fontColor(ProfileTab.COLORS.gold)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            this.openTimePicker();
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 时间段列表
      if (this.timeRanges.length === 0) {
        Column() {
          Text('暂无时间段设置')
            .fontSize(13)
            .fontColor(ProfileTab.COLORS.textDim)
            .margin({ top: 8, bottom: 8 })
          Text('点击右上角 + 添加灯律时间段')
            .fontSize(11)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      } else {
        ForEach(this.timeRanges, (timeRange: TimeRange, index: number) => {
          Row() {
            Column({ space: 4 }) {
              Text(timeRange.label)
                .fontSize(14)
                .fontColor(timeRange.enabled ? ProfileTab.COLORS.text : ProfileTab.COLORS.textDim)
                .fontWeight(FontWeight.Medium)
              Text(TimeRangeManager.formatDisplay(timeRange))
                .fontSize(12)
                .fontColor(ProfileTab.COLORS.textDim)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Blank()

            // 删除按钮
            Text('删除')
              .fontSize(11)
              .fontColor('#ff6b6b')
              .onClick(() => {
                this.showDeleteTimeRangeDialog(timeRange.id);
              })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.editTimeRange(timeRange);
          })
        }, (timeRange: TimeRange, index: number) => `${timeRange.id}_${timeRange.startTime}_${timeRange.endTime}_${timeRange.label}`)
      }

      Text('点击时间段编辑，左键切换启用状态')
        .fontSize(11)
        .fontColor(ProfileTab.COLORS.textDim)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 时间段选择器对话框
   */
  @Builder
  private TimePickerDialog(): void {
    Column() {
      // 标题
      Text(this.editingTimeRange ? '编辑时间段' : '添加管控时间段')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      // 标签输入
      Row() {
        Text('标签')
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
          .width(60)
        TextInput({ placeholder: '如: 夜间休息', text: this.newTimeRangeLabel })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.newTimeRangeLabel = value;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 24 })

      // 时间选择器区域 — 双列滚轮
      Row() {
        // 开始时间列
        Column() {
          Text('开始时间')
            .fontSize(16)
            .fontColor(ProfileTab.COLORS.text)
            .margin({ bottom: 8 })
          TimePicker({
            selected: new Date(1970, 0, 1, this.startHour, this.startMinute)
          })
            .useMilitaryTime(true)
            .selectedTextStyle({ color: ProfileTab.COLORS.gold })
            .disappearTextStyle({ color: ProfileTab.COLORS.textDim })
            .textStyle({ color: ProfileTab.COLORS.text })
            .onChange((value: TimePickerResult) => {
              this.startHour = value.hour;
              this.startMinute = value.minute;
              this.newStartTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Column()
          .width(1)
          .height(120)
          .backgroundColor(ProfileTab.COLORS.border)
          .margin({ left: 12, right: 12 })

        // 结束时间列
        Column() {
          Text('结束时间')
            .fontSize(16)
            .fontColor(ProfileTab.COLORS.text)
            .margin({ bottom: 8 })
          TimePicker({
            selected: new Date(1970, 0, 1, this.endHour, this.endMinute)
          })
            .useMilitaryTime(true)
            .selectedTextStyle({ color: ProfileTab.COLORS.gold })
            .disappearTextStyle({ color: ProfileTab.COLORS.textDim })
            .textStyle({ color: ProfileTab.COLORS.text })
            .onChange((value: TimePickerResult) => {
              this.endHour = value.hour;
              this.endMinute = value.minute;
              this.newEndTime = `${value.hour.toString().padStart(2, '0')}:${value.minute.toString().padStart(2, '0')}`;
            })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })

      // 管控时长提示
      Text(this.getDurationHint())
        .fontSize(16)
        .fontColor(ProfileTab.COLORS.text)
        .margin({ top: 8, bottom: 4 })

      // 错误提示
      if (this.timePickerError) {
        Text(this.timePickerError)
          .fontSize(12)
          .fontColor(ProfileTab.COLORS.orange)
          .margin({ top: 8, bottom: 8 })
      }

      // 按钮行
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.closeTimePicker();
          })

        Button('确认')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.saveTimeRange();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('88%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(20)
    .padding(24)
  }

  /**
   * 计算管控时长提示文本
   */
  private getDurationHint(): string {
    const startTotal = this.startHour * 60 + this.startMinute;
    const endTotal = this.endHour * 60 + this.endMinute;
    const isCrossDay = endTotal <= startTotal;

    let durationMin: number;
    if (isCrossDay) {
      durationMin = (24 * 60 - startTotal) + endTotal;
    } else {
      durationMin = endTotal - startTotal;
    }

    if (durationMin === 0) {
      return '管控时长：0 分钟';
    }

    const hours = Math.floor(durationMin / 60);
    const mins = durationMin % 60;

    let hint = '管控时长：';
    if (hours > 0) {
      hint += `${hours} 小时`;
    }
    if (mins > 0) {
      if (hours > 0) hint += ' ';
      hint += `${mins} 分钟`;
    }

    if (isCrossDay && hours > 0) {
      hint += '（跨天）';
    }

    return hint;
  }

  /**
   * 删除时间段确认对话框
   */
  @Builder
  private DeleteTimeRangeConfirmDialog(): void {
    Column() {
      Text('确认删除')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Text('确定要删除这个时间段吗？')
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.textDim)
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showDeleteTimeRangeConfirm = false;
            this.deleteTimeRangeId = '';
          })

        Button('删除')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.orange)
          .fontColor('#ffffff')
          .borderRadius(8)
          .onClick(() => {
            this.confirmDeleteTimeRange();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('70%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(16)
    .padding(20)
  }

  /**
   * 白名单卡片
   */
  @Builder
  private WhitelistCard(): void {
    Column() {
      Row() {
        Text('📱')
          .fontSize(18)
          .margin({ right: 12 })
        Text('白名单应用')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('管理')
          .fontSize(12)
          .height(28)
          .backgroundColor(ProfileTab.COLORS.accent)
          .fontColor(ProfileTab.COLORS.gold)
          .borderRadius(14)
          .margin({ right: 8 })
          .onClick(() => {
            this.openAppPicker();
          })
        if (this.whitelistApps.length > 0) {
          Button('查看')
            .fontSize(12)
            .height(28)
            .backgroundColor('rgba(255, 158, 109, 0.15)')
            .fontColor(ProfileTab.COLORS.orange)
            .borderRadius(14)
            .onClick(() => {
              this.viewSelectedApps();
            })
        }
      }
      .width('100%')
      .padding({ bottom: 12 })

      // 白名单统计
      if (this.whitelistApps.length > 0) {
        Column() {
          Text(`管控时段内，${this.whitelistApps.length}个白名单应用可用`)
            .fontSize(13)
            .fontColor(ProfileTab.COLORS.text)
            .margin({ bottom: 10 })

          Text('点击「管理」选择/修改白名单应用')
            .fontSize(11)
            .fontColor(ProfileTab.COLORS.textDim)
            .margin({ top: 8 })
          Text('点击「查看」预览已选应用详情')
            .fontSize(11)
            .fontColor(ProfileTab.COLORS.textDim)
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 4, bottom: 8 })
      } else {
        Column() {
          Text('暂无白名单应用')
            .fontSize(13)
            .fontColor(ProfileTab.COLORS.textDim)
            .margin({ bottom: 4 })
          Text('点击「管理」按钮选择允许使用的应用')
            .fontSize(11)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 4, bottom: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 删除确认对话框
   */
  @Builder
  private DeleteConfirmDialog(): void {
    Column() {
      Text('确认删除')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      Text(`确定要从白名单中移除 "应用 ${this.deleteAppIndex + 1}" 吗？`)
        .fontSize(14)
        .fontColor(ProfileTab.COLORS.textDim)
        .margin({ bottom: 20 })

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showDeleteConfirm = false;
            this.deleteAppIndex = -1;
          })

        Button('删除')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.orange)
          .fontColor('#ffffff')
          .borderRadius(8)
          .onClick(() => {
            this.confirmDeleteApp();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('70%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(16)
    .padding(20)
  }

  /**
   * 提醒设置卡片
   */
  @Builder
  private NotificationCard(): void {
    Column() {
      Row() {
        Text('🔔')
          .fontSize(18)
          .margin({ right: 12 })
        Text('提醒设置')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 睡前提醒
      this.SwitchItem('睡前提醒', '15 分钟', true)
      // 起床后提醒
      this.SwitchItem('起床后提醒', '自动', true)
      // 越狱通知
      this.SwitchItem('越狱通知', '即时', false)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 开关设置项
   */
  @Builder
  private SwitchItem(label: string, description: string, enabled: boolean): void {
    Row() {
      Column({ space: 4 }) {
        Text(label)
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
        Text(description)
          .fontSize(11)
          .fontColor(ProfileTab.COLORS.textDim)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      // 模拟开关
      Column()
        .width(44)
        .height(24)
        .backgroundColor(enabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
        .borderRadius(12)
        .justifyContent(FlexAlign.Start)
        .padding({ left: 2 })
        .onClick(() => {
          Logger.info('ProfileTab', `切换开关: ${label}`);
        })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
  }

  /**
   * 关于卡片
   */
  @Builder
  private AboutCard(): void {
    Column() {
      Row() {
        Text('ℹ️')
          .fontSize(18)
          .margin({ right: 12 })
        Text('关于')
          .fontSize(16)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      Column({ space: 12 }) {
        this.AboutItem('版本', 'v1.0.0')
        this.AboutItem('开发者', 'cloudchw')
        this.AboutItem('说明', 'LanternLaw - 掌灯人')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: ProfileTab.COLORS.border })
    .margin({ bottom: 16 })
  }

  /**
   * 关于信息项
   */
  @Builder
  private AboutItem(label: string, value: string): void {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor(ProfileTab.COLORS.textDim)
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor(ProfileTab.COLORS.text)
    }
    .width('100%')
  }

  /**
   * 切换全局开关
   */
  private toggleGlobalSwitch(): void {
    this.lanternlawEnabled = !this.lanternlawEnabled;
    Logger.info('ProfileTab', '全局开关切换为: ' + (this.lanternlawEnabled ? '启用' : '停用'));
    this.saveConfig();
  }

  // ==================== 时间段管理方法 ====================

  /**
   * 打开时间段选择器
   */
  private openTimePicker(): void {
    Logger.info('ProfileTab', '打开时间段选择器');
    this.editingTimeRange = null;
    this.newTimeRangeLabel = '';
    this.newStartTime = '22:00';
    this.newEndTime = '06:00';
    this.startHour = 22;
    this.startMinute = 0;
    this.endHour = 6;
    this.endMinute = 0;
    this.timePickerError = '';
    this.showTimePicker = true;
  }

  /**
   * 关闭时间段选择器
   */
  private closeTimePicker(): void {
    this.showTimePicker = false;
    this.editingTimeRange = null;
    this.newTimeRangeLabel = '';
    this.timePickerError = '';
  }

  /**
   * 编辑时间段
   */
  private editTimeRange(timeRange: TimeRange): void {
    Logger.info('ProfileTab', `编辑时间段: ${timeRange.label}`);
    this.editingTimeRange = timeRange;
    this.newTimeRangeLabel = timeRange.label;
    this.newStartTime = timeRange.startTime;
    this.newEndTime = timeRange.endTime;
    this.startHour = parseInt(timeRange.startTime.split(':')[0]);
    this.startMinute = parseInt(timeRange.startTime.split(':')[1]);
    this.endHour = parseInt(timeRange.endTime.split(':')[0]);
    this.endMinute = parseInt(timeRange.endTime.split(':')[1]);
    this.timePickerError = '';
    this.showTimePicker = true;
  }

  /**
   * 保存时间段
   */
  private saveTimeRange(): void {
    // 从 TimePicker 状态变量同步时间字符串（onChange 在未滚动时不触发）
    this.newStartTime = `${this.startHour.toString().padStart(2, '0')}:${this.startMinute.toString().padStart(2, '0')}`;
    this.newEndTime = `${this.endHour.toString().padStart(2, '0')}:${this.endMinute.toString().padStart(2, '0')}`;

    // 验证时间格式
    const timeRegex = /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/;
    if (!timeRegex.test(this.newStartTime) || !timeRegex.test(this.newEndTime)) {
      this.timePickerError = '时间格式不正确，请使用 HH:mm 格式';
      return;
    }

    // 创建新的时间段
    const newTimeRange: TimeRange = {
      id: this.editingTimeRange ? this.editingTimeRange.id : `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      label: this.newTimeRangeLabel || '灯律时段',
      startTime: this.newStartTime,
      endTime: this.newEndTime,
      enabled: this.editingTimeRange ? this.editingTimeRange.enabled : true
    };

    // 检查重叠
    const overlapRange = TimeRangeManager.checkOverlap(newTimeRange, this.timeRanges);
    if (overlapRange) {
      this.timePickerError = `与"${overlapRange.label}"时间段重叠`;
      return;
    }

    if (this.editingTimeRange) {
      // 更新现有时间段 — 用新数组替换以触发 @State 响应式更新
      const updated: TimeRange[] = [];
      for (const tr of this.timeRanges) {
        if (tr.id === this.editingTimeRange!.id) {
          updated.push(newTimeRange);
        } else {
          updated.push({ id: tr.id, label: tr.label, startTime: tr.startTime, endTime: tr.endTime, enabled: tr.enabled });
        }
      }
      this.timeRanges = updated;
      Logger.info('ProfileTab', `更新时间段: ${newTimeRange.label}`);
    } else {
      // 添加新时间段
      const added: TimeRange[] = [];
      for (const tr of this.timeRanges) {
        added.push({ id: tr.id, label: tr.label, startTime: tr.startTime, endTime: tr.endTime, enabled: tr.enabled });
      }
      added.push(newTimeRange);
      this.timeRanges = added;
      Logger.info('ProfileTab', `添加时间段: ${newTimeRange.label}`);
    }

    this.closeTimePicker();
    this.saveConfig();
  }

  /**
   * 切换时间段启用状态
   */
  private toggleTimeRangeEnabled(id: string): void {
    const updated: TimeRange[] = [];
    for (const tr of this.timeRanges) {
      if (tr.id === id) {
        updated.push({ id: tr.id, label: tr.label, startTime: tr.startTime, endTime: tr.endTime, enabled: !tr.enabled });
      } else {
        updated.push({ id: tr.id, label: tr.label, startTime: tr.startTime, endTime: tr.endTime, enabled: tr.enabled });
      }
    }
    this.timeRanges = updated;
    Logger.info('ProfileTab', `切换时间段状态`);
    this.saveConfig();
  }

  /**
   * 显示删除时间段确认对话框
   */
  private showDeleteTimeRangeDialog(id: string): void {
    this.deleteTimeRangeId = id;
    this.showDeleteTimeRangeConfirm = true;
  }

  /**
   * 确认删除时间段
   */
  private confirmDeleteTimeRange(): void {
    const label = this.timeRanges.find(tr => tr.id === this.deleteTimeRangeId)?.label ?? '';
    const remaining: TimeRange[] = [];
    for (const tr of this.timeRanges) {
      if (tr.id !== this.deleteTimeRangeId) {
        remaining.push({ id: tr.id, label: tr.label, startTime: tr.startTime, endTime: tr.endTime, enabled: tr.enabled });
      }
    }
    this.timeRanges = remaining;
    Logger.info('ProfileTab', `删除时间段: ${label}`);
    this.showDeleteTimeRangeConfirm = false;
    this.deleteTimeRangeId = '';
    this.saveConfig();
  }

  /**
   * 加载配置
   */
  private loadConfig(): void {
    try {
      const config = this.stateManager.getConfig();
      this.lanternlawEnabled = config.lanternlawEnabled;

      // 加载时间段
      if (config.timeRanges && config.timeRanges.length > 0) {
        this.timeRanges = JSON.parse(JSON.stringify(config.timeRanges));
        Logger.info('ProfileTab', `加载了 ${this.timeRanges.length} 个时间段`);
      } else {
        this.timeRanges = [];
        Logger.info('ProfileTab', '时间段为空');
      }

      // 加载白名单应用
      if (config.whitelistApps && config.whitelistApps.length > 0) {
        this.whitelistApps = JSON.parse(JSON.stringify(config.whitelistApps));
        Logger.info('ProfileTab', `加载了 ${this.whitelistApps.length} 个白名单应用`);
      } else {
        this.whitelistApps = [];
        Logger.info('ProfileTab', '白名单应用为空');
      }
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '加载配置失败');
    }
  }

  /**
   * 保存配置
   */
  private async saveConfig(): Promise<void> {
    try {
      const config = this.stateManager.getConfig();
      config.lanternlawEnabled = this.lanternlawEnabled;
      config.timeRanges = JSON.parse(JSON.stringify(this.timeRanges));
      config.whitelistApps = JSON.parse(JSON.stringify(this.whitelistApps));

      await this.stateManager.saveConfig(config);

      // 同时保存到 SharedPreferences 供无障碍服务读取
      this.saveConfigToPreferences(config);

      Logger.info('ProfileTab', '配置保存成功');
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '保存配置失败');
    }
  }

  /**
   * 保存配置到 SharedPreferences（供无障碍服务读取）
   */
  private saveConfigToPreferences(config: LanternLawConfig): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      dataPreferences.getPreferences(context, 'lanternlaw_config').then((prefs) => {
        prefs.put('config', config.toJSON());
        prefs.flush();
        Logger.info('ProfileTab', '配置已同步到 Preferences');
      }).catch(() => {});
    } catch (error) {
      // 非关键路径，忽略错误
    }
  }

  // ==================== 白名单应用管理方法 ====================

  /**
   * 打开系统应用选择器（Screen Time Guard Kit）
   */
  private async openAppPicker(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const existingTokens = this.whitelistApps
        .filter(app => app.appToken && app.appToken.length > 0)
        .map(app => app.appToken!);

      const guardManager = ScreenTimeGuardManager.getInstance();
      const selectedTokens = await guardManager.openAppPicker(context, existingTokens);

      if (selectedTokens.length === 0) {
        return;
      }

      // 用系统选择器返回的 tokens 重新构建白名单
      const newWhitelist: WhitelistApp[] = selectedTokens.map(token => {
        const existing = this.whitelistApps.find(app => app.appToken === token);
        if (existing) {
          return existing;
        }
        return {
          appToken: token,
          enabled: true
        };
      });

      this.whitelistApps = newWhitelist;
      this.saveConfig();
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '系统应用选择器失败');
    }
  }

  /**
   * 打开系统应用展示页（查看已选应用的名称和图标）
   */
  private async viewSelectedApps(): Promise<void> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const tokens = this.whitelistApps
        .filter(app => app.appToken && app.appToken.length > 0)
        .map(app => app.appToken!);

      if (tokens.length === 0) {
        return;
      }

      const guardManager = ScreenTimeGuardManager.getInstance();
      const opened = await guardManager.openAppForm(context, tokens);
      if (!opened) {
        Logger.warn('ProfileTab', '应用展示页打开失败，可能需要在真机上使用');
      }
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '打开应用展示页失败');
    }
  }

  /**
   * 切换白名单应用启用状态
   */
  private toggleWhitelistApp(index: number): void {
    if (index < 0 || index >= this.whitelistApps.length) {
      return;
    }
    this.whitelistApps[index].enabled = !this.whitelistApps[index].enabled;
    Logger.info('ProfileTab', `切换白名单应用: ${this.whitelistApps[index].appToken} -> ${this.whitelistApps[index].enabled}`);
    this.saveConfig();
  }

  /**
   * 显示删除确认对话框
   */
  private showDeleteConfirmDialog(index: number): void {
    this.deleteAppIndex = index;
    this.showDeleteConfirm = true;
  }

  /**
   * 确认删除应用
   */
  private confirmDeleteApp(): void {
    if (this.deleteAppIndex < 0 || this.deleteAppIndex >= this.whitelistApps.length) {
      this.showDeleteConfirm = false;
      return;
    }
    const appToken = this.whitelistApps[this.deleteAppIndex].appToken;
    this.whitelistApps.splice(this.deleteAppIndex, 1);
    Logger.info('ProfileTab', `已从白名单删除: ${appToken}`);
    this.showDeleteConfirm = false;
    this.deleteAppIndex = -1;
    this.saveConfig();
  }
}
