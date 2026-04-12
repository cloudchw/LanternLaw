// entry/src/main/ets/pages/FamilyGroupPage.ets

/**
 * 沟通组管理页面
 * 家长可创建沟通组、管理邀请码、查看/移除成员
 */
import { FamilyGroup } from '../models/FamilyGroup';
import { UserAccount } from '../models/UserAccount';
import { AccountMode } from '../models/AccountMode';
import { FamilyGroupService } from '../services/FamilyGroupService';
import { AccountService } from '../services/AccountService';
import { ConfigSyncService } from '../services/ConfigSyncService';
import { WhitelistRequestObj } from '../models/cloud/CloudObjectTypes';
import { Logger } from '../utils/Logger';
import { pasteboard } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

const TAG = 'FamilyGroupPage';

interface PageColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

interface WhitelistRequestDisplay {
  requestId: string;
  childAccountId: string;
  childName: string;
  childAvatar: string;
  appCount: number;
  createdAt: number;
}

@Entry({ routeName: 'FamilyGroupPage' })
@Component
struct FamilyGroupPage {
  @State familyGroup: FamilyGroup | null = null;
  @State members: UserAccount[] = [];
  @State pendingMembers: UserAccount[] = [];
  @State invitationCode: string = '';
  @State codeExpiresText: string = '';
  @State showCreateGroup: boolean = false;
  @State groupNameInput: string = '';
  @State createGroupError: string = '';
  @State showToast: boolean = false;
  @State toastMessage: string = '';
  @State pendingWhitelistRequests: WhitelistRequestDisplay[] = [];

  private familyGroupService: FamilyGroupService = FamilyGroupService.getInstance();
  private readonly COLORS: PageColorScheme = {
    background: '#0f1529',
    card: 'rgba(26, 31, 58, 0.8)',
    gold: '#ffd166',
    orange: '#ff9e6d',
    text: '#c0c6e9',
    textDim: 'rgba(192, 198, 233, 0.4)',
    accent: 'rgba(255, 209, 102, 0.1)',
    border: 'rgba(255, 209, 102, 0.15)'
  };

