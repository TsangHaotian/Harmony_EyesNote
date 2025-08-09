import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { storage } from '../utils/Storage';

@Entry
@Component
struct Settings {
  @State customTemplates: string[] = [];
  @State newTemplate: string = '';
  @State showAddTemplateDialog: boolean = false;
  @State darkModeEnabled: boolean = false;
  @State autoSaveEnabled: boolean = true;
  @State fontSizeOption: string = '中';
  @State fontSizeOptions: string[] = ['小', '中', '大'];

  aboutToAppear() {
    // 加载自定义模板
    this.loadCustomTemplates();
    // 这里可以加载其他设置项，如主题设置、字体大小等
  }

  async loadCustomTemplates() {
    try {
      this.customTemplates = await storage.getCustomTemplates();
    } catch (error) {
      console.error(`加载自定义模板失败: ${error}`);
      promptAction.showToast({
        message: '加载自定义模板失败',
        duration: 2000
      });
    }
  }

  async saveCustomTemplates() {
    try {
      await storage.saveCustomTemplates(this.customTemplates);
      promptAction.showToast({
        message: '保存成功',
        duration: 2000
      });
    } catch (error) {
      console.error(`保存自定义模板失败: ${error}`);
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      });
    }
  }

  async addTemplate() {
    if (this.newTemplate.trim() === '') {
      promptAction.showToast({
        message: '模板内容不能为空',
        duration: 2000
      });
      return;
    }

    this.customTemplates.push(this.newTemplate.trim());
    await this.saveCustomTemplates();
    this.newTemplate = '';
    this.showAddTemplateDialog = false;
  }

  async deleteTemplate(index: number) {
    this.customTemplates.splice(index, 1);
    await this.saveCustomTemplates();
  }

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
        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')
      .height(66)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#f5f5f5')

      Scroll() {
        Column({ space: 10 }) {

          Row() {
            Text('版本')
              .fontSize(16)
            Blank()
            Text('1.0.0')
              .fontSize(16)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
          .margin({ bottom: 8 })

          Row() {
            Text('开发者')
              .fontSize(16)
            Blank()
            Text('眨眼笔记团队')
              .fontSize(16)
              .opacity(0.6)
          }
          .width('100%')
          .padding(16)
          .borderRadius(8)
          .backgroundColor('#FFFFFF')
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
  }
}