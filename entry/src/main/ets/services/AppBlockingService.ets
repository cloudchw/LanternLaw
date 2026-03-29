/**
 * 应用拦截服务
 * App Blocking Service
 * 核心功能：在灯律时段内拦截非白名单应用
 *
 * 实现方案：
 * 1. 通过 Continuous Task（长时任务）获取后台运行权限
 * 2. onBackground 中尝试 startAbility 拉回前台
 * 3. 若 startAbility 失败，发送通知提醒用户返回
 * 4. onForeground 中检测拦截状态，显示拦截覆盖层
 */

import { Logger } from '../utils/Logger';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import bundleManager from '@ohos.bundle.bundleManager';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';

/**
 * 拦截状态
 */
export enum BlockingState {
  IDLE = 'idle',
  ACTIVE = 'active',
  BLOCKING = 'blocking'
}

/**
 * 应用拦截服务（单例）
 */
export class AppBlockingService {
  private static instance: AppBlockingService;
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private context: common.UIAbilityContext | null = null;

  private currentState: BlockingState = BlockingState.IDLE;
  private isNavigatingBack: boolean = false;
  private bundleName: string = '';
  private isBackgroundRunning: boolean = false;
  private wasBlockingInBackground: boolean = false;

  private constructor() {}

  public static getInstance(): AppBlockingService {
    if (!AppBlockingService.instance) {
      AppBlockingService.instance = new AppBlockingService();
    }
    return AppBlockingService.instance;
  }

