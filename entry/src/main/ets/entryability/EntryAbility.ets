import { AbilityConstant, ConfigurationConstant, UIAbility, Want, common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { cloudCommon } from '@kit.CloudFoundationKit';
import auth from '@hw-agconnect/auth';
import { AppBlockingService } from '../services/AppBlockingService';
import { ScreenTimeGuardManager } from '../services/ScreenTimeGuardManager';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { AccountService } from '../services/AccountService';
import { ConfigSyncService } from '../services/ConfigSyncService';
import { setUIAbilityContext } from '../accessibility/LanternLawAccessibilityAbility';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private windowStage: window.WindowStage | null = null;
  private cloudInitPromise: Promise<void> | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. 初始化 AGC 认证 SDK
    try {
      const file = this.context.resourceManager.getRawFileContentSync('agconnect-services.json');
      const json: string = new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(file.buffer));
      auth.init(this.context, json);
      hilog.info(DOMAIN, 'testTag', 'AGC Auth SDK init success');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'AGC Auth SDK init failed: %{public}s', JSON.stringify(err));
    }

    // 2. 匿名登录获取 authProvider，再初始化 Cloud Foundation
    //    存储 Promise，确保 initializeServices 等待完成后才创建 zone
    this.cloudInitPromise = auth.signInAnonymously().then(() => {
      const authProvider = auth.getAuthProvider();
      cloudCommon.init({
        region: cloudCommon.CloudRegion.CHINA,
        authProvider: authProvider,
        databaseOptions: {
          schema: 'app-schema.json'
        }
      });
      hilog.info(DOMAIN, 'testTag', 'CloudFoundation init success with auth');
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'testTag', 'Anonymous auth failed: %{public}s', err.message);
      // 匿名认证失败时回退到无 authProvider 初始化
      cloudCommon.init({
        databaseOptions: {
          schema: 'app-schema.json'
        }
      });
    });

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
    const syncService = ConfigSyncService.getInstance();
    syncService.destroy();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    this.windowStage = windowStage;
    this.initializeServices();
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
        return;
      }
      if (params['navigateTo'] === 'MainPage' || params['navigateTo'] === 'JoinFamilyGroupPage' ||
        params['navigateTo'] === 'WaitingForApprovalPage') {
        const pageName = params['navigateTo'] as string;
        hilog.info(DOMAIN, 'testTag', `帐号创建完成，跳转到${pageName}`);
        // 帐号创建后重新初始化服务（含 Cloud DB）
        this.initializeServicesForNewAccount(pageName);
        return;
      }
    }
  }

  /**
   * 帐号创建后初始化服务（Cloud DB 同步等）
   * 与 initializeServices 不同，此方法在帐号已创建后调用，直接加载目标页面
   */
  private async initializeServicesForNewAccount(targetPage: string): Promise<void> {
    try {
      const accountService = AccountService.getInstance();
      // 重新加载活跃帐号
      await accountService.initialize(this.context);

      if (!accountService.hasActiveAccount()) {
        hilog.error(DOMAIN, 'testTag', 'initializeServicesForNewAccount: 无活跃帐号');
        this.windowStage?.loadContent('pages/AccountModeSelectPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load AccountModeSelectPage: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }

      const accountId = accountService.getActiveAccountId();
      hilog.info(DOMAIN, 'testTag', `帐号后初始化，活跃帐号: ${accountId}，目标页: ${targetPage}`);

      // 初始化 Cloud DB 同步
      const syncService = ConfigSyncService.getInstance();
      syncService.setAccountId(accountId);
      const cloudReady = syncService.initialize();
      if (cloudReady) {
        syncService.startPeriodicSync();
      }
      hilog.info(DOMAIN, 'testTag', `帐号后初始化 Cloud sync: ${cloudReady ? 'enabled' : 'unavailable'}`);

      // 加载目标页面
      this.windowStage?.loadContent(`pages/${targetPage}`, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', `Failed to load ${targetPage}: %{public}s`, JSON.stringify(err));
        }
      });

      // 如果目标是主页，初始化其他服务
      if (targetPage === 'MainPage') {
        const stateManager = LanternLawStateManager.getInstance();
        await stateManager.initialize(this.context, accountId);

        const blockingService = AppBlockingService.getInstance();
        await blockingService.initialize(this.context);
        blockingService.start();

        const guardManager = ScreenTimeGuardManager.getInstance();
        const authorized = await guardManager.requestUserAuth(this.context);
        if (authorized) {
          const config = stateManager.getConfig();
          await guardManager.syncStrategies(config.timeRanges, config.whitelistApps, accountId);
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'initializeServicesForNewAccount failed: %{public}s', JSON.stringify(error));
      this.windowStage?.loadContent(`pages/${targetPage}`, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load %s: %{public}s', targetPage, JSON.stringify(err));
        }
      });
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

      // 等待 Cloud Foundation 初始化完成（匿名认证 + cloudCommon.init）
      if (this.cloudInitPromise) {
        hilog.info(DOMAIN, 'testTag', '等待 Cloud Foundation 初始化...');
        await this.cloudInitPromise;
        hilog.info(DOMAIN, 'testTag', 'Cloud Foundation 初始化已完成');
      }

      // 初始化帐号服务（含数据库初始化）
      const accountService = AccountService.getInstance();
      await accountService.initialize(this.context);

      // 初始化云端同步服务（无论是否有活跃帐号都需要初始化）
      const syncService = ConfigSyncService.getInstance();
      const cloudReady = syncService.initialize();
      hilog.info(DOMAIN, 'testTag', `Cloud sync init: ${cloudReady ? 'success' : 'unavailable'}`);

      // 检查是否有活跃帐号
      if (!accountService.hasActiveAccount()) {
        hilog.info(DOMAIN, 'testTag', '无活跃帐号，跳转到帐号创建页');
        this.windowStage?.loadContent('pages/AccountModeSelectPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load AccountModeSelectPage: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }

      const accountId = accountService.getActiveAccountId();
      hilog.info(DOMAIN, 'testTag', `活跃帐号: ${accountId}`);

      // 设置云端同步的 accountId 并启动定时同步
      syncService.setAccountId(accountId);
      if (cloudReady) {
        syncService.startPeriodicSync();
      }

      // 儿童帐号启动时从云端同步最新状态
      if (accountService.getActiveAccountMode() === 'child' && cloudReady) {
        hilog.info(DOMAIN, 'testTag', '儿童帐号启动，从云端同步最新状态...');
        const cloudAccount = await syncService.queryAccount(accountId);
        if (cloudAccount) {
          const current = accountService.getActiveAccount();
          if (current) {
            current.joinStatus = cloudAccount.joinStatus;
            current.familyGroupId = cloudAccount.familyGroupId;
            current.parentAccountId = cloudAccount.parentAccountId;
            current.pendingGroupId = cloudAccount.pendingGroupId;
            current.pendingRequestedAt = cloudAccount.pendingRequestedAt;
            await accountService.saveActiveAccount();
          }
          hilog.info(DOMAIN, 'testTag', `云端同步完成，joinStatus: ${cloudAccount.joinStatus}`);
        }
      }

      // 检查儿童帐号状态，决定跳转页面
      if (accountService.isChildPendingApproval()) {
        hilog.info(DOMAIN, 'testTag', '儿童帐号等待家长确认，跳转到等待页');
        this.windowStage?.loadContent('pages/WaitingForApprovalPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load WaitingForApprovalPage: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }
      if (accountService.isChildWithoutGroup()) {
        hilog.info(DOMAIN, 'testTag', '儿童帐号未加入沟通组，跳转到加入页');
        this.windowStage?.loadContent('pages/JoinFamilyGroupPage', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load JoinFamilyGroupPage: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }

      // 加载主页
      this.windowStage?.loadContent('pages/MainPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });

      const stateManager = LanternLawStateManager.getInstance();
      await stateManager.initialize(this.context, accountId);

      // 儿童帐号：从云端拉取最新管控配置
      if (accountService.getActiveAccountMode() === 'child' && cloudReady) {
        hilog.info(DOMAIN, 'testTag', '儿童帐号，从云端拉取最新管控配置...');
        const cloudConfig = await syncService.pullLatestConfig(accountId);
        if (cloudConfig) {
          await stateManager.saveConfig(cloudConfig);
          hilog.info(DOMAIN, 'testTag', '云端管控配置已同步到本地');
        }
      }

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
        await guardManager.syncStrategies(config.timeRanges, config.whitelistApps, accountId);
      }

      hilog.info(DOMAIN, 'testTag', 'Services initialized successfully');
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize services: %{public}s', JSON.stringify(error));
      // 初始化失败时仍尝试加载主页
      this.windowStage?.loadContent('pages/MainPage', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load MainPage after error: %{public}s', JSON.stringify(err));
        }
      });
    }
  }
}
