// entry/src/main/ets/utils/TimerWorker.ets

/**
 * 简化的定时器包装类
 * 使用setInterval实现定时器功能（Worker API在ArkTS中不被支持）
 */
export class TimerWorker {
  private timerId: number = 0;
  private isRunning: boolean = false;
  private callback: (() => void) | null = null;

  /**
   * 启动定时器
   * @param interval 间隔时间（毫秒）
   * @param callback 回调函数
   * @returns 是否启动成功
   */
  start(interval: number, callback: () => void): boolean {
    if (this.isRunning) {
      console.warn('定时器已经在运行中');
      return false;
    }

    try {
      this.callback = callback;
      this.isRunning = true;

      // 使用setInterval实现定时器
      this.timerId = setInterval(() => {
        if (this.callback) {
          try {
            this.callback();
          } catch (error) {
            console.error(`定时器回调执行失败: ${JSON.stringify(error)}`);
          }
        }
      }, interval);

      console.log(`定时器已启动，间隔: ${interval}ms`);
      return true;
    } catch (error) {
      console.error(`启动定时器失败: ${JSON.stringify(error)}`);
      this.stop();
      return false;
    }
  }

  /**
   * 停止定时器
   */
  stop(): void {
    if (!this.isRunning) {
      return;
    }

    try {
      // 清除setInterval定时器
      if (this.timerId !== 0) {
        clearInterval(this.timerId);
        this.timerId = 0;
      }

      this.isRunning = false;
      this.callback = null;

      console.log('定时器已停止');
    } catch (error) {
      console.error(`停止定时器失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 检查定时器是否在运行
   * @returns 是否在运行
   */
  isActive(): boolean {
    return this.isRunning;
  }

  /**
   * 清理资源
   */
  destroy(): void {
    this.stop();
  }
}