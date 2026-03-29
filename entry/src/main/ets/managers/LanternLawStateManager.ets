// entry/src/main/ets/managers/LanternLawStateManager.ets
/**
 * 灯律状态管理器
 * LanternLaw State Manager
 */
import { LanternLawConfig } from '../models/LanternLawConfig';
import { DailyRecord } from '../models/DailyRecord';
import { EscapeAttempt } from '../models/EscapeAttempt';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { TimeUtils } from '../utils/TimeUtils';
import { ErrorHandler } from '../utils/ErrorHandler';
import { TimerWorker } from '../utils/TimerWorker';
import { DelayedTask } from '../utils/DelayedTask';
import { DeviceLockManager } from './DeviceLockManager';
import { BackgroundKeepAlive, KeepAliveState } from '../services/BackgroundKeepAlive';
import { ScreenTimeGuardManager } from '../services/ScreenTimeGuardManager';

export interface LanternLawConfigUpdate {
  bedtime?: string;
  wakeupTime?: string;
  lanternlawEnabled?: boolean;
  vibrationEnabled?: boolean;
  soundEnabled?: boolean;
}

export enum LanternLawState {
  IDLE = 'idle',          // 非灯律时段
  ACTIVE = 'active',      // 灯律进行中
  OVERRIDDEN = 'overridden' // 设备重启后恢复的灯律状态
}

export interface LanternLawStateChangeListener {
  onStateChanged(newState: LanternLawState, oldState: LanternLawState): void;
  onTimeUpdated(currentTime: Date): void;
  onEscapeDetected(attempt: EscapeAttempt): void;
}

export class LanternLawStateManager {
  private static instance: LanternLawStateManager;
  private currentState: LanternLawState = LanternLawState.IDLE;
  private config: LanternLawConfig = new LanternLawConfig();
  private todayRecord: DailyRecord | null = null;
  private listeners: LanternLawStateChangeListener[] = [];
  private updateTimer: TimerWorker | null = null;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 灯律状态持续时间（分钟）
  private lanternlawStartTime: Date | null = null;
  private lanternlawEndTime: Date | null = null;
  private stateLock: boolean = false; // 状态锁，防止竞态条件
  private emergencyUnlockTask: DelayedTask | null = null; // 紧急解锁恢复任务

  // 后台保活服务
  private backgroundKeepAlive: BackgroundKeepAlive = BackgroundKeepAlive.getInstance();

  private constructor() {}

  public static getInstance(): LanternLawStateManager {
    if (!LanternLawStateManager.instance) {
      LanternLawStateManager.instance = new LanternLawStateManager();
    }
    return LanternLawStateManager.instance;
  }


  // 初始化管理器
  public async initialize(context: Context): Promise<void> {
    try {
      // 验证参数
      ErrorHandler.validateParam('context', context, (ctx) => ctx !== null && ctx !== undefined);

      // 初始化数据库
      await ErrorHandler.safeAsync('初始化数据库', () => this.database.initialize(context), true);

      // 初始化设备锁管理器
      await this.initializeDeviceLockManager(context);

      // 初始化后台保活服务
      await this.initializeBackgroundKeepAlive();

      // 加载配置
      await this.loadConfig();

      // 加载今日记录
      await this.loadTodayRecord();

      // 计算当前状态
      await this.calculateCurrentState();

      // 启动定时更新
      this.startUpdateTimer();

      console.log('灯律状态管理器初始化成功');
    } catch (error) {
      ErrorHandler.handleAsyncError('灯律状态管理器初始化', error, true);
    }
  }

  // 初始化设备锁管理器
  private async initializeDeviceLockManager(context: Context): Promise<void> {
    try {
      const deviceLockManager = DeviceLockManager.getInstance();
      await deviceLockManager.initialize(context);
      console.log('设备锁管理器初始化成功');
    } catch (error) {
      console.error('设备锁管理器初始化失败:', error);
      // 设备锁管理器初始化失败不应阻止整个应用启动
      // 但需要记录错误以便调试
    }
  }

