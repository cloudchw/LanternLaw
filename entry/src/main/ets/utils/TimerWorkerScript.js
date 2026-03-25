// entry/src/main/ets/utils/TimerWorkerScript.js
// HarmonyOS Worker脚本 - TimerWorker.ets的Worker脚本

let timerId = null;
let interval = 60000; // 默认1分钟

// 消息处理器
self.onmessage = function(event) {
  const data = event.data;

  try {
    switch (data.type) {
      case 'start':
        if (typeof data.interval === 'number' && data.interval > 0) {
          interval = data.interval;
          startTimer();
        } else {
          console.error('无效的间隔时间:', data.interval);
          self.postMessage({ type: 'error', message: '无效的间隔时间' });
        }
        break;

      case 'stop':
        stopTimer();
        break;

      case 'ping':
        // 心跳检测
        self.postMessage({ type: 'pong' });
        break;

      default:
        console.warn(`未知的消息类型: ${data.type}`);
        self.postMessage({ type: 'error', message: `未知的消息类型: ${data.type}` });
    }
  } catch (error) {
    console.error('处理消息时发生错误:', error);
    self.postMessage({ type: 'error', message: `处理消息失败: ${error.message || error}` });
  }
};

// 启动定时器
function startTimer() {
  if (timerId !== null) {
    stopTimer();
  }

  try {
    timerId = setInterval(() => {
      try {
        self.postMessage('tick');
      } catch (error) {
        console.error('发送tick消息失败:', error);
        // 如果发送失败，停止定时器
        stopTimer();
      }
    }, interval);

    console.log(`Worker定时器已启动，间隔: ${interval}ms`);
    self.postMessage({ type: 'started', interval: interval });
  } catch (error) {
    console.error('启动定时器失败:', error);
    self.postMessage({ type: 'error', message: `启动定时器失败: ${error.message || error}` });
  }
}

// 停止定时器
function stopTimer() {
  if (timerId !== null) {
    try {
      clearInterval(timerId);
      timerId = null;
      console.log('Worker定时器已停止');
      self.postMessage({ type: 'stopped' });
    } catch (error) {
      console.error('停止定时器失败:', error);
    }
  }
}

// Worker终止时的清理
self.onclose = function() {
  stopTimer();
  console.log('Worker正在关闭');
};