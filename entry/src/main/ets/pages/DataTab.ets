/**
 * 数据 Tab - LanternLaw
 * 历史数据分析报告
 */
import { Logger } from '../utils/Logger';

@Component
export struct DataTab {
  build() {
    Column() {
      Text('📊 数据分析')
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
    Logger.info('DataTab', '数据 Tab 初始化');
  }
}
