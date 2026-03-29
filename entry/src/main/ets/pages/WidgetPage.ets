/**
 * 掌灯人桌面卡片 UI
 * LanternLaw Desktop Widget Page (2x2)
 *
 * 显示灯律管控状态和倒计时
 * 使用 formBindingData 获取数据
 */

@Entry
@Component
struct WidgetPage {
  @State title: string = '掌灯人';
  @State time: string = '--:--';
  @State status: string = '加载中...';
  @State countdown: string = '';
  @State statusColor: string = '#c0c6e9';

  build() {
    Column() {
      // 顶部：图标 + 标题
      Row() {
        Text('🏮')
          .fontSize(16)
        Text(this.title)
          .fontSize(14)
          .fontColor('#ffd166')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 6 })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      // 中间：状态
      Column() {
        Text(this.status)
          .fontSize(18)
          .fontColor(this.statusColor)
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .layoutWeight(1)

      // 底部：倒计时
      if (this.countdown.length > 0) {
        Text(this.countdown)
          .fontSize(12)
          .fontColor('rgba(192, 198, 233, 0.7)')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Center)
      }

      // 时间显示
      Text(this.time)
        .fontSize(11)
        .fontColor('rgba(192, 198, 233, 0.5)')
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#0f1529')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(255, 209, 102, 0.15)' })
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          from: 'widget'
        }
      });
    })
  }
}
