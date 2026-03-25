# Curfew - 鸿蒙APK Level技术选型设计方案

## 概述

### 决策背景
基于用户对"鸿蒙APK Level"的澄清需求，明确技术选型目标为API版本级别选择。原设计文档（2026-03-21）建议API 9+ (HarmonyOS 4.0+)，但考虑到市场发展和设备兼容性，需要进行技术选型确认。

### 选型目标
1. **明确鸿蒙API版本**：确定compileSdkVersion、targetSdkVersion等关键配置
2. **平衡兼容性与先进性**：在设备覆盖和功能新颖性间找到平衡点
3. **验证核心功能支持**：确保设计文档中的关键功能在选定API上可用

### 决策过程
- **用户澄清**："鸿蒙APK Level"指API版本级别（类似Android的minSdkVersion/targetSdkVersion）
- **用户要求**：采用API 21（对应HarmonyOS 6.0.1+）
- **方案分析**：提出三个方案，用户选择方案二（API 20 - HarmonyOS 6.0.0+）

## 技术选型方案

### 方案二：平衡兼容性 - API 20 (HarmonyOS 6.0.0+)

#### 版本配置
```json
{
  "compileSdkVersion": 20,
  "compatibleSdkVersion": 20,
  "targetSdkVersion": 21,
  "apiReleaseType": "Release",
  "deviceTypes": ["phone"]
}
```

#### 配置详解
| 配置项 | 值 | 说明 |
|--------|-----|------|
| **compileSdkVersion** | 20 | 编译时使用的SDK版本，对应HarmonyOS 6.0.0（参考：HarmonyOS 6.0.1对应API 21，6.0.0对应API 20） |
| **compatibleSdkVersion** | 20 | 应用兼容的最低API版本 |
| **targetSdkVersion** | 21 | 应用目标API版本，可调用API 21特性 |
| **apiReleaseType** | Release | 使用正式发布版SDK，非Beta版本 |

**说明**：`compileSdkVersion: 20`表示使用API 20编译，`targetSdkVersion: 21`表示应用目标API版本为21，可调用API 21特性（需运行时检查）。这种配置在鸿蒙开发中是常见模式，平衡了编译兼容性和目标特性使用。

## 核心API兼容性分析

### 与设计文档功能对比

| 功能模块 | 设计文档(API 9+) | API 20兼容性 | 调整建议 |
|---------|----------------|--------------|----------|
| **设备管理** | `@ohos.distributedHardware.deviceManager` | ✅ **完全支持**<br>DeviceManager从API 7开始支持，API 20有增强 | 无需调整，保持原设计 |
| **无障碍服务** | `AccessibilityExtensionAbility` | ✅ **完全支持**<br>无障碍服务是鸿蒙核心功能 | 无需调整，接口保持兼容 |
| **前台服务** | `ServiceExtensionAbility` | ⚠️ **有限支持**<br>鸿蒙NEXT限制第三方应用使用 | 调整为后台任务+系统能力保持 |
| **本地存储** | `@ohos.data.preferences` | ✅ **完全支持**<br>保持向后兼容，接口稳定。<br>**注意**：API 20+推荐使用`@ohos.data.relationalStore`进行结构化数据存储 | 可考虑升级到`@ohos.data.relationalStore`以获得更好性能 |
| **Canvas绘制** | ArkUI Canvas API | ✅ **完全支持**<br>ArkUI 3.0在API 20中更成熟 | 无需调整，可能有性能优化 |

**数据存储升级说明**：
- **推荐方案**：API 20+推荐使用`@ohos.data.relationalStore`进行结构化数据存储，性能更好，支持SQL查询
- **数据迁移**：从`@ohos.data.preferences`迁移到`@ohos.data.relationalStore`需要设计数据迁移脚本，确保用户数据不丢失
- **接口设计**：更新`DailyRecord`接口，添加唯一标识符、版本号和时间戳字段，便于数据管理和迁移
- **兼容性**：保持对`@ohos.data.preferences`的兼容支持，逐步迁移到新存储方案

### 关键调整点

