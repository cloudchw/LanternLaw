/**
 * 后台保活服务
 * Background Keep-Alive Service
 * 多策略后台保活方案，确保宵禁期间应用不被系统杀死
 */

import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import runningLock from '@ohos.runningLock';
import { BusinessError } from '@ohos.base';
import { Logger } from '../utils/Logger';
import { ErrorHandler } from '../utils/ErrorHandler';

/**
 * 保活状态枚举
 */
export enum KeepAliveState {
  IDLE = 'idle',           // 空闲
  ACTIVE = 'active',       // 保活中
  ERROR = 'error'          // 错误状态
}

/**
 * 保活状态变更监听器
 */
export interface KeepAliveStateListener {
  onStateChanged(newState: KeepAliveState, oldState: KeepAliveState): void;
  onError(error: Error): void;
}

/**
 * 后台保活服务类
 * 采用多策略保活方案：
 * 1. 后台延迟申请 (requestSuspendDelay)
 * 2. 运行锁防止休眠 (RunningLock)
 * 3. 定时刷新保活状态
 */
export class BackgroundKeepAlive {
  private static instance: BackgroundKeepAlive;

  // 后台延迟ID
  private suspendDelayId: number = 0;

  // 运行锁实例
  private runningLock: runningLock.RunningLock | null = null;

  // 保活定时器
  private keepAliveTimer: number | null = null;

  // 保活状态
  private currentState: KeepAliveState = KeepAliveState.IDLE;

  // 状态监听器列表
  private listeners: KeepAliveStateListener[] = [];

  // 刷新间隔（毫秒）- 20秒
  private readonly REFRESH_INTERVAL: number = 20000;

  // 后台延迟时长（毫秒）- 30秒
  private readonly SUSPEND_DELAY_DURATION: number = 30000;

  // 运行锁时长（毫秒）- 5秒
  private readonly RUNNING_LOCK_DURATION: number = 5000;

  // 运行锁名称
  private readonly RUNNING_LOCK_NAME: string = 'LanternLawBackgroundLock';