  /**
   * 初始化服务
   */
  public async initialize(ctx: common.UIAbilityContext): Promise<void> {
    try {
      this.context = ctx;
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      this.bundleName = bundleInfo.name;
      await this.requestNotificationPermission();
      Logger.info('AppBlockingService', `应用拦截服务初始化完成, bundleName: ${this.bundleName}`);
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '初始化失败');
    }
  }

  private async requestNotificationPermission(): Promise<void> {
    try {
      await notificationManager.requestEnableNotification();
      Logger.info('AppBlockingService', '通知权限已获取');
    } catch (error) {
      Logger.warn('AppBlockingService', `通知权限获取失败: ${JSON.stringify(error)}`);
    }
  }

  public start(): void {
    this.updateState();
    Logger.info('AppBlockingService', `应用拦截服务已启动，状态: ${this.currentState}`);
  }

  public stop(): void {
    this.stopBackgroundRunning();
    this.currentState = BlockingState.IDLE;
    Logger.info('AppBlockingService', '应用拦截服务已停止');
  }

  public getState(): BlockingState {
    return this.currentState;
  }

  /**
   * 是否刚从拦截状态恢复（用于 onForeground 显示覆盖层）
   */
  public wasBlockedInBackground(): boolean {
    return this.wasBlockingInBackground;
  }

  /**
   * 清除拦截标记
   */
  public clearBlockingFlag(): void {
    this.wasBlockingInBackground = false;
    this.currentState = BlockingState.ACTIVE;
  }

  /**
   * 应用切到后台时调用
   */
  public onAppGoBackground(): void {
    if (this.isNavigatingBack) {
      return;
    }

    if (!this.shouldBlockApps()) {
      Logger.debug('AppBlockingService', '不在管控时段，允许切后台');
      return;
    }

    Logger.info('AppBlockingService', '管控时段内检测到切后台');
    this.wasBlockingInBackground = true;
    this.currentState = BlockingState.BLOCKING;

    // 尝试拉回前台
    this.bringToFront();

    // 记录越狱尝试
    this.stateManager.recordEscapeAttempt('APP_SWITCH', 'foreground_switch').catch(() => {});
  }

  /**
   * 应用回到前台时调用
   */
  public onAppGoForeground(): void {
    if (this.wasBlockingInBackground) {
      Logger.info('AppBlockingService', '从拦截状态恢复到前台，显示覆盖层');
      // 状态保持 BLOCKING，由 MainPage 检测并显示覆盖层
    }
  }

  public shouldBlockApps(): boolean {
    try {
      const config = this.stateManager.getConfig();

      if (!config.lanternlawEnabled) {
        return false;
      }

      const now = new Date();
      const currentTimeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

      for (const timeRange of config.timeRanges) {
        if (!timeRange.enabled) {
          continue;
        }
        if (this.isTimeInRange(currentTimeStr, timeRange.startTime, timeRange.endTime)) {
          return true;
        }
      }

      return false;
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '检查拦截状态出错');
      return false;
    }
  }

  /**
   * 启动长时任务
   */
  public async startBackgroundRunning(): Promise<void> {
    if (this.isBackgroundRunning || !this.context) {
      return;
    }

    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.bundleName,
            abilityName: 'EntryAbility'
          } as Want
        ],
        requestCode: 0,
        operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };
      const agent = await wantAgent.getWantAgent(wantAgentInfo);

      const notificationRequest: notificationManager.NotificationRequest = {
        id: 1001,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '掌灯人正在守护',
            text: '灯律时段内，掌灯人正在守护你的自律',
          }
        },
        wantAgent: agent,
        isOngoing: true,
        isUnremovable: true
      };
      // Screen Time Guard Kit 已接管拦截，不再发送通知
      // await notificationManager.publish(notificationRequest);

      backgroundTaskManager.startBackgroundRunning(this.context, backgroundTaskManager.BackgroundMode.DATA_TRANSFER, agent);

      this.isBackgroundRunning = true;
      Logger.info('AppBlockingService', '长时任务已启动');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '启动长时任务失败');
    }
  }

  public stopBackgroundRunning(): void {
    if (!this.isBackgroundRunning || !this.context) {
      return;
    }

    try {
      backgroundTaskManager.stopBackgroundRunning(this.context);
      notificationManager.cancel(1001);
      this.isBackgroundRunning = false;
      Logger.info('AppBlockingService', '长时任务已停止');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '停止长时任务失败');
    }
  }

  /**
   * 拉回前台
   */
  private bringToFront(): void {
    if (!this.context || !this.bundleName) {
      return;
    }

    this.isNavigatingBack = true;

    const want: Want = {
      bundleName: this.bundleName,
      abilityName: 'EntryAbility',
      parameters: {
        blocked: true,
        blockedTimestamp: Date.now()
      }
    };

    // 尝试 startAbility
    this.context.startAbility(want).then(() => {
      Logger.info('AppBlockingService', 'startAbility 成功');
    }).catch((error: Error) => {
      Logger.warn('AppBlockingService', `startAbility 失败: ${error.message}`);
      // Screen Time Guard Kit 已接管拦截，不再发送紧急通知
    });

    setTimeout(() => {
      this.isNavigatingBack = false;
    }, 3000);
  }

  /**
   * 发送紧急通知（startAbility 失败时的备选方案）
   */
  private showUrgentNotification(): void {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: this.bundleName,
            abilityName: 'EntryAbility'
          } as Want
        ],
        requestCode: 0,
        operationType: wantAgent.OperationType.START_ABILITY,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      wantAgent.getWantAgent(wantAgentInfo).then((agent) => {
        const request: notificationManager.NotificationRequest = {
          id: 1002,
          content: {
            notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
            normal: {
              title: '请回到掌灯人',
              text: '灯律时段内，请点击返回掌灯人应用',
            }
          },
          wantAgent: agent,
          isUnremovable: false
        };
        notificationManager.publish(request).then(() => {
          Logger.info('AppBlockingService', '紧急通知已发布');
        }).catch(() => {});
      }).catch(() => {});
    } catch (error) {
      Logger.warn('AppBlockingService', `显示紧急通知失败`);
    }
  }

  private updateState(): void {
    const shouldBlock = this.shouldBlockApps();
    if (shouldBlock) {
      this.currentState = BlockingState.ACTIVE;
      this.startBackgroundRunning();
      Logger.info('AppBlockingService', '进入拦截状态');
    } else {
      this.currentState = BlockingState.IDLE;
      this.stopBackgroundRunning();
      Logger.info('AppBlockingService', '退出拦截状态');
    }
  }

  private isTimeInRange(currentTime: string, startTime: string, endTime: string): boolean {
    const current = TimeRangeManager.timeToMinutes(currentTime);
    const start = TimeRangeManager.timeToMinutes(startTime);
    const end = TimeRangeManager.timeToMinutes(endTime);

    if (end >= start) {
      return current >= start && current < end;
    } else {
      return current >= start || current < end;
    }
  }
}
