// entry/src/main/ets/managers/DeviceLockManager.ets

/**
 * 设备锁管理器
 * 封装HarmonyOS设备管理API，用于在宵禁期间锁定设备
 */
import deviceManager from '@ohos.distributedHardware.deviceManager';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import { ErrorHandler } from '../utils/ErrorHandler';
import { Logger } from '../utils/Logger';
import { LanternLawStateManager, LanternLawState, LanternLawStateChangeListener } from './LanternLawStateManager';
import { BusinessError } from '@ohos.base';
import { EscapeAttempt } from '../models/EscapeAttempt';

interface LockPolicyConfig {
  DISABLE_TOUCH: string;
  DISABLE_HOME_KEY: string;
  DISABLE_RECENT_APPS: string;
  RESTRICT_APPS: string;
  ALLOW_ONLY_LANTERNLAW_APP: string;
}

/**
 * 设备锁定状态枚举
 */
export enum DeviceLockState {
  UNLOCKED = 'unlocked',      // 设备未锁定
  LOCKED = 'locked',          // 设备已锁定
  ERROR = 'error',            // 锁定状态错误
  INITIALIZING = 'initializing' // 初始化中
}

/**
 * 设备管理监听器接口
 */
export interface DeviceManagerListener {
  onDeviceStateChanged(state: DeviceLockState, previousState: DeviceLockState): void;
  onDeviceTrustLevelChanged(trustLevel: number): void;
  onDeviceManagerError(error: BusinessError | Error): void;
}

/**
 * 信任级别数据接口
 */
export interface TrustLevelData {
  trustLevel?: number;
}

class DeviceLockStateListener implements LanternLawStateChangeListener {
  private manager: DeviceLockManager;

  constructor(manager: DeviceLockManager) {
    this.manager = manager;
  }

  onStateChanged(newState: LanternLawState, oldState: LanternLawState): void {
    Logger.info('DeviceLockManager', `灯律状态变化: ${newState} -> ${oldState}`);
    if (newState === LanternLawState.ACTIVE) {
      this.manager.lockDevice().catch((error: Error) => {
        Logger.exception('DeviceLockManager', error, '锁定设备失败');
      });
    } else if (newState === LanternLawState.IDLE || newState === LanternLawState.OVERRIDDEN) {
      this.manager.unlockDevice().catch((error: Error) => {
        Logger.exception('DeviceLockManager', error, '解锁设备失败');
      });
    }
  }

  onTimeUpdated(currentTime: Date): void {
    // 时间更新，不需要特殊处理
  }

  onEscapeDetected(attempt: EscapeAttempt): void {
    // 越狱检测，不需要特殊处理
  }
}

/**
 * 设备锁管理器类
 * 单例模式，提供设备锁定/解锁功能
 */
export class DeviceLockManager {
  private static instance: DeviceLockManager;

  // 设备管理器实例
  private dmInstance: deviceManager.DeviceManager | null = null;

  // 当前锁定状态
  private currentState: DeviceLockState = DeviceLockState.INITIALIZING;

  // 监听器数组
  private listeners: DeviceManagerListener[] = [];

  // 初始化标志
  private initialized: boolean = false;

  // 权限管理器
  private atManager: abilityAccessCtrl.AtManager | null = null;

  // 上下文引用
  private context: common.Context | null = null;

  // 灯律状态管理器引用
  private lanternLawStateManager: LanternLawStateManager | null = null;

  // 设备管理权限列表
  private readonly REQUIRED_PERMISSIONS: string[] = [
    'ohos.permission.DEVICE_MANAGER',
    'ohos.permission.DISTRIBUTED_DATASYNC',
    'ohos.permission.MANAGE_SECURE_SETTINGS'
  ];

