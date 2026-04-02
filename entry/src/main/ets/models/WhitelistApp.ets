/**
 * 白名单应用模型
 * Whitelist App Model
 * 用于存储允许在灯律时段使用的应用
 *
 * 注意: Screen Time Guard Kit 的 appToken 是不透明标识符，
 * 三方应用无法获取 token 对应的 bundleName/appName/icon。
 * 应用名称和图标展示需通过 appPicker.startAppForm() 由系统原生页面完成。
 */

/**
 * 白名单应用接口
 */
export interface WhitelistApp {
  appToken: string;    // Screen Time Guard Kit 应用令牌
  enabled: boolean;    // 是否启用
}
