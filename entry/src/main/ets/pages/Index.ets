// Index.ets - 主页面，包含底部导航栏
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import http from '@ohos.net.http';
import { HealthData } from '../utils/Types'; // 导入共享接口

interface RouterParams {
  content?: string;
  index?: number;
  healthData?: HealthData; // 使用共享接口
}

interface Message {
  role: string;
  content: string;
}

// 删除重复的 HealthData 接口定义

interface GeneratedTypeLiteralInterface_2 {
  content: string;
}

interface GeneratedTypeLiteralInterface_1 {
  message: GeneratedTypeLiteralInterface_2;
}

interface GeneratedTypeLiteralInterface_4 {
  content: string;
}

interface GeneratedTypeLiteralInterface_3 {
  message: GeneratedTypeLiteralInterface_4;
}

interface GeneratedTypeLiteralInterface_6 {
  content: string;
}

interface GeneratedTypeLiteralInterface_5 {
  message: GeneratedTypeLiteralInterface_6;
}

@Entry
@Component
struct Index {
  // 底部导航栏相关状态
  @State selectedIndex: number = 0; // 0: 笔记页面, 1: 健康页面, 2: AI页面
  // 笔记页面相关状态
  analyzedNote: string = "";
  isAnalyzing: boolean = false;
  @State showLoading: boolean = false; // 控制加载动画显示
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
  // AI页面相关状态
  @State aiMessages: Message[] = [];
  @State aiInput: string = '';
  @State isAIChatting: boolean = false;

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

    // 新增：加载健康数据
    try {
      const savedHealthData = await storage.getHealthData();
      this.waterCount = savedHealthData.waterCount || 0;
      this.sleepHours = savedHealthData.sleepHours || 7;
      this.stepsCount = savedHealthData.stepsCount || 0;
      this.mood = savedHealthData.mood || '开心';
    } catch (error) {
      console.error(`加载健康数据失败: ${error}`);
    }
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

