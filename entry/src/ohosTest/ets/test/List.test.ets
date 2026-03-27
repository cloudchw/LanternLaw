import abilityTest from './Ability.test';
import timeRangeTest from './TimeRangeTest.test';
import timeRangeQuickTest from './TimeRangeQuickTest.test';
import timeRangeUIFullTest from './TimeRangeUIFullTest.test';
import timeRangeLogicTest from './TimeRangeLogicTest.test';

export default function testsuite() {
  abilityTest();
  timeRangeTest();
  timeRangeQuickTest();
  timeRangeUIFullTest();
  timeRangeLogicTest();
}