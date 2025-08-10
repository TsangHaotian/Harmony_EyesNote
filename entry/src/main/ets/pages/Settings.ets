import router from '@ohos.router';

@Entry
@Component
struct Settings {
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup'))
          .width(24)
          .height(24)
          .margin({ right: 16 })
          .onClick(() => {
            router.back();
          })
        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')
      .height(66)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r("app.color.backgroundColor"))

      Scroll() {
        Column({ space: 10 }) {

          Row() {
            Text('版本号')
              .fontSize(16)
            Blank()
            Text('V1.0.0')
              .fontSize(16)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor($r("app.color.backgroundColor"))
          .margin({ bottom: 8 })

          Row() {
            Text('开发者')
              .fontSize(16)
            Blank()
            Text('TsangHaotian')
              .fontSize(16)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor($r("app.color.backgroundColor"))

          Row() {
            Text('联系邮箱')
              .fontSize(16)
            Blank()
            Text('TsangHaotian@hotmail.com')
              .fontSize(16)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor($r("app.color.backgroundColor"))


          Row() {
            Text('项目开源地址')
              .fontSize(10)
            Blank()
            Text('https://github.com/TsangHaotian/Harmony_EyesNote')
              .fontSize(10)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor($r("app.color.backgroundColor"))

        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
  }
}