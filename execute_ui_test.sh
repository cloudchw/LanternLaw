#!/bin/bash

# LanternLaw UI集成测试执行辅助脚本
# 实时监控和指导UI测试执行

echo "========================================"
echo "  UI集成测试执行助手"
echo "========================================"
echo "测试时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

HDC_PATH="/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe"
BUNDLE_NAME="com.cloudchw.lanternlaw"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# 测试指导
echo -e "${CYAN}📋 测试准备检查${NC}"
echo "-------------------------------------------"

# 检查设备连接
DEVICE_COUNT=$($HDC_PATH list targets | wc -l)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ 未检测到设备或模拟器${NC}"
    echo "请先启动HarmonyOS模拟器或连接真机"
    exit 1
fi

DEVICE_ID=$($HDC_PATH list targets | head -1)
echo -e "${GREEN}✅ 设备已连接: $DEVICE_ID${NC}"

# 检查应用状态
APP_RUNNING=$($HDC_PATH shell "aa dump -a" | grep -c "$BUNDLE_NAME")
if [ "$APP_RUNNING" -gt "0" ]; then
    echo -e "${GREEN}✅ 应用正在运行${NC}"
else
    echo -e "${YELLOW}⚠️  应用未运行，正在启动...${NC}"
    $HDC_PATH shell aa start -b $BUNDLE_NAME -a EntryAbility
    sleep 3
fi

echo ""
echo -e "${CYAN}📱 测试执行指导${NC}"
echo "==========================================="
echo ""
echo -e "${MAGENTA}第一步: 导航到时间管理页面${NC}"
echo "1. 在应用中点击底部导航栏的'我的'标签"
echo "2. 向下滚动找到'时间管理'卡片"
echo "3. 确认看到默认的'夜间休息'时间段 (22:30 → 06:30)"
echo ""
read -p "按Enter键继续到下一个测试..."

echo ""
echo -e "${MAGENTA}第二步: 测试添加按钮交互${NC}"
echo "1. 点击时间管理卡片右上角的'+'圆形按钮"
echo "2. 观察是否出现新的输入行"
echo "3. 确认输入行有金色边框和浅金色背景"
echo ""
read -p "按Enter键继续到下一个测试..."

# 开始监控日志
echo ""
echo -e "${CYAN}🔍 开始监控UI交互日志...${NC}"
echo "==========================================="
echo ""

# 清除历史日志
$HDC_PATH shell hilog -r > /dev/null 2>&1

# 启动后台日志监控
(
    while true; do
        clear
        echo -e "${CYAN}📊 实时UI交互日志${NC}"
        echo "==========================================="
        echo ""
        $HDC_PATH shell "hilog -x -z 50" | grep -iE "ProfileTab|时间段|点击|选择|TimeRange|计算|重叠" | tail -20
        echo ""
        echo -e "${YELLOW}按Ctrl+C停止日志监控${NC}"
        sleep 2
    done
) &
LOG_MONITOR_PID=$!

# 捕获Ctrl+C
trap "kill $LOG_MONITOR_PID 2>/dev/null; echo ''; echo -e '${CYAN}日志监控已停止${NC}'; exit 0" INT

echo -e "${GREEN}日志监控已启动 (PID: $LOG_MONITOR_PID)${NC}"
echo ""
echo -e "${MAGENTA}第三步: 执行UI测试操作${NC}"
echo "现在在应用中执行以下操作，日志将实时显示："
echo ""
echo "📝 测试操作清单："
echo "  1. 点击起始时间选择器，选择 00:00"
echo "  2. 点击结束时间选择器，选择 00:00"
echo "  3. 观察管控时长是否显示 24.00h"
echo "  4. 点击确认按钮添加时间段"
echo "  5. 观察新时间段是否添加成功"
echo ""
echo "  6. 再次点击+按钮"
echo "  7. 测试添加跨天时间段: 22:30 → 06:30"
echo "  8. 测试添加同天时间段: 09:00 → 12:00"
echo "  9. 测试添加重叠时间段: 21:00 → 08:00 (应显示错误)"
echo "  10. 测试添加无重叠时间段: 09:00 → 12:00 (应成功)"
echo ""
echo -e "${YELLOW}⚠️  观察上方日志输出，确认操作正确执行${NC}"
echo ""

# 等待用户操作
echo -e "${CYAN}按Ctrl+C停止日志监控并完成测试${NC}"
wait $LOG_MONITOR_PID

# 测试完成
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  UI集成测试执行完成${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📋 后续步骤："
echo "1. 查看UI测试计划文档: UI_INTEGRATION_TEST_PLAN.md"
echo "2. 记录测试结果到测试报告"
echo "3. 对实际结果与预期结果进行对比"
echo "4. 记录发现的问题"
echo ""
echo "📄 相关文档："
echo "  - UI_INTEGRATION_TEST_PLAN.md (详细测试计划)"
echo "  - FINAL_TEST_SUMMARY.md (核心逻辑测试总结)"
echo "  - CORE_LOGIC_TEST_REPORT_20260326.md (核心逻辑报告)"
echo ""
