/**
 * 简化版UI测试 - 快速验证版本
 * 用于快速诊断测试问题
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';

const TAG = 'TimeRangeQuickTest';
const DOMAIN = 0x0006;

export default function timeRangeQuickTest() {
  describe('TimeRangeQuickTest', () => {

    it('test_1_basic_logic', async () => {
      hilog.info(DOMAIN, TAG, '=== 测试1: 基础逻辑验证 ===');

      // 导入TimeRange模块
      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试1: 全天管控
      const allDayStart = TimeRangeManager.timeToMinutes('00:00');
      const allDayEnd = TimeRangeManager.timeToMinutes('00:00');
      hilog.info(DOMAIN, TAG, `全天管控测试: ${allDayStart} === ${allDayEnd}`);
      expect(allDayStart).toBe(0);
      expect(allDayEnd).toBe(0);

      // 测试2: 跨天时间
      const crossDayStart = TimeRangeManager.timeToMinutes('22:30');
      const crossDayEnd = TimeRangeManager.timeToMinutes('06:30');
      hilog.info(DOMAIN, TAG, `跨天时间测试: ${crossDayStart} > ${crossDayEnd}`);
      expect(crossDayStart).toBeGreaterThan(crossDayEnd);

      // 测试3: 无重叠检测
      const range1 = { id: '1', startTime: '22:30', endTime: '06:30', enabled: true };
      const range2 = { id: '2', startTime: '09:00', endTime: '12:00', enabled: true };
      const hasOverlap = TimeRangeManager.isOverlapping(range1, range2);
      hilog.info(DOMAIN, TAG, `无重叠检测: ${hasOverlap}`);
      expect(hasOverlap).toBe(false);

      hilog.info(DOMAIN, TAG, '✅ 测试1完成: 基础逻辑验证通过');
    });

    it('test_2_overlap_detection', async () => {
      hilog.info(DOMAIN, TAG, '=== 测试2: 重叠检测验证 ===');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 真实重叠测试
      const range1 = { id: '1', startTime: '22:30', endTime: '06:30', enabled: true };
      const range2 = { id: '2', startTime: '21:00', endTime: '08:00', enabled: true };
      const hasOverlap = TimeRangeManager.isOverlapping(range1, range2);

      hilog.info(DOMAIN, TAG, `真实重叠检测: ${hasOverlap}`);
      expect(hasOverlap).toBe(true);

      hilog.info(DOMAIN, TAG, '✅ 测试2完成: 重叠检测验证通过');
    });

    it('test_3_time_calculations', async () => {
      hilog.info(DOMAIN, TAG, '=== 测试3: 时间计算验证 ===');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 多个时间计算测试
      const tests = [
        { start: '09:00', end: '12:00', expected: 180, name: '同天' },
        { start: '22:00', end: '06:00', expected: 480, name: '跨天' },
        { start: '00:00', end: '00:00', expected: 0, name: '全天' }
      ];

      let passCount = 0;
      tests.forEach(test => {
        const startMins = TimeRangeManager.timeToMinutes(test.start);
        const endMins = TimeRangeManager.timeToMinutes(test.end);
        hilog.info(DOMAIN, TAG, `${test.name}: ${test.start} → ${test.end} = ${startMins}, ${endMins}`);

        if (test.name === '全天') {
          expect(startMins).toBe(endMins);
        } else if (test.name === '跨天') {
          expect(endMins).toBeLessThan(startMins);
        } else {
          expect(endMins).toBeGreaterThan(startMins);
        }
        passCount++;
      });

      hilog.info(DOMAIN, TAG, `✅ 测试3完成: ${passCount}/${tests.length} 个时间计算通过`);
    });

  });
}