#### 1. 前台服务实现调整
```typescript
// 原设计：ServiceExtensionAbility（需要调整）
// 新方案：多策略后台保活方案

import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import deviceManager from '@ohos.distributedHardware.deviceManager';
import runningLock from '@ohos.runningLock';
import { BusinessError } from '@ohos.base';

class CurfewBackgroundService {
  private suspendDelayId: number = 0;
  private runningLock: runningLock.RunningLock | null = null;
  private keepAliveTimer: number | null = null;

  async keepAlive(): Promise<void> {
    // 策略1：申请后台运行延迟（最高30秒）
    try {
      this.suspendDelayId = await backgroundTaskManager.requestSuspendDelay(
        'Curfew宵禁保持',
        30000 // 30秒延迟
      );

      // 注册延迟到期回调
      backgroundTaskManager.subscribeSuspendDelayEvent(
        this.suspendDelayId,
        this.onSuspendDelayExpired.bind(this)
      );
    } catch (error) {
      console.error(`后台延迟申请失败: ${JSON.stringify(error)}`);
    }

    // 策略2：获取运行锁（防止系统休眠）
    try {
      const lockInfo: runningLock.RunningLockInfo = {
        name: 'CurfewBackgroundLock',
        type: runningLock.RunningLockType.BACKGROUND
      };
      this.runningLock = await runningLock.createRunningLock(lockInfo);
      if (this.runningLock) {
        await this.runningLock.lock(5000); // 锁定5秒
        console.log('运行锁获取成功');
      }
    } catch (error) {
      console.error(`运行锁获取失败: ${JSON.stringify(error)}`);
    }

    // 策略3：定时刷新保活状态
    this.startKeepAliveTimer();
  }

  private startKeepAliveTimer(): void {
    // 每20秒刷新一次保活状态
    this.keepAliveTimer = setInterval(() => {
      this.refreshKeepAlive();
    }, 20000) as unknown as number;
  }

  private async refreshKeepAlive(): Promise<void> {
    // 刷新运行锁
    if (this.runningLock) {
      try {
        await this.runningLock.lock(5000);
      } catch (error) {
        console.error(`运行锁刷新失败: ${JSON.stringify(error)}`);
      }
    }

    // 检查后台延迟状态
    try {
      const delayInfo = await backgroundTaskManager.getSuspendDelayStatus();
      if (delayInfo.remainingTime < 10000) {
        // 剩余时间不足10秒，重新申请
        await this.renewSuspendDelay();
      }
    } catch (error) {
      console.error(`延迟状态检查失败: ${JSON.stringify(error)}`);
    }
  }

  private async renewSuspendDelay(): Promise<void> {
    if (this.suspendDelayId > 0) {
      await backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
    }

    try {
      this.suspendDelayId = await backgroundTaskManager.requestSuspendDelay(
        'Curfew宵禁保持',
        30000
      );
    } catch (error) {
      console.error(`延迟重新申请失败: ${JSON.stringify(error)}`);
    }
  }

  private onSuspendDelayExpired(): void {
    // 延迟到期，重新申请
    this.renewSuspendDelay();
  }

  async stopKeepAlive(): Promise<void> {
    // 清理定时器
    if (this.keepAliveTimer !== null) {
      clearInterval(this.keepAliveTimer);
      this.keepAliveTimer = null;
    }

    // 释放运行锁
    if (this.runningLock) {
      try {
        this.runningLock.unlock();
      } catch (error) {
        console.error(`运行锁释放失败: ${JSON.stringify(error)}`);
      }
      this.runningLock = null;
    }

    // 取消后台延迟
    if (this.suspendDelayId > 0) {
      try {
        await backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
        this.suspendDelayId = 0;
      } catch (error) {
        console.error(`延迟取消失败: ${JSON.stringify(error)}`);
      }
    }
  }
}
```

**技术风险说明**：
1. **后台延迟限制**：`backgroundTaskManager.requestSuspendDelay()`最多30秒，对整夜运行的宵禁功能不足
2. **运行锁限制**：`runningLock.lock(5000)`只能锁定5秒
3. **系统资源限制**：鸿蒙NEXT对第三方应用后台运行有严格限制
4. **电池消耗**：频繁刷新会增加电池消耗

