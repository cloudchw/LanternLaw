// entry/src/main/ets/utils/ErrorHandler.ets

/**
 * 错误处理工具类
 * 提供统一的错误处理策略
 */
import { BusinessError } from '@ohos.base';

export class ErrorHandler {
  /**
   * 处理异步操作中的错误
   * @param operation 操作描述
   * @param error 错误对象
   * @param shouldThrow 是否重新抛出错误
   * @returns 是否成功处理
   */
  static handleAsyncError(
    operation: string,
    error: BusinessError | Error | Record<string, string | number | boolean>,
    shouldThrow: boolean = false
  ): boolean {
    const errorMessage = formatErrorMessage(operation, error);
    console.error(errorMessage);

    if (shouldThrow) {
      throw new Error(errorMessage);
    }

    return false;
  }

  /**
   * 处理同步操作中的错误
   * @param operation 操作描述
   * @param error 错误对象
   * @param shouldThrow 是否重新抛出错误
   * @returns 是否成功处理
   */
  static handleSyncError(
    operation: string,
    error: BusinessError | Error | Record<string, string | number | boolean>,
    shouldThrow: boolean = false
  ): boolean {
    const errorMessage = formatErrorMessage(operation, error);
    console.error(errorMessage);

    if (shouldThrow) {
      throw new Error(errorMessage);
    }

    return false;
  }

  /**
   * 安全执行异步操作
   * @param operation 操作描述
   * @param asyncFunc 异步函数
   * @param shouldThrow 是否重新抛出错误
   * @returns 操作结果或null
   */
  static async safeAsync<T>(
    operation: string,
    asyncFunc: () => Promise<T>,
    shouldThrow: boolean = false
  ): Promise<T | null> {
    try {
      return await asyncFunc();
    } catch (error) {
      ErrorHandler.handleAsyncError(operation, error, shouldThrow);
      return null;
    }
  }

  /**
   * 安全执行同步操作
   * @param operation 操作描述
   * @param syncFunc 同步函数
   * @param shouldThrow 是否重新抛出错误
   * @returns 操作结果或null
   */
  static safeSync<T>(
    operation: string,
    syncFunc: () => T,
    shouldThrow: boolean = false
  ): T | null {
    try {
      return syncFunc();
    } catch (error) {
      ErrorHandler.handleSyncError(operation, error, shouldThrow);
      return null;
    }
  }

  /**
   * 验证参数
   * @param paramName 参数名
   * @param paramValue 参数值
   * @param validator 验证函数
   * @throws Error 如果参数无效
   */
  static validateParam<T>(
    paramName: string,
    paramValue: T,
    validator: (value: T) => boolean,
    errorMessage?: string
  ): void {
    if (!validator(paramValue)) {
      const message = errorMessage || `参数 ${paramName} 无效`;
      throw new Error(message);
    }
  }

  /**
   * 验证字符串不为空
   * @param paramName 参数名
   * @param paramValue 参数值
   * @throws Error 如果字符串为空
   */
  static validateStringNotEmpty(paramName: string, paramValue: string): void {
    ErrorHandler.validateParam(
      paramName,
      paramValue,
      (value) => value !== null && value !== undefined && value.trim().length > 0,
      `参数 ${paramName} 不能为空`
    );
  }

  /**
   * 验证数字在范围内
   * @param paramName 参数名
   * @param paramValue 参数值
   * @param min 最小值
   * @param max 最大值
   * @throws Error 如果数字不在范围内
   */
  static validateNumberInRange(paramName: string, paramValue: number, min: number, max: number): void {
    ErrorHandler.validateParam(
      paramName,
      paramValue,
      (value) => !isNaN(value) && value >= min && value <= max,
      `参数 ${paramName} 必须在 ${min} 到 ${max} 之间`
    );
  }
}

/**
 * 格式化错误消息
 * @param operation 操作描述
 * @param error 错误对象
 * @returns 格式化的错误消息
 */
function formatErrorMessage(
  operation: string,
  error: BusinessError | Error | Record<string, string | number | boolean>
): string {
  if (error instanceof Error) {
    return `${operation}失败: ${error.message}`;
  } else if (typeof error === 'string') {
    return `${operation}失败: ${error}`;
  } else {
    return `${operation}失败: ${JSON.stringify(error)}`;
  }
}