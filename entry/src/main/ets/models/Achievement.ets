// entry/src/main/ets/models/Achievement.ets
export class Achievement {
  id: string = '';                  // 成就ID
  name: string = '';                // 成就名称
  description: string = '';         // 成就描述
  type: string = '';                // 类型: 'STREAK' | 'TOTAL' | 'SPECIAL'
  requirement: number = 0;          // 解锁要求（天数/次数）
  unlocked: boolean = false;        // 是否已解锁
  unlockedAt: number = 0;           // 解锁时间戳
  icon: string = '';                // 成就图标

  constructor(
    id: string = '',
    name: string = '',
    description: string = '',
    type: string = '',
    requirement: number = 0,
    unlocked: boolean = false,
    unlockedAt: number = 0,
    icon: string = ''
  ) {
    this.id = id;
    this.name = name;
    this.description = description;
    this.type = type;
    this.requirement = requirement;
    this.unlocked = unlocked;
    this.unlockedAt = unlockedAt;
    this.icon = icon;
  }

  // 转换为JSON
  toJSON(): string {
    return JSON.stringify({
      id: this.id,
      name: this.name,
      description: this.description,
      type: this.type,
      requirement: this.requirement,
      unlocked: this.unlocked,
      unlockedAt: this.unlockedAt,
      icon: this.icon
    });
  }

  // 从JSON解析
  static fromJSON(json: string): Achievement {
    const data = JSON.parse(json) as Record<string, Object | string | number | boolean | null | undefined>;
    const achievement = new Achievement();

    achievement.id = (data.id as string) || achievement.id;
    achievement.name = (data.name as string) || achievement.name;
    achievement.description = (data.description as string) || achievement.description;
    achievement.type = (data.type as string) || achievement.type;
    achievement.requirement = (data.requirement as number) || achievement.requirement;
    achievement.unlocked = data.unlocked !== undefined ? (data.unlocked as boolean) : achievement.unlocked;
    achievement.unlockedAt = (data.unlockedAt as number) || achievement.unlockedAt;
    achievement.icon = (data.icon as string) || achievement.icon;

    return achievement;
  }

  // 深拷贝方法
  clone(): Achievement {
    const achievement = new Achievement();
    achievement.id = this.id;
    achievement.name = this.name;
    achievement.description = this.description;
    achievement.type = this.type;
    achievement.requirement = this.requirement;
    achievement.unlocked = this.unlocked;
    achievement.unlockedAt = this.unlockedAt;
    achievement.icon = this.icon;
    return achievement;
  }
}