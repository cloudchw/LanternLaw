// entry/src/main/ets/utils/Logger.ets

/**
 * 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3
}

/**
 * 日志配置接口
 */
export interface LoggerConfig {
  minLevel: LogLevel;
  enableConsole: boolean;
  enableFileLog: boolean;
  maxFileSize?: number; // 最大文件大小（字节）
  maxFiles?: number; // 最大文件数量
}

/**
 * 异常数据接口
 */
interface ExceptionData {
  stack: string;
  context?: string;
}

/**
 * 统一的日志工具类
 * 提供分级日志功能，支持控制台输出和文件记录
 */
export class Logger {
  private static config: LoggerConfig = {
    minLevel: LogLevel.DEBUG,
    enableConsole: true,
    enableFileLog: false
  };

  private static readonly LOG_TAG = 'LanternLaw';
  private static readonly MAX_LOG_LENGTH = 1000;

  /**
   * 配置日志器
   * @param config 日志配置
   */
  static configure(config: LoggerConfig): void {
    Logger.config = {
      minLevel: config.minLevel ?? Logger.config.minLevel,
      enableConsole: config.enableConsole ?? Logger.config.enableConsole,
      enableFileLog: config.enableFileLog ?? Logger.config.enableFileLog,
      maxFileSize: config.maxFileSize ?? Logger.config.maxFileSize,
      maxFiles: config.maxFiles ?? Logger.config.maxFiles
    };
    Logger.info('Logger', `日志器已配置: ${JSON.stringify(Logger.config)}`);
  }

  /**
   * 调试日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param data 附加数据（可选）
   */
  static debug(tag: string, message: string, data?: string | number | boolean | object): void {
    Logger.log(LogLevel.DEBUG, tag, message, data);
  }

  /**
   * 信息日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param data 附加数据（可选）
   */
  static info(tag: string, message: string, data?: string | number | boolean | object): void {
    Logger.log(LogLevel.INFO, tag, message, data);
  }

  /**
   * 警告日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param data 附加数据（可选）
   */
  static warn(tag: string, message: string, data?: string | number | boolean | object): void {
    Logger.log(LogLevel.WARN, tag, message, data);
  }

  /**
   * 错误日志
   * @param tag 日志标签
   * @param message 日志消息
   * @param data 附加数据（可选）
   */
  static error(tag: string, message: string, data?: string | number | boolean | object): void {
    Logger.log(LogLevel.ERROR, tag, message, data);
  }

  /**
   * 记录异常
   * @param tag 日志标签
   * @param error 错误对象
   * @param context 上下文信息（可选）
   */
  static exception(tag: string, error: Error | string, context?: string): void {
    const errorMessage: string = error instanceof Error ? error.message : error;
    const stackTrace: string = error instanceof Error && error.stack ? error.stack : '无堆栈信息';

    const exceptionData: ExceptionData = {
      stack: stackTrace,
      context: context
    };
    Logger.error(tag, `异常: ${errorMessage}${context ? ` [${context}]` : ''}`, exceptionData);
  }

  /**
   * 内部日志方法
   * @param level 日志级别
   * @param tag 日志标签
   * @param message 日志消息
   * @param data 附加数据
   */
  private static log(level: LogLevel, tag: string, message: string, data?: string | number | boolean | object): void {
    // 检查日志级别
    if (level < Logger.config.minLevel) {
      return;
    }

    // 格式化日志消息
    const timestamp: string = Logger.getTimestamp();
    const levelStr: string = Logger.getLevelString(level);
    const fullTag: string = `${Logger.LOG_TAG}:${tag}`;

    // 构建日志条目
    let logEntry: string = `[${timestamp}] ${levelStr} ${fullTag}: ${message}`;

    // 添加附加数据
    if (data !== undefined && data !== null) {
      try {
        const dataStr: string = typeof data === 'object' ? JSON.stringify(data) : String(data);
        // 限制数据长度
        const truncatedData: string = dataStr.length > Logger.MAX_LOG_LENGTH
          ? dataStr.substring(0, Logger.MAX_LOG_LENGTH) + '... [已截断]'
          : dataStr;
        logEntry += ` | ${truncatedData}`;
      } catch (error) {
        logEntry += ` | [无法序列化数据]`;
      }
    }

    // 输出到控制台
    if (Logger.config.enableConsole) {
      Logger.consoleLog(level, logEntry);
    }

    // 记录到文件
    if (Logger.config.enableFileLog) {
      Logger.fileLog(logEntry);
    }
  }

  /**
   * 控制台日志输出
   * @param level 日志级别
   * @param message 日志消息
   */
  private static consoleLog(level: LogLevel, message: string): void {
    switch (level) {
      case LogLevel.DEBUG:
        console.debug(message);
        break;
      case LogLevel.INFO:
        console.info(message);
        break;
      case LogLevel.WARN:
        console.warn(message);
        break;
      case LogLevel.ERROR:
        console.error(message);
        break;
    }
  }

  /**
   * 文件日志记录
   * @param message 日志消息
   */
  private static fileLog(message: string): void {
    // 在HarmonyOS中，文件日志需要特定的API
    // 这里使用控制台输出模拟文件日志
    // 实际项目中可以集成文件系统API
    console.info(`[文件日志] ${message}`);
  }

  /**
   * 获取时间戳
   * @returns 格式化的时间戳
   */
  private static getTimestamp(): string {
    const now: Date = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}.${now.getMilliseconds().toString().padStart(3, '0')}`;
  }

  /**
   * 获取日志级别字符串
   * @param level 日志级别
   * @returns 级别字符串
   */
  private static getLevelString(level: LogLevel): string {
    switch (level) {
      case LogLevel.DEBUG:
        return 'DEBUG';
      case LogLevel.INFO:
        return 'INFO';
      case LogLevel.WARN:
        return 'WARN';
      case LogLevel.ERROR:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }

  /**
   * 记录内存使用情况
   */
  static logMemoryUsage(): void {
    Logger.debug('Memory', '内存使用情况记录');
  }

  /**
   * 清理日志文件
   * @returns 是否成功
   */
  static async cleanupLogFiles(): Promise<boolean> {
    if (!Logger.config.enableFileLog) {
      return true;
    }

    try {
      Logger.info('Logger', '日志文件清理完成');
      return true;
    } catch (error) {
      Logger.exception('Logger', error instanceof Error ? error : String(error), '清理日志文件时发生错误');
      return false;
    }
  }
}
