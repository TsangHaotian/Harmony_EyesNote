// MarkdownPreview.ets - 简单的 Markdown 预览组件
@Component
export struct MarkdownPreview {
  @Prop content: string = ''
  @Prop textColor: string = '#FFFFFF'
  @Prop mutedColor: string = 'rgba(255,255,255,0.6)'
  @Prop accentColor: string = '#60A5FA'

  build() {
    Column() {
      ForEach(this.getLines(), (line: string, idx: number) => {
        if (line === '') {
          Row().height(6).width('100%')
        } else if (this.starts(line, '# ')) {
          Text(this.after(line, '# ')).fontSize(22).fontWeight(FontWeight.Bold)
            .fontColor(this.textColor).width('100%').lineHeight(32).padding({ top: 6, bottom: 2 })
        } else if (this.starts(line, '## ')) {
          Text(this.after(line, '## ')).fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor(this.textColor).width('100%').lineHeight(28).padding({ top: 4, bottom: 2 })
        } else if (this.starts(line, '### ')) {
          Text(this.after(line, '### ')).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor(this.textColor).width('100%').lineHeight(24).padding({ top: 2, bottom: 2 })
        } else if (this.starts(line, '---') || this.starts(line, '___')) {
          Divider().strokeWidth(0.5).color(this.mutedColor).margin({ top: 6, bottom: 6 })
        } else if (this.starts(line, '- ') || this.starts(line, '• ')) {
          Row() {
            Text('  •  ').fontSize(15).fontColor(this.accentColor)
            Text(this.after(line, line.substring(0, 2))).fontSize(15).fontColor(this.textColor).lineHeight(24).layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        } else if (this.starts(line, '□ ')) {
          Row() {
            Text('  ☐  ').fontSize(15).fontColor(this.accentColor)
            Text(this.after(line, '□ ')).fontSize(15).fontColor(this.textColor).lineHeight(24).layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        } else if (this.starts(line, '> ')) {
          Row() {
            Row().width(3).height('100%').backgroundColor(this.accentColor).borderRadius(2).margin({ right: 12 })
            Text(this.after(line, '> ')).fontSize(14).fontColor(this.mutedColor).lineHeight(22).layoutWeight(1).fontStyle(FontStyle.Italic)
          }.width('100%').padding({ left: 4 }).alignItems(VerticalAlign.Top)
        } else if (this.isNumbered(line)) {
          Row() {
            Text(`  ${this.getNum(line)}  `).fontSize(15).fontColor(this.accentColor)
            Text(this.getNumText(line)).fontSize(15).fontColor(this.textColor).lineHeight(24).layoutWeight(1)
          }.width('100%').alignItems(VerticalAlign.Top)
        } else {
          Text(line).fontSize(15).fontColor(this.textColor).lineHeight(24).width('100%')
        }
      }, (line: string, idx: number) => `md_${idx}`)
    }
    .width('100%')
  }

  getLines(): string[] {
    const raw = this.content || '';
    const lines: string[] = [];
    let cur = '';
    for (let i = 0; i < raw.length; i++) {
      if (raw[i] === '\n') {
        lines.push(cur);
        cur = '';
      } else {
        cur += raw[i];
      }
    }
    lines.push(cur);
    return lines;
  }

  starts(s: string, prefix: string): boolean {
    if (s.length < prefix.length) return false;
    for (let i = 0; i < prefix.length; i++) {
      if (s[i] !== prefix[i]) return false;
    }
    return true;
  }

  after(s: string, prefix: string): string {
    if (s.length <= prefix.length) return '';
    let result = '';
    for (let i = prefix.length; i < s.length; i++) {
      result += s[i];
    }
    return result;
  }

  isNumbered(s: string): boolean {
    let i = 0;
    let hasDigit = false;
    while (i < s.length && s[i] >= '0' && s[i] <= '9') {
      hasDigit = true;
      i++;
    }
    return hasDigit && i < s.length && s[i] === '.';
  }

  getNum(s: string): string {
    let result = '';
    for (let i = 0; i < s.length; i++) {
      if (s[i] === '.') { result += '.'; break; }
      result += s[i];
    }
    return result;
  }

  getNumText(s: string): string {
    let i = 0;
    while (i < s.length && s[i] >= '0' && s[i] <= '9') { i++; }
    if (i < s.length && s[i] === '.') { i++; }
    if (i < s.length && s[i] === ' ') { i++; }
    let result = '';
    for (let j = i; j < s.length; j++) result += s[j];
    return result;
  }
}
