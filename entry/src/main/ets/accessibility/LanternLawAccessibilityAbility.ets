// entry/src/main/ets/accessibility/LanternLawAccessibilityAbility.ets
/**
 * 越狱检测无障碍服务
 * LanternLaw Accessibility Ability
 * 检测用户尝试绕过灯律的行为，包括应用切换和卸载尝试检测
 * 并在灯律时段内拦截非白名单应用
 */

import { AccessibilityExtensionAbility, AccessibilityEvent } from '@kit.AccessibilityKit';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { AppBlockingService } from '../services/AppBlockingService';
import { Logger } from '../utils/Logger';
import bundleManager from '@ohos.bundle.bundleManager';

// 频率限制窗口：5分钟
const FREQUENCY_LIMIT_WINDOW_MS: number = 5 * 60 * 1000;

// 系统应用包名前缀（过滤误判）
const SYSTEM_APP_PREFIXES: string[] = [
  'com.huawei.',
  'com.ohos.',
  'android.',
  'com.android.',
  'system.'
];

// 本应用包名（从上下文获取）
let LANTERNLAW_APP_PACKAGE: string = '';

/**
 * 应用切换记录接口
 */
interface AppSwitchRecord {
  packageName: string;
  timestamp: number;
}

/**
 * 无障碍服务扩展类
 */
export default class LanternLawAccessibilityAbility extends AccessibilityExtensionAbility {
  // 应用切换记录缓存（用于频率限制）
  private appSwitchRecords: Map<string, AppSwitchRecord> = new Map();

