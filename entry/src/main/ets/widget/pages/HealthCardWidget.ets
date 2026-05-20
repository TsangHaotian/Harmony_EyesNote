// HealthCardWidget.ets - 桌面卡片 UI（显示最近4条笔记）
@Entry
@Component
struct HealthCardWidget {
  @LocalStorageProp('note0') note0: string = '';
  @LocalStorageProp('note1') note1: string = '';
  @LocalStorageProp('note2') note2: string = '';
  @LocalStorageProp('note3') note3: string = '';
  @LocalStorageProp('updateTime') updateTime: string = '--:--';

  build() {
    Column() {
      Row() {
        Text('📝 最近笔记').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#0F172A')
        Blank()
        Text(`⏱ ${this.updateTime}`).fontSize(9).fontColor('#94A3B8')
      }
      .width('100%').padding({ bottom: 6 })

      Column({ space: 4 }) {
        if (this.note0) {
          this.NoteItem(this.note0)
        }
        if (this.note1) {
          this.NoteItem(this.note1)
        }
        if (this.note2) {
          this.NoteItem(this.note2)
        }
        if (this.note3) {
          this.NoteItem(this.note3)
        }
        if (!this.note0 && !this.note1 && !this.note2 && !this.note3) {
          Text('暂无笔记，快去记录吧').fontSize(12).fontColor('#94A3B8').margin({ top: 8 })
        }
      }
      .layoutWeight(1).width('100%')
    }
    .width('100%').height('100%')
    .padding(12).backgroundColor('#FFFFFF').borderRadius(12)
    .onClick(() => {
      postCardAction(this, { action: 'router', abilityName: 'EntryAbility', params: {} });
    })
  }

  @Builder
  NoteItem(text: string) {
    Row() {
      Text(text).fontSize(11).fontColor('#334155')
        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(16)
    }
    .width('100%').padding({ top: 4, bottom: 4, left: 6, right: 6 })
    .backgroundColor('#F8FAFC').borderRadius(6)
  }
}
