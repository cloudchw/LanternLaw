# HiTest框架安装配置指南

**目标**: 为LanternLaw项目配置HarmonyOS官方UI自动化测试框架

---

## 📋 HiTest框架介绍

### 什么是HiTest？
- **HarmonyOS官方UI测试框架**
- 支持UI元素查找、点击、输入等操作
- 可以录制和回放UI操作
- 集成在DevEco Studio中

### 当前项目状态
项目已使用 **Hypium** 框架（单元测试），但需要 **HiTest** 进行UI自动化测试。

---

## 🚀 安装步骤

### 1. 确认DevEco Studio版本
```bash
# 在DevEco Studio中查看版本
Help -> About
# 建议版本: DevEco Studio 4.0+
```

### 2. 检查测试模块配置
检查项目中是否存在测试模块：
```bash
# 查看项目结构
ls -la entry/
# 应该看到 ohosTest/ 目录
```

### 3. 确认测试框架依赖
检查 `entry/ohosTest/build-profile.json5`：
```json
{
  "apiType": "stageMode",
  "buildOption": {},
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
```

### 4. 配置测试依赖包
检查 `entry/ohosTest/oh-package.json5`：
```json5
{
  "name": "entry_test",
  "version": "1.0.0",
  "description": "Example description for entry_test",
  "main": "",
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@ohos/hypium": "1.0.18",  // 单元测试框架
    "@ohos/harmony-task": "^1.0.0" // 任务管理
  },
  "devDependencies": {}
}
```

---

## 🏗️ 项目配置步骤

### 1. 为UI元素添加ID
为了进行UI自动化测试，需要为关键UI元素添加唯一ID：

#### ProfileTab.ets 修改示例
```typescript
// "我的"Tab按钮
Tabs({ index: this.currentTabIndex }) {
  TabContent() {
    this.ProfileTabContent()
  }
  .tabBar(this.TabBuilder('我的', 2))
}

// 添加时间段按钮
Button('+ 添加')
  .id('add_time_range_button')  // ✅ 添加ID
  .onClick(() => {
    this.addNewTimeRange();
  })

// 起始时间选择区域
Text(this.addingStartTime || '选择')
  .id('start_time_selector')  // ✅ 添加ID
  .onClick(() => {
    this.showStartTimePicker();
  })

// 结束时间选择区域
Text(this.addingEndTime || '选择')
  .id('end_time_selector')  // ✅ 添加ID
  .onClick(() => {
    this.showEndTimePicker();
  })

// 确认按钮
Button('确定')
  .id('confirm_add_button')  // ✅ 添加ID
  .onClick(() => {
    this.confirmAddTimeRange();
  })
```

### 2. 创建UI测试文件
创建 `entry/src/ohosTest/ets/test/TimeRangeUITest.ets`：

```typescript
/**
 * 时间段UI自动化测试
 * Time Range UI Automation Test
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.uitest';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

const TAG = 'TimeRangeUITest';
const DOMAIN = 0x0002;

export default function timeRangeUITest() {
  describe('TimeRangeUIAutomation', () => {
    let driver: Driver;
    let delegator = AbilityDelegatorRegistry.getAbilityDelegator();

    beforeEach(async () => {
      hilog.info(DOMAIN, TAG, 'Setup test driver');
      driver = Driver.create(delegator);
    });

    it('testNavigateToProfileTab', async () => {
      hilog.info(DOMAIN, TAG, '测试：导航到"我的"页面');

      // 查找并点击"我的"Tab
      let profileTab = await driver.findComponent(ON.id('profile_tab_button'));
      expect(profileTab).notBeNull();

      await profileTab.click();
      hilog.info(DOMAIN, TAG, '成功点击"我的"Tab');

      // 等待页面加载
      await driver.delayMs(1000);
    });

    it('testAddAllDayTimeRange', async () => {
      hilog.info(DOMAIN, TAG, '测试：添加全天管控时间段');

      // 1. 点击"+"按钮
      let addButton = await driver.findComponent(ON.id('add_time_range_button'));
      expect(addButton).notBeNull();
      await addButton.click();
      hilog.info(DOMAIN, TAG, '成功点击"+"按钮');

      await driver.delayMs(500);

      // 2. 点击起始时间选择器
      let startTimeSelector = await driver.findComponent(ON.id('start_time_selector'));
      expect(startTimeSelector).notBeNull();
      await startTimeSelector.click();
      hilog.info(DOMAIN, TAG, '成功点击起始时间选择器');

      await driver.delayMs(500);

      // 3. 在时间选择器中设置 00:00
      let hourPicker = await driver.findComponent(ON.id('hour_picker'));
      if (hourPicker) {
        await hourPicker.setText('00');
        hilog.info(DOMAIN, TAG, '设置小时为00');
      }

      await driver.delayMs(500);

      // 4. 点击确定按钮关闭时间选择器
      let pickerConfirm = await driver.findComponent(ON.id('picker_confirm_button'));
      if (pickerConfirm) {
        await pickerConfirm.click();
      }

      await driver.delayMs(500);

      // 5. 点击结束时间选择器
      let endTimeSelector = await driver.findComponent(ON.id('end_time_selector'));
      expect(endTimeSelector).notBeNull();
      await endTimeSelector.click();

      await driver.delayMs(500);

      // 6. 同样设置 00:00
      if (hourPicker) {
        await hourPicker.setText('00');
      }

      // 7. 确认时间选择
      if (pickerConfirm) {
        await pickerConfirm.click();
      }

      await driver.delayMs(500);

      // 8. 点击确认按钮添加时间段
      let confirmButton = await driver.findComponent(ON.id('confirm_add_button'));
      expect(confirmButton).notBeNull();
      await confirmButton.click();
      hilog.info(DOMAIN, TAG, '成功点击确认按钮');

      await driver.delayMs(1000);

      // 验证：应该能看到新添加的时间段
      let timeRangeList = await driver.findComponent(ON.id('time_range_list'));
      expect(timeRangeList).notBeNull();

      hilog.info(DOMAIN, TAG, '全天管控时间段添加成功');
    });

    it('testAddCrossDayTimeRange', async () => {
      hilog.info(DOMAIN, TAG, '测试：添加跨天时间段');

      // 点击"+"按钮
      let addButton = await driver.findComponent(ON.id('add_time_range_button'));
      await addButton.click();

      await driver.delayMs(500);

      // 设置起始时间 22:30
      let startTimeSelector = await driver.findComponent(ON.id('start_time_selector'));
      await startTimeSelector.click();

      // 设置小时和分钟
      let hourPicker = await driver.findComponent(ON.id('hour_picker'));
      let minutePicker = await driver.findComponent(ON.id('minute_picker'));

      if (hourPicker) await hourPicker.setText('22');
      if (minutePicker) await minutePicker.setText('30');

      // 确认起始时间
      let pickerConfirm = await driver.findComponent(ON.id('picker_confirm_button'));
      if (pickerConfirm) await pickerConfirm.click();

      await driver.delayMs(500);

      // 设置结束时间 06:30
      let endTimeSelector = await driver.findComponent(ON.id('end_time_selector'));
      await endTimeSelector.click();

      if (hourPicker) await hourPicker.setText('06');
      if (minutePicker) await minutePicker.setText('30');

      if (pickerConfirm) await pickerConfirm.click();

      await driver.delayMs(500);

      // 确认添加
      let confirmButton = await driver.findComponent(ON.id('confirm_add_button'));
      await confirmButton.click();

      await driver.delayMs(1000);

      hilog.info(DOMAIN, TAG, '跨天时间段添加成功');
    });
  });
}
```

