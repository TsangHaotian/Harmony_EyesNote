// NoteDetail.ets - 编辑已有笔记
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset, NoteItem } from '../utils/Types';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';
import { callDeepSeek, NOTE_ANALYSIS_SYSTEM_PROMPT } from '../utils/AIService';
import { EditorToolbar } from '../components/EditorToolbar';

interface NoteParams {
  noteContent?: string;
  noteIndex?: number;
}

@Entry
@Component
struct NoteDetail {
  @State noteContent: string = '';
  @State editedContent: string = '';
  @State noteIndex: number = -1;
  @State showToolbar: boolean = true;
  @State toolbarOpacity: number = 1;
  @State toolbarOffset: number = 0;
  @State isAnalyzing: boolean = false;
  @State showLoading: boolean = false;

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
    if (this.noteIndex >= 0) {
      const historyNotes = await storage.getHistoryNotes();
      historyNotes[this.noteIndex].content = this.editedContent;
      await storage.saveHistoryNotes(historyNotes);
    } else {
      const historyNotes = await storage.getHistoryNotes();
      const now = new Date();
      const y = now.getFullYear();
      const m = (now.getMonth() + 1).toString().padStart(2, '0');
      const d = now.getDate().toString().padStart(2, '0');
      const h = now.getHours().toString().padStart(2, '0');
      const min = now.getMinutes().toString().padStart(2, '0');
      const newNote: NoteItem = { content: this.editedContent, createdAt: `${y}-${m}-${d} ${h}:${min}` };
      historyNotes.unshift(newNote);
      await storage.saveHistoryNotes(historyNotes);
      this.noteIndex = 0;
    }
    router.back({ url: 'pages/Index', params: { _refresh: Date.now() } });
  }

  getWordCount(): number { return this.editedContent.replace(/\s/g, '').length; }

  insertText(text: string) { this.editedContent += text; }
  insertDate() { const d = new Date(); this.insertText(`${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日`); }
  insertTime() { const d = new Date(); this.insertText(`${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`); }
  insertDivider() { this.insertText('\n────────────────\n'); }
  insertTodo() { this.insertText('\n□ '); }
  insertTitle() { this.insertText('\n【标题】\n'); }

  toggleToolbar() {
    if (!this.showToolbar) {
      this.showToolbar = true; this.toolbarOpacity = 0; this.toolbarOffset = -8;
      animateTo({ duration: 280, curve: 'easeInOut' }, () => { this.toolbarOpacity = 1; this.toolbarOffset = 0; });
    } else {
      animateTo({ duration: 240, curve: 'easeInOut' }, () => { this.toolbarOpacity = 0; this.toolbarOffset = -8; });
      setTimeout(() => { this.showToolbar = false; }, 210);
    }
  }

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
          .onClick(() => { router.back(); })
        Text('笔记详情').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
        Button('保存').fontSize(15).fontColor('#FFFFFF').backgroundColor(this.getThemeColor('accentColor'))
          .borderRadius(20).height(36).padding({ left: 20, right: 20 })
          .onClick(() => { this.saveNote(); })
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor(this.getThemeColor('cardColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      // 工具栏
      EditorToolbar({
        showToolbar: this.showToolbar,
        toolbarOpacity: this.toolbarOpacity,
        toolbarOffset: this.toolbarOffset,
        showDate: true,
        showTime: true,
        showDivider: true,
        showTodo: true,
        showTitleButton: true,
        showSelectAll: true,
        showClear: true,
        wordCount: this.getWordCount(),
        lineCount: this.editedContent.split('\n').length,
        cardColor: this.getThemeColor('cardColor'),
        textColor: this.getThemeColor('textColor'),
        accentColor: this.getThemeColor('accentColor'),
        mutedTextColor: this.getThemeColor('mutedTextColor'),
        onToggleToolbar: () => { this.toggleToolbar(); },
        onInsertDate: () => { this.insertDate(); },
        onInsertTime: () => { this.insertTime(); },
        onInsertDivider: () => { this.insertDivider(); },
        onInsertTodo: () => { this.insertTodo(); },
        onInsertTitle: () => { this.insertTitle(); },
        onClearContent: () => { this.clearContent(); }
      })

      // 笔记内容编辑区
      Column() {
        TextArea({ placeholder: '请输入笔记内容...', text: this.editedContent })
          .width('100%').height('100%')
          .fontSize(16).fontColor(this.getThemeColor('textColor')).lineHeight(24)
          .backgroundColor(this.getThemeColor('cardColor'))
          .placeholderColor(this.getThemeColor('mutedTextColor'))
          .padding(20)
          .onChange((value: string) => { this.editedContent = value; })
      }
      .layoutWeight(1).width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

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
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
