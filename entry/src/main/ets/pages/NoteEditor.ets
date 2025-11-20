import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';
import { ThemePreset } from '../utils/Types';
import { DEFAULT_THEME_ID, ThemeColorKey, cloneThemePreset, cloneThemePresets, getThemeById, getThemeColorValue } from '../utils/Theme';

// 定义路由参数接口
interface EditorParams {
  currentNote?: string; // 当前笔记内容
}

interface Message {
  role: string;
  content: string;
}

interface GeneratedTypeLiteralInterface_3 {
  message: GeneratedTypeLiteralInterface_4;
}

interface GeneratedTypeLiteralInterface_4 {
  content: string;
}

@Entry
@Component
struct NoteEditor {
  @State editedContent: string = '';
  @State showToolbar: boolean = true; // 工具栏显示状态
  @State toolbarOpacity: number = 1; // 工具栏透明度动画
  @State toolbarOffset: number = 0; // 工具栏垂直位移
  @State isAnalyzing: boolean = false; // AI分析状态
  @State showLoading: boolean = false; // 加载动画状态
  analyzedNote: string = ""; // 分析结果
  @State themePresets: ThemePreset[] = cloneThemePresets();
  @State selectedThemeId: string = DEFAULT_THEME_ID;

  getCurrentTheme(): ThemePreset {
    return getThemeById(this.selectedThemeId, this.themePresets);
  }

  getThemeColor(key: ThemeColorKey): string {
    return getThemeColorValue(this.getCurrentTheme(), key);
  }

  async syncThemePresetsFromStorage() {
    const presets = cloneThemePresets();
    const customTheme = await storage.getCustomThemePreset();
    if (customTheme) {
      presets.push(cloneThemePreset(customTheme));
    }
    this.themePresets = presets;
  }

  async refreshTheme() {
    await this.syncThemePresetsFromStorage();
    const themeId = await storage.getThemePreference();
    if (themeId && this.themePresets.some((theme: ThemePreset) => theme.id === themeId)) {
      this.selectedThemeId = themeId;
    } else {
      this.selectedThemeId = DEFAULT_THEME_ID;
    }
  }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    await this.refreshTheme();

    const params = router.getParams() as EditorParams;
    // 优先从存储中读取最新内容（可能包含AI分析结果）
    const savedNote = await storage.getCurrentNote();
    this.editedContent = savedNote || params.currentNote || '';
    