  async aboutToAppear() {
    await this.loadGroup();
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#0a0e1f', 0.0], ['#0f1529', 0.5], ['#1a1f3a', 1.0]]
        })

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(this.COLORS.text)
            .margin({ right: 16 })
            .onClick(() => {
              this.goBack();
            })
          Text('沟通组管理')
            .fontSize(20)
            .fontColor(this.COLORS.text)
            .fontWeight(FontWeight.Bold)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        Scroll() {
          Column() {
            if (this.familyGroup) {
              // 已有沟通组
              this.GroupInfoCard()
              this.InvitationCodeCard()
              this.MembersCard()
              if (this.pendingMembers.length > 0) {
                this.PendingMembersCard()
              }
              if (this.pendingWhitelistRequests.length > 0) {
                this.PendingWhitelistCard()
              }
            } else {
              // 未创建沟通组
              this.NoGroupCard()
            }
          }
          .width('90%')
          .padding({ bottom: 100 })
        }
        .layoutWeight(1)
        .width('100%')
        .scrollable(ScrollDirection.Vertical)
        .edgeEffect(EdgeEffect.Spring)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })

      // 创建沟通组弹窗
      if (this.showCreateGroup) {
        Column() {
          Column() {
            this.CreateGroupDialog()
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showCreateGroup = false;
        })
      }

      // Toast
      if (this.showToast) {
        Text(this.toastMessage)
          .fontSize(14)
          .fontColor('#ffffff')
          .backgroundColor('rgba(0,0,0,0.8)')
          .borderRadius(20)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .position({ x: '50%', y: '40%' })
          .translate({ x: '-50%' })
          .onClick(() => {
            this.showToast = false;
          })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private NoGroupCard(): void {
    Column() {
      Text('👨‍👩‍👧')
        .fontSize(48)
        .margin({ bottom: 16 })
      Text('尚未创建沟通组')
        .fontSize(18)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })
      Text('创建沟通组后，可以邀请儿童帐号加入，\n为他们设置灯律管控。')
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 32 })
      Button('创建沟通组')
        .width('60%')
        .height(44)
        .backgroundColor(this.COLORS.gold)
        .fontColor(this.COLORS.background)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .borderRadius(12)
        .onClick(() => {
          this.showCreateGroup = true;
          this.groupNameInput = '';
          this.createGroupError = '';
        })
    }
    .width('100%')
    .padding(32)
    .backgroundColor(this.COLORS.card)
    .borderRadius(16)
    .border({ width: 1, color: this.COLORS.border })
  }

  @Builder
  private GroupInfoCard(): void {
    Column() {
      Row() {
        Text('🏠')
          .fontSize(18)
          .margin({ right: 12 })
        Column({ space: 4 }) {
          Text(this.familyGroup?.groupName ?? '我的家庭')
            .fontSize(16)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Bold)
          Text(`沟通组ID: ${this.familyGroup?.groupId?.substring(0, 8) ?? ''}...`)
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.COLORS.gold })
    .margin({ bottom: 16 })
  }

  @Builder
  private InvitationCodeCard(): void {
    Column() {
      Row() {
        Text('🎟️')
          .fontSize(18)
          .margin({ right: 12 })
        Text('邀请码')
          .fontSize(16)
          .fontColor(this.COLORS.text)
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 邀请码显示
      Row() {
        Text(this.invitationCode)
          .fontSize(28)
          .fontColor(this.COLORS.gold)
          .fontWeight(FontWeight.Bold)
          .letterSpacing(8)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.COLORS.background)
      .borderRadius(8)
      .margin({ bottom: 8 })

      Text(this.codeExpiresText)
        .fontSize(12)
        .fontColor(this.COLORS.textDim)
        .margin({ bottom: 16 })

      Row() {
        Button('复制邀请码')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.COLORS.accent)
          .fontColor(this.COLORS.gold)
          .borderRadius(8)
          .onClick(() => {
            this.copyCode();
          })
        Button('刷新邀请码')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.handleRefreshCode();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  @Builder
  private MembersCard(): void {
    Column() {
      Row() {
        Text('👥')
          .fontSize(18)
          .margin({ right: 12 })
        Text('成员列表')
          .fontSize(16)
          .fontColor(this.COLORS.text)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.members.length} 人`)
          .fontSize(14)
          .fontColor(this.COLORS.textDim)
      }
      .width('100%')
      .padding({ bottom: 16 })

      // 家长（创建者）
      Row() {
        Text('👨')
          .fontSize(24)
          .margin({ right: 12 })
        Column({ space: 4 }) {
          Text(this.familyGroup?.parentAccountId ? this.getParentName() : '家长')
            .fontSize(14)
            .fontColor(this.COLORS.gold)
            .fontWeight(FontWeight.Medium)
          Text('家长（创建者）')
            .fontSize(12)
            .fontColor(this.COLORS.textDim)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      // 儿童成员
      ForEach(this.members.filter((m: UserAccount) => m.accountMode === AccountMode.CHILD), (child: UserAccount) => {
        Column()
          .width('100%')
          .height(0.5)
          .backgroundColor(this.COLORS.border)

        Row() {
          Text(child.avatar)
            .fontSize(24)
            .margin({ right: 12 })
          Column({ space: 4 }) {
            Text(child.username)
              .fontSize(14)
              .fontColor(this.COLORS.text)
              .fontWeight(FontWeight.Medium)
            Text('儿童')
              .fontSize(12)
              .fontColor(this.COLORS.orange)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Button('移除')
            .fontSize(12)
            .height(32)
            .backgroundColor('rgba(255, 107, 107, 0.15)')
            .fontColor('#ff6b6b')
            .borderRadius(16)
            .onClick(() => {
              this.handleRemoveChild(child);
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }, (child: UserAccount) => child.accountId)

      if (this.members.filter((m: UserAccount) => m.accountMode === AccountMode.CHILD).length === 0) {
        Text('暂无儿童成员')
          .fontSize(13)
          .fontColor(this.COLORS.textDim)
          .margin({ top: 12, bottom: 12 })
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.COLORS.border })
    .margin({ bottom: 16 })
  }

  @Builder
  private PendingMembersCard(): void {
    Column() {
      Row() {
        Text('📬')
          .fontSize(18)
          .margin({ right: 12 })
        Text('待确认成员')
          .fontSize(16)
          .fontColor(this.COLORS.gold)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.pendingMembers.length} 人`)
          .fontSize(14)
          .fontColor(this.COLORS.orange)
      }
      .width('100%')
      .padding({ bottom: 16 })

      ForEach(this.pendingMembers, (child: UserAccount) => {
        Row() {
          Text(child.avatar)
            .fontSize(24)
            .margin({ right: 12 })
          Column({ space: 4 }) {
            Text(child.username)
              .fontSize(14)
              .fontColor(this.COLORS.text)
              .fontWeight(FontWeight.Medium)
            Text('请求加入你的沟通组')
              .fontSize(12)
              .fontColor(this.COLORS.textDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Row({ space: 8 }) {
            Button('同意')
              .fontSize(12)
              .height(32)
              .backgroundColor('rgba(81, 207, 102, 0.2)')
              .fontColor('#51cf66')
              .borderRadius(16)
              .onClick(() => {
                this.handleApprove(child);
              })
            Button('拒绝')
              .fontSize(12)
              .height(32)
              .backgroundColor('rgba(255, 107, 107, 0.15)')
              .fontColor('#ff6b6b')
              .borderRadius(16)
              .onClick(() => {
                this.handleReject(child);
              })
          }
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }, (child: UserAccount) => child.accountId)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.COLORS.gold })
    .margin({ bottom: 16 })
  }

  @Builder
  private PendingWhitelistCard(): void {
    Column() {
      Row() {
        Text('📱')
          .fontSize(18)
          .margin({ right: 12 })
        Text('白名单修改请求')
          .fontSize(16)
          .fontColor(this.COLORS.gold)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(`${this.pendingWhitelistRequests.length} 条`)
          .fontSize(14)
          .fontColor(this.COLORS.orange)
      }
      .width('100%')
      .padding({ bottom: 16 })

      ForEach(this.pendingWhitelistRequests, (request: WhitelistRequestDisplay) => {
        Row() {
          Text(request.childAvatar)
            .fontSize(24)
            .margin({ right: 12 })
          Column({ space: 4 }) {
            Text(request.childName)
              .fontSize(14)
              .fontColor(this.COLORS.text)
              .fontWeight(FontWeight.Medium)
            Text(`请求修改白名单（${request.appCount}个应用）`)
              .fontSize(12)
              .fontColor(this.COLORS.textDim)
            Text(this.formatRequestTime(request.createdAt))
              .fontSize(11)
              .fontColor(this.COLORS.textDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Row({ space: 8 }) {
            Button('同意')
              .fontSize(12)
              .height(32)
              .backgroundColor('rgba(81, 207, 102, 0.2)')
              .fontColor('#51cf66')
              .borderRadius(16)
              .onClick(() => {
                this.handleApproveWhitelist(request);
              })
            Button('拒绝')
              .fontSize(12)
              .height(32)
              .backgroundColor('rgba(255, 107, 107, 0.15)')
              .fontColor('#ff6b6b')
              .borderRadius(16)
              .onClick(() => {
                this.handleRejectWhitelist(request);
              })
          }
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }, (request: WhitelistRequestDisplay) => request.requestId)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.COLORS.card)
    .borderRadius(12)
    .border({ width: 1, color: this.COLORS.gold })
    .margin({ bottom: 16 })
  }

  @Builder
  private CreateGroupDialog(): void {
    Column() {
      Text('创建沟通组')
        .fontSize(18)
        .fontColor(this.COLORS.text)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 24 })

      Text('给沟通组起个名字，如"李家"')
        .fontSize(14)
        .fontColor(this.COLORS.textDim)
        .margin({ bottom: 16 })

      TextInput({ placeholder: '请输入沟通组名称', text: this.groupNameInput })
        .width('100%')
        .height(44)
        .backgroundColor(this.COLORS.background)
        .fontColor(this.COLORS.text)
        .borderRadius(8)
        .onChange((value: string) => {
          this.groupNameInput = value;
          this.createGroupError = '';
        })

      if (this.createGroupError) {
        Text(this.createGroupError)
          .fontSize(12)
          .fontColor('#ff4444')
          .margin({ top: 8 })
      }

      Row() {
        Button('取消')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.COLORS.background)
          .fontColor(this.COLORS.text)
          .borderRadius(8)
          .onClick(() => {
            this.showCreateGroup = false;
          })
        Button('创建')
          .layoutWeight(1)
          .height(44)
          .backgroundColor(this.COLORS.gold)
          .fontColor(this.COLORS.background)
          .fontWeight(FontWeight.Medium)
          .borderRadius(8)
          .margin({ left: 16 })
          .onClick(() => {
            this.handleCreateGroup();
          })
      }
      .width('100%')
      .margin({ top: 24 })
    }
    .width('80%')
    .backgroundColor(this.COLORS.card)
    .borderRadius(20)
    .padding(24)
  }

  private async loadGroup(): Promise<void> {
    try {
      const accountService = AccountService.getInstance();
      const accountId = accountService.getActiveAccountId();
      if (!accountId) {
        Logger.warn(TAG, '无活跃帐号');
        return;
      }
      const group = await this.familyGroupService.getMyGroup(accountId);
      this.familyGroup = group;

      if (group) {
        this.invitationCode = group.invitationCode;
        this.updateExpiresText(group.invitationExpiresAt);
        this.members = await this.familyGroupService.getMembers(group.groupId);
        this.pendingMembers = await this.familyGroupService.getPendingJoinRequests(group.groupId);
        this.loadPendingWhitelistRequests(group.groupId, this.members);
      }
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '加载沟通组失败');
    }
  }

  private updateExpiresText(expiresAt: number): void {
    const remaining = expiresAt - Date.now();
    if (remaining <= 0) {
      this.codeExpiresText = '邀请码已过期';
    } else {
      const hours = Math.floor(remaining / (1000 * 60 * 60));
      const mins = Math.floor((remaining % (1000 * 60 * 60)) / (1000 * 60));
      if (hours > 0) {
        this.codeExpiresText = `${hours}小时${mins}分钟后过期`;
      } else {
        this.codeExpiresText = `${mins}分钟后过期`;
      }
    }
  }

  private copyCode(): void {
    const systemPasteboard = pasteboard.getSystemPasteboard();
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.invitationCode);
    systemPasteboard.setDataSync(pasteData);
    this.toastMessage = '邀请码已复制';
    this.showToast = true;
    setTimeout(() => {
      this.showToast = false;
    }, 2000);
  }

  private async handleRefreshCode(): Promise<void> {
    if (!this.familyGroup) {
      return;
    }
    try {
      this.invitationCode = await this.familyGroupService.refreshInvitationCode(this.familyGroup.groupId);
      this.updateExpiresText(Date.now() + 24 * 60 * 60 * 1000);
      this.toastMessage = '邀请码已刷新';
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '刷新邀请码失败');
    }
  }

  private async handleCreateGroup(): Promise<void> {
    const name = this.groupNameInput.trim();
    if (!name) {
      this.createGroupError = '请输入沟通组名称';
      return;
    }
    if (name.length > 20) {
      this.createGroupError = '名称不超过20个字符';
      return;
    }
    try {
      const accountService = AccountService.getInstance();
      const group = await this.familyGroupService.createGroup(name, accountService.getActiveAccountId());
      this.familyGroup = group;
      this.invitationCode = group.invitationCode;
      this.updateExpiresText(group.invitationExpiresAt);
      this.members = [];
      this.showCreateGroup = false;
      Logger.info(TAG, `沟通组创建成功: ${name}`);
    } catch (error) {
      this.createGroupError = '创建失败，请重试';
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '创建沟通组失败');
    }
  }

  private async handleRemoveChild(child: UserAccount): Promise<void> {
    try {
      await this.familyGroupService.removeChild(child.accountId);
      await this.loadGroup();
      this.toastMessage = `已移除 ${child.username}`;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '移除儿童失败');
    }
  }

  private async handleApprove(child: UserAccount): Promise<void> {
    try {
      await this.familyGroupService.approveJoinRequest(child.accountId);
      await this.loadGroup();
      this.toastMessage = `已同意 ${child.username} 加入`;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      this.toastMessage = '操作失败';
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '同意加入失败');
    }
  }

  private async handleReject(child: UserAccount): Promise<void> {
    try {
      await this.familyGroupService.rejectJoinRequest(child.accountId);
      await this.loadGroup();
      this.toastMessage = `已拒绝 ${child.username} 的请求`;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      this.toastMessage = '操作失败';
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '拒绝加入失败');
    }
  }

  private getParentName(): string {
    for (const m of this.members) {
      if (m.accountMode === AccountMode.PARENT) {
        return m.username;
      }
    }
    return '家长';
  }

  private async loadPendingWhitelistRequests(groupId: string, allMembers: UserAccount[]): Promise<void> {
    try {
      const childIds: string[] = [];
      for (const member of allMembers) {
        if (member.accountMode === AccountMode.CHILD) {
          childIds.push(member.accountId);
        }
      }
      if (childIds.length === 0) {
        this.pendingWhitelistRequests = [];
        return;
      }
      const syncService = ConfigSyncService.getInstance();
      const requests = await syncService.queryPendingWhitelistRequests(childIds);
      const displayList: WhitelistRequestDisplay[] = [];
      for (const req of requests) {
        const childMember = allMembers.find(m => m.accountId === req.childAccountId);
        const display: WhitelistRequestDisplay = {
          requestId: req.requestId,
          childAccountId: req.childAccountId,
          childName: childMember?.username ?? '未知儿童',
          childAvatar: childMember?.avatar ?? '😊',
          appCount: req.appCount,
          createdAt: req.createdAt
        };
        displayList.push(display);
      }
      this.pendingWhitelistRequests = displayList;
    } catch (error) {
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '加载待审批白名单请求失败');
    }
  }

  private async handleApproveWhitelist(request: WhitelistRequestDisplay): Promise<void> {
    try {
      const syncService = ConfigSyncService.getInstance();
      await syncService.updateWhitelistRequestStatus(request.requestId, 'approved');
      await this.loadGroup();
      this.toastMessage = `已同意 ${request.childName} 的白名单修改`;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      this.toastMessage = '操作失败';
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '同意白名单修改失败');
    }
  }

  private async handleRejectWhitelist(request: WhitelistRequestDisplay): Promise<void> {
    try {
      const syncService = ConfigSyncService.getInstance();
      await syncService.updateWhitelistRequestStatus(request.requestId, 'rejected');
      await this.loadGroup();
      this.toastMessage = `已拒绝 ${request.childName} 的白名单修改`;
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
    } catch (error) {
      this.toastMessage = '操作失败';
      this.showToast = true;
      setTimeout(() => {
        this.showToast = false;
      }, 2000);
      Logger.exception(TAG, error instanceof Error ? error : new Error(String(error)), '拒绝白名单修改失败');
    }
  }

  private formatRequestTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '';
    }
    const date = new Date(timestamp);
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hour = date.getHours().toString().padStart(2, '0');
    const minute = date.getMinutes().toString().padStart(2, '0');
    return `${month}-${day} ${hour}:${minute}`;
  }

  private goBack(): void {
    router.back();
  }
}
