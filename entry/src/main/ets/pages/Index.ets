import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import http from '@ohos.net.http';

interface RouterParams {
  content?: string;
  index?: number;
}

interface Message {
  role: string;
  content: string;
}

interface GeneratedTypeLiteralInterface_2 {
  content: string;
}

interface GeneratedTypeLiteralInterface_1 {
  message: GeneratedTypeLiteralInterface_2;
}

@Entry
@Component
struct Index {
  analyzedNote: string = "";
  isAnalyzing: boolean = false;
  @State currentNote: string = '';
  @State historyNotes: string[] = [];
  // 预置的模板列表
  @State defaultTemplates: string[] = [
    '会议记录模板：\n\n会议主题：\n时间：\n地点：\n参与人员：\n\n议程：\n1. \n2. \n3. \n\n待办事项：',
    '购物清单：\n\n🥬 蔬菜类：\n🥩 肉类：\n🥛 奶制品：\n🍞 主食：\n🧹 日用品：',
    '学习计划：\n\n📚 今日学习目标：\n⏰ 预计用时：\n📖 重点内容：\n✅ 完成情况：'
  ];
  @State customTemplates: string[] = [];
  @State allTemplates: string[] = [];

  // 页面加载时恢复数据
  async aboutToAppear() {
    // 获取应用上下文并初始化存储
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);

    // 加载历史笔记
    const savedNotes = await storage.getHistoryNotes();
    if (savedNotes.length > 0) {
      this.historyNotes = savedNotes;
    } else {
      // 如果没有保存的笔记，使用默认值
      this.historyNotes = ['欢迎使用眨眼笔记，这是一个快速记录工具，可以帮助您记录您的想法'];
    }

    // 加载当前笔记
    const savedCurrentNote = await storage.getCurrentNote();
    if (savedCurrentNote) {
      this.currentNote = savedCurrentNote;
    }

