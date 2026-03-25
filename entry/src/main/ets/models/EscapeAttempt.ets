// entry/src/main/ets/models/EscapeAttempt.ets
export class EscapeAttempt {
  timestamp: number = 0;            // 时间戳
  type: string = '';                // 类型: 'APP_SWITCH' | 'UNINSTALL_ATTEMPT'
  appName: string = '';             // 尝试切换的应用名称
  count: number = 0;                // 本次计数
  totalEscapeCount: number = 0;     // 累计次数

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      timestamp: this.timestamp,
      type: this.type,
      appName: this.appName,
      count: this.count,
      totalEscapeCount: this.totalEscapeCount
    });
  }

  // 从JSON解析
  static fromJSON(json: string): EscapeAttempt {
    const data = JSON.parse(json) as Record<string, Object | string | number | boolean | null | undefined>;
    const attempt = new EscapeAttempt();

    const timestampValue = data.timestamp;
    if (timestampValue !== undefined && typeof timestampValue === 'number') {
      attempt.timestamp = timestampValue as number;
    }
    const typeValue = data.type;
    if (typeValue !== undefined && typeof typeValue === 'string') {
      attempt.type = typeValue as string;
    }
    const appNameValue = data.appName;
    if (appNameValue !== undefined && typeof appNameValue === 'string') {
      attempt.appName = appNameValue as string;
    }
    const countValue = data.count;
    if (countValue !== undefined && typeof countValue === 'number') {
      attempt.count = countValue as number;
    }
    const totalEscapeCountValue = data.totalEscapeCount;
    if (totalEscapeCountValue !== undefined && typeof totalEscapeCountValue === 'number') {
      attempt.totalEscapeCount = totalEscapeCountValue as number;
    }

    return attempt;
  }
}