    // 新增：保存健康数据
    await this.saveHealthData();
  }

  // 新增：保存健康数据
  async saveHealthData() {
    const healthData: HealthData = {
      waterCount: this.waterCount,
      sleepHours: this.sleepHours,
      stepsCount: this.stepsCount,
      mood: this.mood
    };
    await storage.saveHealthData(healthData); // 现在类型匹配
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
    this.showLoading = true; // 新增：显示加载动画
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
        interface DeepSeekResponse {
          choices: Array<GeneratedTypeLiteralInterface_3>;
        }

        const body: DeepSeekResponse = JSON.parse(resp.result.toString());
        this.analyzedNote = body.choices[0].message.content.trim();
        this.currentNote = this.analyzedNote;
      } else {
        this.analyzedNote = `分析失败：HTTP错误码 ${resp.responseCode}`;
      }
    } catch (err) {
      this.analyzedNote = `分析失败：${JSON.stringify(err)}`;
    } finally {
      this.isAnalyzing = false;
      this.showLoading = false; // 新增：隐藏加载动画
      client.destroy();
    }
  }

  // 健康页面方法
  incrementWater() {
    this.waterCount += 1;
    this.saveHealthData(); // 新增：保存健康数据
  }

  decrementWater() {
    if (this.waterCount > 0) {
      this.waterCount -= 1;
      this.saveHealthData(); // 新增：保存健康数据
    }
  }

  incrementSteps() {
    this.stepsCount += 100;
    this.saveHealthData(); // 新增：保存健康数据
  }

  decrementSteps() {
    if (this.stepsCount >= 100) {
      this.stepsCount -= 100;
      this.saveHealthData(); // 新增：保存健康数据
    }
  }

  changeSleep(hours: number) {
    this.sleepHours = Math.max(1, Math.min(12, this.sleepHours + hours));
    this.saveHealthData(); // 新增：保存健康数据
  }

  changeMood(newMood: string) {
    this.mood = newMood;
    this.saveHealthData(); // 新增：保存健康数据
  }

  // 新增：跳转到AI页面并传递健康数据
  goToAIPage() {
    const healthData: HealthData = {
      waterCount: this.waterCount,
      sleepHours: this.sleepHours,
      stepsCount: this.stepsCount,
      mood: this.mood
    };
    router.pushUrl({
      url: 'pages/AIPage',
      params: {
        healthData: healthData
      }
    });
  }

  // 新增：AI对话方法
  async sendAIMessage() {
    if (this.aiInput.trim().length === 0) {
      return;
    }

    // 添加用户消息
    const userMessage: Message = {
      role: 'user',
      content: this.aiInput
    };
    this.aiMessages.push(userMessage);
    this.aiInput = '';
    this.isAIChatting = true;

    // 准备健康数据
    const healthDataStr = `健康数据：
- 饮水量：${this.waterCount}杯
- 睡眠时间：${this.sleepHours}小时
- 步数：${this.stepsCount}步
- 心情：${this.mood}`;

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
                '你是「健康顾问AI助手」，你的任务是：\n'
                  + '1. 分析用户提供的健康数据（饮水量、睡眠时间、步数、心情）\n'
                  + '2. 提供个性化的健康建议和生活方式改进意见\n'
                  + '3. 回答用户关于健康、营养、运动等方面的问题\n'
                  + '4. 保持友好、专业的语气，用通俗易懂的语言解释健康知识\n'
                  + '5. 结合用户的健康数据给出具体的、可操作的建议'
              } as Message,
              ...this.aiMessages,
              {
                role: 'system',
                content: healthDataStr
              } as Message
            ] as Message[],
            max_tokens: 1000
          })
        }
      );

      if (resp.responseCode === 200) {
        interface DeepSeekResponse {
          choices: Array<GeneratedTypeLiteralInterface_5>;
        }

        const response: DeepSeekResponse = JSON.parse(resp.result.toString());
        const aiResponse: Message = {
          role: 'assistant',
          content: response.choices[0].message.content.trim()
        };
        this.aiMessages.push(aiResponse);
      } else {
        const errorMessage: Message = {
          role: 'assistant',
          content: `请求失败，错误码：${resp.responseCode}`
        };
        this.aiMessages.push(errorMessage);
      }
    } catch (error) {
      const errorMessage: Message = {
        role: 'assistant',
        content: `发生错误：${JSON.stringify(error)}`
      };
      this.aiMessages.push(errorMessage);
    } finally {
      this.isAIChatting = false;
      client.destroy();
    }
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
        Image($r("app.media.about"))
          .width(24)
          .height(24)
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' });
          })
      }
      .width('100%')
      .height(66)
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

        // 新增：AI分析加载动画
        if (this.showLoading) {
          Row() {
            LoadingProgress()
              .color('#007AFF')
              .width(24)
              .height(24)
            Text('AI正在分析，请稍候...')
              .fontSize(14)
              .margin({ left: 8 })
          }
          .margin({ top: 12 })
          .justifyContent(FlexAlign.Center)
        }
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
                .onClick((): void => this.decrementWater())

              Button('+')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick((): void => this.incrementWater())
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
                .onClick((): void => this.changeSleep(-1))

              Button('+')
                .width(40)
                .height(40)
                .borderRadius(20)
                .onClick((): void => this.changeSleep(1))
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
                .onClick((): void => this.decrementSteps())

              Button('+100')
                .width(60)
                .height(40)
                .borderRadius(20)
                .fontSize(12)
                .onClick((): void => this.incrementSteps())
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
                  .onClick((): void => this.changeMood(moodOption))
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

  // ai页面UI
  @Builder
  AIPage() {
    Column() {
      // 顶部标题
      Row() {
        Text('健康AI助手')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
        Blank()
        Image($r("app.media.about"))
          .width(24)
          .height(24)
      }
      .width('100%')
      .height(66)
      .padding(16)
      .backgroundColor('#f5f5f5')

      Divider().strokeWidth(1).color('#1F000000')

      // 聊天记录
      Scroll() {
        Column() {
          ForEach(this.aiMessages, (message: Message, index: number) => {
            if (message.role === 'user') {
              Row() {
                Blank()
                Text(message.content)
                  .backgroundColor('#007AFF')
                  .padding(12)
                  .borderRadius(16)
              }
              .width('100%')
              .padding(8)
            } else {
              Row() {
                Image($r('app.media.ic_ai'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                Text(message.content)
                  .backgroundColor('#F5F5F5')
                  .padding(12)
                  .borderRadius(16)
                Blank()
              }
              .width('100%')
              .padding(8)
            }
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 输入区域
      Row() {
        TextInput({
          placeholder: '输入你的问题...',
          text: $$this.aiInput
        })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(24)
          .padding({ left: 16, right: 16 })

        Button('发送')
          .width(80)
          .height(48)
          .backgroundColor('#007AFF')
          .borderRadius(24)
          .onClick(() => {
            this.sendAIMessage();
          })
          .enabled(!this.isAIChatting)
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  build() {
    Column() {
      // 主内容区域
      Stack() {
        if (this.selectedIndex === 0) {
          this.NotePage()
        } else if (this.selectedIndex === 1) {
          this.HealthPage()
        } else {
          this.AIPage()
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

        // AI页面按钮
        Column() {
          Image($r('app.media.ic_ai'))
            .width(26)
            .height(26)
            .fillColor(this.selectedIndex === 2 ? '#007AFF' : '#8E8E93')
          Text('AI助手')
            .fontSize(12)
            .fontColor(this.selectedIndex === 2 ? '#007AFF' : '#8E8E93')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 2;
        })
        .alignItems(HorizontalAlign.Center)
      }

      // AI对话界面按钮
      // 已整合到底部导航栏

      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .border({ width: { top: 1 }, color: '#E5E5EA' })
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