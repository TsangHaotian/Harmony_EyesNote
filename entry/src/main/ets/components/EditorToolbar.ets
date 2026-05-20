// EditorToolbar.ets - 可复用的编辑器工具栏组件
@Component
export struct EditorToolbar {
  @Prop showToolbar: boolean = true
  @Prop toolbarOpacity: number = 1
  @Prop toolbarOffset: number = 0
  @Prop showDate: boolean = true
  @Prop showTime: boolean = true
  @Prop showDateTimeFull: boolean = false
  @Prop showDivider: boolean = true
  @Prop showTodo: boolean = true
  @Prop showTitleButton: boolean = true
  @Prop showList: boolean = false
  @Prop showNumberedList: boolean = false
  @Prop showSelectAll: boolean = false
  @Prop showClear: boolean = true
  @Prop wordCount: number = 0
  @Prop lineCount: number = 0
  @Prop cardColor: string = '#FFFFFF'
  @Prop textColor: string = '#0F172A'
  @Prop accentColor: string = '#0FAF97'
  @Prop mutedTextColor: string = '#6B7280'

  onToggleToolbar: () => void = () => {}
  onInsertDate: () => void = () => {}
  onInsertTime: () => void = () => {}
  onInsertDateTime: () => void = () => {}
  onInsertDivider: () => void = () => {}
  onInsertTodo: () => void = () => {}
  onInsertTitle: () => void = () => {}
  onInsertListItem: () => void = () => {}
  onInsertNumberedList: () => void = () => {}
  onSelectAll: () => void = () => {}
  onClearContent: () => void = () => {}

  build() {
    Column() {
      // 工具栏标题栏（始终显示）
      Row() {
        Text('📝 编辑工具')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.textColor)
        Blank()
        Text(this.showToolbar ? '收起 ▲' : '展开 ▼')
          .fontSize(12)
          .fontColor(this.accentColor)
          .onClick(() => {
            this.onToggleToolbar();
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 8 })

      // 工具栏按钮（可收起）
      if (this.showToolbar || this.toolbarOpacity > 0) {
        Scroll() {
          Row({ space: 12 }) {
            if (this.showDate) {
              this.renderButton('📅 日期', () => { this.onInsertDate(); })
            }
            if (this.showTime) {
              this.renderButton('🕐 时间', () => { this.onInsertTime(); })
            }
            if (this.showDateTimeFull) {
              this.renderButton('📆 日期时间', () => { this.onInsertDateTime(); })
            }
            if (this.showDivider) {
              this.renderButton('➖ 分隔线', () => { this.onInsertDivider(); })
            }
            if (this.showTodo) {
              this.renderButton('☐ 待办', () => { this.onInsertTodo(); })
            }
            if (this.showTitleButton) {
              this.renderButton('📌 标题', () => { this.onInsertTitle(); })
            }
            if (this.showList) {
              this.renderButton('• 列表', () => { this.onInsertListItem(); })
            }
            if (this.showNumberedList) {
              this.renderButton('1. 数字', () => { this.onInsertNumberedList(); })
            }
            if (this.showSelectAll) {
              this.renderButton('✓ 全选', () => { this.onSelectAll(); })
            }
            if (this.showClear) {
              this.renderButton('🗑️ 清空', () => { this.onClearContent(); })
            }
          }
          .padding({ left: 20, right: 20, bottom: 12 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .height(50)
        .opacity(this.toolbarOpacity)
        .translate({ y: this.toolbarOffset })
      }

      // 字数统计（始终显示）
      Row() {
        Text(`字数：${this.wordCount}`)
          .fontSize(12)
          .fontColor(this.mutedTextColor)
        Blank()
        Text(`行数：${this.lineCount}`)
          .fontSize(12)
          .fontColor(this.mutedTextColor)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 4, bottom: 12 })
    }
    .width('100%')
    .backgroundColor(this.cardColor)
    .border({ width: { bottom: 0.5 }, color: '#E5E5EA' })
  }

  @Builder
  renderButton(label: string, onClick: () => void) {
    Button(label)
      .fontSize(13)
      .fontColor(this.textColor)
      .backgroundColor(this.cardColor)
      .borderRadius(16)
      .height(36)
      .padding({ left: 12, right: 12 })
      .onClick(onClick)
  }
}
