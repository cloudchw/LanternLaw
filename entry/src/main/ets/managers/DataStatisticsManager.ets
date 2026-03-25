// entry/src/main/ets/managers/DataStatisticsManager.ets
/**
 * 数据统计管理器
 * Data Statistics Manager
 * 处理灯律数据的统计、分析和导出
 */
import { DailyRecord } from '../models/DailyRecord';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { Logger } from '../utils/Logger';
import { ErrorHandler } from '../utils/ErrorHandler';

/**
 * 统计数据接口
 */
export interface StatisticsData {
  totalDays: number;                    // 总天数
  successfulDays: number;               // 成功天数
  failedDays: number;                   // 失败天数
  totalDuration: number;                // 总时长（分钟）
  averageDuration: number;              // 平均时长（分钟）
  totalEscapeAttempts: number;          // 总越狱次数
  successRate: number;                  // 成功率（0-100）
  consecutiveSuccessDays: number;       // 连续成功天数
  longestStreak: number;                // 最长连续成功天数
}

/**
 * 导出数据接口
 */
interface ExportData {
  exportDate: string;
  totalRecords: number;
  statistics: StatisticsData;
  records: DailyRecord[];
}

/**
 * 趋势数据接口
 */
export interface TrendData {
  date: string;                         // 日期
  duration: number;                     // 时长（分钟）
  escapeCount: number;                  // 越狱次数
  success: boolean;                     // 是否成功
}

/**
 * 周统计接口
 */
export interface WeeklyStatistics {
  weekStart: string;                    // 周开始日期
  weekEnd: string;                      // 周结束日期
  totalDays: number;                    // 本周天数
  successfulDays: number;               // 成功天数
  averageDuration: number;              // 平均时长
  totalEscapeAttempts: number;          // 越狱次数
}

export class DataStatisticsManager {
  private static instance: DataStatisticsManager;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  private constructor() {}

  public static getInstance(): DataStatisticsManager {
    if (!DataStatisticsManager.instance) {
      DataStatisticsManager.instance = new DataStatisticsManager();
    }
    return DataStatisticsManager.instance;
  }

  /**
   * 初始化统计管理器
   */
  public async initialize(): Promise<void> {
    try {
      await ErrorHandler.safeAsync('初始化统计管理器', async () => {
        Logger.info('DataStatisticsManager', '统计管理器初始化成功');
      }, true);
    } catch (error) {
      ErrorHandler.handleAsyncError('统计管理器初始化', error, true);
    }
  }

  /**
   * 计算每日成功率
   * @param record 当日记录
   * @returns 成功率（0-100）
   */
  public calculateDailySuccess(record: DailyRecord): number {
    if (!record || record.actualDuration === 0) {
      return 0;
    }
    return record.successPercentage();
  }

  /**
   * 获取总体统计数据
   * @param days 统计天数（默认所有历史数据）
   * @returns 统计数据
   */
  public async getOverallStatistics(days: number = 0): Promise<StatisticsData> {
    try {
      const records = await this.database.getRecentRecords(days || 365); // 最多365天
      return this.calculateStatistics(records);
    } catch (error) {
      ErrorHandler.handleAsyncError('获取总体统计数据', error, true);
      return this.getEmptyStatistics();
    }
  }

  /**
   * 获取连续成功天数
   * @returns 连续成功天数
   */
  public async getConsecutiveSuccessDays(): Promise<number> {
    try {
      const records = await this.database.getRecentRecords(365);
      return this.calculateConsecutiveDays(records, true);
    } catch (error) {
      ErrorHandler.handleAsyncError('获取连续成功天数', error, true);
      return 0;
    }
  }

  /**
   * 计算总体成功率
   * @returns 总体成功率（0-100）
   */
  public async calculateOverallSuccessRate(): Promise<number> {
    try {
      const records = await this.database.getRecentRecords(365);
      if (records.length === 0) return 0;

      const successfulDays = records.filter(r => r.success).length;
      return Math.round((successfulDays / records.length) * 100);
    } catch (error) {
      ErrorHandler.handleAsyncError('计算总体成功率', error, true);
      return 0;
    }
  }

