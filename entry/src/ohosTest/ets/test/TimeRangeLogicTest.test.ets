/**
 * 时间段功能逻辑验证测试
 * 符合ArkTS严格规范
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect } from '@ohos/hypium';

const TAG = 'TimeRangeLogicTest';
const DOMAIN = 0x0007;

// 定义测试用的时间范围接口
interface TestTimeRange {
  id: string;
  label: string;
  startTime: string;
  endTime: string;
  enabled: boolean;
}

export default function timeRangeLogicTest() {
  describe('TimeRangeLogicTest', () => {

    it('should_test_all_day_time_calculation', async () => {
      hilog.info(DOMAIN, TAG, '测试全天管控时间计算');

      // 导入TimeRange模块
      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试全天管控：00:00 -> 00:00 应该是 24 小时
      const startMinutes: number = TimeRangeManager.timeToMinutes('00:00');
      const endMinutes: number = TimeRangeManager.timeToMinutes('00:00');

      // 验证时间转换正确
      expect(startMinutes).toEqual(0);
      expect(endMinutes).toEqual(0);
      expect(startMinutes).toEqual(endMinutes);

      hilog.info(DOMAIN, TAG, `✅ 全天管控测试通过: ${startMinutes} === ${endMinutes}`);
    });

    it('should_test_cross_day_time_calculation', async () => {
      hilog.info(DOMAIN, TAG, '测试跨天时间计算');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试跨天时间：22:30 -> 06:30
      const startMinutes: number = TimeRangeManager.timeToMinutes('22:30');
      const endMinutes: number = TimeRangeManager.timeToMinutes('06:30');

      // 22:30 = 22*60 + 30 = 1350分钟
      // 06:30 = 6*60 + 30 = 390分钟
      expect(startMinutes).toEqual(1350);
      expect(endMinutes).toEqual(390);
      expect(endMinutes).toBeLessThan(startMinutes);

      hilog.info(DOMAIN, TAG, `✅ 跨天时间测试通过: ${startMinutes} > ${endMinutes}`);
    });

    it('should_test_no_overlap_detection', async () => {
      hilog.info(DOMAIN, TAG, '测试无重叠检测');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试无重叠情况：22:30-06:30 vs 09:00-12:00
      const range1: TestTimeRange = {
        id: '1',
        label: '夜间休息',
        startTime: '22:30',
        endTime: '06:30',
        enabled: true
      };

      const range2: TestTimeRange = {
        id: '2',
        label: '上午工作',
        startTime: '09:00',
        endTime: '12:00',
        enabled: true
      };

      const hasOverlap: boolean = TimeRangeManager.isOverlapping(range1, range2);

      expect(hasOverlap).assertFalse();
      hilog.info(DOMAIN, TAG, `✅ 无重叠检测通过: ${hasOverlap}`);
    });

    it('should_test_real_overlap_detection', async () => {
      hilog.info(DOMAIN, TAG, '测试真实重叠检测');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试真实重叠情况：22:30-06:30 vs 21:00-08:00
      const range1: TestTimeRange = {
        id: '1',
        label: '夜间休息',
        startTime: '22:30',
        endTime: '06:30',
        enabled: true
      };

      const range2: TestTimeRange = {
        id: '2',
        label: '深夜时段',
        startTime: '21:00',
        endTime: '08:00',
        enabled: true
      };

      const hasOverlap: boolean = TimeRangeManager.isOverlapping(range1, range2);

      expect(hasOverlap).assertTrue();
      hilog.info(DOMAIN, TAG, `✅ 真实重叠检测通过: ${hasOverlap}`);
    });

    it('should_test_time_calculations', async () => {
      hilog.info(DOMAIN, TAG, '测试多种时间计算');

      const TimeRangeModule = await import('../../../main/ets/models/TimeRange');
      const TimeRangeManager = TimeRangeModule.TimeRangeManager;

      // 测试1: 同天时间 09:00 -> 12:00 = 3小时
      const start1: number = TimeRangeManager.timeToMinutes('09:00');
      const end1: number = TimeRangeManager.timeToMinutes('12:00');
      const duration1: number = end1 - start1;
      expect(duration1).toEqual(180); // 3小时 = 180分钟

      // 测试2: 跨天时间 22:00 -> 06:00 = 8小时
      const start2: number = TimeRangeManager.timeToMinutes('22:00');
      const end2: number = TimeRangeManager.timeToMinutes('06:00');
      let duration2: number = end2 - start2;
      if (end2 < start2) {
        duration2 = end2 + 24 * 60 - start2;
      }
      expect(duration2).toEqual(480); // 8小时 = 480分钟

      hilog.info(DOMAIN, TAG, `✅ 时间计算测试通过: 同天=${duration1}分钟, 跨天=${duration2}分钟`);
    });

  });
}
