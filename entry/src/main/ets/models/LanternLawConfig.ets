// entry/src/main/ets/models/LanternLawConfig.ets
/**
 * 灯律配置模型
 * LanternLaw Configuration Model
 */
import { TimeRange } from './TimeRange';
import { WhitelistApp } from './WhitelistApp';

export class LanternLawConfig {
  emergencyUnlocks: number = 3;              // 每月紧急解锁次数
  emergencyUsed: number = 0;                 // 已用紧急解锁次数
  lanternlawEnabled: boolean = true;         // 灯律是否启用
  timeRanges: TimeRange[] = [];              // 时间段列表
  whitelistApps: WhitelistApp[] = [];        // 白名单应用列表

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      emergencyUnlocks: this.emergencyUnlocks,
      emergencyUsed: this.emergencyUsed,
      lanternlawEnabled: this.lanternlawEnabled,
      timeRanges: this.timeRanges,
      whitelistApps: this.whitelistApps
    });
  }

  // 从JSON解析
  static fromJSON(json: string): LanternLawConfig {
    const data = JSON.parse(json) as Record<string, Object | string | number | boolean | null | undefined>;
    const config = new LanternLawConfig();

    const emergencyUnlocksValue = data.emergencyUnlocks;
    if (emergencyUnlocksValue !== undefined && typeof emergencyUnlocksValue === 'number') {
      config.emergencyUnlocks = emergencyUnlocksValue as number;
    }
    const emergencyUsedValue = data.emergencyUsed;
    if (emergencyUsedValue !== undefined && typeof emergencyUsedValue === 'number') {
      config.emergencyUsed = emergencyUsedValue as number;
    }
    // 优先使用新字段名，向后兼容旧字段名
    const lanternlawEnabledValue = data.lanternlawEnabled;
    const curfewEnabledValue = data.curfewEnabled;
    if (lanternlawEnabledValue !== undefined && typeof lanternlawEnabledValue === 'boolean') {
      config.lanternlawEnabled = lanternlawEnabledValue as boolean;
    } else if (curfewEnabledValue !== undefined && typeof curfewEnabledValue === 'boolean') {
      config.lanternlawEnabled = curfewEnabledValue as boolean;
    }

    // 加载时间段列表
    const timeRangesValue = data.timeRanges;
    if (timeRangesValue !== undefined && Array.isArray(timeRangesValue)) {
      config.timeRanges = timeRangesValue as TimeRange[];
    }

    // 加载白名单应用列表
    const whitelistAppsValue = data.whitelistApps;
    if (whitelistAppsValue !== undefined && Array.isArray(whitelistAppsValue)) {
      config.whitelistApps = whitelistAppsValue as WhitelistApp[];
    }

    return config;
  }

  // 深拷贝方法
  clone(): LanternLawConfig {
    const config = new LanternLawConfig();

    config.emergencyUnlocks = this.emergencyUnlocks;
    config.emergencyUsed = this.emergencyUsed;
    config.lanternlawEnabled = this.lanternlawEnabled;
    config.timeRanges = JSON.parse(JSON.stringify(this.timeRanges));
    config.whitelistApps = JSON.parse(JSON.stringify(this.whitelistApps));

    return config;
  }
}
