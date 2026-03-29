import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppBlockingService } from '../services/AppBlockingService';
import { ScreenTimeGuardManager } from '../services/ScreenTimeGuardManager';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { setUIAbilityContext } from '../accessibility/LanternLawAccessibilityAbility';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;

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
    this.windowStage = windowStage;
    this.initializeServices();

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
    this.windowStage = null;
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    const blockingService = AppBlockingService.getInstance();
    blockingService.onAppGoForeground();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    const blockingService = AppBlockingService.getInstance();
    blockingService.onAppGoBackground();
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'onNewWant received');

    if (want.parameters) {
      const params = want.parameters as Record<string, Object>;
      if (params['blocked'] === true || params['blocked'] === 'true') {
        hilog.info(DOMAIN, 'testTag', '拦截拉回，显示拦截页面');
        this.showBlockingOverlay();
      }
    }
  }

  private showBlockingOverlay(): void {
    if (!this.windowStage) {
      hilog.warn(DOMAIN, 'testTag', 'windowStage 为空');
      return;
    }

    this.windowStage.loadContent('pages/BlockingOverlayPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load BlockingOverlayPage: %{public}s', JSON.stringify(err));
      } else {
        hilog.info(DOMAIN, 'testTag', 'BlockingOverlayPage loaded');
        setTimeout(() => {
          this.windowStage?.loadContent('pages/MainPage');
        }, 5000);
      }
    });
  }

  private async initializeServices(): Promise<void> {
    try {
      // 设置全局 context 供无障碍服务使用
      setUIAbilityContext(this.context);

      const stateManager = LanternLawStateManager.getInstance();
      await stateManager.initialize(this.context);

      const blockingService = AppBlockingService.getInstance();
      await blockingService.initialize(this.context);
      blockingService.start();

      // 初始化 Screen Time Guard Kit
      const guardManager = ScreenTimeGuardManager.getInstance();
      const authorized = await guardManager.requestUserAuth(this.context);
      hilog.info(DOMAIN, 'testTag', `Screen Time Guard authorization: ${authorized}`);

      // 同步策略（将已保存的配置同步到系统）
      if (authorized) {
        const config = stateManager.getConfig();
        await guardManager.syncStrategies(config.timeRanges, config.whitelistApps);
      }

      hilog.info(DOMAIN, 'testTag', 'Services initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize services: %{public}s', JSON.stringify(error));
    }
  }
}