**替代方案建议**：
1. **使用设备管理API实现设备锁定**：通过`deviceManager.lockDevice()`直接锁定设备，无需应用后台运行
2. **申请长时任务权限**：研究鸿蒙"特殊场景"权限申请流程
3. **用户教育**：引导用户在设置中手动授予应用后台运行权限
4. **降级方案**：设备锁定时显示全屏警告界面，防止用户绕过

#### 2. 设备管理API优化
```typescript
// API 20可能提供增强的设备管理功能
import deviceManager from '@ohos.distributedHardware.deviceManager';

class EnhancedDeviceLockManager {
  private dmInstance: deviceManager.DeviceManager;

  async init(): Promise<void> {
    // API 20可能有更简洁的初始化方式
    this.dmInstance = await deviceManager.createDeviceManager('com.curfew.app');

    // 注册设备状态监听（API 20可能有更丰富的事件）
    this.dmInstance.on('deviceStateChange', this.handleDeviceStateChange.bind(this));
    this.dmInstance.on('deviceTrustLevelChange', this.handleTrustLevelChange.bind(this));
  }

  private handleDeviceStateChange(data): void {
    // 处理设备连接状态变化
    console.log(`设备状态变更: ${JSON.stringify(data)}`);
  }

  private handleTrustLevelChange(data): void {
    // 处理设备信任级别变化
    console.log(`设备信任级别变更: ${JSON.stringify(data)}`);
  }
}
```

## 设备兼容性分析

### 目标设备范围
- **主要支持**：HarmonyOS 6.0.0+ 智能手机
- **具体版本**：6.0.0 (API 20) → 6.0.2+ (API 22+)
- **排除版本**：HarmonyOS 5.x及以下（API 19以下）

### 市场影响评估（基于2026年数据）
| 指标 | 分析 | 影响 |
|------|------|------|
| **设备覆盖** | HarmonyOS 6.0+设备约95%+ | ✅ **覆盖主流设备** |
| **用户群体** | 放弃HarmonyOS 5.x用户约5% | ⚠️ **小部分用户流失** |
| **技术前瞻** | 面向未来设备架构 | ✅ **减少升级成本** |
| **开发资源** | 无需维护多版本兼容 | ✅ **开发效率高** |

## 开发环境配置

### 工具要求
| 工具/配置 | 要求 | 说明 |
|-----------|------|------|
| **DevEco Studio** | 4.1.0+ | 支持API 20编译和调试 |
| **HarmonyOS SDK** | ohos_sdk_public_6.0.0.110+ | API 20 Release SDK（格式：ohos_sdk_public_{版本号}） |
| **构建工具** | Hvigor 3.0.0+ | 支持API级别配置 |
| **测试设备** | HarmonyOS 6.0.0+ 手机 | 真实设备测试必需 |

### 项目配置文件

#### `module.json5` 核心配置
```json
{
  "module": {
    "name": "curfew",
    "type": "entry",
    "deviceTypes": ["phone"],
    "compileMode": "esmodule",
    "compileSdkVersion": 20,
    "compatibleSdkVersion": 20,
    "targetSdkVersion": 21,
    "apiReleaseType": "Release",
    "abilities": [
      {
        "name": "MainAbility",
        "srcEntry": "./ets/mainability/MainAbility.ts",
        "description": "主界面入口",
        "exported": true
      },
      {
        "name": "CurfewAccessibilityAbility",
        "type": "accessibility",
        "srcEntry": "./ets/accessibility/CurfewAccessibilityAbility.ts",
        "description": "越狱检测无障碍服务"
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.DISTRIBUTED_DATASYNC",
        "reason": "设备管理需要分布式数据同步"
      },
      {
        "name": "ohos.permission.DEVICE_MANAGER",
        "reason": "宵禁功能需要设备锁定和解锁权限"
      },
      {
        "name": "ohos.permission.RUNNING_LOCK",
        "reason": "保持应用后台运行需要运行锁"
      },
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",
        "reason": "宵禁功能需要长时间后台运行"
      },
      {
        "name": "ohos.permission.ACCESSIBILITY",
        "reason": "越狱检测需要无障碍服务权限"
      },
      {
        "name": "ohos.permission.MANAGE_DISPOSED_ABILITY_STATUS",
        "reason": "管理应用Ability状态，确保宵禁服务正常运行"
      }
    ]
  }
}
```

