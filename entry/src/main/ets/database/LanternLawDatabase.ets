// entry/src/main/ets/database/LanternLawDatabase.ets
/**
 * 灯律数据库管理器
 * LanternLaw Database Manager
 */
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import { DailyRecord } from '../models/DailyRecord';

// 每日逃跑次数统计接口
export interface DailyEscapeCount {
  date: string;
  escapeCount: number;
}

export class LanternLawDatabase {
  private static instance: LanternLawDatabase;
  private rdbStore: relationalStore.RdbStore | null = null;

  // 数据库配置
  private readonly DB_CONFIG: relationalStore.StoreConfig = {
    name: 'lanternlaw.db',
    securityLevel: relationalStore.SecurityLevel.S1
  };

  // 数据库版本
  private readonly DB_VERSION: number = 2;

  // 表定义（使用新字段名）
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

  // 用于数据迁移的新表定义
  private readonly CREATE_NEW_TABLES_SQL: string = `
    CREATE TABLE IF NOT EXISTS new_lanternlaw_config (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS new_daily_records (
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
  public isInitialized(): boolean {
    return this.rdbStore !== null;
  }

  public async initialize(context: Context): Promise<void> {
    try {
      // 创建或打开数据库
      this.rdbStore = await relationalStore.getRdbStore(
        context,
        this.DB_CONFIG
      );

      // 检查数据库版本并执行迁移
      await this.checkAndMigrateDatabase();

      // 创建表（如果已存在则跳过）
      await this.rdbStore.executeSql(this.CREATE_TABLES_SQL);

      console.log('灯律数据库初始化成功');
    } catch (error) {
      console.error(`灯律数据库初始化失败: ${JSON.stringify(error)}`);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  // 保存配置
  public async saveConfig(key: string, value: string): Promise<void> {
    console.info('[LanternLawDatabase] saveConfig 开始执行, key: ' + key);
    if (!this.rdbStore) {
      console.error('[LanternLawDatabase] 数据库未初始化');
      throw new Error('数据库未初始化');
    }

    const now = Date.now();
    const predicates = new relationalStore.RdbPredicates('lanternlaw_config');
    predicates.equalTo('key', key);

    try {
      // 检查是否已存在
      console.info('[LanternLawDatabase] 检查记录是否存在');
      const resultSet = await this.rdbStore.query(predicates, ['id']);
      let isUpdate = false;
      if (resultSet) {
        isUpdate = await resultSet.goToFirstRow();
        resultSet.close();
      }
      console.info('[LanternLawDatabase] isUpdate: ' + isUpdate);

      if (isUpdate) {
        // 更新现有记录
        console.info('[LanternLawDatabase] 更新现有记录');
        const valuesBucket: relationalStore.ValuesBucket = {
          'value': value,
          'updated_at': now
        };
        await this.rdbStore.update(valuesBucket, predicates);
        console.info('[LanternLawDatabase] 更新完成');
      } else {
        // 插入新记录
        console.info('[LanternLawDatabase] 插入新记录');
        const valuesBucket: relationalStore.ValuesBucket = {
          'key': key,
          'value': value,
          'updated_at': now
        };
        await this.rdbStore.insert('lanternlaw_config', valuesBucket);
        console.info('[LanternLawDatabase] 插入完成');
      }
      console.info('[LanternLawDatabase] saveConfig 完成');
    } catch (error) {
      console.error('[LanternLawDatabase] 保存配置失败: ' + JSON.stringify(error));
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  // 读取配置
  public async getConfig(key: string): Promise<string | null> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    // 优先查询新表
    let predicates = new relationalStore.RdbPredicates('lanternlaw_config');
    predicates.equalTo('key', key);

    try {
      const columns = ['value'];
      const resultSet = await this.rdbStore.query(predicates, columns);

      if (resultSet && await resultSet.goToFirstRow()) {
        const value = resultSet.getString(resultSet.getColumnIndex('value'));
        resultSet.close();
        return value;
      }

      if (resultSet) {
        resultSet.close();
      }

      // 如果新表中没有找到，尝试从旧表读取（向后兼容）
      const oldPredicates = new relationalStore.RdbPredicates('curfew_config');
      oldPredicates.equalTo('key', key);
      const oldResultSet = await this.rdbStore.query(oldPredicates, columns);

      if (oldResultSet && await oldResultSet.goToFirstRow()) {
        const value = oldResultSet.getString(oldResultSet.getColumnIndex('value'));
        oldResultSet.close();
        // 自动迁移到新表
        await this.saveConfig(key, value);
        return value;
      }

      if (oldResultSet) {
        oldResultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`读取配置失败: ${JSON.stringify(error)}`);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  // 保存每日记录
  public async saveDailyRecord(record: DailyRecord): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'id': record.id,
        'version': record.version,
        'date': record.date,
        'lanternlaw_start': record.lanternlawStart,
        'lanternlaw_end': record.lanternlawEnd,
        'actual_duration': record.actualDuration,
        'escape_count': record.escapeCount,
        'success': record.success ? 1 : 0,
        'created_at': record.createdAt,
        'updated_at': record.updatedAt
      };

      // 使用INSERT OR REPLACE语义
      await this.rdbStore.insert('daily_records', valuesBucket);
    } catch (error) {
      console.error(`保存每日记录失败: ${JSON.stringify(error)}`);
      throw new Error(`保存每日记录失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // 获取今日记录
  public async getTodayRecord(): Promise<DailyRecord | null> {
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

      if (resultSet && await resultSet.goToFirstRow()) {
        const record = new DailyRecord();
        record.id = resultSet.getString(resultSet.getColumnIndex('id'));
        record.version = resultSet.getLong(resultSet.getColumnIndex('version'));
        record.date = resultSet.getString(resultSet.getColumnIndex('date'));
        record.lanternlawStart = resultSet.getLong(resultSet.getColumnIndex('lanternlaw_start'));
        record.lanternlawEnd = resultSet.getLong(resultSet.getColumnIndex('lanternlaw_end'));
        record.actualDuration = resultSet.getLong(resultSet.getColumnIndex('actual_duration'));
        record.escapeCount = resultSet.getLong(resultSet.getColumnIndex('escape_count'));
        record.success = this.getBooleanFromResultSet(resultSet, 'success');
        record.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
        record.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));

