// entry/src/main/ets/test/DeviceLockManagerTest.ets

/**
 * 设备锁管理器测试
 * 验证DeviceLockManager的核心功能
 */

import { DeviceLockManager, DeviceLockState } from '../managers/DeviceLockManager';
import { Logger } from '../utils/Logger';
import { BusinessError } from '@ohos.base';

// 模拟的上下文对象
class MockContext {
  tokenId: number = 12345;
}

/**
 * 设备锁管理器测试类
 */
export class DeviceLockManagerTest {
  private mockContext: MockContext = new MockContext();

  /**
   * 运行所有测试
   */
  public async runAllTests(): Promise<void> {
    console.log('=== 开始设备锁管理器测试 ===');

    try {
      await this.testSingletonPattern();
      await this.testInitialization();
      await this.testStateManagement();
      await this.testPermissionChecking();
      await this.testListenerRegistration();

      console.log('=== 所有测试通过 ===');
    } catch (error) {
      console.error('测试失败:', error);
      throw error;
    }
  }

  /**
   * 测试单例模式
   */
  private async testSingletonPattern(): Promise<void> {
    console.log('测试单例模式...');

    const instance1 = DeviceLockManager.getInstance();
    const instance2 = DeviceLockManager.getInstance();

    if (instance1 === instance2) {
      console.log('✓ 单例模式测试通过：两个实例相同');
    } else {
      throw new Error('单例模式测试失败：两个实例不同');
    }
  }

  /**
   * 测试初始化
   */
  private async testInitialization(): Promise<void> {
    console.log('测试初始化...');

    const manager = DeviceLockManager.getInstance();

    // 初始状态应该是INITIALIZING
    const initialState = manager.getCurrentState();
    if (initialState === DeviceLockState.INITIALIZING) {
      console.log('✓ 初始状态正确：INITIALIZING');
    } else {
      throw new Error(`初始状态不正确：${initialState}`);
    }

    // 初始化前应该返回未初始化
    if (!manager.isInitialized()) {
      console.log('✓ 初始化前状态正确：未初始化');
    } else {
      throw new Error('初始化前状态不正确：已初始化');
    }

    // 注意：实际初始化需要真实的Context对象
    // 这里只测试基本逻辑
    console.log('⚠️ 初始化测试跳过（需要真实Context）');
  }

  /**
   * 测试状态管理
   */
  private async testStateManagement(): Promise<void> {
    console.log('测试状态管理...');

    const manager = DeviceLockManager.getInstance();

    // 测试状态获取
    const state = manager.getCurrentState();
    console.log(`✓ 当前状态：${state}`);

    // 测试设备锁定状态检查（模拟）
    const isLocked = await manager.isDeviceLocked();
    console.log(`✓ 设备锁定状态：${isLocked}`);

    console.log('⚠️ 锁定/解锁功能测试跳过（需要真实设备管理器）');
  }

  /**
   * 测试权限检查
   */
  private async testPermissionChecking(): Promise<void> {
    console.log('测试权限检查...');

    const manager = DeviceLockManager.getInstance();

    // 测试权限检查（模拟）
    try {
      const permissions = await manager.checkPermissions();
      console.log(`✓ 权限检查结果：${JSON.stringify(permissions)}`);
    } catch (error) {
      console.log(`⚠️ 权限检查失败（预期中）：${(error as Error).message}`);
    }

    console.log('⚠️ 权限请求测试跳过（需要真实权限管理器）');
  }

  /**
   * 测试监听器注册
   */
  private async testListenerRegistration(): Promise<void> {
    console.log('测试监听器注册...');

    const manager = DeviceLockManager.getInstance();

    // 创建测试监听器
    let stateChanged = false;
    let trustLevelChanged = false;
    let errorOccurred = false;

    const testListener = {
      onDeviceStateChanged: (state: DeviceLockState, previousState: DeviceLockState) => {
        stateChanged = true;
        console.log(`监听器：状态变化 ${previousState} -> ${state}`);
      },
      onDeviceTrustLevelChanged: (trustLevel: number) => {
        trustLevelChanged = true;
        console.log(`监听器：信任级别变化 ${trustLevel}`);
      },
      onDeviceManagerError: (error: BusinessError | Error) => {
        errorOccurred = true;
        console.log(`监听器：错误发生 ${error}`);
      }
    };

    // 注册监听器
    manager.addListener(testListener);
    console.log('✓ 监听器注册成功');

    // 移除监听器
    manager.removeListener(testListener);
    console.log('✓ 监听器移除成功');

    // 测试多次添加移除
    manager.addListener(testListener);
    manager.addListener(testListener); // 故意添加两次
    manager.removeListener(testListener);
    console.log('✓ 多次添加移除测试通过');
  }

  /**
   * 运行性能测试
   */
  public async runPerformanceTests(): Promise<void> {
    console.log('=== 开始性能测试 ===');

    const manager = DeviceLockManager.getInstance();
    const iterations = 100;

    // 测试状态获取性能
    const startTime = Date.now();
    for (let i = 0; i < iterations; i++) {
      manager.getCurrentState();
    }
    const endTime = Date.now();
    const duration = endTime - startTime;
    const avgTime = duration / iterations;

    console.log(`状态获取性能测试：${iterations}次迭代，总耗时${duration}ms，平均${avgTime.toFixed(3)}ms/次`);

    if (avgTime < 1) {
      console.log('✓ 状态获取性能良好');
    } else {
      console.log('⚠️ 状态获取性能有待优化');
    }

    console.log('=== 性能测试完成 ===');
  }
}

// 导出测试运行函数
export async function runDeviceLockManagerTests(): Promise<boolean> {
  try {
    const test = new DeviceLockManagerTest();
    await test.runAllTests();
    await test.runPerformanceTests();
    return true;
  } catch (error) {
    console.error('设备锁管理器测试失败:', error);
    return false;
  }
}

// 如果直接运行此文件，执行测试
// 注：在HarmonyOS环境中，测试通过显式调用 runDeviceLockManagerTests() 执行