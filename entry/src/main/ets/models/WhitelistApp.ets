/**
 * 白名单应用模型
 * Whitelist App Model
 * 用于存储允许在灯律时段使用的应用
 */

/**
 * 白名单应用接口
 */
export interface WhitelistApp {
  bundleName: string;    // 应用包名（唯一标识）
  appName: string;       // 应用显示名称
  iconId?: string;       // 图标资源ID（可选）
  appToken?: string;     // Screen Time Guard Kit 应用令牌（可选）
  enabled: boolean;      // 是否启用
}

/**
 * 白名单应用管理器
 * 提供创建和验证白名单应用的工具方法
 */
export class WhitelistAppManager {
  /**
   * 创建新的白名单应用
   * @param bundleName 应用包名
   * @param appName 应用显示名称
   * @param iconId 图标资源ID（可选）
   * @returns WhitelistApp 对象
   */
  static create(bundleName: string, appName: string, iconId?: string): WhitelistApp {
    return {
      bundleName,
      appName,
      iconId,
      enabled: true
    };
  }

  /**
   * 检查是否重复添加
   * @param newApp 新应用
   * @param existingApps 现有应用列表
   * @returns 是否重复
   */
  static isDuplicate(newApp: WhitelistApp, existingApps: WhitelistApp[]): boolean {
    return existingApps.some(app => app.bundleName === newApp.bundleName);
  }

  /**
   * 根据包名查找应用
   * @param bundleName 包名
   * @param apps 应用列表
   * @returns 找到的应用或undefined
   */
  static findByBundleName(bundleName: string, apps: WhitelistApp[]): WhitelistApp | undefined {
    return apps.find(app => app.bundleName === bundleName);
  }

  /**
   * 根据包名移除应用
   * @param bundleName 包名
   * @param apps 应用列表
   * @returns 移除后的新列表
   */
  static removeByBundleName(bundleName: string, apps: WhitelistApp[]): WhitelistApp[] {
    return apps.filter(app => app.bundleName !== bundleName);
  }

  /**
   * 切换应用启用状态
   * @param bundleName 包名
   * @param apps 应用列表
   * @returns 更新后的新列表
   */
  static toggleEnabled(bundleName: string, apps: WhitelistApp[]): WhitelistApp[] {
    return apps.map(app => {
      if (app.bundleName === bundleName) {
        const newApp: WhitelistApp = {
          bundleName: app.bundleName,
          appName: app.appName,
          iconId: app.iconId,
          appToken: app.appToken,
          enabled: !app.enabled
        };
        return newApp;
      }
      return app;
    });
  }
}
