// Index.ets - 主页面，包含底部导航栏
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import http from '@ohos.net.http';
import { HealthData, DailyHealthRecord, Template, ThemePreset } from '../utils/Types'; // 导入共享接口
import promptAction from '@ohos.promptAction';
import { HealthKitSync } from '../utils/HealthKitSync';
import { DEFAULT_THEME_ID, ThemeColorKey, cloneThemePreset, cloneThemePresets, getThemeById, getThemeColorValue } from '../utils/Theme';

interface RouterParams {
  content?: string;
  index?: number;
  healthData?: HealthData; // 使用共享接口
  currentNote?: string; // 当前笔记内容
  noteSaved?: boolean; // 笔记是否已保存到历史记录
}

interface Message {
  role: string;
  content: string;
}

// 删除重复的 HealthData 接口定义

interface GeneratedTypeLiteralInterface_2 {
  content: string;
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
  @State filteredNotes: string[] = []; // 过滤后的笔记列表
  @State searchKeyword: string = ''; // 搜索关键词
  @State showSearch: boolean = false; // 是否显示搜索框
  @State defaultTemplates: Template[] = [
    {
      id: 'meeting',
      name: '会议记录',
      icon: '📝',
      content: '会议记录模板：\n\n会议主题：\n时间：\n地点：\n参与人员：\n\n议程：\n1. \n2. \n3. \n\n待办事项：',
      category: '工作',
      description: '快速记录会议要点'
    },
    {
      id: 'shopping',
      name: '购物清单',
      icon: '🛒',
      content: '购物清单：\n\n🥬 蔬菜类：\n🥩 肉类：\n🥛 奶制品：\n🍞 主食：\n🧹 日用品：',
      category: '生活',
      description: '分类整理购物需求'
    },
    {
      id: 'study',
      name: '学习计划',
      icon: '📚',
      content: '学习计划：\n\n📚 今日学习目标：\n⏰ 预计用时：\n📖 重点内容：\n✅ 完成情况：',
      category: '学习',
      description: '规划每日学习任务'
    },
    {
      id: 'daily',
      name: '每日总结',
      icon: '📅',
      content: '每日总结：\n\n✅ 今日完成：\n\n💡 今日收获：\n\n📝 明日计划：\n\n🎯 待改进：',
      category: '生活',
      description: '记录每日生活点滴'
    },
    {
      id: 'todo',
      name: '待办事项',
      icon: '✓',
      content: '待办事项：\n\n□ 任务1\n□ 任务2\n□ 任务3\n\n优先级：\n🔴 紧急重要\n🟡 重要不紧急\n🟢 紧急不重要',
      category: '工作',
      description: '管理日常待办任务'
    }
  ];
  @State customTemplates: Template[] = [];
  @State allTemplates: Template[] = [];
  // 健康页面相关状态
  @State waterCount: number = 0;
  @State sleepHours: number = 7;
  @State stepsCount: number = 0;
  @State mood: string = '开心';
  @State waterGoal: number = 8; // 每日饮水目标
  @State sleepGoal: number = 8; // 每日睡眠目标
  @State stepsGoal: number = 10000; // 每日步数目标
  @State lastResetDate: string = ''; // 上次重置日期
  @State isSyncing: boolean = false; // 是否正在同步健康数据
  // AI页面相关状态
  @State aiMessages: Message[] = [];
  @State aiInput: string = '';
  @State isAIChatting: boolean = false;
  // 主题相关状态
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

  async applyTheme(themeId: string, persist: boolean = true) {
    const themeExists = this.themePresets.some((theme: ThemePreset) => theme.id === themeId);
    if (!themeExists) {
      console.warn(`未找到主题：${themeId}`);
      return;
    }
    this.selectedThemeId = themeId;
    if (persist) {
      await storage.saveThemePreference(themeId);
    }
  }

  // 页面加载时恢复数据
  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    await this.syncThemePresetsFromStorage();
    const savedThemeId = await storage.getThemePreference();
    const themeToApply = savedThemeId && this.themePresets.some((theme: ThemePreset) => theme.id === savedThemeId)
      ? savedThemeId
      : this.selectedThemeId;
    await this.applyTheme(themeToApply, false);

    // 加载笔记数据
    const savedNotes = await storage.getHistoryNotes();
    if (savedNotes.length > 0) {
      this.historyNotes = savedNotes;
    } else {
      this.historyNotes = ['欢迎使用眨眼笔记，这是一个快速记录工具，可以帮助您记录您的想法'];
    }
    this.filteredNotes = this.historyNotes;

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
      const today = new Date().toDateString();
      
