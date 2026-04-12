import { Logger } from '../utils/Logger';
import { FamilyMessage, MessageType } from '../models/Message';
import { MessageService, PARENT_TEMPLATES, CHILD_TEMPLATES } from '../services/MessageService';
import { AccountService } from '../services/AccountService';
import { AccountMode } from '../models/AccountMode';
import { router } from '@kit.ArkUI';

const TAG = 'MessageHistoryPage';

interface ColorScheme {
  background: string;
  card: string;
  gold: string;
  orange: string;
  text: string;
  textDim: string;
  accent: string;
  border: string;
}

const COLORS: ColorScheme = {
  background: '#0a0e1f',
  card: '#1a1f3a',
  gold: '#ffd166',
  orange: '#ff9e6d',
  text: '#e8e8f0',
  textDim: '#8888aa',
  accent: '#2a2f4a',
  border: '#2a2f4a'
};

@Entry
@Component
struct MessageHistoryPage {
  @State messages: FamilyMessage[] = [];
  @State otherUsername: string = '';
  @State otherAvatar: string = '';
  @State isLoading: boolean = true;
  @State showSendDialog: boolean = false;
  @State customMessage: string = '';
  @State isParentMode: boolean = true;

  private messageService: MessageService = MessageService.getInstance();
  private accountId: string = '';
  private otherAccountId: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    this.accountId = params['accountId'] ?? '';
    this.otherAccountId = params['otherAccountId'] ?? '';
    this.otherUsername = params['otherUsername'] ?? '对方';
    this.otherAvatar = params['otherAvatar'] ?? '😊';
    this.isParentMode = AccountService.getInstance().getActiveAccountMode() === AccountMode.PARENT;
    this.loadMessages();
  }

  private async loadMessages(): Promise<void> {
    try {
      this.messages = await this.messageService.getMessagesBetween(this.accountId, this.otherAccountId);
      // 标记为已读
      await this.messageService.markAsRead(this.accountId, this.otherAccountId);
      Logger.info(TAG, `加载了 ${this.messages.length} 条消息`);
    } catch (error) {
      Logger.error(TAG, `加载消息失败: ${JSON.stringify(error)}`);
    }
    this.isLoading = false;
  }

  private async sendMessage(content: string): Promise<void> {
    if (!content.trim()) {
      return;
    }
    await this.messageService.sendMessage(this.accountId, this.otherAccountId, content.trim());
    this.showSendDialog = false;
    this.customMessage = '';
    await this.loadMessages();
  }

  private goBack(): void {
    router.back();
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [COLORS.background, 0.0],
            ['#0f1529', 0.5],
            ['#1a1f3a', 1.0]
          ]
        })

      Column() {
        // 标题栏
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(COLORS.text)
            .onClick(() => {
              this.goBack();
            })
          Text(this.otherAvatar)
            .fontSize(24)
            .margin({ left: 8 })
          Text(this.otherUsername)
            .fontSize(18)
            .fontColor(COLORS.text)
            .fontWeight(FontWeight.Medium)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 50, bottom: 20 })

        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor(COLORS.textDim)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.messages.length === 0) {
          Column() {
            Text('💬')
              .fontSize(48)
              .margin({ bottom: 16 })
            Text('暂无消息')
              .fontSize(14)
              .fontColor(COLORS.textDim)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
              ForEach(this.messages, (msg: FamilyMessage) => {
                this.MessageBubble(msg)
              }, (msg: FamilyMessage) => msg.id)
            }
            .width('90%')
            .padding({ bottom: 100 })
          }
          .layoutWeight(1)
          .width('100%')
          .scrollable(ScrollDirection.Vertical)
          .edgeEffect(EdgeEffect.Spring)
        }

        // 底部发送栏
        Row() {
          TextInput({ placeholder: '输入消息...' })
            .layoutWeight(1)
            .height(40)
            .backgroundColor(COLORS.card)
            .fontColor(COLORS.text)
            .borderRadius(20)
            .padding({ left: 16, right: 16 })
            .onChange((value: string) => {
              this.customMessage = value;
            })

          Text('✉')
            .fontSize(24)
            .fontColor(COLORS.background)
            .margin({ left: 12 })
            .onClick(() => {
              if (this.customMessage.trim()) {
                this.sendMessage(this.customMessage);
              } else {
                this.showSendDialog = true;
              }
            })
        }
        .width('90%')
        .padding({ top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .height('100%')
      .padding({ bottom: 60 })

      // 快捷消息弹窗
      if (this.showSendDialog) {
        Column() {
          Column() {
            Text('快捷消息')
              .fontSize(18)
              .fontColor(COLORS.text)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 16 })

            Column() {
              ForEach(this.isParentMode ? PARENT_TEMPLATES : CHILD_TEMPLATES, (tpl: string) => {
                Text(tpl)
                  .fontSize(14)
                  .fontColor(COLORS.text)
                  .width('100%')
                  .padding(12)
                  .backgroundColor(COLORS.accent)
                  .borderRadius(8)
                  .margin({ bottom: 8 })
                  .onClick(() => {
                    this.sendMessage(tpl);
                  })
              }, (tpl: string) => tpl.substring(0, 10))
            }

            TextInput({ placeholder: '或输入自定义消息', text: this.customMessage })
              .width('100%')
              .height(40)
              .backgroundColor(COLORS.background)
              .fontColor(COLORS.text)
              .borderRadius(8)
              .margin({ top: 8 })
              .onChange((value: string) => {
                this.customMessage = value;
              })

            Row() {
              Button('取消')
                .layoutWeight(1)
                .height(40)
                .backgroundColor(COLORS.background)
                .fontColor(COLORS.text)
                .borderRadius(8)
                .onClick(() => {
                  this.showSendDialog = false;
                })

              Button('发送')
                .layoutWeight(1)
                .height(40)
                .backgroundColor(COLORS.gold)
                .fontColor(COLORS.background)
                .fontWeight(FontWeight.Medium)
                .borderRadius(8)
                .margin({ left: 16 })
                .onClick(() => {
                  this.sendMessage(this.customMessage);
                })
            }
            .width('100%')
            .margin({ top: 16 })
          }
          .width('85%')
          .backgroundColor(COLORS.card)
          .borderRadius(16)
          .padding(20)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.6)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showSendDialog = false;
        })
      }
    }
    .height('100%')
  }

  @Builder
  private MessageBubble(msg: FamilyMessage): void {
    Row() {
      if (msg.senderAccountId !== this.accountId) {
        Text(this.otherAvatar)
          .fontSize(28)
          .margin({ right: 8 })
      }

      Column() {
        Text(msg.content)
          .fontSize(15)
          .fontColor(msg.senderAccountId === this.accountId ? COLORS.background : COLORS.text)
          .maxLines(10)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(msg.senderAccountId === this.accountId ? HorizontalAlign.End : HorizontalAlign.Start)
      .padding(12)
      .backgroundColor(msg.senderAccountId === this.accountId ? COLORS.gold : COLORS.accent)
      .borderRadius(12)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .justifyContent(msg.senderAccountId === this.accountId ? FlexAlign.End : FlexAlign.Start)
  }
}
