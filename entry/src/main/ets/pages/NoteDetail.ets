// NoteDetail.ets - 编辑已有笔记
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset, NoteItem } from '../utils/Types';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';
import { callDeepSeek, NOTE_ANALYSIS_SYSTEM_PROMPT } from '../utils/AIService';
import { MarkdownPreview } from '../components/MarkdownPreview';

interface NoteParams {
  noteContent?: string;
  noteIndex?: number;
}

@Entry
@Component
struct NoteDetail {
  @State noteContent: string = '';
  noteCreatedAt: string = '';
  @State editedContent: string = '';
  @State noteIndex: number = -1;
  @State isAnalyzing: boolean = false;
  @State showLoading: boolean = false;
  @State showPreview: boolean = true;

  private theme: ThemePreset = getTheme();

  getThemeColor(key: ThemeColorKey): string {
    return getThemeColorValue(this.theme, key);
  }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    const params = router.getParams() as NoteParams;
    this.noteContent = params.noteContent || '';
    this.noteIndex = params.noteIndex || -1;
    this.editedContent = this.noteContent;
    if (this.noteIndex >= 0) {
      const historyNotes = await storage.getHistoryNotes();
      if (historyNotes[this.noteIndex] && historyNotes[this.noteIndex].content !== this.editedContent) {
        this.editedContent = historyNotes[this.noteIndex].content;
        this.noteContent = historyNotes[this.noteIndex].content;
      }
    }
    // 如果没有传 index，尝试根据传入内容匹配
    if (this.noteIndex < 0 && this.noteContent) {
      const historyNotes = await storage.getHistoryNotes();
      for (let i = 0; i < historyNotes.length; i++) {
        if (historyNotes[i].content === this.noteContent) {
          this.noteIndex = i;
          break;
        }
      }
    }
  }

  async onPageShow() {
    if (this.noteIndex >= 0) {
      const historyNotes = await storage.getHistoryNotes();
      if (historyNotes[this.noteIndex] && historyNotes[this.noteIndex].content !== this.editedContent) {
        this.editedContent = historyNotes[this.noteIndex].content;
        this.noteContent = historyNotes[this.noteIndex].content;
      }
    }
  }

  async saveNote() {
    if (this.editedContent.trim() === '') {
      promptAction.showToast({ message: '内容不能为空', duration: 2000 });
      return;
    }
    const historyNotes = await storage.getHistoryNotes();

    if (this.noteIndex >= 0 && this.noteIndex < historyNotes.length) {
      // 更新已有笔记（通过 index）
      historyNotes[this.noteIndex].content = this.editedContent;
      await storage.saveHistoryNotes(historyNotes);
    } else {
      // 通过内容匹配查找（日历等地方没有传 index）
      let found = false;
      for (let i = 0; i < historyNotes.length; i++) {
        if (historyNotes[i].content === this.noteContent) {
          historyNotes[i].content = this.editedContent;
          await storage.saveHistoryNotes(historyNotes);
          found = true;
          break;
        }
      }
      if (!found) {
        // 完全没匹配到，创建新笔记
        const now = new Date();
        const y = now.getFullYear();
        const m_ = (now.getMonth() + 1).toString().padStart(2, '0');
        const d_ = now.getDate().toString().padStart(2, '0');
        const h = now.getHours().toString().padStart(2, '0');
        const min = now.getMinutes().toString().padStart(2, '0');
        const newNote: NoteItem = { content: this.editedContent, createdAt: `${y}-${m_}-${d_} ${h}:${min}` };
        historyNotes.unshift(newNote);
        await storage.saveHistoryNotes(historyNotes);
      }
    }
    router.back({ url: 'pages/Index', params: { _refresh: Date.now() } });
  }

  getWordCount(): number { return this.editedContent.replace(/\s/g, '').length; }

  clearContent() {
    promptAction.showDialog({
      title: '确认清空', message: '确定要清空所有内容吗？',
      buttons: [{ text: '取消', color: '#666666' }, { text: '清空', color: '#FF3B30' }]
    }).then((result) => {
      if (result.index === 1) { this.editedContent = ''; promptAction.showToast({ message: '内容已清空', duration: 2000 }); }
    }).catch((err: Error) => { console.error(`清空确认对话框错误: ${err}`); });
  }

  async analyzeNoteWithAI() {
    if (this.editedContent.trim().length === 0) {
      promptAction.showToast({ message: '笔记内容不能为空', duration: 2000 });
      return;
    }

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

    if (this.noteIndex >= 0) {
      const historyNotes = await storage.getHistoryNotes();
      historyNotes[this.noteIndex].content = this.editedContent;
      await storage.saveHistoryNotes(historyNotes);
    }
    this.isAnalyzing = true;
    this.showLoading = true;

    try {
      const result = await callDeepSeek([
        { role: 'system', content: NOTE_ANALYSIS_SYSTEM_PROMPT },
        { role: 'user', content: `请整理以下笔记内容：${this.editedContent}` }
      ]);
      this.editedContent = result;
      if (this.noteIndex >= 0) {
        const historyNotes = await storage.getHistoryNotes();
        historyNotes[this.noteIndex].content = result;
        await storage.saveHistoryNotes(historyNotes);
      }
      promptAction.showToast({ message: 'AI分析完成', duration: 2000 });
    } catch (err) {
      promptAction.showToast({ message: `AI 请求失败，请检查 API Key 是否有效`, duration: 3000 });
    } finally {
      this.isAnalyzing = false;
      this.showLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部安全距离（避开摄像头区域）
      Row().width('100%').height(40).backgroundColor(this.getThemeColor('backgroundColor'))

      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup')).width(28).height(28).padding(4).margin({ right: 12 })
          .fillColor(this.getThemeColor('textColor'))
          .onClick(() => { router.back(); })
        Text('笔记详情').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
        // 操作按钮组（椭圆玻璃卡片）
        Row({ space: 4 }) {
          Button(this.showPreview ? '编辑' : '预览').fontSize(13).fontColor(this.getThemeColor('textColor'))
            .backgroundColor('transparent').borderRadius(16).height(32).padding({ left: 12, right: 12 })
            .onClick(() => { this.showPreview = !this.showPreview; })
          Divider().vertical(true).height(18).color('rgba(255,255,255,0.15)')
          Button('保存').fontSize(13).fontColor('#FFFFFF')
            .backgroundColor('transparent').borderRadius(16).height(32).padding({ left: 12, right: 12 })
            .onClick(() => { this.saveNote(); })
        }
        .height(36).padding({ left: 4, right: 4 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(18)
        .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.15)' })
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })

      // 笔记内容区域
      if (this.showPreview) {
        // Markdown 预览模式
        Scroll() {
          Column() {
            MarkdownPreview({
              content: this.editedContent,
              textColor: this.getThemeColor('textColor'),
              mutedColor: this.getThemeColor('mutedTextColor'),
              accentColor: this.getThemeColor('accentColor')
            })
          }
          .width('100%').padding(16)
          .justifyContent(FlexAlign.Start)
        }
        .layoutWeight(1).width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      } else {
        // 编辑模式
        Column() {
          TextArea({ placeholder: '请输入笔记内容...', text: this.editedContent })
            .width('100%').height('100%')
            .fontSize(16).fontColor(this.getThemeColor('textColor')).lineHeight(24)
            .backgroundColor('rgba(255, 255, 255, 0.06)')
            .placeholderColor(this.getThemeColor('mutedTextColor'))
            .padding(20)
            .onChange((value: string) => { this.editedContent = value; })
        }
        .layoutWeight(1).width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      }

      // 操作区域
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Button('AI分析').layoutWeight(1).height(44).fontSize(16).fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor')).borderRadius(22)
            .onClick(() => { this.analyzeNoteWithAI(); })
            .enabled(!this.isAnalyzing)
        }
        .width('100%').padding({ left: 20, right: 20 })

        if (this.showLoading) {
          Row() {
            LoadingProgress().color(this.getThemeColor('accentColor')).width(20).height(20)
            Text('AI正在分析，请稍候...').fontSize(14).fontColor(this.getThemeColor('mutedTextColor')).margin({ left: 8 })
          }
          .width('100%').justifyContent(FlexAlign.Center).padding({ bottom: 8 })
        }
      }
      .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 32 })
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#1a1a2e', 0], ['#16213e', 0.5], ['#0f3460', 1]]
    })
  }
}
