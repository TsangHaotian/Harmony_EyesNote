import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { HealthData, DailyHealthRecord, StatisticsData, HealthScore, HealthAnalysis, Template, ThemePreset, Message } from './Types'; // 导入共享接口
import { HealthCalculator } from './HealthCalculator';

class StorageManager {
  private static instance: StorageManager;
  private pref: preferences.Preferences | null = null;

  private constructor() {}

  /**
   * 获取单例实例
   */
  public static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager();
    }
    return StorageManager.instance;
  }

  /**
   * 初始化首选项
   * @param context 应用上下文
   */
  public async init(context: common.UIAbilityContext): Promise<void> {
    if (!this.pref) {
      try {
        this.pref = await preferences.getPreferences(context, 'noteApp');
        console.log('首选项初始化成功');
      } catch (error) {
        console.error(`首选项初始化失败: ${error}`);
        throw new Error(error);
      }
    }
  }

  /**
   * 保存历史笔记
   * @param notes 历史笔记数组
   */
  public async saveHistoryNotes(notes: string[]): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('historyNotes', JSON.stringify(notes));
      await this.pref.flush();
      console.log('历史笔记保存成功');
    } catch (error) {
      console.error(`历史笔记保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取历史笔记
   * @returns 历史笔记数组
   */
  public async getHistoryNotes(): Promise<string[]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const notesStr = await this.pref.get('historyNotes', '[]');
      return JSON.parse(notesStr as string) as string[];
    } catch (error) {
      console.error(`历史笔记获取失败: ${error}`);
      return [];
    }
  }

  /**
   * 保存当前笔记
   * @param note 当前笔记内容
   */
  public async saveCurrentNote(note: string): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('currentNote', note);
      await this.pref.flush();
      console.log('当前笔记保存成功');
    } catch (error) {
      console.error(`当前笔记保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取当前笔记
   * @returns 当前笔记内容
   */
  public async getCurrentNote(): Promise<string> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      return await this.pref.get('currentNote', '') as string;
    } catch (error) {
      console.error(`当前笔记获取失败: ${error}`);
      return '';
    }
  }

  /**
   * 保存自定义模板
   * @param templates 自定义模板数组
   */
  public async saveCustomTemplates(templates: Template[]): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('customTemplates', JSON.stringify(templates));
      await this.pref.flush();
      console.log('自定义模板保存成功');
    } catch (error) {
      console.error(`自定义模板保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取自定义模板
   * @returns 自定义模板数组
   */
  public async getCustomTemplates(): Promise<Template[]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const templatesStr = await this.pref.get('customTemplates', '[]');
      const parsed: string[] | Template[] = JSON.parse(templatesStr as string) as string[] | Template[];
      // 兼容旧格式：如果是string[]，转换为Template[]
      if (Array.isArray(parsed) && parsed.length > 0 && typeof parsed[0] === 'string') {
        const stringTemplates = parsed as string[];
        return stringTemplates.map((content: string, index: number): Template => {
          const template: Template = {
            id: `custom_${index}`,
            name: `自定义模板${index + 1}`,
            icon: '📄',
            content: content,
            category: '自定义'
          };
          return template;
        });
      }
      return parsed as Template[];
    } catch (error) {
      console.error(`自定义模板获取失败: ${error}`);
      return [];
    }
  }

  /**
   * 保存主题偏好
   */
  public async saveThemePreference(themeId: string): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('themePreset', themeId);
      await this.pref.flush();
    } catch (error) {
      console.error(`主题偏好保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 读取主题偏好
   */
  public async getThemePreference(): Promise<string> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      return await this.pref.get('themePreset', '') as string;
    } catch (error) {
      console.error(`主题偏好获取失败: ${error}`);
      return '';
    }
  }

  /**
   * 保存自定义主题
   */
  public async saveCustomThemePreset(theme: ThemePreset | null): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const value: string = theme ? JSON.stringify(theme) : '';
      await this.pref.put('customThemePreset', value);
      await this.pref.flush();
    } catch (error) {
      console.error(`自定义主题保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取自定义主题
   */
  public async getCustomThemePreset(): Promise<ThemePreset | null> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const themeStr = await this.pref.get('customThemePreset', '');
      if (!themeStr || themeStr === '') {
        return null;
      }
      return JSON.parse(themeStr as string) as ThemePreset;
    } catch (error) {
      console.error(`自定义主题获取失败: ${error}`);
      return null;
    }
  }

  // 保存健康数据方法
  public async saveHealthData(healthData: HealthData): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('healthData', JSON.stringify(healthData));
      await this.pref.flush();
      console.log('健康数据保存成功');
    } catch (error) {
      console.error(`健康数据保存失败: ${error}`);
      throw new Error(error);
    }
  }

  // 获取健康数据方法
  public async getHealthData(): Promise<HealthData> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const data = await this.pref.get('healthData', '{}');
      return JSON.parse(data as string) as HealthData;
    } catch (error) {
      console.error(`健康数据获取失败: ${error}`);
      return { waterCount: 0, sleepHours: 7, stepsCount: 0, mood: '开心' };
    }
  }

  /**
   * 保存每日健康记录
   * @param record 每日健康记录
   */
  public async saveDailyHealthRecord(record: DailyHealthRecord): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const records = await this.getDailyHealthRecords();
      // 检查是否已存在该日期的记录
      const index = records.findIndex(r => r.date === record.date);
      if (index >= 0) {
        records[index] = record; // 更新
      } else {
        records.push(record); // 新增
      }
      await this.pref.put('dailyHealthRecords', JSON.stringify(records));
      await this.pref.flush();
      console.log('每日健康记录保存成功');
    } catch (error) {
      console.error(`每日健康记录保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取所有每日健康记录
   * @returns 每日健康记录数组
   */
  public async getDailyHealthRecords(): Promise<DailyHealthRecord[]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const recordsStr = await this.pref.get('dailyHealthRecords', '[]');
      return JSON.parse(recordsStr as string) as DailyHealthRecord[];
    } catch (error) {
      console.error(`每日健康记录获取失败: ${error}`);
      return [];
    }
  }

  /**
   * 获取统计数据
   */
  public async getStatisticsData(): Promise<StatisticsData> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const notes = await this.getHistoryNotes();
      const records = await this.getDailyHealthRecords();
      
      // 计算总字数
      const totalWords = notes.reduce((sum, note) => sum + note.replace(/\s/g, '').length, 0);
      
      // 计算健康数据平均值
      let avgWater = 0;
      let avgSleep = 0;
      let avgSteps = 0;
      const moodCount: Record<string, number> = {};
      
      if (records.length > 0) {
        avgWater = records.reduce((sum, r) => sum + r.waterCount, 0) / records.length;
        avgSleep = records.reduce((sum, r) => sum + r.sleepHours, 0) / records.length;
        avgSteps = records.reduce((sum, r) => sum + r.stepsCount, 0) / records.length;
        
        records.forEach(r => {
          moodCount[r.mood] = (moodCount[r.mood] || 0) + 1;
        });
      }
      
      // 找出最常见的心情
      let mostCommonMood = '开心';
      let maxCount = 0;
      const moodKeys = Object.keys(moodCount);
      for (let i = 0; i < moodKeys.length; i++) {
        const mood = moodKeys[i];
        if (moodCount[mood] > maxCount) {
          maxCount = moodCount[mood];
          mostCommonMood = mood;
        }
      }
      
      return {
        totalNotes: notes.length,
        totalWords: totalWords,
        avgWaterCount: Math.round(avgWater * 10) / 10,
        avgSleepHours: Math.round(avgSleep * 10) / 10,
        avgStepsCount: Math.round(avgSteps),
        healthRecordsCount: records.length,
        mostCommonMood: mostCommonMood
      };
    } catch (error) {
      console.error(`统计数据获取失败: ${error}`);
      return {
        totalNotes: 0,
        totalWords: 0,
        avgWaterCount: 0,
        avgSleepHours: 0,
        avgStepsCount: 0,
        healthRecordsCount: 0,
        mostCommonMood: '开心'
      };
    }
  }

  /**
   * 导出所有数据为JSON字符串
   */
  public async exportAllData(): Promise<string> {
    try {
      const notes = await this.getHistoryNotes();
      const healthData = await this.getHealthData();
      const records = await this.getDailyHealthRecords();
      const templates = await this.getCustomTemplates();
      
      interface ExportData {
        exportTime: string;
        version: string;
        notes: string[];
        healthData: HealthData;
        dailyHealthRecords: DailyHealthRecord[];
        customTemplates: Template[];
      }
      
      const exportData: ExportData = {
        exportTime: new Date().toISOString(),
        version: '1.0.0',
        notes: notes,
        healthData: healthData,
        dailyHealthRecords: records,
        customTemplates: templates
      };
      
      return JSON.stringify(exportData, null, 2);
    } catch (error) {
      console.error(`数据导出失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取健康评分
   */
  public async getHealthScore(): Promise<HealthScore> {
    const healthData = await this.getHealthData();
    const records = await this.getDailyHealthRecords();
    return HealthCalculator.calculateHealthScore(healthData, records);
  }

  /**
   * 获取健康分析
   */
  public async getHealthAnalysis(): Promise<HealthAnalysis> {
    const healthData = await this.getHealthData();
    const records = await this.getDailyHealthRecords();
    return HealthCalculator.calculateHealthAnalysis(healthData, records);
  }

  /**
   * 保存AI对话历史
   * @param messages AI对话消息数组
   */
  public async saveAIChatHistory(messages: Message[]): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('aiChatHistory', JSON.stringify(messages));
      await this.pref.flush();
      console.log('AI对话历史保存成功');
    } catch (error) {
      console.error(`AI对话历史保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取AI对话历史
   * @returns AI对话消息数组
   */
  public async getAIChatHistory(): Promise<Message[]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const messagesStr = await this.pref.get('aiChatHistory', '[]');
      return JSON.parse(messagesStr as string) as Message[];
    } catch (error) {
      console.error(`AI对话历史获取失败: ${error}`);
      return [];
    }
  }

  /**
   * 保存AI对话历史列表（多条历史对话）
   * @param historyList 历史对话列表
   */
  public async saveAIChatHistoryList(historyList: Message[][]): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.put('aiChatHistoryList', JSON.stringify(historyList));
      await this.pref.flush();
      console.log('AI对话历史列表保存成功');
    } catch (error) {
      console.error(`AI对话历史列表保存失败: ${error}`);
      throw new Error(error);
    }
  }

  /**
   * 获取AI对话历史列表（多条历史对话）
   * @returns AI对话历史列表
   */
  public async getAIChatHistoryList(): Promise<Message[][]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const historyListStr = await this.pref.get('aiChatHistoryList', '[]');
      return JSON.parse(historyListStr as string) as Message[][];
    } catch (error) {
      console.error(`AI对话历史列表获取失败: ${error}`);
      return [];
    }
  }

  /**
   * 清空所有数据
   */
  public async clearAllData(): Promise<void> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      await this.pref.clear();
      await this.pref.flush();
      console.log('所有数据已清空');
    } catch (error) {
      console.error(`清空数据失败: ${error}`);
      throw new Error(error);
    }
  }
}

export const storage = StorageManager.getInstance();