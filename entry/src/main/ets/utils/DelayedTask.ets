// entry/src/main/ets/utils/DelayedTask.ets

/**
 * 延迟任务执行器
 * 使用HarmonyOS API实现安全的延迟执行
 */
export class DelayedTask {
  private taskId: number = 0;
  private isScheduled: boolean = false;
  private callback: (() => void) | null = null;

  /**
   * 安排延迟任务
   * @param delay 延迟时间（毫秒）
   * @param callback 回调函数
   * @returns 是否安排成功
   */
  schedule(delay: number, callback: () => void): boolean {
    if (this.isScheduled) {
      console.warn('延迟任务已经在安排中');
      return false;
    }

    try {
      this.callback = callback;
      this.isScheduled = true;

      // 使用setTimeout，但在HarmonyOS环境中这是安全的
      const timeoutId = setTimeout(() => {
        this.execute();
      }, delay);
      this.taskId = Number(timeoutId);

      console.log(`延迟任务已安排，${delay}ms后执行`);
      return true;
    } catch (error) {
      console.error(`安排延迟任务失败: ${JSON.stringify(error)}`);
      this.cancel();
      return false;
    }
  }

  /**
   * 执行任务
   */
  private execute(): void {
    if (!this.isScheduled || !this.callback) {
      return;
    }

    try {
      this.callback();
    } catch (error) {
      console.error(`延迟任务执行失败: ${JSON.stringify(error)}`);
    } finally {
      this.cleanup();
    }
  }

  /**
   * 取消延迟任务
   */
  cancel(): void {
    if (!this.isScheduled) {
      return;
    }

    try {
      clearTimeout(this.taskId);
      this.cleanup();
      console.log('延迟任务已取消');
    } catch (error) {
      console.error(`取消延迟任务失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 清理资源
   */
  private cleanup(): void {
    this.taskId = 0;
    this.isScheduled = false;
    this.callback = null;
  }

  /**
   * 检查任务是否在安排中
   * @returns 是否在安排中
   */
  isActive(): boolean {
    return this.isScheduled;
  }

  /**
   * 立即执行并清理
   */
  destroy(): void {
    this.cancel();
  }
}