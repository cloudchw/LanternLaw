/**
 * 主页面 - LanternLaw
 * 携带底部导航栏的容器页面
 */
import { Logger } from '../utils/Logger';
import { HomePage } from './HomePage';
import { DataTab } from './DataTab';
import { ProfileTab } from './ProfileTab';
import { AppBlockingService, BlockingState } from '../services/AppBlockingService';

export interface TabItem {
  title: string;
  icon: string;
}

@Entry
@Component
export struct MainPage {
  @State currentIndex: number = 0;
  @State tabBarHeight: number = 60;
  @State isBlocking: boolean = false;
  @Provide profileRefreshTrigger: number = 0;

  private tabs: TabItem[] = [
    {
      title: '首页',
      icon: '🏠'
    },
    {
      title: '数据',
      icon: '📊'
    },
    {
      title: '我的',
      icon: '⚙️'
    }
  ];

  aboutToAppear(): void {
    const blockingService = AppBlockingService.getInstance();
    this.isBlocking = blockingService.getState() === BlockingState.BLOCKING;
    Logger.info('MainPage', `页面加载，拦截状态: ${this.isBlocking}`);
  }

  onPageShow(): void {
    this.profileRefreshTrigger++;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 主内容区域
      Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
        TabContent() {
          HomePage()
        }
        .tabBar(this.getTabBarBuilder(0))

        TabContent() {
          DataTab()
        }
        .tabBar(this.getTabBarBuilder(1))

        TabContent() {
          ProfileTab()
        }
        .tabBar(this.getTabBarBuilder(2))
      }
      .width('100%')
      .height('100%')
      .barHeight(this.tabBarHeight)
      .animationDuration(200)
      .onChange((index: number) => {
        this.currentIndex = index;
        Logger.info('MainPage', `切换到 Tab ${index}: ${this.tabs[index].title}`);
      })

      // 拦截覆盖层 — 管控时段内切后台被拉回时显示
      if (this.isBlocking) {
        Column() {
          Text('🚫')
            .fontSize(64)
            .fontColor('#ff6b6b')
            .margin({ bottom: 20 })

          Text('应用已被拦截')
            .fontSize(24)
            .fontColor('#ffd166')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })

          Text('灯律时段内，请留在掌灯人应用中')
            .fontSize(16)
            .fontColor('#c0c6e9')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 32 })

          Button('我知道了')
            .width('80%')
            .height(44)
            .backgroundColor('#ffd166')
            .fontColor('#0f1529')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(22)
            .onClick(() => {
              this.isBlocking = false;
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .linearGradient({
          angle: 135,
          colors: [
            ['#0a0e1f', 0.0],
            ['#0f1529', 0.5],
            ['#1a1f3a', 1.0]
          ]
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 获取 TabBar 构建器
   */
  @Builder
  getTabBarBuilder(index: number): void {
    Column({ space: 4 }) {
      Text(this.tabs[index].icon)
        .fontSize(24)
        .fontColor(this.currentIndex === index ? '#ffd166' : 'rgba(192, 198, 233, 0.6)')
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })

      Text(this.tabs[index].title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#ffd166' : 'rgba(192, 198, 233, 0.6)')
        .fontWeight(this.currentIndex === index ? FontWeight.Medium : FontWeight.Normal)
        .animation({
          duration: 200,
          curve: Curve.EaseInOut
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.currentIndex === index ? 'rgba(255, 209, 102, 0.08)' : 'transparent')
  }
}
