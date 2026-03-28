/**
 * 应用拦截功能自动化测试用例
 *
 * 测试核心逻辑：时间匹配、 配置解析、 白名单管理
 */
import { describe, it, expect } from '@ohos/hypium';
import { TimeRangeManager } from '../../../../main/ets/models/TimeRange';
import { LanternLawConfig } from '../../../../main/ets/models/LanternLawConfig';
import { WhitelistApp, WhitelistAppManager } from '../../../../main/ets/models/WhitelistApp';

export default function appBlockingTest() {
  describe('时间工具测试', () => {
    it('timeToMinutes 正确转换', () => {
      expect(TimeRangeManager.timeToMinutes('00:00')).assertEqual(0);
      expect(TimeRangeManager.timeToMinutes('01:00')).assertEqual(60);
      expect(TimeRangeManager.timeToMinutes('12:30')).assertEqual(750);
      expect(TimeRangeManager.timeToMinutes('23:59')).assertEqual(1439);
    });

    it('minutesToTime 正确反转', () => {
      expect(TimeRangeManager.minutesToTime(0)).assertEqual('00:00');
      expect(TimeRangeManager.minutesToTime(60)).assertEqual('01:00');
      expect(TimeRangeManager.minutesToTime(750)).assertEqual('12:30');
    });
  });

  describe('时间段重叠检测', () => {
    it('不重叠返回 false', () => {
      const r1 = { id: '1', label: 'A', startTime: '08:00', endTime: '10:00', enabled: true };
      const r2 = { id: '2', label: 'B', startTime: '10:00', endTime: '12:00', enabled: true };
      expect(TimeRangeManager.isOverlapping(r1, r2)).assertFalse();
    });

    it('重叠返回 true', () => {
      const r1 = { id: '1', label: 'A', startTime: '08:00', endTime: '10:00', enabled: true };
      const r2 = { id: '2', label: 'B', startTime: '09:00', endTime: '11:00', enabled: true };
      expect(TimeRangeManager.isOverlapping(r1, r2)).assertTrue();
    });

    it('跨天重叠返回 true', () => {
      const r1 = { id: '1', label: 'A', startTime: '22:00', endTime: '06:00', enabled: true };
      const r2 = { id: '2', label: 'B', startTime: '05:00', endTime: '07:00', enabled: true };
      expect(TimeRangeManager.isOverlapping(r1, r2)).assertTrue();
    });

    it('禁用不参与检测', () => {
      const r1 = { id: '1', label: 'A', startTime: '08:00', endTime: '10:00', enabled: true };
      const r2 = { id: '2', label: 'B', startTime: '09:00', endTime: '11:00', enabled: false };
      expect(TimeRangeManager.isOverlapping(r1, r2)).assertFalse();
    });
  });

  describe('LanternLawConfig 配置', () => {
    it('默认值正确', () => {
      const config = new LanternLawConfig();
      expect(config.lanternlawEnabled).assertTrue();
      expect(config.timeRanges.length).assertEqual(0);
      expect(config.whitelistApps.length).assertEqual(0);
    });

    it('clone 产生独立副本', () => {
      const config = new LanternLawConfig();
      config.lanternlawEnabled = false;
      const cloned = config.clone();
      cloned.lanternlawEnabled = true;
      expect(config.lanternlawEnabled).assertFalse();
      expect(cloned.lanternlawEnabled).assertTrue();
    });
  });

  describe('白名单管理', () => {
    it('create 生成正确对象', () => {
      const app = WhitelistAppManager.create('com.test.app', 'Test');
      expect(app.bundleName).assertEqual('com.test.app');
      expect(app.appName).assertEqual('Test');
      expect(app.enabled).assertTrue();
    });

    it('isDuplicate 正确检测', () => {
      const apps: WhitelistApp[] = [WhitelistAppManager.create('com.test.app', 'A')];
      const dup = WhitelistAppManager.create('com.test.app', 'B');
      expect(WhitelistAppManager.isDuplicate(dup, apps)).assertTrue();
      const nonDup = WhitelistAppManager.create('com.other', 'C');
      expect(WhitelistAppManager.isDuplicate(nonDup, apps)).assertFalse();
    });

    it('removeByBundleName 正确移除' () => {
      const apps: WhitelistApp[] = [
        WhitelistAppManager.create('com.a', 'A'),
        WhitelistAppManager.create('com.b', 'B')
      ];
      const result = WhitelistAppManager.removeByBundleName('com.a', apps);
      expect(result.length).assertEqual(1);
      expect(result[0].bundleName).assertEqual('com.b');
    });
  });
}