  /**
   * 无障碍服务初始化
   */
  onInit(): void {
    Logger.info('LanternLawAccessibilityAbility', '无障碍服务初始化');

    try {
      // 获取本应用包名
      this.getBundleName();

      Logger.info('LanternLawAccessibilityAbility', '无障碍服务初始化完成');
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '初始化无障碍服务时发生错误');
    }
  }

  /**
   * 获取本应用包名
   */
  private async getBundleName(): Promise<void> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      LANTERNLAW_APP_PACKAGE = bundleInfo.name;
      Logger.info('LanternLawAccessibilityAbility', `应用包名: ${LANTERNLAW_APP_PACKAGE}`);
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '获取包名失败');
      LANTERNLAW_APP_PACKAGE = 'com.cloudchw.lanternlaw';
    }
  }

  /**
   * 无障碍事件处理
   * @param event 无障碍事件
   */
  onAccessibilityEvent(event: AccessibilityEvent): void {
    if (!event) {
      return;
    }

    try {
      this.handleAccessibilityEvent(event);
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '处理无障碍事件时发生错误');
    }
  }

  /**
   * 无障碍服务连接建立
   */
  onConnect(): void {
    Logger.info('LanternLawAccessibilityAbility', '无障碍服务连接建立');
  }

  /**
   * 无障碍服务连接断开
   */
  onDisconnect(): void {
    Logger.info('LanternLawAccessibilityAbility', '无障碍服务连接断开');
  }

  /**
   * 无障碍服务销毁
   */
  onDestroy(): void {
    Logger.info('LanternLawAccessibilityAbility', '无障碍服务销毁');
    // 清理缓存
    this.appSwitchRecords.clear();
  }

  /**
   * 处理无障碍事件
   * @param event 无障碍事件
   */
  private handleAccessibilityEvent(event: AccessibilityEvent): void {
    // 将事件转换为字符串形式进行处理
    const eventStr = JSON.stringify(event);
    const eventObj = JSON.parse(eventStr) as Record<string, Object>;

    // 获取事件类型
    const eventType = eventObj['eventType'] as number;

    // 根据事件类型处理
    // 0x00000010 = TYPE_WINDOW_STATE_CHANGED (16)
    // 0x00000020 = TYPE_NOTIFICATION_STATE_CHANGED (32)
    // 0x00000800 = TYPE_WINDOW_CONTENT_CHANGED (2048)
    if (eventType === 16) {
      this.handleWindowStateChanged(eventObj);
    } else if (eventType === 32) {
      this.handleNotificationStateChanged(eventObj);
    } else if (eventType === 2048) {
      this.handleWindowContentChanged(eventObj);
    }
  }

  /**
   * 处理窗口状态变化事件（应用切换检测）
   * @param eventObj 事件对象
   */
  private handleWindowStateChanged(eventObj: Record<string, Object>): void {
    try {
      const packageName = eventObj['packageName'] as string;
      const bundleName = eventObj['bundleName'] as string;

      // 使用 packageName 或 bundleName
      const targetPackage = packageName || bundleName;

      if (!targetPackage) {
        return;
      }

      Logger.debug('LanternLawAccessibilityAbility', `窗口状态变化: ${targetPackage}`);

      // 检测是否切换到其他应用
      if (targetPackage !== LANTERNLAW_APP_PACKAGE) {
        // 检查是否是系统应用
        if (this.isSystemApp(targetPackage)) {
          Logger.debug('LanternLawAccessibilityAbility', `系统应用切换，忽略: ${targetPackage}`);
          return;
        }

        // 调用拦截服务处理应用切换
        const blockingService = AppBlockingService.getInstance();
        blockingService.handleAppSwitch(targetPackage);

        // 检查频率限制
        if (this.shouldRecordAppSwitch(targetPackage)) {
          // 记录应用切换尝试（用于统计）
          this.recordAppSwitchAttempt(targetPackage);
        }
      }
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '处理窗口状态变化时发生错误');
    }
  }

  /**
   * 处理通知状态变化事件（卸载/禁用检测）
   * @param eventObj 事件对象
   */
  private handleNotificationStateChanged(eventObj: Record<string, Object>): void {
    try {
      // 检查是否包含卸载相关文本
      const textContent = this.extractTextContent(eventObj);
      if (this.isUninstallRelatedText(textContent)) {
        Logger.info('LanternLawAccessibilityAbility', '检测到卸载相关操作');
        this.recordUninstallAttempt();
      }
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '处理通知状态变化时发生错误');
    }
  }

  /**
   * 处理窗口内容变化事件（卸载界面检测）
   * @param eventObj 事件对象
   */
  private handleWindowContentChanged(eventObj: Record<string, Object>): void {
    try {
      // 检查是否包含卸载相关文本
      const textContent = this.extractTextContent(eventObj);
      if (this.isUninstallRelatedText(textContent)) {
        Logger.info('LanternLawAccessibilityAbility', '检测到卸载界面');
        this.recordUninstallAttempt();
      }
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '处理窗口内容变化时发生错误');
    }
  }

  /**
   * 检查是否应该记录应用切换（频率限制）
   * @param packageName 应用包名
   * @returns 是否应该记录
   */
  private shouldRecordAppSwitch(packageName: string): boolean {
    try {
      const now = Date.now();
      const record = this.appSwitchRecords.get(packageName);

      if (!record) {
        return true;
      }

      // 检查是否在频率限制窗口内
      const timeDiff = now - record.timestamp;
      return timeDiff >= FREQUENCY_LIMIT_WINDOW_MS;
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '检查应用切换频率限制时发生错误');
      return true; // 出错时允许记录，避免漏检
    }
  }

  /**
   * 记录应用切换尝试
   * @param packageName 应用包名
   */
  private async recordAppSwitchAttempt(packageName: string): Promise<void> {
    try {
      Logger.info('LanternLawAccessibilityAbility', `记录应用切换尝试: ${packageName}`);

      // 更新记录
      this.appSwitchRecords.set(packageName, {
        packageName: packageName,
        timestamp: Date.now()
      });

      // 调用状态管理器记录越狱尝试
      const stateManager = LanternLawStateManager.getInstance();
      await stateManager.recordEscapeAttempt('APP_SWITCH', packageName);

      Logger.info('LanternLawAccessibilityAbility', `应用切换尝试已记录: ${packageName}`);
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '记录应用切换尝试时发生错误');
    }
  }

  /**
   * 记录卸载尝试
   */
  private async recordUninstallAttempt(): Promise<void> {
    try {
      Logger.info('LanternLawAccessibilityAbility', '记录卸载尝试');

      // 调用状态管理器记录越狱尝试
      const stateManager = LanternLawStateManager.getInstance();
      await stateManager.recordEscapeAttempt('UNINSTALL_ATTEMPT', LANTERNLAW_APP_PACKAGE);

      Logger.info('LanternLawAccessibilityAbility', '卸载尝试已记录');
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '记录卸载尝试时发生错误');
    }
  }

  /**
   * 检查是否是系统应用
   * @param packageName 应用包名
   * @returns 是否是系统应用
   */
  private isSystemApp(packageName: string): boolean {
    if (typeof packageName !== 'string' || !packageName) {
      return false;
    }

    return SYSTEM_APP_PREFIXES.some(prefix => packageName.startsWith(prefix));
  }

  /**
   * 提取文本内容
   * @param eventObj 事件对象
   * @returns 提取的文本内容
   */
  private extractTextContent(eventObj: Record<string, Object>): string {
    try {
      const text = eventObj['text'] as string;
      if (text) {
        return String(text).toLowerCase();
      }

      // 尝试从 source 中获取
      const source = eventObj['source'] as Record<string, Object>;
      if (source) {
        const sourceText = source['text'] as string;
        if (sourceText) {
          return String(sourceText).toLowerCase();
        }
      }

      return '';
    } catch (error) {
      Logger.exception('LanternLawAccessibilityAbility', error instanceof Error ? error : String(error), '提取文本内容时发生错误');
      return '';
    }
  }

  /**
   * 检查是否包含卸载相关文本
   * @param text 文本内容
   * @returns 是否包含卸载相关文本
   */
  private isUninstallRelatedText(text: string): boolean {
    if (!text) {
      return false;
    }

    const uninstallKeywords: string[] = [
      'uninstall',
      '卸载',
      'remove',
      '删除',
      'disable',
      '禁用',
      '停用',
      'force stop',
      '强制停止',
      'clear data',
      '清除数据',
      'storage',
      '存储',
      'app info',
      '应用信息',
      'application',
      '应用'
    ];

    return uninstallKeywords.some(keyword => text.includes(keyword));
  }
}
