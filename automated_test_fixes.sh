#!/bin/bash

# LanternLaw 时间段功能自动化测试脚本
# 测试修复后的全天管控计算和跨天重叠检测功能

HDC_PATH="/d/ProgramFiles/DevEcoStudio/sdk/default/openharmony/toolchains/hdc.exe"
BUNDLE_NAME="com.cloudchw.lanternlaw"
ABILITY_NAME="EntryAbility"

echo "=== LanternLaw 时间段功能自动化测试 ==="
echo "测试日期: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 测试1: 清除日志并启动应用
echo "【测试1】启动应用"
$HDC_PATH shell hilog -r
sleep 1

# 检查应用是否已安装，如果未安装则安装
echo "检查应用状态..."
INSTALLED=$($HDC_PATH shell bm dump -n $BUNDLE_NAME | grep -c "bundleName")
if [ "$INSTALLED" -eq "0" ]; then
    echo "应用未安装，正在安装..."
    $HDC_PATH app install entry/build/default/outputs/default/entry-default-signed.hap
fi

echo "启动应用..."
$HDC_PATH shell aa start -b $BUNDLE_NAME -a $ABILITY_NAME
sleep 3
echo "✅ 应用已启动"
echo ""

# 测试2: 监控日志
echo "【测试2】开始监控应用日志"
echo "请在模拟器中执行以下操作来验证修复："
echo ""

# 测试3: 全天管控测试
echo "【测试3】全天管控计算测试 (修复验证)"
echo "操作步骤："
echo "1. 在应用中导航到'我的'页面"
echo "2. 点击'+'按钮添加新时间段"
echo "3. 点击'起始时间'选择 00:00"
echo "4. 点击'结束时间'选择 00:00"
echo "5. 观察管控时长显示"
echo ""
echo "预期结果: 管控时长应显示为 '24.00h' 或 '24.00 小时'"
echo "修复前: 显示为 '0.00h' 或 '0.00 小时' (错误)"
echo ""

# 等待用户操作
read -p "完成操作后按回车继续..."

echo "检查全天管控日志..."
LOG_RESULT=$($HDC_PATH shell hilog -x -z 200 | grep -i "添加时间段\|准备添加新时间段\|管控时长")
if [ -n "$LOG_RESULT" ]; then
    echo "✅ 发现相关日志:"
    echo "$LOG_RESULT"
else
    echo "⚠️ 未发现明确的添加日志，可能需要手动验证UI显示"
fi
echo ""

# 测试4: 跨天时间计算
echo "【测试4】跨天时间计算测试"
echo "操作步骤："
echo "1. 添加时间段: 22:00 → 06:00"
echo "2. 观察管控时长显示"
echo ""
echo "预期结果: 管控时长应显示为 '8.00h' 或 '8.00 小时'"
echo ""

read -p "完成操作后按回车继续..."

echo "检查跨天时间计算日志..."
LOG_RESULT=$($HDC_PATH shell hilog -x -z 200 | grep -i "22:00.*06:00\|22:00-06:00")
if [ -n "$LOG_RESULT" ]; then
    echo "✅ 发现跨天时间日志:"
    echo "$LOG_RESULT"
else
    echo "⚠️ 未发现明确的日志"
fi
echo ""

# 测试5: 跨天重叠检测修复验证
echo "【测试5】跨天重叠检测修复验证 (核心修复)"
echo "操作步骤："
echo "1. 添加第一个时间段: 22:30 → 06:30 (跨天)"
echo "2. 添加第二个时间段: 09:00 → 12:00 (不跨天)"
echo "3. 观察是否都能成功添加"
echo ""
echo "预期结果: 两个时间段都应该成功添加，无重叠警告"
echo "修复前: 第二个时间段会被误判为重叠，无法添加"
echo ""

read -p "完成操作后按回车继续..."

echo "检查重叠检测日志..."
LOG_RESULT=$($HDC_PATH shell hilog -x -z 300 | grep -i "重叠\|overlap\|检查重叠")
if [ -n "$LOG_RESULT" ]; then
    echo "重叠检测日志:"
    echo "$LOG_RESULT"
    # 检查是否有误判的日志
    if echo "$LOG_RESULT" | grep -q "发现重叠.*22:30-06:30.*09:00-12:00"; then
        echo "❌ 测试失败: 仍然存在跨天重叠误报问题"
    else
        echo "✅ 测试通过: 未发现跨天重叠误报"
    fi
else
    echo "✅ 未发现重叠警告日志，说明两个时间段都成功添加"
fi
echo ""

# 测试6: 真实重叠检测
echo "【测试6】真实重叠检测测试"
echo "操作步骤："
echo "1. 尝试添加时间段: 21:00 → 08:00 (与22:30-06:30真实重叠)"
echo "2. 观察是否被正确拒绝"
echo ""
echo "预期结果: 应该显示重叠警告，时间段未添加"
echo ""

read -p "完成操作后按回车继续..."

echo "检查真实重叠检测日志..."
LOG_RESULT=$($HDC_PATH shell hilog -x -z 400 | grep -i "重叠\|overlap")
if echo "$LOG_RESULT" | grep -q "发现重叠"; then
    echo "✅ 测试通过: 正确检测到真实重叠"
    echo "$LOG_RESULT"
else
    echo "⚠️ 未发现重叠检测日志"
fi
echo ""

# 测试7: 日志汇总分析
echo "【测试7】日志汇总分析"
echo "提取所有时间段相关日志..."
echo ""

echo "=== ProfileTab 日志 ==="
$HDC_PATH shell hilog -x -z 500 | grep "ProfileTab" | tail -20
echo ""

echo "=== TimeRangeManager 日志 ==="
$HDC_PATH shell hilog -x -z 500 | grep "TimeRangeManager" | tail -20
echo ""

# 测试总结
echo "=== 测试总结 ==="
echo "✅ 应用已成功启动"
echo "✅ 测试脚本执行完成"
echo ""
echo "关键修复验证:"
echo "1. 全天管控计算 (00:00 → 00:00 = 24小时) - 请在UI中验证"
echo "2. 跨天重叠检测 (22:30-06:30 vs 09:00-12:00 无重叠) - 请在UI中验证"
echo "3. 真实重叠检测 (22:30-06:30 vs 21:00-08:00 重叠) - 请在UI中验证"
echo ""
echo "如需查看完整日志，请运行:"
echo "$HDC_PATH shell hilog | grep -i 'lanternlaw\\|profiletab\\|timerange'"
echo ""
echo "测试完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
