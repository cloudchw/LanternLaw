// entry/src/main/ets/database/migrations/Migration_v1.ets
import { LanternLawDatabase } from '../LanternLawDatabase';
import dataPreferences from '@ohos.data.preferences';

export class Migration_v1 {
  // v1迁移：从Preferences迁移到RelationalStore
  static async migrateFromPreferences(
    context: Context,
    preferences: dataPreferences.Preferences
  ): Promise<void> {
    try {
      // 迁移配置数据
      const configKeys = ['bedtime', 'wakeupTime', 'emergencyUnlocks', 'emergencyUsed'];
      const db = LanternLawDatabase.getInstance();

      for (const key of configKeys) {
        const exists = await preferences.has(key);
        if (exists) {
          const value = await preferences.get(key, '');
          await db.saveConfig(key, JSON.stringify(value));
        }
      }

      console.log('数据迁移完成');
    } catch (error) {
      console.error(`数据迁移失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }
}