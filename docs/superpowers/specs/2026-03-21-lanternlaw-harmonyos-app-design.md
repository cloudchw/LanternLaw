# LanternLaw - 鸿蒙宵禁自律应用设计方案

## 概述

### 项目背景
LanternLaw是一款基于鸿蒙操作系统的自律工具应用，帮助用户在夜间建立健康的睡眠习惯。应用通过宵禁机制限制设备使用，提供数据统计和成就系统，激励用户坚持早睡。

### 核心价值主张
- **不可逆转性**：宵禁一旦启动，除非设备重启或等待天亮，否则无法退出
- **诗意表达**：极简界面配合克制但略带诗意的文案
- **成就激励**：通过掌灯人系统和里程碑成就提供正向反馈
- **数据洞察**：记录成功时长和越狱尝试，提供行为分析

### 目标用户
- 希望改善睡眠习惯的年轻人
- 需要夜间自我约束的用户
- 追求数字极简主义和自律生活的人群

## 需求分析

### 核心需求
1. **宵禁管理**：用户可设置就寝时间和解锁时间，应用自动管理宵禁
2. **越狱监测**：检测并记录绕过宵禁的尝试行为
3. **数据统计**：记录成功宵禁时长和尝试越狱次数
4. **成就系统**：通过掌灯人和里程碑成就提供激励
5. **极简界面**：以表盘为核心的极简设计，无多余信息流

### 用户场景
1. **设置宵禁**：用户首次使用时配置就寝时间和解锁时间
2. **日常使用**：到点自动进入宵禁，限制设备使用直到早上
3. **坚守成功**：成功完成宵禁后获得掌灯人激励，解锁成就
4. **越狱尝试**：用户试图绕过宵禁时被检测记录，收到警示
5. **数据回顾**：查看历史统计和成就解锁情况

## 系统架构

### 模块划分
```
LanternLaw应用架构
├── 宵禁管理模块
│   ├── 时间调度器
│   ├── 状态管理器
│   └── 紧急解锁处理器
├── 越狱检测模块
│   ├── 应用切换检测器
│   ├── 卸载尝试检测器
│   └── 越狱记录器
├── 数据统计模块
│   ├── 每日记录器
│   ├── 统计计算器
│   └── 趋势分析器
├── 成就系统模块
│   ├── 掌灯人管理器
│   ├── 成就解锁器
│   └── 奖励反馈器
├── 用户界面模块
│   ├── 表盘主界面
│   ├── 统计面板
│   └── 设置界面
└── 存储模块
    ├── 配置存储
    ├── 记录存储
    └── 成就存储
```

### 数据流
1. **配置阶段**：用户设置 → 配置存储 → 时间调度器初始化
2. **宵禁启动**：时间触发 → 状态变更 → 监测服务启动 → 界面更新
3. **越狱检测**：事件触发 → 检测器响应 → 记录存储 → 界面反馈
4. **宵禁结束**：时间触发 → 状态变更 → 数据计算 → 成就检查 → 存储更新
5. **用户交互**：界面操作 → 状态查询 → 数据读取 → 界面渲染

## 功能设计

### 1. 宵禁管理功能

#### 1.1 时间配置
- **就寝时间**：用户自定义（默认22:30）
- **解锁时间**：用户自定义（默认06:30）
- **紧急解锁次数**：每月3次，可配置

#### 1.2 宵禁状态
- **空闲状态 (IDLE)**：非宵禁时段，可正常使用设备
- **活跃状态 (ACTIVE)**：宵禁进行中，设备功能受限
- **覆盖状态 (OVERRIDDEN)**：设备重启后恢复的宵禁状态

#### 1.3 不可逆转机制
1. **设备管理锁定**：使用鸿蒙设备管理API限制功能
2. **前台服务保持**：确保应用在后台持续运行
3. **覆盖层显示**：阻挡用户交互，显示宵禁界面
4. **重启处理**：设备重启后自动恢复宵禁状态

### 2. 越狱检测功能

#### 2.1 检测类型
- **应用切换检测**：用户尝试切换到其他应用
- **卸载/禁用检测**：用户尝试卸载或禁用本应用

#### 2.2 检测策略
- **频率限制**：每5分钟最多记录1次应用切换
- **误判过滤**：系统级应用切换（如电话）不计入
- **用户反馈**：每次检测到越狱尝试时提供视觉和触觉反馈

#### 2.3 记录格式
```typescript
interface EscapeAttempt {
  timestamp: number;     // 时间戳
  type: 'APP_SWITCH' | 'UNINSTALL_ATTEMPT';
  count: number;         // 本次计数
  totalEscapeCount: number; // 累计次数
}
```

