import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppBlockingService } from '../services/AppBlockingService';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    const blockingService = AppBlockingService.getInstance();
    blockingService.stop();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    this.initializeServices();

    // 检查是否从拦截返回
    windowStage.loadContent('pages/MainPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  /**
   * 应用切到后台 — 核心拦截入口
   * 在管控时段内立即拉回前台
   */
  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');

    // 调用拦截服务检查并处理
    const blockingService = AppBlockingService.getInstance();
    blockingService.onAppGoBackground();
  }

  /**
   * 初始化服务
   */
  private async initializeServices(): Promise<void> {
    try {
      const stateManager = LanternLawStateManager.getInstance();
      await stateManager.initialize(this.context);

      const blockingService = AppBlockingService.getInstance();
      await blockingService.initialize(this.context);
      blockingService.start();

      hilog.info(DOMAIN, 'testTag', 'Services initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize services: %{public}s', JSON.stringify(error));
    }
  }
}
