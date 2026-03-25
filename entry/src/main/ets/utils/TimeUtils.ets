// entry/src/main/ets/utils/TimeUtils.ets

/**
 * 时间解析结果接口
 */
interface TimeParts {
  hour: number;
  minute: number;
}

/**
 * 时间工具类
 * 提供时间相关的工具方法
 */
export class TimeUtils {
  /**
   * 解析时间字符串 "HH:mm" 为小时和分钟
   * @param timeString 时间字符串，格式为 "HH:mm"
   * @returns 包含小时和分钟的对象
   * @throws Error 如果时间格式无效
   */
  static parseTimeString(timeString: string): TimeParts {
    const parts = timeString.split(':');
    if (parts.length !== 2) {
      throw new Error(`无效的时间格式: ${timeString}`);
    }

    const hour = parseInt(parts[0], 10);
    const minute = parseInt(parts[1], 10);

    if (isNaN(hour) || isNaN(minute) || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw new Error(`无效的时间值: ${timeString}`);
    }

    const result: TimeParts = { hour: hour, minute: minute };
    return result;
  }

  /**
   * 格式化时间为 "HH:mm" 字符串
   * @param hour 小时 (0-23)
   * @param minute 分钟 (0-59)
   * @returns 格式化的时间字符串
   */
  static formatTime(hour: number, minute: number): string {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw new Error(`无效的时间值: hour=${hour}, minute=${minute}`);
    }

    return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
  }

  /**
   * 获取当前时间的 "HH:mm" 字符串
   * @returns 当前时间字符串
   */
  static getCurrentTimeString(): string {
    const now = new Date();
    return TimeUtils.formatTime(now.getHours(), now.getMinutes());
  }

  /**
   * 计算两个时间之间的分钟数
   * @param startTime 开始时间字符串 "HH:mm"
   * @param endTime 结束时间字符串 "HH:mm"
   * @returns 分钟数（可能为负数，如果结束时间在开始时间之前）
   */
  static calculateMinutesBetween(startTime: string, endTime: string): number {
    const start = TimeUtils.parseTimeString(startTime);
    const end = TimeUtils.parseTimeString(endTime);

    const startMinutes = start.hour * 60 + start.minute;
    const endMinutes = end.hour * 60 + end.minute;

    return endMinutes - startMinutes;
  }

  /**
   * 检查当前时间是否在指定时间范围内
   * @param startTime 开始时间字符串 "HH:mm"
   * @param endTime 结束时间字符串 "HH:mm"
   * @returns 是否在时间范围内
   */
  static isTimeInRange(startTime: string, endTime: string): boolean {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();

    const start = TimeUtils.parseTimeString(startTime);
    const end = TimeUtils.parseTimeString(endTime);

    const startMinutes = start.hour * 60 + start.minute;
    const endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      // 同一天内的时间范围
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // 跨夜的时间范围
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }
}