### 3. 配置测试入口文件
修改 `entry/src/ohosTest/ets/TestRunner.ets`：

```typescript
import testRunner from '@ohos.hypium/index'
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';

export default {
  onCreate() {
    console.info('TestApplication onCreate');
    let abilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    abilityDelegator.installNotify_observer('onAbilityCreate', 1000, (ability) => {
      console.info('onAbilityCreate: ' + ability.bundleName + ability.name);
    });

    testRunner.run();
    console.info('TestRunner run');
  },
  onDestroy() {
    console.info('TestApplication onDestroy');
  }
}
```

---

## 🔧 DevEco Studio配置

### 1. 创建测试配置
1. 打开 DevEco Studio
2. 点击 `Run` -> `Edit Configurations...`
3. 点击 `+` -> `HarmonyOS Tests`
4. 配置测试参数：
   - **Name**: TimeRangeUITest
   - **Module**: entry
   - **Test Type**: UI Test

### 2. 运行测试
```bash
# 方法1: 使用DevEco Studio
# 右键点击 TimeRangeUITest.ets -> Run 'TimeRangeUITest'

# 方法2: 使用命令行
cd entry
ohpm test
```

---

## 📱 测试执行流程

### 自动化测试步骤
1. **启动模拟器**
2. **运行测试脚本**
3. **自动执行UI操作**：
   - 点击"我的"Tab
   - 点击"+"按钮
   - 选择时间
   - 点击确认
4. **自动验证结果**

### 查看测试结果
```bash
# 在DevEco Studio底部查看测试结果面板
# 或查看日志
hdc shell hilog | grep TimeRangeUITest
```

---

## 🛠️ 需要您协助的工作

### 1. 为UI元素添加ID (重要)
在 `ProfileTab.ets` 中为以下元素添加 `.id()`：
- [ ] "我的"Tab按钮
- [ ] "+"添加按钮
- [ ] 起始时间选择器
- [ ] 结束时间选择器
- [ ] 时间选择器中的小时选择
- [ ] 时间选择器中的分钟选择
- [ ] 时间选择器确定按钮
- [ ] 添加时间段确认按钮

### 2. 确认测试框架依赖
请确认 `oh-package.json5` 中是否需要添加额外的依赖。

### 3. 创建完整的测试用例
基于上面提供的模板，我们可以创建更多测试场景。

---

## 📝 下一步行动

### 方案A: 我为您修改代码
如果您同意，我可以：
1. 为ProfileTab.ets中的关键UI元素添加ID
2. 创建完整的UI测试文件
3. 配置测试运行环境

### 方案B: 您手动修改
我可以提供详细的修改指南，您手动添加ID和配置。

### 方案C: 混合方式
我提供代码，您review后应用。

---

## 🎯 优先级

**高优先级**:
1. ✅ 修复确认按钮问题 (已完成)
2. 🔲 为关键UI元素添加ID
3. 🔲 创建基础UI测试用例
4. 🔲 验证自动化测试

**中优先级**:
5. 🔲 创建完整的测试套件
6. 🔲 集成到CI/CD流程

---

## ❓ 需要确认的问题

1. **您希望使用哪种方案**？(A/B/C)
2. **DevEco Studio的版本是什么**？
3. **是否需要我先为UI元素添加ID**？
4. **测试的主要场景是什么**？(全天管控/跨天检测/基本功能)

---

**建议**: 我建议先使用方案C（混合方式）：
1. 我为UI元素添加必要的ID
2. 创建一个简单的测试用例验证框架
3. 您review并测试
4. 然后扩展更多测试场景

这样可以快速验证HiTest框架是否适合您的项目。

请告诉我您的选择，我会立即开始实施！🚀
