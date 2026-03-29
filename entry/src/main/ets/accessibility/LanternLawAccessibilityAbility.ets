/**
 * 掌灯人无障碍扩展服务
 * LanternLaw Accessibility Extension Ability
 *
 * 可选增强功能：检测用户切换到其他应用，在管控时段内尝试拉回掌灯人
 * 需要用户在系统设置 > 辅助功能 > 扩展服务中手动开启
 */

import { AccessibilityExtensionAbility, AccessibilityEvent } from '@kit.AccessibilityKit';
import { Logger } from '../utils/Logger';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import dataPreferences from '@ohos.data.preferences';

const TAG = 'LanternLawAccessibility';

// 全局存储 UIAbilityContext，供无障碍服务使用
let gUIAbilityContext: common.UIAbilityContext | null = null;

export function setUIAbilityContext(ctx: common.UIAbilityContext): void {
  gUIAbilityContext = ctx;
}

export default class LanternLawAccessibilityAbility extends AccessibilityExtensionAbility {

  onConnect(): void {
    Logger.info(TAG, '无障碍服务已连接');
  }

  onDisconnect(): void {
    Logger.info(TAG, '无障碍服务已断开');
  }

  onAccessibilityEvent(accessibilityEvent: AccessibilityEvent): void {
    try {
      const eventType = accessibilityEvent.eventType;
      const bundleName = this.getEventBundleName(accessibilityEvent);

      if (!bundleName || bundleName.length === 0) {
        return;
      }

      // 忽略自身应用的事件
      if (bundleName === 'com.cloudchw.lanternlaw') {
        return;
      }

      // 忽略系统应用
      if (this.isSystemBundle(bundleName)) {
        return;
      }

      Logger.info(TAG, `检测到应用: ${bundleName}, event: ${eventType}`);

      // 检查是否需要拦截
      this.checkAndBlock(bundleName);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '处理事件失败');
    }
  }

  /**
   * 从事件中获取 bundleName
   */
  private getEventBundleName(event: AccessibilityEvent): string {
    // 使用 JSON 序列化获取 bundleName
    try {
      const jsonStr = JSON.stringify(event);
      const parsed = JSON.parse(jsonStr) as Record<string, string>;
      return parsed['bundleName'] || '';
    } catch (e) {
      return '';
    }
  }

  /**
   * 判断是否为系统应用
   */
  private isSystemBundle(bundleName: string): boolean {
    const systemPrefixes: string[] = [
      'com.huawei.',
      'com.huawei.hmos.',
      'com.ohos.',
      'ohos.',
      'com.hihonor.',
    ];

    for (const prefix of systemPrefixes) {
      if (bundleName.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }

  /**
   * 检查并拦截
   */
  private async checkAndBlock(targetBundleName: string): Promise<void> {
    try {
      // 读取配置
      const config = await this.loadConfig();
      if (!config) {
        return;
      }

      // 检查总开关
      if (config.lanternlawEnabled !== true) {
        return;
      }

      // 检查白名单
      const whitelist = config.whitelistApps;
      if (Array.isArray(whitelist)) {
        for (let i = 0; i < whitelist.length; i++) {
          const app = whitelist[i] as Record<string, string | boolean>;
          if (app['bundleName'] === targetBundleName && app['enabled'] === true) {
            return; // 白名单应用，不拦截
          }
        }
      }

      // 检查时间段
      const timeRanges = config.timeRanges;
      if (!Array.isArray(timeRanges)) {
        return;
      }

      const now = new Date();
      const currentTimeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
      const currentMinutes = this.timeToMinutes(currentTimeStr);
      let inRange = false;

      for (let i = 0; i < timeRanges.length; i++) {
        const range = timeRanges[i] as Record<string, string | boolean>;
        if (range['enabled'] !== true) {
          continue;
        }
        const startTime = range['startTime'];
        const endTime = range['endTime'];
        if (typeof startTime === 'string' && typeof endTime === 'string') {
          const start = this.timeToMinutes(startTime);
          const end = this.timeToMinutes(endTime);
          if (end >= start) {
            if (currentMinutes >= start && currentMinutes < end) {
              inRange = true;
            }
          } else {
            if (currentMinutes >= start || currentMinutes < end) {
              inRange = true;
            }
          }
        }
      }

      if (inRange) {
        Logger.info(TAG, `拦截应用: ${targetBundleName}，拉回掌灯人`);
        this.bringLanternLawToFront();
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '检查拦截失败');
    }
  }

  /**
   * 从 SharedPreferences 加载配置
   */
  private async loadConfig(): Promise<Record<string, Object> | null> {
    try {
      const ctx = this.context;
      if (!ctx) {
        return null;
      }

      const preferences = await dataPreferences.getPreferences(ctx, 'lanternlaw_config');
      const configStr = await preferences.get('config', '');
      if (typeof configStr === 'string' && configStr.length > 0) {
        return JSON.parse(configStr) as Record<string, Object>;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  /**
   * 拉回掌灯人前台
   */
  private bringLanternLawToFront(): void {
    // 优先使用全局 UIAbilityContext
    const ctx = gUIAbilityContext;
    if (ctx) {
      const want: Want = {
        bundleName: 'com.cloudchw.lanternlaw',
        abilityName: 'EntryAbility',
        parameters: {
          blocked: true,
          blockedTimestamp: Date.now()
        }
      };

      ctx.startAbility(want).then(() => {
        Logger.info(TAG, '无障碍服务拉回掌灯人成功');
      }).catch((error: Error) => {
        Logger.warn(TAG, `无障碍服务拉回失败: ${error.message}`);
      });
    } else {
      Logger.warn(TAG, 'UIAbilityContext 未设置，无法拉回');
    }
  }

  private timeToMinutes(timeStr: string): number {
    const parts = timeStr.split(':');
    const hours = parseInt(parts[0]);
    const minutes = parseInt(parts[1]);
    return hours * 60 + minutes;
  }
}
