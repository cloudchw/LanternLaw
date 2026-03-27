/**
 * 时间段模型
 * Time Range Model
 * 用于表示灯律时间段
 */
import { Logger } from '../utils/Logger';

export interface TimeRange {
  id: string;
  label: string;           // 显示标签，如"夜间休息"
  startTime: string;       // HH:mm 格式
  endTime: string;         // HH:mm 格式（跨天时可能比startTime小）
  enabled: boolean;        // 是否启用
}

/**
 * 时间段管理器
 * Time Range Manager
 * 管理时间段列表，检查重叠等
 */
export class TimeRangeManager {
  /**
   * 检查两个时间范围是否重叠
   */
  static isOverlapping(range1: TimeRange, range2: TimeRange): boolean {
    if (!range1.enabled || !range2.enabled) {
      return false;
    }

    // 如果是同一个人（id相同），不检查重叠
    if (range1.id === range2.id) {
      return false;
    }

    const start1 = TimeRangeManager.timeToMinutes(range1.startTime);
    const end1 = TimeRangeManager.timeToMinutes(range1.endTime);
    const start2 = TimeRangeManager.timeToMinutes(range2.startTime);
    const end2 = TimeRangeManager.timeToMinutes(range2.endTime);

    Logger.info('TimeRangeManager', `检查重叠: ${range1.startTime}-${range1.endTime} vs ${range2.startTime}-${range2.endTime}`);
    Logger.info('TimeRangeManager', `时间值(分钟): ${start1}-${end1} vs ${start2}-${end2}`);

    // 处理跨天情况：将跨天范围拆分为两个不跨天的区间
    const normalizeRange = (start: number, end: number): number[][] => {
      if (end >= start) {
        // 不跨天，返回单个区间
        return [[start, end]];
      }
      // 跨天，拆分为两个区间
      return [[start, 24 * 60], [0, end]];
    };

    const intervals1 = normalizeRange(start1, end1);
    const intervals2 = normalizeRange(start2, end2);

    Logger.info('TimeRangeManager', `范围1区间: ${JSON.stringify(intervals1)}`);
    Logger.info('TimeRangeManager', `范围2区间: ${JSON.stringify(intervals2)}`);

    // 检查任意两个区间是否重叠
    for (let i = 0; i < intervals1.length; i++) {
      const s1 = intervals1[i][0];
      const e1 = intervals1[i][1];
      for (let j = 0; j < intervals2.length; j++) {
        const s2 = intervals2[j][0];
        const e2 = intervals2[j][1];
        const overlaps = !(e1 <= s2 || e2 <= s1);
        Logger.info('TimeRangeManager', `检查重叠: 区间 [${s1},${e1}] vs [${s2},${e2}]，结果: ${overlaps}`);
        if (overlaps) {
          Logger.info('TimeRangeManager', `发现重叠: 区间 [${s1},${e1}] vs [${s2},${e2}]`);
          return true;
        }
      }
    }

    Logger.info('TimeRangeManager', `无重叠`);
    return false;
  }

  /**
   * 检查时间段是否与现有列表重叠
   */
  static checkOverlap(newRange: TimeRange, existingRanges: TimeRange[]): TimeRange | null {
    for (const range of existingRanges) {
      if (range.id === newRange.id) {
        continue; // 跳过自身
      }
      if (TimeRangeManager.isOverlapping(newRange, range)) {
        return range;
      }
    }
    return null;
  }

  /**
   * 时间字符串转换为分钟数
   */
  static timeToMinutes(timeStr: string): number {
    const parts = timeStr.split(':');
    const hours = parseInt(parts[0], 10);
    const minutes = parseInt(parts[1], 10);
    return hours * 60 + minutes;
  }

  /**
   * 分钟数转换为时间字符串
   */
  static minutesToTime(minutes: number): string {
    const hours = Math.floor(minutes / 60) % 24;
    const mins = minutes % 60;
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}`;
  }

  /**
   * 创建默认时间段
   */
  static createDefault(): TimeRange {
    return {
      id: 'default',
      label: '夜间休息',
      startTime: '22:30',
      endTime: '06:30',
      enabled: true
    };
  }

  /**
   * 创建新的时间段
   */
  static create(label: string): TimeRange {
    return {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      label: label,
      startTime: '22:00',
      endTime: '06:00',
      enabled: true
    };
  }

  /**
   * 格式化时间范围显示
   */
  static formatDisplay(range: TimeRange): string {
    if (range.endTime < range.startTime) {
      return `${range.startTime} → ${range.endTime} (跨天)`;
    }
    return `${range.startTime} - ${range.endTime}`;
  }
}