#### `build-profile.json5` 构建配置
```json
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compatibleSdkVersion": 20,
        "compileSdkVersion": 20,
        "targetSdkVersion": 21
      }
    ]
  }
}
```

## 实施计划

### 第一阶段：环境准备与验证
```bash
# 1. 安装DevEco Studio 4.1.0+
# 2. 下载Ohos_sdk_public 6.0.0.110 (API 20 Release)
# 3. 创建API 20测试工程
# 4. 验证关键API可用性
```

### 第二阶段：功能适配与测试
```bash
# 1. 根据API 20调整ServiceExtensionAbility实现
# 2. 验证设备管理API在API 20上的行为
# 3. 测试无障碍服务功能
# 4. 性能测试与优化
```

### 第三阶段：集成与发布
```bash
# 1. 集成调整后的组件到Curfew项目
# 2. 真机测试（多款HarmonyOS 6.0+设备）
# 3. 应用市场审核准备
# 4. 发布与监控
```

## 风险评估与缓解

### 高风险项：前台服务权限限制
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| **无法使用ServiceExtensionAbility** | 高 | 采用后台任务+运行锁替代方案 |
| **用户手动设置需求** | 中 | 清晰的使用指南和权限引导 |
| **系统资源限制** | 中 | 优化资源使用，减少性能影响 |

### 中风险项：API 20功能变更
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| **设备管理API接口变化** | 中 | 详细查阅API 20文档，准备降级方案 |
| **无障碍服务审核要求** | 低 | 遵循开发规范，准备审核材料 |
| **性能差异** | 低 | 在不同设备上进行性能测试 |

### 低风险项：用户兼容性
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| **HarmonyOS 5.x用户流失** | 低 | 应用描述明确系统要求，收集反馈 |
| **新API学习曲线** | 低 | 参考官方文档和示例代码 |

## 成功标准

### 技术标准
- ✅ 应用在HarmonyOS 6.0.0+设备上正常运行
- ✅ 宵禁功能可靠（设备重启后状态恢复）
- ✅ 越狱检测准确率>95%
- ✅ 前台服务替代方案有效保活（24小时存活率>99%）
- ✅ 性能达标（启动时间<2秒，内存占用<150MB）

### 市场标准
- ✅ 应用市场审核通过
- ✅ 用户评价>4.5星（兼容性相关差评<5%）
- ✅ 30日留存率>40%
- ✅ 崩溃率<0.1%

## 后续步骤

### 立即执行
1. **创建API 20测试工程**：验证核心功能可行性
2. **调整前台服务实现**：完成后台任务替代方案
3. **更新项目配置**：应用新的API版本配置

### 设计确认
1. **用户review本设计文档**
2. **启动spec review loop**（自动验证设计完整性）
3. **过渡到implementation计划**

## 参考资料

### 官方文档
- [HarmonyOS 6.0.0 Release Notes](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-600)
- [DeviceManager API Reference](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-devicemanager)
- [AccessibilityExtensionAbility开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/accessibility-extension-ability)
- [后台任务管理](https://developer.huawei.com/consumer/en/doc/harmonyos-faqs-V5/faqs-background-tasks-1-V5)

### 市场数据
- [华为鸿蒙存量设备API版本使用数据](https://m.ithome.com/html/912221.htm)（2026年2月）
- [HarmonyOS 6.0.1(21)版本概览](https://developer.huawei.com/consumer/cn/doc/harmonyos-releases/overview-601)

---

**文档版本**: 1.0
**创建日期**: 2026-03-22
**更新日期**: 2026-03-22
**决策者**: [用户名称]
**技术负责人**: Claude Sonnet 4.6