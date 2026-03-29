/**
 * 掌灯人桌面卡片服务
 * LanternLaw Desktop Widget (FormExtension)
 *
 * 在桌面上显示灯律管控状态和倒计时
 */
import formProvider from '@ohos.app.form.formProvider';
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import Want from '@ohos.app.ability.Want';
import { Logger } from '../utils/Logger';

const TAG = 'LanternLawFormAbility';

// 配置结构体
interface WidgetConfig {
  lanternlawEnabled: boolean;
  timeRanges: TimeRangeInfo[];
}

interface TimeRangeInfo {
  startTime: string;
  endTime: string;
  enabled: boolean;
}

export default class LanternLawFormAbility extends FormExtensionAbility {

  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info(TAG, '卡片添加请求');

    const formData = this.buildFormData();

    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string): void {
    Logger.info(TAG, `卡片更新: ${formId}`);

    const formData = this.buildFormData();

    const formBindingDataObj = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, formBindingDataObj).then(() => {
      Logger.info(TAG, '卡片更新成功');
    }).catch((error: Error) => {
      Logger.warn(TAG, `卡片更新失败: ${error.message}`);
    });
  }

  onFormEvent(formId: string, message: string): void {
    Logger.info(TAG, `卡片事件: ${formId}, message: ${message}`);
  }

  onRemoveForm(formId: string): void {
    Logger.info(TAG, `卡片移除: ${formId}`);
  }

  /**
   * 构建卡片数据
   */
  private buildFormData(): Record<string, string> {
    try {
      const now = new Date();
      const timeStr = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

      // 返回默认数据 - 实际配置通过 Preferences 异步加载后 onUpdateForm 更新
      const config: WidgetConfig = this.getDefaultConfig();

      let statusText = '未设置';
      let countdownText = '';
      let statusColor = '#c0c6e9';

      if (config.lanternlawEnabled) {
        const currentMinutes = now.getHours() * 60 + now.getMinutes();

        // 检查当前是否在管控时段内
        let inRange = false;
        let endMinutes = 0;

        if (config.timeRanges.length > 0) {
          for (let i = 0; i < config.timeRanges.length; i++) {
            const range = config.timeRanges[i];
            if (!range.enabled) {
              continue;
            }
            const startMin = this.timeToMinutes(range.startTime);
            const endMin = this.timeToMinutes(range.endTime);

            if (endMin >= startMin) {
              if (currentMinutes >= startMin && currentMinutes < endMin) {
                inRange = true;
                endMinutes = endMin;
                break;
              }
            } else {
              if (currentMinutes >= startMin || currentMinutes < endMin) {
                inRange = true;
                if (currentMinutes >= startMin) {
                  endMinutes = endMin + 1440;
                } else {
                  endMinutes = endMin;
                }
                break;
              }
            }
          }
        }

        if (inRange) {
          statusText = '灯律进行中';
          statusColor = '#ffd166';

          const remaining = endMinutes - currentMinutes;
          if (remaining > 0) {
            const hours = Math.floor(remaining / 60);
            const minutes = remaining % 60;
            if (hours > 0) {
              countdownText = `${hours}小时${minutes}分后解锁`;
            } else {
              countdownText = `${minutes}分钟后解锁`;
            }
          }
        } else {
          statusText = '自由时段';
          statusColor = '#4ade80';

          // 找到下一个管控时段
          if (config.timeRanges.length > 0) {
            let closestMin = -1;
            for (let i = 0; i < config.timeRanges.length; i++) {
              const range = config.timeRanges[i];
              if (!range.enabled) continue;
              const startMin = this.timeToMinutes(range.startTime);
              let diff = startMin - currentMinutes;
              if (diff <= 0) {
                diff = diff + 1440;
              }
              if (closestMin === -1 || diff < closestMin) {
                closestMin = diff;
              }
            }
            if (closestMin > 0) {
              const hours = Math.floor(closestMin / 60);
              const minutes = closestMin % 60;
              if (hours > 0) {
                countdownText = `${hours}小时${minutes}分后开始`;
              } else {
                countdownText = `${minutes}分钟后开始`;
              }
            }
          }
        }
      } else {
        statusText = '已停用';
        statusColor = 'rgba(192, 198, 233, 0.4)';
      }

      const result: Record<string, string> = {
        'title': '掌灯人',
        'time': timeStr,
        'status': statusText,
        'countdown': countdownText,
        'statusColor': statusColor
      };
      return result;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '构建卡片数据失败');
      const fallback: Record<string, string> = {
        'title': '掌灯人',
        'time': '--:--',
        'status': '加载中...',
        'countdown': '',
        'statusColor': '#c0c6e9'
      };
      return fallback;
    }
  }

  /**
   * 获取默认配置
   */
  private getDefaultConfig(): WidgetConfig {
    const config: WidgetConfig = {
      lanternlawEnabled: true,
      timeRanges: []
    };
    return config;
  }

  private timeToMinutes(timeStr: string): number {
    const parts = timeStr.split(':');
    const hours = parseInt(parts[0]);
    const minutes = parseInt(parts[1]);
    return hours * 60 + minutes;
  }
}
