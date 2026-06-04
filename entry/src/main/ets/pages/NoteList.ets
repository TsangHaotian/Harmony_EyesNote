// NoteList.ets - 当前笔记快捷入口（液态玻璃风格）
import router from '@ohos.router';

@Component
export struct NoteList {
  @Link currentNote: string
  getThemeColor: (key: string) => string = () => ''

  openNoteEditor() {
    router.pushUrl({ url: 'pages/NoteEditor', params: { currentNote: this.currentNote } });
  }

  getNoteWordCount(note: string): number {
    return note.replace(/\s/g, '').length;
  }

  build() {
    Column() {
      Row() {
        Text('当前笔记').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
        Blank()
        Text(`${this.getNoteWordCount(this.currentNote)} 字`).fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Stack() {
        TextInput({ placeholder: '点击进入编辑模式…', text: this.currentNote })
          .width('100%').height(200)
          .backgroundColor('rgba(255, 255, 255, 0.08)').borderRadius(16).padding(20)
          .fontSize(15).fontColor(this.getThemeColor('textColor')).placeholderColor('rgba(255, 255, 255, 0.4)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.12)' })
          .enabled(false)
        Row().width('100%').height(200).onClick(() => { this.openNoteEditor(); })
      }
      .width('100%').height(200)
      .padding({ left: 20, right: 20, bottom: 16 })
      .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 6 })
    }
    .width('100%')
  }
}
