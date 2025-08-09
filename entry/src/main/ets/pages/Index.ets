// Index.ets - 主页面，包含底部导航栏
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
  // 底部导航栏相关状态
  @State selectedIndex: number = 0; // 0: 笔记页面, 1: 健康页面

  // 笔记页面相关状态
  analyzedNote: string = "";
  isAnalyzing: boolean = false;
  @State currentNote: string = '';
  @State historyNotes: string[] = [];
  @State defaultTemplates: string[] = [
    '会议记录模板：\n\n会议主题：\n时间：\n地点：\n参与人员：\n\n议程：\n1. \n2. \n3. \n\n待办事项：',
    '购物清单：\n\n🥬 蔬菜类：\n🥩 肉类：\n🥛 奶制品：\n🍞 主食：\n🧹 日用品：',
    '学习计划：\n\n📚 今日学习目标：\n⏰ 预计用时：\n📖 重点内容：\n✅ 完成情况：'
  ];
  @State customTemplates: string[] = [];
  @State allTemplates: string[] = [];

  // 健康页面相关状态
  @State waterCount: number = 0;
  @State sleepHours: number = 7;
  @State stepsCount: number = 0;
  @State mood: string = '开心';

  // 页面加载时恢复数据
  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);

    // 加载笔记数据
    const savedNotes = await storage.getHistoryNotes();
    if (savedNotes.length > 0) {
      this.historyNotes = savedNotes;
    } else {
      this.historyNotes = ['欢迎使用眨眼笔记，这是一个快速记录工具，可以帮助您记录您的想法'];
    }

    const savedCurrentNote = await storage.getCurrentNote();
    if (savedCurrentNote) {
      this.currentNote = savedCurrentNote;
    }

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

    const savedCustomTemplates = await storage.getCustomTemplates();
    this.customTemplates = savedCustomTemplates;
    this.allTemplates = [...this.defaultTemplates, ...this.customTemplates];
  }

  // 笔记页面方法
  openNoteDetail(note: string, index: number) {
    router.pushUrl({
      url: 'pages/NoteDetail',
      params: {
        noteContent: note,
        noteIndex: index
      }
    });
  }

  async saveNote() {
    if (this.currentNote.trim().length === 0) {
      return;
    }

    this.historyNotes.unshift(this.currentNote.trim());
    this.currentNote = '';

    await storage.saveHistoryNotes(this.historyNotes);
    await storage.saveCurrentNote('');
  }

  async deleteNote(index: number) {
    this.historyNotes.splice(index, 1);
    await storage.saveHistoryNotes(this.historyNotes);
  }

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
                content: '你是一个专业的笔记整理助手。请将用户输入的杂乱文字整理成结构清晰、格式规范的笔记。根据内容类型选择合适的模板，如会议记录、待办事项、学习笔记等。保持原意，但让格式更规范易读。'
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

  // 健康页面方法
  incrementWater() {
    this.waterCount += 1;
  }

  decrementWater() {
    if (this.waterCount > 0) {
      this.waterCount -= 1;
    }
  }

  incrementSteps() {
    this.stepsCount += 100;
  }

  decrementSteps() {
    if (this.stepsCount >= 100) {
      this.stepsCount -= 100;
    }
  }

  changeSleep(hours: number) {
    this.sleepHours = Math.max(1, Math.min(12, this.sleepHours + hours));
  }

  changeMood(newMood: string) {
    this.mood = newMood;
  }

  // 笔记页面UI
  @Builder
  NotePage() {
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

      // 模板卡片
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

  // 健康页面UI
  @Builder
  HealthPage() {
    Scroll() {
      Column({ space: 16 }) {
        // 顶部标题
        Text('健康追踪')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        // 饮水追踪
        Card() {
          Column({ space: 12 }) {
            Text('💧 今日饮水')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text(`${this.waterCount} 杯`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')

            Row({ space: 20 }) {
              Button('-')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick(() => this.decrementWater())

              Button('+')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick(() => this.incrementWater())
            }
          }
          .width('100%')
          .padding(20)
        }

        // 睡眠记录
        Card() {
          Column({ space: 12 }) {
            Text('😴 睡眠时间')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text(`${this.sleepHours} 小时`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#34C759')

            Row({ space: 20 }) {
              Button('-')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick(() => this.changeSleep(-1))

              Button('+')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick(() => this.changeSleep(1))
            }
          }
          .width('100%')
          .padding(20)
        }

        // 步数统计
        Card() {
          Column({ space: 12 }) {
            Text('🚶 今日步数')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text(`${this.stepsCount} 步`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')

            Row({ space: 20 }) {
              Button('-100')
                .width(60)
                .height(40)
                .borderRadius(20)
                .fontSize(12)
                .onClick(() => this.decrementSteps())

              Button('+100')
                .width(60)
                .height(40)
                .borderRadius(20)
                .fontSize(12)
                .onClick(() => this.incrementSteps())
            }
          }
          .width('100%')
          .padding(20)
        }

        // 心情记录
        Card() {
          Column({ space: 12 }) {
            Text('😊 今日心情')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)

            Text(this.mood)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#AF52DE')

            Row({ space: 10 }) {
              ForEach(['开心', '平静', '疲惫', '焦虑', '兴奋'], (moodOption: string) => {
                Button(moodOption)
                  .height(35)
                  .borderRadius(18)
                  .fontSize(12)
                  .backgroundColor(this.mood === moodOption ? '#AF52DE' : '#E5E5EA')
                  .onClick(() => this.changeMood(moodOption))
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
          }
          .width('100%')
          .padding(20)
        }
      }
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFF5F5F5')
  }

  build() {
    Column() {
      // 主内容区域
      Stack() {
        if (this.selectedIndex === 0) {
          this.NotePage()
        } else {
          this.HealthPage()
        }
      }
      .layoutWeight(1)

      // 底部导航栏
      Row() {
        // 笔记页面按钮
        Column() {
          Image($r('app.media.ic_edit'))
            .width(24)
            .height(24)
            .fillColor(this.selectedIndex === 0 ? '#007AFF' : '#8E8E93')
          Text('笔记')
            .fontSize(12)
            .fontColor(this.selectedIndex === 0 ? '#007AFF' : '#8E8E93')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 0;
        })
        .alignItems(HorizontalAlign.Center)

        // 健康页面按钮
        Column() {
          Image($r('app.media.ic_right'))
            .width(24)
            .height(24)
            .fillColor(this.selectedIndex === 1 ? '#007AFF' : '#8E8E93')
          Text('健康')
            .fontSize(12)
            .fontColor(this.selectedIndex === 1 ? '#007AFF' : '#8E8E93')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 1;
        })
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .border({
        width: { top: 1 },
        color: '#E5E5EA'
      })
    }
    .width('100%')
    .height('100%')
  }
}

// 卡片样式组件
@Component
struct Card {
  @BuilderParam content: () => void

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#0000001A',
      offsetX: 0,
      offsetY: 2
    })
  }
}