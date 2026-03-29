/**
 * 掌灯人屏幕时间守护 Extension
 * LanternLaw Time Guard Extension Ability
 *
 * 当管控策略开始/停止时由系统回调
 */
import TimeGuardExtensionAbility from '@hms.utilityApplication.screenTimeGuard.TimeGuardExtensionAbility';
import { Logger } from '../utils/Logger';

const TAG = 'TimeGuardExtension';

export default class TimeGuardExtension extends TimeGuardExtensionAbility {

  onStart(strategyName: string): Promise<void> {
    Logger.info(TAG, `策略生效: ${strategyName}`);
    return Promise.resolve();
  }

  onStop(strategyName: string): Promise<void> {
    Logger.info(TAG, `策略停止: ${strategyName}`);
    return Promise.resolve();
  }

  onUserAuthSwitchOn(): Promise<void> {
    Logger.info(TAG, '用户授权开启');
    return Promise.resolve();
  }

  onUserAuthSwitchOff(): Promise<void> {
    Logger.warn(TAG, '用户撤销授权，管控将失效');
    return Promise.resolve();
  }
}
