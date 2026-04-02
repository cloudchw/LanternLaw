/**
 * 诊断页面
 * 用于测试和验证应用拦截功能
 */
import { AppBlockingService, BlockingState } from '../services/AppBlockingService';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { Logger } from '../utils/Logger';
import router from '@ohos.router';

@Entry
@Component
struct DiagnosticsPage {
  @State private statusText: string = '正在检查...';
  @State private shouldBlock: boolean = false;
  @State private configInfo: string = '';
  @State private testResults: string[] = [];

  build() {
    Column() {
      // 标题
      Text('应用拦截诊断')
        .fontSize(24)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })

      // 状态卡片
      Column() {
        Text('当前状态')
          .fontSize(16)
          .fontColor('#c0c6e9')
          .margin({ bottom: 8 })

        Text(this.statusText)
          .fontSize(14)
          .fontColor(this.shouldBlock ? '#4ade96' : '#ff6b6b')
          .margin({ bottom: 16 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.1)')
      .borderRadius(12)

      // 配置信息卡片
      Column() {
        Text('配置信息')
          .fontSize(16)
          .fontColor('#c0c6e9')
          .margin({ bottom: 8 })

        Text(this.configInfo)
          .fontSize(12)
          .fontColor('#a0e1f')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.1)')
      .borderRadius(12)
      .margin({ bottom: 16 })

      // 测试结果
      Column() {
        Text('测试结果')
          .fontSize(16)
          .fontColor('#c0c6e9')
          .margin({ bottom: 8 })

        if (this.testResults.length === 0) {
          Text('点击下方按钮开始测试')
            .fontSize(14)
            .fontColor('rgba(192, 198, 233, 0.5)')
        } else {
          ForEach(this.testResults, (result: string, index: number) => {
            Text(`${index + 1}. ${result}`)
              .fontSize(12)
              .fontColor('#c0c6e9')
              .width('100%')
              .margin({ bottom: 4 })
          }, (result: string) => result)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor('rgba(255, 255, 255, 0.1)')
      .borderRadius(12)
      .margin({ bottom: 16 })

      // 测试按钮
      Button('运行诊断测试')
        .width('80%')
        .height(44)
        .backgroundColor('#ffd166')
        .fontColor('#0f1529')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .borderRadius(22)
        .margin({ top: 16 })
        .onClick(() => {
          this.runDiagnostics();
        })

      // 返回按钮
      Button('返回')
        .width('80%')
        .height(44)
        .backgroundColor('rgba(255, 255, 255, 0.2)')
        .fontColor('#c0c6e9')
        .fontSize(16)
        .margin({ top: 12 })
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0f1529')
  }

  /**
   * 运行诊断测试
   */
  private runDiagnostics(): void {
    this.testResults = [];
    this.statusText = '正在检查...';

    try {
      // 测试1: 检查服务状态
      const blockingService = AppBlockingService.getInstance();
      const state = blockingService.getState();
      this.testResults.push(`拦截服务状态: ${state}`);

      // 测试2: 检查是否应该拦截
      const shouldBlock = blockingService.shouldBlockApps();
      this.shouldBlock = shouldBlock;
      this.testResults.push(`是否应该拦截: ${shouldBlock ? '是' : '否'}`);

      // 测试3: 检查配置
      const stateManager = LanternLawStateManager.getInstance();
      const config = stateManager.getConfig();
      this.testResults.push(`全局开关: ${config.lanternlawEnabled ? '已启用' : '已禁用'}`);
      this.testResults.push(`时间段数量: ${config.timeRanges.length}`);

      // 测试4: 检查时间段
      const now = new Date();
      const currentTimeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
      this.testResults.push(`当前时间: ${currentTimeStr}`);

      for (const range of config.timeRanges) {
        this.testResults.push(`时间段: ${range.startTime} - ${range.endTime} (${range.enabled ? '已启用' : '已禁用'})`);
      }

      // 测试5: 检查白名单
      this.testResults.push(`白名单应用数量: ${config.whitelistApps.length}`);
      for (const app of config.whitelistApps) {
        const maskedToken = app.appToken ? `${app.appToken.substring(0, 4)}****` : '未知';
        this.testResults.push(`白名单: ${maskedToken} (${app.enabled ? '已启用' : '已禁用'})`);
      }

      // 更新状态
      if (shouldBlock) {
        this.statusText = '应该拦截非白名单应用';
      } else if (!config.lanternlawEnabled) {
        this.statusText = '全局开关未启用';
      } else {
        this.statusText = '当前不在管控时间段';
      }

      // 更新配置信息
      this.configInfo = `开关: ${config.lanternlawEnabled ? '开' : '关'} | 时间段: ${config.timeRanges.length} | 白名单: ${config.whitelistApps.length}`;

    } catch (error) {
      Logger.exception('DiagnosticsPage', error instanceof Error ? error : String(error), '诊断测试失败');
      this.testResults.push(`测试失败: ${error instanceof Error ? error.message : String(error)}`);
      this.statusText = '测试失败';
    }
  }
}