### 3. 数据统计功能

#### 3.1 统计指标
- **成功宵禁时长**：实际坚持的宵禁时间（分钟）
- **尝试越狱次数**：当天越狱尝试总次数
- **连续成功天数**：不间断成功完成宵禁的天数
- **总体成功率**：历史成功次数/总尝试次数

#### 3.2 数据存储
```typescript
interface DailyRecord {
  id: string;           // 唯一标识符
  version: number;      // 数据版本号（用于数据迁移）
  date: string;         // "2026-03-21"
  lanternlawStart: number;  // 宵禁开始时间戳
  lanternlawEnd: number;    // 宵禁结束时间戳
  actualDuration: number; // 实际时长（分钟）
  escapeCount: number;  // 越狱次数
  success: boolean;     // 是否成功（无越狱且完成）
  createdAt: number;    // 创建时间戳
  updatedAt: number;    // 更新时间戳
}
```

#### 3.3 数据可视化
- **今日面板**：实时显示当前数据
- **本周概览**：7天趋势图表
- **历史记录**：按月/年查看统计数据

### 4. 成就系统功能

#### 4.1 掌灯人系统
- **数量**：7盏灯，代表一周
- **点亮规则**：每成功一天点亮一盏
- **视觉效果**：暖黄色渐变，呼吸动画，光链连接
- **重置周期**：每周一重置，保留历史记录

#### 4.2 成就类型
1. **连续天数里程碑**
   - 7天：周度坚守者
   - 30天：月度自律者
   - 100天：百日坚守
   - 365天：年度自律大师

2. **总成功天数**
   - 10天：新手上路
   - 50天：熟练坚守
   - 200天：资深自律者
   - 500天：自律大师

#### 4.3 成就反馈
- **视觉特效**：表盘金色光效
- **动画展示**：成就解锁动画
- **文案庆祝**："又一盏灯为你点亮"等诗意文案

## 用户界面设计

### 整体设计原则
- **极简主义**：减少元素，专注核心功能
- **诗意表达**：克制但富有意境的文案
- **功能隐喻**：通过视觉元素传达功能意义
- **深夜氛围**：深色主题配合暖色高光