      // 检查是否需要重置（新的一天）
      if (savedHealthData.lastResetDate !== today) {
        // 新的一天，重置数据
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
      
      // 加载健康目标
      this.waterGoal = savedHealthData.waterGoal || 8;
      this.sleepGoal = savedHealthData.sleepGoal || 8;
      this.stepsGoal = savedHealthData.stepsGoal || 10000;
    } catch (error) {
      console.error(`加载健康数据失败: ${error}`);
    }
  }

  // 页面返回时处理数据
  async onPageShow() {
    const result = router.getParams() as RouterParams;

    await this.syncThemePresetsFromStorage();
    const themeOnShow = await storage.getThemePreference();
    if (themeOnShow && this.themePresets.some((theme: ThemePreset) => theme.id === themeOnShow)) {
      if (themeOnShow !== this.selectedThemeId) {
        await this.applyTheme(themeOnShow, false);
      }
    } else if (this.selectedThemeId !== DEFAULT_THEME_ID) {
      await this.applyTheme(DEFAULT_THEME_ID, false);
    }

    if (result) {
      // 处理历史笔记更新
      if (result.content !== undefined && result.index !== undefined) {
        const newContent = result.content;
        const index = result.index;
        if (index >= 0 && index < this.historyNotes.length) {
          this.historyNotes[index] = newContent;
          await storage.saveHistoryNotes(this.historyNotes);
          this.filterNotes(); // 更新过滤列表
        }
      }
      
      // 处理当前笔记更新
      if (result.currentNote !== undefined) {
        this.currentNote = result.currentNote;
        await storage.saveCurrentNote(this.currentNote);
      }
      
      // 如果笔记已保存到历史记录，刷新历史笔记列表
      if (result.noteSaved) {
        const savedNotes = await storage.getHistoryNotes();
        this.historyNotes = savedNotes;
        this.filterNotes();
      }
    }

    // 检查当前笔记是否有更新（AI分析可能已完成）
    const savedCurrentNote = await storage.getCurrentNote();
    if (savedCurrentNote !== this.currentNote) {
      this.currentNote = savedCurrentNote;
    }

    // 刷新历史笔记列表（AI分析可能已更新了历史笔记）
    const savedNotes = await storage.getHistoryNotes();
    if (JSON.stringify(savedNotes) !== JSON.stringify(this.historyNotes)) {
      this.historyNotes = savedNotes;
      this.filterNotes();
    }

    const savedCustomTemplates = await storage.getCustomTemplates();
    this.customTemplates = savedCustomTemplates;
    this.allTemplates = [...this.defaultTemplates, ...this.customTemplates];

    // 新增：保存健康数据
    await this.saveHealthData();
  }

  // 打开笔记编辑器
  openNoteEditor() {
    router.pushUrl({
      url: 'pages/NoteEditor',
      params: {
        currentNote: this.currentNote
      }
    });
  }

  // 新增：保存健康数据
  async saveHealthData() {
    const today = new Date().toDateString();
    const healthData: HealthData = {
      waterCount: this.waterCount,
      sleepHours: this.sleepHours,
      stepsCount: this.stepsCount,
      mood: this.mood,
      lastResetDate: this.lastResetDate || today,
      waterGoal: this.waterGoal,
      sleepGoal: this.sleepGoal,
      stepsGoal: this.stepsGoal
    };
    await storage.saveHealthData(healthData);
    
    // 同时保存每日健康记录
    const todayStr = new Date().toISOString().split('T')[0]; // YYYY-MM-DD格式
    const dailyRecord: DailyHealthRecord = {
      date: todayStr,
      waterCount: this.waterCount,
      sleepHours: this.sleepHours,
      stepsCount: this.stepsCount,
      mood: this.mood
    };
    await storage.saveDailyHealthRecord(dailyRecord);
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
      promptAction.showToast({
        message: '笔记内容不能为空',
        duration: 2000
      });
      return;
    }

    this.historyNotes.unshift(this.currentNote.trim());
    this.currentNote = '';
    this.filteredNotes = this.historyNotes;

    await storage.saveHistoryNotes(this.historyNotes);
    await storage.saveCurrentNote('');
    
    promptAction.showToast({
      message: '笔记保存成功',
      duration: 2000
    });
  }

  async deleteNote(index: number) {
    // 显示确认对话框
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条笔记吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        // 用户点击了删除
        const originalIndex = this.historyNotes.indexOf(this.filteredNotes[index]);
        this.historyNotes.splice(originalIndex, 1);
        this.filterNotes();
        storage.saveHistoryNotes(this.historyNotes);
        promptAction.showToast({
          message: '笔记已删除',
          duration: 2000
        });
      }
    }).catch((err: Error) => {
      console.error(`删除确认对话框错误: ${err}`);
    });
  }

  // 搜索笔记
  filterNotes() {
    if (this.searchKeyword.trim() === '') {
      this.filteredNotes = this.historyNotes;
    } else {
      this.filteredNotes = this.historyNotes.filter(note =>
        note.toLowerCase().includes(this.searchKeyword.toLowerCase())
      );
    }
  }

  // 分享笔记
  async shareNote(note: string) {
    promptAction.showToast({
      message: '分享功能：可以复制笔记内容后分享',
      duration: 3000
    });
    // 注意：鸿蒙系统的分享功能需要更复杂的配置，这里先提示用户
  }

  // 获取笔记字数
  getNoteWordCount(note: string): number {
    return note.replace(/\s/g, '').length;
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

  // 新增：同步华为运动健康数据
  async syncHealthKitData() {
    const context = getContext(this) as common.UIAbilityContext;
    if (!context) {
      promptAction.showToast({
        message: '无法获取应用上下文',
        duration: 2000
      });
      return;
    }

    this.isSyncing = true;
    try {
      // 检查Health Kit是否可用
      const isAvailable = await HealthKitSync.isHealthKitAvailable(context);
      if (!isAvailable) {
        promptAction.showToast({
          message: '功能待开发，敬请期待',
          duration: 3000
        });
        this.isSyncing = false;
        return;
      }

      // 请求权限
      const hasPermission = await HealthKitSync.requestHealthKitPermission(context);
      if (!hasPermission) {
        promptAction.showToast({
          message: '需要Health Kit权限才能同步数据',
          duration: 3000
        });
        this.isSyncing = false;
        return;
      }

      // 获取当前健康数据
      const currentHealthData: HealthData = {
        waterCount: this.waterCount,
        sleepHours: this.sleepHours,
        stepsCount: this.stepsCount,
        mood: this.mood,
        lastResetDate: this.lastResetDate,
        waterGoal: this.waterGoal,
        sleepGoal: this.sleepGoal,
        stepsGoal: this.stepsGoal
      };

      // 同步数据
      const syncedData = await HealthKitSync.syncAllHealthData(context, currentHealthData);

      // 更新本地数据
      if (syncedData.stepsCount > 0 && syncedData.stepsCount !== this.stepsCount) {
        this.stepsCount = syncedData.stepsCount;
        promptAction.showToast({
          message: `已同步步数：${syncedData.stepsCount}步`,
          duration: 2000
        });
      }

      if (syncedData.sleepHours > 0 && syncedData.sleepHours !== this.sleepHours) {
        this.sleepHours = syncedData.sleepHours;
        promptAction.showToast({
          message: `已同步睡眠：${syncedData.sleepHours}小时`,
          duration: 2000
        });
      }

      // 保存更新后的数据
      await this.saveHealthData();

      if (syncedData.stepsCount === this.stepsCount && syncedData.sleepHours === this.sleepHours) {
        promptAction.showToast({
          message: '数据已是最新，无需同步',
          duration: 2000
        });
      }
    } catch (error) {
      console.error(`同步健康数据失败: ${error}`);
      promptAction.showToast({
        message: '同步失败，请稍后重试',
        duration: 2000
      });
    } finally {
      this.isSyncing = false;
    }
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

    // 获取历史笔记内容
    let notesContext = '';
    try {
      const historyNotes = await storage.getHistoryNotes();
      if (historyNotes && historyNotes.length > 0) {
        // 限制笔记数量，避免token过多（取最近20条）
        const recentNotes = historyNotes.slice(0, 20);
        notesContext = '\n\n用户的历史笔记内容（供参考）：\n';
        recentNotes.forEach((note: string, index: number) => {
          if (note && note.trim().length > 0) {
            notesContext += `笔记${index + 1}：${note.substring(0, 200)}${note.length > 200 ? '...' : ''}\n\n`;
          }
        });
        notesContext += '你可以参考这些历史笔记内容，结合用户的健康数据，提供更个性化的健康建议。';
      }
    } catch (error) {
      console.error(`获取历史笔记失败: ${error}`);
    }

    // 准备健康数据
    const healthDataStr = `健康数据：
- 饮水量：${this.waterCount}杯
- 睡眠时间：${this.sleepHours}小时
- 步数：${this.stepsCount}步
- 心情：${this.mood}${notesContext}`;

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
                  + '5. 结合用户的健康数据和历史笔记内容，给出具体的、可操作的建议\n'
                  + '6. 你可以访问用户的历史笔记内容，这些笔记可能包含用户的生活习惯、饮食记录、健康问题等信息，请结合这些信息提供更个性化的建议\n'
                  + '对话禁止出现md格式的文档，严格按照正常的普通文本格式输出\n'
                  + '对话禁止出现特殊符号，比如"#"和"*"\n'
                  + '当用户问到关于吃饭、做饭、吃什么等问题时，你可以提供健康饮食建议和食谱推荐。\n'
                  + '健康饮食知识如下：\n'
                  + '推荐食物：营养助力健康\n'
                  + '1. Omega-3脂肪酸的食物\n'
                  + '推荐种类：深海鱼类（三文鱼、鲭鱼）、亚麻籽及核桃等富含Omega-3脂肪酸的食物。\n'
                  + '作用：有助于抗炎、保护心血管健康、促进大脑发育。\n'
                  + '建议：每周摄入深海鱼类2-3次（单次建议量150-200g），或每日补充亚麻籽油15-20mL（约一汤匙）。\n'
                  + '2. 抗氧化蔬果\n'
                  + '推荐种类：西兰花、蓝莓、胡萝卜、紫甘蓝、南瓜、番茄、菠菜等。\n'
                  + '作用：通过中和氧自由基，减少氧化损伤，增强免疫力。\n'
                  + '建议：每日摄入至少5种不同颜色的蔬果，保证营养均衡。\n'
                  + '3. 优质蛋白质摄入\n'
                  + '植物蛋白：推荐豆腐、豆浆、豆类等，有助于降低胆固醇。\n'
                  + '动物蛋白：建议选用低脂乳制品（脱脂牛奶、酸奶）、瘦肉、鱼类、鸡蛋等。\n'
                  + '作用：维持肌肉量，促进组织修复，增强免疫力。\n'
                  + '4. 低盐、低脂饮食\n'
                  + '盐分控制：建议每日食盐摄入量＜5克，严格限制腌制食品、加工肉制品。\n'
                  + '健康油脂：推荐使用橄榄油、茶籽油等植物油替代动物油。\n'
                  + '作用：降低高血压、心血管疾病风险。\n'
                  + '5. 补钙与维生素D\n'
                  + '高钙食物：黑芝麻、虾皮、奶制品、豆制品、绿叶蔬菜等。\n'
                  + '维生素D来源：适量晒太阳、食用富含维生素D的食物（如鱼类、蛋黄），必要时可补充维生素D。\n'
                  + '作用：维持骨骼健康，预防骨质疏松。\n'
                  + '需谨慎或避免的食物\n'
                  + '1. 高盐、高糖、高脂食品\n'
                  + '腌制食品（咸菜、腊肉）、甜点、油炸食品、肥肉等可能增加心血管疾病风险，应适量摄入。\n'
                  + '2. 过度加工食品\n'
                  + '含有大量添加剂、防腐剂的加工食品，营养价值低，应尽量选择天然食物。\n'
                  + '3. 过量酒精\n'
                  + '过量饮酒可能加重肝脏负担，影响健康，建议适量或避免饮酒。\n'
                  + '4. 含糖饮料\n'
                  + '碳酸饮料、果汁饮料等含糖量高，建议多喝白开水、淡茶等。\n'
                  + '健康饮食原则\n'
                  + '1. 均衡营养：保证碳水化合物、蛋白质、脂肪、维生素、矿物质的均衡摄入。\n'
                  + '2. 适量原则：控制总热量摄入，避免暴饮暴食。\n'
                  + '3. 多样化：食物种类多样化，保证营养全面。\n'
                  + '4. 规律饮食：定时定量，三餐规律，避免过度节食或暴食。\n'
                  + '5. 个体化：根据个人身体状况、活动量、年龄等因素调整饮食方案。\n'
                  + '当用户询问饮食问题时，请结合以上健康饮食知识和用户的历史笔记内容，提供科学、实用的建议。`;'
              } as Message,
              ...this.aiMessages,
              {
                role: 'system',
                content: healthDataStr
              } as Message
            ] as Message[],
            max_tokens: 2000
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
    Scroll() {
      Column() {
        // 顶部导航栏
        Row() {
          Text('EyesNote')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor'))
          Blank()
          Image($r("app.media.ic_setting"))
            .width(28)
            .height(28)
            .padding(4)
            .onClick(() => {
              router.pushUrl({ url: 'pages/Settings' });
            })
        }
        .width('100%')
        .height(56)
        .padding({
          left: 20,
          right: 20,
          top: 8,
          bottom: 8
        })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      // 模板卡片
      Column() {
        Row() {
          Text('📋 快速模板')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
          .fontColor(this.getThemeColor('textColor'))
          Blank()
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })

        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.allTemplates, (template: Template) => {
              Column({ space: 10 }) {
                // 图标和名称
                Column({ space: 6 }) {
                  Text(template.icon)
                    .fontSize(32)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .margin({ top: 8 })
                  
                  Text(template.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.getThemeColor('textColor'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .textAlign(TextAlign.Center)
                    .padding({ left: 8, right: 8 })
                  
                  // 描述
                  if (template.description) {
                    Text(template.description)
                      .fontSize(11)
                      .fontColor('#999999')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .textAlign(TextAlign.Center)
                      .padding({ left: 8, right: 8, bottom: 4 })
                  }
                  
                  // 分类标签
                  if (template.category) {
                    Text(template.category)
                      .fontSize(10)
                      .fontColor('#007AFF')
                      .backgroundColor('#E3F2FD')
                      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      .borderRadius(8)
                      .margin({ top: 4 })
                  }
                }
                .width('100%')
                .layoutWeight(1)
                
                // 使用按钮
                Button('使用')
                  .width('100%')
                  .height(36)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.getThemeColor('accentColor'))
                  .borderRadius(8)
                  .margin({ bottom: 12, left: 12, right: 12 })
                  .onClick(() => {
                    this.currentNote = template.content;
                    promptAction.showToast({
                      message: `已应用模板：${template.name}`,
                      duration: 1500
                    });
                  })
              }
              .width(140)
              .height(180)
              .backgroundColor(this.getThemeColor('cardColor'))
              .borderRadius(16)
              .shadow({
                radius: 8,
                color: '#00000012',
                offsetX: 0,
                offsetY: 4
              })
              .onClick(() => {
                // 点击卡片也可以使用模板
                this.currentNote = template.content;
                promptAction.showToast({
                  message: `已应用模板：${template.name}`,
                  duration: 1500
                });
              })
            }, (template: Template) => template.id)
          }
          .padding({ left: 20, right: 20 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .edgeEffect(EdgeEffect.Spring)
      }
      .padding({ top: 20, bottom: 16 })

      Divider().strokeWidth(0.5).color('#E5E5EA').margin({ left: 20, right: 20 })

      // 当前笔记输入区
      Column({ space: 12 }) {
        Row() {
          Text('当前笔记')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getThemeColor('textColor'))
          Blank()
          Text(`${this.getNoteWordCount(this.currentNote)} 字`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')

        Stack() {
          TextInput({ placeholder: '点击进入编辑模式…', text: $$this.currentNote })
            .width('100%')
            .height(120)
            .backgroundColor(this.getThemeColor('cardColor'))
            .borderRadius(12)
            .padding(16)
            .fontSize(15)
            .fontColor(this.getThemeColor('textColor'))
            .placeholderColor('#999999')
            .enabled(false)
          
          // 可点击的覆盖层
          Row()
            .width('100%')
            .height(120)
            .onClick(() => {
              this.openNoteEditor();
            })
        }
        .width('100%')
        .height(120)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })

      Divider().strokeWidth(0.5).color('#E5E5EA').margin({ left: 20, right: 20 })

      // 历史笔记列表
      Column() {
        Row() {
          Text('历史笔记')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getThemeColor('textColor'))
          Blank()
          // 搜索按钮
          Text(this.showSearch ? '取消' : '🔍')
            .fontSize(18)
            .fontColor(this.getThemeColor('textColor'))
            .onClick(() => {
              this.showSearch = !this.showSearch;
              if (!this.showSearch) {
                this.searchKeyword = '';
                this.filterNotes();
              }
            })
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })

        // 搜索框
        if (this.showSearch) {
          Row({ space: 8 }) {
            TextInput({ placeholder: '搜索笔记...', text: $$this.searchKeyword })
              .layoutWeight(1)
              .height(40)
              .backgroundColor(this.getThemeColor('cardColor'))
              .borderRadius(20)
              .padding({ left: 16, right: 16 })
              .fontSize(14)
              .onChange((value: string) => {
                this.searchKeyword = value;
                this.filterNotes();
              })
            if (this.searchKeyword.length > 0) {
              Image($r('app.media.ic_close'))
                .width(20)
                .height(20)
                .onClick(() => {
                  this.searchKeyword = '';
                  this.filterNotes();
                })
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 12 })
        }

        Column({ space: 12 }) {
          if (this.filteredNotes.length === 0) {
            Column() {
              Text('暂无笔记')
                .fontSize(16)
                .fontColor('#999999')
                .margin({ top: 40, bottom: 40 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.filteredNotes, (note: string, index: number) => {
              Row({ space: 12 }) {
                Column({ space: 6 }) {
                  Text(note)
                    .fontSize(15)
                    .maxLines(2)
                    .fontColor(this.getThemeColor('textColor'))
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .lineHeight(22)
                    .width('100%')
                  Row() {
                    Text(`${this.getNoteWordCount(note)} 字`)
                      .fontSize(12)
                      .fontColor('#999999')
                    Blank()
                  }
                  .width('100%')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                
                Row({ space: 4 }) {
                  Image($r('app.media.ic_about'))
                    .width(30)
                    .height(30)
                  .fillColor(this.getThemeColor('accentColor'))
                    .padding(6)
                    .onClick(() => {
                      this.shareNote(note);
                    })
                  Image($r('app.media.ic_delete'))
                    .width(30)
                    .height(30)
                    .padding(6)
                    .onClick(() => {
                      this.deleteNote(index);
                    })
                }
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor(this.getThemeColor('cardColor'))
              .borderRadius(12)
              .shadow({
                radius: 2,
                color: '#00000006',
                offsetX: 0,
                offsetY: 1
              })
              .onClick(() => {
                const originalIndex = this.historyNotes.indexOf(note);
                this.openNoteDetail(note, originalIndex);
              })
            }, (note: string, index: number) => `${note}_${index}`)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .padding({ top: 8 })
      .width('100%')
      .margin({ bottom: 20 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }

  // 健康页面UI
  @Builder
  HealthPage() {
    Scroll() {
      Column({ space: 20 }) {
        // 顶部标题和同步按钮
        Row() {
          Text('健康追踪')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColor('textColor'))
          Blank()
          Button(this.isSyncing ? '同步中...' : '🔄 同步')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor'))
            .borderRadius(16)
            .height(32)
            .padding({ left: 12, right: 12 })
            .enabled(!this.isSyncing)
            .onClick(() => {
              this.syncHealthKitData();
            })
        }
        .width('100%')
        .margin({ top: 24, bottom: 8 })
        .padding({ left: 20, right: 20 })

        // 饮水追踪
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
            Text('💧 今日饮水')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
                .fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.waterGoal}杯`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')

            Text(`${this.waterCount} / ${this.waterGoal} 杯`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007AFF')
              .margin({ top: 8, bottom: 8 })

            // 进度条
            Row() {
              Row()
                .width(`${Math.min(100, (this.waterCount / this.waterGoal) * 100)}%`)
                .height(6)
                .backgroundColor('#007AFF')
                .borderRadius(3)
              Row()
                .layoutWeight(1)
                .height(6)
                .backgroundColor('#E5E5EA')
                .borderRadius(3)
            }
            .width('100%')
            .height(6)
            .borderRadius(3)
            .backgroundColor('#E5E5EA')

            Row({ space: 16 }) {
              Button('-')
                .width(48)
                .height(48)
                .borderRadius(24)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF3B30')
                .onClick((): void => this.decrementWater())

              Button('+')
                .width(48)
                .height(48)
                .borderRadius(24)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .backgroundColor('#34C759')
                .onClick((): void => this.incrementWater())
            }
          }
          .width('100%')
          .padding(24)
        }

        // 睡眠记录
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
            Text('😴 睡眠时间')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
                .fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.sleepGoal}小时`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')

            Text(`${this.sleepHours} / ${this.sleepGoal} 小时`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#34C759')
              .margin({ top: 8, bottom: 8 })

            // 进度条
            Row() {
              Row()
                .width(`${Math.min(100, (this.sleepHours / this.sleepGoal) * 100)}%`)
                .height(6)
                .backgroundColor('#34C759')
                .borderRadius(3)
              Row()
                .layoutWeight(1)
                .height(6)
                .backgroundColor('#E5E5EA')
                .borderRadius(3)
            }
            .width('100%')
            .height(6)
            .borderRadius(3)
            .backgroundColor('#E5E5EA')

            Row({ space: 16 }) {
              Button('-')
                .width(48)
                .height(48)
                .borderRadius(24)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF3B30')
                .onClick((): void => this.changeSleep(-1))

              Button('+')
                .width(48)
                .height(48)
                .borderRadius(24)
                .fontSize(20)
                .fontColor('#FFFFFF')
                .backgroundColor('#34C759')
                .onClick((): void => this.changeSleep(1))
            }
          }
          .width('100%')
          .padding(24)
        }

        // 步数统计
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
            Text('🚶 今日步数')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
                .fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.stepsGoal}步`)
                .fontSize(12)
                .fontColor('#666666')
            }
            .width('100%')

            Text(`${this.stepsCount} / ${this.stepsGoal} 步`)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FF9500')
              .margin({ top: 8, bottom: 8 })

            // 进度条
            Row() {
              Row()
                .width(`${Math.min(100, (this.stepsCount / this.stepsGoal) * 100)}%`)
                .height(6)
                .backgroundColor('#FF9500')
                .borderRadius(3)
              Row()
                .layoutWeight(1)
                .height(6)
                .backgroundColor('#E5E5EA')
                .borderRadius(3)
            }
            .width('100%')
            .height(6)
            .borderRadius(3)
            .backgroundColor('#E5E5EA')

            Row({ space: 16 }) {
              Button('-100')
                .width(72)
                .height(48)
                .borderRadius(24)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor('#FF3B30')
                .onClick((): void => this.decrementSteps())

              Button('+100')
                .width(72)
                .height(48)
                .borderRadius(24)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .backgroundColor('#34C759')
                .onClick((): void => this.incrementSteps())
            }
          }
          .width('100%')
          .padding(24)
        }

        // 心情记录
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Text('😊 今日心情')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getThemeColor('textColor'))

            Text(this.mood)
              .fontSize(32)
              .fontWeight(FontWeight.Bold)
              .fontColor('#AF52DE')
              .margin({ top: 8, bottom: 8 })

            Row({ space: 10 }) {
              ForEach(['开心', '平静', '疲惫', '焦虑', '兴奋'], (moodOption: string) => {
                Button(moodOption)
                  .height(40)
                  .borderRadius(20)
                  .fontSize(14)
                  .fontColor(this.mood === moodOption ? '#FFFFFF' : this.getThemeColor('textColor'))
                  .backgroundColor(this.mood === moodOption ? '#AF52DE' : '#F2F2F7')
                  .onClick((): void => this.changeMood(moodOption))
              })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceEvenly)
            .padding({ top: 4 })
          }
          .width('100%')
          .padding(24)
        }

        // 健康目标设置
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Text('🎯 健康目标设置')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getThemeColor('textColor'))
              .width('100%')

            // 饮水目标
            Column({ space: 10 }) {
              Row() {
                Text('💧 饮水目标')
                  .fontSize(15)
                  .fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.waterGoal} 杯`)
                  .fontSize(15)
                  .fontColor('#007AFF')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              Row({ space: 12 }) {
                Button('-')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#FF3B30')
                  .borderRadius(20)
                  .onClick(() => {
                    if (this.waterGoal > 1) {
                      this.waterGoal -= 1;
                      this.saveHealthData();
                    }
                  })
                Button('+')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#34C759')
                  .borderRadius(20)
                  .onClick(() => {
                    this.waterGoal += 1;
                    this.saveHealthData();
                  })
              }
              .width('100%')
            }
            .width('100%')

            Divider()
              .strokeWidth(0.5)
              .color('#E5E5EA')
              .margin({ top: 8, bottom: 8 })

            // 睡眠目标
            Column({ space: 10 }) {
              Row() {
                Text('😴 睡眠目标')
                  .fontSize(15)
                  .fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.sleepGoal} 小时`)
                  .fontSize(15)
                  .fontColor('#34C759')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              Row({ space: 12 }) {
                Button('-')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#FF3B30')
                  .borderRadius(20)
                  .onClick(() => {
                    if (this.sleepGoal > 1) {
                      this.sleepGoal -= 1;
                      this.saveHealthData();
                    }
                  })
                Button('+')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#34C759')
                  .borderRadius(20)
                  .onClick(() => {
                    this.sleepGoal += 1;
                    this.saveHealthData();
                  })
              }
              .width('100%')
            }
            .width('100%')

            Divider()
              .strokeWidth(0.5)
              .color('#E5E5EA')
              .margin({ top: 8, bottom: 8 })

            // 步数目标
            Column({ space: 10 }) {
              Row() {
                Text('🚶 步数目标')
                  .fontSize(15)
                  .fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.stepsGoal} 步`)
                  .fontSize(15)
                  .fontColor('#FF9500')
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')
              Row({ space: 12 }) {
                Button('-1000')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#FF3B30')
                  .borderRadius(20)
                  .onClick(() => {
                    if (this.stepsGoal >= 1000) {
                      this.stepsGoal -= 1000;
                      this.saveHealthData();
                    }
                  })
                Button('+1000')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor('#34C759')
                  .borderRadius(20)
                  .onClick(() => {
                    this.stepsGoal += 1000;
                    this.saveHealthData();
                  })
              }
              .width('100%')
            }
            .width('100%')
          }
          .width('100%')
          .padding(24)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }

  // ai页面UI
  @Builder
  AIPage() {
    Column() {
      // 顶部标题
      Column() {
        Text('健康Deepseek')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor'))
        Text('您的专属健康顾问')
          .fontSize(12)
          .fontColor(this.getThemeColor('mutedTextColor'))
          .margin({ top: 4 })
      }
      .width('100%')
      .height(66)
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(this.getThemeColor('backgroundColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      // 聊天记录
      Scroll() {
        Column() {
          ForEach(this.aiMessages, (message: Message, index: number) => {
            if (message.role === 'user') {
              // 用户消息 - 右侧对齐的气泡
              Row() {
                Blank()
                Column() {
                  Text(message.content)
                    .fontSize(15)
                    .fontColor('#FFFFFF')
                    .lineHeight(22)
                    .backgroundColor(this.getThemeColor('accentColor'))
                    .padding({
                      top: 14,
                      bottom: 14,
                      left: 18,
                      right: 18
                    })
                    .borderRadius({
                      topLeft: 20,
                      topRight: 6,
                      bottomLeft: 20,
                      bottomRight: 20
                    })
                    .constraintSize({ maxWidth: '75%' })
                }
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 10,
                bottom: 10
              })
            } else {
              // AI消息 - 左侧对齐的气泡，带头像
              Row() {
                Image($r('app.media.ic_ai'))
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                  .margin({ right: 12 })
                Column() {
                  Text(message.content)
                    .fontSize(15)
                    .fontColor(this.getThemeColor('textColor'))
                    .lineHeight(22)
                    .backgroundColor(this.getThemeColor('cardColor'))
                    .padding({
                      top: 14,
                      bottom: 14,
                      left: 18,
                      right: 18
                    })
                    .borderRadius({
                      topLeft: 6,
                      topRight: 20,
                      bottomLeft: 20,
                      bottomRight: 20
                    })
                    .constraintSize({ maxWidth: '75%' })
                    .shadow({
                      radius: 3,
                      color: '#00000008',
                      offsetX: 0,
                      offsetY: 2
                    })
                }

                Blank()
              }
              .width('100%')
              .padding({
                left: 20,
                right: 20,
                top: 10,
                bottom: 10
              })
              .alignItems(VerticalAlign.Top)
            }
          })

          // 新增：AI正在思考的加载动画
          if (this.isAIChatting) {
            Row() {
              Image($r('app.media.ic_ai'))
                .width(40)
                .height(40)
                .borderRadius(20)
                .margin({ right: 12 })
              Column() {
                Row() {
                  LoadingProgress()
                    .color(this.getThemeColor('accentColor'))
                    .width(18)
                    .height(18)
                  Text('AI正在思考...')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ left: 10 })
                }
                .padding({
                  top: 14,
                  bottom: 14,
                  left: 18,
                  right: 18
                })
                .backgroundColor(this.getThemeColor('cardColor'))
                .borderRadius({
                  topLeft: 6,
                  topRight: 20,
                  bottomLeft: 20,
                  bottomRight: 20
                })
                .shadow({
                  radius: 3,
                  color: '#00000008',
                  offsetX: 0,
                  offsetY: 2
                })
              }

              Blank()
            }
            .width('100%')
            .padding({
              left: 20,
              right: 20,
              top: 10,
              bottom: 10
            })
            .alignItems(VerticalAlign.Top)
          }
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      // 输入区域
      Row({ space: 12 }) {
        TextInput({
          placeholder: '输入你的问题...',
          text: $$this.aiInput
        })
          .layoutWeight(1)
          .height(50)
          .backgroundColor(this.getThemeColor('cardColor'))
          .borderRadius(25)
          .padding({ left: 18, right: 18 })
          .fontSize(15)
          .fontColor(this.getThemeColor('textColor'))
          .placeholderColor('#999999')

        Button('发送')
          .width(70)
          .height(50)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getThemeColor('accentColor'))
          .borderRadius(25)
          .onClick(() => {
            this.sendAIMessage();
          })
          .enabled(!this.isAIChatting)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 16 })
      .backgroundColor(this.getThemeColor('backgroundColor'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
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
        Column({ space: 4 }) {
          Image($r('app.media.ic_edit'))
            .width(26)
            .height(26)
            .fillColor(this.selectedIndex === 0 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('笔记')
            .fontSize(12)
            .fontColor(this.selectedIndex === 0 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 0 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 0;
        })
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })

        // 健康页面按钮
        Column({ space: 4 }) {
          Image($r('app.media.ic_right'))
            .width(26)
            .height(26)
            .fillColor(this.selectedIndex === 1 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('健康')
            .fontSize(12)
            .fontColor(this.selectedIndex === 1 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 1 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 1;
        })
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })

        // AI页面按钮
        Column({ space: 4 }) {
          Image($r('app.media.ic_ai'))
            .width(26)
            .height(26)
            .fillColor(this.selectedIndex === 2 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
          Text('健康Deepseek')
            .fontSize(11)
            .fontColor(this.selectedIndex === 2 ? this.getThemeColor('accentColor') : this.getThemeColor('mutedTextColor'))
            .fontWeight(this.selectedIndex === 2 ? FontWeight.Medium : FontWeight.Normal)
        }
        .layoutWeight(1)
        .onClick(() => {
          this.selectedIndex = 2;
        })
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 8, bottom: 8 })
      }
      .width('100%')
      .height(64)
      .backgroundColor(this.getThemeColor('cardColor'))
      .border({ width: { top: 0.5 }, color: '#E5E5EA' })
      .shadow({
        radius: 8,
        color: '#00000008',
        offsetX: 0,
        offsetY: -2
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}

// 卡片样式组件
@Component
struct Card {
  @BuilderParam content: () => void
  @Prop cardColor: string = '#FFFFFF'

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .backgroundColor(this.cardColor)
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#0000001A',
      offsetX: 0,
      offsetY: 2
    })
  }
}