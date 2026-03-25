// entry/src/main/ets/models/DailyRecord.ets
export class DailyRecord {
  id: string = '';                  // 唯一标识符
  version: number = 1;              // 数据版本号（用于数据迁移）
  date: string = '';                // 日期 "2026-03-23"
  lanternlawStart: number = 0;       // 灯律开始时间戳
  lanternlawEnd: number = 0;         // 灯律结束时间戳
  actualDuration: number = 0;       // 实际时长（分钟）
  escapeCount: number = 0;          // 越狱次数
  success: boolean = false;         // 是否成功（无越狱且完成）
  createdAt: number = 0;            // 创建时间戳
  updatedAt: number = 0;            // 更新时间戳

  // 计算是否在今天
  isToday(): boolean {
    const today = new Date().toISOString().split('T')[0];
    return this.date === today;
  }

  // 计算成功百分比
  successPercentage(): number {
    if (this.actualDuration === 0) return 0;
    const totalMinutes = (this.lanternlawEnd - this.lanternlawStart) / (1000 * 60);
    return Math.round((this.actualDuration / totalMinutes) * 100);
  }

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      version: this.version,
      date: this.date,
      lanternlawStart: this.lanternlawStart,
      lanternlawEnd: this.lanternlawEnd,
      actualDuration: this.actualDuration,
      escapeCount: this.escapeCount,
      success: this.success,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    });
  }

  // 从JSON解析
  static fromJSON(json: string): DailyRecord {
    const data = JSON.parse(json) as Record<string, Object | string | number | boolean | null | undefined>;
    const record = new DailyRecord();

    // 支持旧字段名向后兼容
    record.id = (data.id as string) || record.id;
    record.version = (data.version as number) || record.version;
    record.date = (data.date as string) || record.date;
    // 优先使用新字段名，向后兼容旧字段名
    record.lanternlawStart = data.lanternlawStart !== undefined ? (data.lanternlawStart as number) :
                             data.curfewStart !== undefined ? (data.curfewStart as number) : record.lanternlawStart;
    record.lanternlawEnd = data.lanternlawEnd !== undefined ? (data.lanternlawEnd as number) :
                           data.curfewEnd !== undefined ? (data.curfewEnd as number) : record.lanternlawEnd;
    record.actualDuration = (data.actualDuration as number) || record.actualDuration;
    record.escapeCount = (data.escapeCount as number) || record.escapeCount;
    record.success = data.success !== undefined ? (data.success as boolean) : record.success;
    record.createdAt = (data.createdAt as number) || record.createdAt;
    record.updatedAt = (data.updatedAt as number) || record.updatedAt;

    return record;
  }

  // 深拷贝方法
  clone(): DailyRecord {
    const record = new DailyRecord();

    record.id = this.id;
    record.version = this.version;
    record.date = this.date;
    record.lanternlawStart = this.lanternlawStart;
    record.lanternlawEnd = this.lanternlawEnd;
    record.actualDuration = this.actualDuration;
    record.escapeCount = this.escapeCount;
    record.success = this.success;
    record.createdAt = this.createdAt;
    record.updatedAt = this.updatedAt;

    return record;
  }

  // 生成唯一ID
  static generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}