    // 加载自定义模板
    const savedCustomTemplates = await storage.getCustomTemplates();
    this.customTemplates = savedCustomTemplates;
    this.allTemplates = [...this.defaultTemplates, ...this.customTemplates];
  }

  // 页面返回时处理数据
  async onPageShow() {
    const result = router.getParams() as RouterParams;
    if (result && result.content !== undefined && result.index !== undefined) {
      const newContent = result.content;
      const index = result.index;
      if (index >= 0 && index < this.historyNotes.length) {
        this.historyNotes[index] = newContent;
        await storage.saveHistoryNotes(this.historyNotes);
      }
    }

    // 重新加载自定义模板
    const savedCustomTemplates = await storage.getCustomTemplates();
    this.customTemplates = savedCustomTemplates;
    this.allTemplates = [...this.defaultTemplates, ...this.customTemplates];
  }

  // 打开详情页
  openNoteDetail(note: string, index: number) {
    router.pushUrl({
      url: 'pages/NoteDetail',
      params: {
        noteContent: note,
        noteIndex: index
      }
    });
  }

  // 保存笔记
  async saveNote() {
    if (this.currentNote.trim().length === 0) {
      return;
    }

    this.historyNotes.unshift(this.currentNote.trim());
    this.currentNote = '';

    // 保存到持久化存储
    await storage.saveHistoryNotes(this.historyNotes);
    await storage.saveCurrentNote('');
  }

  // 删除笔记
  async deleteNote(index: number) {
    this.historyNotes.splice(index, 1);
    await storage.saveHistoryNotes(this.historyNotes);
  }

  // AI分析笔记内容
  async analyzeNoteWithAI() {
    if (this.currentNote.trim().length === 0) {
      return;
    }

    this.isAnalyzing = true;
    this.analyzedNote = '正在分析中...';

    const client = http.createHttp();
    try {
      const resp = await client.request(
        'https://api.deepseek.com/v1/chat/completions',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer sk-20faf5c818224258a495651e2d663907'
          },
          extraData: JSON.stringify({
            model: 'deepseek-chat',
            messages: [
              {
                role: 'system',
                content:
                '你是「专业笔记整理助手 + 注册营养师」。\n' +
                  '1. 先识别用户输入的文本类型（会议/待办/学习/买菜/其他）。\n' +
                  '2. 按对应模板输出纯文本笔记，层级用【】或①②③，禁用Markdown。\n' +
                  '3. 若信息缺失，直接补建议并标注【待确认】。\n' +
                  '4. 当检测到买菜、食材、饮食、健康相关关键词，立即切换营养师身份：\n' +
                  '   - 生成当天3餐食材清单（蔬菜/蛋白/主食/水果/调味）。\n' +
                  '   - 标注每人份量≈热量、蛋白质、关键营养素。\n' +
                  '   - 给出储存小贴士（冷藏/冷冻/常温天数）。\n' +
                  '5. 输出示例：\n' +
                  '【今日3人餐食材清单】\n' +
                  '① 蔬菜：西兰花300g（维C≈135mg）\n' +
                  '② 蛋白：去皮鸡胸400g（蛋白≈92g，低脂）\n' +
                  '③ 主食：糙米200g（低GI）\n' +
                  '④ 水果：蓝莓150g（花青素护眼）\n' +
                  '⑤ 调味：初榨橄榄油20ml\n' +
                  '储存：鸡胸分2袋冷冻，蔬菜3天内冷藏用完。\n' +
                  '【待确认】请补充用餐人数/忌口/预算/烹饪方式。'
              } as Message,
              {
                role: 'user',
                content: `请整理以下笔记内容：${this.currentNote}`
              } as Message
            ] as Message[],
            max_tokens: 500
          })
        }
      );

      if (resp.responseCode === 200) {
        interface Body {
          choices: Array<GeneratedTypeLiteralInterface_1>;
        }

        const body: Body = JSON.parse(resp.result.toString());
        this.analyzedNote = body.choices[0].message.content.trim();
        this.currentNote = this.analyzedNote;
      } else {
        this.analyzedNote = `分析失败：HTTP错误码 ${resp.responseCode}`;
      }
    } catch (err) {
      this.analyzedNote = `分析失败：${JSON.stringify(err)}`;
    } finally {
      this.isAnalyzing = false;
      client.destroy();
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('眨眼笔记')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r("app.media.ic_setting"))
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
      }
      .width('100%')
      .padding({
        left: 16,
        right: 16,
        top: 12,
        bottom: 12
      })
      .backgroundColor('#f5f5f5')

      Divider().strokeWidth(1).color('#1F000000')

      // 模板卡片（置顶显示）
      Column() {
        Text('📋 快速模板')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        Scroll() {
          Row({ space: 8 }) {
            ForEach(this.allTemplates, (template: string, index: number) => {
              Column() {
                Text(template)
                  .fontSize(12)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                  .padding(8)
                Button('使用')
                  .width('100%')
                  .height(28)
                  .fontSize(12)
                  .onClick(() => {
                    this.currentNote = template;
                  })
              }
              .width(120)
              .height(100)
              .padding(8)
              .backgroundColor('#FFF0F0F0')
              .borderRadius(8)
            })
          }
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .edgeEffect(EdgeEffect.Spring)
      }
      .padding({ top: 16, bottom: 8 })

      Divider().strokeWidth(1).color('#1F000000')

      // 当前笔记输入区
      Column() {
        Text('当前笔记')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        TextInput({ placeholder: '写下你的想法…', text: $$this.currentNote })
          .width('100%')
          .height(100)
          .backgroundColor('#FFECECEC')
          .borderRadius(8)

        Row({ space: 8 }) {
          Button('保存')
            .layoutWeight(1)
            .onClick(() => {
              this.saveNote();
            })

          Button('AI分析')
            .layoutWeight(1)
            .backgroundColor('#FF4CAF50')
            .onClick(() => {
              this.analyzeNoteWithAI();
            })
            .enabled(!this.isAnalyzing)
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding(16)

      Divider().strokeWidth(1).color('#1F000000')

      // 历史笔记列表
      Column() {
        Text('历史笔记')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 8 })

        List({ space: 8 }) {
          ForEach(this.historyNotes, (note: string, index: number) => {
            ListItem() {
              Row() {
                Text(note)
                  .fontSize(14)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
                Image($r('app.media.ic_delete'))
                  .width(18)
                  .height(18)
                  .onClick(() => {
                    this.deleteNote(index);
                  })
              }
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF5F5F5')
              .borderRadius(8)
              .onClick(() => {
                this.openNoteDetail(note, index);
              })
            }
          }, (note: string, index: number) => `${note}_${index}`)
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
      }
      .padding({ top: 8 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFFFF')
  }
}