  /**
   * 获取7天趋势数据
   * @returns 趋势数据数组
   */
  public async getWeeklyTrends(): Promise<TrendData[]> {
    try {
      const records = await this.database.getRecentRecords(7);
      return records.reverse().map((record: DailyRecord): TrendData => ({
        date: record.date,
        duration: record.actualDuration,
        escapeCount: record.escapeCount,
        success: record.success
      }));
    } catch (error) {
      ErrorHandler.handleAsyncError('获取7天趋势', error, true);
      return [];
    }
  }

  /**
   * 获取30天趋势数据
   * @returns 趋势数据数组
   */
  public async getMonthlyTrends(): Promise<TrendData[]> {
    try {
      const records = await this.database.getRecentRecords(30);
      return records.reverse().map((record: DailyRecord): TrendData => ({
        date: record.date,
        duration: record.actualDuration,
        escapeCount: record.escapeCount,
        success: record.success
      }));
    } catch (error) {
      ErrorHandler.handleAsyncError('获取30天趋势', error, true);
      return [];
    }
  }

  /**
   * 获取周统计数据
   * @param weekOffset 周偏移量（0=本周，-1=上周，等）
   * @returns 周统计数据
   */
  public async getWeeklyStatistics(weekOffset: number = 0): Promise<WeeklyStatistics> {
    try {
      const now = new Date();
      const dayOfWeek = now.getDay(); // 0 = 周日, 1 = 周一, ...

      // 计算目标周的起始和结束日期
      const diff = dayOfWeek === 0 ? 6 : dayOfWeek - 1; // 调整为周一为第0天
      const weekStart = new Date(now);
      weekStart.setDate(now.getDate() - diff + (weekOffset * 7));
      weekStart.setHours(0, 0, 0, 0);

      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 6);
      weekEnd.setHours(23, 59, 59, 999);

      // 获取本周所有记录
      const allRecords = await this.database.getRecentRecords(365); // 获取足够多的记录
      const weekRecords = allRecords.filter(record => {
        const recordDate = new Date(record.date);
        return recordDate >= weekStart && recordDate <= weekEnd;
      });

      // 计算统计数据
      const successfulDays = weekRecords.filter(r => r.success).length;
      const totalDuration = weekRecords.reduce((sum, r) => sum + r.actualDuration, 0);
      const totalEscapeAttempts = weekRecords.reduce((sum, r) => sum + r.escapeCount, 0);

      return {
        weekStart: weekStart.toISOString().split('T')[0],
        weekEnd: weekEnd.toISOString().split('T')[0],
        totalDays: weekRecords.length,
        successfulDays: successfulDays,
        averageDuration: weekRecords.length > 0 ? Math.round(totalDuration / weekRecords.length) : 0,
        totalEscapeAttempts: totalEscapeAttempts
      };
    } catch (error) {
      ErrorHandler.handleAsyncError('获取周统计数据', error, true);
      return this.getEmptyWeeklyStatistics();
    }
  }

  /**
   * 获取月统计数据
   * @param year 年份（默认当年）
   * @param month 月份（1-12，默认当月）
   * @returns 统计数据
   */
  public async getMonthlyStatistics(year: number = 0, month: number = 0): Promise<StatisticsData> {
    try {
      const now = new Date();
      const targetYear = year || now.getFullYear();
      const targetMonth = month || (now.getMonth() + 1);

      // 获取该月所有记录
      const allRecords = await this.database.getRecentRecords(365); // 获取足够多的记录
      const monthRecords = allRecords.filter(record => {
        const recordDate = new Date(record.date);
        return recordDate.getFullYear() === targetYear &&
               (recordDate.getMonth() + 1) === targetMonth;
      });

      return this.calculateStatistics(monthRecords);
    } catch (error) {
      ErrorHandler.handleAsyncError('获取月统计数据', error, true);
      return this.getEmptyStatistics();
    }
  }

  /**
   * 导出统计数据
   * @param format 导出格式（'json' | 'csv'）
   * @returns 导出的数据字符串
   */
  public async exportStatisticsData(format: string = 'json'): Promise<string> {
    try {
      const records = await this.database.getRecentRecords(365);

      if (format === 'csv') {
        return this.exportAsCSV(records);
      } else {
        return this.exportAsJSON(records);
      }
    } catch (error) {
      ErrorHandler.handleAsyncError('导出统计数据', error, true);
      return '';
    }
  }

  /**
   * 导出为JSON格式
   */
  private exportAsJSON(records: DailyRecord[]): string {
    const exportData: ExportData = {
      exportDate: new Date().toISOString(),
      totalRecords: records.length,
      statistics: this.calculateStatistics(records),
      records: records.reverse()
    };
    return JSON.stringify(exportData, null, 2);
  }

  /**
   * 导出为CSV格式
   */
  private exportAsCSV(records: DailyRecord[]): string {
    const headers = ['日期', '时长(分钟)', '越狱次数', '是否成功'];
    const rows = records.reverse().map(record => [
      record.date,
      record.actualDuration,
      record.escapeCount,
      record.success ? '成功' : '失败'
    ]);

    // 添加标题行
    const csvContent = [
      headers.join(','),
      ...rows.map(row => row.join(','))
    ].join('\n');

    return csvContent;
  }

  /**
   * 计算统计数据
   */
  private calculateStatistics(records: DailyRecord[]): StatisticsData {
    if (records.length === 0) {
      return this.getEmptyStatistics();
    }

    const successfulDays = records.filter(r => r.success).length;
    const failedDays = records.length - successfulDays;
    const totalDuration = records.reduce((sum, r) => sum + r.actualDuration, 0);
    const totalEscapeAttempts = records.reduce((sum, r) => sum + r.escapeCount, 0);
    const consecutiveDays = this.calculateConsecutiveDays(records, true);

    return {
      totalDays: records.length,
      successfulDays: successfulDays,
      failedDays: failedDays,
      totalDuration: totalDuration,
      averageDuration: Math.round(totalDuration / records.length),
      totalEscapeAttempts: totalEscapeAttempts,
      successRate: Math.round((successfulDays / records.length) * 100),
      consecutiveSuccessDays: consecutiveDays,
      longestStreak: this.calculateLongestStreak(records)
    };
  }

  /**
   * 计算连续天数
   */
  private calculateConsecutiveDays(records: DailyRecord[], fromStart: boolean = false): number {
    if (records.length === 0) return 0;

    let consecutiveDays = 0;
    let currentDate = fromStart ? new Date() : new Date(records[records.length - 1].date);
    const startDate = new Date(currentDate);
    startDate.setHours(0, 0, 0, 0);

    for (const record of records) {
      const recordDate = new Date(record.date);
      recordDate.setHours(0, 0, 0, 0);

      const daysDiff = Math.abs(Math.floor((currentDate.getTime() - recordDate.getTime()) / (1000 * 60 * 60 * 24)));

      if (daysDiff === 1 || (daysDiff === 0 && consecutiveDays === 0)) {
        if (record.success) {
          consecutiveDays++;
          currentDate = recordDate;
        } else {
          break;
        }
      } else if (daysDiff > 1) {
        break;
      }
    }

    return consecutiveDays;
  }

  /**
   * 计算最长连续成功天数
   */
  private calculateLongestStreak(records: DailyRecord[]): number {
    if (records.length === 0) return 0;

    let longestStreak = 0;
    let currentStreak = 0;

    for (const record of records) {
      if (record.success) {
        currentStreak++;
        longestStreak = Math.max(longestStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }

    return longestStreak;
  }

  /**
   * 获取空的统计数据
   */
  private getEmptyStatistics(): StatisticsData {
    return {
      totalDays: 0,
      successfulDays: 0,
      failedDays: 0,
      totalDuration: 0,
      averageDuration: 0,
      totalEscapeAttempts: 0,
      successRate: 0,
      consecutiveSuccessDays: 0,
      longestStreak: 0
    };
  }

  /**
   * 获取空的周统计数据
   */
  private getEmptyWeeklyStatistics(): WeeklyStatistics {
    const now = new Date();
    return {
      weekStart: now.toISOString().split('T')[0],
      weekEnd: now.toISOString().split('T')[0],
      totalDays: 0,
      successfulDays: 0,
      averageDuration: 0,
      totalEscapeAttempts: 0
    };
  }
}