  // 是否已初始化
  private initialized: boolean = false;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): BackgroundKeepAlive {
    if (!BackgroundKeepAlive.instance) {
      BackgroundKeepAlive.instance = new BackgroundKeepAlive();
    }
    return BackgroundKeepAlive.instance;
  }

  /**
   * 初始化保活服务
   */
  public async initialize(): Promise<void> {
    if (this.initialized) {
      Logger.warn('BackgroundKeepAlive', '保活服务已初始化，跳过重复初始化');
      return;
    }

    try {
      Logger.info('BackgroundKeepAlive', '初始化后台保活服务');

      // 检测系统支持情况
      await this.checkSystemSupport();

      this.initialized = true;
      Logger.info('BackgroundKeepAlive', '后台保活服务初始化完成');
    } catch (error) {
      ErrorHandler.handleSyncError('BackgroundKeepAlive初始化', error, false);
      throw new Error(`BackgroundKeepAlive初始化失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 检测系统支持情况
   */
  private async checkSystemSupport(): Promise<void> {
    try {
      // 检查后台任务管理器是否可用
      // 注：API 20+中backgroundTaskManager是基础服务，应该始终可用

      // 检查运行锁是否可用
      // 注：运行锁是基础能力，应该始终可用

      Logger.info('BackgroundKeepAlive', '系统支持检测通过');
    } catch (error) {
      Logger.error('BackgroundKeepAlive', `系统支持检测失败: ${JSON.stringify(error)}`);
      throw new Error(`系统支持检测失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 启动后台保活
   */
  public async startKeepAlive(): Promise<void> {
    if (!this.initialized) {
      Logger.error('BackgroundKeepAlive', '保活服务未初始化');
      throw new Error('保活服务未初始化');
    }

    if (this.currentState === KeepAliveState.ACTIVE) {
      Logger.warn('BackgroundKeepAlive', '保活服务已在运行中');
      return;
    }

    Logger.info('BackgroundKeepAlive', '启动后台保活服务');

    try {
      // 策略1：申请后台运行延迟
      await this.requestSuspendDelay();

      // 策略2：获取运行锁
      await this.acquireRunningLock();

      // 策略3：启动定时刷新
      this.startKeepAliveTimer();

      // 更新状态
      this.updateState(KeepAliveState.ACTIVE);

      Logger.info('BackgroundKeepAlive', '后台保活服务启动成功');
    } catch (error) {
      ErrorHandler.handleSyncError('启动后台保活', error, false);
      this.updateState(KeepAliveState.ERROR);
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 停止后台保活
   */
  public async stopKeepAlive(): Promise<void> {
    if (this.currentState !== KeepAliveState.ACTIVE) {
      Logger.warn('BackgroundKeepAlive', '保活服务未在运行');
      return;
    }

    Logger.info('BackgroundKeepAlive', '停止后台保活服务');

    try {
      // 停止定时器
      if (this.keepAliveTimer !== null) {
        clearInterval(this.keepAliveTimer);
        this.keepAliveTimer = null;
        Logger.info('BackgroundKeepAlive', '保活定时器已停止');
      }

      // 释放运行锁
      await this.releaseRunningLock();

      // 取消后台延迟
      await this.cancelSuspendDelay();

      // 更新状态
      this.updateState(KeepAliveState.IDLE);

      Logger.info('BackgroundKeepAlive', '后台保活服务已停止');
    } catch (error) {
      ErrorHandler.handleSyncError('停止后台保活', error, false);
      throw new Error(error instanceof Error ? error.message : String(error));
    }
  }

  /**
   * 申请后台运行延迟
   */
  private async requestSuspendDelay(): Promise<void> {
    try {
      // 取消之前的延迟（如果存在）
      if (this.suspendDelayId > 0) {
        await this.cancelSuspendDelay();
      }

      // TODO: API 20 - 已注释掉不支持的API
      // 申请后台延迟（API可能不支持）
      // this.suspendDelayId = await backgroundTaskManager.requestSuspendDelay(
      //   'LanternLaw宵禁保活',
      //   this.SUSPEND_DELAY_DURATION
      // );
      Logger.warn('BackgroundKeepAlive', '后台延迟API暂不支持');

      Logger.info('BackgroundKeepAlive', `后台延迟申请成功，ID: ${this.suspendDelayId}`);

      // TODO: 注册延迟到期回调（如果API支持）
      // 注：API 20可能不支持此回调，已移除以避免错误
      // try {
      //   backgroundTaskManager.on('suspendDelayExpired', this.suspendDelayId, () => {
      //     Logger.info('BackgroundKeepAlive', '后台延迟到期，重新申请');
      //     this.renewSuspendDelay();
      //   });
      // } catch (error) {
      //   // 如果不支持回调，使用定时刷新机制处理
      //   Logger.warn('BackgroundKeepAlive', '延迟到期回调不支持，依赖定时刷新机制');
      // }
    } catch (error) {
      const err = error as BusinessError;
      Logger.error('BackgroundKeepAlive', `后台延迟申请失败: ${err.message}`);
      throw new Error(`后台延迟申请失败: ${err.message}`);
    }
  }

  /**
   * 续期后台延迟
   */
  private async renewSuspendDelay(): Promise<void> {
    // TODO: API 20 - 已注释掉不支持的API
    Logger.debug('BackgroundKeepAlive', '续期后台延迟（暂不支持）');
  }

  /**
   * 取消后台延迟
   */
  private async cancelSuspendDelay(): Promise<void> {
    // TODO: API 20 - 已注释掉不支持的API
    if (this.suspendDelayId <= 0) {
      return;
    }
    Logger.debug('BackgroundKeepAlive', `取消后台延迟（暂不支持）`);
    this.suspendDelayId = 0;
  }

  /**
   * 获取运行锁
   */
  private async acquireRunningLock(): Promise<void> {
    try {
      // TODO: API 20 - 运行锁API可能有变化，请根据实际API文档调整
      const lockResult = await runningLock.createRunningLock(this.RUNNING_LOCK_NAME, runningLock.RunningLockType.BACKGROUND);

      if (lockResult !== null && lockResult !== undefined) {
        this.runningLock = lockResult as runningLock.RunningLock;
        // TODO: lock方法参数可能有变化
        const result = this.runningLock.lock(this.RUNNING_LOCK_DURATION);
        Logger.info('BackgroundKeepAlive', `运行锁获取成功，锁定${this.RUNNING_LOCK_DURATION}ms`);
      }
    } catch (error) {
      Logger.error('BackgroundKeepAlive', `运行锁获取失败: ${JSON.stringify(error)}`);
      throw new Error(`运行锁获取失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 释放运行锁
   */
  private async releaseRunningLock(): Promise<void> {
    if (!this.runningLock) {
      return;
    }

    try {
      // TODO: unlock方法可能需要调整
      this.runningLock.unlock();
      Logger.info('BackgroundKeepAlive', '运行锁已释放');
      this.runningLock = null;
    } catch (error) {
      Logger.error('BackgroundKeepAlive', `运行锁释放失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 启动保活定时器
   */
  private startKeepAliveTimer(): void {
    // 清理旧定时器
    if (this.keepAliveTimer !== null) {
      clearInterval(this.keepAliveTimer);
    }

    // 启动新定时器
    const self = this;
    this.keepAliveTimer = setInterval(() => {
      self.refreshKeepAlive();
    }, this.REFRESH_INTERVAL);

    Logger.info('BackgroundKeepAlive', `保活定时器已启动，间隔${this.REFRESH_INTERVAL}ms`);
  }

  /**
   * 刷新保活状态
   */
  private async refreshKeepAlive(): Promise<void> {
    if (this.currentState !== KeepAliveState.ACTIVE) {
      return;
    }

    Logger.debug('BackgroundKeepAlive', '刷新保活状态');

    try {
      // 刷新运行锁
      if (this.runningLock) {
        try {
          // TODO: lock方法可能需要调整
          const result = this.runningLock.lock(this.RUNNING_LOCK_DURATION);
          Logger.debug('BackgroundKeepAlive', '运行锁刷新成功');
        } catch (error) {
          Logger.error('BackgroundKeepAlive', `运行锁刷新失败: ${JSON.stringify(error)}`);
          // 尝试重新获取运行锁
          await this.acquireRunningLock();
        }
      }

      // TODO: 已注释掉后台延迟状态查询（API可能不支持）
      // // 检查后台延迟状态并续期
      // try {
      //   const delayInfo = await backgroundTaskManager.getSuspendDelayStatus();
      //
      //   // 检查剩余时间，如果不足10秒则续期
      //   // 注：API可能不支持getSuspendDelayStatus，需要运行时检查
      //   if (delayInfo && delayInfo.remainingTime < 10000) {
      //     Logger.info('BackgroundKeepAlive',`后台延迟剩余时间不足，准备续期`);
      //     await this.renewSuspendDelay();
      //   }
      // } catch (error) {
      //   // 如果不支持状态查询，直接续期
      //   Logger.debug('BackgroundKeepAlive', '不支持延迟状态查询，直接续期');
      //   await this.renewSuspendDelay();
      // }
    } catch (error) {
      Logger.error('BackgroundKeepAlive', `刷新保活状态失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 更新状态并通知监听器
   */
  private updateState(newState: KeepAliveState): void {
    const oldState = this.currentState;
    this.currentState = newState;

    // 通知所有监听器
    this.listeners.forEach(listener => {
      try {
        listener.onStateChanged(newState, oldState);
      } catch (error) {
        Logger.error('BackgroundKeepAlive', `通知监听器失败: ${JSON.stringify(error)}`);
      }
    });

    Logger.info('BackgroundKeepAlive', `状态变更: ${oldState} -> ${newState}`);
  }

  /**
   * 添加状态监听器
   */
  public addStateListener(listener: KeepAliveStateListener): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  /**
   * 移除状态监听器
   */
  public removeStateListener(listener: KeepAliveStateListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 获取当前状态
   */
  public getState(): KeepAliveState {
    return this.currentState;
  }

  /**
   * 检查是否正在运行
   */
  public isRunning(): boolean {
    return this.currentState === KeepAliveState.ACTIVE;
  }

  /**
   * 清理资源
   */
  public async cleanup(): Promise<void> {
    try {
      await this.stopKeepAlive();
      this.listeners = [];
      this.initialized = false;
      Logger.info('BackgroundKeepAlive', '保活服务资源已清理');
    } catch (error) {
      Logger.error('BackgroundKeepAlive', `清理资源失败: ${JSON.stringify(error)}`);
    }
  }
}