  // 初始化后台保活服务
  private async initializeBackgroundKeepAlive(): Promise<void> {
    try {
      await this.backgroundKeepAlive.initialize();
      console.log('后台保活服务初始化成功');
    } catch (error) {
      console.error('后台保活服务初始化失败:', error);
      // 后台保活服务初始化失败不应阻止整个应用启动
      // 但需要记录错误以便调试
    }
  }

  // 加载配置
  private async loadConfig(): Promise<void> {
    console.info('[LanternLawStateManager] loadConfig 开始执行');
    await ErrorHandler.safeAsync('加载配置', async () => {
      console.info('[LanternLawStateManager] 准备从数据库读取配置');
      const configJson = await this.database.getConfig('lanternlaw_config');
      console.info('[LanternLawStateManager] 数据库返回的 configJson: ' + (configJson ? configJson.substring(0, 200) + '...' : 'null'));
      if (configJson) {
        console.info('[LanternLawStateManager] 准备解析 JSON');
        this.config = LanternLawConfig.fromJSON(configJson);
        console.info('[LanternLawStateManager] 解析后的 config.timeRanges: ' + JSON.stringify(this.config.timeRanges));
        console.info('[LanternLawStateManager] config.timeRanges 长度: ' + this.config.timeRanges.length);
      } else {
        console.info('[LanternLawStateManager] 数据库中没有配置，使用默认值');
      }
    });
    console.info('[LanternLawStateManager] loadConfig 完成，当前 config.timeRanges 长度: ' + this.config.timeRanges.length);
  }

  // 保存配置
  public async saveConfig(config: LanternLawConfig): Promise<void> {
    console.info('[LanternLawStateManager] saveConfig 开始执行');
    await ErrorHandler.safeAsync('保存配置', async () => {
      // 验证配置
      console.info('[LanternLawStateManager] 验证配置');
      ErrorHandler.validateParam('config', config, (cfg) => cfg !== null && cfg.isValid());

      console.info('[LanternLawStateManager] 配置验证通过，准备保存');
      this.config = config;

      console.info('[LanternLawStateManager] 准备调用 database.saveConfig');
      await this.database.saveConfig('lanternlaw_config', config.toJSON());
      console.info('[LanternLawStateManager] database.saveConfig 完成');

      // 重新计算状态
      await this.calculateCurrentState();
      console.info('[LanternLawStateManager] calculateCurrentState 完成');

      // 同步 Screen Time Guard 策略
      try {
        const guardManager = ScreenTimeGuardManager.getInstance();
        if (this.config.lanternlawEnabled) {
          await guardManager.syncStrategies(this.config.timeRanges, this.config.whitelistApps);
        } else {
          await guardManager.stopAllStrategies();
        }
        console.info('[LanternLawStateManager] Screen Time Guard 策略同步完成');
      } catch (guardError) {
        console.error('[LanternLawStateManager] Screen Time Guard 策略同步失败: ' + JSON.stringify(guardError));
      }
    }, true);
    console.info('[LanternLawStateManager] saveConfig 完成');
  }

  // 加载今日记录
  private async loadTodayRecord(): Promise<void> {
    await ErrorHandler.safeAsync('加载今日记录', async () => {
      const recordData = await this.database.getTodayRecord();
      if (recordData) {
        this.todayRecord = DailyRecord.fromJSON(JSON.stringify(recordData));
      } else {
        // 创建新记录
        this.todayRecord = new DailyRecord();
        this.todayRecord.id = DailyRecord.generateId();
        this.todayRecord.date = new Date().toISOString().split('T')[0];
        this.todayRecord.createdAt = Date.now();
        this.todayRecord.updatedAt = Date.now();
      }
    });
  }

  // 保存今日记录
  public async saveTodayRecord(): Promise<void> {
    if (this.todayRecord) {
      const record = this.todayRecord;
      await ErrorHandler.safeAsync('保存今日记录', async () => {
        record.updatedAt = Date.now();
        await this.database.saveDailyRecord(record);
      });
    }
  }

