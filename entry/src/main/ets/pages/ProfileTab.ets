/**
 * 我的 Tab - LanternLaw
 * 个人设置页面
 */
import { Logger } from '../utils/Logger';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';
import { WhitelistApp } from '../models/WhitelistApp';
import { AppListManager, AppInfo } from '../managers/AppListManager';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';

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
  // 白名单应用状态
  @State whitelistApps: WhitelistApp[] = [];
  @State showAppPicker: boolean = false;
  @State installedApps: AppInfo[] = [];
  @State appSearchQuery: string = '';
  @State filteredApps: AppInfo[] = [];
  @State showDeleteConfirm: boolean = false;
  @State deleteAppIndex: number = -1;
  @State showDeleteTimeRangeConfirm: boolean = false;
  @State deleteTimeRangeId: string = '';
  @State loadingApps: boolean = false;

  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private appListManager: AppListManager = AppListManager.getInstance();
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

      // 应用选择对话框
      if (this.showAppPicker) {
        Column() {
          Column() {
            this.AppPickerDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.closeAppPicker();
        })
      }

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

            // 启用/禁用开关
            Text(timeRange.enabled ? '✓' : '✗')
              .fontSize(16)
              .fontColor(timeRange.enabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
              .margin({ right: 12 })
              .onClick(() => {
                this.toggleTimeRangeEnabled(timeRange.id);
              })

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
        }, (timeRange: TimeRange, index: number) => timeRange.id)
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
      Text(this.editingTimeRange ? '编辑时间段' : '添加时间段')
        .fontSize(18)
        .fontColor(ProfileTab.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 标签输入
      Column({ space: 8 }) {
        Text('标签')
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
        TextInput({ placeholder: '如: 夜间休息', text: this.newTimeRangeLabel })
          .width('100%')
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onChange((value: string) => {
            this.newTimeRangeLabel = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })

      // 开始时间
      Column({ space: 8 }) {
        Text('开始时间')
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
        TextInput({ text: this.newStartTime })
          .width('100%')
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.gold)
          .borderRadius(8)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.newStartTime = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })

      // 结束时间
      Column({ space: 8 }) {
        Text('结束时间')
          .fontSize(14)
          .fontColor(ProfileTab.COLORS.text)
        TextInput({ text: this.newEndTime })
          .width('100%')
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.gold)
          .borderRadius(8)
          .type(InputType.Normal)
          .onChange((value: string) => {
            this.newEndTime = value;
          })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 16 })

      // 错误提示
      if (this.timePickerError) {
        Text(this.timePickerError)
          .fontSize(12)
          .fontColor(ProfileTab.COLORS.orange)
          .margin({ bottom: 16 })
      }

      // 按钮行
      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.background)
          .fontColor(ProfileTab.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.closeTimePicker();
          })

        Button(this.editingTimeRange ? '保存' : '添加')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(ProfileTab.COLORS.gold)
          .fontColor(ProfileTab.COLORS.background)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.saveTimeRange();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('85%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(16)
    .padding(20)
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
        Button('+ 添加')
          .fontSize(12)
          .height(28)
          .backgroundColor(ProfileTab.COLORS.accent)
          .fontColor(ProfileTab.COLORS.gold)
          .borderRadius(14)
          .onClick(() => {
            this.openAppPicker();
          })
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 白名单列表
      if (this.whitelistApps.length === 0) {
        Text('暂无白名单应用')
          .fontSize(13)
          .fontColor(ProfileTab.COLORS.textDim)
          .margin({ top: 8, bottom: 8 })
      } else {
        ForEach(this.whitelistApps, (app: WhitelistApp, index: number) => {
          Row() {
            Text('📲')
              .fontSize(14)
              .margin({ right: 10 })
            Text(app.appName)
              .fontSize(14)
              .fontColor(app.enabled ? ProfileTab.COLORS.text : ProfileTab.COLORS.textDim)
              .decoration({ type: app.enabled ? TextDecorationType.None : TextDecorationType.LineThrough })
              .layoutWeight(1)
            Blank()
            Text(app.enabled ? '✓' : '✗')
              .fontSize(16)
              .fontColor(app.enabled ? ProfileTab.COLORS.gold : ProfileTab.COLORS.textDim)
              .margin({ right: 12 })
            Button('删除')
              .fontSize(11)
              .height(24)
              .backgroundColor('rgba(255, 107, 107, 0.2)')
              .fontColor('#ff6b6b')
              .borderRadius(12)
              .onClick(() => {
                this.showDeleteConfirmDialog(index);
              })
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .onClick(() => {
            this.toggleWhitelistApp(index);
          })
        }, (app: WhitelistApp, index: number) => `${app.bundleName}_${index}`)
      }

      Text('点击应用切换启用/禁用，点击删除按钮移除')
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
   * 应用选择对话框
   */
  @Builder
  private AppPickerDialog(): void {
    Column() {
      // 标题栏
      Row() {
        Text('选择应用')
          .fontSize(18)
          .fontColor(ProfileTab.COLORS.text)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('✕')
          .fontSize(20)
          .fontColor(ProfileTab.COLORS.textDim)
          .onClick(() => {
            this.closeAppPicker();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 搜索框
      TextInput({ placeholder: '搜索应用...', text: this.appSearchQuery })
        .width('100%')
        .height(40)
        .backgroundColor(ProfileTab.COLORS.background)
        .fontColor(ProfileTab.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.searchApps(value);
        })

      // 应用列表
      if (this.loadingApps) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(ProfileTab.COLORS.gold)
          Text('加载中...')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.textDim)
            .margin({ top: 8 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else if (this.filteredApps.length === 0) {
        Column() {
          Text('暂无应用')
            .fontSize(14)
            .fontColor(ProfileTab.COLORS.textDim)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.filteredApps, (appInfo: AppInfo) => {
            ListItem() {
              Row() {
                Text('📲')
                  .fontSize(16)
                  .margin({ right: 10 })
                Column() {
                  Text(appInfo.appName)
                    .fontSize(14)
                    .fontColor(ProfileTab.COLORS.text)
                  Text(appInfo.bundleName)
                    .fontSize(11)
                    .fontColor(ProfileTab.COLORS.textDim)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Blank()
                Text('+')
                  .fontSize(18)
                  .fontColor(ProfileTab.COLORS.gold)
              }
              .width('100%')
              .padding(12)
              .onClick(() => {
                this.addToWhitelist(appInfo);
              })
            }
          })
        }
        .width('100%')
        .height(280)
      }
    }
    .width('85%')
    .backgroundColor(ProfileTab.COLORS.card)
    .borderRadius(16)
    .padding(20)
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

      Text(`确定要从白名单中移除 "${this.deleteAppIndex >= 0 && this.deleteAppIndex < this.whitelistApps.length ? this.whitelistApps[this.deleteAppIndex].appName : '该应用'}" 吗？`)
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
    this.timePickerError = '';
    this.showTimePicker = true;
  }

  /**
   * 保存时间段
   */
  private saveTimeRange(): void {
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
      // 更新现有时间段
      const index = this.timeRanges.findIndex(tr => tr.id === this.editingTimeRange!.id);
      if (index >= 0) {
        this.timeRanges[index] = newTimeRange;
        Logger.info('ProfileTab', `更新时间段: ${newTimeRange.label}`);
      }
    } else {
      // 添加新时间段
      this.timeRanges.push(newTimeRange);
      Logger.info('ProfileTab', `添加时间段: ${newTimeRange.label}`);
    }

    this.closeTimePicker();
    this.saveConfig();
  }

  /**
   * 切换时间段启用状态
   */
  private toggleTimeRangeEnabled(id: string): void {
    const index = this.timeRanges.findIndex(tr => tr.id === id);
    if (index >= 0) {
      this.timeRanges[index].enabled = !this.timeRanges[index].enabled;
      Logger.info('ProfileTab', `切换时间段状态: ${this.timeRanges[index].label} -> ${this.timeRanges[index].enabled}`);
      this.saveConfig();
    }
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
    const index = this.timeRanges.findIndex(tr => tr.id === this.deleteTimeRangeId);
    if (index >= 0) {
      const label = this.timeRanges[index].label;
      this.timeRanges.splice(index, 1);
      Logger.info('ProfileTab', `删除时间段: ${label}`);
    }
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
      Logger.info('ProfileTab', '配置保存成功');
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '保存配置失败');
    }
  }

  /**
   * 显示旧版时间选择器（已弃用）
   */
  private showLegacyTimePicker(type: string): void {
    Logger.info('ProfileTab', `显示时间选择器: ${type}`);
    // 已被新的时间段管理功能替代
  }

  // ==================== 白名单应用管理方法 ====================

  /**
   * 打开应用选择器
   */
  private async openAppPicker(): Promise<void> {
    Logger.info('ProfileTab', '打开应用选择器');
    this.loadingApps = true;
    this.showAppPicker = true;
    this.appSearchQuery = '';

    try {
      this.installedApps = await this.appListManager.getInstalledApps();
      this.filteredApps = [...this.installedApps];
      Logger.info('ProfileTab', `加载了 ${this.installedApps.length} 个应用`);
    } catch (error) {
      Logger.exception('ProfileTab', error instanceof Error ? error : new Error(String(error)), '获取应用列表失败');
      this.installedApps = [];
      this.filteredApps = [];
    } finally {
      this.loadingApps = false;
    }
  }

  /**
   * 关闭应用选择器
   */
  private closeAppPicker(): void {
    this.showAppPicker = false;
    this.appSearchQuery = '';
    this.filteredApps = [];
    Logger.info('ProfileTab', '关闭应用选择器');
  }

  /**
   * 搜索应用
   */
  private searchApps(query: string): void {
    this.appSearchQuery = query;
    if (!query || query.trim() === '') {
      this.filteredApps = [...this.installedApps];
    } else {
      const lowerQuery = query.toLowerCase().trim();
      this.filteredApps = this.installedApps.filter(app =>
        app.appName.toLowerCase().includes(lowerQuery) ||
        app.bundleName.toLowerCase().includes(lowerQuery)
      );
    }
    Logger.info('ProfileTab', `搜索 "${query}" 找到 ${this.filteredApps.length} 个应用`);
  }

  /**
   * 添加应用到白名单
   */
  private addToWhitelist(appInfo: AppInfo): void {
    Logger.info('ProfileTab', `添加应用到白名单: ${appInfo.appName}`);

    // 检查是否已存在
    const exists = this.whitelistApps.some(app => app.bundleName === appInfo.bundleName);
    if (exists) {
      Logger.warn('ProfileTab', '应用已在白名单中');
      this.closeAppPicker();
      return;
    }

    // 添加新应用
    const newApp: WhitelistApp = {
      bundleName: appInfo.bundleName,
      appName: appInfo.appName,
      enabled: true
    };

    this.whitelistApps.push(newApp);
    this.closeAppPicker();
    this.saveConfig();
    Logger.info('ProfileTab', `白名单应用数量: ${this.whitelistApps.length}`);
  }

  /**
   * 切换白名单应用启用状态
   */
  private toggleWhitelistApp(index: number): void {
    if (index < 0 || index >= this.whitelistApps.length) {
      return;
    }
    this.whitelistApps[index].enabled = !this.whitelistApps[index].enabled;
    Logger.info('ProfileTab', `切换白名单应用: ${this.whitelistApps[index].appName} -> ${this.whitelistApps[index].enabled}`);
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
    const appName = this.whitelistApps[this.deleteAppIndex].appName;
    this.whitelistApps.splice(this.deleteAppIndex, 1);
    Logger.info('ProfileTab', `已从白名单删除: ${appName}`);
    this.showDeleteConfirm = false;
    this.deleteAppIndex = -1;
    this.saveConfig();
  }
}
