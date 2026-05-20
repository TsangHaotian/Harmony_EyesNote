//Settings.ets - 设置页面
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset } from '../utils/Types';
import { DEFAULT_THEME_ID, ThemeColorKey, cloneThemePresets, getThemeById, getThemeColorValue } from '../utils/ThemeHelper';

@Entry
@Component
struct Settings {
  @State themePresets: ThemePreset[] = cloneThemePresets();
  @State selectedThemeId: string = DEFAULT_THEME_ID;
  @State showThemeSelector: boolean = false;
  @State themeSelectorOpacity: number = 0;
  @State themeSelectorOffset: number = -8;
  @State themeArrowAngle: number = 0;

  getCurrentTheme(): ThemePreset { return getThemeById(this.selectedThemeId, this.themePresets); }
  getThemeColor(key: ThemeColorKey): string { return getThemeColorValue(this.getCurrentTheme(), key); }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    this.themePresets = cloneThemePresets();
    const savedThemeId = await storage.getThemePreference();
    if (savedThemeId) {
      const exists = this.themePresets.some((t: ThemePreset) => t.id === savedThemeId);
      this.selectedThemeId = exists ? savedThemeId : DEFAULT_THEME_ID;
    }
  }

  async selectTheme(themeId: string) {
    this.selectedThemeId = themeId;
    await storage.saveThemePreference(themeId);
    const themeName = this.themePresets.find((t: ThemePreset) => t.id === themeId)?.name || '';
    promptAction.showToast({ message: `已切换主题：${themeName}`, duration: 1500 });
    this.animateThemeSelectorVisibility(false);
  }

  toggleThemeSelector() { this.animateThemeSelectorVisibility(!this.showThemeSelector); }

  animateThemeSelectorVisibility(show: boolean) {
    if (show) {
      if (this.showThemeSelector) return;
      this.showThemeSelector = true;
      this.themeSelectorOpacity = 0; this.themeSelectorOffset = -8;
      animateTo({ duration: 220, curve: 'linear' }, () => { this.themeSelectorOpacity = 1; this.themeSelectorOffset = 0; this.themeArrowAngle = 90; });
    } else {
      if (!this.showThemeSelector) return;
      animateTo({ duration: 200, curve: 'linear' }, () => { this.themeSelectorOpacity = 0; this.themeSelectorOffset = -8; this.themeArrowAngle = 0; });
      setTimeout(() => { this.showThemeSelector = false; }, 210);
    }
  }

  async exportData() {
    try {
      const data = await storage.exportAllData();
      promptAction.showDialog({
        title: '数据导出',
        message: `数据已导出，共${data.length}字符\n\n数据已复制到控制台，可在开发者工具中查看`,
        buttons: [{ text: '确定', color: '#007AFF' }]
      });
      console.log('=== 导出数据开始 ===');
      console.log(data);
      console.log('=== 导出数据结束 ===');
    } catch (error) {
      promptAction.showToast({ message: '导出失败', duration: 2000 });
    }
  }

  async clearAllData() {
    promptAction.showDialog({
      title: '危险操作',
      message: '确定要清空所有数据吗？此操作不可恢复！',
      buttons: [{ text: '取消', color: '#666666' }, { text: '清空', color: '#FF3B30' }]
    }).then((result) => {
      if (result.index === 1) {
        storage.clearAllData().then(() => { promptAction.showToast({ message: '数据已清空', duration: 2000 }); })
          .catch(() => { promptAction.showToast({ message: '清空失败', duration: 2000 }); });
      }
    }).catch((err: Error) => { console.error(`清空数据对话框错误: ${err}`); });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup')).width(28).height(28).padding(4).margin({ right: 12 })
          .onClick(() => { router.back(); })
        Text('关于我们').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      Scroll() {
        Column({ space: 16 }) {
          Text('数据管理').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%').margin({ bottom: 8 })

          // 数据统计
          Row() {
            Text('📊 数据统计').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Image($r('app.media.ic_right')).width(20).height(20).fillColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
          .onClick(() => { router.pushUrl({ url: 'pages/Statistics' }); })

          // 导出数据
          Row() {
            Text('📤 导出数据').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Image($r('app.media.ic_right')).width(20).height(20).fillColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
          .onClick(() => { this.exportData(); })

          // 清空数据
          Row() {
            Text('🗑️ 清空所有数据').fontSize(16).fontColor('#FF3B30')
            Blank()
            Image($r('app.media.ic_right')).width(20).height(20).fillColor('#FF3B30')
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
          .onClick(() => { this.clearAllData(); })

          Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 16, bottom: 16 })

          Text('主题风格').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%').margin({ bottom: 8 })

          Row() {
            Column({ space: 4 }) {
              Text('当前主题').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
              Text(this.themePresets.find((t: ThemePreset) => t.id === this.selectedThemeId)?.name || '默认')
                .fontSize(16).fontColor(this.getThemeColor('textColor')).fontWeight(FontWeight.Medium)
            }
            Blank()
            Image($r('app.media.ic_backup2')).width(20).height(20).fillColor('#666666').rotate({ angle: this.themeArrowAngle })
          }
          .width('100%').height(72).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
          .onClick(() => { this.toggleThemeSelector(); })

          if (this.showThemeSelector || this.themeSelectorOpacity > 0) {
            Column({ space: 12 }) {
              ForEach(this.themePresets, (theme: ThemePreset) => {
                Row() {
                  Column({ space: 6 }) {
                    Text(theme.name).fontSize(16).fontColor(this.getThemeColor('textColor')).fontWeight(FontWeight.Medium)
                    Row({ space: 8 }) {
                      Text(`背景 ${theme.backgroundColor}`).fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                      Text(`强调 ${theme.accentColor}`).fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                    }
                  }
                  Blank()
                  if (this.selectedThemeId === theme.id) {
                    Text('✓').fontSize(18).fontColor(theme.accentColor)
                  } else {
                    Row().width(18).height(18).borderRadius(9)
                      .border({ width: 1, color: '#E5E7EB' })
                      .backgroundColor(this.getThemeColor('cardColor'))
                  }
                }
                .width('100%').height(72).padding({ left: 20, right: 20 }).borderRadius(12)
                .backgroundColor(this.getThemeColor('cardColor'))
                .border({ width: 1, color: this.selectedThemeId === theme.id ? theme.accentColor : '#F1F5F9' })
                .onClick(() => { this.selectTheme(theme.id); })
              }, (theme: ThemePreset) => theme.id)
            }
            .width('100%').padding({ top: 12, bottom: 4 })
            .opacity(this.themeSelectorOpacity).translate({ y: this.themeSelectorOffset })
          }

          Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 16, bottom: 16 })

          Text('关于应用').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor')).width('100%').margin({ bottom: 8 })

          // 版本号
          Row() {
            Text('版本号').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('V1.0.0').fontSize(16).fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })

          // 开发者
          Row() {
            Text('开发者').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('TsangHaotian').fontSize(16).fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })

          // 联系邮箱
          Row() {
            Text('联系邮箱').fontSize(16).fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('TsangHaotian@hotmail.com').fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).constraintSize({ maxWidth: '60%' })
          }
          .width('100%').height(56).padding({ left: 20, right: 20 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })

          // 项目开源地址
          Column({ space: 8 }) {
            Row() {
              Text('项目开源地址').fontSize(16).fontColor(this.getThemeColor('textColor'))
              Blank()
            }.width('100%')
            Text('https://github.com/TsangHaotian/Harmony_EyesNote')
              .fontSize(14).fontColor(this.getThemeColor('accentColor')).width('100%')
              .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 16 }).borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({ radius: 2, color: '#00000006', offsetX: 0, offsetY: 1 })
        }
        .width('100%').padding({ top: 24, left: 20, right: 20, bottom: 24 })
      }
      .layoutWeight(1).width('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    }
    .width('100%').height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