  // 计算当前状态（线程安全）
  private async calculateCurrentState(): Promise<void> {
    // 检查是否已经有状态更新在进行中
    if (this.stateLock) {
      console.warn('状态更新正在进行中，跳过本次计算');
      return;
    }

    try {
      // 获取锁
      this.stateLock = true;

      if (!this.config.lanternlawEnabled) {
        await this.setState(LanternLawState.IDLE);
        return;
      }

      const now = new Date();
      const bedtime = TimeUtils.parseTimeString(this.config.bedtime);
      const wakeupTime = TimeUtils.parseTimeString(this.config.wakeupTime);

      // 计算今天的灯律时间段
      const lanternlawStart = new Date(now);
      lanternlawStart.setHours(bedtime.hour, bedtime.minute, 0, 0);

      const lanternlawEnd = new Date(now);
      lanternlawEnd.setHours(wakeupTime.hour, wakeupTime.minute, 0, 0);

      // 如果解锁时间在就寝时间之前（跨夜）
      if (wakeupTime.hour < bedtime.hour ||
          (wakeupTime.hour === bedtime.hour && wakeupTime.minute < bedtime.minute)) {
        lanternlawEnd.setDate(lanternlawEnd.getDate() + 1);
      }

      this.lanternlawStartTime = lanternlawStart;
      this.lanternlawEndTime = lanternlawEnd;

      // 检查是否在灯律时间内
      if (now >= lanternlawStart && now < lanternlawEnd) {
        await this.setState(LanternLawState.ACTIVE);

        // 如果是新进入灯律状态，初始化记录
        if (this.todayRecord && this.todayRecord.lanternlawStart === 0) {
          this.todayRecord.lanternlawStart = lanternlawStart.getTime();
          this.todayRecord.lanternlawEnd = lanternlawEnd.getTime();
          await this.saveTodayRecord();
        }
      } else {
        // 检查是否刚离开灯律状态
        const wasActive = this.currentState === LanternLawState.ACTIVE;
        await this.setState(LanternLawState.IDLE);

        // 如果刚离开灯律状态，计算实际时长
        if (wasActive && this.todayRecord) {
          const actualDuration = Math.floor((now.getTime() - lanternlawStart.getTime()) / (1000 * 60));
          this.todayRecord.actualDuration = Math.max(0, actualDuration);
          this.todayRecord.success = this.todayRecord.escapeCount === 0;
          await this.saveTodayRecord();
        }
      }
    } finally {
      // 释放锁
      this.stateLock = false;
    }
  }

  // 设置状态（线程安全）
  private async setState(newState: LanternLawState): Promise<void> {
    // 检查是否已经有状态更新在进行中
    if (this.stateLock) {
      console.warn('状态更新正在进行中，跳过本次更新');
      return;
    }

    try {
      // 获取锁
      this.stateLock = true;

      const oldState = this.currentState;

      if (newState !== oldState) {
        this.currentState = newState;

        // 通知监听器
        for (const listener of this.listeners) {
          try {
            listener.onStateChanged(newState, oldState);
          } catch (error) {
            console.error(`监听器通知失败: ${JSON.stringify(error)}`);
          }
        }

        // 状态变化处理
        await this.handleStateChange(newState, oldState);
      }
    } finally {
      // 释放锁
      this.stateLock = false;
    }
  }

  // 处理状态变化
  private async handleStateChange(newState: LanternLawState, oldState: LanternLawState): Promise<void> {
    switch (newState) {
      case LanternLawState.ACTIVE:
        console.log('进入灯律状态');
        // 启动后台保活服务
        await this.startBackgroundKeepAlive();
        // 触发设备锁定
        await this.lockDeviceForLanternLaw();
        break;
      case LanternLawState.IDLE:
        console.log('离开灯律状态');
        // 停止后台保活服务
        await this.stopBackgroundKeepAlive();
        // 触发设备解锁
        await this.unlockDeviceFromLanternLaw();
        break;
    }
  }

