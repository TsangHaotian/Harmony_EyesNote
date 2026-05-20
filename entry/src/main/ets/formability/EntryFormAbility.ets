// EntryFormAbility.ets - 桌面卡片数据处理
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import preferences from '@ohos.data.preferences';
import Want from '@ohos.app.ability.Want';

export default class EntryFormAbility extends FormExtensionAbility {
  private pref: preferences.Preferences | null = null;

  async getPref(): Promise<preferences.Preferences> {
    if (!this.pref) {
      this.pref = await preferences.getPreferences(this.context, 'noteApp');
    }
    return this.pref;
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const defaultStr = '{"note0":"","note1":"","note2":"","note3":"","updateTime":"--:--"}';
    return formBindingData.createFormBindingData(JSON.parse(defaultStr));
  }

  async onUpdateForm(formId: string): Promise<void> {
    try {
      const pref = await this.getPref();
      const notesStr = (await pref.get('historyNotes', '[]')) as string;
      const notes: string[] = JSON.parse(notesStr) as string[];

      const now = new Date();
      const updateTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;

      const esc = (s: string): string => {
        return s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\r/g, '\\r').replace(/\t/g, '\\t');
      };

      const note0 = notes.length > 0 ? esc(notes[0].substring(0, 100)) : '';
      const note1 = notes.length > 1 ? esc(notes[1].substring(0, 100)) : '';
      const note2 = notes.length > 2 ? esc(notes[2].substring(0, 100)) : '';
      const note3 = notes.length > 3 ? esc(notes[3].substring(0, 100)) : '';

      const formDataStr = `{"note0":"${note0}","note1":"${note1}","note2":"${note2}","note3":"${note3}","updateTime":"${updateTime}"}`;
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(JSON.parse(formDataStr)));
    } catch (error) {
      console.error(`更新卡片失败: ${JSON.stringify(error)}`);
    }
  }

  onFormEvent(formId: string, message: string): void {
    console.info(`卡片事件: ${message}`);
  }
}
