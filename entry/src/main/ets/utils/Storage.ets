import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';

class StorageManager {
  private static instance: StorageManager;
  private pref: preferences.Preferences | null = null;

  private constructor() {
  }

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
  public async saveCustomTemplates(templates: string[]): Promise<void> {
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
  public async getCustomTemplates(): Promise<string[]> {
    if (!this.pref) {
      throw new Error('首选项未初始化');
    }
    try {
      const templatesStr = await this.pref.get('customTemplates', '[]');
      return JSON.parse(templatesStr as string) as string[];
    } catch (error) {
      console.error(`自定义模板获取失败: ${error}`);
      return [];
    }
  }

}

export const storage = StorageManager.getInstance();