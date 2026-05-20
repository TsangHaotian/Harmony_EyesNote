// HealthTracker.ets - 健康追踪 Tab 组件
import { ThemePreset } from '../utils/Types';
import { Card } from '../components/Card';
import promptAction from '@ohos.promptAction';

@Component
export struct HealthTracker {
  @Prop themePresets: ThemePreset[] = []
  @Prop selectedThemeId: string = ''
  getThemeColor: (key: string) => string = () => ''
  @Link waterCount: number
  @Link sleepHours: number
  @Link stepsCount: number
  @Link mood: string
  @Link waterGoal: number
  @Link sleepGoal: number
  @Link stepsGoal: number
  @Link lastResetDate: string
  onSave: () => void = () => {}

  @State isSyncing: boolean = false

  runHealthButtonAnimation(action: () => void) {
    animateTo({ duration: 220, curve: 'easeInOut' }, () => { action(); });
  }

  incrementWater() { this.runHealthButtonAnimation(() => { this.waterCount += 1; this.onSave(); }); }
  decrementWater() { if (this.waterCount === 0) return; this.runHealthButtonAnimation(() => { this.waterCount -= 1; this.onSave(); }); }
  incrementSteps() { this.runHealthButtonAnimation(() => { this.stepsCount += 100; this.onSave(); }); }
  decrementSteps() { if (this.stepsCount < 100) return; this.runHealthButtonAnimation(() => { this.stepsCount -= 100; this.onSave(); }); }

  changeSleep(hours: number) {
    const nextValue = Math.max(1, Math.min(12, this.sleepHours + hours));
    if (nextValue === this.sleepHours) return;
    this.runHealthButtonAnimation(() => { this.sleepHours = nextValue; this.onSave(); });
  }

  changeMood(newMood: string) {
    if (this.mood === newMood) return;
    this.runHealthButtonAnimation(() => { this.mood = newMood; this.onSave(); });
  }

  updateWaterGoal(delta: number) {
    const nextValue = Math.max(1, this.waterGoal + delta);
    if (nextValue === this.waterGoal) return;
    this.runHealthButtonAnimation(() => { this.waterGoal = nextValue; this.onSave(); });
  }

  updateSleepGoal(delta: number) {
    const nextValue = Math.max(1, this.sleepGoal + delta);
    if (nextValue === this.sleepGoal) return;
    this.runHealthButtonAnimation(() => { this.sleepGoal = nextValue; this.onSave(); });
  }

  updateStepsGoal(delta: number) {
    const nextValue = Math.max(1000, this.stepsGoal + delta);
    if (nextValue === this.stepsGoal) return;
    this.runHealthButtonAnimation(() => { this.stepsGoal = nextValue; this.onSave(); });
  }