  // 设备锁定策略常量 - 使用Record类型
  private readonly LOCK_POLICY: LockPolicyConfig = {
    DISABLE_TOUCH: 'disable_touch',
    DISABLE_HOME_KEY: 'disable_home_key',
    DISABLE_RECENT_APPS: 'disable_recent_apps',
    RESTRICT_APPS: 'restrict_apps',
    ALLOW_ONLY_LANTERNLAW_APP: 'allow_only_lanternlaw_app'
  };

  private constructor() {
    // 私有构造函数，确保单例模式
  }

  /**
   * 获取设备锁管理器实例
   * @returns 设备锁管理器实例
   */
  public static getInstance(): DeviceLockManager {
    if (!DeviceLockManager.instance) {
      DeviceLockManager.instance = new DeviceLockManager();
    }
    return DeviceLockManager.instance;
  }

  /**
   * 初始化设备锁管理器
   * @param context 应用上下文
   * @returns Promise<void>
   */
  public async initialize(context: common.Context): Promise<void> {
    try {
      // 验证参数
      ErrorHandler.validateParam('context', context, (ctx) => ctx !== null && ctx !== undefined);

      // 保存上下文引用
      this.context = context;

      // 获取灯律状态管理器实例
      this.lanternLawStateManager = LanternLawStateManager.getInstance();

      // 初始化权限管理器
      this.atManager = abilityAccessCtrl.createAtManager();

      // 检查权限
      const permissionsGranted = await this.checkPermissions();
      if (!permissionsGranted.every(granted => granted)) {
        Logger.warn('DeviceLockManager', '部分权限未授予，设备锁定功能可能受限');
      }

      // 创建设备管理器实例
      await this.createDeviceManager();

      // 注册灯律状态监听器
      this.registerLanternLawStateListener();

      // 标记为已初始化
      this.initialized = true;
      this.setState(DeviceLockState.UNLOCKED);

      Logger.info('DeviceLockManager', `设备锁管理器初始化成功: permissionsGranted=${permissionsGranted}, deviceManagerAvailable=${this.dmInstance !== null}`);

    } catch (error) {
      this.setState(DeviceLockState.ERROR);
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '初始化设备锁管理器时发生错误');
      throw new Error(`初始化设备锁管理器失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 创建设备管理器实例
   * @private
   */
  private async createDeviceManager(): Promise<void> {
    try {
      // TODO: deviceManager.createDeviceManager API在当前版本可能不支持此调用方式
      // 使用回调方式创建设备管理器
      Logger.warn('DeviceLockManager', '设备管理器API暂不完全支持，设备锁定功能受限');
      this.dmInstance = null;
    } catch (error) {
      Logger.error('DeviceLockManager', `创建设备管理器失败: ${error instanceof Error ? error.message : String(error)}`);
      this.dmInstance = null;
    }
  }

  /**
   * 注册灯律状态监听器
   * @private
   */
  private registerLanternLawStateListener(): void {
    if (!this.lanternLawStateManager) {
      Logger.warn('DeviceLockManager', '灯律状态管理器未初始化，无法注册监听器');
      return;
    }

    const listener: LanternLawStateChangeListener = new DeviceLockStateListener(this);

    this.lanternLawStateManager.addListener(listener);
    Logger.info('DeviceLockManager', '灯律状态监听器注册成功');
  }

  /**
   * 锁定设备
   * @returns Promise<boolean> 是否成功锁定
   */
  public async lockDevice(): Promise<boolean> {
    if (!this.initialized) {
      Logger.error('DeviceLockManager', '设备锁管理器未初始化');
      return false;
    }

    if (this.currentState === DeviceLockState.LOCKED) {
      Logger.info('DeviceLockManager', '设备已锁定，无需重复锁定');
      return true;
    }

    try {
      // 检查权限
      const permissionsGranted = await this.checkPermissions();
      if (!permissionsGranted.every(granted => granted)) {
        Logger.error('DeviceLockManager', '权限不足，无法锁定设备');
        return false;
      }

      // 检查设备管理器是否可用
      if (!this.dmInstance) {
        Logger.error('DeviceLockManager', '设备管理器不可用');
        return false;
      }

      // 在HarmonyOS中，设备锁定通常通过设备管理策略实现
      // 这里使用设备管理器的控制功能来限制设备使用
      // 具体实现可能因API版本而异

      // API 20示例：设置设备限制策略
      // 注意：实际API可能有所不同，需要参考官方文档
      const deviceId = await this.getLocalDeviceId();
      if (!deviceId) {
        Logger.error('DeviceLockManager', '无法获取本地设备ID');
        return false;
      }

      // 应用设备锁定策略
      const result = await this.applyLockPolicy(deviceId);

      if (result) {
        this.setState(DeviceLockState.LOCKED);
        Logger.info('DeviceLockManager', '设备锁定成功');
        return true;
      } else {
        Logger.error('DeviceLockManager', '设备锁定失败');
        return false;
      }

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '锁定设备时发生错误');
      return false;
    }
  }

  /**
   * 解锁设备
   * @returns Promise<boolean> 是否成功解锁
   */
  public async unlockDevice(): Promise<boolean> {
    if (!this.initialized) {
      Logger.error('DeviceLockManager', '设备锁管理器未初始化');
      return false;
    }

    if (this.currentState === DeviceLockState.UNLOCKED) {
      Logger.info('DeviceLockManager', '设备已解锁，无需重复解锁');
      return true;
    }

    try {
      // 检查权限
      const permissionsGranted = await this.checkPermissions();
      if (!permissionsGranted.every(granted => granted)) {
        Logger.error('DeviceLockManager', '权限不足，无法解锁设备');
        return false;
      }

      // 检查设备管理器是否可用
      if (!this.dmInstance) {
        Logger.error('DeviceLockManager', '设备管理器不可用');
        return false;
      }

      // 解除设备限制（示例代码，实际API可能不同）
      const deviceId = await this.getLocalDeviceId();
      if (!deviceId) {
        Logger.error('DeviceLockManager', '无法获取本地设备ID');
        return false;
      }

      // 移除设备锁定策略
      const result = await this.removeLockPolicy(deviceId);

      if (result) {
        this.setState(DeviceLockState.UNLOCKED);
        Logger.info('DeviceLockManager', '设备解锁成功');
        return true;
      } else {
        Logger.error('DeviceLockManager', '设备解锁失败');
        return false;
      }

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '解锁设备时发生错误');
      return false;
    }
  }

  /**
   * 检查设备是否被锁定
   * @returns Promise<boolean> 设备是否被锁定
   */
  public async isDeviceLocked(): Promise<boolean> {
    return this.currentState === DeviceLockState.LOCKED;
  }

  /**
   * 获取当前锁定状态
   * @returns DeviceLockState 当前锁定状态
   */
  public getCurrentState(): DeviceLockState {
    return this.currentState;
  }

  /**
   * 检查所需权限是否已授予
   * @returns Promise<boolean[]> 权限授予状态数组
   */
  public async checkPermissions(): Promise<boolean[]> {
    if (!this.atManager || !this.context) {
      Logger.warn('DeviceLockManager', '权限管理器或上下文未初始化');
      return this.REQUIRED_PERMISSIONS.map(() => false);
    }

    try {
      const grantStatuses: boolean[] = [];

      for (const permission of this.REQUIRED_PERMISSIONS) {
        try {
          // TODO: checkAccessToken requires Permissions type which is not directly accessible
          // Permissions check is best-effort; device manager is already stubbed
          grantStatuses.push(false);
        } catch (error) {
          Logger.warn('DeviceLockManager', `检查权限 ${permission} 失败: ${error instanceof Error ? error.message : String(error)}`);
          grantStatuses.push(false);
        }
      }

      Logger.debug('DeviceLockManager', `权限检查结果: ${JSON.stringify(grantStatuses)}`);

      return grantStatuses;
    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '检查权限时发生错误');
      return this.REQUIRED_PERMISSIONS.map(() => false);
    }
  }

  /**
   * 请求所需权限
   * @param context 应用上下文
   * @returns Promise<void>
   */
  public async requestPermissions(context: common.Context): Promise<void> {
    if (!this.atManager) {
      Logger.error('DeviceLockManager', '权限管理器未初始化');
      throw new Error('权限管理器未初始化');
    }


    try {
      // 检查当前权限状态
      const currentPermissions = await this.checkPermissions();
      const permissionsToRequest = this.REQUIRED_PERMISSIONS.filter(
        (_, index) => !currentPermissions[index]
      );

      if (permissionsToRequest.length === 0) {
        Logger.info('DeviceLockManager', '所有所需权限已授予');
        return;
      }

      Logger.info('DeviceLockManager', `请求权限: ${permissionsToRequest.join(', ')}`);

      // 在实际应用中，权限请求通常通过Ability的onRequestPermissionsFromUserResult回调处理
      // 这里记录需要请求的权限，实际请求由应用界面触发

      // 注意：在HarmonyOS中，权限请求通常通过系统弹窗进行
      // 这里只是记录需要请求的权限
      for (const permission of permissionsToRequest) {
        Logger.info('DeviceLockManager', `需要请求权限: ${permission}`);
      }

      // 在实际实现中，这里应该触发权限请求流程
      // 例如：abilityContext.requestPermissionsFromUser(permissionsToRequest, requestCode);

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '请求权限时发生错误');
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 应用设备锁定策略
   * @private
   * @param deviceId 设备ID
   * @returns Promise<boolean> 是否成功应用策略
   */
  private async applyLockPolicy(deviceId: string): Promise<boolean> {
    try {
      if (!this.dmInstance) {
        Logger.error('DeviceLockManager', '设备管理器不可用');
        return false;
      }

      // 在HarmonyOS API 20中，设备管理策略通常通过设备管理器设置
      // 这里使用设备管理器的控制功能来限制设备使用

      // 1. 禁用触摸输入（通过设置设备限制）
      // 2. 禁用Home键（通过设置系统属性）
      // 3. 禁用多任务切换（通过设置设备策略）
      // 4. 限制特定应用使用（通过应用管理）

      Logger.info('DeviceLockManager', `应用设备锁定策略: deviceId=${deviceId}`);

      // 在实际实现中，这里应该调用具体的设备管理API
      // 例如：await this.dmInstance.setDevicePolicy(deviceId, 'lock_policy', this.LOCK_POLICY);

      // 由于HarmonyOS API的具体实现可能因版本而异，这里记录策略应用
      // 在实际部署中，需要根据具体的API文档实现

      // 模拟成功返回
      return true;

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '应用设备锁定策略时发生错误');
      return false;
    }
  }

  /**
   * 移除设备锁定策略
   * @private
   * @param deviceId 设备ID
   * @returns Promise<boolean> 是否成功移除策略
   */
  private async removeLockPolicy(deviceId: string): Promise<boolean> {
    try {
      if (!this.dmInstance) {
        Logger.error('DeviceLockManager', '设备管理器不可用');
        return false;
      }

      Logger.info('DeviceLockManager', `移除设备锁定策略: deviceId=${deviceId}`);

      // 在实际实现中，这里应该调用具体的设备管理API来移除策略
      // 例如：await this.dmInstance.removeDevicePolicy(deviceId, 'lock_policy');

      // 模拟成功返回
      return true;

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '移除设备锁定策略时发生错误');
      return false;
    }
  }

  /**
   * 获取本地设备ID
   * @private
   * @returns Promise<string | null> 设备ID或null
   */
  private async getLocalDeviceId(): Promise<string | null> {
    if (!this.dmInstance) {
      return null;
    }

    try {
      // API 20: 设备管理器暂不支持，返回null
      Logger.warn('DeviceLockManager', '设备管理器不可用，无法获取设备ID');
      return null;
    } catch (error) {
      Logger.error('DeviceLockManager', `获取本地设备ID失败: ${error instanceof Error ? error.message : String(error)}`);
      return null;
    }
  }

  /**
   * 处理设备状态变化
   * @private
   * @param data 设备状态数据
   */
  private handleDeviceStateChange(data: object): void {
    Logger.info('DeviceLockManager', '设备状态变化');

    // 通知监听器
    for (const listener of this.listeners) {
      try {
        listener.onDeviceStateChanged(this.currentState, this.currentState);
      } catch (error) {
        Logger.error('DeviceLockManager', `通知设备状态变化监听器失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 处理设备信任级别变化
   * @private
   * @param data 信任级别数据
   */
  private handleTrustLevelChange(data: TrustLevelData): void {
    Logger.info('DeviceLockManager', '设备信任级别变化');

    // 通知监听器
    for (const listener of this.listeners) {
      try {
        listener.onDeviceTrustLevelChanged(data.trustLevel || 0);
      } catch (error) {
        Logger.error('DeviceLockManager', `通知信任级别变化监听器失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 处理设备管理器错误
   * @private
   * @param error 错误信息
   */
  private handleDeviceManagerError(error: BusinessError | Error): void {
    Logger.error('DeviceLockManager', `设备管理器错误: ${error instanceof Error ? error.message : String(error)}`);

    // 更新状态为错误
    this.setState(DeviceLockState.ERROR);

    // 通知监听器
    for (const listener of this.listeners) {
      try {
        listener.onDeviceManagerError(error);
      } catch (error) {
        Logger.error('DeviceLockManager', `通知错误监听器失败: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
  }

  /**
   * 设置状态并通知监听器
   * @private
   * @param newState 新状态
   */
  private setState(newState: DeviceLockState): void {
    const oldState = this.currentState;

    if (newState !== oldState) {
      this.currentState = newState;

      Logger.info('DeviceLockManager', `设备锁定状态变化: ${oldState} -> ${newState}`);

      // 通知监听器
      for (const listener of this.listeners) {
        try {
          listener.onDeviceStateChanged(newState, oldState);
        } catch (error) {
          Logger.error('DeviceLockManager', `通知状态变化监听器失败: ${error instanceof Error ? error.message : String(error)}`);
        }
      }
    }
  }

  /**
   * 注册监听器
   * @param listener 设备管理监听器
   */
  public addListener(listener: DeviceManagerListener): void {
    this.listeners.push(listener);
    Logger.debug('DeviceLockManager', `监听器已添加: count=${this.listeners.length}`);
  }

  /**
   * 移除监听器
   * @param listener 设备管理监听器
   */
  public removeListener(listener: DeviceManagerListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
      Logger.debug('DeviceLockManager', `监听器已移除: count=${this.listeners.length}`);
    }
  }

  /**
   * 检查是否已初始化
   * @returns boolean 是否已初始化
   */
  public isInitialized(): boolean {
    return this.initialized;
  }

  /**
   * 清理资源
   */
  public destroy(): void {
    try {
      // 清理监听器
      this.listeners.length = 0;

      // 清理设备管理器
      if (this.dmInstance) {
        try {
          // TODO: 取消所有监听器（API可能不支持off方法）
          // this.dmInstance.off('deviceStateChange');
          // this.dmInstance.off('deviceTrustLevelChange');
          // this.dmInstance.off('error');
        } catch (error) {
          Logger.warn('DeviceLockManager', `清理设备管理器监听器失败: ${error instanceof Error ? error.message : String(error)}`);
        }
        this.dmInstance = null;
      }

      // 清理其他资源
      this.atManager = null;
      this.context = null;
      this.lanternLawStateManager = null;
      this.initialized = false;
      this.setState(DeviceLockState.INITIALIZING);

      Logger.info('DeviceLockManager', '设备锁管理器资源已清理');

    } catch (error) {
      Logger.exception('DeviceLockManager', error instanceof Error ? error : String(error), '清理资源时发生错误');
    }
  }
}