  // 锁定设备用于灯律
  private async lockDeviceForLanternLaw(): Promise<void> {
    try {
      const deviceLockManager = DeviceLockManager.getInstance();
      if (deviceLockManager.isInitialized()) {
        const success = await deviceLockManager.lockDevice();
        if (success) {
          console.log('设备锁定成功');
        } else {
          console.error('设备锁定失败');
        }
      } else {
        console.warn('设备锁管理器未初始化，无法锁定设备');
      }
    } catch (error) {
      console.error('锁定设备时发生错误:', error);
    }
  }

  // 解锁设备从灯律
  private async unlockDeviceFromLanternLaw(): Promise<void> {
    try {
      const deviceLockManager = DeviceLockManager.getInstance();
      if (deviceLockManager.isInitialized()) {
        const success = await deviceLockManager.unlockDevice();
        if (success) {
          console.log('设备解锁成功');
        } else {
          console.error('设备解锁失败');
        }
      } else {
        console.warn('设备锁管理器未初始化，无法解锁设备');
      }
    } catch (error) {
      console.error('解锁设备时发生错误:', error);
    }
  }

  // 启动后台保活服务
  private async startBackgroundKeepAlive(): Promise<void> {
    try {
      if (!this.backgroundKeepAlive.isRunning()) {
        await this.backgroundKeepAlive.startKeepAlive();
        console.log('后台保活服务已启动');
      }
    } catch (error) {
      console.error('启动后台保活服务失败:', error);
      // 后台保活失败不应阻止宵禁功能，但记录错误
    }
  }

  // 停止后台保活服务
  private async stopBackgroundKeepAlive(): Promise<void> {
    try {
      if (this.backgroundKeepAlive.isRunning()) {
        await this.backgroundKeepAlive.stopKeepAlive();
        console.log('后台保活服务已停止');
      }
    } catch (error) {
      console.error('停止后台保活服务失败:', error);
    }
  }

  // 启动定时更新（使用HarmonyOS Worker）
  private startUpdateTimer(): void {
    try {
      // 创建定时器Worker
      this.updateTimer = new TimerWorker();

      // 每分钟检查一次状态
      const success = this.updateTimer.start(60000, async () => {
        await this.calculateCurrentState();

        // 通知监听器时间更新
        const now = new Date();
        for (const listener of this.listeners) {
          try {
            listener.onTimeUpdated(now);
          } catch (error) {
            ErrorHandler.handleSyncError('时间更新通知', error);
          }
        }
      });

      if (!success) {
        console.error('启动定时器失败');
        this.updateTimer = null;
      }
    } catch (error) {
      ErrorHandler.handleSyncError('启动定时更新', error);
      this.updateTimer = null;
    }
  }

  // 停止定时更新
  public stop(): void {
    if (this.updateTimer !== null) {
      this.updateTimer.stop();
      this.updateTimer = null;
    }
  }

  // 清理所有资源
  public async destroy(): Promise<void> {
    // 停止定时器
    if (this.updateTimer !== null) {
      this.updateTimer.destroy();
      this.updateTimer = null;
    }

    // 取消紧急解锁恢复任务
    if (this.emergencyUnlockTask) {
      this.emergencyUnlockTask.destroy();
      this.emergencyUnlockTask = null;
    }

    // 停止后台保活服务
    await this.stopBackgroundKeepAlive();

    // 清理设备锁管理器
    this.cleanupDeviceLockManager();

    // 清理监听器数组
    this.listeners.length = 0;

    // 清理其他资源
    this.lanternlawStartTime = null;
    this.lanternlawEndTime = null;
    this.todayRecord = null;
    this.stateLock = false;

    console.log('灯律状态管理器资源已清理');
  }

  // 清理设备锁管理器
  private cleanupDeviceLockManager(): void {
    try {
      const deviceLockManager = DeviceLockManager.getInstance();
      if (deviceLockManager.isInitialized()) {
        deviceLockManager.destroy();
        console.log('设备锁管理器资源已清理');
      }
    } catch (error) {
      console.error('清理设备锁管理器时发生错误:', error);
    }
  }