  build() {
    Scroll() {
      Column({ space: 20 }) {
        // 顶部标题和同步按钮
        Row() {
          Text('健康追踪').fontSize(24).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
          Blank()
          Button(this.isSyncing ? '同步中...' : '🔄 同步')
            .fontSize(14).fontColor('#FFFFFF')
            .backgroundColor(this.getThemeColor('accentColor'))
            .borderRadius(16).height(32).padding({ left: 12, right: 12 })
            .enabled(!this.isSyncing)
            .onClick(() => {
              this.isSyncing = true;
              promptAction.showToast({ message: '功能待开发，敬请期待', duration: 3000 });
              setTimeout(() => { this.isSyncing = false; }, 1000);
            })
        }
        .width('100%').margin({ top: 24, bottom: 8 }).padding({ left: 20, right: 20 })

        // 饮水追踪
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
              Text('💧 今日饮水').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.waterGoal}杯`).fontSize(12).fontColor('#666666')
            }.width('100%')
            Text(`${this.waterCount} / ${this.waterGoal} 杯`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#007AFF').margin({ top: 8, bottom: 8 })
            Row() {
              Row().width(`${Math.min(100, (this.waterCount / this.waterGoal) * 100)}%`).height(6).backgroundColor('#007AFF').borderRadius(3)
              Row().layoutWeight(1).height(6).backgroundColor('#E5E5EA').borderRadius(3)
            }.width('100%').height(6).borderRadius(3).backgroundColor('#E5E5EA')
            Row({ space: 16 }) {
              Button('-').width(48).height(48).borderRadius(24).fontSize(20).fontColor('#FFFFFF').backgroundColor('#FF3B30').onClick(() => this.decrementWater())
              Button('+').width(48).height(48).borderRadius(24).fontSize(20).fontColor('#FFFFFF').backgroundColor('#34C759').onClick(() => this.incrementWater())
            }
          }.width('100%').padding(24)
        }

        // 睡眠记录
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
              Text('😴 睡眠时间').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.sleepGoal}小时`).fontSize(12).fontColor('#666666')
            }.width('100%')
            Text(`${this.sleepHours} / ${this.sleepGoal} 小时`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#34C759').margin({ top: 8, bottom: 8 })
            Row() {
              Row().width(`${Math.min(100, (this.sleepHours / this.sleepGoal) * 100)}%`).height(6).backgroundColor('#34C759').borderRadius(3)
              Row().layoutWeight(1).height(6).backgroundColor('#E5E5EA').borderRadius(3)
            }.width('100%').height(6).borderRadius(3).backgroundColor('#E5E5EA')
            Row({ space: 16 }) {
              Button('-').width(48).height(48).borderRadius(24).fontSize(20).fontColor('#FFFFFF').backgroundColor('#FF3B30').onClick(() => this.changeSleep(-1))
              Button('+').width(48).height(48).borderRadius(24).fontSize(20).fontColor('#FFFFFF').backgroundColor('#34C759').onClick(() => this.changeSleep(1))
            }
          }.width('100%').padding(24)
        }

        // 步数统计
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Row() {
              Text('🚶 今日步数').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
              Blank()
              Text(`目标: ${this.stepsGoal}步`).fontSize(12).fontColor('#666666')
            }.width('100%')
            Text(`${this.stepsCount} / ${this.stepsGoal} 步`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#FF9500').margin({ top: 8, bottom: 8 })
            Row() {
              Row().width(`${Math.min(100, (this.stepsCount / this.stepsGoal) * 100)}%`).height(6).backgroundColor('#FF9500').borderRadius(3)
              Row().layoutWeight(1).height(6).backgroundColor('#E5E5EA').borderRadius(3)
            }.width('100%').height(6).borderRadius(3).backgroundColor('#E5E5EA')
            Row({ space: 16 }) {
              Button('-100').width(72).height(48).borderRadius(24).fontSize(14).fontColor('#FFFFFF').backgroundColor('#FF3B30').onClick(() => this.decrementSteps())
              Button('+100').width(72).height(48).borderRadius(24).fontSize(14).fontColor('#FFFFFF').backgroundColor('#34C759').onClick(() => this.incrementSteps())
            }
          }.width('100%').padding(24)
        }

        // 心情记录
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Text('😊 今日心情').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
            Text(this.mood).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#AF52DE').margin({ top: 8, bottom: 8 })
            Row({ space: 10 }) {
              ForEach(['开心', '平静', '疲惫', '焦虑', '兴奋'], (moodOption: string) => {
                Button(moodOption).height(40).borderRadius(20).fontSize(14)
                  .fontColor(this.mood === moodOption ? '#FFFFFF' : this.getThemeColor('textColor'))
                  .backgroundColor(this.mood === moodOption ? '#AF52DE' : '#F2F2F7')
                  .onClick(() => this.changeMood(moodOption))
              })
            }.width('100%').justifyContent(FlexAlign.SpaceEvenly).padding({ top: 4 })
          }.width('100%').padding(24)
        }

        // 健康目标设置
        Card({ cardColor: this.getThemeColor('cardColor') }) {
          Column({ space: 16 }) {
            Text('🎯 健康目标设置').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor')).width('100%')
            Column({ space: 10 }) {
              Row() {
                Text('💧 饮水目标').fontSize(15).fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.waterGoal} 杯`).fontSize(15).fontColor('#007AFF').fontWeight(FontWeight.Medium)
              }.width('100%')
              Row({ space: 12 }) {
                Button('-').layoutWeight(1).height(40).fontSize(16).fontColor('#FFFFFF').backgroundColor('#FF3B30').borderRadius(20).onClick(() => this.updateWaterGoal(-1))
                Button('+').layoutWeight(1).height(40).fontSize(16).fontColor('#FFFFFF').backgroundColor('#34C759').borderRadius(20).onClick(() => this.updateWaterGoal(1))
              }.width('100%')
            }.width('100%')
            Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 8, bottom: 8 })
            Column({ space: 10 }) {
              Row() {
                Text('😴 睡眠目标').fontSize(15).fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.sleepGoal} 小时`).fontSize(15).fontColor('#34C759').fontWeight(FontWeight.Medium)
              }.width('100%')
              Row({ space: 12 }) {
                Button('-').layoutWeight(1).height(40).fontSize(16).fontColor('#FFFFFF').backgroundColor('#FF3B30').borderRadius(20).onClick(() => this.updateSleepGoal(-1))
                Button('+').layoutWeight(1).height(40).fontSize(16).fontColor('#FFFFFF').backgroundColor('#34C759').borderRadius(20).onClick(() => this.updateSleepGoal(1))
              }.width('100%')
            }.width('100%')
            Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 8, bottom: 8 })
            Column({ space: 10 }) {
              Row() {
                Text('🚶 步数目标').fontSize(15).fontColor(this.getThemeColor('textColor'))
                Blank()
                Text(`${this.stepsGoal} 步`).fontSize(15).fontColor('#FF9500').fontWeight(FontWeight.Medium)
              }.width('100%')
              Row({ space: 12 }) {
                Button('-1000').layoutWeight(1).height(40).fontSize(14).fontColor('#FFFFFF').backgroundColor('#FF3B30').borderRadius(20).onClick(() => this.updateStepsGoal(-1000))
                Button('+1000').layoutWeight(1).height(40).fontSize(14).fontColor('#FFFFFF').backgroundColor('#34C759').borderRadius(20).onClick(() => this.updateStepsGoal(1000))
              }.width('100%')
            }.width('100%')
          }.width('100%').padding(24)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
  }
}
