import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';
import { ThemePreset } from '../utils/Types';
import { CUSTOM_THEME_ID, DEFAULT_THEME_ID, ThemeColorKey, cloneThemePreset, cloneThemePresets, createDefaultCustomTheme, getThemeById, getThemeColorValue } from '../utils/Theme';

interface ThemeColorField {
  key: ThemeColorKey;
  label: string;
  description: string;
}

const THEME_COLOR_FIELDS: ThemeColorField[] = [
  { key: 'backgroundColor', label: '背景颜色', description: '页面整体背景' },
  { key: 'cardColor', label: '卡片颜色', description: '卡片和容器背景' },
  { key: 'textColor', label: '主文本颜色', description: '标题和正文文字' },
  { key: 'accentColor', label: '强调颜色', description: '按钮和高亮元素' },
  { key: 'mutedTextColor', label: '次级文本颜色', description: '说明文字与标签' }
];

@Entry
@Component
struct Settings {
  @State themePresets: ThemePreset[] = cloneThemePresets();
  @State selectedThemeId: string = DEFAULT_THEME_ID;
  @State showThemeSelector: boolean = false;
  @State customTheme: ThemePreset = createDefaultCustomTheme();
  @State customThemeDraft: ThemePreset = createDefaultCustomTheme();
  @State showCustomThemeEditor: boolean = false;
  @State isSavingCustomTheme: boolean = false;

  getCurrentTheme(): ThemePreset {
    return getThemeById(this.selectedThemeId, this.themePresets);
  }

  getThemeColor(key: ThemeColorKey): string {
    return getThemeColorValue(this.getCurrentTheme(), key);
  }

  refreshThemeList(customTheme?: ThemePreset) {
    const presets = cloneThemePresets();
    if (customTheme) {
      presets.push(cloneThemePreset(customTheme));
    }
    this.themePresets = presets;
  }

  getColorFromPreset(theme: ThemePreset, key: ThemeColorKey): string {
    switch (key) {
      case 'cardColor':
        return theme.cardColor;
      case 'textColor':
        return theme.textColor;
      case 'accentColor':
        return theme.accentColor;
      case 'mutedTextColor':
        return theme.mutedTextColor;
      case 'backgroundColor':
      default:
        return theme.backgroundColor;
    }
  }

  updateCustomThemeDraftColor(key: ThemeColorKey, value: string) {
    const trimmed = value.trim();
    const updated: ThemePreset = {
      id: this.customThemeDraft.id,
      name: this.customThemeDraft.name,
      backgroundColor: key === 'backgroundColor' ? trimmed : this.customThemeDraft.backgroundColor,
      cardColor: key === 'cardColor' ? trimmed : this.customThemeDraft.cardColor,
      textColor: key === 'textColor' ? trimmed : this.customThemeDraft.textColor,
      accentColor: key === 'accentColor' ? trimmed : this.customThemeDraft.accentColor,
      mutedTextColor: key === 'mutedTextColor' ? trimmed : this.customThemeDraft.mutedTextColor
    };
    this.customThemeDraft = updated;
  }

  isValidHexColor(value: string): boolean {
    const regex = /^#?[0-9A-Fa-f]{6}$|^#?[0-9A-Fa-f]{3}$/;
    if (value.length === 0) {
      return false;
    }
    return regex.test(value.trim());
  }

  normalizeHexColor(value: string): string {
    let color = value.trim();
    if (!color.startsWith('#')) {
      color = `#${color}`;
    }
    return color.toUpperCase();
  }

  toggleCustomThemeEditor() {
    if (!this.showCustomThemeEditor) {
      this.customThemeDraft = cloneThemePreset(this.customTheme);
    }
    this.showCustomThemeEditor = !this.showCustomThemeEditor;
  }

