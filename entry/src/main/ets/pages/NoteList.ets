// NoteList.ets - 历史笔记列表组件（搜索 + 列表）
import router from '@ohos.router';
import { storage } from '../utils/Storage';
import { ThemePreset } from '../utils/Types';
import promptAction from '@ohos.promptAction';

@Component
export struct NoteList {
  @Prop themePresets: ThemePreset[] = []
  @Prop selectedThemeId: string = ''
  @Link currentNote: string
  @Link @Watch('onHistoryNotesChange') historyNotes: string[]
  getThemeColor: (key: string) => string = () => ''

  @State filteredNotes: string[] = []
  @State searchKeyword: string = ''
  @State showSearch: boolean = false
  @State searchBarOpacity: number = 0
  @State searchBarOffset: number = 8

  aboutToAppear() {
    this.filteredNotes = this.historyNotes;
  }

  filterNotes() {
    if (this.searchKeyword.trim() === '') {
      this.filteredNotes = this.historyNotes;
    } else {
      this.filteredNotes = this.historyNotes.filter(note =>
        note.toLowerCase().includes(this.searchKeyword.toLowerCase())
      );
    }
  }

  onHistoryNotesChange() {
    this.filterNotes();
  }

  openNoteEditor() {
    router.pushUrl({ url: 'pages/NoteEditor', params: { currentNote: this.currentNote } });
  }

  openNoteDetail(note: string, index: number) {
    router.pushUrl({ url: 'pages/NoteDetail', params: { noteContent: note, noteIndex: index } });
  }

  getNoteWordCount(note: string): number {
    return note.replace(/\s/g, '').length;
  }

  build() {
    Column() {
      // 当前笔记快捷入口
      Row() {
        Text('当前笔记').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
        Blank()
        Text(`${this.getNoteWordCount(this.currentNote)} 字`).fontSize(12).fontColor('#999999')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Stack() {
        TextInput({ placeholder: '点击进入编辑模式…', text: this.currentNote })
          .width('100%').height(120)
          .backgroundColor(this.getThemeColor('cardColor')).borderRadius(12).padding(16)
          .fontSize(15).fontColor(this.getThemeColor('textColor')).placeholderColor('#999999')
          .enabled(false)
        Row().width('100%').height(120).onClick(() => { this.openNoteEditor(); })
      }
      .width('100%').height(120)
      .padding({ left: 20, right: 20, bottom: 16 })

      Divider().strokeWidth(0.5).color('#E5E5EA').margin({ left: 20, right: 20 })

      // 历史笔记
      Column() {
        Row() {
          Text('历史笔记').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
          Blank()
          Text(this.showSearch ? '取消' : '🔍').fontSize(18).fontColor(this.getThemeColor('textColor'))
            .onClick(() => {
              if (!this.showSearch) {
                this.showSearch = true; this.searchBarOpacity = 0; this.searchBarOffset = 8;
                animateTo({ duration: 280, curve: 'easeInOut' }, () => { this.searchBarOpacity = 1; this.searchBarOffset = 0; });
              } else {
                this.showSearch = false;
                animateTo({ duration: 300, curve: 'easeInOut' }, () => { this.searchBarOpacity = 0; this.searchBarOffset = 8; });
                setTimeout(() => { this.searchKeyword = ''; this.filterNotes(); }, 220);
              }
            })
        }
        .width('100%').padding({ left: 20, right: 20, bottom: 12 })

        if (this.showSearch || this.searchBarOpacity > 0) {
          Row({ space: 8 }) {
            TextInput({ placeholder: '搜索笔记...', text: this.searchKeyword })
              .layoutWeight(1).height(40)
              .backgroundColor(this.getThemeColor('cardColor')).borderRadius(20).padding({ left: 16, right: 16 }).fontSize(14)
              .onChange((value: string) => { this.searchKeyword = value; this.filterNotes(); })
            if (this.searchKeyword.length > 0) {
              Image($r('app.media.ic_close')).width(20).height(20)
                .onClick(() => { this.searchKeyword = ''; this.filterNotes(); })
            }
          }
          .width('100%').padding({ left: 20, right: 20, bottom: 12 })
          .opacity(this.searchBarOpacity).translate({ y: this.searchBarOffset })
        }

        Column({ space: 12 }) {
          if (this.filteredNotes.length === 0) {
            Column() {
              Text('暂无笔记').fontSize(16).fontColor('#999999').margin({ top: 40, bottom: 40 })
            }.width('100%').alignItems(HorizontalAlign.Center)
          } else {
            ForEach(this.filteredNotes, (note: string, index: number) => {
              Row({ space: 12 }) {
                Column({ space: 6 }) {
                  Text(note).fontSize(15).maxLines(2).fontColor(this.getThemeColor('textColor'))
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(22).width('100%')
                  Text(`${this.getNoteWordCount(note)} 字`).fontSize(12).fontColor('#999999')
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)

                Row({ space: 4 }) {
                  Image($r('app.media.ic_about')).width(30).height(30)
                    .fillColor(this.getThemeColor('accentColor')).padding(6)
                    .onClick(() => { promptAction.showToast({ message: '分享功能：可以复制笔记内容后分享', duration: 3000 }); })
                  Image($r('app.media.ic_delete')).width(30).height(30).padding(6)
                    .onClick(() => { this.deleteNote(index); })
                }.alignItems(VerticalAlign.Center)
              }
              .width('100%').padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor(this.getThemeColor('cardColor')).borderRadius(12)
              .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
              .onClick(() => {
                const originalIndex = this.historyNotes.indexOf(note);
                this.openNoteDetail(note, originalIndex);
              })
            }, (note: string, index: number) => `${note}_${index}`)
          }
        }
        .width('100%').padding({ left: 20, right: 20, bottom: 20 })
      }
      .padding({ top: 8 }).width('100%')
    }
    .width('100%')
  }

  async deleteNote(index: number) {
    promptAction.showDialog({
      title: '确认删除', message: '确定要删除这条笔记吗？',
      buttons: [{ text: '取消', color: '#666666' }, { text: '删除', color: '#FF3B30' }]
    }).then((result) => {
      if (result.index === 1) {
        const originalIndex = this.historyNotes.indexOf(this.filteredNotes[index]);
        this.historyNotes.splice(originalIndex, 1);
        this.filterNotes();
        storage.saveHistoryNotes(this.historyNotes);
        promptAction.showToast({ message: '笔记已删除', duration: 2000 });
      }
    }).catch((err: Error) => { console.error(`删除确认对话框错误: ${err}`); });
  }
}