  // 注册监听器
  public addListener(listener: LanternLawStateChangeListener): void {
    this.listeners.push(listener);
  }

  // 移除监听器
  public removeListener(listener: LanternLawStateChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  // 获取当前状态
  public getCurrentState(): LanternLawState {
    return this.currentState;
  }

  // 获取配置
  public getConfig(): LanternLawConfig {
    // 返回配置的深拷贝
    return this.config.clone();
  }

  // 获取今日记录
  public getTodayRecord(): DailyRecord | null {
    // 返回记录的深拷贝
    return this.todayRecord ? this.todayRecord.clone() : null;
  }

  // 获取今日记录（别名，用于兼容）
  public getCurrentStateRecord(): DailyRecord | null {
    return this.getTodayRecord();
  }

  // 更新配置
  public async updateConfig(newConfig: LanternLawConfigUpdate): Promise<void> {
    await ErrorHandler.safeAsync('更新配置', async () => {
      // 验证参数
      if (newConfig.bedtime !== undefined) {
        ErrorHandler.validateStringNotEmpty('bedtime', newConfig.bedtime);
      }
      if (newConfig.wakeupTime !== undefined) {
        ErrorHandler.validateStringNotEmpty('wakeupTime', newConfig.wakeupTime);
      }

      // 更新配置
      if (newConfig.bedtime !== undefined) {
        this.config.bedtime = newConfig.bedtime;
      }
      if (newConfig.wakeupTime !== undefined) {
        this.config.wakeupTime = newConfig.wakeupTime;
      }
      if (newConfig.lanternlawEnabled !== undefined) {
        this.config.lanternlawEnabled = newConfig.lanternlawEnabled;
      }

      // 保存配置
      await this.saveConfig(this.config);

      // 重新计算状态
      await this.calculateCurrentState();
    });
  }

  // 记录越狱尝试
  public async recordEscapeAttempt(type: string, appName: string = ''): Promise<void> {
    await ErrorHandler.safeAsync('记录越狱尝试', async () => {
      if (!this.todayRecord) return;

      // 验证参数
      ErrorHandler.validateStringNotEmpty('type', type);

      this.todayRecord.escapeCount++;
      this.todayRecord.updatedAt = Date.now();

      await this.saveTodayRecord();

      // 通知监听器
      const attempt = new EscapeAttempt();
      attempt.timestamp = Date.now();
      attempt.type = type;
      attempt.appName = appName;
      attempt.count = 1;
      attempt.totalEscapeCount = this.todayRecord.escapeCount;

      for (const listener of this.listeners) {
        try {
          listener.onEscapeDetected(attempt);
        } catch (error) {
          ErrorHandler.handleSyncError('越狱检测通知', error);
        }
      }
    });
  }

  // 计算剩余时间（分钟）
  public getRemainingMinutes(): number {
    if (this.currentState !== LanternLawState.ACTIVE || !this.lanternlawEndTime) {
      return 0;
    }

    const now = new Date();
    const remainingMs = this.lanternlawEndTime.getTime() - now.getTime();
    return Math.max(0, Math.floor(remainingMs / (1000 * 60)));
  }

  // 使用紧急解锁
  public async useEmergencyUnlock(): Promise<boolean> {
    return await ErrorHandler.safeAsync('使用紧急解锁', async () => {
      if (this.config.emergencyUsed >= this.config.emergencyUnlocks) {
        return false;
      }

      this.config.emergencyUsed++;
      await this.saveConfig(this.config);

      // 临时退出灯律状态（例如15分钟）
      await this.setState(LanternLawState.IDLE);

      // 取消现有的恢复任务
      if (this.emergencyUnlockTask) {
        this.emergencyUnlockTask.cancel();
      }

      // 15分钟后恢复灯律状态
      this.emergencyUnlockTask = new DelayedTask();
      this.emergencyUnlockTask.schedule(15 * 60 * 1000, async () => {
        await this.calculateCurrentState();
        this.emergencyUnlockTask = null;
      });

      return true;
    }, false) || false;
  }
}
