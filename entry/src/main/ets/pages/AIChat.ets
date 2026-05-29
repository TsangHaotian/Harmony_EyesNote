// AIChat.ets - AI 聊天 Tab 组件
import router from '@ohos.router';
import { storage } from '../utils/Storage';
import { Message, NoteItem } from '../utils/Types';
import { callDeepSeek } from '../utils/AIService';
import promptAction from '@ohos.promptAction';

@Component
export struct AIChat {
  getThemeColor: (key: string) => string = () => ''

  @State aiMessages: Message[] = []
  @State aiInput: string = ''
  @State isAIChatting: boolean = false
  @State showChatHistory: boolean = false
  @State chatHistoryList: Message[][] = []
  @State sidebarOffset: number = 1

  async aboutToAppear() {
    try {
      const savedAIChatHistory = await storage.getAIChatHistory();
      if (savedAIChatHistory && savedAIChatHistory.length > 0) {
        this.aiMessages = savedAIChatHistory;
      }
    } catch (error) {
      console.error(`加载AI对话历史失败: ${error}`);
    }
  }

  async sendAIMessage() {
    if (this.aiInput.trim().length === 0) return;

    // 检查 API Key
    const key = await storage.getApiKey();
    if (!key) {
      promptAction.showDialog({
        title: '需要配置 API Key',
        message: '请先在设置页面添加 DeepSeek API Key 才能使用 AI 功能',
        buttons: [
          { text: '去设置', color: '#007AFF' },
          { text: '取消', color: '#666666' }
        ]
      }).then((result) => {
        if (result.index === 0) {
          router.pushUrl({ url: 'pages/Settings' });
        }
      }).catch(() => {});
      return;
    }

    const userMessage: Message = { role: 'user', content: this.aiInput };
    this.aiMessages.push(userMessage);
    await storage.saveAIChatHistory(this.aiMessages);
    this.aiInput = '';
    this.isAIChatting = true;

    let notesContext = '';
    try {
      const historyNotes = await storage.getHistoryNotes();
      if (historyNotes && historyNotes.length > 0) {
        const recentNotes = historyNotes.slice(0, 20);
        notesContext = '\n\n用户的历史笔记内容（供参考）：\n';
        recentNotes.forEach((note: NoteItem, index: number) => {
          if (note.content && note.content.trim().length > 0) {
            notesContext += `笔记${index + 1}：${note.content.substring(0, 200)}${note.content.length > 200 ? '...' : ''}\n\n`;
          }
        });
        notesContext += '您可以参考这些历史笔记内容，帮助用户整理、检索或分析笔记。';
      }
    } catch (error) {
      console.error(`获取历史笔记失败: ${error}`);
    }

    const systemPrompt = `你是一个智能笔记助手，帮助用户整理、检索和分析他们的笔记内容。
你可以根据用户的历史笔记回答问题、总结内容、提取关键信息，或者帮助用户梳理思路。
请用中文回答，保持回答简洁有条理。${notesContext}`;

    try {
      const result = await callDeepSeek([
        { role: 'system', content: systemPrompt },
        ...this.aiMessages.slice(-20)
      ], 2000);

      // 先插入一条空消息占位，然后逐字追加
      const aiResponse: Message = { role: 'assistant', content: '' };
      this.aiMessages.push(aiResponse);
      // 保存含占位消息的列表（防止切页面丢消息）
      await storage.saveAIChatHistory(this.aiMessages);
      this.isAIChatting = false;

      // 打字机效果：逐字追加
      const fullText = result;
      let typingIndex = 0;
      const typeNext = () => {
        if (typingIndex < fullText.length) {
          const chunkSize = 2;
          const endIndex = Math.min(typingIndex + chunkSize, fullText.length);
          aiResponse.content += fullText.substring(typingIndex, endIndex);
          typingIndex = endIndex;
          this.aiMessages = [...this.aiMessages];
          setTimeout(typeNext, 25);
        } else {
          storage.saveAIChatHistory(this.aiMessages);
        }
      };
      setTimeout(typeNext, 50);
    } catch (error) {
      const errorMessage: Message = {
        role: 'assistant',
        content: `AI 请求失败，请检查 API Key 是否有效或网络连接`
      };
      this.aiMessages.push(errorMessage);
      await storage.saveAIChatHistory(this.aiMessages);
      this.isAIChatting = false;
    }
  }

