// entry/src/main/ets/models/FamilyGroup.ets

/**
 * 沟通组（家庭组）模型
 * Family Group Model
 */
export class FamilyGroup {
  groupId: string = '';
  groupName: string = '';
  parentAccountId: string = '';
  invitationCode: string = '';
  invitationExpiresAt: number = 0;
  pendingMembers: string = '';    // JSON 数组，如 '["acc-1","acc-2"]'
  createdAt: number = 0;
  updatedAt: number = 0;

  toJSON(): string {
    return JSON.stringify({
      groupId: this.groupId,
      groupName: this.groupName,
      parentAccountId: this.parentAccountId,
      invitationCode: this.invitationCode,
      invitationExpiresAt: this.invitationExpiresAt,
      pendingMembers: this.pendingMembers,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt
    });
  }

  static fromJSON(json: string): FamilyGroup {
    const obj: Record<string, Object> = JSON.parse(json);
    const group = new FamilyGroup();
    group.groupId = (obj['groupId'] as string) ?? '';
    group.groupName = (obj['groupName'] as string) ?? '';
    group.parentAccountId = (obj['parentAccountId'] as string) ?? '';
    group.invitationCode = (obj['invitationCode'] as string) ?? '';
    group.invitationExpiresAt = (obj['invitationExpiresAt'] as number) ?? 0;
    group.pendingMembers = (obj['pendingMembers'] as string) ?? '';
    group.createdAt = (obj['createdAt'] as number) ?? 0;
    group.updatedAt = (obj['updatedAt'] as number) ?? 0;
    return group;
  }

  clone(): FamilyGroup {
    return FamilyGroup.fromJSON(this.toJSON());
  }
}
