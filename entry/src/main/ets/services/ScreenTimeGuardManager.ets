/**
 * 屏幕时间守护管理器
 * Screen Time Guard Manager
 *
 * 封装 HarmonyOS 6 Screen Time Guard Kit API
 * 负责创建/同步/清理系统级应用管控策略
 */
import { guardService, appPicker } from '@kit.ScreenTimeGuardKit';
import common from '@ohos.app.ability.common';
import { BusinessError } from '@ohos.base';
import { Logger } from '../utils/Logger';
import { TimeRange } from '../models/TimeRange';
import { WhitelistApp } from '../models/WhitelistApp';

const TAG = 'ScreenTimeGuardManager';

// 策略名前缀，用于区分掌灯人创建的策略
const STRATEGY_PREFIX = 'lanternlaw_';

export class ScreenTimeGuardManager {
  private static instance: ScreenTimeGuardManager;
  private isAuthorized: boolean = false;

  private constructor() {}

  public static getInstance(): ScreenTimeGuardManager {
    if (!ScreenTimeGuardManager.instance) {
      ScreenTimeGuardManager.instance = new ScreenTimeGuardManager();
    }
    return ScreenTimeGuardManager.instance;
  }

  /**
   * 请求用户授权
   * 首次使用必须调用，系统会弹出授权弹窗
   */
  async requestUserAuth(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const status = await guardService.getUserAuthStatus();
      if (status === guardService.AuthStatus.AUTH_GRANTED) {
        Logger.info(TAG, '用户已授权');
        this.isAuthorized = true;
        return true;
      }

      await guardService.requestUserAuth(context);
      this.isAuthorized = true;
      Logger.info(TAG, '用户授权成功');
      return true;
    } catch (error) {
      const errCode = (error as BusinessError).code;
      if (errCode === 1019000002) {
        Logger.warn(TAG, '用户未授权');
      } else {
        Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '请求授权失败');
      }
      return false;
    }
  }

  /**
   * 查询用户授权状态
   */
  async checkAuthStatus(): Promise<boolean> {
    try {
      const status = await guardService.getUserAuthStatus();
      this.isAuthorized = status === guardService.AuthStatus.AUTH_GRANTED;
      return this.isAuthorized;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '查询授权状态失败');
      return false;
    }
  }

  /**
   * 打开系统应用选择器
   * 返回用户选中的应用 token 列表
   */
  async openAppPicker(
    context: common.Context,
    preselectedTokens: string[] = []
  ): Promise<string[]> {
    try {
      const appSelection: guardService.AppInfo = {
        appTokens: preselectedTokens
      };
      const tokens = await appPicker.startAppPicker(context, appSelection);
      Logger.info(TAG, `应用选择器返回 ${tokens.length} 个应用`);
      return tokens;
    } catch (error) {
      const errCode = (error as BusinessError).code;
      if (errCode === 1019000003) {
        Logger.info(TAG, '用户取消了应用选择');
      } else {
        Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '打开应用选择器失败');
      }
      return [];
    }
  }

  /**
   * 打开系统应用展示页
   * 由系统原生页面展示已选应用的名称和图标，用户可点击图标跳转
   * @returns true 成功打开，false 失败（模拟器不支持）
   */
  async openAppForm(context: common.Context, tokens: string[]): Promise<boolean> {
    try {
      const appSelection: guardService.AppInfo = {
        appTokens: tokens
      };
      await appPicker.startAppForm(context, appSelection, '管控应用', true);
      Logger.info(TAG, `应用展示页已打开`);
      return true;
    } catch (error) {
      const errCode = (error as BusinessError).code;
      if (errCode === 1019000003) {
        Logger.info(TAG, '用户关闭了应用展示页');
        return false;
      } else if (errCode === 1019000001) {
        Logger.warn(TAG, '应用展示页不可用（模拟器可能不支持此功能）');
        return false;
      } else {
        Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '打开应用展示页失败');
        return false;
      }
    }
  }

  /**
   * 同步所有管控策略
   * 根据当前配置（时间段 + 白名单应用）创建/更新/删除系统策略
   */
  async syncStrategies(timeRanges: TimeRange[], whitelistApps: WhitelistApp[]): Promise<void> {
    if (!this.isAuthorized) {
      Logger.warn(TAG, '未授权，跳过策略同步');
      return;
    }

    try {
      // 1. 查询现有策略
      const existingStrategies = await guardService.queryGuardStrategies();
      const existingMap: Map<string, guardService.GuardStrategy> = new Map();
      for (const strategy of existingStrategies) {
        if (strategy.name.startsWith(STRATEGY_PREFIX)) {
          existingMap.set(strategy.name, strategy);
        }
      }

      // 2. 收集白名单应用的 appToken（仅 enabled 的）
      const enabledAppTokens: string[] = [];
      for (const app of whitelistApps) {
        if (app.enabled && app.appToken && app.appToken.length > 0) {
          enabledAppTokens.push(app.appToken);
        }
      }

      // 3. 计算需要的策略
      const desiredNames: Set<string> = new Set();
      for (const range of timeRanges) {
        if (!range.enabled) continue;

        // 策略名只允许字母、数字、下划线，替换 range.id 中的连字符
        const safeId = range.id.replace(/-/g, '_').replace(/[^a-zA-Z0-9_]/g, '');
        const strategyName = `${STRATEGY_PREFIX}${safeId}`;
        desiredNames.add(strategyName);

        const strategy: guardService.GuardStrategy = {
          name: strategyName,
          timeStrategy: {
            type: guardService.TimeStrategyType.START_END_TIME_TYPE,
            startTime: range.startTime,
            endTime: range.endTime
          },
          appInfo: {
            appTokens: enabledAppTokens
          },
          appRestrictionType: guardService.RestrictionType.TRUSTLIST_TYPE
        };

        if (existingMap.has(strategyName)) {
          // 更新现有策略
          try {
            await guardService.updateGuardStrategy(strategyName, strategy);
            Logger.info(TAG, `更新策略: ${strategyName}`);
          } catch (error) {
            Logger.warn(TAG, `更新策略失败 ${strategyName}: ${JSON.stringify(error)}`);
          }
        } else {
          // 创建新策略
          try {
            await guardService.addGuardStrategy(strategy);
            Logger.info(TAG, `创建策略: ${strategyName}`);
          } catch (error) {
            Logger.warn(TAG, `创建策略失败 ${strategyName}: ${JSON.stringify(error)}`);
          }
        }
      }

      // 4. 删除不再需要的策略
      const existingNames = Array.from(existingMap.keys());
      for (const name of existingNames) {
        if (!desiredNames.has(name)) {
          try {
            // 先停止再删除
            await guardService.stopGuardStrategy(name).catch(() => {});
            await guardService.removeGuardStrategy(name);
            Logger.info(TAG, `删除策略: ${name}`);
          } catch (error) {
            Logger.warn(TAG, `删除策略失败 ${name}: ${JSON.stringify(error)}`);
          }
        }
      }

      // 5. 启动所有需要的策略
      for (const name of desiredNames) {
        try {
          await guardService.startGuardStrategy(name);
          Logger.info(TAG, `启动策略: ${name}`);
        } catch (error) {
          const errCode = (error as BusinessError).code;
          if (errCode === 1019000007) {
            // STRATEGY_ALREADY_EXECUTED - 已经在运行中，忽略
            Logger.info(TAG, `策略已在运行: ${name}`);
          } else {
            Logger.warn(TAG, `启动策略失败 ${name}: ${JSON.stringify(error)}`);
          }
        }
      }

      Logger.info(TAG, `策略同步完成: 需要 ${desiredNames.size} 个策略`);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '同步策略失败');
    }
  }

  /**
   * 停止并移除所有掌灯人创建的策略
   */
  async removeAllStrategies(): Promise<void> {
    if (!this.isAuthorized) {
      return;
    }

    try {
      const strategies = await guardService.queryGuardStrategies();
      for (const strategy of strategies) {
        if (strategy.name.startsWith(STRATEGY_PREFIX)) {
          try {
            await guardService.stopGuardStrategy(strategy.name).catch(() => {});
            await guardService.removeGuardStrategy(strategy.name);
            Logger.info(TAG, `已移除策略: ${strategy.name}`);
          } catch (error) {
            Logger.warn(TAG, `移除策略失败: ${strategy.name}`);
          }
        }
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '移除所有策略失败');
    }
  }

  /**
   * 停止所有策略（不删除，用于全局关闭时）
   */
  async stopAllStrategies(): Promise<void> {
    if (!this.isAuthorized) {
      return;
    }

    try {
      const strategies = await guardService.queryGuardStrategies();
      for (const strategy of strategies) {
        if (strategy.name.startsWith(STRATEGY_PREFIX)) {
          try {
            await guardService.stopGuardStrategy(strategy.name);
            Logger.info(TAG, `已停止策略: ${strategy.name}`);
          } catch (error) {
            // STRATEGY_NOT_STARTED 可忽略
          }
        }
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '停止所有策略失败');
    }
  }
}
