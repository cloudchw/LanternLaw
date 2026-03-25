/**
 * 主页面 - LanternLaw
 * 携带底部导航栏的容器页面
 */
import { Logger } from '../utils/Logger';
import { HomePage } from './HomePage';
import { DataTab } from './DataTab';
import { ProfileTab } from './ProfileTab';

export interface TabItem {
  title: string;
  icon: string;
}

@Entry
@Component
export struct MainPage {
  @State currentIndex: number = 0;
  @State tabBarHeight: number = 80;

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
