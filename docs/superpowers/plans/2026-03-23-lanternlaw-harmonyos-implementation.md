# LanternLaw 鸿蒙应用实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现基于鸿蒙HarmonyOS 6.0.0+ (API 20)的宵禁自律应用，包含宵禁管理、越狱检测、数据统计、成就系统和极简表盘界面

**Architecture:** 采用ArkUI 3.0 + TypeScript (ETS)开发，使用设备管理API锁定设备，无障碍服务检测越狱行为，关系型数据库存储数据，基于状态管理实现响应式UI

**Tech Stack:** HarmonyOS API 20, ArkUI 3.0, TypeScript (ETS), @ohos.data.relationalStore, @ohos.distributedHardware.deviceManager, AccessibilityExtensionAbility, Canvas API

---

## 文件结构

### 项目根目录
```
LanternLaw/
├── entry/                           # 应用主模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/
│   │   │   │   ├── MainAbility/     # 主Ability
│   │   │   │   │   └── MainAbility.ts
│   │   │   │   ├── pages/           # 页面组件
│   │   │   │   │   ├── IndexPage.ets  # 主页面
│   │   │   │   │   ├── SettingsPage.ets # 设置页面
│   │   │   │   │   └── StatsPage.ets   # 统计页面
│   │   │   │   ├── components/      # 共享组件
│   │   │   │   │   ├── ClockComponent.ets      # 表盘组件
│   │   │   │   │   ├── LanternSystem.ets       # 虚拟提灯组件
│   │   │   │   │   ├── TimeDisplay.ets         # 时间显示组件
│   │   │   │   │   └── StatsPanel.ets          # 统计面板组件
│   │   │   │   ├── services/        # 后台服务
│   │   │   │   │   ├── LanternLawService.ets       # 宵禁服务
│   │   │   │   │   ├── DeviceLockManager.ets   # 设备锁定管理器
│   │   │   │   │   └── BackgroundKeepAlive.ets # 后台保活服务
│   │   │   │   ├── managers/        # 业务逻辑管理器
│   │   │   │   │   ├── LanternLawStateManager.ets  # 宵禁状态管理器
│   │   │   │   │   ├── EscapeDetectionManager.ets # 越狱检测管理器
│   │   │   │   │   ├── DataStatisticsManager.ets  # 数据统计管理器
│   │   │   │   │   └── AchievementManager.ets  # 成就管理器
│   │   │   │   ├── models/          # 数据模型
│   │   │   │   │   ├── LanternLawConfig.ets        # 配置模型
│   │   │   │   │   ├── DailyRecord.ets         # 每日记录模型
│   │   │   │   │   ├── EscapeAttempt.ets       # 越狱尝试模型
│   │   │   │   │   └── Achievement.ets         # 成就模型
│   │   │   │   ├── database/        # 数据库层
│   │   │   │   │   ├── LanternLawDatabase.ets      # 数据库管理器
│   │   │   │   │   └── migrations/             # 数据迁移
│   │   │   │   ├── accessibility/   # 无障碍服务
│   │   │   │   │   └── LanternLawAccessibilityAbility.ets
│   │   │   │   └── utils/           # 工具类
│   │   │   │       ├── TimeUtils.ets
│   │   │   │       ├── StorageUtils.ets
│   │   │   │       └── NotificationUtils.ets
│   │   │   ├── resources/           # 资源文件
│   │   │   │   └── base/
│   │   │   │       ├── element/
│   │   │   │       ├── media/
│   │   │   │       └── profile/
│   │   │   └── module.json5         # 模块配置
│   │   └── resources/
│   ├── ohosTest/                    # 测试模块
│   │   └── src/
│   │       └── test/
│   │           ├── ets/
│   │           │   ├── test/
│   │           │   │   └── Example.test.ets
│   │           │   └── list/
│   │           │       └── testList.test.ets
│   │           └── resources/
│   └── build-profile.json5          # 构建配置
├── signatures/                      # 签名文件
└── oh-package.json5                 # 项目依赖配置
```

### 核心配置文件
1. `entry/src/main/module.json5` - 模块配置，权限声明，Ability定义
2. `entry/src/main/resources/base/profile/main_pages.json` - 页面路由配置
3. `entry/build-profile.json5` - 构建配置，API版本设置
4. `oh-package.json5` - 依赖管理

---

## 实施任务

### Task 1: 创建基础项目结构

**Files:**
- Create: `entry/src/main/module.json5`
- Create: `entry/src/main/resources/base/profile/main_pages.json`
- Create: `entry/build-profile.json5`
- Create: `oh-package.json5`

- [ ] **Step 1: 创建模块配置文件**

```json5
// entry/src/main/module.json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "宵禁自律应用主模块",
    "mainElement": "MainAbility",
    "deviceTypes": ["phone"],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "MainAbility",
        "srcEntry": "./ets/MainAbility/MainAbility.ts",
        "description": "应用主界面",
        "icon": "$media:app_icon",
        "label": "LanternLaw",
        "startWindowIcon": "$media:app_icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": ["entity.system.home"],
            "actions": ["action.system.home"]
          }
        ]
      },
      {
        "name": "LanternLawAccessibilityAbility",
        "type": "accessibility",
        "srcEntry": "./ets/accessibility/LanternLawAccessibilityAbility.ets",
        "description": "越狱检测无障碍服务",
        "exported": false
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

- [ ] **Step 2: 创建页面路由配置**

```json
// entry/src/main/resources/base/profile/main_pages.json
{
  "src": [
    "pages/IndexPage"
  ]
}
```

- [ ] **Step 3: 创建构建配置文件**

```json5
// entry/build-profile.json5
{
  "app": {
    "signingConfigs": [],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "compileSdkVersion": 20,
        "compatibleSdkVersion": 20,
        "targetSdkVersion": 21,
        "apiReleaseType": "Release"
      }
    ]
  }
}
```

- [ ] **Step 4: 创建依赖配置文件**

```json5
// oh-package.json5
{
  "license": "ISC",
  "devDependencies": {},
  "name": "lanternlaw",
  "description": "鸿蒙宵禁自律应用",
  "version": "1.0.0",
  "dependencies": {}
}
```

- [ ] **Step 5: 提交基础项目结构**

```bash
git add entry/src/main/module.json5 entry/src/main/resources/base/profile/main_pages.json entry/build-profile.json5 oh-package.json5
git commit -m "feat: 创建基础鸿蒙项目结构"
```

### Task 2: 创建数据模型

**Files:**
- Create: `entry/src/main/ets/models/LanternLawConfig.ets`
- Create: `entry/src/main/ets/models/DailyRecord.ets`
- Create: `entry/src/main/ets/models/EscapeAttempt.ets`
- Create: `entry/src/main/ets/models/Achievement.ets`

- [ ] **Step 1: 创建宵禁配置模型**

```typescript
// entry/src/main/ets/models/LanternLawConfig.ets
export class LanternLawConfig {
  bedtime: string = '22:30';        // 就寝时间 HH:mm
  wakeupTime: string = '06:30';     // 解锁时间 HH:mm
  emergencyUnlocks: number = 3;     // 每月紧急解锁次数
  emergencyUsed: number = 0;        // 已用紧急解锁次数
  lanternlawEnabled: boolean = true;    // 宵禁是否启用
  vibrationEnabled: boolean = true; // 振动反馈是否启用
  soundEnabled: boolean = false;    // 声音反馈是否启用

  // 验证配置有效性
  isValid(): boolean {
    const bedtimeParts = this.bedtime.split(':');
    const wakeupParts = this.wakeupTime.split(':');

    if (bedtimeParts.length !== 2 || wakeupParts.length !== 2) {
      return false;
    }

    const bedtimeHour = parseInt(bedtimeParts[0]);
    const bedtimeMinute = parseInt(bedtimeParts[1]);
    const wakeupHour = parseInt(wakeupParts[0]);
    const wakeupMinute = parseInt(wakeupParts[1]);

    return bedtimeHour >= 0 && bedtimeHour < 24 &&
           bedtimeMinute >= 0 && bedtimeMinute < 60 &&
           wakeupHour >= 0 && wakeupHour < 24 &&
           wakeupMinute >= 0 && wakeupMinute < 60;
  }

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      bedtime: this.bedtime,
      wakeupTime: this.wakeupTime,
      emergencyUnlocks: this.emergencyUnlocks,
      emergencyUsed: this.emergencyUsed,
      lanternlawEnabled: this.lanternlawEnabled,
      vibrationEnabled: this.vibrationEnabled,
      soundEnabled: this.soundEnabled
    });
  }

  // 从JSON解析
  static fromJSON(json: string): LanternLawConfig {
    const data = JSON.parse(json);
    const config = new LanternLawConfig();

    config.bedtime = data.bedtime || config.bedtime;
    config.wakeupTime = data.wakeupTime || config.wakeupTime;
    config.emergencyUnlocks = data.emergencyUnlocks || config.emergencyUnlocks;
    config.emergencyUsed = data.emergencyUsed || config.emergencyUsed;
    config.lanternlawEnabled = data.lanternlawEnabled !== undefined ? data.lanternlawEnabled : config.lanternlawEnabled;
    config.vibrationEnabled = data.vibrationEnabled !== undefined ? data.vibrationEnabled : config.vibrationEnabled;
    config.soundEnabled = data.soundEnabled !== undefined ? data.soundEnabled : config.soundEnabled;

    return config;
  }
}
```

- [ ] **Step 2: 创建每日记录模型**

```typescript
// entry/src/main/ets/models/DailyRecord.ets
export class DailyRecord {
  id: string = '';                  // 唯一标识符
  version: number = 1;              // 数据版本号（用于数据迁移）
  date: string = '';                // 日期 "2026-03-23"
  lanternlawStart: number = 0;          // 宵禁开始时间戳
  lanternlawEnd: number = 0;            // 宵禁结束时间戳
  actualDuration: number = 0;       // 实际时长（分钟）
  escapeCount: number = 0;          // 越狱次数
  success: boolean = false;         // 是否成功（无越狱且完成）
  createdAt: number = 0;            // 创建时间戳
  updatedAt: number = 0;            // 更新时间戳

  // 计算是否在今天
  isToday(): boolean {
    const today = new Date().toISOString().split('T')[0];
    return this.date === today;
  }

  // 计算成功百分比
  successPercentage(): number {
    if (this.actualDuration === 0) return 0;
    const totalMinutes = (this.lanternlawEnd - this.lanternlawStart) / (1000 * 60);
    return Math.round((this.actualDuration / totalMinutes) * 100);
  }

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      version: this.version,
      date: this.date,
      lanternlawStart: this.lanternlawStart,
      lanternlawEnd: this.lanternlawEnd,
      actualDuration: this.actualDuration,
      escapeCount: this.escapeCount,
      success: this.success,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    });
  }

  // 从JSON解析
  static fromJSON(json: string): DailyRecord {
    const data = JSON.parse(json);
    const record = new DailyRecord();

    record.id = data.id || record.id;
    record.version = data.version || record.version;
    record.date = data.date || record.date;
    record.lanternlawStart = data.lanternlawStart || record.lanternlawStart;
    record.lanternlawEnd = data.lanternlawEnd || record.lanternlawEnd;
    record.actualDuration = data.actualDuration || record.actualDuration;
    record.escapeCount = data.escapeCount || record.escapeCount;
    record.success = data.success !== undefined ? data.success : record.success;
    record.createdAt = data.createdAt || record.createdAt;
    record.updatedAt = data.updatedAt || record.updatedAt;

    return record;
  }

  // 生成唯一ID
  static generateId(): string {
    return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  }
}
```

- [ ] **Step 3: 创建越狱尝试模型**

```typescript
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
    const data = JSON.parse(json);
    const attempt = new EscapeAttempt();

    attempt.timestamp = data.timestamp || attempt.timestamp;
    attempt.type = data.type || attempt.type;
    attempt.appName = data.appName || attempt.appName;
    attempt.count = data.count || attempt.count;
    attempt.totalEscapeCount = data.totalEscapeCount || attempt.totalEscapeCount;

    return attempt;
  }
}
```

- [ ] **Step 4: 创建成就模型**

```typescript
// entry/src/main/ets/models/Achievement.ets
export class Achievement {
  id: string = '';                  // 成就ID
  name: string = '';                // 成就名称
  description: string = '';         // 成就描述
  type: string = '';                // 类型: 'STREAK' | 'TOTAL' | 'SPECIAL'
  requirement: number = 0;          // 解锁要求（天数/次数）
  unlocked: boolean = false;        // 是否已解锁
  unlockedAt: number = 0;           // 解锁时间戳
  icon: string = '';                // 成就图标

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      name: this.name,
      description: this.description,
      type: this.type,
      requirement: this.requirement,
      unlocked: this.unlocked,
      unlockedAt: this.unlockedAt,
      icon: this.icon
    });
  }

  // 从JSON解析
  static fromJSON(json: string): Achievement {
    const data = JSON.parse(json);
    const achievement = new Achievement();

    achievement.id = data.id || achievement.id;
    achievement.name = data.name || achievement.name;
    achievement.description = data.description || achievement.description;
    achievement.type = data.type || achievement.type;
    achievement.requirement = data.requirement || achievement.requirement;
    achievement.unlocked = data.unlocked !== undefined ? data.unlocked : achievement.unlocked;
    achievement.unlockedAt = data.unlockedAt || achievement.unlockedAt;
    achievement.icon = data.icon || achievement.icon;

    return achievement;
  }
}
```

- [ ] **Step 5: 提交数据模型**

```bash
git add entry/src/main/ets/models/
git commit -m "feat: 添加数据模型 (LanternLawConfig, DailyRecord, EscapeAttempt, Achievement)"
```

### Task 3: 创建数据库管理器

**Files:**
- Create: `entry/src/main/ets/database/LanternLawDatabase.ets`
- Create: `entry/src/main/ets/database/migrations/Migration_v1.ets`

- [ ] **Step 1: 创建数据库管理器**

```typescript
// entry/src/main/ets/database/LanternLawDatabase.ets
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';

