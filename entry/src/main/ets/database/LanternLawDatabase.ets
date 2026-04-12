// entry/src/main/ets/database/LanternLawDatabase.ets
/**
 * 灯律数据库管理器
 * LanternLaw Database Manager
 */
import relationalStore from '@ohos.data.relationalStore';
import { BusinessError } from '@ohos.base';
import { DailyRecord } from '../models/DailyRecord';
import { UserAccount } from '../models/UserAccount';
import { FamilyGroup } from '../models/FamilyGroup';
import { FamilyMessage, MessageType } from '../models/Message';
import { AccountMode } from '../models/AccountMode';

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
  private readonly DB_VERSION: number = 4;

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

  // Phase 1: 多帐号体系新增表
  private readonly CREATE_ACCOUNTS_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS accounts (
      account_id TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      avatar TEXT DEFAULT '😊',
      password_hash TEXT NOT NULL,
      account_mode TEXT NOT NULL DEFAULT 'parent',
      family_group_id TEXT,
      parent_account_id TEXT,
      is_local_active INTEGER DEFAULT 0,
      join_status TEXT DEFAULT '',
      pending_group_id TEXT DEFAULT '',
      pending_requested_at INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`;

  private readonly CREATE_FAMILY_GROUPS_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS family_groups (
      group_id TEXT PRIMARY KEY,
      group_name TEXT NOT NULL,
      parent_account_id TEXT NOT NULL,
      invitation_code TEXT,
      invitation_expires_at INTEGER,
      pending_members TEXT DEFAULT '',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )`;

  private readonly CREATE_MESSAGES_TABLE_SQL: string = `
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      sender_account_id TEXT NOT NULL,
      receiver_account_id TEXT NOT NULL,
      message_type TEXT NOT NULL,
      content TEXT NOT NULL,
      is_read INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL
    )`;

  private readonly CREATE_ACCOUNT_INDEXES_SQL: string[] = [
    'CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_account_id, is_read)',
    'CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at)',
    'CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(is_local_active)',
    'CREATE INDEX IF NOT EXISTS idx_accounts_family_group ON accounts(family_group_id)'
  ];

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

      // 创建多帐号体系表（Phase 1）
      await this.rdbStore.executeSql(this.CREATE_ACCOUNTS_TABLE_SQL);
      await this.rdbStore.executeSql(this.CREATE_FAMILY_GROUPS_TABLE_SQL);
      await this.rdbStore.executeSql(this.CREATE_MESSAGES_TABLE_SQL);
      for (const sql of this.CREATE_ACCOUNT_INDEXES_SQL) {
        await this.rdbStore.executeSql(sql);
      }

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

    // v2 → v3: 多帐号体系迁移
    if (fromVersion < 3) {
      await this.migrateV2ToV3();
    }

    // v3 → v4: 儿童加入沟通组流程字段
    if (fromVersion < 4) {
      await this.migrateV3ToV4();
    }

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
   * v2 → v3 迁移：将现有帐号迁移到 accounts 表，配置 key 添加 accountId 后缀
   * @private
   */
  private async migrateV2ToV3(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    console.log('开始 v2 → v3 迁移...');

    // 1. 创建新表
    await this.rdbStore.executeSql(this.CREATE_ACCOUNTS_TABLE_SQL);
    await this.rdbStore.executeSql(this.CREATE_FAMILY_GROUPS_TABLE_SQL);
    await this.rdbStore.executeSql(this.CREATE_MESSAGES_TABLE_SQL);
    for (const sql of this.CREATE_ACCOUNT_INDEXES_SQL) {
      await this.rdbStore.executeSql(sql);
    }

    // 2. 读取现有帐号数据（从 lanternlaw_config 表的 user_account key）
    const accountJson = await this.getConfig('user_account');
    if (accountJson) {
      try {
        const account = UserAccount.fromJSON(accountJson);

        // 生成 accountId（如果不存在）
        let accountId = account.accountId;
        if (!accountId) {
          accountId = this.generateUUID();
        }

        // 写入 accounts 表
        const now = Date.now();
        const valuesBucket: relationalStore.ValuesBucket = {
          'account_id': accountId,
          'username': account.username || '用户',
          'avatar': account.avatar || '😊',
          'password_hash': account.passwordHash || '',
          'account_mode': account.accountMode || AccountMode.PARENT,
          'family_group_id': '',
          'parent_account_id': '',
          'is_local_active': 1,
          'created_at': account.createdAt || now,
          'updated_at': now
        };
        await this.rdbStore.insert('accounts', valuesBucket);

        // 3. 将现有配置复制到按 accountId 隔离的 key
        const configJson = await this.getConfig('lanternlaw_config');
        if (configJson) {
          await this.saveConfig(`lanternlaw_config_${accountId}`, configJson);
        }

        // 4. 更新 user_account JSON 中的 accountId 字段
        account.accountId = accountId;
        await this.saveConfig('user_account', account.toJSON());

        console.log(`v2 → v3 迁移完成, accountId: ${accountId}`);
      } catch (error) {
        console.error(`v2 → v3 迁移帐号数据失败: ${JSON.stringify(error)}`);
        // 迁移失败不阻止升级
      }
    } else {
      console.log('v2 → v3 迁移: 无现有帐号数据，跳过');
    }
  }

  /**
   * v3 → v4 迁移：accounts 表新增 join_status/pending_group_id/pending_requested_at，
   * family_groups 表新增 pending_members
   * @private
   */
  private async migrateV3ToV4(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    console.log('开始 v3 → v4 迁移...');

    // ALTER TABLE ADD COLUMN（try-catch 防止重复添加）
    const alterStatements = [
      'ALTER TABLE accounts ADD COLUMN join_status TEXT DEFAULT \'\'',
      'ALTER TABLE accounts ADD COLUMN pending_group_id TEXT DEFAULT \'\'',
      'ALTER TABLE accounts ADD COLUMN pending_requested_at INTEGER DEFAULT 0',
      'ALTER TABLE family_groups ADD COLUMN pending_members TEXT DEFAULT \'\''
    ];

    for (const sql of alterStatements) {
      try {
        await this.rdbStore.executeSql(sql);
      } catch (e) {
        // 列已存在时忽略
        console.log(`v3→v4 ALTER 跳过（列可能已存在）: ${sql.substring(0, 50)}`);
      }
    }

    console.log('v3 → v4 迁移完成');
  }

  /**
   * 生成 UUID
   * @private
   */
  private generateUUID(): string {
    const charArr: string[] = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
    const sections: number[] = [8, 4, 4, 4, 12];
    let uuid = '';
    for (const len of sections) {
      for (let i = 0; i < len; i++) {
        uuid += charArr[Math.floor(Math.random() * charArr.length)];
      }
      if (len !== 12) {
        uuid += '-';
      }
    }
    return uuid;
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

  // ==================== 帐号 CRUD (Phase 1) ====================

  /**
   * 获取本地活跃帐号
   */
  public async getActiveAccount(): Promise<UserAccount | null> {
    if (!this.rdbStore) {
      return null;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('accounts');
      predicates.equalTo('is_local_active', 1);
      const resultSet = await this.rdbStore.query(predicates, [
        'account_id', 'username', 'avatar', 'password_hash', 'account_mode',
        'family_group_id', 'parent_account_id', 'is_local_active',
        'join_status', 'pending_group_id', 'pending_requested_at',
        'created_at', 'updated_at'
      ]);
      if (resultSet && await resultSet.goToFirstRow()) {
        const account = this.parseAccountFromResultSet(resultSet);
        resultSet.close();
        return account;
      }
      if (resultSet) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`获取活跃帐号失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 根据 accountId 获取帐号
   */
  public async getAccountByAccountId(accountId: string): Promise<UserAccount | null> {
    if (!this.rdbStore) {
      return null;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('accounts');
      predicates.equalTo('account_id', accountId);
      const resultSet = await this.rdbStore.query(predicates, [
        'account_id', 'username', 'avatar', 'password_hash', 'account_mode',
        'family_group_id', 'parent_account_id', 'is_local_active',
        'join_status', 'pending_group_id', 'pending_requested_at',
        'created_at', 'updated_at'
      ]);
      if (resultSet && await resultSet.goToFirstRow()) {
        const account = this.parseAccountFromResultSet(resultSet);
        resultSet.close();
        return account;
      }
      if (resultSet) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`根据accountId获取帐号失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存帐号（INSERT OR REPLACE）
   */
  public async saveAccount(account: UserAccount): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    try {
      const now = Date.now();
      const valuesBucket: relationalStore.ValuesBucket = {
        'account_id': account.accountId,
        'username': account.username,
        'avatar': account.avatar,
        'password_hash': account.passwordHash,
        'account_mode': account.accountMode,
        'family_group_id': account.familyGroupId,
        'parent_account_id': account.parentAccountId,
        'is_local_active': account.isLocalActive ? 1 : 0,
        'join_status': account.joinStatus,
        'pending_group_id': account.pendingGroupId,
        'pending_requested_at': account.pendingRequestedAt,
        'created_at': account.createdAt || now,
        'updated_at': now
      };
      await this.rdbStore.insert('accounts', valuesBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      console.error(`保存帐号失败: ${JSON.stringify(error)}`);
      throw new Error(`保存帐号失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 更新帐号字段
   */
  public async updateAccountField(accountId: string, field: string, value: string | number): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    try {
      const predicates = new relationalStore.RdbPredicates('accounts');
      predicates.equalTo('account_id', accountId);
      const now = Date.now();
      let valuesBucket: relationalStore.ValuesBucket;
      if (field === 'is_local_active') {
        valuesBucket = { 'is_local_active': value as number, 'updated_at': now };
      } else if (field === 'family_group_id') {
        valuesBucket = { 'family_group_id': value as string, 'updated_at': now };
      } else if (field === 'parent_account_id') {
        valuesBucket = { 'parent_account_id': value as string, 'updated_at': now };
      } else if (field === 'username') {
        valuesBucket = { 'username': value as string, 'updated_at': now };
      } else if (field === 'avatar') {
        valuesBucket = { 'avatar': value as string, 'updated_at': now };
      } else if (field === 'password_hash') {
        valuesBucket = { 'password_hash': value as string, 'updated_at': now };
      } else if (field === 'account_mode') {
        valuesBucket = { 'account_mode': value as string, 'updated_at': now };
      } else if (field === 'join_status') {
        valuesBucket = { 'join_status': value as string, 'updated_at': now };
      } else if (field === 'pending_group_id') {
        valuesBucket = { 'pending_group_id': value as string, 'updated_at': now };
      } else if (field === 'pending_requested_at') {
        valuesBucket = { 'pending_requested_at': value as number, 'updated_at': now };
      } else {
        valuesBucket = { 'updated_at': now };
      }
      await this.rdbStore.update(valuesBucket, predicates);
    } catch (error) {
      console.error(`更新帐号字段失败: ${JSON.stringify(error)}`);
      throw new Error(`更新帐号字段失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 获取沟通组内所有帐号
   */
  public async getAccountsByFamilyGroup(groupId: string): Promise<UserAccount[]> {
    if (!this.rdbStore) {
      return [];
    }
    try {
      const predicates = new relationalStore.RdbPredicates('accounts');
      predicates.equalTo('family_group_id', groupId);
      const resultSet = await this.rdbStore.query(predicates, [
        'account_id', 'username', 'avatar', 'password_hash', 'account_mode',
        'family_group_id', 'parent_account_id', 'is_local_active',
        'join_status', 'pending_group_id', 'pending_requested_at',
        'created_at', 'updated_at'
      ]);
      const accounts: UserAccount[] = [];
      if (resultSet) {
        while (await resultSet.goToNextRow()) {
          accounts.push(this.parseAccountFromResultSet(resultSet));
        }
        resultSet.close();
      }
      return accounts;
    } catch (error) {
      console.error(`获取沟通组成员失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 从结果集解析帐号对象
   * @private
   */
  private parseAccountFromResultSet(resultSet: relationalStore.ResultSet): UserAccount {
    const account = new UserAccount();
    account.accountId = resultSet.getString(resultSet.getColumnIndex('account_id'));
    account.username = resultSet.getString(resultSet.getColumnIndex('username'));
    account.avatar = resultSet.getString(resultSet.getColumnIndex('avatar'));
    account.passwordHash = resultSet.getString(resultSet.getColumnIndex('password_hash'));
    const modeStr = resultSet.getString(resultSet.getColumnIndex('account_mode'));
    account.accountMode = (modeStr === 'child' ? AccountMode.CHILD : AccountMode.PARENT);
    account.familyGroupId = resultSet.getString(resultSet.getColumnIndex('family_group_id'));
    account.parentAccountId = resultSet.getString(resultSet.getColumnIndex('parent_account_id'));
    account.isLocalActive = this.getBooleanFromResultSet(resultSet, 'is_local_active');
    // v4 新增字段
    try {
      account.joinStatus = resultSet.getString(resultSet.getColumnIndex('join_status'));
    } catch (e) {
      account.joinStatus = '';
    }
    try {
      account.pendingGroupId = resultSet.getString(resultSet.getColumnIndex('pending_group_id'));
    } catch (e) {
      account.pendingGroupId = '';
    }
    try {
      account.pendingRequestedAt = resultSet.getLong(resultSet.getColumnIndex('pending_requested_at'));
    } catch (e) {
      account.pendingRequestedAt = 0;
    }
    account.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    account.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    return account;
  }

  // ==================== 按帐号隔离配置 (Phase 1) ====================

  /**
   * 保存指定帐号的配置
   */
  public async saveAccountConfig(accountId: string, configJson: string): Promise<void> {
    await this.saveConfig(`lanternlaw_config_${accountId}`, configJson);
  }

  /**
   * 获取指定帐号的配置
   */
  public async getAccountConfig(accountId: string): Promise<string | null> {
    return await this.getConfig(`lanternlaw_config_${accountId}`);
  }

  // ==================== 沟通组 CRUD (Phase 1) ====================

  /**
   * 获取沟通组
   */
  public async getFamilyGroup(groupId: string): Promise<FamilyGroup | null> {
    if (!this.rdbStore) {
      return null;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('family_groups');
      predicates.equalTo('group_id', groupId);
      const resultSet = await this.rdbStore.query(predicates, [
        'group_id', 'group_name', 'parent_account_id',
        'invitation_code', 'invitation_expires_at', 'pending_members',
        'created_at', 'updated_at'
      ]);
      if (resultSet && await resultSet.goToFirstRow()) {
        const group = this.parseFamilyGroupFromResultSet(resultSet);
        resultSet.close();
        return group;
      }
      if (resultSet) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`获取沟通组失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 保存沟通组（INSERT OR REPLACE）
   */
  public async saveFamilyGroup(group: FamilyGroup): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    try {
      const now = Date.now();
      const valuesBucket: relationalStore.ValuesBucket = {
        'group_id': group.groupId,
        'group_name': group.groupName,
        'parent_account_id': group.parentAccountId,
        'invitation_code': group.invitationCode,
        'invitation_expires_at': group.invitationExpiresAt,
        'pending_members': group.pendingMembers,
        'created_at': group.createdAt || now,
        'updated_at': now
      };
      await this.rdbStore.insert('family_groups', valuesBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      console.error(`保存沟通组失败: ${JSON.stringify(error)}`);
      throw new Error(`保存沟通组失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 根据邀请码获取沟通组（需检查过期时间）
   */
  public async getFamilyGroupByInvitationCode(code: string): Promise<FamilyGroup | null> {
    if (!this.rdbStore) {
      return null;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('family_groups');
      predicates.equalTo('invitation_code', code);
      const resultSet = await this.rdbStore.query(predicates, [
        'group_id', 'group_name', 'parent_account_id',
        'invitation_code', 'invitation_expires_at', 'pending_members',
        'created_at', 'updated_at'
      ]);
      if (resultSet && await resultSet.goToFirstRow()) {
        const group = this.parseFamilyGroupFromResultSet(resultSet);
        resultSet.close();
        // 检查邀请码是否过期
        if (group.invitationExpiresAt > 0 && Date.now() > group.invitationExpiresAt) {
          return null;
        }
        return group;
      }
      if (resultSet) {
        resultSet.close();
      }
      return null;
    } catch (error) {
      console.error(`根据邀请码获取沟通组失败: ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 从结果集解析沟通组对象
   * @private
   */
  private parseFamilyGroupFromResultSet(resultSet: relationalStore.ResultSet): FamilyGroup {
    const group = new FamilyGroup();
    group.groupId = resultSet.getString(resultSet.getColumnIndex('group_id'));
    group.groupName = resultSet.getString(resultSet.getColumnIndex('group_name'));
    group.parentAccountId = resultSet.getString(resultSet.getColumnIndex('parent_account_id'));
    group.invitationCode = resultSet.getString(resultSet.getColumnIndex('invitation_code'));
    group.invitationExpiresAt = resultSet.getLong(resultSet.getColumnIndex('invitation_expires_at'));
    // v4 新增字段
    try {
      group.pendingMembers = resultSet.getString(resultSet.getColumnIndex('pending_members'));
    } catch (e) {
      group.pendingMembers = '';
    }
    group.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    group.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    return group;
  }

  // ==================== 消息 CRUD (Phase 1) ====================

  /**
   * 保存消息
   */
  public async saveMessage(msg: FamilyMessage): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }
    try {
      const valuesBucket: relationalStore.ValuesBucket = {
        'id': msg.id,
        'sender_account_id': msg.senderAccountId,
        'receiver_account_id': msg.receiverAccountId,
        'message_type': msg.messageType,
        'content': msg.content,
        'is_read': msg.isRead ? 1 : 0,
        'created_at': msg.createdAt || Date.now()
      };
      await this.rdbStore.insert('messages', valuesBucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      console.error(`保存消息失败: ${JSON.stringify(error)}`);
      throw new Error(`保存消息失败: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 获取两个帐号之间的消息历史
   */
  public async getMessagesBetween(accountId1: string, accountId2: string): Promise<FamilyMessage[]> {
    if (!this.rdbStore) {
      return [];
    }
    try {
      const sql = `SELECT * FROM messages WHERE ` +
        `(sender_account_id = '${accountId1}' AND receiver_account_id = '${accountId2}') OR ` +
        `(sender_account_id = '${accountId2}' AND receiver_account_id = '${accountId1}') ` +
        `ORDER BY created_at DESC`;
      const resultSet = await this.rdbStore.querySql(sql);
      const messages: FamilyMessage[] = [];
      if (resultSet) {
        while (await resultSet.goToNextRow()) {
          messages.push(this.parseMessageFromResultSet(resultSet));
        }
        resultSet.close();
      }
      return messages;
    } catch (error) {
      console.error(`获取消息历史失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 获取指定帐号收到的所有消息（按时间倒序）
   */
  public async getMessagesByReceiver(accountId: string): Promise<FamilyMessage[]> {
    if (!this.rdbStore) {
      return [];
    }
    try {
      const predicates = new relationalStore.RdbPredicates('messages');
      predicates.equalTo('receiver_account_id', accountId);
      predicates.orderByDesc('created_at');
      const resultSet = await this.rdbStore.query(predicates);
      const messages: FamilyMessage[] = [];
      if (resultSet) {
        while (await resultSet.goToNextRow()) {
          messages.push(this.parseMessageFromResultSet(resultSet));
        }
        resultSet.close();
      }
      return messages;
    } catch (error) {
      console.error(`获取收到的消息失败: ${JSON.stringify(error)}`);
      return [];
    }
  }

  /**
   * 获取指定帐号的未读消息数
   */
  public async getUnreadMessageCount(accountId: string): Promise<number> {
    if (!this.rdbStore) {
      return 0;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('messages');
      predicates.equalTo('receiver_account_id', accountId);
      predicates.equalTo('is_read', 0);
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
      console.error(`获取未读消息数失败: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * 标记消息为已读
   */
  public async markMessagesAsRead(receiverAccountId: string, senderAccountId?: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates('messages');
      predicates.equalTo('receiver_account_id', receiverAccountId);
      predicates.equalTo('is_read', 0);
      if (senderAccountId) {
        predicates.equalTo('sender_account_id', senderAccountId);
      }
      const valuesBucket: relationalStore.ValuesBucket = {
        'is_read': 1
      };
      await this.rdbStore.update(valuesBucket, predicates);
    } catch (error) {
      console.error(`标记消息已读失败: ${JSON.stringify(error)}`);
    }
  }

  /**
   * 从结果集解析消息对象
   * @private
   */
  private parseMessageFromResultSet(resultSet: relationalStore.ResultSet): FamilyMessage {
    const msg = new FamilyMessage();
    msg.id = resultSet.getString(resultSet.getColumnIndex('id'));
    msg.senderAccountId = resultSet.getString(resultSet.getColumnIndex('sender_account_id'));
    msg.receiverAccountId = resultSet.getString(resultSet.getColumnIndex('receiver_account_id'));
    msg.messageType = resultSet.getString(resultSet.getColumnIndex('message_type')) as MessageType;
    msg.content = resultSet.getString(resultSet.getColumnIndex('content'));
    msg.isRead = this.getBooleanFromResultSet(resultSet, 'is_read');
    msg.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    return msg;
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