  async saveAIMessageToNotes(content: string) {
    try {
      const now = new Date();
      const y = now.getFullYear();
      const m = (now.getMonth() + 1).toString().padStart(2, '0');
      const d = now.getDate().toString().padStart(2, '0');
      const h = now.getHours().toString().padStart(2, '0');
      const min = now.getMinutes().toString().padStart(2, '0');
      const newNote: NoteItem = { content: content.trim(), createdAt: `${y}-${m}-${d} ${h}:${min}` };
      const allNotes = await storage.getHistoryNotes();
      allNotes.unshift(newNote);
      await storage.saveHistoryNotes(allNotes);
      promptAction.showToast({ message: '已保存到历史笔记', duration: 2000 });
    } catch (error) {
      console.error(`保存AI消息到笔记失败: ${error}`);
      promptAction.showToast({ message: '保存失败，请稍后重试', duration: 2000 });
    }
  }

  async startNewChat() {
    promptAction.showDialog({
      title: '开始新对话',
      message: '确定开启新对话吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '确定', color: this.getThemeColor('accentColor') }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        if (this.aiMessages.length > 0) {
          await this.saveCurrentChatToHistory();
        }
        this.aiMessages = [];
        await storage.saveAIChatHistory([]);
        promptAction.showToast({ message: '已开始新对话', duration: 1500 });
      }
    }).catch((err: Error) => {
      console.error(`新对话确认对话框错误: ${err}`);
    });
  }

  async saveCurrentChatToHistory() {
    try {
      const historyList = await storage.getAIChatHistoryList();
      historyList.unshift([...this.aiMessages]);
      if (historyList.length > 50) historyList.splice(50);
      await storage.saveAIChatHistoryList(historyList);
    } catch (error) {
      console.error(`保存当前对话到历史记录失败: ${error}`);
    }
  }

  async loadChatHistoryList() {
    try {
      this.chatHistoryList = await storage.getAIChatHistoryList();
    } catch (error) {
      console.error(`加载历史对话列表失败: ${error}`);
      this.chatHistoryList = [];
    }
  }

  async loadChatHistory(index: number) {
    if (index >= 0 && index < this.chatHistoryList.length) {
      if (this.aiMessages.length > 0) {
        const currentChatStr = JSON.stringify(this.aiMessages);
        const isInHistory = this.chatHistoryList.some((chat: Message[]) => JSON.stringify(chat) === currentChatStr);
        if (!isInHistory) {
          await this.saveCurrentChatToHistory();
        }
      }
      this.aiMessages = [...this.chatHistoryList[index]];
      await storage.saveAIChatHistory(this.aiMessages);
      this.showChatHistory = false;
      promptAction.showToast({ message: '已加载历史对话', duration: 1500 });
    }
  }

  async deleteChatHistory(index: number) {
    promptAction.showDialog({
      title: '删除历史对话',
      message: '确定要删除这条历史对话吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF3B30' }
      ]
    }).then(async (result) => {
      if (result.index === 1) {
        this.chatHistoryList.splice(index, 1);
        await storage.saveAIChatHistoryList(this.chatHistoryList);
        promptAction.showToast({ message: '已删除历史对话', duration: 1500 });
      }
    }).catch((err: Error) => {
      console.error(`删除历史对话确认对话框错误: ${err}`);
    });
  }

  getChatTitle(chat: Message[]): string {
    if (chat.length === 0) return '空对话';
    for (let i = 0; i < chat.length; i++) {
      if (chat[i].role === 'user' && chat[i].content && chat[i].content.trim().length > 0) {
        const title = chat[i].content.trim();
        return title.length > 40 ? title.substring(0, 40) + '...' : title;
      }
    }
    for (let i = 0; i < chat.length; i++) {
      if (chat[i].content && chat[i].content.trim().length > 0) {
        const title = chat[i].content.trim();
        return title.length > 40 ? title.substring(0, 40) + '...' : title;
      }
    }
    return '空对话';
  }

  build() {
    Column() {
      // 顶部安全距离（避开摄像头区域）
      Row().width('100%').height(40).backgroundColor(this.getThemeColor('backgroundColor'))

      // 顶部标题栏
      Row() {
        Column() {
          Text('DeepSeek').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
          Text('笔记智能助手').fontSize(12).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: 12 }) {
          Image($r('app.media.ic_histo'))
            .width(42).height(42)
            .fillColor(this.getThemeColor('textColor'))
            .padding(8)
            .onClick(() => {
              if (!this.showChatHistory) {
                this.showChatHistory = true;
                this.sidebarOffset = 1;
                this.loadChatHistoryList();
                animateTo({ duration: 300, curve: 'easeOut' }, () => { this.sidebarOffset = 0; });
              } else {
                animateTo({ duration: 300, curve: 'easeIn' }, () => { this.sidebarOffset = 1; });
                setTimeout(() => { this.showChatHistory = false; }, 300);
              }
            })
          Image($r('app.media.ic_newtchat'))
            .width(42).height(42)
            .fillColor(this.getThemeColor('textColor'))
            .padding(8)
            .onClick(() => { this.startNewChat(); })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%').height(66)
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      Stack() {
        // 聊天记录
        Scroll() {
          Column() {
            ForEach(this.aiMessages, (message: Message, index: number) => {
              if (message.role === 'user') {
                Row() {
                  Blank()
                  Column() {
                    Text(message.content)
                      .fontSize(15).fontColor('#FFFFFF').lineHeight(22)
                      .backgroundColor(this.getThemeColor('accentColor'))
                      .padding({ top: 14, bottom: 14, left: 18, right: 18 })
                      .borderRadius({ topLeft: 20, topRight: 6, bottomLeft: 20, bottomRight: 20 })
                      .constraintSize({ maxWidth: '75%' })
                  }
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              } else {
                Row() {
                  Image($r('app.media.ic_ai')).width(40).height(40).borderRadius(20).margin({ right: 12 })
                  Column({ space: 6 }) {
                    Text(message.content)
                      .fontSize(15).fontColor(this.getThemeColor('textColor')).lineHeight(22)
                      .backgroundColor(this.getThemeColor('cardColor'))
                      .padding({ top: 14, bottom: 14, left: 18, right: 18 })
                      .borderRadius({ topLeft: 6, topRight: 20, bottomLeft: 20, bottomRight: 20 })
                      .constraintSize({ maxWidth: '75%' })
                      .shadow({ radius: 3, color: '#00000008', offsetX: 0, offsetY: 2 })
                    Row() {
                      Button('💾保存到笔记')
                        .fontSize(11).fontColor('#FFFFFF')
                        .backgroundColor(this.getThemeColor('accentColor'))
                        .borderRadius(10).height(26).padding({ left: 10, right: 10 })
                        .onClick(async () => { await this.saveAIMessageToNotes(message.content); })
                      Blank()
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: '75%' })
                  }
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                }
                .width('100%')
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .alignItems(VerticalAlign.Top)
              }
            })

            if (this.isAIChatting) {
              Row() {
                Image($r('app.media.ic_ai')).width(40).height(40).borderRadius(20).margin({ right: 12 })
                Column() {
                  Row() {
                    LoadingProgress().color(this.getThemeColor('accentColor')).width(18).height(18)
                    Text('AI正在思考...').fontSize(14).fontColor('#666666').margin({ left: 10 })
                  }
                  .padding({ top: 14, bottom: 14, left: 18, right: 18 })
                  .backgroundColor(this.getThemeColor('cardColor'))
                  .borderRadius({ topLeft: 6, topRight: 20, bottomLeft: 20, bottomRight: 20 })
                  .shadow({ radius: 3, color: '#00000008', offsetX: 0, offsetY: 2 })
                }
                Blank()
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 10, bottom: 10 })
              .alignItems(VerticalAlign.Top)
            }
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)

        // 历史对话侧边栏
        if (this.showChatHistory) {
          Row()
            .width('100%').height('100%')
            .backgroundColor('#00000040')
            .opacity(1 - this.sidebarOffset * 0.6)
            .onClick(() => {
              animateTo({ duration: 300, curve: 'easeIn' }, () => { this.sidebarOffset = 1; });
              setTimeout(() => { this.showChatHistory = false; }, 300);
            })

          Row() {
            Blank()
            Column() {
              Row() {
                Text('历史对话').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
                Blank()
                Image($r('app.media.ic_close')).width(42).height(42)
                  .fillColor(this.getThemeColor('textColor')).padding(8)
                  .onClick(() => {
                    animateTo({ duration: 300, curve: 'easeIn' }, () => { this.sidebarOffset = 1; });
                    setTimeout(() => { this.showChatHistory = false; }, 300);
                  })
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .backgroundColor(this.getThemeColor('cardColor'))
              .borderRadius({ topLeft: 16, topRight: 0, bottomLeft: 0, bottomRight: 0 })
              .border({ width: { bottom: 0.5 }, color: '#E5E5EA' })

              if (this.chatHistoryList.length === 0) {
                Column() {
                  Text('暂无历史对话').fontSize(14).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 100 })
                }
                .width('100%').layoutWeight(1).alignItems(HorizontalAlign.Center)
              } else {
                Scroll() {
                  Column({ space: 0 }) {
                    ForEach(this.chatHistoryList, (chat: Message[], index: number) => {
                      Column() {
                        Row() {
                          Column({ space: 4 }) {
                            Text(this.getChatTitle(chat))
                              .fontSize(15).fontColor(this.getThemeColor('textColor'))
                              .fontWeight(FontWeight.Medium).maxLines(2)
                              .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(`${chat.length} 条消息`).fontSize(12).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 4 })
                          }
                          .layoutWeight(1).alignItems(HorizontalAlign.Start)
                          Row({ space: 12 }) {
                            Image($r('app.media.ic_edit')).width(22).height(22)
                              .fillColor(this.getThemeColor('accentColor'))
                              .onClick(() => { this.loadChatHistory(index); })
                            Image($r('app.media.ic_delete')).width(22).height(22)
                              .fillColor('#FF3B30')
                              .onClick(() => { this.deleteChatHistory(index); })
                          }
                          .alignItems(VerticalAlign.Center)
                        }
                        .width('100%')
                        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
                        .onClick(() => { this.loadChatHistory(index); })
                        if (index < this.chatHistoryList.length - 1) {
                          Divider().strokeWidth(0.5).color('#E5E5EA').margin({ left: 20, right: 20 })
                        }
                      }
                      .width('100%')
                      .backgroundColor(this.getThemeColor('cardColor'))
                      .borderRadius(12)
                      .margin({ left: 12, right: 12, top: 4, bottom: 4 })
                    }, (chat: Message[], index: number) => `chat_${index}`)
                  }
                  .width('100%').padding({ top: 12, bottom: 12 })
                }
                .layoutWeight(1).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
              }
            }
            .width('75%').height('100%')
            .backgroundColor(this.getThemeColor('cardColor'))
            .borderRadius({ topLeft: 16, topRight: 0, bottomLeft: 16, bottomRight: 0 })
            .border({ width: 1, color: '#00000020' })
            .shadow({ radius: 16, color: '#00000020', offsetX: -4, offsetY: 0 })
            .translate({ x: `${this.sidebarOffset * 100}%` })
            .opacity(1 - this.sidebarOffset)
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.End)
        }
      }
      .layoutWeight(1)

      // 输入区域
      Row({ space: 12 }) {
        TextInput({ placeholder: '输入你的问题...', text: this.aiInput })
          .layoutWeight(1).height(50)
          .backgroundColor(this.getThemeColor('cardColor'))
          .borderRadius(25).padding({ left: 18, right: 18 })
          .fontSize(15).fontColor(this.getThemeColor('textColor'))
          .placeholderColor('#999999')
          .onChange((value: string) => { this.aiInput = value; })
        Button('发送')
          .width(70).height(50).fontSize(15).fontColor('#FFFFFF')
          .backgroundColor(this.getThemeColor('accentColor'))
          .borderRadius(25)
          .onClick(() => { this.sendAIMessage(); })
          .enabled(!this.isAIChatting)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })
      .backgroundColor(this.getThemeColor('backgroundColor'))
    }
    .width('100%').height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
