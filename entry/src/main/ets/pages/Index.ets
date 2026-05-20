// Index.ets - 主页面，包含底部导航栏和所有子组件
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import { ThemePreset, Template, HealthData, DailyHealthRecord } from '../utils/Types';
import { DEFAULT_THEME_ID, ThemeColorKey, getThemeById, getThemeColorValue } from '../utils/Theme';
import { syncThemePresetsFromStorage } from '../utils/ThemeHelper';
import { NoteList } from './NoteList';
import { HealthTracker } from './HealthTracker';
import { AIChat } from './AIChat';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
    @State selectedIndex: number = 0;
  @State currentNote: string = '';
  @State historyNotes: string[] = [];
  @State themePresets: ThemePreset[] = [];
  @State selectedThemeId: string = DEFAULT_THEME_ID;
  // 健康数据（在 Index 层级管理，用于传递给 AIChat）
  @State waterCount: number = 0;
  @State sleepHours: number = 7;
  @State stepsCount: number = 0;
  @State mood: string = '开心';
  @State waterGoal: number = 8;
  @State sleepGoal: number = 8;
  @State stepsGoal: number = 10000;
  @State lastResetDate: string = '';

  @State defaultTemplates: Template[] = [
    { id: 'meeting', name: '会议记录', icon: '📝', content: '会议记录模板：\n\n会议主题：\n时间：\n地点：\n参与人员：\n\n议程：\n1. \n2. \n3. \n\n待办事项：', category: '工作', description: '快速记录会议要点' },
    { id: 'shopping', name: '购物清单', icon: '🛒', content: '购物清单：\n\n🥬 蔬菜类：\n🥩 肉类：\n🥛 奶制品：\n🍞 主食：\n🧹 日用品：', category: '生活', description: '分类整理购物需求' },
    { id: 'study', name: '学习计划', icon: '📚', content: '学习计划：\n\n📚 今日学习目标：\n⏰ 预计用时：\n📖 重点内容：\n✅ 完成情况：', category: '学习', description: '规划每日学习任务' },
    { id: 'daily', name: '每日总结', icon: '📅', content: '每日总结：\n\n✅ 今日完成：\n\n💡 今日收获：\n\n📝 明日计划：\n\n🎯 待改进：', category: '生活', description: '记录每日生活点滴' },
    { id: 'todo', name: '待办事项', icon: '✓', content: '待办事项：\n\n□ 任务1\n□ 任务2\n□ 任务3\n\n优先级：\n🔴 紧急重要\n🟡 重要不紧急\n🟢 紧急不重要', category: '工作', description: '管理日常待办任务' }
  ]
  @State customTemplates: Template[] = [];
  @State allTemplates: Template[] = [];

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    await this.loadAllData();
  }

  async onPageShow() {
    await this.syncThemeFromStorage();
    const result = router.getParams() as Record<string, Object>;

    if (result) {
      if (result.content !== undefined && result.index !== undefined) {
        const newContent = result.content as string;
        const idx = result.index as number;
        if (idx >= 0 && idx < this.historyNotes.length) {
          this.historyNotes[idx] = newContent;
          await storage.saveHistoryNotes(this.historyNotes);
        }
      }
      if (result.currentNote !== undefined) {
        this.currentNote = result.currentNote as string;
        await storage.saveCurrentNote(this.currentNote);
      }
      if (result.noteSaved) {
        const savedNotes = await storage.getHistoryNotes();
        this.historyNotes = savedNotes;
      }
    }

    const savedCurrentNote = await storage.getCurrentNote();
    if (savedCurrentNote !== this.currentNote) {
      this.currentNote = savedCurrentNote;
    }

    const savedNotes = await storage.getHistoryNotes();
    if (JSON.stringify(savedNotes) !== JSON.stringify(this.historyNotes)) {
      this.historyNotes = savedNotes;
    }

    const savedCustomTemplates = await storage.getCustomTemplates();
    this.customTemplates = savedCustomTemplates;
    this.allTemplates = [...this.defaultTemplates, ...this.customTemplates];
  }

  async loadAllData() {
    const presets = await syncThemePresetsFromStorage();
    this.themePresets = presets;
    const savedThemeId = await storage.getThemePreference();
    const themeToApply = savedThemeId && presets.some((t: ThemePreset) => t.id === savedThemeId)
      ? savedThemeId : this.selectedThemeId;
    this.selectedThemeId = themeToApply;

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

    // 健康数据
    try {
      const savedHealthData = await storage.getHealthData();
      const today = new Date().toDateString();
      if (savedHealthData.lastResetDate !== today) {
        this.waterCount = 0;
        this.sleepHours = 7;
        this.stepsCount = 0;
        this.mood = '开心';
        this.lastResetDate = today;
        await this.saveHealthData();
      } else {
        this.waterCount = savedHealthData.waterCount || 0;
        this.sleepHours = savedHealthData.sleepHours || 7;
        this.stepsCount = savedHealthData.stepsCount || 0;
        this.mood = savedHealthData.mood || '开心';
        this.lastResetDate = savedHealthData.lastResetDate || today;
      }
      this.waterGoal = savedHealthData.waterGoal || 8;
      this.sleepGoal = savedHealthData.sleepGoal || 8;
      this.stepsGoal = savedHealthData.stepsGoal || 10000;
    } catch (error) {
      console.error(`加载健康数据失败: ${error}`);
    }
  }

  async saveHealthData() {
    const today = new Date().toDateString();
    const healthData: HealthData = {
      waterCount: this.waterCount, sleepHours: this.sleepHours, stepsCount: this.stepsCount,
      mood: this.mood, lastResetDate: this.lastResetDate || today,
      waterGoal: this.waterGoal, sleepGoal: this.sleepGoal, stepsGoal: this.stepsGoal
    };
    await storage.saveHealthData(healthData);
    const todayStr = new Date().toISOString().split('T')[0];
    const dailyRecord: DailyHealthRecord = {
      date: todayStr, waterCount: this.waterCount, sleepHours: this.sleepHours,
      stepsCount: this.stepsCount, mood: this.mood
    };
    await storage.saveDailyHealthRecord(dailyRecord);
  }

  async syncThemeFromStorage() {
    const presets = await syncThemePresetsFromStorage();
    this.themePresets = presets;
    const themeOnShow = await storage.getThemePreference();
    if (themeOnShow && presets.some((t: ThemePreset) => t.id === themeOnShow)) {
      if (themeOnShow !== this.selectedThemeId) this.selectedThemeId = themeOnShow;
    } else if (this.selectedThemeId !== DEFAULT_THEME_ID) {
      this.selectedThemeId = DEFAULT_THEME_ID;
    }
  }

  getCurrentTheme(): ThemePreset { return getThemeById(this.selectedThemeId, this.themePresets); }
  getThemeColor(key: ThemeColorKey): string { return getThemeColorValue(this.getCurrentTheme(), key); }

  @Builder
  TemplateSection() {
    Column() {
      Row() {
        Text('📋 快速模板').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%').padding({ left: 20, right: 20, bottom: 12 })

      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.allTemplates, (template: Template) => {
            Column({ space: 10 }) {
              Column({ space: 6 }) {
                Text(template.icon).fontSize(32).width('100%').textAlign(TextAlign.Center).margin({ top: 8 })
                Text(template.name).fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor(this.getThemeColor('textColor')).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').textAlign(TextAlign.Center)
                  .padding({ left: 8, right: 8 })
                if (template.description) {
                  Text(template.description).fontSize(11).fontColor('#999999').maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').textAlign(TextAlign.Center)
                    .padding({ left: 8, right: 8, bottom: 4 })
                }
                if (template.category) {
                  Text(template.category).fontSize(10).fontColor('#007AFF').backgroundColor('#E3F2FD')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(8).margin({ top: 4 })
                }
              }
              .width('100%').layoutWeight(1)

              Button('使用').width('70%').height(36).fontSize(14).fontColor('#FFFFFF')
                .backgroundColor(this.getThemeColor('accentColor')).borderRadius(8)
                .margin({ bottom: 12, left: 12, right: 12 })
                .onClick(() => { this.currentNote = template.content;
                  promptAction.showToast({ message: `已应用模板：${template.name}`, duration: 1500 }); })
            }
            .width(140).height(180)
            .backgroundColor(this.getThemeColor('cardColor')).borderRadius(16)
            .shadow({ radius: 8, color: '#00000012', offsetX: 0, offsetY: 4 })
            .onClick(() => { this.currentNote = template.content;
              promptAction.showToast({ message: `已应用模板：${template.name}`, duration: 1500 }); })
          }, (template: Template) => template.id)
        }
        .padding({ left: 20, right: 20 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .padding({ top: 20, bottom: 16 })
  }

  build() {
    Column() {
      Stack() {
        // 笔记页面 — 标题栏 + 模板卡片 + 笔记列表
        Column() {
          Scroll() {
            Column() {
              // 顶部导航栏
              Row() {
                Text('EyesNote').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
                Blank()
                Image($r("app.media.ic_setting")).width(42).height(42).padding(4)
                  .onClick(() => { router.pushUrl({ url: 'pages/Settings' }); })
              }
              .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })
              .backgroundColor(this.getThemeColor('backgroundColor'))

              // 模板卡片
              this.TemplateSection()

              Divider().strokeWidth(0.5).color('#E5E5EA').margin({ left: 20, right: 20 })

              // 笔记列表组件
              NoteList({
                themePresets: this.themePresets,
                selectedThemeId: this.selectedThemeId,
                currentNote: $currentNote,
                historyNotes: $historyNotes,
                getThemeColor: (key: string) => { return this.getThemeColor(key as ThemeColorKey); }
              })
            }
            .width('100%')
          }
          .width('100%').height('100%')
          .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
          .backgroundColor(this.getThemeColor('backgroundColor'))
        }
        .width('100%').height('100%')
        .translate({ x: `${(0 - this.selectedIndex) * 100}%` })

        // 健康页面
        Column() {
          HealthTracker({
            themePresets: this.themePresets, selectedThemeId: this.selectedThemeId,
            getThemeColor: (key: string) => { return this.getThemeColor(key as ThemeColorKey); },
            waterCount: $waterCount, sleepHours: $sleepHours, stepsCount: $stepsCount, mood: $mood,
            waterGoal: $waterGoal, sleepGoal: $sleepGoal, stepsGoal: $stepsGoal, lastResetDate: $lastResetDate,
            onSave: () => { this.saveHealthData(); }
          })
        }
        .width('100%').height('100%')
        .translate({ x: `${(1 - this.selectedIndex) * 100}%` })

        // AI 页面
        Column() {
          AIChat({
            themePresets: this.themePresets, selectedThemeId: this.selectedThemeId,
            getThemeColor: (key: string) => { return this.getThemeColor(key as ThemeColorKey); },
            waterCount: this.waterCount, sleepHours: this.sleepHours,
            stepsCount: this.stepsCount, mood: this.mood,
            historyNotes: $historyNotes
          })
        }
        .width('100%').height('100%')
        .translate({ x: `${(2 - this.selectedIndex) * 100}%` })
      }
      .layoutWeight(1)

      // 底部导航栏
      Row() {
        Column({ space: 4 }) {
          Image($r('app.media.ic_edit')).width(26).height(26)
            .fillColor(this.selectedIndex === 0 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('笔记').fontSize(12)
            .fontColor(this.selectedIndex === 0 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 0 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => { if (this.selectedIndex !== 0) { animateTo({ duration: 250, curve: 'easeInOut' }, () => { this.selectedIndex = 0; }); } })
        .alignItems(HorizontalAlign.Center).padding({ top: 8, bottom: 8 })

        Column({ space: 4 }) {
          Image($r('app.media.ic_right')).width(26).height(26)
            .fillColor(this.selectedIndex === 1 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('健康').fontSize(12)
            .fontColor(this.selectedIndex === 1 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 1 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => { if (this.selectedIndex !== 1) { animateTo({ duration: 250, curve: 'easeInOut' }, () => { this.selectedIndex = 1; }); } })
        .alignItems(HorizontalAlign.Center).padding({ top: 8, bottom: 8 })

        Column({ space: 4 }) {
          Image($r('app.media.ic_ai')).width(26).height(26)
            .fillColor(this.selectedIndex === 2 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('健康Deepseek').fontSize(11)
            .fontColor(this.selectedIndex === 2 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 2 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => { if (this.selectedIndex !== 2) { animateTo({ duration: 250, curve: 'easeInOut' }, () => { this.selectedIndex = 2; }); } })
        .alignItems(HorizontalAlign.Center).padding({ top: 8, bottom: 8 })
      }
      .width('100%').height(64)
      .backgroundColor(this.getThemeColor('cardColor'))
      .border({ width: { top: 0.5 }, color: '#E5E5EA' })
      .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: -2 })
    }
    .width('100%').height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
