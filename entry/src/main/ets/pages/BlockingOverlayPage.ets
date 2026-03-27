/**
 * 拦截覆盖页面
 * App Blocking Overlay Page
 * 当用户尝试打开非白名单应用时显示此页面
 */
import { Logger } from '../utils/Logger';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';

@Entry
@Component
struct BlockingOverlayPage {
  @State blockedAppName: string = '未知应用';

  /**
   * 设置被拦截的应用名
   */
  public setBlockedAppName(name: string): void {
    this.blockedAppName = name;
  }

  /**
   * 返回掌灯人应用
   */
  private goBackToLanternLaw(): void {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const want: Want = {
        bundleName: context.abilityInfo.bundleName,
        abilityName: 'EntryAbility'
      };
      context.startAbility(want)
        .then(() => {
          Logger.info('BlockingOverlayPage', '已返回掌灯人应用');
          context.terminateSelf();
        })
        .catch((error: Error) => {
          Logger.exception('BlockingOverlayPage', error, '返回掌灯人失败');
        });
    } catch (error) {
      Logger.exception('BlockingOverlayPage', error instanceof Error ? error : new Error(String(error)), '启动失败');
    }
  }

  build() {
    Stack() {
      // 背景渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            ['#0a0e1f', 0.0],
            ['#0f1529', 0.5],
            ['#1a1f3a', 1.0]
          ]
        })

      // 内容区域
      Column() {
        // 图标
        Text('🚫')
          .fontSize(64)
          .fontColor('#ff6b6b')
          .margin({ bottom: 20 })

        // 标题
        Text('应用已被拦截')
          .fontSize(24)
          .fontColor('#ffd166')
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 12 })

        // 说明文字
        Text(`"${this.blockedAppName}" 不在白名单中`)
          .fontSize(16)
          .fontColor('#c0c6e9')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 24 })

        // 提示
        Text('灯律时段内，此应用已被拦截')
          .fontSize(14)
          .fontColor('rgba(192, 198, 233, 0.6)')
          .margin({ bottom: 32 })

        // 返回按钮
        Button('返回掌灯人')
          .width('80%')
          .height(44)
          .backgroundColor('#ffd166')
          .fontColor('#0f1529')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(22)
          .onClick(() => {
            this.goBackToLanternLaw();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
