// CalendarView.ets - 日历视图，使用 GridRow/GridCol 网格布局
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import { NoteItem } from '../utils/Types';
import promptAction from '@ohos.promptAction';

class DayCell {
  day: number = 0;
  isToday: boolean = false;
  isSel: boolean = false;
  hasNote: boolean = false;
  constructor(day: number, isToday: boolean, isSel: boolean, hasNote: boolean) {
    this.day = day;
    this.isToday = isToday;
    this.isSel = isSel;
    this.hasNote = hasNote;
  }
}

@Component
export struct CalendarView {
  @Prop @Watch('onRefresh') refreshFlag: number = 0
  getThemeColor: (key: string) => string = () => ''

  @State year: number = 0
  @State month: number = 0
  @State selDay: number = 0
  @State days: DayCell[] = []
  @State dayNotes: NoteItem[] = []
  @State noteList: NoteItem[] = []
  @State gridOpacity: number = 1.0
  @State gridTranslateX: number = 0

  onRefresh() {
    this.loadData();
  }

  async aboutToAppear() {
    const d = new Date();
    this.year = d.getFullYear();
    this.month = d.getMonth() + 1;
    this.selDay = d.getDate();
    // 确保 storage 已初始化
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      await storage.init(ctx);
    } catch (e) {
      console.error(`Calendar storage init error: ${e}`);
    }
    await this.loadData();
  }

  async loadData() {
    try {
      const notes = await storage.getHistoryNotes();
      if (notes) {
        this.noteList = notes;
        this.buildDays();
      }
    } catch (e) {
      console.error(`Calendar load error: ${e}`);
    }
  }

  pad(n: number): string {
    return n < 10 ? '0' + n : '' + n;
  }

  getNoteDates(): string[] {
    const arr: string[] = [];
    for (let i = 0; i < this.noteList.length; i++) {
      const nd = this.noteList[i].createdAt.substring(0, 10);
      let found = false;
      for (let j = 0; j < arr.length; j++) {
        if (arr[j] === nd) { found = true; break; }
      }
      if (!found) arr.push(nd);
    }
    return arr;
  }

  buildDays() {
    const y = this.year;
    const m = this.month;
    const firstDay = new Date(y, m - 1, 1).getDay();
    const daysInMonth = new Date(y, m, 0).getDate();
    const today = new Date();
    const todayStr = `${today.getFullYear()}-${this.pad(today.getMonth() + 1)}-${this.pad(today.getDate())}`;
    const noteDates = this.getNoteDates();

    const cells: DayCell[] = [];

    // 月初空白
    for (let i = 0; i < firstDay; i++) {
      cells.push(new DayCell(0, false, false, false));
    }

    // 当月日期
    for (let d = 1; d <= daysInMonth; d++) {
      const ds = `${y}-${this.pad(m)}-${this.pad(d)}`;
      const isToday = ds === todayStr;
      const isSel = d === this.selDay;
      let hasNote = false;
      for (let j = 0; j < noteDates.length; j++) {
        if (noteDates[j] === ds) { hasNote = true; break; }
      }
      cells.push(new DayCell(d, isToday, isSel, hasNote));
    }

    this.days = cells;

    // 加载选中日期的笔记
    const selStr = `${y}-${this.pad(m)}-${this.pad(this.selDay)}`;
    const matched: NoteItem[] = [];
    for (let i = 0; i < this.noteList.length; i++) {
      if (this.noteList[i].createdAt.substring(0, 10) === selStr) {
        matched.push(this.noteList[i]);
      }
    }
    const sorted: NoteItem[] = [];
    for (let i = matched.length - 1; i >= 0; i--) {
      sorted.push(matched[i]);
    }
    this.dayNotes = sorted;
  }

  prevMonth() {
    // 向左滑出
    animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.gridOpacity = 0;
      this.gridTranslateX = -30;
    });
    setTimeout(() => {
      if (this.month === 1) { this.year--; this.month = 12; }
      else { this.month--; }
      const max = new Date(this.year, this.month, 0).getDate();
      if (this.selDay > max) this.selDay = max;
      this.buildDays();
      // 从右侧滑入
      this.gridTranslateX = 30;
      animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
        this.gridOpacity = 1;
        this.gridTranslateX = 0;
      });
    }, 160);
  }

  nextMonth() {
    // 向右滑出
    animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.gridOpacity = 0;
      this.gridTranslateX = 30;
    });
    setTimeout(() => {
      if (this.month === 12) { this.year++; this.month = 1; }
      else { this.month++; }
      const max = new Date(this.year, this.month, 0).getDate();
      if (this.selDay > max) this.selDay = max;
      this.buildDays();
      // 从左侧滑入
      this.gridTranslateX = -30;
      animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
        this.gridOpacity = 1;
        this.gridTranslateX = 0;
      });
    }, 160);
  }

  pickDay(d: number) {
    if (d <= 0) return;
    this.selDay = d;
    this.buildDays();
  }

  goToday() {
    animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.gridOpacity = 0;
      this.gridTranslateX = -30;
    });
    setTimeout(() => {
      const d = new Date();
      this.year = d.getFullYear();
      this.month = d.getMonth() + 1;
      this.selDay = d.getDate();
      this.buildDays();
      this.gridTranslateX = 30;
      animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
        this.gridOpacity = 1;
        this.gridTranslateX = 0;
      });
    }, 160);
  }

  openDetail(note: NoteItem) {
    router.pushUrl({ url: 'pages/NoteDetail', params: { noteContent: note.content, noteIndex: -1 } });
  }

  getTime(s: string): string {
    const p = s.split(' ');
    return p.length > 1 ? p[1].substring(0, 5) : '';
  }

  wordCount(s: string): number {
    return s.replace(/\s/g, '').length;
  }

  async deleteNote(item: NoteItem) {
    promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这条笔记吗？',
      buttons: [{ text: '取消', color: '#666666' }, { text: '删除', color: '#FF3B30' }]
    }).then(async (r) => {
      if (r.index === 1) {
        const f: NoteItem[] = [];
        for (let i = 0; i < this.noteList.length; i++) {
          const n = this.noteList[i];
          if (n.content !== item.content || n.createdAt !== item.createdAt) {
            f.push(n);
          }
        }
        await storage.saveHistoryNotes(f);
        await this.loadData();
      }
    }).catch(() => {});
  }

  build() {
    Column() {
      // 安全距离
      Row().width('100%').height(50).backgroundColor(this.getThemeColor('backgroundColor'))

      // 月份导航
      Row() {
        Text('‹').fontSize(26).fontColor(this.getThemeColor('textColor'))
          .fontWeight(FontWeight.Bold).width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { this.prevMonth(); })
        Text(`${this.year}年${this.month}月`).fontSize(20).fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor')).layoutWeight(1).textAlign(TextAlign.Center)
          .onClick(() => {
            DatePickerDialog.show({
              start: new Date(2000, 0, 1),
              end: new Date(2099, 11, 31),
              selected: new Date(this.year, this.month - 1, this.selDay),
              onAccept: (val: DatePickerResult) => {
                if (val.year) this.year = val.year;
                if (val.month !== undefined) this.month = val.month + 1;
                if (val.day) this.selDay = val.day;
                const max = new Date(this.year, this.month, 0).getDate();
                if (this.selDay > max) this.selDay = max;
                this.buildDays();
              }
            });
          })
        Text('›').fontSize(26).fontColor(this.getThemeColor('textColor'))
          .fontWeight(FontWeight.Bold).width(40).height(40).textAlign(TextAlign.Center)
          .onClick(() => { this.nextMonth(); })
        Text('今天').fontSize(13).fontColor(this.getThemeColor('accentColor')).fontWeight(FontWeight.Medium)
          .width(52).height(30).textAlign(TextAlign.Center).borderRadius(15)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000010', offsetX: 0, offsetY: 1 })
          .onClick(() => { this.goToday(); })
      }
      .width('100%').height(44).padding({ left: 8, right: 8 })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      // 星期行
      Row() {
        ForEach(['日', '一', '二', '三', '四', '五', '六'], (w: string) => {
          Text(w).fontSize(13).fontColor(this.getThemeColor('mutedTextColor'))
            .layoutWeight(1).textAlign(TextAlign.Center)
        }, (w: string) => w)
      }
      .width('100%').height(24).padding({ left: 4, right: 4 })

      // 日期网格 — 使用 GridRow/GridCol
      GridRow({ columns: 7, gutter: { y: 4 } }) {
        ForEach(this.days, (cell: DayCell) => {
          GridCol() {
            if (cell.day > 0) {
              Column() {
                Text(`${cell.day}`).fontSize(17)
                  .fontColor(cell.isSel ? '#FFFFFF' : cell.isToday ? this.getThemeColor('accentColor') : this.getThemeColor('textColor'))
                  .fontWeight(cell.isToday || cell.isSel ? FontWeight.Bold : FontWeight.Normal)
                if (cell.hasNote) {
                  Row().width(4).height(4).borderRadius(2)
                    .backgroundColor(cell.isSel ? '#FFFFFF' : this.getThemeColor('accentColor'))
                    .margin({ top: 2 })
                }
              }
              .width('100%').aspectRatio(1)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(cell.isSel ? this.getThemeColor('accentColor') : 'transparent')
              .borderRadius(10)
              .onClick(() => { this.pickDay(cell.day); })
            }
          }
        }, (cell: DayCell) => `d${cell.day}_${cell.isSel}`)
      }
      .width('100%').padding({ left: 8, right: 8 })
      .opacity(this.gridOpacity)
      .translate({ x: this.gridTranslateX })

      Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 8, bottom: 8 })

      // 选中日期标题
      Row() {
        Text(`${this.month}月${this.selDay}日`).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor'))
        Text(` ${this.dayNotes.length}条`).fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
          .margin({ left: 8 })
        Blank()
      }
      .width('100%').padding({ left: 20, right: 20, bottom: 8 })

      // 笔记卡片列表
      Scroll() {
        Column() {
          if (this.dayNotes.length === 0) {
            Text('暂无笔记').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
              .margin({ top: 24, bottom: 24 }).width('100%').textAlign(TextAlign.Center)
          } else {
            Column({ space: 8 }) {
              ForEach(this.dayNotes, (item: NoteItem) => {
                Row() {
                  Column({ space: 4 }) {
                    Text(item.content).fontSize(15).maxLines(3)
                      .fontColor(this.getThemeColor('textColor'))
                      .textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(22).width('100%')
                    Row() {
                      Text(this.getTime(item.createdAt)).fontSize(12).fontColor('#999999')
                      Text(` ${this.wordCount(item.content)} 字`).fontSize(12).fontColor('#999999')
                        .margin({ left: 12 })
                    }
                  }
                  .layoutWeight(1).alignItems(HorizontalAlign.Start)

                  Image($r('app.media.ic_delete')).width(28).height(28).padding(4)
                    .onClick(() => { this.deleteNote(item); })
                }
                .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .backgroundColor(this.getThemeColor('cardColor')).borderRadius(12)
                .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
                .onClick(() => { this.openDetail(item); })
              }, (item: NoteItem) => `${item.content}_${item.createdAt}`)
            }
            .width('100%').padding({ left: 20, right: 20, bottom: 16 })
          }
        }
        .width('100%')
      }
      .layoutWeight(1).width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%').height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
