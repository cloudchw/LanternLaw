/**
 * 主入口Ability
 * Main entry Ability
 */
import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { Logger } from '../utils/Logger';

export default class MainAbility extends UIAbility {
  private static readonly TAG: string = 'MainAbility';

  onCreate(want, launchParam) {
    Logger.info(MainAbility.TAG, 'MainAbility onCreate');
  }

  onDestroy() {
    Logger.info(MainAbility.TAG, 'MainAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    Logger.info(MainAbility.TAG, 'MainAbility onWindowStageCreate');

    // 设置主页面
    // Set main page
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        Logger.error(MainAbility.TAG, `Failed to load content. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      Logger.info(MainAbility.TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy() {
    Logger.info(MainAbility.TAG, 'MainAbility onWindowStageDestroy');
  }

  onForeground() {
    Logger.info(MainAbility.TAG, 'MainAbility onForeground');
  }

  onBackground() {
    Logger.info(MainAbility.TAG, 'MainAbility onBackground');
  }
}