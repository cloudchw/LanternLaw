/**
 * 我的 Tab - LanternLaw
 * 个人设置页面
 */
import { Logger } from '../utils/Logger';

@Component
export struct ProfileTab {
  build() {
    Column() {
      Text('⚙️ 我的设置')
        .fontSize(32)
        .fontColor('#ffd166')
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })

      Text('功能开发中...')
        .fontSize(16)
        .fontColor('#c0c6e9')
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#0f1529')
  }

  aboutToAppear() {
    Logger.info('ProfileTab', '我的 Tab 初始化');
  }
}