  async saveCustomThemeChanges() {
    if (this.isSavingCustomTheme) {
      return;
    }
    const draft = this.customThemeDraft;
    const colors: ThemeColorKey[] = ['backgroundColor', 'cardColor', 'textColor', 'accentColor', 'mutedTextColor'];
    for (let i = 0; i < colors.length; i++) {
      const key = colors[i];
      const raw = this.getColorFromPreset(draft, key);
      if (!this.isValidHexColor(raw)) {
        promptAction.showToast({
          message: `${this.getFieldLabel(key)}格式不正确，请输入如 #FFFFFF`,
          duration: 2000
        });
        return;
      }
    }

    this.isSavingCustomTheme = true;
    const normalizedTheme: ThemePreset = {
      id: CUSTOM_THEME_ID,
      name: '自定义主题',
      backgroundColor: this.normalizeHexColor(draft.backgroundColor),
      cardColor: this.normalizeHexColor(draft.cardColor),
      textColor: this.normalizeHexColor(draft.textColor),
      accentColor: this.normalizeHexColor(draft.accentColor),
      mutedTextColor: this.normalizeHexColor(draft.mutedTextColor)
    };

    this.customTheme = normalizedTheme;
    this.refreshThemeList(normalizedTheme);

    try {
      await storage.saveCustomThemePreset(normalizedTheme);
      await this.selectTheme(CUSTOM_THEME_ID);
      this.showCustomThemeEditor = false;
      promptAction.showToast({
        message: '自定义主题已保存并应用',
        duration: 1500
      });
    } catch (error) {
      promptAction.showToast({
        message: '保存自定义主题失败',
        duration: 2000
      });
    } finally {
      this.isSavingCustomTheme = false;
    }
  }

  getFieldLabel(key: ThemeColorKey): string {
    const field = THEME_COLOR_FIELDS.find((item: ThemeColorField) => item.key === key);
    return field ? field.label : '颜色';
  }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    const savedCustomTheme = await storage.getCustomThemePreset();
    if (savedCustomTheme) {
      this.customTheme = cloneThemePreset(savedCustomTheme);
    } else {
      this.customTheme = createDefaultCustomTheme();
    }
    this.customThemeDraft = cloneThemePreset(this.customTheme);
    this.refreshThemeList(this.customTheme);