### 色彩方案
- **主色调**：午夜蓝 (#0f1529)、暗夜黑 (#1a1f3a)
- **辅助色**：强调蓝 (#2a3157)
- **高亮色**：金色灯光 (#ffd166)、橙色辉光 (#ff9e6d)
- **文本色**：浅灰色 (#c0c6e9)、暖黄色 (#ff9e6d)

### 主界面设计

#### 布局结构
```
┌─────────────────────────────────────┐
│                                       │
│            ╔═══════════╗             │
│            ║           ║             │
│            ║   表盘     ║             │
│            ║           ║             │
│            ╚═══════════╝             │
│            [当前时间显示]              │
│                                       │
│       ──────────────────────         │
│        剩余解锁时间：X小时Y分钟        │
│       ──────────────────────         │
│                                       │
│       "夜晚的坚守，黎明的奖赏"          │
│                                       │
│   ● ● ● ● ○ ○ ○   (虚拟提灯系统)       │
│                                       │
│  ▼ 统计数据（轻触展开）                │
│  ▼ 设置按钮（仅在非宵禁时间可用）        │
└─────────────────────────────────────┘
```

#### 表盘组件
- **基础表盘**：深色背景，极简刻度
- **指针设计**：时针（金色）、分针（橙色）、秒针（透明微光）
- **状态指示**：
  - 正常状态：柔和发光，指针正常
  - 宵禁状态：变暗，指针变细，显示进度环
  - 越狱警示：短暂红色闪烁
  - 成就解锁：金色光效

#### 交互设计
- **轻触表盘**：切换显示模式（时间/剩余时间）
- **长按表盘**：振动反馈，显示深度文案
- **下滑手势**：展开统计面板
- **上滑手势**：收起面板

### 统计面板设计
- **折叠式设计**：默认收起，需要时展开
- **信息分层**：
  1. 今日概要（时长、越狱、成功率）
  2. 本周趋势（图表可视化）
  3. 成就列表（已解锁/进行中）
- **交互反馈**：平滑展开动画，数据刷新指示

### 设置界面设计
- **时间配置**：时间选择器，24小时制
- **紧急解锁**：剩余次数显示，使用记录
- **数据管理**：数据导出/清除选项
- **权限管理**：权限状态查看，重新申请

## 技术实现

### 鸿蒙技术栈
- **开发框架**：ArkUI 3.0
- **开发语言**：TypeScript (ETS)
- **构建工具**：Hvigor
- **测试框架**：Hypium
- **API版本**：API 9+ (HarmonyOS 4.0+)

### 核心API使用

#### 1. 设备管理
```typescript
// 设备管理API锁定功能
import deviceManager from '@ohos.distributedHardware.deviceManager';

class DeviceLockManager {
  async lockDevice(): Promise<void> {
    // 实现设备锁定逻辑
  }
}
```

#### 2. 无障碍服务
```json
// module.json5配置
{
  "abilities": [
    {
      "name": "LanternLawAccessibilityAbility",
      "type": "accessibility",
      "description": "越狱检测无障碍服务"
    }
  ]
}
```

#### 3. 前台服务
```typescript
@ServiceExtensionAbility
export default class LanternLawService extends ServiceExtensionAbility {
  onCreate(want: Want): void {
    // 创建前台服务通知
    this.context.startForegroundService(want, notificationRequest);
  }
}
```

#### 4. 本地存储

> **技术选型更新**：在API 20+中，推荐使用`@ohos.data.relationalStore`替代`@ohos.data.preferences`，以获得更好的性能和结构化数据支持。详见技术选型文档。
```typescript
import dataPreferences from '@ohos.data.preferences';

class LanternLawStorage {
  private preferences: dataPreferences.Preferences | null = null;

  async init(): Promise<void> {
    this.preferences = await dataPreferences.getPreferences(
      this.context,
      'lanternlaw_data'
    );
  }
}
```

### 组件架构

#### 主页面结构
```typescript
@Component
struct MainPage {
  @State currentTime: Date = new Date();
  @State isLanternLawActive: boolean = false;
  @State statsPanelExpanded: boolean = false;

  build() {
    Column({ space: 20 }) {
      // 表盘区域
      LanternLawClock({
        currentTime: this.currentTime,
        isActive: this.isLanternLawActive
      })

      // 时间显示
      TimeDisplay({ time: this.currentTime })

      // 剩余时间
      RemainingTimeDisplay({
        isLanternLawActive: this.isLanternLawActive,
        remainingMinutes: this.calculateRemainingTime()
      })

      // 激励文案
      MotivationText({ state: this.getCurrentState() })

      // 虚拟提灯
      LanternSystem({
        successDays: this.getSuccessDays(),
        currentStreak: this.getCurrentStreak()
      })

      // 统计面板
      if (this.statsPanelExpanded) {
        StatsPanel({
          dailyStats: this.dailyStats,
          achievements: this.achievements
        })
      }
    }
  }
}
```

#### 表盘组件
```typescript
@Component
struct LanternLawClock {
  @Prop currentTime: Date;
  @Prop isActive: boolean;
  @State clockSize: number = 300;

  build() {
    Canvas(this.context)
      .width(this.clockSize)
      .height(this.clockSize)
      .onReady(() => {
        this.drawClockFace();
        this.drawClockHands();
        if (this.isActive) {
          this.drawProgressRing();
        }
      })
  }
}
```

### 状态管理

#### 全局状态管理器
```typescript
class LanternLawStateManager {
  private static instance: LanternLawStateManager;

  // 响应式状态
  @State lanternlawState: LanternLawState = LanternLawState.IDLE;
  @State dailyStats: DailyStats;
  @State achievements: Achievement[];

  // 状态更新方法
  updateLanternLawState(newState: LanternLawState): void {
    this.lanternlawState = newState;
    this.persistState();
    this.notifyUI();
  }

  // 数据持久化
  async persistState(): Promise<void> {
    await LanternLawStorage.saveLanternLawState(this.lanternlawState);
    await LanternLawStorage.saveDailyStats(this.dailyStats);
  }
}
```

### 性能优化

#### 1. Canvas优化
- **按需渲染**：只在时间变化时重绘
- **分层绘制**：指针和表盘分离Canvas层
- **硬件加速**：启用GPU渲染
- **缓存策略**：静态元素预渲染到位图

#### 2. 内存管理
- **资源优化**：使用WebP格式，按需加载
- **组件回收**：虚拟列表处理历史记录
- **及时释放**：页面离开时释放Canvas上下文

#### 3. 电池优化
- **后台调度**：使用WorkScheduler
- **传感器管理**：只在必要时启用
- **网络优化**：避免不必要请求

### 测试策略

#### 单元测试
```typescript
import { describe, it, expect } from '@ohos.hypium';

describe('LanternLawLogicTest', () => {
  it('testLanternLawTimeCalculation', () => {
    const config: LanternLawConfig = { bedtime: '22:30', wakeupTime: '06:30' };
    const currentTime = '23:00';
    const result = shouldLanternLawBeActive(config, currentTime);
    expect(result).assertTrue();
  });
});
```

#### UI测试
```typescript
import { Driver, ON } from '@ohos.uitest';

describe('MainPageUITest', () => {
  it('testClockInteraction', async () => {
    const driver = await Driver.create();
    const clock = await driver.findComponent(ON.text('22:30'));
    await clock.click();
    const timeDisplay = await driver.findComponent(ON.text('当前时间'));
    expect(await timeDisplay.getText()).assertContain('22:30');
  });
});
```

## 部署与维护

### 构建配置
```json5
// build-profile.json5
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compileSdkVersion": 9,
        "compatibleSdkVersion": 9
      }
    ]
  }
}
```

### 权限配置
```json5
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.DEVICE_MANAGER",
        "reason": "宵禁锁定需要设备管理权限"
      },
      {
        "name": "ohos.permission.ACCESSIBILITY",
        "reason": "越狱检测需要无障碍服务权限"
      }
    ]
  }
}
```

### 发布计划

#### 版本1.0.0 (MVP)
- 基本宵禁功能（时间设置、自动启动）
- 基础越狱检测（应用切换）
- 简单数据统计（时长、次数）
- 虚拟提灯系统
- 表盘主界面

#### 版本1.1.0
- 高级越狱检测（卸载尝试）
- 详细统计面板（图表可视化）
- 成就系统（里程碑成就）
- 数据导出功能

#### 版本1.2.0
- 云同步备份（可选）
- 社交分享功能（成就分享）
- 自定义主题
- 高级分析报告

## 风险与缓解

### 技术风险
1. **权限获取困难**：用户可能拒绝关键权限
   - 缓解：逐步引导，提供降级方案，清晰说明必要性

2. **系统兼容性**：不同鸿蒙版本API差异
   - 缓解：明确最低API版本，使用条件编译

3. **电池消耗**：前台服务和监测可能增加耗电
   - 缓解：优化监测频率，提供省电模式

### 用户体验风险
1. **过于严格**：不可逆转性可能引起用户反感
   - 缓解：提供有限紧急解锁，清晰说明设计理念

2. **隐私担忧**：越狱监测可能被视为侵犯隐私
   - 缓解：本地处理数据，不收集个人身份信息，透明隐私政策

3. **使用门槛**：极简设计可能隐藏功能
   - 缓解：首次使用引导，提供帮助文档

### 业务风险
1. **应用商店审核**：设备管理功能可能审核严格
   - 缓解：准备详细功能说明，遵循平台规范

2. **用户留存**：功能单一可能影响长期使用
   - 缓解：通过成就系统增加游戏化元素，定期更新内容

## 成功标准

### 技术成功标准
- 应用通过鸿蒙应用市场审核
- 在目标设备上稳定运行（无崩溃）
- 宵禁功能100%可靠（无意外解锁）
- 越狱检测准确率>95%

### 用户体验标准
- 用户评分>4.5/5.0
- 30日留存率>40%
- 平均每日使用时长>15分钟
- 成就解锁完成率>30%

### 业务成功标准
- 发布后3个月下载量>10,000
- 月活跃用户>3,000
- 用户推荐率>25%
- 应用商店正面评价>100条

## 附录

### A. 文案库

#### 激励文案
- "夜晚的坚守，黎明的奖赏"
- "自律是自由的开始"
- "每一分钟坚持，都是对自己的承诺"
- "黑夜终将过去，坚守终有回报"

#### 警示文案
- "请回吧，黑夜不属于这里"
- "黑夜在注视"
- "每一次越狱，都是对自己的背叛"
- "坚守此刻，成就未来"

#### 成就文案
- "又一盏灯为你点亮"
- "周度坚守者，名副其实"
- "百日坚守，见证自律的力量"
- "年度自律大师，你做到了！"

### B. 设计参考
- 色彩方案：见"色彩方案"章节
- 图标设计：提供图标设计规范
- 动效规范：提供动画时长和曲线规范

### C. 技术参考
- 鸿蒙官方文档链接
- 关键API参考手册
- 性能优化指南
- 测试最佳实践

---

**文档版本**：1.0
**最后更新**：2026-03-21
**作者**：Claude Code Assistant
**状态**：已批准 ✅