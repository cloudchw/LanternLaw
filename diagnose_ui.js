/**
 * UI诊断脚本 - 收集详细的UI交互日志
 */

const { execSync } = require('child_process');

const HDC_PATH = 'D:\\ProgramFiles\\DevEcoStudio\\sdk\\default\\openharmony\\toolchains\\hdc.exe';

function log(message, color = '\x1b[0m') {
  console.log(`${color}${message}\x1b[0m`);
}

function executeCommand(command) {
  try {
    const output = execSync(command, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'] });
    return { success: true, output: output.trim() };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
  log('\n========================================', '\x1b[34m');
  log('  UI诊断 - 详细日志收集', '\x1b[34m');
  log('========================================\n', '\x1b[34m');

  // 检查应用状态
  log('📱 步骤1: 检查应用状态', '\x1b[36m');
  const appInfo = executeCommand(`${HDC_PATH} shell "aa dump -a"`);
  if (appInfo.success && appInfo.output.includes('lanternlaw')) {
    log('✅ 应用正在运行', '\x1b[32m');
  } else {
    log('❌ 应用未运行，请先启动应用', '\x1b[31m');
    return;
  }

  // 清除日志
  log('\n📱 步骤2: 清除历史日志', '\x1b[36m');
  executeCommand(`${HDC_PATH} shell "hilog -r"`);
  log('✅ 日志已清除', '\x1b[32m');

  // 指导用户操作
  log('\n========================================', '\x1b[33m');
  log('  请在应用中执行以下操作：', '\x1b[33m');
  log('========================================', '\x1b[33m');
  log('1. 点击底部导航栏的"我的"标签', '\x1b[37m');
  log('2. 向下滚动找到"时间管理"卡片', '\x1b[37m');
  log('3. 点击右上角的"+"按钮', '\x1b[37m');
  log('4. 观察是否出现新的输入行', '\x1b[37m');
  log('5. 点击"起始时间"区域', '\x1b[37m');
  log('6. 观察是否弹出时间选择器', '\x1b[37m');
  log('');

  log('⏳ 等待30秒供您操作...', '\x1b[36m');
  log('');

  // 等待用户操作
  for (let i = 30; i > 0; i--) {
    process.stdout.write(`\r倒计时: ${i}秒... `);
    await sleep(1000);
  }
  log('\r✅ 等待完成                    \n', '\x1b[32m');

  // 收集日志
  log('📊 步骤3: 收集详细日志', '\x1b[36m');
  log('----------------------------------------', '\x1b[34m');

  const logs = executeCommand(`${HDC_PATH} shell "hilog -x -z 500"`);
  if (logs.success) {
    const lines = logs.output.split('\n');

    // 筛选关键日志
    const keyPatterns = [
      'ProfileTab',
      '添加',
      '时间',
      '点击',
      'onClick',
      'showAddRangeInput',
      'AddRangeInputRow',
      'showStartTimePicker',
      'showTimePicker',
      'TimePickerModal',
      'Picker',
      'Column',
      'Row',
      'Button',
      'start_time',
      'end_time',
      'Logger',
      'LanternLaw'
    ];

    const relevantLogs = lines.filter(line => {
      const lowerLine = line.toLowerCase();
      return keyPatterns.some(pattern => lowerLine.includes(pattern.toLowerCase()));
    });

    if (relevantLogs.length > 0) {
      log(`找到 ${relevantLogs.length} 条相关日志:\n`, '\x1b[32m');
      relevantLogs.slice(0, 50).forEach(logLine => {
        log(`  ${logLine.trim()}`, '\x1b[37m');
      });
    } else {
      log('❌ 未找到相关日志', '\x1b[31m');
      log('\n这表明点击事件可能没有被触发。', '\x1b[33m');
    }

    // 检查错误日志
    const errorLogs = lines.filter(line => {
      const lowerLine = line.toLowerCase();
      return lowerLine.includes('error') ||
             lowerLine.includes('exception') ||
             lowerLine.includes('fail') ||
             lowerLine.includes('warn');
    });

    if (errorLogs.length > 0) {
      log(`\n⚠️  发现 ${errorLogs.length} 条错误/警告日志:\n`, '\x1b[33m');
      errorLogs.slice(0, 20).forEach(logLine => {
        log(`  ${logLine.trim()}`, '\x1b[31m');
      });
    }
  } else {
    log(`❌ 获取日志失败: ${logs.error}`, '\x1b[31m');
  }

  // 诊断建议
  log('\n========================================', '\x1b[34m');
  log('  诊断建议', '\x1b[34m');
  log('========================================', '\x1b[34m');

  log('\n如果"点击+"按钮后没有出现新输入行:', '\x1b[33m');
  log('  - 检查是否在"我的"页面', '\x1b[37m');
  log('  - 检查"+"按钮是否可点击', '\x1b[37m');

  log('\n如果出现输入行但点击"起始时间"没反应:', '\x1b[33m');
  log('  - 可能是 hitTestBehavior 问题', '\x1b[37m');
  log('  - 可能是 onClick 事件未绑定', '\x1b[37m');
  log('  - 可能是 showTimePicker 状态未更新', '\x1b[37m');

  log('\n如果时间选择器弹出但无法选择时间:', '\x1b[33m');
  log('  - 可能是 Select 组件问题', '\x1b[37m');
  log('  - 可能是选项数据未正确生成', '\x1b[37m');
  log('');
}

main().catch(error => {
  log(`\n❌ 诊断过程出错: ${error.message}`, '\x1b[31m');
  process.exit(1);
});
