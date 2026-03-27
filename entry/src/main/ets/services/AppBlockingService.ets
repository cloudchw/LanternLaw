/**
 * 应用拦截服务
 * App Blocking Service
 * 核心功能：在灯律时段内拦截非白名单应用
 */

import { Logger } from '../utils/Logger';
import { LanternLawStateManager, LanternLawState } from '../managers/LanternLawStateManager';
import { TimeRange, TimeRangeManager } from '../models/TimeRange';
import { WhitelistApp } from '../models/WhitelistApp';
import common from '@ohos.app.ability.common';
import window from '@ohos.window';
import Want from '@ohos.app.ability.Want';
import bundleManager from '@ohos.bundle.bundleManager';

/**
 * 拦截状态
 */
export enum BlockingState {
  IDLE = 'idle',           // 空闲（不在灯律时段或未启用）
  ACTIVE = 'active',       // 激活拦截中
  BLOCKING = 'blocking'    // 正在拦截应用
}

/**
 * 应用拦截服务
 * 单例模式
 */
export class AppBlockingService {
  private static instance: AppBlockingService;

  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private context: common.UIAbilityContext | null = null;
  private mainWindow: window.Window | null = null;

  // 拦截状态
  private currentState: BlockingState = BlockingState.IDLE;

  // 检测定时器
  private checkTimer: number | null = null;

  // 上次检测的前台应用
  private lastForegroundApp: string = '';

  // 拦截窗口是否显示
  private isBlockingWindowShown: boolean = false;

  // 检测间隔（毫秒）- 500ms
  private readonly CHECK_INTERVAL: number = 500;

  private constructor() {}

  /**
   * 获取单例实例
   */
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
      this.mainWindow = await window.getLastWindow(ctx);
      Logger.info('AppBlockingService', '应用拦截服务初始化完成');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '初始化失败');
    }
  }

  /**
   * 启动拦截服务
   */
  public start(): void {
    if (this.checkTimer !== null) {
      Logger.warn('AppBlockingService', '拦截服务已在运行');
      return;
    }

    Logger.info('AppBlockingService', '启动应用拦截服务');

    // 启动定时检测
    this.checkTimer = setInterval(() => {
      this.checkAndBlock();
    }, this.CHECK_INTERVAL);

    this.updateState();
    Logger.info('AppBlockingService', '应用拦截服务已启动');
  }

  /**
   * 停止拦截服务
   */
  public stop(): void {
    if (this.checkTimer !== null) {
    clearInterval(this.checkTimer);
    this.checkTimer = null;
    Logger.info('AppBlockingService', '定时检测已停止');
    }

    this.currentState = BlockingState.IDLE;
    this.hideBlockingWindow();
    Logger.info('AppBlockingService', '应用拦截服务已停止');
  }

  /**
   * 获取当前状态
   */
  public getState(): BlockingState {
    return this.currentState;
  }

  /**
   * 检查是否应该激活拦截
   */
  public shouldBlockApps(): boolean {
    const config = this.stateManager.getConfig();

    // 检查全局开关是否启用
    if (!config.lanternlawEnabled) {
      return false;
    }

    // 检查当前时间是否在任意灯律时段内
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
  }

  /**
   * 检查应用是否在白名单中
   */
  public isAppWhitelisted(bundleName: string): boolean {
    const config = this.stateManager.getConfig();

    // 系统应用始终允许
    if (this.isSystemApp(bundleName)) {
      return true;
    }

    // 检查白名单
    for (const app of config.whitelistApps) {
      if (app.bundleName === bundleName && app.enabled) {
        return true;
      }
    }

    return false;
  }

  /**
   * 处理应用切换事件（由无障碍服务调用）
   */
  public async handleAppSwitch(bundleName: string): Promise<void> {
    if (!this.shouldBlockApps()) {
      Logger.debug('AppBlockingService', `不在拦截时段，忽略应用切换: ${bundleName}`);
      return;
    }

    if (this.isAppWhitelisted(bundleName)) {
      Logger.debug('AppBlockingService', `应用在白名单中，允许: ${bundleName}`);
      return;
    }

    // 需要拦截
    Logger.info('AppBlockingService', `检测到非白名单应用，准备拦截: ${bundleName}`);
    await this.blockApp(bundleName);
  }

  /**
   * 核心检测和拦截逻辑
   */
  private checkAndBlock(): void {
    try {
      const shouldBlock = this.shouldBlockApps();

      // 更新状态
      if (shouldBlock && this.currentState !== BlockingState.BLOCKING) {
        this.currentState = BlockingState.ACTIVE;
      }

      if (!shouldBlock && this.currentState !== BlockingState.IDLE) {
        this.currentState = BlockingState.IDLE;
        this.hideBlockingWindow();
      }
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '检测拦截逻辑出错');
    }
  }

  /**
   * 拦截应用
   */
  private async blockApp(bundleName: string): Promise<void> {
    try {
      Logger.info('AppBlockingService', `拦截应用: ${bundleName}`);
      this.currentState = BlockingState.BLOCKING;

      // 记录越狱尝试
      await this.stateManager.recordEscapeAttempt('APP_SWITCH', bundleName);

      // 显示拦截窗口
      this.showBlockingWindow(bundleName);

      // 延迟后返回本应用
      setTimeout(() => {
        this.navigateToSelf();
      }, 500);

    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '拦截应用失败');
    }
  }

  /**
   * 显示拦截窗口（全屏覆盖层）
   */
  private showBlockingWindow(blockedApp: string): void {
    if (this.isBlockingWindowShown) {
      return;
    }

    Logger.info('AppBlockingService', `显示拦截窗口，拦截应用: ${blockedApp}`);
    this.isBlockingWindowShown = true;

    // TODO: 使用悬浮窗或全屏窗口显示拦截提示
    // HarmonyOS 需要申请悬浮窗权限才能显示覆盖层
    // 这里暂时通过返回本应用实现拦截效果
  }

  /**
   * 隐藏拦截窗口
   */
  private hideBlockingWindow(): void {
    if (!this.isBlockingWindowShown) {
      return;
    }

    Logger.info('AppBlockingService', '隐藏拦截窗口');
    this.isBlockingWindowShown = false;
  }

  /**
   * 返回本应用
   */
  private async navigateToSelf(): Promise<void> {
    try {
      if (!this.context) {
        Logger.warn('AppBlockingService', '上下文为空，无法导航');
        return;
      }

      // 获取本应用的包名
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const bundleName = bundleInfo.name;

      const want: Want = {
        bundleName: bundleName,
        abilityName: 'EntryAbility',
        parameters: {
          blocked: true
        }
      };

      await this.context.startAbility(want);
      Logger.info('AppBlockingService', '已返回本应用');
    } catch (error) {
      Logger.exception('AppBlockingService', error instanceof Error ? error : new Error(String(error)), '导航到本应用失败');
    }
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
      // 不跨天
      return current >= start && current < end;
    } else {
      // 跨天
      return current >= start || current < end;
    }
  }

  /**
   * 检查是否是系统应用
   */
  private isSystemApp(bundleName: string): boolean {
    const systemPrefixes = [
      'com.huawei.',
      'com.ohos.',
      'android.',
      'com.android.',
      'system.'
    ];
    return systemPrefixes.some(prefix => bundleName.startsWith(prefix));
  }
}