    const savedThemeId = await storage.getThemePreference();
    if (savedThemeId) {
      const exists = this.themePresets.some((theme: ThemePreset) => theme.id === savedThemeId);
      this.selectedThemeId = exists ? savedThemeId : DEFAULT_THEME_ID;
    }
  }

  async selectTheme(themeId: string) {
    this.selectedThemeId = themeId;
    await storage.saveThemePreference(themeId);
    const themeName = this.themePresets.find((theme: ThemePreset) => theme.id === themeId)?.name || '';
    promptAction.showToast({
      message: `已切换主题：${themeName}`,
      duration: 1500
    });
    this.showThemeSelector = false;
  }

  toggleThemeSelector() {
    this.showThemeSelector = !this.showThemeSelector;
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
      promptAction.showToast({
        message: '导出失败',
        duration: 2000
      });
    }
  }

  async clearAllData() {
    promptAction.showDialog({
      title: '危险操作',
      message: '确定要清空所有数据吗？此操作不可恢复！',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '清空', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        storage.clearAllData().then(() => {
          promptAction.showToast({
            message: '数据已清空',
            duration: 2000
          });
        }).catch((err: Error) => {
          promptAction.showToast({
            message: '清空失败',
            duration: 2000
          });
        });
      }
    }).catch((err: Error) => {
      console.error(`清空数据对话框错误: ${err}`);
    });
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup'))
          .width(28)
          .height(28)
          .padding(4)
          .margin({ right: 12 })
          .onClick(() => {
            router.back();
          })
        Text('关于我们')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      Scroll() {
        Column({ space: 16 }) {
          // 数据管理标题
          Text('数据管理')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColor('textColor'))
            .width('100%')
            .margin({ bottom: 8 })

          // 数据统计
          Row() {
            Text('📊 数据统计')
              .fontSize(16)
              .fontColor(this.getThemeColor('textColor'))
            Blank()
            Image($r('app.media.ic_right'))
              .width(20)
              .height(20)
              .fillColor('#666666')
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })
          .onClick(() => {
            router.pushUrl({ url: 'pages/Statistics' });
          })

          // 导出数据
          Row() {
            Text('📤 导出数据')
              .fontSize(16)
              .fontColor(this.getThemeColor('textColor'))
            Blank()
            Image($r('app.media.ic_right'))
              .width(20)
              .height(20)
              .fillColor('#666666')
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })
          .onClick(() => {
            this.exportData();
          })

          // 清空数据
          Row() {
            Text('🗑️ 清空所有数据')
              .fontSize(16)
              .fontColor('#FF3B30')
            Blank()
            Image($r('app.media.ic_right'))
              .width(20)
              .height(20)
              .fillColor('#FF3B30')
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })
          .onClick(() => {
            this.clearAllData();
          })

          Divider()
            .strokeWidth(0.5)
            .color('#E5E5EA')
            .margin({ top: 16, bottom: 16 })

          // 主题风格
          Text('主题风格')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColor('textColor'))
            .width('100%')
            .margin({ bottom: 8 })

          Row() {
            Column({ space: 4 }) {
              Text('当前主题')
                .fontSize(14)
                .fontColor(this.getThemeColor('mutedTextColor'))
              Text(this.themePresets.find((theme: ThemePreset) => theme.id === this.selectedThemeId)?.name || '默认')
                .fontSize(16)
                .fontColor(this.getThemeColor('textColor'))
                .fontWeight(FontWeight.Medium)
            }
            Blank()
            Image($r('app.media.ic_backup2'))
              .width(20)
              .height(20)
              .fillColor('#666666')
              .rotate({ angle: this.showThemeSelector ? 90 : 0 })
          }
          .width('100%')
          .height(72)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })
          .onClick(() => {
            this.toggleThemeSelector();
          })

          if (this.showThemeSelector) {
            Column({ space: 12 }) {
              ForEach(this.themePresets, (theme: ThemePreset) => {
                Row() {
                  Column({ space: 6 }) {
                    Text(theme.name)
                      .fontSize(16)
                      .fontColor(this.getThemeColor('textColor'))
                      .fontWeight(FontWeight.Medium)
                    Row({ space: 8 }) {
                      Text(`背景 ${theme.backgroundColor}`)
                        .fontSize(12)
                        .fontColor(this.getThemeColor('mutedTextColor'))
                      Text(`强调 ${theme.accentColor}`)
                        .fontSize(12)
                        .fontColor(this.getThemeColor('mutedTextColor'))
                    }
                  }
                  Blank()
                  if (this.selectedThemeId === theme.id) {
                    Text('✓')
                      .fontSize(18)
                      .fontColor(theme.accentColor)
                  } else {
                    Row()
                      .width(18)
                      .height(18)
                      .borderRadius(9)
                      .border({ width: 1, color: '#E5E7EB' })
                      .backgroundColor(this.getThemeColor('cardColor'))
                  }
                }
                .width('100%')
                .height(72)
                .padding({ left: 20, right: 20 })
                .borderRadius(12)
                .backgroundColor(this.getThemeColor('cardColor'))
                .border({
                  width: 1,
                  color: this.selectedThemeId === theme.id ? theme.accentColor : '#F1F5F9'
                })
                .onClick(() => {
                  this.selectTheme(theme.id);
                })
              }, (theme: ThemePreset) => theme.id)
            }
            .width('100%')
            .padding({ top: 12, bottom: 4 })
          }

          Column({ space: 12 }) {
            Row() {
              Column({ space: 4 }) {
                Text('自定义主题')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.getThemeColor('textColor'))
                Text('设置属于你的颜色组合')
                  .fontSize(13)
                  .fontColor(this.getThemeColor('mutedTextColor'))
              }
              Blank()
              Button(this.showCustomThemeEditor ? '关闭编辑' : '编辑颜色')
                .fontSize(14)
                .height(34)
                .padding({ left: 16, right: 16 })
                .borderRadius(17)
                .fontColor('#FFFFFF')
                .backgroundColor(this.getThemeColor('accentColor'))
                .onClick(() => {
                  this.toggleCustomThemeEditor();
                })
              Button('应用主题')
                .fontSize(14)
                .height(34)
                .padding({ left: 16, right: 16 })
                .borderRadius(17)
                .fontColor('#FFFFFF')
                .backgroundColor(this.getThemeColor('accentColor'))
                .onClick(() => {
                  this.selectTheme(CUSTOM_THEME_ID);
                })
            }
            .width('100%')

            Row({ space: 12 }) {
              ForEach(THEME_COLOR_FIELDS, (field: ThemeColorField) => {
                Column({ space: 6 }) {
                  Text(field.label)
                    .fontSize(12)
                    .fontColor(this.getThemeColor('mutedTextColor'))
                  Row()
                    .width(44)
                    .height(44)
                    .borderRadius(12)
                    .backgroundColor(this.getColorFromPreset(this.customTheme, field.key))
                    .border({ width: 1, color: '#E5E7EB' })
                }
              }, (field: ThemeColorField) => field.key)
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .borderRadius(16)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 3,
            color: '#0000000A',
            offsetX: 0,
            offsetY: 2
          })

          if (this.showCustomThemeEditor) {
            Column({ space: 16 }) {
              ForEach(THEME_COLOR_FIELDS, (field: ThemeColorField) => {
                Column({ space: 6 }) {
                  Text(field.label)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.getThemeColor('textColor'))
                  Row({ space: 12 }) {
                    TextInput({
                      placeholder: '#FFFFFF',
                      text: this.getColorFromPreset(this.customThemeDraft, field.key)
                    })
                      .width('70%')
                      .height(40)
                      .borderRadius(10)
                      .fontSize(14)
                      .padding({ left: 12, right: 12 })
                      .backgroundColor(this.getThemeColor('cardColor'))
                      .border({
                        width: 1,
                        color: this.isValidHexColor(this.getColorFromPreset(this.customThemeDraft, field.key)) ? '#E5E7EB' : '#F87171'
                      })
                      .onChange((value: string) => {
                        this.updateCustomThemeDraftColor(field.key, value);
                      })

                    Row()
                      .width(44)
                      .height(44)
                      .borderRadius(12)
                      .backgroundColor(this.getColorFromPreset(this.customThemeDraft, field.key))
                      .border({ width: 1, color: '#E5E7EB' })
                  }
                  Text(field.description)
                    .fontSize(12)
                    .fontColor(this.getThemeColor('mutedTextColor'))
                }
                .width('100%')
              }, (field: ThemeColorField) => field.key)

              Row({ space: 12 }) {
                Button('取消')
                  .layoutWeight(1)
                  .height(44)
                  .borderRadius(22)
                  .fontSize(15)
                  .fontColor(this.getThemeColor('textColor'))
                  .backgroundColor(this.getThemeColor('cardColor'))
                  .border({ width: 1, color: '#E5E7EB' })
                  .onClick(() => {
                    this.toggleCustomThemeEditor();
                  })
                Button(this.isSavingCustomTheme ? '保存中…' : '保存并应用')
                  .layoutWeight(1)
                  .height(44)
                  .borderRadius(22)
                  .fontSize(15)
                  .fontColor('#FFFFFF')
                  .backgroundColor(this.getThemeColor('accentColor'))
                  .onClick(() => {
                    this.saveCustomThemeChanges();
                  })
                  .enabled(!this.isSavingCustomTheme)
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 16, bottom: 16 })
            .borderRadius(16)
            .backgroundColor(this.getThemeColor('cardColor'))
            .shadow({
              radius: 4,
              color: '#00000012',
              offsetX: 0,
              offsetY: 2
            })
          }

          Divider()
            .strokeWidth(0.5)
            .color('#E5E5EA')
            .margin({ top: 16, bottom: 16 })

          // 关于标题
          Text('关于应用')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getThemeColor('textColor'))
            .width('100%')
            .margin({ bottom: 8 })

          // 版本号
          Row() {
            Text('版本号')
              .fontSize(16)
              .fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('V1.0.0')
              .fontSize(16)
              .fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })

          // 开发者
          Row() {
            Text('开发者')
              .fontSize(16)
              .fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('TsangHaotian')
              .fontSize(16)
              .fontColor(this.getThemeColor('mutedTextColor'))
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })

          // 联系邮箱
          Row() {
            Text('联系邮箱')
              .fontSize(16)
              .fontColor(this.getThemeColor('textColor'))
            Blank()
            Text('TsangHaotian@hotmail.com')
              .fontSize(12)
              .fontColor(this.getThemeColor('mutedTextColor'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .constraintSize({ maxWidth: '60%' })
          }
          .width('100%')
          .height(56)
          .padding({ left: 20, right: 20 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })

          // 项目开源地址
          Column({ space: 8 }) {
          Row() {
            Text('项目开源地址')
                .fontSize(16)
                .fontColor(this.getThemeColor('textColor'))
            Blank()
            }
            .width('100%')
            Text('https://github.com/TsangHaotian/Harmony_EyesNote')
              .fontSize(14)
              .fontColor(this.getThemeColor('accentColor'))
              .width('100%')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .borderRadius(12)
          .backgroundColor(this.getThemeColor('cardColor'))
          .shadow({
            radius: 2,
            color: '#00000006',
            offsetX: 0,
            offsetY: 1
          })

        }
        .width('100%')
        .padding({ top: 24, left: 20, right: 20, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
      .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}