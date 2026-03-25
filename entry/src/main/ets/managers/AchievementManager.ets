// entry/src/main/ets/managers/AchievementManager.ets
/**
 * 成就管理器
 * Achievement Manager
 * 管理虚拟提灯系统和成就系统
 */
import { Achievement } from '../models/Achievement';
import { DailyRecord } from '../models/DailyRecord';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { Logger } from '../utils/Logger';
import { ErrorHandler } from '../utils/ErrorHandler';

interface LanternProgress {
  current: number;
  max: number;
}

export class AchievementManager {
  private static instance: AchievementManager;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 提灯配置
  private readonly WEEKLY_LANTERNS_COUNT: number = 7;    // 每周的提灯数量
  private readonly RESET_DAY: number = 1;                // 每周几重置（1 = 周一）

  // 成就配置
  private readonly ACHIEVEMENTS: Achievement[] = [
    // 连续天数里程碑
    new Achievement(
      'streak_week',
      '周度坚守者',
      '连续7天成功完成灯律',
      'STREAK',
      7,
      false,
      0,
      '🔥'
    ),
    new Achievement(
      'streak_month',
      '月度自律者',
      '连续30天成功完成灯律',
      'STREAK',
      30,
      false,
      0,
      '⭐'
    ),
    new Achievement(
      'streak_hundred',
      '百日坚守',
      '连续100天成功完成灯律',
      'STREAK',
      100,
      false,
      0,
      '💎'
    ),
    new Achievement(
      'streak_year',
      '年度自律大师',
      '连续365天成功完成灯律',
      'STREAK',
      365,
      false,
      0,
      '👑'
    ),
    // 总成功天数
    new Achievement(
      'total_ten',
      '新手上路',
      '累计10天成功完成灯律',
      'TOTAL',
      10,
      false,
      0,
      '🌱'
    ),
    new Achievement(
      'total_fifty',
      '熟练坚守',
      '累计50天成功完成灯律',
      'TOTAL',
      50,
      false,
      0,
      '🌿'
    ),
    new Achievement(
      'total_twohundred',
      '资深自律者',
      '累计200天成功完成灯律',
      'TOTAL',
      200,
      false,
      0,
      '🌳'
    ),
    new Achievement(
      'total_fivehundred',
      '自律大师',
      '累计500天成功完成灯律',
      'TOTAL',
      500,
      false,
      0,
      '🌍'
    )
  ];

  private constructor() {}

  public static getInstance(): AchievementManager {
    if (!AchievementManager.instance) {
      AchievementManager.instance = new AchievementManager();
    }
    return AchievementManager.instance;
  }

  /**
   * 初始化成就管理器
   */
  public async initialize(): Promise<void> {
    try {
      await ErrorHandler.safeAsync('初始化成就管理器', async () => {
        // 加载成就状态
        await this.loadAchievements();

        // 检查是否需要重置每周提灯
        await this.checkWeeklyReset();

        Logger.info('AchievementManager', '成就管理器初始化成功');
      }, true);
    } catch (error) {
      ErrorHandler.handleAsyncError('成就管理器初始化', error, true);
    }
  }

  /**
   * 获取虚拟提灯状态
   * @returns 每周提灯状态数组（true=点亮，false=熄灭）
   */
  public getLanternStatus(): boolean[] {
    const now = new Date();
    const dayOfWeek = now.getDay(); // 0 = 周日, 1 = 周一, ...

    // 计算本周起始日期（周一）
    const weekStart = new Date(now);
    const diff = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // 调整为周一为第0天
    weekStart.setDate(now.getDate() - diff);
    weekStart.setHours(0, 0, 0, 0);

    const lanterns: boolean[] = new Array(this.WEEKLY_LANTERNS_COUNT).fill(false);

    // 简化版：基于当天是否成功点亮对应的提灯
    // 实际实现需要查询数据库中本周的记录
    for (let i = 0; i < this.WEEKLY_LANTERNS_COUNT; i++) {
      const checkDate = new Date(weekStart);
      checkDate.setDate(weekStart.getDate() + i);

      // 如果是今天或过去的日期，查询成功状态
      if (checkDate <= now) {
        // TODO: 实现实际的成功记录查询
        // lanterns[i] = await this.checkSuccessForDate(checkDate);
      }
    }

    return lanterns;
  }

  /**
   * 计算提灯进度
   * @returns 当前进度和最大进度
   */
  public getLanternProgress(): LanternProgress {
    const lanterns = this.getLanternStatus();
    const current = lanterns.filter(lit => lit).length;
    const progress: LanternProgress = {
      current: current,
      max: this.WEEKLY_LANTERNS_COUNT
    };
    return progress;
  }

