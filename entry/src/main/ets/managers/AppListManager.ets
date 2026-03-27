/**
 * 应用列表管理器
 * App List Manager
 * 用于获取系统已安装的应用列表
 */
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@ohos.base';
import { Logger } from '../utils/Logger';

/**
 * 应用信息类
 */
export class AppInfo {
  bundleName: string = '';
  appName: string = '';
  iconId: string = '';
  versionName: string = '';

  constructor(bundleName: string, appName: string, iconId?: string, versionName?: string) {
    this.bundleName = bundleName;
    this.appName = appName;
    this.iconId = iconId || '';
    this.versionName = versionName || '';
  }
}

/**
 * 应用列表管理器
 * 单例模式
 */
export class AppListManager {
  private static instance: AppListManager;
  private appListCache: AppInfo[] = [];
  private cacheTimestamp: number = 0;
  private readonly CACHE_DURATION: number = 60000; // 缓存1分钟

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): AppListManager {
    if (!AppListManager.instance) {
      AppListManager.instance = new AppListManager();
    }
    return AppListManager.instance;
  }

  /**
   * 获取已安装应用列表
   * @param forceRefresh 是否强制刷新缓存
   * @returns 应用信息列表
   */
  async getInstalledApps(forceRefresh: boolean = false): Promise<AppInfo[]> {
    // 检查缓存是否有效
    if (!forceRefresh && this.appListCache.length > 0 && (Date.now() - this.cacheTimestamp) < this.CACHE_DURATION) {
      Logger.info('AppListManager', '使用缓存的应用列表');
      return this.appListCache;
    }

    try {
      Logger.info('AppListManager', '开始获取已安装应用列表');

      // 获取当前应用包名
      const selfBundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT
      );
      const selfBundleName = selfBundleInfo.name;
      Logger.info('AppListManager', `当前应用包名: ${selfBundleName}`);

      // 使用默认应用列表作为示例
      // 在实际应用中，需要使用正确的 HarmonyOS API 获取已安装应用
      const defaultApps: AppInfo[] = [
        new AppInfo('com.huawei.contacts', '电话'),
        new AppInfo('com.huawei.mms', '短信'),
        new AppInfo('com.huawei.photos', '相册'),
        new AppInfo('com.huawei.clock', '闹钟'),
        new AppInfo('com.huawei.calendar', '日历'),
        new AppInfo('com.huawei.notepad', '备忘录'),
        new AppInfo('com.huawei.calculator', '计算器'),
        new AppInfo('com.huawei.weather', '天气'),
        new AppInfo('com.huawei.browser', '浏览器'),
        new AppInfo('com.huawei.email', '邮箱'),
        new AppInfo('com.huawei.music', '音乐'),
        new AppInfo('com.huawei.video', '视频'),
        new AppInfo('com.huawei.files', '文件管理'),
        new AppInfo('com.huawei.settings', '设置'),
        new AppInfo('com.huawei.camera', '相机')
      ];

      // 过滤掉当前应用
      const appList = defaultApps.filter(app => app.bundleName !== selfBundleName);

      // 更新缓存
      this.appListCache = appList;
      this.cacheTimestamp = Date.now();

      Logger.info('AppListManager', `应用列表包含 ${appList.length} 个应用`);
      return appList;
    } catch (error) {
      const err = error as BusinessError;
      Logger.error('AppListManager', `获取应用列表失败: code=${err.code}, message=${err.message}`);

      // 如果有缓存，返回缓存数据
      if (this.appListCache.length > 0) {
        Logger.info('AppListManager', '使用缓存数据作为降级');
        return this.appListCache;
      }

      // 返回空列表
      Logger.error('AppListManager', '无缓存数据，返回空列表');
      return [];
    }
  }

  /**
   * 根据包名获取应用信息
   * @param bundleName 应用包名
   * @returns 应用信息或null
   */
  async getAppInfo(bundleName: string): Promise<AppInfo | null> {
    try {
      const apps = await this.getInstalledApps();
      for (let i = 0; i < apps.length; i++) {
        if (apps[i].bundleName === bundleName) {
          return apps[i];
        }
      }
      return null;
    } catch (error) {
      Logger.error('AppListManager', `获取应用信息失败: ${bundleName}`);
      return null;
    }
  }

  /**
   * 搜索应用
   * @param query 搜索关键词
   * @returns 匹配的应用列表
   */
  async searchApps(query: string): Promise<AppInfo[]> {
    if (!query || query.trim() === '') {
      return this.getInstalledApps();
    }

    const apps = await this.getInstalledApps();
    const lowerQuery = query.toLowerCase().trim();
    const result: AppInfo[] = [];

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i];
      if (app.appName.toLowerCase().includes(lowerQuery) ||
          app.bundleName.toLowerCase().includes(lowerQuery)) {
        result.push(app);
      }
    }

    return result;
  }

  /**
   * 清除缓存
   */
  clearCache(): void {
    this.appListCache = [];
    this.cacheTimestamp = 0;
    Logger.info('AppListManager', '应用列表缓存已清除');
  }
}