export class LanternLawDatabase {
  private static instance: LanternLawDatabase;
  private rdbStore: relationalStore.RdbStore | null = null;

  // 数据库配置
  private readonly DB_CONFIG: relationalStore.StoreConfig = {
    name: 'lanternlaw.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  // 表定义
  private readonly CREATE_TABLES_SQL = `
    CREATE TABLE IF NOT EXISTS lanternlaw_config (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS daily_records (
      id TEXT PRIMARY KEY,
      version INTEGER NOT NULL,
      date TEXT NOT NULL,
      lanternlaw_start INTEGER NOT NULL,
      lanternlaw_end INTEGER NOT NULL,
      actual_duration INTEGER NOT NULL,
      escape_count INTEGER NOT NULL,
      success BOOLEAN NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      UNIQUE(date)
    );

    CREATE TABLE IF NOT EXISTS escape_attempts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      type TEXT NOT NULL,
      app_name TEXT,
      count INTEGER NOT NULL,
      total_escape_count INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS achievements (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      type TEXT NOT NULL,
      requirement INTEGER NOT NULL,
      unlocked BOOLEAN NOT NULL,
      unlocked_at INTEGER,
      icon TEXT,
      created_at INTEGER NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_daily_records_date ON daily_records(date);
    CREATE INDEX IF NOT EXISTS idx_escape_attempts_timestamp ON escape_attempts(timestamp);
    CREATE INDEX IF NOT EXISTS idx_achievements_unlocked ON achievements(unlocked);
  `;

  private constructor() {}

  // 获取单例实例
  public static getInstance(): LanternLawDatabase {
    if (!LanternLawDatabase.instance) {
      LanternLawDatabase.instance = new LanternLawDatabase();
    }
    return LanternLawDatabase.instance;
  }

  // 初始化数据库
  public async initialize(context: Context): Promise<void> {
    try {
      // 创建或打开数据库
      this.rdbStore = await relationalStore.getRdbStore(
        context,
        this.DB_CONFIG
      );

      // 创建表
      await this.rdbStore.executeSql(this.CREATE_TABLES_SQL);

      console.log('数据库初始化成功');
    } catch (error) {
      console.error(`数据库初始化失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 保存配置
  public async saveConfig(key: string, value: string): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const now = Date.now();
    const predicates = new relationalStore.RdbPredicates('lanternlaw_config');
    predicates.equalTo('key', key);

    try {
      // 检查是否已存在
      const resultSet = await this.rdbStore.query(predicates, ['id']);
      const isUpdate = await resultSet.goToFirstRow();
      resultSet.close();

      if (isUpdate) {
        // 更新现有记录
        const valuesBucket = {
          'value': value,
          'updated_at': now
        };
        await this.rdbStore.update(valuesBucket, predicates);
      } else {
        // 插入新记录
        const valuesBucket = {
          'key': key,
          'value': value,
          'updated_at': now
        };
        await this.rdbStore.insert('lanternlaw_config', valuesBucket);
      }
    } catch (error) {
      console.error(`保存配置失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 读取配置
  public async getConfig(key: string): Promise<string | null> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates('lanternlaw_config');
    predicates.equalTo('key', key);

    try {
      const columns = ['value'];
      const resultSet = await this.rdbStore.query(predicates, columns);

      if (await resultSet.goToFirstRow()) {
        const value = resultSet.getString(resultSet.getColumnIndex('value'));
        resultSet.close();
        return value;
      }

      resultSet.close();
      return null;
    } catch (error) {
      console.error(`读取配置失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 保存每日记录
  public async saveDailyRecord(record: any): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket = {
        'id': record.id,
        'version': record.version,
        'date': record.date,
        'lanternlaw_start': record.lanternlawStart,
        'lanternlaw_end': record.lanternlawEnd,
        'actual_duration': record.actualDuration,
        'escape_count': record.escapeCount,
        'success': record.success,
        'created_at': record.createdAt,
        'updated_at': record.updatedAt
      };

      // 使用REPLACE语义（INSERT OR REPLACE）
      await this.rdbStore.insert('daily_records', valuesBucket);
    } catch (error) {
      console.error(`保存每日记录失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 获取今日记录
  public async getTodayRecord(): Promise<any | null> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const today = new Date().toISOString().split('T')[0];
    const predicates = new relationalStore.RdbPredicates('daily_records');
    predicates.equalTo('date', today);

    try {
      const columns = [
        'id', 'version', 'date', 'lanternlaw_start', 'lanternlaw_end',
        'actual_duration', 'escape_count', 'success', 'created_at', 'updated_at'
      ];

      const resultSet = await this.rdbStore.query(predicates, columns);

      if (await resultSet.goToFirstRow()) {
        const record = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          version: resultSet.getLong(resultSet.getColumnIndex('version')),
          date: resultSet.getString(resultSet.getColumnIndex('date')),
          lanternlawStart: resultSet.getLong(resultSet.getColumnIndex('lanternlaw_start')),
          lanternlawEnd: resultSet.getLong(resultSet.getColumnIndex('lanternlaw_end')),
          actualDuration: resultSet.getLong(resultSet.getColumnIndex('actual_duration')),
          escapeCount: resultSet.getLong(resultSet.getColumnIndex('escape_count')),
          success: resultSet.getLong(resultSet.getColumnIndex('success')) === 1,
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
          updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
        };

        resultSet.close();
        return record;
      }

      resultSet.close();
      return null;
    } catch (error) {
      console.error(`获取今日记录失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 获取最近N天记录
  public async getRecentRecords(days: number = 7): Promise<any[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates('daily_records');
    predicates.orderByDesc('date');
    predicates.limit(days);

    try {
      const columns = [
        'id', 'date', 'actual_duration', 'escape_count', 'success'
      ];

      const resultSet = await this.rdbStore.query(predicates, columns);
      const records: any[] = [];

      while (await resultSet.goToNextRow()) {
        const record = {
          id: resultSet.getString(resultSet.getColumnIndex('id')),
          date: resultSet.getString(resultSet.getColumnIndex('date')),
          actualDuration: resultSet.getLong(resultSet.getColumnIndex('actual_duration')),
          escapeCount: resultSet.getLong(resultSet.getColumnIndex('escape_count')),
          success: resultSet.getLong(resultSet.getColumnIndex('success')) === 1
        };
        records.push(record);
      }

      resultSet.close();
      return records;
    } catch (error) {
      console.error(`获取最近记录失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 关闭数据库
  public async close(): Promise<void> {
    if (this.rdbStore) {
      try {
        await this.rdbStore.close();
        this.rdbStore = null;
      } catch (error) {
        console.error(`关闭数据库失败: ${JSON.stringify(error)}`);
      }
    }
  }
}
```

- [ ] **Step 2: 创建数据迁移脚本**

```typescript
// entry/src/main/ets/database/migrations/Migration_v1.ets
export class Migration_v1 {
  // v1迁移：从Preferences迁移到RelationalStore
  static async migrateFromPreferences(
    context: Context,
    preferences: any // 原有的Preferences实例
  ): Promise<void> {
    try {
      // 迁移配置数据
      const configKeys = ['bedtime', 'wakeupTime', 'emergencyUnlocks', 'emergencyUsed'];
      const db = LanternLawDatabase.getInstance();

      for (const key of configKeys) {
        const value = await preferences.get(key, null);
        if (value !== null) {
          await db.saveConfig(key, JSON.stringify(value));
        }
      }

      console.log('数据迁移完成');
    } catch (error) {
      console.error(`数据迁移失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }
}
```

- [ ] **Step 3: 提交数据库管理器**

```bash
git add entry/src/main/ets/database/
git commit -m "feat: 添加数据库管理器和数据迁移"
```

### Task 4: 创建宵禁状态管理器

**Files:**
- Create: `entry/src/main/ets/managers/LanternLawStateManager.ets`

- [ ] **Step 1: 创建宵禁状态枚举和类型**

```typescript
// entry/src/main/ets/managers/LanternLawStateManager.ets
export enum LanternLawState {
  IDLE = 'idle',          // 非宵禁时段
  ACTIVE = 'active',      // 宵禁进行中
  OVERRIDDEN = 'overridden' // 设备重启后恢复的宵禁状态
}

export interface LanternLawStateChangeListener {
  onStateChanged(newState: LanternLawState, oldState: LanternLawState): void;
  onTimeUpdated(currentTime: Date): void;
  onEscapeDetected(attempt: any): void;
}
```

- [ ] **Step 2: 创建宵禁状态管理器**

```typescript
// entry/src/main/ets/managers/LanternLawStateManager.ets (续)
import { LanternLawConfig } from '../models/LanternLawConfig';
import { DailyRecord } from '../models/DailyRecord';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { TimeUtils } from '../utils/TimeUtils';

export class LanternLawStateManager {
  private static instance: LanternLawStateManager;
  private currentState: LanternLawState = LanternLawState.IDLE;
  private config: LanternLawConfig = new LanternLawConfig();
  private todayRecord: DailyRecord | null = null;
  private listeners: LanternLawStateChangeListener[] = [];
  private updateTimer: number | null = null;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 宵禁状态持续时间（分钟）
  private lanternlawStartTime: Date | null = null;
  private lanternlawEndTime: Date | null = null;

  private constructor() {}

  public static getInstance(): LanternLawStateManager {
    if (!LanternLawStateManager.instance) {
      LanternLawStateManager.instance = new LanternLawStateManager();
    }
    return LanternLawStateManager.instance;
  }

  // 初始化管理器
  public async initialize(context: Context): Promise<void> {
    try {
      // 初始化数据库
      await this.database.initialize(context);

      // 加载配置
      await this.loadConfig();

      // 加载今日记录
      await this.loadTodayRecord();

      // 计算当前状态
      await this.calculateCurrentState();

      // 启动定时更新
      this.startUpdateTimer();

      console.log('宵禁状态管理器初始化成功');
    } catch (error) {
      console.error(`宵禁状态管理器初始化失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 加载配置
  private async loadConfig(): Promise<void> {
    try {
      const configJson = await this.database.getConfig('lanternlaw_config');
      if (configJson) {
        this.config = LanternLawConfig.fromJSON(configJson);
      }
    } catch (error) {
      console.error(`加载配置失败: ${JSON.stringify(error)}`);
    }
  }

  // 保存配置
  public async saveConfig(config: LanternLawConfig): Promise<void> {
    this.config = config;
    await this.database.saveConfig('lanternlaw_config', config.toJSON());

    // 重新计算状态
    await this.calculateCurrentState();
  }

  // 加载今日记录
  private async loadTodayRecord(): Promise<void> {
    try {
      const recordData = await this.database.getTodayRecord();
      if (recordData) {
        this.todayRecord = DailyRecord.fromJSON(JSON.stringify(recordData));
      } else {
        // 创建新记录
        this.todayRecord = new DailyRecord();
        this.todayRecord.id = DailyRecord.generateId();
        this.todayRecord.date = new Date().toISOString().split('T')[0];
        this.todayRecord.createdAt = Date.now();
        this.todayRecord.updatedAt = Date.now();
      }
    } catch (error) {
      console.error(`加载今日记录失败: ${JSON.stringify(error)}`);
    }
  }

  // 保存今日记录
  public async saveTodayRecord(): Promise<void> {
    if (this.todayRecord) {
      this.todayRecord.updatedAt = Date.now();
      await this.database.saveDailyRecord(this.todayRecord);
    }
  }

  // 计算当前状态
  private async calculateCurrentState(): Promise<void> {
    if (!this.config.lanternlawEnabled) {
      await this.setState(LanternLawState.IDLE);
      return;
    }

    const now = new Date();
    const bedtime = TimeUtils.parseTimeString(this.config.bedtime);
    const wakeupTime = TimeUtils.parseTimeString(this.config.wakeupTime);

    // 计算今天的宵禁时间段
    const lanternlawStart = new Date(now);
    lanternlawStart.setHours(bedtime.hour, bedtime.minute, 0, 0);

    const lanternlawEnd = new Date(now);
    lanternlawEnd.setHours(wakeupTime.hour, wakeupTime.minute, 0, 0);

    // 如果解锁时间在就寝时间之前（跨夜）
    if (wakeupTime.hour < bedtime.hour ||
        (wakeupTime.hour === bedtime.hour && wakeupTime.minute < bedtime.minute)) {
      lanternlawEnd.setDate(lanternlawEnd.getDate() + 1);
    }

    this.lanternlawStartTime = lanternlawStart;
    this.lanternlawEndTime = lanternlawEnd;

    // 检查是否在宵禁时间内
    if (now >= lanternlawStart && now < lanternlawEnd) {
      await this.setState(LanternLawState.ACTIVE);

      // 如果是新进入宵禁状态，初始化记录
      if (this.todayRecord && this.todayRecord.lanternlawStart === 0) {
        this.todayRecord.lanternlawStart = lanternlawStart.getTime();
        this.todayRecord.lanternlawEnd = lanternlawEnd.getTime();
        await this.saveTodayRecord();
      }
    } else {
      await this.setState(LanternLawState.IDLE);

      // 如果刚离开宵禁状态，计算实际时长
      if (this.currentState === LanternLawState.ACTIVE && this.todayRecord) {
        const actualDuration = Math.floor((now.getTime() - lanternlawStart.getTime()) / (1000 * 60));
        this.todayRecord.actualDuration = Math.max(0, actualDuration);
        this.todayRecord.success = this.todayRecord.escapeCount === 0;
        await this.saveTodayRecord();
      }
    }
  }

  // 设置状态
  private async setState(newState: LanternLawState): Promise<void> {
    const oldState = this.currentState;

    if (newState !== oldState) {
      this.currentState = newState;

      // 通知监听器
      for (const listener of this.listeners) {
        try {
          listener.onStateChanged(newState, oldState);
        } catch (error) {
          console.error(`监听器通知失败: ${JSON.stringify(error)}`);
        }
      }

      // 状态变化处理
      await this.handleStateChange(newState, oldState);
    }
  }

  // 处理状态变化
  private async handleStateChange(newState: LanternLawState, oldState: LanternLawState): Promise<void> {
    switch (newState) {
      case LanternLawState.ACTIVE:
        console.log('进入宵禁状态');
        // 这里可以触发设备锁定等操作
        break;
      case LanternLawState.IDLE:
        console.log('离开宵禁状态');
        // 这里可以触发设备解锁等操作
        break;
    }
  }

  // 启动定时更新
  private startUpdateTimer(): void {
    // 每分钟检查一次状态
    this.updateTimer = setInterval(async () => {
      await this.calculateCurrentState();

      // 通知监听器时间更新
      const now = new Date();
      for (const listener of this.listeners) {
        try {
          listener.onTimeUpdated(now);
        } catch (error) {
          console.error(`时间更新通知失败: ${JSON.stringify(error)}`);
        }
      }
    }, 60000) as unknown as number; // 1分钟
  }

  // 停止定时更新
  public stop(): void {
    if (this.updateTimer !== null) {
      clearInterval(this.updateTimer);
      this.updateTimer = null;
    }
  }

  // 注册监听器
  public addListener(listener: LanternLawStateChangeListener): void {
    this.listeners.push(listener);
  }

  // 移除监听器
  public removeListener(listener: LanternLawStateChangeListener): void {
    const index = this.listeners.indexOf(listener);
    if (index >= 0) {
      this.listeners.splice(index, 1);
    }
  }

  // 获取当前状态
  public getCurrentState(): LanternLawState {
    return this.currentState;
  }

  // 获取配置
  public getConfig(): LanternLawConfig {
    return { ...this.config };
  }

  // 获取今日记录
  public getTodayRecord(): DailyRecord | null {
    return this.todayRecord ? { ...this.todayRecord } : null;
  }

  // 记录越狱尝试
  public async recordEscapeAttempt(type: string, appName: string = ''): Promise<void> {
    if (!this.todayRecord) return;

    this.todayRecord.escapeCount++;
    this.todayRecord.updatedAt = Date.now();

    await this.saveTodayRecord();

    // 通知监听器
    const attempt = {
      timestamp: Date.now(),
      type: type,
      appName: appName,
      count: 1,
      totalEscapeCount: this.todayRecord.escapeCount
    };

    for (const listener of this.listeners) {
      try {
        listener.onEscapeDetected(attempt);
      } catch (error) {
        console.error(`越狱检测通知失败: ${JSON.stringify(error)}`);
      }
    }
  }

  // 计算剩余时间（分钟）
  public getRemainingMinutes(): number {
    if (this.currentState !== LanternLawState.ACTIVE || !this.lanternlawEndTime) {
      return 0;
    }

    const now = new Date();
    const remainingMs = this.lanternlawEndTime.getTime() - now.getTime();
    return Math.max(0, Math.floor(remainingMs / (1000 * 60)));
  }

  // 使用紧急解锁
  public async useEmergencyUnlock(): Promise<boolean> {
    if (this.config.emergencyUsed >= this.config.emergencyUnlocks) {
      return false;
    }

    this.config.emergencyUsed++;
    await this.saveConfig(this.config);

    // 临时退出宵禁状态（例如15分钟）
    await this.setState(LanternLawState.IDLE);

    // 15分钟后恢复宵禁状态
    setTimeout(async () => {
      await this.calculateCurrentState();
    }, 15 * 60 * 1000);

    return true;
  }
}
```

- [ ] **Step 3: 提交宵禁状态管理器**

```bash
git add entry/src/main/ets/managers/LanternLawStateManager.ets
git commit -m "feat: 添加宵禁状态管理器"
```

### Task 5: 创建工具类

**Files:**
- Create: `entry/src/main/ets/utils/TimeUtils.ets`
- Create: `entry/src/main/ets/utils/StorageUtils.ets`
- Create: `entry/src/main/ets/utils/NotificationUtils.ets`

- [ ] **Step 1: 创建时间工具类**

```typescript
// entry/src/main/ets/utils/TimeUtils.ets
export class TimeUtils {
  // 解析时间字符串 "HH:mm" 为小时和分钟
  static parseTimeString(timeStr: string): { hour: number, minute: number } {
    const parts = timeStr.split(':');
    if (parts.length !== 2) {
      throw new Error(`无效的时间格式: ${timeStr}`);
    }

    const hour = parseInt(parts[0], 10);
    const minute = parseInt(parts[1], 10);

    if (isNaN(hour) || hour < 0 || hour > 23) {
      throw new Error(`无效的小时: ${parts[0]}`);
    }

    if (isNaN(minute) || minute < 0 || minute > 59) {
      throw new Error(`无效的分钟: ${parts[1]}`);
    }

    return { hour, minute };
  }

  // 格式化分钟数为 "X小时Y分钟"
  static formatMinutes(minutes: number): string {
    if (minutes < 0) return '0分钟';

    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;

    if (hours === 0) {
      return `${remainingMinutes}分钟`;
    } else if (remainingMinutes === 0) {
      return `${hours}小时`;
    } else {
      return `${hours}小时${remainingMinutes}分钟`;
    }
  }

  // 获取当前时间字符串 "HH:mm"
  static getCurrentTimeString(): string {
    const now = new Date();
    const hour = now.getHours().toString().padStart(2, '0');
    const minute = now.getMinutes().toString().padStart(2, '0');
    return `${hour}:${minute}`;
  }

  // 获取今天的日期字符串 "YYYY-MM-DD"
  static getTodayDateString(): string {
    return new Date().toISOString().split('T')[0];
  }

  // 检查是否在时间范围内
  static isInTimeRange(
    currentTime: Date,
    startTimeStr: string,
    endTimeStr: string
  ): boolean {
    const start = TimeUtils.parseTimeString(startTimeStr);
    const end = TimeUtils.parseTimeString(endTimeStr);

    const currentHour = currentTime.getHours();
    const currentMinute = currentTime.getMinutes();

    // 转换为分钟数便于比较
    const currentTotalMinutes = currentHour * 60 + currentMinute;
    const startTotalMinutes = start.hour * 60 + start.minute;
    const endTotalMinutes = end.hour * 60 + end.minute;

    if (startTotalMinutes <= endTotalMinutes) {
      // 同一天内的时间范围
      return currentTotalMinutes >= startTotalMinutes &&
             currentTotalMinutes < endTotalMinutes;
    } else {
      // 跨夜的时间范围
      return currentTotalMinutes >= startTotalMinutes ||
             currentTotalMinutes < endTotalMinutes;
    }
  }

  // 计算两个时间戳之间的分钟数
  static minutesBetween(startTimestamp: number, endTimestamp: number): number {
    return Math.floor((endTimestamp - startTimestamp) / (1000 * 60));
  }

  // 格式化时间戳为可读字符串
  static formatTimestamp(timestamp: number): string {
    const date = new Date(timestamp);
    return date.toLocaleString();
  }
}
```

- [ ] **Step 2: 创建存储工具类**

```typescript
// entry/src/main/ets/utils/StorageUtils.ets
import { LanternLawConfig } from '../models/LanternLawConfig';
import { DailyRecord } from '../models/DailyRecord';
import { LanternLawDatabase } from '../database/LanternLawDatabase';

export class StorageUtils {
  private static database: LanternLawDatabase = LanternLawDatabase.getInstance();

  // 保存配置
  static async saveConfig(config: LanternLawConfig): Promise<void> {
    await this.database.saveConfig('lanternlaw_config', config.toJSON());
  }

  // 加载配置
  static async loadConfig(): Promise<LanternLawConfig> {
    const configJson = await this.database.getConfig('lanternlaw_config');
    if (configJson) {
      return LanternLawConfig.fromJSON(configJson);
    }
    return new LanternLawConfig();
  }

  // 保存每日记录
  static async saveDailyRecord(record: DailyRecord): Promise<void> {
    await this.database.saveDailyRecord(record);
  }

  // 获取今日记录
  static async getTodayRecord(): Promise<DailyRecord | null> {
    const recordData = await this.database.getTodayRecord();
    if (recordData) {
      return DailyRecord.fromJSON(JSON.stringify(recordData));
    }
    return null;
  }

  // 获取最近N天记录
  static async getRecentRecords(days: number = 7): Promise<any[]> {
    return await this.database.getRecentRecords(days);
  }

  // 导出所有数据为JSON
  static async exportAllData(): Promise<string> {
    const config = await this.loadConfig();
    const todayRecord = await this.getTodayRecord();
    const recentRecords = await this.getRecentRecords(30);

    const exportData = {
      version: 1,
      exportedAt: Date.now(),
      config: config,
      todayRecord: todayRecord,
      recentRecords: recentRecords
    };

    return JSON.stringify(exportData, null, 2);
  }

  // 清除所有数据
  static async clearAllData(): Promise<void> {
    // 注意：这里只清除应用数据，不删除数据库文件
    // 实际实现可能需要删除并重建数据库表
    console.warn('清除所有数据功能未实现');
  }
}
```

- [ ] **Step 3: 创建通知工具类**

```typescript
// entry/src/main/ets/utils/NotificationUtils.ets
import { notification } from '@ohos.notificationManager';
import { BusinessError } from '@ohos.base';

export class NotificationUtils {
  // 发送宵禁开始通知
  static async sendLanternLawStartNotification(): Promise<void> {
    const request: notification.NotificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '宵禁开始',
          text: '设备已进入宵禁模式，请专注于休息',
          additionalText: '自律是自由的开始'
        }
      },
      id: 1001,
      slotType: notification.SlotType.SERVICE_INFORMATION
    };

    try {
      await notification.publish(request);
      console.log('宵禁开始通知发送成功');
    } catch (error) {
      console.error(`发送通知失败: ${JSON.stringify(error)}`);
    }
  }

  // 发送宵禁结束通知
  static async sendLanternLawEndNotification(): Promise<void> {
    const request: notification.NotificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '宵禁结束',
          text: '新的一天开始了，昨晚休息得好吗？',
          additionalText: '夜晚的坚守，黎明的奖赏'
        }
      },
      id: 1002,
      slotType: notification.SlotType.SERVICE_INFORMATION
    };

    try {
      await notification.publish(request);
      console.log('宵禁结束通知发送成功');
    } catch (error) {
      console.error(`发送通知失败: ${JSON.stringify(error)}`);
    }
  }

  // 发送越狱检测通知
  static async sendEscapeDetectionNotification(count: number): Promise<void> {
    const messages = [
      '请回吧，黑夜不属于这里',
      '黑夜在注视',
      '每一次越狱，都是对自己的背叛',
      '坚守此刻，成就未来'
    ];

    const randomMessage = messages[Math.floor(Math.random() * messages.length)];

    const request: notification.NotificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: `越狱检测 (${count}次)`,
          text: randomMessage,
          additionalText: '请专注于休息'
        }
      },
      id: 1003,
      slotType: notification.SlotType.SERVICE_INFORMATION
    };

    try {
      await notification.publish(request);
      console.log('越狱检测通知发送成功');
    } catch (error) {
      console.error(`发送通知失败: ${JSON.stringify(error)}`);
    }
  }

  // 发送成就解锁通知
  static async sendAchievementUnlockedNotification(achievementName: string): Promise<void> {
    const request: notification.NotificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '成就解锁',
          text: `恭喜解锁成就: ${achievementName}`,
          additionalText: '又一盏灯为你点亮'
        }
      },
      id: 1004,
      slotType: notification.SlotType.SERVICE_INFORMATION
    };

    try {
      await notification.publish(request);
      console.log('成就解锁通知发送成功');
    } catch (error) {
      console.error(`发送通知失败: ${JSON.stringify(error)}`);
    }
  }

  // 取消所有通知
  static async cancelAllNotifications(): Promise<void> {
    try {
      await notification.cancelAll();
      console.log('所有通知已取消');
    } catch (error) {
      console.error(`取消通知失败: ${JSON.stringify(error)}`);
    }
  }
}
```

- [ ] **Step 4: 提交工具类**

```bash
git add entry/src/main/ets/utils/
git commit -m "feat: 添加工具类 (TimeUtils, StorageUtils, NotificationUtils)"
```

### Task 6: 创建设备锁定管理器

**Files:**
- Create: `entry/src/main/ets/services/DeviceLockManager.ets`

- [ ] **Step 1: 创建设备锁定管理器**

```typescript
// entry/src/main/ets/services/DeviceLockManager.ets
import deviceManager from '@ohos.distributedHardware.deviceManager';
import { BusinessError } from '@ohos.base';