  /**
   * 检查并解锁成就
   * @param record 当日记录
   * @returns 新解锁的成就列表
   */
  public async checkAndUnlockAchievement(record: DailyRecord): Promise<Achievement[]> {
    const newlyUnlocked: Achievement[] = [];

    try {
      const recentRecords = await this.database.getRecentRecords(365); // 获取最多365天的记录

      // 计算统计数据
      const consecutiveDays = this.calculateConsecutiveSuccessDays(recentRecords);
      const totalSuccessDays = this.calculateTotalSuccessDays(recentRecords);

      // 检查每个成就
      for (const achievement of this.ACHIEVEMENTS) {
        if (achievement.unlocked) {
          continue; // 已经解锁
        }

        let shouldUnlock = false;

        switch (achievement.type) {
          case 'STREAK':
            shouldUnlock = consecutiveDays >= achievement.requirement;
            break;
          case 'TOTAL':
            shouldUnlock = totalSuccessDays >= achievement.requirement;
            break;
        }

        if (shouldUnlock) {
          achievement.unlocked = true;
          achievement.unlockedAt = Date.now();
          newlyUnlocked.push(achievement.clone());

          Logger.info('AchievementManager', `解锁成就: ${achievement.name}`);
        }
      }

      // 保存成就状态
      if (newlyUnlocked.length > 0) {
        await this.saveAchievements();
      }
    } catch (error) {
      ErrorHandler.handleAsyncError('检查成就解锁', error, true);
    }

    return newlyUnlocked;
  }

  /**
   * 获取所有成就
   * @returns 成就列表
   */
  public getAllAchievements(): Achievement[] {
    return this.ACHIEVEMENTS.map(a => a.clone());
  }

  /**
   * 获取已解锁的成就
   * @returns 已解锁成就列表
   */
  public getUnlockedAchievements(): Achievement[] {
    return this.ACHIEVEMENTS
      .filter(a => a.unlocked)
      .map(a => a.clone());
  }

  /**
   * 获取进行中的成就
   * @returns 进行中的成就列表
   */
  public getInProgressAchievements(): Achievement[] {
    // 这里可以实现更复杂的进度计算
    return this.ACHIEVEMENTS
      .filter(a => !a.unlocked)
      .map(a => a.clone());
  }

  /**
   * 重置每周提灯
   */
  private async resetWeeklyLanterns(): Promise<void> {
    try {
      Logger.info('AchievementManager', '重置每周提灯');
      // TODO: 实现提灯重置逻辑
    } catch (error) {
      ErrorHandler.handleAsyncError('重置每周提灯', error, true);
    }
  }

  /**
   * 检查是否需要重置每周提灯
   */
  private async checkWeeklyReset(): Promise<void> {
    try {
      const now = new Date();
      const dayOfWeek = now.getDay();

      // 如果是周一，检查是否已经重置
      if (dayOfWeek === this.RESET_DAY) {
        const yesterday = new Date(now);
        yesterday.setDate(yesterday.getDate() - 1);

        // 简化检查：如果是周一早上的第一次访问
        const hour = now.getHours();
        if (hour < 6) { // 凌晨6点前
          // TODO: 检查上次重置时间，避免同一天重复重置
          await this.resetWeeklyLanterns();
        }
      }
    } catch (error) {
      ErrorHandler.handleAsyncError('检查每周重置', error, true);
    }
  }

  /**
   * 计算连续成功天数
   * @param records 记录列表（按日期降序）
   * @returns 连续成功天数
   */
  private calculateConsecutiveSuccessDays(records: DailyRecord[]): number {
    if (records.length === 0) return 0;

    let consecutiveDays = 0;
    let currentDate = new Date();

    // 记录应该按日期降序排列
    // 从今天开始检查每个日期
    for (const record of records) {
      const recordDate = new Date(record.date);

      // 检查日期是否连续
      const daysDiff = Math.floor((currentDate.getTime() - recordDate.getTime()) / (1000 * 60 * 60 * 24));

      if (daysDiff === 1 || (daysDiff === 0 && consecutiveDays === 0)) {
        // 连续的日期（昨天或今天第一天）
        if (record.success) {
          consecutiveDays++;
          currentDate = recordDate;
        } else {
          // 这一天没有成功，中断连续性
          break;
        }
      } else if (daysDiff > 1) {
        // 日期不连续，中断连续性
        break;
      }
    }

    return consecutiveDays;
  }

  /**
   * 计算总成功天数
   * @param records 记录列表
   * @returns 总成功天数
   */
  private calculateTotalSuccessDays(records: DailyRecord[]): number {
    return records.filter(r => r.success).length;
  }

  /**
   * 加载成就状态
   */
  private async loadAchievements(): Promise<void> {
    try {
      const achievementsJson = await this.database.getConfig('achievements');
      if (achievementsJson) {
        const savedAchievements = JSON.parse(achievementsJson) as Achievement[];

        // 更新内存中的成就状态
        for (const saved of savedAchievements) {
          const achievement = this.ACHIEVEMENTS.find(a => a.id === saved.id);
          if (achievement) {
            achievement.unlocked = saved.unlocked;
            achievement.unlockedAt = saved.unlockedAt || 0;
          }
        }

        Logger.info('AchievementManager', '成就状态加载成功');
      }
    } catch (error) {
      Logger.exception('AchievementManager', error instanceof Error ? error : String(error), '加载成就状态失败');
    }
  }

  /**
   * 保存成就状态
   */
  private async saveAchievements(): Promise<void> {
    try {
      const achievementsJson = JSON.stringify(this.ACHIEVEMENTS);
      await this.database.saveConfig('achievements', achievementsJson);

      Logger.info('AchievementManager', '成就状态保存成功');
    } catch (error) {
      Logger.exception('AchievementManager', error instanceof Error ? error : String(error), '保存成就状态失败');
    }
  }
}
