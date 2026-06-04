// NoteEditor.ets - 新笔记编辑器
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset, NoteItem } from '../utils/Types';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';
import { callDeepSeek, NOTE_ANALYSIS_SYSTEM_PROMPT } from '../utils/AIService';
import { MarkdownPreview } from '../components/MarkdownPreview';

interface EditorParams {
  currentNote?: string;
}

@Entry
@Component
struct NoteEditor {
  @State editedContent: string = '';
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
    const params = router.getParams() as EditorParams;
    const savedNote = await storage.getCurrentNote();
    this.editedContent = savedNote || params.currentNote || '';
    await storage.saveCurrentNote(this.editedContent);
  }

  async onPageShow() {
    const savedNote = await storage.getCurrentNote();
    if (savedNote && savedNote !== this.editedContent) {
      this.editedContent = savedNote;
    }
  }

  async saveCurrentNote() {
    if (this.editedContent.trim().length === 0) {
      promptAction.showToast({ message: '笔记内容不能为空', duration: 2000 });
      return;
    }
    await storage.saveCurrentNote(this.editedContent);
    const historyNotes = await storage.getHistoryNotes();
    const now = new Date();
    const y = now.getFullYear();
    const m = (now.getMonth() + 1).toString().padStart(2, '0');
    const d = now.getDate().toString().padStart(2, '0');
    const h = now.getHours().toString().padStart(2, '0');
    const min = now.getMinutes().toString().padStart(2, '0');
    const noteContent: string = this.editedContent.trim();
    const newNote: NoteItem = { content: noteContent, createdAt: `${y}-${m}-${d} ${h}:${min}` };
    historyNotes.unshift(newNote);
    await storage.saveHistoryNotes(historyNotes);
    this.editedContent = '';
    await storage.saveCurrentNote('');
    promptAction.showToast({ message: '已保存到历史笔记', duration: 2000 });
    router.back({ url: 'pages/Index', params: { currentNote: '', _refresh: Date.now() } });
  }

  async saveAndBack() {
    await storage.saveCurrentNote(this.editedContent);
    router.back({ url: 'pages/Index', params: { currentNote: this.editedContent, _refresh: Date.now() } });
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

    await storage.saveCurrentNote(this.editedContent);
    this.isAnalyzing = true;
    this.showLoading = true;

    try {
      const result = await callDeepSeek([
        { role: 'system', content: NOTE_ANALYSIS_SYSTEM_PROMPT },
        { role: 'user', content: `请整理以下笔记内容：${this.editedContent}` }
      ]);
      this.editedContent = result;
      await storage.saveCurrentNote(result);
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
          .onClick(() => { this.saveAndBack(); })
        Text('编辑笔记').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
        // 操作按钮组（椭圆玻璃卡片）
        Row({ space: 4 }) {
          Button(this.showPreview ? '编辑' : '预览').fontSize(13).fontColor(this.getThemeColor('textColor'))
            .backgroundColor('transparent').borderRadius(16).height(32).padding({ left: 12, right: 12 })
            .onClick(() => { this.showPreview = !this.showPreview; })
          Divider().vertical(true).height(18).color('rgba(255,255,255,0.15)')
          Button('保存').fontSize(13).fontColor('#FFFFFF')
            .backgroundColor('transparent').borderRadius(16).height(32).padding({ left: 12, right: 12 })
            .onClick(() => { this.saveCurrentNote(); })
        }
        .height(36).padding({ left: 4, right: 4 })
        .backgroundColor('rgba(255, 255, 255, 0.1)')
        .borderRadius(18)
        .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.15)' })
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })

      // 笔记内容区域
      if (this.showPreview) {
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
        Column() {
          TextArea({ placeholder: '写下你的想法…', text: this.editedContent })
            .width('100%').height('100%')
            .fontSize(16).fontColor(this.getThemeColor('textColor')).lineHeight(24)
            .backgroundColor('rgba(255, 255, 255, 0.06)')
            .placeholderColor(this.getThemeColor('mutedTextColor'))
            .padding(20)
            .onChange((value: string) => {
              this.editedContent = value;
              storage.saveCurrentNote(value);
            })
        }
        .layoutWeight(1).width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      }

      // 操作按钮区域
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Button('保存到历史笔记').layoutWeight(1).height(44).fontSize(16).fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor')).borderRadius(22)
            .onClick(() => { this.saveCurrentNote(); })
          Button('AI分析').layoutWeight(1).height(44).fontSize(16).fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor')).borderRadius(22)
            .onClick(() => { this.analyzeNoteWithAI(); })
            .enabled(!this.isAnalyzing)
        }
        .width('100%')

        if (this.showLoading) {
          Row() {
            LoadingProgress().color(this.getThemeColor('accentColor')).width(20).height(20)
            Text('AI正在分析，请稍候...').fontSize(14).fontColor(this.getThemeColor('mutedTextColor')).margin({ left: 8 })
          }
          .width('100%').margin({ top: 4 }).justifyContent(FlexAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 36 })
      .backgroundColor('rgba(255, 255, 255, 0.06)')
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#1a1a2e', 0], ['#16213e', 0.5], ['#0f3460', 1]]
    })
  }
}
