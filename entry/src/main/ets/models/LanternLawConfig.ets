// entry/src/main/ets/models/LanternLawConfig.ets
/**
 * 灯律配置模型
 * LanternLaw Configuration Model
 */
export class LanternLawConfig {
  bedtime: string = '22:30';                  // 就寝时间 HH:mm
  wakeupTime: string = '06:30';               // 解锁时间 HH:mm
  emergencyUnlocks: number = 3;              // 每月紧急解锁次数
  emergencyUsed: number = 0;                 // 已用紧急解锁次数
  lanternlawEnabled: boolean = true;         // 灯律是否启用
  vibrationEnabled: boolean = true;          // 振动反馈是否启用
  soundEnabled: boolean = false;             // 声音反馈是否启用

  // 验证配置有效性
  isValid(): boolean {
    const bedtimeParts = this.bedtime.split(':');
    const wakeupParts = this.wakeupTime.split(':');

    if (bedtimeParts.length !== 2 || wakeupParts.length !== 2) {
      return false;
    }

    const bedtimeHour = parseInt(bedtimeParts[0]);
    const bedtimeMinute = parseInt(bedtimeParts[1]);
    const wakeupHour = parseInt(wakeupParts[0]);
    const wakeupMinute = parseInt(wakeupParts[1]);

    return bedtimeHour >= 0 && bedtimeHour < 24 &&
           bedtimeMinute >= 0 && bedtimeMinute < 60 &&
           wakeupHour >= 0 && wakeupHour < 24 &&
           wakeupMinute >= 0 && wakeupMinute < 60;
  }

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      bedtime: this.bedtime,
      wakeupTime: this.wakeupTime,
      emergencyUnlocks: this.emergencyUnlocks,
      emergencyUsed: this.emergencyUsed,
      lanternlawEnabled: this.lanternlawEnabled,
      vibrationEnabled: this.vibrationEnabled,
      soundEnabled: this.soundEnabled
    });
  }

  // 从JSON解析
  static fromJSON(json: string): LanternLawConfig {
    const data = JSON.parse(json) as Record<string, Object | string | number | boolean | null | undefined>;
    const config = new LanternLawConfig();

    // 支持旧字段名向后兼容 - 直接赋值并类型断言
    const bedtimeValue = data.bedtime;
    if (bedtimeValue !== undefined && typeof bedtimeValue === 'string') {
      config.bedtime = bedtimeValue as string;
    }
    const wakeupTimeValue = data.wakeupTime;
    if (wakeupTimeValue !== undefined && typeof wakeupTimeValue === 'string') {
      config.wakeupTime = wakeupTimeValue as string;
    }
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
    const vibrationEnabledValue = data.vibrationEnabled;
    if (vibrationEnabledValue !== undefined && typeof vibrationEnabledValue === 'boolean') {
      config.vibrationEnabled = vibrationEnabledValue as boolean;
    }
    const soundEnabledValue = data.soundEnabled;
    if (soundEnabledValue !== undefined && typeof soundEnabledValue === 'boolean') {
      config.soundEnabled = soundEnabledValue as boolean;
    }

    return config;
  }

  // 深拷贝方法
  clone(): LanternLawConfig {
    const config = new LanternLawConfig();

    config.bedtime = this.bedtime;
    config.wakeupTime = this.wakeupTime;
    config.emergencyUnlocks = this.emergencyUnlocks;
    config.emergencyUsed = this.emergencyUsed;
    config.lanternlawEnabled = this.lanternlawEnabled;
    config.vibrationEnabled = this.vibrationEnabled;
    config.soundEnabled = this.soundEnabled;

    return config;
  }
}