        resultSet.close();
        return record;
      }

      if (resultSet) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`获取今日记录失败: ${JSON.stringify(error)}`);
      throw new Error(`获取今日记录失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  // 获取最近N天记录
  public async getRecentRecords(days: number = 7): Promise<DailyRecord[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    const predicates = new relationalStore.RdbPredicates('daily_records');
    predicates.orderByDesc('date');
    predicates.limitAs(days);

    try {
      const columns = [
        'id', 'date', 'actual_duration', 'escape_count', 'success', 'lanternlaw_start', 'lanternlaw_end'
      ];

      const resultSet = await this.rdbStore.query(predicates, columns);
      const records: DailyRecord[] = [];

      if (resultSet) {
        while (await resultSet.goToNextRow()) {
          const record = new DailyRecord();
          record.id = resultSet.getString(resultSet.getColumnIndex('id'));
          record.version = 1;
          record.date = resultSet.getString(resultSet.getColumnIndex('date'));
          record.actualDuration = resultSet.getLong(resultSet.getColumnIndex('actual_duration'));
          record.escapeCount = resultSet.getLong(resultSet.getColumnIndex('escape_count'));
          record.success = this.getBooleanFromResultSet(resultSet, 'success');
          record.lanternlawStart = resultSet.getLong(resultSet.getColumnIndex('lanternlaw_start'));
          record.lanternlawEnd = resultSet.getLong(resultSet.getColumnIndex('lanternlaw_end'));
          record.createdAt = 0;
          record.updatedAt = 0;
          records.push(record);
        }

        resultSet.close();
      }
      return records;
    } catch (error) {
      console.error(`获取最近记录失败: ${JSON.stringify(error)}`);
      throw new Error(`获取最近记录失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 检查并迁移数据库
   * @private
   */
  private async checkAndMigrateDatabase(): Promise<void> {
    try {
      // 检查是否存在版本表
      const versionTableExists = await this.checkTableExists('db_version');

      if (!versionTableExists) {
        // 版本表不存在，创建它
        const createVersionTableSql = `
          CREATE TABLE IF NOT EXISTS db_version (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            version INTEGER NOT NULL,
            migrated_at INTEGER NOT NULL
          );
        `;
        if (this.rdbStore) {
          await this.rdbStore.executeSql(createVersionTableSql);
        } else {
          throw new Error('数据库未初始化');
        }

        // 检查是否有旧数据库（通过检查旧表）
        const oldTableExists = await this.checkTableExists('daily_records');

        if (oldTableExists) {
          // 从旧版本迁移
          console.log('检测到旧数据库，开始迁移...');
          await this.migrateFromOldDatabase();
        }

        // 插入初始版本
        const insertVersionSql = `INSERT INTO db_version (version, migrated_at) VALUES (${this.DB_VERSION}, ${Date.now()});`;
        if (this.rdbStore) {
          await this.rdbStore.executeSql(insertVersionSql);
        } else {
          throw new Error('数据库未初始化');
        }

        console.log(`数据库版本表创建完成，版本: ${this.DB_VERSION}`);
      } else {
        // 检查当前版本
        const currentVersion = await this.getCurrentDatabaseVersion();
        if (currentVersion !== null && currentVersion < this.DB_VERSION) {
          await this.migrateDatabase(currentVersion, this.DB_VERSION);
        }
      }
    } catch (error) {
      console.error(`数据库版本检查失败: ${JSON.stringify(error)}`);
      if (error instanceof Error) {
        throw error;
      } else {
        throw new Error(String(error));
      }
    }
  }

  /**
   * 从旧数据库迁移数据
   * 迁移旧表名和字段到新命名
   * @private
   */
  private async migrateFromOldDatabase(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      // 1. 创建新表（如果不存在）
      await this.rdbStore.executeSql(this.CREATE_NEW_TABLES_SQL);

      // 2. 迁移daily_records表数据
      await this.rdbStore.executeSql(`
        INSERT OR REPLACE INTO new_daily_records
        SELECT * FROM daily_records
      `);

      // 3. 删除旧表并重命名新表
      await this.rdbStore.executeSql('DROP TABLE IF EXISTS daily_records');
      await this.rdbStore.executeSql('ALTER TABLE new_daily_records RENAME TO daily_records');

      // 4. 同样的方式迁移curfew_config到lanternlaw_config
      await this.rdbStore.executeSql(`
        INSERT OR REPLACE INTO new_lanternlaw_config
        SELECT * FROM curfew_config
      `);
      await this.rdbStore.executeSql('DROP TABLE IF EXISTS curfew_config');
      await this.rdbStore.executeSql('ALTER TABLE new_lanternlaw_config RENAME TO lanternlaw_config');

      console.log('旧数据库迁移完成');
    } catch (error) {
      console.error(`旧数据库迁移失败: ${JSON.stringify(error)}`);
      throw new Error(`旧数据库迁移失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 检查表是否存在
   * @private
   * @param tableName 表名
   * @returns 表是否存在
   */
  private async checkTableExists(tableName: string): Promise<boolean> {
    try {
      const sql = `SELECT name FROM sqlite_master WHERE type='table' AND name='${tableName}';`;
      if (!this.rdbStore) {
        return false;
      }
      const resultSet = await this.rdbStore.querySql(sql);
      let exists = false;
      if (resultSet) {
        exists = await resultSet.goToFirstRow();
        resultSet.close();
      }
      return exists;
    } catch (error) {
      console.error(`检查表是否存在失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取当前数据库版本
   * @private
   * @returns 当前版本号
   */
  private async getCurrentDatabaseVersion(): Promise<number | null> {
    try {
      const sql = 'SELECT MAX(version) as current_version FROM db_version;';
      if (!this.rdbStore) {
        return null;
      }
      const resultSet = await this.rdbStore.querySql(sql);

      if (resultSet !== null && await resultSet.goToFirstRow()) {
        const columnIndex = resultSet.getColumnIndex('current_version');
        const version = resultSet.getLong(columnIndex);
        resultSet.close();
        return version;
      }

      if (resultSet !== null) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`获取数据库版本失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 迁移数据库（版本到版本）
   * @private
   * @param fromVersion 起始版本
   * @param toVersion 目标版本
   */
  private async migrateDatabase(fromVersion: number, toVersion: number): Promise<void> {
    console.log(`开始数据库迁移: ${fromVersion} -> ${toVersion}`);

    // 这里可以添加具体的迁移逻辑
    // 例如：根据版本差异执行不同的SQL语句

    // 更新版本记录
    if (this.rdbStore) {
      await this.rdbStore.executeSql(`
        INSERT INTO db_version (version, migrated_at) VALUES (${toVersion}, ${Date.now()});
      `);
    } else {
      throw new Error('数据库未初始化');
    }

    console.log(`数据库迁移完成: ${fromVersion} -> ${toVersion}`);
  }

  /**
   * 从结果集中获取布尔值
   * @private
   * @param resultSet 结果集
   * @param columnName 列名
   * @returns 布尔值
   */
  private getBooleanFromResultSet(resultSet: relationalStore.ResultSet, columnName: string): boolean {
    try {
      // 在HarmonyOS关系型数据库中，BOOLEAN类型存储为INTEGER（0或1）
      const value = resultSet.getLong(resultSet.getColumnIndex(columnName));
      return value !== 0;
    } catch (error) {
      console.error(`获取布尔值失败: ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 获取指定天数内的逃跑总次数
   */
  public async getEscapeCountInDays(days: number): Promise<number> {
    if (!this.rdbStore) {
      return 0;
    }

    try {
      const now = Date.now();
      const startTime = now - days * 24 * 60 * 60 * 1000;
      const predicates = new relationalStore.RdbPredicates('escape_attempts');
      predicates.greaterThan('timestamp', startTime);
      const resultSet = await this.rdbStore.query(predicates, ['count(*) as cnt']);
      if (resultSet && await resultSet.goToFirstRow()) {
        const count = resultSet.getLong(0);
        resultSet.close();
        return count;
      }
      if (resultSet) {
        resultSet.close();
      }
      return 0;
    } catch (error) {
      return 0;
    }
  }

  /**
   * 获取指定天数内每天的逃跑次数
   * 返回格式: [{ date: '2026-03-28', escapeCount: 3 }, ...]
   */
  public async getDailyEscapeCounts(days: number): Promise<DailyEscapeCount[]> {
    if (!this.rdbStore) {
      return [];
    }

    try {
      const now = Date.now();
      const startTime = now - days * 24 * 60 * 60 * 1000;
      const sql = `SELECT date(datetime(timestamp / 1000, 'unixepoch', 'localtime')) as date, count(*) as cnt ` +
        `FROM escape_attempts WHERE timestamp > ${startTime} GROUP BY date ORDER BY date DESC`;
      const resultSet = await this.rdbStore.querySql(sql);
      const result: DailyEscapeCount[] = [];

      if (resultSet) {
        while (await resultSet.goToNextRow()) {
          const dateStr = resultSet.getString(0);
          const count = resultSet.getLong(1);
          const item: DailyEscapeCount = { date: dateStr, escapeCount: count };
          result.push(item);
        }
        resultSet.close();
      }
      return result;
    } catch (error) {
      return [];
    }
  }

  // ==================== 用户账号管理 ====================

  private static readonly KEY_USER_ACCOUNT = 'user_account';

  /**
   * 保存用户账号
   */
  public async saveUserAccount(accountJson: string): Promise<void> {
    await this.saveConfig(LanternLawDatabase.KEY_USER_ACCOUNT, accountJson);
  }

  /**
   * 获取用户账号
   * @returns 账号 JSON 字符串，不存在时返回 null
   */
  public async getUserAccount(): Promise<string | null> {
    return await this.getConfig(LanternLawDatabase.KEY_USER_ACCOUNT);
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
