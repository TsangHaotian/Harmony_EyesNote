//Statistics.ets - 数据统计（科幻风格）
import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { storage } from '../utils/Storage';
import { NoteItem, ThemePreset } from '../utils/Types';
import { ThemeColorKey, getTheme, getThemeColorValue } from '../utils/Theme';

interface ChartPoint {
  label: string;
  count: number;
}

@Entry
@Component
struct Statistics {
  @State totalNotes: number = 0;
  @State totalWords: number = 0;
  @State doneNotes: number = 0;
  @State chartData: ChartPoint[] = [];
  @State doneChartData: ChartPoint[] = [];
  @State chartMaxVal: number = 1;
  @State isLoading: boolean = true;
  @State animProgress: number = 0;

  private theme: ThemePreset = getTheme();
  private ctx1: CanvasRenderingContext2D = new CanvasRenderingContext2D();
  private ctx2: CanvasRenderingContext2D = new CanvasRenderingContext2D();

  getThemeColor(key: ThemeColorKey): string { return getThemeColorValue(this.theme, key); }

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    await storage.init(context);
    await this.loadData();
  }

  async loadData() {
    this.isLoading = true;
    try {
      const notes: NoteItem[] = await storage.getHistoryNotes() || [];
      this.totalNotes = notes.length;
      let wc = 0;
      let done = 0;
      for (let i = 0; i < notes.length; i++) {
        wc += notes[i].content.replace(/\s/g, '').length;
        if (notes[i].done) done++;
      }
      this.totalWords = wc;
      this.doneNotes = done;

      // 统计最近7天
      const dateKeys: string[] = [];
      const dateVals: number[] = [];
      const doneVals: number[] = [];
      for (let i = 0; i < notes.length; i++) {
        const d = notes[i].createdAt.substring(0, 10);
        let idx = -1;
        for (let j = 0; j < dateKeys.length; j++) {
          if (dateKeys[j] === d) { idx = j; break; }
        }
        if (idx >= 0) {
          dateVals[idx]++;
          if (notes[i].done) doneVals[idx]++;
        } else {
          dateKeys.push(d);
          dateVals.push(1);
          doneVals.push(notes[i].done ? 1 : 0);
        }
      }

      const pts: ChartPoint[] = [];
      const dpts: ChartPoint[] = [];
      const today = new Date();
      for (let i = 6; i >= 0; i--) {
        const dd = new Date(today);
        dd.setDate(dd.getDate() - i);
        const y = dd.getFullYear();
        const m = (dd.getMonth() + 1).toString().padStart(2, '0');
        const day = dd.getDate().toString().padStart(2, '0');
        const key = `${y}-${m}-${day}`;
        let cnt = 0;
        let dcnt = 0;
        for (let j = 0; j < dateKeys.length; j++) {
          if (dateKeys[j] === key) { cnt = dateVals[j]; dcnt = doneVals[j]; break; }
        }
        pts.push({ label: `${dd.getMonth() + 1}/${dd.getDate()}`, count: cnt });
        dpts.push({ label: `${dd.getMonth() + 1}/${dd.getDate()}`, count: dcnt });
      }
      this.chartData = pts;
      this.doneChartData = dpts;

      // 计算笔记趋势的最大值，完成图用同样的比例
      this.chartMaxVal = 1;
      for (let i = 0; i < pts.length; i++) {
        if (pts[i].count > this.chartMaxVal) this.chartMaxVal = pts[i].count;
      }

      this.animProgress = 0;
      const step = () => {
        if (this.animProgress < 1) {
          this.animProgress += 0.05;
          this.renderChart(this.ctx1, this.chartData, '#60A5FA');
          this.renderChart(this.ctx2, this.doneChartData, '#F59E0B', this.chartMaxVal);
          setTimeout(step, 30);
        } else {
          this.animProgress = 1;
          this.renderChart(this.ctx1, this.chartData, '#60A5FA');
          this.renderChart(this.ctx2, this.doneChartData, '#F59E0B', this.chartMaxVal);
        }
      };
      setTimeout(step, 100);
    } catch (error) {
      console.error(`load error: ${error}`);
    } finally {
      this.isLoading = false;
    }
  }

  renderChart(ctx: CanvasRenderingContext2D, data: ChartPoint[], color: string, fixedMax: number = -1) {
    const w = 340;
    const h = 200;
    const pad = 30;
    const cw = w - pad * 2;
    const ch = h - pad * 2;

    ctx.clearRect(0, 0, w, h);

    if (data.length === 0) return;

    let maxVal = 1;
    if (fixedMax > 0) {
      maxVal = fixedMax;
    } else {
      for (let i = 0; i < data.length; i++) {
        if (data[i].count > maxVal) maxVal = data[i].count;
      }
    }

    // 网格
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.06)';
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= 4; i++) {
      const yy = pad + (ch / 4) * i;
      ctx.beginPath();
      ctx.moveTo(pad, yy);
      ctx.lineTo(w - pad, yy);
      ctx.stroke();
      ctx.fillStyle = 'rgba(255, 255, 255, 0.3)';
      ctx.font = '10px sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(`${Math.round(maxVal - (maxVal / 4) * i)}`, pad - 6, yy + 4);
    }

    // 渐变填充
    const grad = ctx.createLinearGradient(0, pad, 0, h - pad);
    if (color === '#60A5FA') {
      grad.addColorStop(0, 'rgba(96, 165, 250, 0.3)');
      grad.addColorStop(1, 'rgba(96, 165, 250, 0)');
    } else {
      grad.addColorStop(0, 'rgba(245, 158, 11, 0.3)');
      grad.addColorStop(1, 'rgba(245, 158, 11, 0)');
    }

    const step = cw / (data.length - 1);
    const cnt = Math.max(1, Math.floor(data.length * this.animProgress));
    const vis: ChartPoint[] = [];
    for (let i = 0; i < cnt && i < data.length; i++) {
      vis.push(data[i]);
    }
    if (vis.length < 2) return;

    // 填充区域
    ctx.beginPath();
    for (let i = 0; i < vis.length; i++) {
      const x = pad + i * step;
      const y = pad + ch - (vis[i].count / maxVal) * ch;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    const lx = pad + (vis.length - 1) * step;
    ctx.lineTo(lx, pad + ch);
    ctx.lineTo(pad, pad + ch);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    // 折线
    ctx.beginPath();
    for (let i = 0; i < vis.length; i++) {
      const x = pad + i * step;
      const y = pad + ch - (vis[i].count / maxVal) * ch;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = color;
    ctx.lineWidth = 2;
    ctx.shadowColor = color === '#60A5FA' ? 'rgba(96, 165, 250, 0.5)' : 'rgba(245, 158, 11, 0.5)';
    ctx.shadowBlur = 8;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // 数据点
    for (let i = 0; i < vis.length; i++) {
      const x = pad + i * step;
      const y = pad + ch - (vis[i].count / maxVal) * ch;
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fillStyle = color;
      ctx.shadowColor = color === '#60A5FA' ? 'rgba(96, 165, 250, 0.8)' : 'rgba(245, 158, 11, 0.8)';
      ctx.shadowBlur = 12;
      ctx.fill();
      ctx.shadowBlur = 0;
      ctx.beginPath();
      ctx.arc(x, y, 2, 0, Math.PI * 2);
      ctx.fillStyle = '#FFFFFF';
      ctx.fill();
    }

    // X轴标签
    ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    for (let i = 0; i < vis.length; i++) {
      ctx.fillText(data[i].label, pad + i * step, h - pad + 16);
    }
  }

  build() {
    Column() {
      Row().width('100%').height(50).backgroundColor('transparent')

      Row() {
        Image($r('app.media.ic_backup')).width(28).height(28).padding(4).margin({ right: 12 })
          .fillColor(this.getThemeColor('textColor'))
          .onClick(() => { router.back(); })
        Text('数据统计').fontSize(20).fontWeight(FontWeight.Bold).fontColor(this.getThemeColor('textColor'))
        Blank()
      }
      .width('100%').height(56).padding({ left: 20, right: 20, top: 8, bottom: 8 })

      Divider().strokeWidth(0.3).color('rgba(255, 255, 255, 0.1)')

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).margin({ top: 100 }).color('#60A5FA')
          Text('加载中...').fontSize(14).fontColor(this.getThemeColor('mutedTextColor')).margin({ top: 16 })
        }
        .width('100%').layoutWeight(1)
      } else {
        Scroll() {
          Column({ space: 20 }) {
            // 数字卡片
            Row({ space: 12 }) {
              Column({ space: 8 }) {
                Text(`${this.totalNotes}`).fontSize(34).fontWeight(FontWeight.Bold)
                  .fontColor('#60A5FA').shadow({ radius: 10, color: 'rgba(96, 165, 250, 0.4)' })
                Text('总笔记').fontSize(13).fontColor(this.getThemeColor('mutedTextColor'))
              }
              .layoutWeight(1).padding(16)
              .backgroundColor('rgba(255, 255, 255, 0.04)').borderRadius(14)
              .border({ width: 0.5, color: 'rgba(96, 165, 250, 0.2)' })

              Column({ space: 8 }) {
                Text(`${this.totalWords}`).fontSize(34).fontWeight(FontWeight.Bold)
                  .fontColor('#34D399').shadow({ radius: 10, color: 'rgba(52, 211, 153, 0.4)' })
                Text('总字数').fontSize(13).fontColor(this.getThemeColor('mutedTextColor'))
              }
              .layoutWeight(1).padding(16)
              .backgroundColor('rgba(255, 255, 255, 0.04)').borderRadius(14)
              .border({ width: 0.5, color: 'rgba(52, 211, 153, 0.2)' })

              Column({ space: 8 }) {
                Text(`${this.doneNotes}`).fontSize(34).fontWeight(FontWeight.Bold)
                  .fontColor('#F59E0B').shadow({ radius: 10, color: 'rgba(245, 158, 11, 0.4)' })
                Text('已完成').fontSize(13).fontColor(this.getThemeColor('mutedTextColor'))
              }
              .layoutWeight(1).padding(16)
              .backgroundColor('rgba(255, 255, 255, 0.04)').borderRadius(14)
              .border({ width: 0.5, color: 'rgba(245, 158, 11, 0.2)' })
            }
            .width('100%')

            // 笔记趋势折线图
            Column() {
              Column({ space: 12 }) {
                Row() {
                  Text('📈 近7天笔记趋势').fontSize(16).fontWeight(FontWeight.Medium)
                    .fontColor(this.getThemeColor('textColor'))
                  Blank()
                  Row() {
                    Row().width(8).height(2).borderRadius(1).backgroundColor('#60A5FA').margin({ right: 4 })
                    Text('笔记数').fontSize(11).fontColor(this.getThemeColor('mutedTextColor'))
                  }
                }
                .width('100%')
                Canvas(this.ctx1).width('100%').height(220).backgroundColor('transparent')
                  .onReady(() => { this.renderChart(this.ctx1, this.chartData, '#60A5FA'); })
              }
              .width('100%').padding(20)
            }
            .width('100%').borderRadius(14)
            .backgroundColor('rgba(255, 255, 255, 0.04)')
            .border({ width: 0.5, color: 'rgba(96, 165, 250, 0.15)' })

            // 完成趋势折线图
            Column() {
              Column({ space: 12 }) {
                Row() {
                  Text('✅ 近7天完成趋势').fontSize(16).fontWeight(FontWeight.Medium)
                    .fontColor(this.getThemeColor('textColor'))
                  Blank()
                  Row() {
                    Row().width(8).height(2).borderRadius(1).backgroundColor('#F59E0B').margin({ right: 4 })
                    Text('已完成').fontSize(11).fontColor(this.getThemeColor('mutedTextColor'))
                  }
                }
                .width('100%')
                Canvas(this.ctx2).width('100%').height(220).backgroundColor('transparent')
                  .onReady(() => { this.renderChart(this.ctx2, this.doneChartData, '#F59E0B', this.chartMaxVal); })
              }
              .width('100%').padding(20)
            }
            .width('100%').borderRadius(14)
            .backgroundColor('rgba(255, 255, 255, 0.04)')
            .border({ width: 0.5, color: 'rgba(245, 158, 11, 0.15)' })
          }
          .width('100%').padding({ top: 24, left: 20, right: 20, bottom: 24 })
        }
        .layoutWeight(1).width('100%')
        .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%').height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#1a1a2e', 0], ['#16213e', 0.5], ['#0f3460', 1]]
    })
  }
}
