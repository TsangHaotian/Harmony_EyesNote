//Settings.ets - 设置页面（液态玻璃）
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset } from '../utils/Types';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';

@Entry
@Component
struct Settings {
  @State apiKey: string = '';
  @State showApiKey: boolean = false;

  private theme: ThemePreset = getTheme();

  getThemeColor(key: ThemeColorKey): string { return getThemeColorValue(this.theme, key); }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    this.apiKey = await storage.getApiKey();
  }

  async exportData() {
    try {
      const data = await storage.exportAllData();
      promptAction.showDialog({
        title: '数据导出', message: `数据已导出，共${data.length}字符`,
        buttons: [{ text: '确定', color: '#007AFF' }]
      });
      console.log('=== 导出数据 ===');
      console.log(data);
    } catch (error) { promptAction.showToast({ message: '导出失败', duration: 2000 }); }
  }

  async clearAllData() {
    promptAction.showDialog({
      title: '危险操作', message: '确定要清空所有数据吗？此操作不可恢复！',
      buttons: [{ text: '取消', color: '#666666' }, { text: '清空', color: '#FF3B30' }]
    }).then((result) => {
      if (result.index === 1) {
        storage.clearAllData().then(() => { promptAction.showToast({ message: '数据已清空', duration: 2000 }); })
          .catch(() => { promptAction.showToast({ message: '清空失败', duration: 2000 }); });
      }
    }).catch((err: Error) => { console.error(`clear error: ${err}`); });
  }

  @Builder
  GlassRow(content: string, onClick?: () => void) {
    Row() {
      Text(content).fontSize(16).fontColor(this.getThemeColor('textColor'))
      Blank()
      Image($r('app.media.ic_right')).width(20).height(20).fillColor(this.getThemeColor('mutedTextColor'))
    }
    .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(14)
    .backgroundColor('rgba(255, 255, 255, 0.06)')
    .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
    .onClick(() => { if (onClick) onClick(); })
  }

  build() {
    Column() {
      Row().width('100%').height(50).backgroundColor('transparent')

      Row() {
        Image($r('app.media.ic_backup')).width(28).height(28).padding(4).margin({ right: 12 })
          .fillColor(this.getThemeColor('textColor'))
          .onClick(() => { router.back(); })
        Text('关于我们').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })

      Divider().strokeWidth(0.3).color('rgba(255, 255, 255, 0.1)')

      Scroll() {
        Column({ space: 16 }) {
          Text('数据管理').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%')

          this.GlassRow('📊 数据统计', () => { router.pushUrl({ url: 'pages/Statistics' }); })

          Row() {
            Text('🗑️ 清空所有数据').fontSize(16).fontColor('#FF6B6B')
            Blank()
            Image($r('app.media.ic_right')).width(20).height(20).fillColor('#FF6B6B')
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(14)
          .backgroundColor('rgba(255, 255, 255, 0.06)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 2 })
          .onClick(() => { this.clearAllData(); })

          Divider().strokeWidth(0.3).color('rgba(255, 255, 255, 0.1)').margin({ top: 8 })

          Text('AI 配置').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%')

          Column({ space: 8 }) {
            Row() {
              Text('🔑 DeepSeek API Key').fontSize(14).fontColor(this.getThemeColor('textColor'))
              Blank()
              Image($r('app.media.ic_about')).width(18).height(18)
                .fillColor(this.getThemeColor('mutedTextColor'))
                .onClick(() => {
                  promptAction.showDialog({
                    title: '获取 API Key',
                    message: '前往 https://platform.deepseek.com 注册并创建 API Key',
                    buttons: [{ text: '知道了', color: '#007AFF' }]
                  });
                })
            }.width('100%')

            Row({ space: 8 }) {
              TextInput({ placeholder: 'sk-...', text: this.apiKey })
                .layoutWeight(1).height(44).fontSize(14)
                .type(this.showApiKey ? InputType.Normal : InputType.Password)
                .backgroundColor('rgba(255, 255, 255, 0.06)').borderRadius(8).padding({ left: 12, right: 12 })
                .fontColor(this.getThemeColor('textColor')).placeholderColor('rgba(255,255,255,0.4)')
                .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })
                .onChange((value: string) => { this.apiKey = value; })

              Button(this.showApiKey ? '隐藏' : '显示')
                .fontSize(12).fontColor('#FFFFFF')
                .backgroundColor('rgba(255, 255, 255, 0.15)').borderRadius(8).height(44).width(56)
                .onClick(() => { this.showApiKey = !this.showApiKey; })
            }.width('100%')

            Button('保存')
              .fontSize(14).fontColor('#FFFFFF')
              .backgroundColor('rgba(255, 255, 255, 0.15)').borderRadius(8).height(40).width('100%')
              .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.15)' })
              .onClick(async () => {
                await storage.saveApiKey(this.apiKey);
                promptAction.showToast({ message: 'API Key 已保存', duration: 2000 });
              })
          }
          .width('100%').padding(16)
          .backgroundColor('rgba(255, 255, 255, 0.04)').borderRadius(14)
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.08)' })

          Divider().strokeWidth(0.3).color('rgba(255, 255, 255, 0.1)').margin({ top: 8 })

          Text('关于应用').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%')

          Row() {
            Text('版本号').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('V1.0.0').fontSize(16).fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(14)
          .backgroundColor('rgba(255, 255, 255, 0.06)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })

          Row() {
            Text('开发者').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('曾昊天').fontSize(16).fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(14)
          .backgroundColor('rgba(255, 255, 255, 0.06)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })

          Column({ space: 8 }) {
            Text('联系邮箱').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
            Text('TsangHaotian@hotmail.com').fontSize(14).fontColor(this.getThemeColor('accentColor'))
          }
          .width('100%').padding(20).borderRadius(14)
          .backgroundColor('rgba(255, 255, 255, 0.06)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })

          Column({ space: 8 }) {
            Text('项目开源地址').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
            Text('https://github.com/TsangHaotian/Harmony_EyesNote').fontSize(14).fontColor(this.getThemeColor('accentColor'))
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').padding(20).borderRadius(14)
          .backgroundColor('rgba(255, 255, 255, 0.06)')
          .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.1)' })
        }
        .width('100%').padding({ top: 24, left: 20, right: 20, bottom: 24 })
      }
      .layoutWeight(1).width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#1a1a2e', 0], ['#16213e', 0.5], ['#0f3460', 1]]
    })
  }
}
