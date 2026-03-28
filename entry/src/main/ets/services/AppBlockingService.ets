/**
 * 应用拦截服务
 * App Blocking Service
 * 核心功能：在灯律时段内拦截非白名单应用
 *
 * 实现方案：不依赖无障碍服务，通过 onBackground 生命周期回调
 * 检测本应用被切到后台，在管控时段内立即拉回前台并显示拦截页面
 */

import { Logger } from '../utils/Logger';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';
import { WhitelistApp } from '../models/WhitelistApp';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import bundleManager from '@ohos.bundle.bundleManager';

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
      Logger.info('AppBlockingService', '应用拦截服务初始化完成');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '初始化失败');
    }
  }

  /**
   * 启动拦截服务
   */
  public start(): void {
    this.updateState();
    Logger.info('AppBlockingService', `应用拦截服务已启动，状态: ${this.currentState}`);
  }

  /**
   * 停止拦截服务
   */
  public stop(): void {
    this.currentState = BlockingState.IDLE;
    Logger.info('AppBlockingService', '应用拦截服务已停止');
  }

  /**
   * 获取当前状态
   */
  public getState(): BlockingState {
    return this.currentState;
  }

  /**
   * 应用切到后台时调用 — 核心拦截入口
   */
  public async onAppGoBackground(): Promise<void> {
    if (this.isNavigatingBack) {
      return;
    }

    if (!this.shouldBlockApps()) {
      Logger.debug('AppBlockingService', '不在管控时段，允许切后台');
      return;
    }

    Logger.info('AppBlockingService', '管控时段内检测到切后台，立即拉回前台');
    await this.bringToFront();
  }

  /**
   * 检查是否应该激活拦截
   */
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
   * 拉回前台
   */
  private async bringToFront(): Promise<void> {
    if (!this.context) {
      Logger.warn('AppBlockingService', '上下文为空，无法拉回前台');
      return;
    }

    this.isNavigatingBack = true;
    this.currentState = BlockingState.BLOCKING;

    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);

      const want: Want = {
        bundleName: bundleInfo.name,
        abilityName: 'EntryAbility',
        parameters: {
          blocked: true,
          blockedTimestamp: Date.now()
        }
      };

      await this.context.startAbility(want);
      Logger.info('AppBlockingService', '已拉回前台');

      // 记录越狱尝试
      await this.stateManager.recordEscapeAttempt('APP_SWITCH', 'foreground_switch');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '拉回前台失败');
    }

    // 延迟重置导航标志
    setTimeout(() => {
      this.isNavigatingBack = false;
      if (this.shouldBlockApps()) {
        this.currentState = BlockingState.ACTIVE;
      } else {
        this.currentState = BlockingState.IDLE;
      }
    }, 1000);
  }

  /**
   * 更新状态
   */
  private updateState(): void {
    const shouldBlock = this.shouldBlockApps();
    if (shouldBlock) {
      this.currentState = BlockingState.ACTIVE;
      Logger.info('AppBlockingService', '进入拦截状态');
    } else {
      this.currentState = BlockingState.IDLE;
      Logger.info('AppBlockingService', '退出拦截状态');
    }
  }

  /**
   * 检查时间是否在范围内
   */
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