    // 自动保存当前笔记内容
    await storage.saveCurrentNote(this.editedContent);
  }

  // 页面显示时检查是否有更新
  async onPageShow() {
    await this.refreshTheme();
    // 检查存储中是否有更新的内容（AI分析可能已完成）
    const savedNote = await storage.getCurrentNote();
    if (savedNote && savedNote !== this.editedContent) {
      this.editedContent = savedNote;
    }
  }

  // 保存当前笔记（同时保存到历史记录）
  async saveCurrentNote() {
    if (this.editedContent.trim().length === 0) {
      promptAction.showToast({
        message: '笔记内容不能为空',
        duration: 2000
      });
      return;
    }

    // 保存到当前笔记
    await storage.saveCurrentNote(this.editedContent);
    
    // 保存到历史笔记
    const historyNotes = await storage.getHistoryNotes();
    historyNotes.unshift(this.editedContent.trim());
    await storage.saveHistoryNotes(historyNotes);
    
    // 清空当前笔记
    this.editedContent = '';
    await storage.saveCurrentNote('');
    
    promptAction.showToast({
      message: '已保存到历史笔记',
      duration: 2000
    });
    
    // 返回主页面
    router.back({
      url: 'pages/Index',
      params: {
        currentNote: '',
        noteSaved: true
      }
    });
  }

  // 保存并返回（只保存到当前笔记，不添加到历史记录）
  async saveAndBack() {
    await storage.saveCurrentNote(this.editedContent);
    router.back({
      url: 'pages/Index',
      params: {
        currentNote: this.editedContent
      }
    });
  }

  // 获取字数统计
  getWordCount(): number {
    return this.editedContent.replace(/\s/g, '').length;
  }

  // 插入文本到末尾
  insertText(text: string) {
    this.editedContent += text;
  }

  // 插入当前日期
  insertDate() {
    const date = new Date();
    const dateStr = `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
    this.insertText(dateStr);
  }

  // 插入当前时间
  insertTime() {
    const date = new Date();
    const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    this.insertText(timeStr);
  }

  // 插入日期时间
  insertDateTime() {
    const date = new Date();
    const dateStr = `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
    const timeStr = `${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    this.insertText(`${dateStr} ${timeStr}`);
  }

  // 插入分隔线
  insertDivider() {
    this.insertText('\n────────────────\n');
  }

  // 插入待办事项格式
  insertTodo() {
    this.insertText('\n□ ');
  }

  // 插入标题格式
  insertTitle() {
    this.insertText('\n【标题】\n');
  }

  // 插入列表项
  insertListItem() {
    this.insertText('\n• ');
  }

  // 插入数字列表
  insertNumberedList() {
    this.insertText('\n1. ');
  }

  toggleToolbar() {
    if (!this.showToolbar) {
      this.showToolbar = true;
      this.toolbarOpacity = 0;
      this.toolbarOffset = -8;
      animateTo({
        duration: 280,
        curve: 'easeInOut'
      }, () => {
        this.toolbarOpacity = 1;
        this.toolbarOffset = 0;
      });
    } else {
      animateTo({
        duration: 240,
        curve: 'easeInOut'
      }, () => {
        this.toolbarOpacity = 0;
        this.toolbarOffset = -8;
      });
      setTimeout(() => {
        this.showToolbar = false;
      }, 210);
    }
  }

  // 全选文本
  selectAll() {
    promptAction.showToast({
      message: '请长按文本区域进行全选',
      duration: 2000
    });
  }

  // 清空内容
  clearContent() {
    promptAction.showDialog({
      title: '确认清空',
      message: '确定要清空所有内容吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '清空', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.editedContent = '';
        promptAction.showToast({
          message: '内容已清空',
          duration: 2000
        });
      }
    }).catch((err: Error) => {
      console.error(`清空确认对话框错误: ${err}`);
    });
  }

  // AI分析笔记
  async analyzeNoteWithAI() {
    if (this.editedContent.trim().length === 0) {
      promptAction.showToast({
        message: '笔记内容不能为空',
        duration: 2000
      });
      return;
    }

    // 保存当前内容到存储，以便退出页面后也能更新
    await storage.saveCurrentNote(this.editedContent);

    this.isAnalyzing = true;
    this.showLoading = true;
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
                content: `请整理以下笔记内容：${this.editedContent}`
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
        this.editedContent = this.analyzedNote;
        
        // 无论是否还在页面，都保存分析结果到存储
        await storage.saveCurrentNote(this.analyzedNote);
        
        promptAction.showToast({
          message: 'AI分析完成',
          duration: 2000
        });
      } else {
        promptAction.showToast({
          message: `分析失败：HTTP错误码 ${resp.responseCode}`,
          duration: 3000
        });
      }
    } catch (err) {
      promptAction.showToast({
        message: `分析失败：${JSON.stringify(err)}`,
        duration: 3000
      });
    } finally {
      this.isAnalyzing = false;
      this.showLoading = false;
      client.destroy();
    }
  }

  // 渲染工具栏
  @Builder
  renderToolbar() {
    Column() {
      // 工具栏标题栏（始终显示）
      Row() {
        Text('📝 编辑工具')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getThemeColor('textColor'))
        Blank()
        Text(this.showToolbar ? '收起 ▲' : '展开 ▼')
          .fontSize(12)
          .fontColor(this.getThemeColor('accentColor'))
          .onClick(() => {
            this.toggleToolbar();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })

      // 工具栏按钮（可收起）
      if (this.showToolbar || this.toolbarOpacity > 0) {
        Scroll() {
          Row({ space: 12 }) {
            // 日期
            this.renderToolbarButton('📅 日期', () => {
              this.insertDate();
            })
            
            // 时间
            this.renderToolbarButton('🕐 时间', () => {
              this.insertTime();
            })
            
            // 日期时间
            this.renderToolbarButton('📆 日期时间', () => {
              this.insertDateTime();
            })
            
            // 分隔线
            this.renderToolbarButton('➖ 分隔线', () => {
              this.insertDivider();
            })
            
            // 待办
            this.renderToolbarButton('☐ 待办', () => {
              this.insertTodo();
            })
            
            // 标题
            this.renderToolbarButton('📌 标题', () => {
              this.insertTitle();
            })
            
            // 列表
            this.renderToolbarButton('• 列表', () => {
              this.insertListItem();
            })
            
            // 数字列表
            this.renderToolbarButton('1. 数字', () => {
              this.insertNumberedList();
            })
            
            // 清空
            this.renderToolbarButton('🗑️ 清空', () => {
              this.clearContent();
            })
          }
          .padding({ left: 20, right: 20, bottom: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .height(50)
        .opacity(this.toolbarOpacity)
        .translate({ y: this.toolbarOffset })
      }

      // 字数统计（始终显示）
      Row() {
        Text(`字数：${this.getWordCount()}`)
          .fontSize(12)
          .fontColor(this.getThemeColor('mutedTextColor'))
        Blank()
        Text(`行数：${this.editedContent.split('\n').length}`)
          .fontSize(12)
          .fontColor(this.getThemeColor('mutedTextColor'))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 4, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.getThemeColor('cardColor'))
    .border({ width: { bottom: 0.5 }, color: '#E5E5EA' })
  }

  // 渲染工具栏按钮
  @Builder
  renderToolbarButton(label: string, onClick: () => void) {
    Button(label)
      .fontSize(13)
      .fontColor(this.getThemeColor('textColor'))
      .backgroundColor(this.getThemeColor('cardColor'))
      .borderRadius(16)
      .height(36)
      .padding({ left: 12, right: 12 })
      .onClick(onClick)
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup'))
          .width(28)
          .height(28)
          .padding(4)
          .margin({ right: 12 })
          .onClick(() => {
            this.saveAndBack();
          })
        Text('编辑笔记')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor'))
        Blank()
        Button('保存')
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getThemeColor('accentColor'))
          .borderRadius(20)
          .height(36)
          .padding({ left: 20, right: 20 })
          .onClick(() => {
            this.saveCurrentNote();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor(this.getThemeColor('cardColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      // 工具栏（始终显示，但内容可收起）
      this.renderToolbar()

      // 笔记内容编辑区
      Column() {
        TextArea({ placeholder: '写下你的想法…', text: this.editedContent })
          .width('100%')
          .height('100%')
          .fontSize(16)
          .fontColor(this.getThemeColor('textColor'))
          .lineHeight(24)
          .backgroundColor(this.getThemeColor('cardColor'))
          .placeholderColor(this.getThemeColor('mutedTextColor'))
          .padding(20)
          .onChange((value: string) => {
            this.editedContent = value;
            // 自动保存
            storage.saveCurrentNote(value);
          })
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      // 操作按钮区域
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Button('保存到历史笔记')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor'))
            .borderRadius(22)
            .onClick(() => {
              this.saveCurrentNote();
            })

          Button('AI分析')
            .layoutWeight(1)
            .height(44)
            .fontSize(16)
            .fontColor('#FFFFFF')
          .backgroundColor(this.getThemeColor('accentColor'))
            .borderRadius(22)
            .onClick(() => {
              this.analyzeNoteWithAI();
            })
            .enabled(!this.isAnalyzing)
        }
        .width('100%')

        // AI分析加载动画
        if (this.showLoading) {
          Row() {
            LoadingProgress()
              .color(this.getThemeColor('accentColor'))
              .width(20)
              .height(20)
            Text('AI正在分析，请稍候...')
              .fontSize(14)
              .fontColor(this.getThemeColor('mutedTextColor'))
              .margin({ left: 8 })
          }
          .width('100%')
          .margin({ top: 4 })
          .justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })
      .backgroundColor(this.getThemeColor('cardColor'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}

