//Statistics.ets - 数据统计页面
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import { StatisticsData, DailyHealthRecord, HealthScore, HealthAnalysis, ThemePreset } from '../utils/Types';
import { HealthCalculator } from '../utils/HealthCalculator';
import promptAction from '@ohos.promptAction';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';
import { Card } from '../components/Card';

@Entry
@Component
struct Statistics {
  @State statisticsData: StatisticsData = {
    totalNotes: 0, totalWords: 0, avgWaterCount: 0, avgSleepHours: 0, avgStepsCount: 0, healthRecordsCount: 0, mostCommonMood: '开心'
  };
  @State recentRecords: DailyHealthRecord[] = [];
  @State isLoading: boolean = true;
  @State healthScore: HealthScore | null = null;
  @State healthAnalysis: HealthAnalysis | null = null;

  private theme: ThemePreset = getTheme();

  getThemeColor(key: ThemeColorKey): string { return getThemeColorValue(this.theme, key); }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      this.statisticsData = await storage.getStatisticsData();
      const allRecords = await storage.getDailyHealthRecords();
      this.recentRecords = allRecords.sort((a, b) => b.date.localeCompare(a.date)).slice(0, 7);
      this.healthScore = await storage.getHealthScore();
      this.healthAnalysis = await storage.getHealthAnalysis();
    } catch (error) {
      console.error(`加载统计数据失败: ${error}`);
      promptAction.showToast({ message: '加载数据失败', duration: 2000 });
    } finally {
      this.isLoading = false;
    }
  }

  async exportData() {
    try {
      const data = await storage.exportAllData();
      promptAction.showToast({ message: `数据已导出，共${data.length}字符\n可在设置页面查看导出选项`, duration: 3000 });
      console.log('导出数据:', data);
    } catch (error) {
      promptAction.showToast({ message: '导出失败', duration: 2000 });
    }
  }

  @Builder
  renderScoreItem(label: string, score: number, color: string) {
    Row() {
      Text(label).fontSize(14).fontColor(this.getThemeColor('textColor'))
      Blank()
      Row({ space: 8 }) {
        Text(`${score}`).fontSize(16).fontColor(color).fontWeight(FontWeight.Medium)
        Text('/25').fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
      }
    }.width('100%').padding({ top: 4, bottom: 4 })
  }

  @Builder
  renderHealthScore(totalScore: number) {
    Column({ space: 8 }) {
      Text(`${totalScore}`).fontSize(48).fontWeight(FontWeight.Bold).fontColor(this.getHealthLevelColor(totalScore))
      Text(this.getHealthLevelText(totalScore)).fontSize(16).fontColor(this.getHealthLevelColor(totalScore)).fontWeight(FontWeight.Medium)
      Text(this.getHealthLevelDescription(totalScore)).fontSize(12).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 4 })
    }
    .width('100%').padding({ top: 12, bottom: 12 }).alignItems(HorizontalAlign.Center)
  }

  private getHealthLevelColor(score: number): string { return HealthCalculator.getHealthLevel(score).color; }
  private getHealthLevelText(score: number): string { return HealthCalculator.getHealthLevel(score).level; }
  private getHealthLevelDescription(score: number): string { return HealthCalculator.getHealthLevel(score).description; }

  build() {
    Column() {
      // 顶部安全距离（避开摄像头区域）
      Row().width('100%').height(40).backgroundColor(this.getThemeColor('backgroundColor'))

      // 顶部导航栏
      Row() {
        Image($r('app.media.ic_backup')).width(28).height(28).padding(4).margin({ right: 12 })
          .onClick(() => { router.back(); })
        Text('数据统计').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })
      .backgroundColor(this.getThemeColor('backgroundColor'))

      Divider().strokeWidth(0.5).color('#E5E5EA')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).margin({ top: 100 })
          Text('加载中...').fontSize(14).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 16 })
        }
        .width('100%').layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 20 }) {
            // 笔记统计
            Card({ cardColor: this.getThemeColor('cardColor') }) {
              Column({ space: 12 }) {
                Text('📝 笔记统计').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
                Row() {
                  Column({ space: 4 }) {
                    Text(`${this.statisticsData.totalNotes}`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#007AFF')
                    Text('总笔记数').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
                  }.layoutWeight(1)
                  Column({ space: 4 }) {
                    Text(`${this.statisticsData.totalWords}`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#34C759')
                    Text('总字数').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
                  }.layoutWeight(1)
                }.width('100%').padding({ top: 8 })
              }.width('100%').padding(24)
            }

            // 健康统计
            Card({ cardColor: this.getThemeColor('cardColor') }) {
              Column({ space: 12 }) {
                Text('💪 健康统计').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
                Row() {
                  Column({ space: 4 }) {
                    Text(`${this.statisticsData.avgWaterCount}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#007AFF')
                    Text('平均饮水量/天').fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                  }.layoutWeight(1)
                  Column({ space: 4 }) {
                    Text(`${this.statisticsData.avgSleepHours}`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#34C759')
                    Text('平均睡眠/小时').fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                  }.layoutWeight(1)
                  Column({ space: 4 }) {
                    Text(`${Math.floor(this.statisticsData.avgStepsCount / 1000)}k`).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FF9500')
                    Text('平均步数').fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                  }.layoutWeight(1)
                }.width('100%').padding({ top: 8 })

                Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 12, bottom: 8 })
                Row() {
                  Text('记录天数').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
                  Blank()
                  Text(`${this.statisticsData.healthRecordsCount} 天`).fontSize(16).fontColor(this.getThemeColor('textColor')).fontWeight(FontWeight.Medium)
                }.width('100%')
                Row() {
                  Text('最常见心情').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
                  Blank()
                  Text(this.statisticsData.mostCommonMood).fontSize(16).fontColor('#AF52DE').fontWeight(FontWeight.Medium)
                }.width('100%').margin({ top: 8 })
              }.width('100%').padding(24)
            }

            // 健康评分
            if (this.healthScore) {
              Card({ cardColor: this.getThemeColor('cardColor') }) {
                Column({ space: 12 }) {
                  Text('⭐ 今日健康评分').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
                  this.renderHealthScore(this.healthScore.totalScore)
                  Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 8, bottom: 8 })
                  Column({ space: 8 }) {
                    this.renderScoreItem('💧 饮水', this.healthScore.waterScore, '#007AFF')
                    this.renderScoreItem('😴 睡眠', this.healthScore.sleepScore, '#34C759')
                    this.renderScoreItem('🚶 步数', this.healthScore.stepsScore, '#FF9500')
                    this.renderScoreItem('😊 心情', this.healthScore.moodScore, '#AF52DE')
                  }.width('100%')

                  if (this.healthScore.suggestions.length > 0) {
                    Divider().strokeWidth(0.5).color('#E5E5EA').margin({ top: 12, bottom: 8 })
                    Column({ space: 6 }) {
                      Text('💡 改进建议').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor')).width('100%')
                      ForEach(this.healthScore.suggestions, (suggestion: string) => {
                        Text(`• ${suggestion}`).fontSize(13).fontColor(this.getThemeColor('mutedTextColor')).width('100%').lineHeight(20)
                      })
                    }.width('100%').alignItems(HorizontalAlign.Start)
                  }
                }.width('100%').padding(24)
              }
            }

            // 健康分析
            if (this.healthAnalysis) {
              Card({ cardColor: this.getThemeColor('cardColor') }) {
                Column({ space: 12 }) {
                  Text('📊 健康分析').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
                  Row() {
                    Text('趋势').fontSize(14).fontColor(this.getThemeColor('mutedTextColor'))
                    Blank()
                    Text(this.healthAnalysis.trend).fontSize(14)
                      .fontColor(this.healthAnalysis.trend === '上升' ? '#34C759' : this.healthAnalysis.trend === '下降' ? '#FF3B30' : this.getThemeColor('mutedTextColor'))
                      .fontWeight(FontWeight.Medium)
                  }.width('100%')

                  if (this.healthAnalysis.insights.length > 0) {
                    Column({ space: 6 }) {
                      Text('📈 数据洞察').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor')).width('100%').margin({ top: 8 })
                      ForEach(this.healthAnalysis.insights, (insight: string) => {
                        Text(`• ${insight}`).fontSize(13).fontColor(this.getThemeColor('mutedTextColor')).width('100%').lineHeight(20)
                      })
                    }.width('100%').alignItems(HorizontalAlign.Start)
                  }

                  if (this.healthAnalysis.recommendations.length > 0) {
                    Column({ space: 6 }) {
                      Text('💡 个性化推荐').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor')).width('100%').margin({ top: 8 })
                      ForEach(this.healthAnalysis.recommendations, (rec: string) => {
                        Text(`• ${rec}`).fontSize(13).fontColor(this.getThemeColor('mutedTextColor')).width('100%').lineHeight(20)
                      })
                    }.width('100%').alignItems(HorizontalAlign.Start)
                  }
                }.width('100%').padding(24)
              }
            }

            // 最近记录
            if (this.recentRecords.length > 0) {
              Card({ cardColor: this.getThemeColor('cardColor') }) {
                Column({ space: 12 }) {
                  Text('📅 最近7天记录').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.getThemeColor('textColor'))
                  Column({ space: 8 }) {
                    ForEach(this.recentRecords, (record: DailyHealthRecord) => {
                      Row() {
                        Column({ space: 4 }) {
                          Text(record.date).fontSize(14).fontColor(this.getThemeColor('textColor')).fontWeight(FontWeight.Medium)
                          Text(`💧${record.waterCount}杯  😴${record.sleepHours}h  🚶${record.stepsCount}步`)
                            .fontSize(12).fontColor(this.getThemeColor('mutedTextColor'))
                        }.layoutWeight(1)
                        Text(record.mood).fontSize(14).fontColor('#AF52DE')
                      }.width('100%').padding({ top: 8, bottom: 8 })
                    }, (record: DailyHealthRecord) => record.date)
                  }
                }.width('100%').padding(24)
              }
            }

            // 数据导出按钮
            Button('导出所有数据').width('100%').height(50).fontSize(16).fontColor('#FFFFFF')
              .backgroundColor(this.getThemeColor('accentColor')).borderRadius(25)
              .onClick(() => { this.exportData(); }).margin({ top: 8 })
          }
          .width('100%').padding({ top: 24, left: 20, right: 20, bottom: 24 })
        }
        .layoutWeight(1).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.getThemeColor('backgroundColor'))
  }
}