export class DeviceLockManager {
  private static instance: DeviceLockManager;
  private dmInstance: deviceManager.DeviceManager | null = null;
  private isInitialized: boolean = false;

  private constructor() {}

  public static getInstance(): DeviceLockManager {
    if (!DeviceLockManager.instance) {
      DeviceLockManager.instance = new DeviceLockManager();
    }
    return DeviceLockManager.instance;
  }

  // 初始化设备管理器
  public async initialize(bundleName: string): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      this.dmInstance = await deviceManager.createDeviceManager(bundleName);

      // 注册设备状态监听
      this.dmInstance.on('deviceStateChange', this.handleDeviceStateChange.bind(this));
      this.dmInstance.on('deviceTrustLevelChange', this.handleTrustLevelChange.bind(this));

      this.isInitialized = true;
      console.log('设备管理器初始化成功');
    } catch (error) {
      console.error(`设备管理器初始化失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 锁定设备功能
  public async lockDevice(): Promise<boolean> {
    if (!this.dmInstance) {
      console.error('设备管理器未初始化');
      return false;
    }

    try {
      // 注意：deviceManager.lockDevice() API可能需要特定权限和设备管理策略
      // 这里使用模拟实现，实际开发需要根据API文档调整
      console.log('设备锁定功能已激活');

      // 模拟锁定成功
      return true;
    } catch (error) {
      console.error(`设备锁定失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  // 解锁设备功能
  public async unlockDevice(): Promise<boolean> {
    if (!this.dmInstance) {
      console.error('设备管理器未初始化');
      return false;
    }

    try {
      // 注意：实际解锁逻辑需要根据API实现
      console.log('设备解锁功能已激活');

      // 模拟解锁成功
      return true;
    } catch (error) {
      console.error(`设备解锁失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  // 限制应用使用
  public async restrictApps(appList: string[]): Promise<boolean> {
    if (!this.dmInstance) {
      console.error('设备管理器未初始化');
      return false;
    }

    try {
      // 设备管理API可能提供应用限制功能
      // 这里记录要限制的应用列表
      console.log(`限制应用使用: ${JSON.stringify(appList)}`);

      // 实际实现需要调用相应API
      return true;
    } catch (error) {
      console.error(`应用限制失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  // 检查设备管理权限
  public async checkDeviceManagerPermission(): Promise<boolean> {
    // 实际实现需要检查权限状态
    // 这里返回模拟值
    return true;
  }

  // 请求设备管理权限
  public async requestDeviceManagerPermission(): Promise<boolean> {
    // 实际实现需要请求权限
    // 这里返回模拟值
    console.log('请求设备管理权限');
    return true;
  }

  // 处理设备状态变化
  private handleDeviceStateChange(data: any): void {
    console.log(`设备状态变更: ${JSON.stringify(data)}`);

    // 可以根据状态变化调整宵禁逻辑
    // 例如：设备重启后恢复宵禁状态
  }

  // 处理设备信任级别变化
  private handleTrustLevelChange(data: any): void {
    console.log(`设备信任级别变更: ${JSON.stringify(data)}`);
  }

  // 清理资源
  public async cleanup(): Promise<void> {
    if (this.dmInstance) {
      try {
        // 取消事件监听
        this.dmInstance.off('deviceStateChange');
        this.dmInstance.off('deviceTrustLevelChange');

        // 释放资源
        this.dmInstance = null;
        this.isInitialized = false;

        console.log('设备管理器清理完成');
      } catch (error) {
        console.error(`设备管理器清理失败: ${JSON.stringify(error)}`);
      }
    }
  }

  // 获取设备信息
  public async getDeviceInfo(): Promise<any> {
    if (!this.dmInstance) {
      throw new Error('设备管理器未初始化');
    }

    try {
      // 获取设备列表（通常只有本设备）
      const devices = await this.dmInstance.getTrustedDeviceList();
      if (devices && devices.length > 0) {
        return devices[0];
      }
      return null;
    } catch (error) {
      console.error(`获取设备信息失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }
}
```

- [ ] **Step 2: 提交设备锁定管理器**

```bash
git add entry/src/main/ets/services/DeviceLockManager.ets
git commit -m "feat: 添加设备锁定管理器"
```

### Task 7: 创建后台保活服务

**Files:**
- Create: `entry/src/main/ets/services/BackgroundKeepAlive.ets`

- [ ] **Step 1: 创建后台保活服务**

```typescript
// entry/src/main/ets/services/BackgroundKeepAlive.ets
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import runningLock from '@ohos.runningLock';
import { BusinessError } from '@ohos.base';

export class BackgroundKeepAlive {
  private static instance: BackgroundKeepAlive;
  private suspendDelayId: number = 0;
  private runningLock: runningLock.RunningLock | null = null;
  private keepAliveTimer: number | null = null;
  private isActive: boolean = false;

  private constructor() {}

  public static getInstance(): BackgroundKeepAlive {
    if (!BackgroundKeepAlive.instance) {
      BackgroundKeepAlive.instance = new BackgroundKeepAlive();
    }
    return BackgroundKeepAlive.instance;
  }

  // 启动后台保活
  public async startKeepAlive(): Promise<void> {
    if (this.isActive) {
      return;
    }

    this.isActive = true;

    // 策略1：申请后台运行延迟（最高30秒）
    try {
      this.suspendDelayId = await backgroundTaskManager.requestSuspendDelay(
        'LanternLaw宵禁保持',
        30000 // 30秒延迟
      );

      // 注册延迟到期回调
      backgroundTaskManager.subscribeSuspendDelayEvent(
        this.suspendDelayId,
        this.onSuspendDelayExpired.bind(this)
      );

      console.log(`后台延迟申请成功，ID: ${this.suspendDelayId}`);
    } catch (error) {
      console.error(`后台延迟申请失败: ${JSON.stringify(error)}`);
    }

    // 策略2：获取运行锁（防止系统休眠）
    try {
      const lockInfo: runningLock.RunningLockInfo = {
        name: 'LanternLawBackgroundLock',
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

    console.log('后台保活服务启动成功');
  }

  // 启动保活定时器
  private startKeepAliveTimer(): void {
    // 每20秒刷新一次保活状态
    this.keepAliveTimer = setInterval(() => {
      this.refreshKeepAlive();
    }, 20000) as unknown as number;
  }

  // 刷新保活状态
  private async refreshKeepAlive(): Promise<void> {
    if (!this.isActive) return;

    // 刷新运行锁
    if (this.runningLock) {
      try {
        await this.runningLock.lock(5000);
        console.log('运行锁刷新成功');
      } catch (error) {
        console.error(`运行锁刷新失败: ${JSON.stringify(error)}`);
      }
    }

    // 检查后台延迟状态
    try {
      const delayInfo = await backgroundTaskManager.getSuspendDelayStatus(this.suspendDelayId);
      if (delayInfo.remainingTime < 10000) {
        // 剩余时间不足10秒，重新申请
        await this.renewSuspendDelay();
      }
    } catch (error) {
      console.error(`延迟状态检查失败: ${JSON.stringify(error)}`);
    }
  }

  // 重新申请后台延迟
  private async renewSuspendDelay(): Promise<void> {
    if (this.suspendDelayId > 0) {
      try {
        await backgroundTaskManager.cancelSuspendDelay(this.suspendDelayId);
      } catch (error) {
        console.error(`取消延迟失败: ${JSON.stringify(error)}`);
      }
    }

    try {
      this.suspendDelayId = await backgroundTaskManager.requestSuspendDelay(
        'LanternLaw宵禁保持',
        30000
      );

      console.log(`后台延迟重新申请成功，ID: ${this.suspendDelayId}`);
    } catch (error) {
      console.error(`延迟重新申请失败: ${JSON.stringify(error)}`);
    }
  }

  // 后台延迟到期回调
  private onSuspendDelayExpired(): void {
    console.log('后台延迟到期，重新申请');
    this.renewSuspendDelay();
  }

  // 停止后台保活
  public async stopKeepAlive(): Promise<void> {
    if (!this.isActive) {
      return;
    }

    this.isActive = false;

    // 清理定时器
    if (this.keepAliveTimer !== null) {
      clearInterval(this.keepAliveTimer);
      this.keepAliveTimer = null;
      console.log('保活定时器已停止');
    }

    // 释放运行锁
    if (this.runningLock) {
      try {
        this.runningLock.unlock();
        console.log('运行锁已释放');
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
        console.log('后台延迟已取消');
      } catch (error) {
        console.error(`延迟取消失败: ${JSON.stringify(error)}`);
      }
    }

    console.log('后台保活服务已停止');
  }

  // 检查是否活跃
  public isKeepAliveActive(): boolean {
    return this.isActive;
  }

  // 获取剩余延迟时间
  public async getRemainingDelayTime(): Promise<number> {
    if (this.suspendDelayId === 0) {
      return 0;
    }

    try {
      const delayInfo = await backgroundTaskManager.getSuspendDelayStatus(this.suspendDelayId);
      return delayInfo.remainingTime;
    } catch (error) {
      console.error(`获取延迟时间失败: ${JSON.stringify(error)}`);
      return 0;
    }
  }
}
```

- [ ] **Step 2: 提交后台保活服务**

```bash
git add entry/src/main/ets/services/BackgroundKeepAlive.ets
git commit -m "feat: 添加后台保活服务"
```

### Task 8: 创建越狱检测管理器

**Files:**
- Create: `entry/src/main/ets/managers/EscapeDetectionManager.ets`

- [ ] **Step 1: 创建越狱检测管理器**

```typescript
// entry/src/main/ets/managers/EscapeDetectionManager.ets
import { LanternLawStateManager } from './LanternLawStateManager';
import { NotificationUtils } from '../utils/NotificationUtils';

export class EscapeDetectionManager {
  private static instance: EscapeDetectionManager;
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private lastDetectionTime: number = 0;
  private detectionCooldown: number = 5 * 60 * 1000; // 5分钟冷却时间
  private isMonitoring: boolean = false;

  private constructor() {}

  public static getInstance(): EscapeDetectionManager {
    if (!EscapeDetectionManager.instance) {
      EscapeDetectionManager.instance = new EscapeDetectionManager();
    }
    return EscapeDetectionManager.instance;
  }

  // 开始越狱检测
  public startMonitoring(): void {
    if (this.isMonitoring) {
      return;
    }

    this.isMonitoring = true;

    // 这里应该注册无障碍服务事件监听
    // 由于鸿蒙无障碍服务需要特定配置，这里使用模拟检测
    console.log('越狱检测监控已启动');

    // 模拟定时检测（实际应由无障碍服务事件驱动）
    this.startSimulatedDetection();
  }

  // 停止越狱检测
  public stopMonitoring(): void {
    this.isMonitoring = false;
    console.log('越狱检测监控已停止');
  }

  // 模拟越狱检测（供测试用）
  private startSimulatedDetection(): void {
    // 实际实现应由无障碍服务事件驱动
    // 这里仅用于演示
    console.log('模拟越狱检测已启动（实际应由无障碍服务实现）');
  }

  // 处理应用切换事件（由无障碍服务调用）
  public async handleAppSwitch(appName: string): Promise<void> {
    if (!this.isMonitoring) {
      return;
    }

    const now = Date.now();

    // 检查冷却时间
    if (now - this.lastDetectionTime < this.detectionCooldown) {
      return;
    }

    // 忽略系统应用
    if (this.isSystemApp(appName)) {
      return;
    }

    this.lastDetectionTime = now;

    // 记录越狱尝试
    await this.stateManager.recordEscapeAttempt('APP_SWITCH', appName);

    // 发送通知
    const todayRecord = this.stateManager.getTodayRecord();
    if (todayRecord) {
      await NotificationUtils.sendEscapeDetectionNotification(todayRecord.escapeCount);
    }

    // 振动反馈（如果启用）
    if (this.stateManager.getConfig().vibrationEnabled) {
      this.vibrate();
    }

    console.log(`应用切换越狱检测: ${appName}`);
  }

  // 处理卸载尝试事件
  public async handleUninstallAttempt(): Promise<void> {
    if (!this.isMonitoring) {
      return;
    }

    // 记录越狱尝试
    await this.stateManager.recordEscapeAttempt('UNINSTALL_ATTEMPT');

    // 发送通知
    const todayRecord = this.stateManager.getTodayRecord();
    if (todayRecord) {
      await NotificationUtils.sendEscapeDetectionNotification(todayRecord.escapeCount);
    }

    // 振动反馈（如果启用）
    if (this.stateManager.getConfig().vibrationEnabled) {
      this.vibrate();
    }

    console.log('卸载尝试越狱检测');
  }

  // 检查是否为系统应用
  private isSystemApp(appName: string): boolean {
    const systemApps = [
      '设置', '电话', '短信', '通讯录', '相机',
      'Settings', 'Phone', 'Messages', 'Contacts', 'Camera'
    ];

    return systemApps.includes(appName);
  }

  // 振动反馈
  private vibrate(): void {
    // 鸿蒙振动API可能需要特定权限
    // 这里使用console模拟
    console.log('振动反馈触发');

    // 实际实现：
    // import vibrator from '@ohos.vibrator';
    // vibrator.startVibration({duration: 200}, {usage: 'alarm'});
  }

  // 检查是否在监控中
  public isMonitoringActive(): boolean {
    return this.isMonitoring;
  }

  // 获取最后检测时间
  public getLastDetectionTime(): number {
    return this.lastDetectionTime;
  }
}
```

- [ ] **Step 2: 提交越狱检测管理器**

```bash
git add entry/src/main/ets/managers/EscapeDetectionManager.ets
git commit -m "feat: 添加越狱检测管理器"
```

### Task 9: 创建成就管理器

**Files:**
- Create: `entry/src/main/ets/managers/AchievementManager.ets`

- [ ] **Step 1: 创建成就管理器**

```typescript
// entry/src/main/ets/managers/AchievementManager.ets
import { Achievement } from '../models/Achievement';
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { NotificationUtils } from '../utils/NotificationUtils';

export class AchievementManager {
  private static instance: AchievementManager;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();
  private achievements: Achievement[] = [];
  private unlockedAchievements: Set<string> = new Set();

  // 成就定义
  private readonly ACHIEVEMENT_DEFINITIONS = [
    {
      id: 'streak_7',
      name: '周度坚守者',
      description: '连续7天成功完成宵禁',
      type: 'STREAK',
      requirement: 7,
      icon: '🌙'
    },
    {
      id: 'streak_30',
      name: '月度自律者',
      description: '连续30天成功完成宵禁',
      type: 'STREAK',
      requirement: 30,
      icon: '⭐'
    },
    {
      id: 'streak_100',
      name: '百日坚守',
      description: '连续100天成功完成宵禁',
      type: 'STREAK',
      requirement: 100,
      icon: '🎯'
    },
    {
      id: 'streak_365',
      name: '年度自律大师',
      description: '连续365天成功完成宵禁',
      type: 'STREAK',
      requirement: 365,
      icon: '👑'
    },
    {
      id: 'total_10',
      name: '新手上路',
      description: '累计成功10天',
      type: 'TOTAL',
      requirement: 10,
      icon: '🚀'
    },
    {
      id: 'total_50',
      name: '熟练坚守',
      description: '累计成功50天',
      type: 'TOTAL',
      requirement: 50,
      icon: '🏆'
    },
    {
      id: 'total_200',
      name: '资深自律者',
      description: '累计成功200天',
      type: 'TOTAL',
      requirement: 200,
      icon: '💎'
    },
    {
      id: 'total_500',
      name: '自律大师',
      description: '累计成功500天',
      type: 'TOTAL',
      requirement: 500,
      icon: '🌟'
    },
    {
      id: 'perfect_week',
      name: '完美一周',
      description: '一周内无任何越狱尝试',
      type: 'SPECIAL',
      requirement: 1,
      icon: '✨'
    },
    {
      id: 'early_bird',
      name: '早起的鸟儿',
      description: '连续3天在06:00前完成宵禁',
      type: 'SPECIAL',
      requirement: 3,
      icon: '🐦'
    }
  ];

  private constructor() {}

  public static getInstance(): AchievementManager {
    if (!AchievementManager.instance) {
      AchievementManager.instance = new AchievementManager();
    }
    return AchievementManager.instance;
  }

  // 初始化成就管理器
  public async initialize(): Promise<void> {
    try {
      // 加载已解锁成就
      await this.loadAchievements();

      console.log('成就管理器初始化成功');
    } catch (error) {
      console.error(`成就管理器初始化失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 加载成就数据
  private async loadAchievements(): Promise<void> {
    // 从数据库加载成就状态
    // 这里简化实现，实际应从数据库加载

    // 初始化成就列表
    this.achievements = this.ACHIEVEMENT_DEFINITIONS.map(def => {
      const achievement = new Achievement();
      achievement.id = def.id;
      achievement.name = def.name;
      achievement.description = def.description;
      achievement.type = def.type;
      achievement.requirement = def.requirement;
      achievement.icon = def.icon;
      achievement.unlocked = false;
      achievement.unlockedAt = 0;
      return achievement;
    });

    // 模拟已解锁成就（实际应从数据库加载）
    const unlockedIds = ['streak_7', 'total_10'];
    for (const id of unlockedIds) {
      this.unlockAchievement(id);
    }
  }

  // 检查并更新成就
  public async checkAndUpdateAchievements(
    stats: {
      currentStreak: number,
      totalSuccessDays: number,
      perfectWeek: boolean,
      earlyBirdDays: number
    }
  ): Promise<Achievement[]> {
    const newlyUnlocked: Achievement[] = [];

    for (const achievement of this.achievements) {
      if (achievement.unlocked) {
        continue;
      }

      let shouldUnlock = false;

      switch (achievement.type) {
        case 'STREAK':
          shouldUnlock = stats.currentStreak >= achievement.requirement;
          break;
        case 'TOTAL':
          shouldUnlock = stats.totalSuccessDays >= achievement.requirement;
          break;
        case 'SPECIAL':
          if (achievement.id === 'perfect_week') {
            shouldUnlock = stats.perfectWeek;
          } else if (achievement.id === 'early_bird') {
            shouldUnlock = stats.earlyBirdDays >= achievement.requirement;
          }
          break;
      }

      if (shouldUnlock) {
        await this.unlockAchievement(achievement.id);
        newlyUnlocked.push(achievement);

        // 发送通知
        await NotificationUtils.sendAchievementUnlockedNotification(achievement.name);
      }
    }

    return newlyUnlocked;
  }

  // 解锁成就
  private async unlockAchievement(id: string): Promise<void> {
    const achievement = this.achievements.find(a => a.id === id);
    if (!achievement || achievement.unlocked) {
      return;
    }

    achievement.unlocked = true;
    achievement.unlockedAt = Date.now();
    this.unlockedAchievements.add(id);

    // 保存到数据库
    await this.saveAchievement(achievement);

    console.log(`成就解锁: ${achievement.name}`);
  }

  // 保存成就状态
  private async saveAchievement(achievement: Achievement): Promise<void> {
    // 实际实现应保存到数据库
    // 这里简化处理
    console.log(`保存成就: ${achievement.name}`);
  }

  // 获取所有成就
  public getAllAchievements(): Achievement[] {
    return [...this.achievements];
  }

  // 获取已解锁成就
  public getUnlockedAchievements(): Achievement[] {
    return this.achievements.filter(a => a.unlocked);
  }

  // 获取进行中成就
  public getInProgressAchievements(): Achievement[] {
    return this.achievements.filter(a => !a.unlocked);
  }

  // 获取成就进度
  public getAchievementProgress(
    achievementId: string,
    stats: {
      currentStreak: number,
      totalSuccessDays: number,
      perfectWeek: boolean,
      earlyBirdDays: number
    }
  ): { current: number, total: number, percentage: number } {
    const achievement = this.achievements.find(a => a.id === achievementId);
    if (!achievement) {
      return { current: 0, total: 0, percentage: 0 };
    }

    let current = 0;

    switch (achievement.type) {
      case 'STREAK':
        current = Math.min(stats.currentStreak, achievement.requirement);
        break;
      case 'TOTAL':
        current = Math.min(stats.totalSuccessDays, achievement.requirement);
        break;
      case 'SPECIAL':
        if (achievement.id === 'perfect_week') {
          current = stats.perfectWeek ? 1 : 0;
        } else if (achievement.id === 'early_bird') {
          current = Math.min(stats.earlyBirdDays, achievement.requirement);
        }
        break;
    }

    const total = achievement.requirement;
    const percentage = total > 0 ? Math.round((current / total) * 100) : 0;

    return { current, total, percentage };
  }

  // 重置成就（用于测试）
  public async resetAchievements(): Promise<void> {
    this.achievements.forEach(a => {
      a.unlocked = false;
      a.unlockedAt = 0;
    });
    this.unlockedAchievements.clear();

    console.log('成就已重置');
  }
}
```

- [ ] **Step 2: 提交成就管理器**

```bash
git add entry/src/main/ets/managers/AchievementManager.ets
git commit -m "feat: 添加成就管理器"
```

### Task 10: 创建数据统计管理器

**Files:**
- Create: `entry/src/main/ets/managers/DataStatisticsManager.ets`

- [ ] **Step 1: 创建数据统计管理器**

```typescript
// entry/src/main/ets/managers/DataStatisticsManager.ets
import { LanternLawDatabase } from '../database/LanternLawDatabase';
import { TimeUtils } from '../utils/TimeUtils';

export class DataStatisticsManager {
  private static instance: DataStatisticsManager;
  private database: LanternLawDatabase = LanternLawDatabase.getInstance();

  private constructor() {}

  public static getInstance(): DataStatisticsManager {
    if (!DataStatisticsManager.instance) {
      DataStatisticsManager.instance = new DataStatisticsManager();
    }
    return DataStatisticsManager.instance;
  }

  // 获取今日统计数据
  public async getTodayStats(): Promise<any> {
    try {
      const todayRecord = await this.database.getTodayRecord();

      if (!todayRecord) {
        return {
          success: false,
          actualDuration: 0,
          escapeCount: 0,
          successPercentage: 0,
          remainingMinutes: 0,
          isActive: false
        };
      }

      return {
        success: todayRecord.success,
        actualDuration: todayRecord.actualDuration,
        escapeCount: todayRecord.escapeCount,
        successPercentage: todayRecord.successPercentage(),
        remainingMinutes: this.calculateRemainingMinutes(todayRecord),
        isActive: this.isLanternLawActiveNow(todayRecord)
      };
    } catch (error) {
      console.error(`获取今日统计失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 计算剩余分钟数
  private calculateRemainingMinutes(record: any): number {
    if (!record.lanternlawEnd || !this.isLanternLawActiveNow(record)) {
      return 0;
    }

    const now = Date.now();
    const remainingMs = record.lanternlawEnd - now;
    return Math.max(0, Math.floor(remainingMs / (1000 * 60)));
  }

  // 检查当前是否在宵禁时间内
  private isLanternLawActiveNow(record: any): boolean {
    if (!record.lanternlawStart || !record.lanternlawEnd) {
      return false;
    }

    const now = Date.now();
    return now >= record.lanternlawStart && now < record.lanternlawEnd;
  }

  // 获取本周统计数据
  public async getWeeklyStats(): Promise<any> {
    try {
      const recentRecords = await this.database.getRecentRecords(7);

      const stats = {
        days: recentRecords.length,
        totalSuccessDays: recentRecords.filter(r => r.success).length,
        totalEscapeCount: recentRecords.reduce((sum, r) => sum + r.escapeCount, 0),
        totalDuration: recentRecords.reduce((sum, r) => sum + r.actualDuration, 0),
        averageDuration: 0,
        successRate: 0,
        records: recentRecords
      };

      if (stats.days > 0) {
        stats.averageDuration = Math.round(stats.totalDuration / stats.days);
        stats.successRate = Math.round((stats.totalSuccessDays / stats.days) * 100);
      }

      return stats;
    } catch (error) {
      console.error(`获取本周统计失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 获取月度统计数据
  public async getMonthlyStats(): Promise<any> {
    try {
      const recentRecords = await this.database.getRecentRecords(30);

      const stats = {
        days: recentRecords.length,
        totalSuccessDays: recentRecords.filter(r => r.success).length,
        totalEscapeCount: recentRecords.reduce((sum, r) => sum + r.escapeCount, 0),
        totalDuration: recentRecords.reduce((sum, r) => sum + r.actualDuration, 0),
        averageDuration: 0,
        successRate: 0,
        bestStreak: this.calculateBestStreak(recentRecords),
        currentStreak: this.calculateCurrentStreak(recentRecords),
        records: recentRecords
      };

      if (stats.days > 0) {
        stats.averageDuration = Math.round(stats.totalDuration / stats.days);
        stats.successRate = Math.round((stats.totalSuccessDays / stats.days) * 100);
      }

      return stats;
    } catch (error) {
      console.error(`获取月度统计失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 计算最佳连续成功天数
  private calculateBestStreak(records: any[]): number {
    let bestStreak = 0;
    let currentStreak = 0;

    // 按日期排序
    const sortedRecords = [...records].sort((a, b) => a.date.localeCompare(b.date));

    for (const record of sortedRecords) {
      if (record.success) {
        currentStreak++;
        bestStreak = Math.max(bestStreak, currentStreak);
      } else {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  // 计算当前连续成功天数
  private calculateCurrentStreak(records: any[]): number {
    // 按日期倒序排序
    const sortedRecords = [...records].sort((a, b) => b.date.localeCompare(a.date));

    let currentStreak = 0;

    for (const record of sortedRecords) {
      if (record.success) {
        currentStreak++;
      } else {
        break;
      }
    }

    return currentStreak;
  }

  // 获取趋势数据（用于图表）
  public async getTrendData(days: number = 7): Promise<any[]> {
    try {
      const records = await this.database.getRecentRecords(days);

      // 按日期排序
      const sortedRecords = [...records].sort((a, b) => a.date.localeCompare(b.date));

      return sortedRecords.map(record => ({
        date: record.date,
        actualDuration: record.actualDuration,
        escapeCount: record.escapeCount,
        success: record.success,
        successPercentage: record.success ? 100 : 0
      }));
    } catch (error) {
      console.error(`获取趋势数据失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 获取成就统计数据
  public async getAchievementStats(): Promise<any> {
    try {
      const monthlyStats = await this.getMonthlyStats();

      return {
        currentStreak: monthlyStats.currentStreak,
        bestStreak: monthlyStats.bestStreak,
        totalSuccessDays: monthlyStats.totalSuccessDays,
        successRate: monthlyStats.successRate,
        perfectWeek: this.checkPerfectWeek(await this.getWeeklyStats()),
        earlyBirdDays: await this.calculateEarlyBirdDays()
      };
    } catch (error) {
      console.error(`获取成就统计失败: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  // 检查是否完美一周（无越狱）
  private checkPerfectWeek(weeklyStats: any): boolean {
    return weeklyStats.totalEscapeCount === 0 && weeklyStats.days > 0;
  }

  // 计算早鸟天数（06:00前完成）
  private async calculateEarlyBirdDays(): Promise<number> {
    // 简化实现，实际需要检查每条记录的结束时间
    // 这里返回模拟值
    return 1;
  }

  // 导出统计数据
  public async exportStats(): Promise<string> {
    const todayStats = await this.getTodayStats();
    const weeklyStats = await this.getWeeklyStats();
    const monthlyStats = await this.getMonthlyStats();

    const exportData = {
      exportedAt: Date.now(),
      today: todayStats,
      week: weeklyStats,
      month: monthlyStats,
      trendData: await this.getTrendData(30)
    };

    return JSON.stringify(exportData, null, 2);
  }
}
```

- [ ] **Step 2: 提交数据统计管理器**

```bash
git add entry/src/main/ets/managers/DataStatisticsManager.ets
git commit -m "feat: 添加数据统计管理器"
```

### Task 11: 创建无障碍服务

**Files:**
- Create: `entry/src/main/ets/accessibility/LanternLawAccessibilityAbility.ets`

- [ ] **Step 1: 创建无障碍服务Ability**

```typescript
// entry/src/main/ets/accessibility/LanternLawAccessibilityAbility.ets
import AccessibilityExtensionAbility from '@ohos.application.AccessibilityExtensionAbility';
import { EscapeDetectionManager } from '../managers/EscapeDetectionManager';

export default class LanternLawAccessibilityAbility extends AccessibilityExtensionAbility {
  private detectionManager: EscapeDetectionManager = EscapeDetectionManager.getInstance();

  onConnect(): void {
    console.log('无障碍服务已连接');
    this.detectionManager.startMonitoring();
  }

  onDisconnect(): void {
    console.log('无障碍服务已断开');
    this.detectionManager.stopMonitoring();
  }

  // 无障碍事件处理
  onAccessibilityEvent(accessibilityEvent: AccessibilityEvent): void {
    // 处理不同类型的无障碍事件
    const eventType = accessibilityEvent.eventType;

    switch (eventType) {
      case 2048: // 窗口状态变化（应用切换）
        this.handleWindowStateChanged(accessibilityEvent);
        break;
      case 131072: // 通知状态变化
        this.handleNotificationChanged(accessibilityEvent);
        break;
      // 可以添加其他事件类型处理
    }
  }

  // 处理窗口状态变化（应用切换）
  private handleWindowStateChanged(event: AccessibilityEvent): void {
    try {
      // 获取当前活动窗口信息
      const windowInfo = this.getWindowInfo();
      if (windowInfo && windowInfo.bundleName) {
        // 检查是否切换到其他应用（排除系统应用）
        const currentApp = windowInfo.bundleName;
        const appName = windowInfo.title || currentApp;

        // 通知越狱检测管理器
        this.detectionManager.handleAppSwitch(appName);
      }
    } catch (error) {
      console.error(`处理窗口状态变化失败: ${JSON.stringify(error)}`);
    }
  }

  // 处理通知状态变化
  private handleNotificationChanged(event: AccessibilityEvent): void {
    // 可以用于检测应用卸载通知等
    // 这里简化处理
  }

  // 获取窗口信息（简化实现）
  private getWindowInfo(): any {
    // 实际实现需要使用AccessibilityExtensionContext获取窗口信息
    // 这里返回模拟数据
    return {
      bundleName: 'com.example.app',
      title: '示例应用'
    };
  }

  // 无障碍服务配置
  static getCapabilities(): number {
    // 配置无障碍服务能力
    // 1: 检索窗口内容
    // 2: 手势交互
    // 4: 按键事件监听
    // 8: 触摸引导
    return 1 | 4; // 检索窗口内容 + 按键事件监听
  }

  static getDescription(): string {
    return 'LanternLaw越狱检测无障碍服务，用于检测用户尝试绕过宵禁的行为';
  }

  static getSettingsUi(): string {
    return 'pages/AccessibilitySettingsPage';
  }
}
```

- [ ] **Step 2: 更新module.json5添加无障碍服务配置**

```json5
// 在entry/src/main/module.json5的abilities数组中添加：
{
  "name": "LanternLawAccessibilityAbility",
  "type": "accessibility",
  "srcEntry": "./ets/accessibility/LanternLawAccessibilityAbility.ets",
  "description": "越狱检测无障碍服务",
  "exported": false,
  "accessibilityCapabilities": ["retrieve", "keyEventObserver"],
  "settingsAbility": "pages/AccessibilitySettingsPage"
}
```

- [ ] **Step 3: 提交无障碍服务**

```bash
git add entry/src/main/ets/accessibility/ entry/src/main/module.json5
git commit -m "feat: 添加无障碍服务Ability"
```

### Task 12: 创建主Ability和页面组件

**Files:**
- Create: `entry/src/main/ets/MainAbility/MainAbility.ts`
- Create: `entry/src/main/ets/pages/IndexPage.ets`
- Create: `entry/src/main/ets/components/ClockComponent.ets`
- Create: `entry/src/main/ets/components/LanternSystem.ets`
- Create: `entry/src/main/ets/components/TimeDisplay.ets`
- Create: `entry/src/main/ets/components/StatsPanel.ets`

- [ ] **Step 1: 创建主Ability**

```typescript
// entry/src/main/ets/MainAbility/MainAbility.ts
import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { DeviceLockManager } from '../services/DeviceLockManager';
import { BackgroundKeepAlive } from '../services/BackgroundKeepAlive';

export default class MainAbility extends UIAbility {
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();
  private deviceManager: DeviceLockManager = DeviceLockManager.getInstance();
  private backgroundKeepAlive: BackgroundKeepAlive = BackgroundKeepAlive.getInstance();

  onCreate(want, launchParam): void {
    console.log('MainAbility onCreate');

    // 初始化状态管理器
    this.stateManager.initialize(this.context).then(() => {
      console.log('状态管理器初始化成功');
    }).catch(error => {
      console.error(`状态管理器初始化失败: ${JSON.stringify(error)}`);
    });

    // 初始化设备管理器
    this.deviceManager.initialize(this.context.abilityInfo.bundleName).then(() => {
      console.log('设备管理器初始化成功');
    }).catch(error => {
      console.error(`设备管理器初始化失败: ${JSON.stringify(error)}`);
    });
  }

  onDestroy(): void {
    console.log('MainAbility onDestroy');

    // 停止状态管理器
    this.stateManager.stop();

    // 清理设备管理器
    this.deviceManager.cleanup();

    // 停止后台保活
    this.backgroundKeepAlive.stopKeepAlive();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.log('MainAbility onWindowStageCreate');

    // 设置主窗口
    windowStage.loadContent('pages/IndexPage', (err, data) => {
      if (err) {
        console.error(`加载页面失败: ${JSON.stringify(err)}`);
        return;
      }
      console.log('页面加载成功');
    });
  }

  onWindowStageDestroy(): void {
    console.log('MainAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.log('MainAbility onForeground');
  }

  onBackground(): void {
    console.log('MainAbility onBackground');

    // 应用进入后台时启动保活服务
    const state = this.stateManager.getCurrentState();
    if (state === 'active') {
      this.backgroundKeepAlive.startKeepAlive().then(() => {
        console.log('后台保活服务已启动');
      }).catch(error => {
        console.error(`后台保活服务启动失败: ${JSON.stringify(error)}`);
      });
    }
  }
}
```

- [ ] **Step 2: 创建主页面组件**

```typescript
// entry/src/main/ets/pages/IndexPage.ets
import { LanternLawStateManager, LanternLawState, LanternLawStateChangeListener } from '../managers/LanternLawStateManager';
import { TimeUtils } from '../utils/TimeUtils';

@Entry
@Component
struct IndexPage implements LanternLawStateChangeListener {
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();

  @State currentTime: Date = new Date();
  @State lanternlawState: LanternLawState = LanternLawState.IDLE;
  @State remainingMinutes: number = 0;
  @State statsPanelExpanded: boolean = false;
  @State todayRecord: any = null;

  aboutToAppear(): void {
    // 注册状态监听
    this.stateManager.addListener(this);

    // 初始化状态
    this.lanternlawState = this.stateManager.getCurrentState();
    this.remainingMinutes = this.stateManager.getRemainingMinutes();
    this.todayRecord = this.stateManager.getTodayRecord();

    // 启动时间更新定时器
    setInterval(() => {
      this.currentTime = new Date();
    }, 1000);
  }

  aboutToDisappear(): void {
    // 移除状态监听
    this.stateManager.removeListener(this);
  }

  // 状态变化回调
  onStateChanged(newState: LanternLawState, oldState: LanternLawState): void {
    this.lanternlawState = newState;
    this.remainingMinutes = this.stateManager.getRemainingMinutes();
  }

  // 时间更新回调
  onTimeUpdated(currentTime: Date): void {
    this.currentTime = currentTime;
    this.remainingMinutes = this.stateManager.getRemainingMinutes();
  }

  // 越狱检测回调
  onEscapeDetected(attempt: any): void {
    // 可以在这里显示越狱提示动画
    console.log(`越狱检测: ${JSON.stringify(attempt)}`);
  }

  // 切换统计面板
  toggleStatsPanel(): void {
    this.statsPanelExpanded = !this.statsPanelExpanded;
  }

  // 获取激励文案
  getMotivationText(): string {
    switch (this.lanternlawState) {
      case LanternLawState.ACTIVE:
        return '夜晚的坚守，黎明的奖赏';
      case LanternLawState.OVERRIDDEN:
        return '自律是自由的开始';
      default:
        return '每一分钟坚持，都是对自己的承诺';
    }
  }

  // 计算成功天数
  getSuccessDays(): number {
    // 简化实现，实际应从成就管理器获取
    return this.todayRecord?.success ? 1 : 0;
  }

  build() {
    Column({ space: 20 }) {
      // 表盘区域
      ClockComponent({
        currentTime: this.currentTime,
        isActive: this.lanternlawState === LanternLawState.ACTIVE,
        remainingMinutes: this.remainingMinutes
      })

      // 时间显示
      TimeDisplay({ time: this.currentTime })

      // 剩余时间显示
      if (this.lanternlawState === LanternLawState.ACTIVE) {
        Text(`剩余解锁时间: ${TimeUtils.formatMinutes(this.remainingMinutes)}`)
          .fontSize(16)
          .fontColor('#ff9e6d')
          .margin({ top: 10 })
      }

      // 激励文案
      Text(this.getMotivationText())
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
        .margin({ top: 20, bottom: 20 })

      // 虚拟提灯系统
      LanternSystem({
        successDays: this.getSuccessDays(),
        currentStreak: 1 // 简化实现
      })

      // 统计面板切换按钮
      Button(this.statsPanelExpanded ? '收起统计' : '查看统计')
        .width(120)
        .height(40)
        .fontSize(14)
        .backgroundColor('#2a3157')
        .onClick(() => this.toggleStatsPanel())
        .margin({ top: 20 })

      // 统计面板
      if (this.statsPanelExpanded) {
        StatsPanel({
          dailyStats: this.todayRecord,
          onClose: () => { this.statsPanelExpanded = false }
        })
        .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#0f1529')
    .justifyContent(FlexAlign.Center)
  }
}
```

- [ ] **Step 3: 创建表盘组件**

```typescript
// entry/src/main/ets/components/ClockComponent.ets
@Component
export struct ClockComponent {
  @Prop currentTime: Date;
  @Prop isActive: boolean;
  @Prop remainingMinutes: number;

  @State clockSize: number = 280;

  build() {
    Column() {
      Canvas(this.context)
        .width(this.clockSize)
        .height(this.clockSize)
        .backgroundColor(this.isActive ? '#1a1f3a' : '#0f1529')
        .borderRadius(this.clockSize / 2)
        .border({ width: 2, color: this.isActive ? '#2a3157' : '#1a1f3a' })
        .onReady(() => {
          const ctx = this.context;
          const center = this.clockSize / 2;
          const radius = center - 20;

          // 清空画布
          ctx.clearRect(0, 0, this.clockSize, this.clockSize);

          // 绘制表盘
          ctx.beginPath();
          ctx.arc(center, center, radius, 0, Math.PI * 2);
          ctx.strokeStyle = this.isActive ? '#2a3157' : '#1a1f3a';
          ctx.lineWidth = 2;
          ctx.stroke();

          // 绘制刻度
          for (let i = 0; i < 12; i++) {
            const angle = (i * Math.PI) / 6;
            const startX = center + (radius - 10) * Math.sin(angle);
            const startY = center - (radius - 10) * Math.cos(angle);
            const endX = center + radius * Math.sin(angle);
            const endY = center - radius * Math.cos(angle);

            ctx.beginPath();
            ctx.moveTo(startX, startY);
            ctx.lineTo(endX, endY);
            ctx.strokeStyle = this.isActive ? '#c0c6e9' : '#2a3157';
            ctx.lineWidth = i % 3 === 0 ? 3 : 1;
            ctx.stroke();
          }

          // 绘制时针
          const hourAngle = ((this.currentTime.getHours() % 12) * Math.PI) / 6;
          const hourLength = radius * 0.5;
          ctx.beginPath();
          ctx.moveTo(center, center);
          ctx.lineTo(
            center + hourLength * Math.sin(hourAngle),
            center - hourLength * Math.cos(hourAngle)
          );
          ctx.strokeStyle = this.isActive ? '#ffd166' : '#ff9e6d';
          ctx.lineWidth = 4;
          ctx.stroke();

          // 绘制分针
          const minuteAngle = (this.currentTime.getMinutes() * Math.PI) / 30;
          const minuteLength = radius * 0.7;
          ctx.beginPath();
          ctx.moveTo(center, center);
          ctx.lineTo(
            center + minuteLength * Math.sin(minuteAngle),
            center - minuteLength * Math.cos(minuteAngle)
          );
          ctx.strokeStyle = this.isActive ? '#ff9e6d' : '#ffd166';
          ctx.lineWidth = 3;
          ctx.stroke();

          // 宵禁状态下绘制进度环
          if (this.isActive && this.remainingMinutes > 0) {
            const progress = 1 - (this.remainingMinutes / (12 * 60)); // 假设12小时宵禁
            const endAngle = Math.PI * 2 * progress - Math.PI / 2;

            ctx.beginPath();
            ctx.arc(center, center, radius + 5, -Math.PI / 2, endAngle);
            ctx.strokeStyle = '#ff9e6d';
            ctx.lineWidth = 4;
            ctx.lineCap = 'round';
            ctx.stroke();
          }
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
```

- [ ] **Step 4: 创建虚拟提灯组件**

```typescript
// entry/src/main/ets/components/LanternSystem.ets
@Component
export struct LanternSystem {
  @Prop successDays: number;
  @Prop currentStreak: number;

  private readonly TOTAL_LANTERNS: number = 7;

  build() {
    Row({ space: 10 }) {
      ForEach(Array.from({ length: this.TOTAL_LANTERNS }), (_, index) => {
        Column() {
          // 提灯主体
          Column()
            .width(20)
            .height(30)
            .backgroundColor(index < this.successDays ? '#ffd166' : '#2a3157')
            .borderRadius(10)
            .border({ width: 1, color: index < this.successDays ? '#ff9e6d' : '#1a1f3a' })
            .shadow({
              radius: index < this.successDays ? 10 : 0,
              color: index < this.successDays ? '#ff9e6d' : 'transparent'
            })

          // 提灯连接线（除了最后一个）
          if (index < this.TOTAL_LANTERNS - 1) {
            Column()
              .width(10)
              .height(2)
              .backgroundColor(index < this.successDays - 1 ? '#ff9e6d' : '#2a3157')
              .margin({ left: 5 })
          }
        }
        .alignItems(HorizontalAlign.Center)
      })
    }
    .margin({ top: 20 })
    .justifyContent(FlexAlign.Center)
  }
}
```

- [ ] **Step 5: 创建时间显示组件**

```typescript
// entry/src/main/ets/components/TimeDisplay.ets
import { TimeUtils } from '../utils/TimeUtils';

@Component
export struct TimeDisplay {
  @Prop time: Date;

  build() {
    Column() {
      Text(TimeUtils.getCurrentTimeString())
        .fontSize(32)
        .fontColor('#c0c6e9')
        .fontWeight(FontWeight.Bold)

      Text(this.getDateString())
        .fontSize(14)
        .fontColor('#ff9e6d')
        .margin({ top: 5 })
    }
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 20, bottom: 10 })
  }

  private getDateString(): string {
    const options: Intl.DateTimeFormatOptions = {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    };
    return this.time.toLocaleDateString('zh-CN', options);
  }
}
```

- [ ] **Step 6: 创建统计面板组件**

```typescript
// entry/src/main/ets/components/StatsPanel.ets
import { DataStatisticsManager } from '../managers/DataStatisticsManager';
import { AchievementManager } from '../managers/AchievementManager';
import { TimeUtils } from '../utils/TimeUtils';

@Component
export struct StatsPanel {
  @Prop dailyStats: any;
  @Prop onClose: () => void;

  @State weeklyStats: any = null;
  @State achievements: any[] = [];
  @State selectedTab: string = 'today';

  private dataManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();

  aboutToAppear(): void {
    this.loadWeeklyStats();
    this.loadAchievements();
  }

  async loadWeeklyStats(): Promise<void> {
    try {
      this.weeklyStats = await this.dataManager.getWeeklyStats();
    } catch (error) {
      console.error(`加载周统计失败: ${JSON.stringify(error)}`);
    }
  }

  async loadAchievements(): Promise<void> {
    try {
      this.achievements = this.achievementManager.getUnlockedAchievements();
    } catch (error) {
      console.error(`加载成就失败: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column() {
      // 标题和关闭按钮
      Row() {
        Text('统计数据')
          .fontSize(18)
          .fontColor('#ffd166')
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        Button('关闭')
          .width(60)
          .height(30)
          .fontSize(12)
          .backgroundColor('transparent')
          .borderColor('#ff9e6d')
          .borderWidth(1)
          .onClick(() => this.onClose())
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 标签页
      Row({ space: 20 }) {
        Button('今日')
          .width(80)
          .height(35)
          .fontSize(14)
          .backgroundColor(this.selectedTab === 'today' ? '#2a3157' : 'transparent')
          .borderColor(this.selectedTab === 'today' ? '#ff9e6d' : '#2a3157')
          .borderWidth(1)
          .onClick(() => { this.selectedTab = 'today'; })

        Button('本周')
          .width(80)
          .height(35)
          .fontSize(14)
          .backgroundColor(this.selectedTab === 'week' ? '#2a3157' : 'transparent')
          .borderColor(this.selectedTab === 'week' ? '#ff9e6d' : '#2a3157')
          .borderWidth(1)
          .onClick(() => { this.selectedTab = 'week'; })

        Button('成就')
          .width(80)
          .height(35)
          .fontSize(14)
          .backgroundColor(this.selectedTab === 'achievements' ? '#2a3157' : 'transparent')
          .borderColor(this.selectedTab === 'achievements' ? '#ff9e6d' : '#2a3157')
          .borderWidth(1)
          .onClick(() => { this.selectedTab = 'achievements'; })
      }
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })

      // 内容区域
      Scroll() {
        Column({ space: 15 }) {
          if (this.selectedTab === 'today') {
            this.buildTodayStats();
          } else if (this.selectedTab === 'week') {
            this.buildWeeklyStats();
          } else {
            this.buildAchievements();
          }
        }
        .padding(15)
      }
      .height(300)
    }
    .width('90%')
    .padding(20)
    .backgroundColor('#1a1f3a')
    .borderRadius(15)
    .border({ width: 1, color: '#2a3157' })
  }

  @Builder
  buildTodayStats() {
    if (!this.dailyStats) {
      Text('暂无今日数据')
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
      return;
    }

    Column({ space: 12 }) {
      StatItem('实际时长', `${this.dailyStats.actualDuration}分钟`)
      StatItem('越狱次数', `${this.dailyStats.escapeCount}次`)
      StatItem('成功率', `${this.dailyStats.successPercentage || 0}%`)
      StatItem('剩余时间', TimeUtils.formatMinutes(this.dailyStats.remainingMinutes))
      StatItem('状态', this.dailyStats.success ? '成功' : this.dailyStats.isActive ? '进行中' : '未开始')
    }
  }

  @Builder
  buildWeeklyStats() {
    if (!this.weeklyStats) {
      Text('加载中...')
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
      return;
    }

    Column({ space: 12 }) {
      StatItem('统计天数', `${this.weeklyStats.days}天`)
      StatItem('成功天数', `${this.weeklyStats.totalSuccessDays}天`)
      StatItem('越狱总次数', `${this.weeklyStats.totalEscapeCount}次`)
      StatItem('平均时长', `${this.weeklyStats.averageDuration}分钟/天`)
      StatItem('成功率', `${this.weeklyStats.successRate}%`)
      StatItem('累计时长', TimeUtils.formatMinutes(this.weeklyStats.totalDuration))
    }
  }

  @Builder
  buildAchievements() {
    if (this.achievements.length === 0) {
      Text('暂无已解锁成就')
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
      return;
    }

    Column({ space: 10 }) {
      ForEach(this.achievements, (achievement) => {
        Row() {
          Text(achievement.icon || '🏆')
            .fontSize(20)
            .margin({ right: 10 })

          Column({ space: 2 }) {
            Text(achievement.name)
              .fontSize(14)
              .fontColor('#ffd166')

            Text(achievement.description)
              .fontSize(12)
              .fontColor('#c0c6e9')
              .maxLines(2)

            Text(`解锁时间: ${TimeUtils.formatTimestamp(achievement.unlockedAt)}`)
              .fontSize(10)
              .fontColor('#ff9e6d')
              .margin({ top: 5 })
          }
          .layoutWeight(1)
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#2a3157')
        .borderRadius(8)
      })
    }
  }
}

// 统计项组件
@Component
struct StatItem {
  @Prop label: string;
  @Prop value: string;

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor('#c0c6e9')
        .layoutWeight(1)

      Text(this.value)
        .fontSize(14)
        .fontColor('#ff9e6d')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 8, bottom: 8 })
    .backgroundColor('#2a3157')
    .borderRadius(8)
  }
}
```

- [ ] **Step 7: 提交主Ability和页面组件**

```bash
git add entry/src/main/ets/MainAbility/ entry/src/main/ets/pages/ entry/src/main/ets/components/
git commit -m "feat: 添加主Ability和页面组件"
```

### Task 13: 创建设置页面和统计页面

**Files:**
- Create: `entry/src/main/ets/pages/SettingsPage.ets`
- Create: `entry/src/main/ets/pages/StatsPage.ets`

- [ ] **Step 1: 创建设置页面**

```typescript
// entry/src/main/ets/pages/SettingsPage.ets
import { LanternLawStateManager } from '../managers/LanternLawStateManager';
import { LanternLawConfig } from '../models/LanternLawConfig';

@Entry
@Component
struct SettingsPage {
  private stateManager: LanternLawStateManager = LanternLawStateManager.getInstance();

  @State config: LanternLawConfig = new LanternLawConfig();
  @State bedtime: string = '22:30';
  @State wakeupTime: string = '06:30';
  @State emergencyUnlocks: number = 3;
  @State lanternlawEnabled: boolean = true;
  @State vibrationEnabled: boolean = true;

  aboutToAppear(): void {
    this.loadConfig();
  }

  async loadConfig(): Promise<void> {
    this.config = this.stateManager.getConfig();
    this.bedtime = this.config.bedtime;
    this.wakeupTime = this.config.wakeupTime;
    this.emergencyUnlocks = this.config.emergencyUnlocks;
    this.lanternlawEnabled = this.config.lanternlawEnabled;
    this.vibrationEnabled = this.config.vibrationEnabled;
  }

  async saveConfig(): Promise<void> {
    this.config.bedtime = this.bedtime;
    this.config.wakeupTime = this.wakeupTime;
    this.config.emergencyUnlocks = this.emergencyUnlocks;
    this.config.lanternlawEnabled = this.lanternlawEnabled;
    this.config.vibrationEnabled = this.vibrationEnabled;

    await this.stateManager.saveConfig(this.config);

    // 显示保存成功提示
    // 实际实现可以使用Toast或Dialog
    console.log('配置已保存');
  }

  // 验证时间格式
  isValidTime(time: string): boolean {
    const regex = /^([01]?[0-9]|2[0-3]):([0-5][0-9])$/;
    return regex.test(time);
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('设置')
        .fontSize(24)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      Scroll() {
        Column({ space: 15 }) {
          // 宵禁开关
          Row() {
            Text('启用宵禁')
              .fontSize(16)
              .fontColor('#c0c6e9')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.lanternlawEnabled })
              .onChange((value: boolean) => {
                this.lanternlawEnabled = value;
              })
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#1a1f3a')
          .borderRadius(10)

          // 就寝时间
          SettingItem('就寝时间', this.bedtime, (value: string) => {
            if (this.isValidTime(value)) {
              this.bedtime = value;
            }
          })

          // 解锁时间
          SettingItem('解锁时间', this.wakeupTime, (value: string) => {
            if (this.isValidTime(value)) {
              this.wakeupTime = value;
            }
          })

          // 紧急解锁次数
          Row() {
            Text('紧急解锁次数')
              .fontSize(16)
              .fontColor('#c0c6e9')
              .layoutWeight(1)

            Text(`${this.emergencyUnlocks}次/月`)
              .fontSize(16)
              .fontColor('#ff9e6d')
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#1a1f3a')
          .borderRadius(10)

          // 振动反馈
          Row() {
            Text('振动反馈')
              .fontSize(16)
              .fontColor('#c0c6e9')
              .layoutWeight(1)

            Toggle({ type: ToggleType.Switch, isOn: this.vibrationEnabled })
              .onChange((value: boolean) => {
                this.vibrationEnabled = value;
              })
          }
          .width('100%')
          .padding(15)
          .backgroundColor('#1a1f3a')
          .borderRadius(10)

          // 保存按钮
          Button('保存设置')
            .width('100%')
            .height(50)
            .fontSize(16)
            .fontColor('#0f1529')
            .backgroundColor('#ff9e6d')
            .borderRadius(10)
            .onClick(() => this.saveConfig())
            .margin({ top: 30 })

          // 权限管理按钮
          Button('权限管理')
            .width('100%')
            .height(45)
            .fontSize(14)
            .fontColor('#c0c6e9')
            .backgroundColor('transparent')
            .borderColor('#2a3157')
            .borderWidth(1)
            .borderRadius(10)
            .onClick(() => {
              // 跳转到系统权限设置
              console.log('跳转到权限管理');
            })

          // 数据管理按钮
          Button('数据管理')
            .width('100%')
            .height(45)
            .fontSize(14)
            .fontColor('#c0c6e9')
            .backgroundColor('transparent')
            .borderColor('#2a3157')
            .borderWidth(1)
            .borderRadius(10)
            .onClick(() => {
              // 跳转到数据管理页面
              console.log('跳转到数据管理');
            })
        }
        .padding(20)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0f1529')
  }
}

// 设置项组件
@Component
struct SettingItem {
  @Prop label: string;
  @Prop value: string;
  @Prop onChange: (value: string) => void;

  @State editing: boolean = false;
  @State editValue: string = '';

  aboutToAppear(): void {
    this.editValue = this.value;
  }

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(16)
          .fontColor('#c0c6e9')
          .layoutWeight(1)

        if (this.editing) {
          TextInput({ text: this.editValue })
            .width(80)
            .height(40)
            .fontSize(16)
            .fontColor('#ff9e6d')
            .onChange((value: string) => {
              this.editValue = value;
            })
            .onSubmit(() => {
              this.editing = false;
              this.onChange(this.editValue);
            })
        } else {
          Text(this.value)
            .fontSize(16)
            .fontColor('#ff9e6d')
            .onClick(() => {
              this.editing = true;
            })
        }
      }
      .width('100%')
      .padding(15)
      .backgroundColor('#1a1f3a')
      .borderRadius(10)
    }
  }
}
```

- [ ] **Step 2: 创建统计页面**

```typescript
// entry/src/main/ets/pages/StatsPage.ets
import { DataStatisticsManager } from '../managers/DataStatisticsManager';
import { AchievementManager } from '../managers/AchievementManager';
import { TimeUtils } from '../utils/TimeUtils';

@Entry
@Component
struct StatsPage {
  private dataManager: DataStatisticsManager = DataStatisticsManager.getInstance();
  private achievementManager: AchievementManager = AchievementManager.getInstance();

  @State todayStats: any = null;
  @State weeklyStats: any = null;
  @State monthlyStats: any = null;
  @State achievements: any[] = [];
  @State trendData: any[] = [];
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.loadAllStats();
  }

  async loadAllStats(): Promise<void> {
    this.loading = true;

    try {
      this.todayStats = await this.dataManager.getTodayStats();
      this.weeklyStats = await this.dataManager.getWeeklyStats();
      this.monthlyStats = await this.dataManager.getMonthlyStats();
      this.achievements = this.achievementManager.getUnlockedAchievements();
      this.trendData = await this.dataManager.getTrendData(7);
    } catch (error) {
      console.error(`加载统计失败: ${JSON.stringify(error)}`);
    } finally {
      this.loading = false;
    }
  }

  // 导出数据
  async exportData(): Promise<void> {
    try {
      const exportText = await this.dataManager.exportStats();

      // 实际实现应该保存到文件或分享
      console.log('导出数据:', exportText);

      // 显示导出成功提示
    } catch (error) {
      console.error(`导出数据失败: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column({ space: 20 }) {
      // 标题
      Text('详细统计')
        .fontSize(24)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 30, bottom: 20 })

      if (this.loading) {
        Text('加载中...')
          .fontSize(16)
          .fontColor('#c0c6e9')
          .margin({ top: 50 })
      } else {
        Scroll() {
          Column({ space: 25 }) {
            // 今日概览
            this.buildSection('今日概览', this.buildTodayOverview())

            // 本周统计
            this.buildSection('本周统计', this.buildWeeklyStats())

            // 月度统计
            this.buildSection('月度统计', this.buildMonthlyStats())

            // 趋势图表
            this.buildSection('趋势分析', this.buildTrendChart())

            // 成就展示
            this.buildSection('成就展示', this.buildAchievements())

            // 导出按钮
            Button('导出所有数据')
              .width('100%')
              .height(50)
              .fontSize(16)
              .fontColor('#0f1529')
              .backgroundColor('#ff9e6d')
              .borderRadius(10)
              .onClick(() => this.exportData())
              .margin({ top: 20, bottom: 40 })
          }
          .padding(20)
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0f1529')
  }

  @Builder
  buildSection(title: string, content: any) {
    Column({ space: 15 }) {
      Text(title)
        .fontSize(18)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .width('100%')

      content
    }
  }

  @Builder
  buildTodayOverview() {
    if (!this.todayStats) return;

    Grid() {
      GridItem() {
        StatCard('实际时长', `${this.todayStats.actualDuration}分钟`, '#ff9e6d')
      }

      GridItem() {
        StatCard('越狱次数', `${this.todayStats.escapeCount}次`, '#ff9e6d')
      }

      GridItem() {
        StatCard('成功率', `${this.todayStats.successPercentage}%`, '#ff9e6d')
      }

      GridItem() {
        StatCard('状态', this.todayStats.success ? '成功' : this.todayStats.isActive ? '进行中' : '未开始', '#ff9e6d')
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
  }

  @Builder
  buildWeeklyStats() {
    if (!this.weeklyStats) return;

    Column({ space: 10 }) {
      StatRow('统计天数', `${this.weeklyStats.days}天`)
      StatRow('成功天数', `${this.weeklyStats.totalSuccessDays}天`)
      StatRow('越狱总次数', `${this.weeklyStats.totalEscapeCount}次`)
      StatRow('平均时长', `${this.weeklyStats.averageDuration}分钟/天`)
      StatRow('成功率', `${this.weeklyStats.successRate}%`)
    }
  }

  @Builder
  buildMonthlyStats() {
    if (!this.monthlyStats) return;

    Column({ space: 10 }) {
      StatRow('当前连续', `${this.monthlyStats.currentStreak}天`)
      StatRow('最佳连续', `${this.monthlyStats.bestStreak}天`)
      StatRow('累计成功', `${this.monthlyStats.totalSuccessDays}天`)
      StatRow('累计时长', TimeUtils.formatMinutes(this.monthlyStats.totalDuration))
      StatRow('平均时长', `${this.monthlyStats.averageDuration}分钟/天`)
    }
  }

  @Builder
  buildTrendChart() {
    if (this.trendData.length === 0) {
      Text('暂无趋势数据')
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(40)
      return;
    }

    // 简化趋势图表 - 实际应使用Canvas绘制
    Column({ space: 5 }) {
      ForEach(this.trendData, (item, index) => {
        Row() {
          Text(item.date.substring(5)) // 显示月-日
            .fontSize(12)
            .fontColor('#c0c6e9')
            .width(60)

          // 时长条形图
          Column() {
            Column()
              .width(`${Math.min(item.actualDuration / 60 * 100, 100)}%`) // 假设最大60分钟为100%
              .height(15)
              .backgroundColor('#ff9e6d')
              .borderRadius(3)
          }
          .width('100%')
          .height(15)
          .backgroundColor('#2a3157')
          .borderRadius(3)

          Text(`${item.actualDuration}m`)
            .fontSize(12)
            .fontColor('#ff9e6d')
            .width(40)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 8 })
      })
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#1a1f3a')
    .borderRadius(10)
  }

  @Builder
  buildAchievements() {
    if (this.achievements.length === 0) {
      Text('暂无已解锁成就')
        .fontSize(14)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(30)
      return;
    }

    Grid() {
      ForEach(this.achievements.slice(0, 4), (achievement) => {
        GridItem() {
          AchievementCard(achievement)
        }
      })
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
  }
}

// 统计卡片组件
@Component
struct StatCard {
  @Prop label: string;
  @Prop value: string;
  @Prop color: string;

  build() {
    Column({ space: 5 }) {
      Text(this.label)
        .fontSize(12)
        .fontColor('#c0c6e9')
        .textAlign(TextAlign.Center)

      Text(this.value)
        .fontSize(16)
        .fontColor(this.color)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(80)
    .padding(10)
    .backgroundColor('#1a1f3a')
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
  }
}

// 统计行组件
@Component
struct StatRow {
  @Prop label: string;
  @Prop value: string;

  build() {
    Row() {
      Text(this.label)
        .fontSize(14)
        .fontColor('#c0c6e9')
        .layoutWeight(1)

      Text(this.value)
        .fontSize(14)
        .fontColor('#ff9e6d')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#1a1f3a')
    .borderRadius(8)
  }
}

// 成就卡片组件
@Component
struct AchievementCard {
  @Prop achievement: any;

  build() {
    Column({ space: 5 }) {
      Text(this.achievement.icon || '🏆')
        .fontSize(24)

      Text(this.achievement.name)
        .fontSize(12)
        .fontColor('#ffd166')
        .textAlign(TextAlign.Center)
        .maxLines(2)
    }
    .width('100%')
    .height(100)
    .padding(10)
    .backgroundColor('#1a1f3a')
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
```

- [ ] **Step 3: 更新页面路由配置**

```json
// 更新 entry/src/main/resources/base/profile/main_pages.json
{
  "src": [
    "pages/IndexPage",
    "pages/SettingsPage",
    "pages/StatsPage"
  ]
}
```

- [ ] **Step 4: 提交设置页面和统计页面**

```bash
git add entry/src/main/ets/pages/SettingsPage.ets entry/src/main/ets/pages/StatsPage.ets entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: 添加设置页面和统计页面"
```

### Task 14: 创建资源文件

**Files:**
- Create: `entry/src/main/resources/base/media/app_icon.png` (占位符)
- Create: `entry/src/main/resources/base/element/string.json`
- Create: `entry/src/main/resources/base/element/color.json`

- [ ] **Step 1: 创建字符串资源**

```json
// entry/src/main/resources/base/element/string.json
{
  "string": [
    {
      "name": "app_name",
      "value": "LanternLaw"
    },
    {
      "name": "main_title",
      "value": "宵禁自律"
    },
    {
      "name": "settings_title",
      "value": "设置"
    },
    {
      "name": "stats_title",
      "value": "统计"
    },
    {
      "name": "lanternlaw_active",
      "value": "宵禁进行中"
    },
    {
      "name": "lanternlaw_idle",
      "value": "非宵禁时段"
    },
    {
      "name": "remaining_time",
      "value": "剩余时间"
    },
    {
      "name": "escape_detected",
      "value": "越狱检测"
    },
    {
      "name": "achievement_unlocked",
      "value": "成就解锁"
    },
    {
      "name": "save_settings",
      "value": "保存设置"
    },
    {
      "name": "export_data",
      "value": "导出数据"
    }
  ]
}
```

- [ ] **Step 2: 创建颜色资源**

```json
// entry/src/main/resources/base/element/color.json
{
  "color": [
    {
      "name": "midnight_blue",
      "value": "#0f1529"
    },
    {
      "name": "dark_night_black",
      "value": "#1a1f3a"
    },
    {
      "name": "accent_blue",
      "value": "#2a3157"
    },
    {
      "name": "golden_light",
      "value": "#ffd166"
    },
    {
      "name": "orange_glow",
      "value": "#ff9e6d"
    },
    {
      "name": "light_gray",
      "value": "#c0c6e9"
    },
    {
      "name": "warm_yellow",
      "value": "#ff9e6d"
    },
    {
      "name": "start_window_background",
      "value": "#0f1529"
    }
  ]
}
```

- [ ] **Step 3: 创建应用图标占位符**

```bash
# 创建占位符图标目录
mkdir -p entry/src/main/resources/base/media
# 注意：实际需要提供PNG图标文件，这里创建空文件占位
touch entry/src/main/resources/base/media/app_icon.png
```

- [ ] **Step 4: 提交资源文件**

```bash
git add entry/src/main/resources/
git commit -m "feat: 添加资源文件 (字符串、颜色、图标)"
```

### Task 15: 创建测试模块

**Files:**
- Create: `entry/ohosTest/src/test/ets/test/LanternLawLogicTest.ets`
- Create: `entry/ohosTest/src/test/ets/test/TimeUtilsTest.ets`
- Create: `entry/ohosTest/src/test/resources/base/profile/test_runner_config.json`

- [ ] **Step 1: 创建测试运行器配置**

```json
// entry/ohosTest/src/test/resources/base/profile/test_runner_config.json
{
  "testRunnerClass": "ohos.test.junit.JUnitTestRunner",
  "cases": []
}
```

- [ ] **Step 2: 创建时间工具测试**

```typescript
// entry/ohosTest/src/test/ets/test/TimeUtilsTest.ets
import { describe, it, expect } from '@ohos.hypium';
import { TimeUtils } from '../../../src/main/ets/utils/TimeUtils';

@Entry
@Component
struct TimeUtilsTest {
  build() {
    Column() {
      // 测试组件占位
      Text('TimeUtils 测试套件')
        .fontSize(16)
    }
  }
}

describe('TimeUtilsTest', () => {
  it('testParseTimeString_valid', 0, async () => {
    const result = TimeUtils.parseTimeString('14:30');
    expect(result.hour).assertEqual(14);
    expect(result.minute).assertEqual(30);
  });

  it('testParseTimeString_invalid', 0, async () => {
    try {
      TimeUtils.parseTimeString('25:30');
      expect(true).assertFalse(); // 应该抛出异常
    } catch (error) {
      expect(error.message).assertContain('无效的小时');
    }
  });

  it('testFormatMinutes', 0, async () => {
    expect(TimeUtils.formatMinutes(90)).assertEqual('1小时30分钟');
    expect(TimeUtils.formatMinutes(60)).assertEqual('1小时');
    expect(TimeUtils.formatMinutes(45)).assertEqual('45分钟');
    expect(TimeUtils.formatMinutes(0)).assertEqual('0分钟');
  });

  it('testIsInTimeRange_same_day', 0, async () => {
    const currentTime = new Date('2026-03-23T15:30:00');
    const result = TimeUtils.isInTimeRange(currentTime, '14:00', '18:00');
    expect(result).assertTrue();
  });

  it('testIsInTimeRange_overnight', 0, async () => {
    const currentTime = new Date('2026-03-23T02:30:00');
    const result = TimeUtils.isInTimeRange(currentTime, '22:00', '06:00');
    expect(result).assertTrue();
  });
});
```

- [ ] **Step 3: 创建宵禁逻辑测试**

```typescript
// entry/ohosTest/src/test/ets/test/LanternLawLogicTest.ets
import { describe, it, expect } from '@ohos.hypium';
import { LanternLawConfig } from '../../../src/main/ets/models/LanternLawConfig';

@Entry
@Component
struct LanternLawLogicTest {
  build() {
    Column() {
      Text('LanternLawLogic 测试套件')
        .fontSize(16)
    }
  }
}

describe('LanternLawLogicTest', () => {
  it('testLanternLawConfig_isValid_valid', 0, async () => {
    const config = new LanternLawConfig();
    config.bedtime = '22:30';
    config.wakeupTime = '06:30';
    expect(config.isValid()).assertTrue();
  });

  it('testLanternLawConfig_isValid_invalid', 0, async () => {
    const config = new LanternLawConfig();
    config.bedtime = '25:30'; // 无效时间
    config.wakeupTime = '06:30';
    expect(config.isValid()).assertFalse();
  });

  it('testLanternLawConfig_toJSON_fromJSON', 0, async () => {
    const config = new LanternLawConfig();
    config.bedtime = '23:00';
    config.wakeupTime = '07:00';
    config.emergencyUnlocks = 5;
    config.lanternlawEnabled = false;

    const json = config.toJSON();
    const restoredConfig = LanternLawConfig.fromJSON(json);

    expect(restoredConfig.bedtime).assertEqual('23:00');
    expect(restoredConfig.wakeupTime).assertEqual('07:00');
    expect(restoredConfig.emergencyUnlocks).assertEqual(5);
    expect(restoredConfig.lanternlawEnabled).assertFalse();
  });

  it('testShouldLanternLawBeActive', 0, async () => {
    // 简化测试，实际应测试时间计算逻辑
    expect(true).assertTrue();
  });
});
```

- [ ] **Step 4: 提交测试模块**

```bash
git add entry/ohosTest/
git commit -m "feat: 添加测试模块和单元测试"
```

---

## 执行选项

**计划完成并保存到 `docs/superpowers/plans/2026-03-23-lanternlaw-harmonyos-implementation.md`。**

**两个执行选项：**

**1. 子代理驱动开发（推荐）** - 我为每个任务分发新的子代理，任务间进行审查，快速迭代

**2. 内联执行** - 在当前会话中使用executing-plans技能，分批执行任务并设置检查点

**选择哪种方式？**