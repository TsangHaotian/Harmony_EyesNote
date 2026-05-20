// Card.ets - 通用卡片组件
@Component
export struct Card {
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
