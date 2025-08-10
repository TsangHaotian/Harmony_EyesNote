import router from '@ohos.router';
import { storage } from '../utils/Storage';
import promptAction from '@ohos.promptAction';

// 定义路由参数接口
interface NoteParams {
  noteContent?: string;
  noteIndex?: number;
}

@Entry
@Component
struct NoteDetail {
  @State noteContent: string = '';
  @State editedContent: string = '';
  @State noteIndex: number = -1;

  async aboutToAppear() {
    const params = router.getParams() as NoteParams;
    this.noteContent = params.noteContent || '';
    this.noteIndex = params.noteIndex || -1;
    this.editedContent = this.noteContent;
  }

  async saveNote() {
    if (this.editedContent.trim() === '') {
      promptAction.showToast({
        message: '内容不能为空',
        duration: 2000
      });
      return;
    }

    if (this.noteIndex >= 0) {
      // 编辑已有笔记
      const historyNotes = await storage.getHistoryNotes();
      historyNotes[this.noteIndex] = this.editedContent;
      await storage.saveHistoryNotes(historyNotes);
    } else {
      // 创建新笔记
      const historyNotes = await storage.getHistoryNotes();
      historyNotes.unshift(this.editedContent); // 添加到历史笔记列表的开头
      await storage.saveHistoryNotes(historyNotes);
      // 更新索引为0，因为新笔记被添加到了列表开头
      this.noteIndex = 0;
    }
    
    // 返回首页并传递更新后的内容和索引
    router.back({
      url: 'pages/Index',
      params: {
        content: this.editedContent,
        index: this.noteIndex
      }
    });
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
        Text('笔记详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
        Blank()
        Button('保存')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(20)
          .height(36)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.saveNote();
          })
      }
      .width('100%')
      .height(58)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#f5f5f5')

      // 笔记内容编辑区
      Column() {
        TextArea({ placeholder: '请输入笔记内容...', text: this.editedContent })
          .width('100%')
          .height('100%')
          .fontSize(16)
          .backgroundColor('#FFFFFF')
          .placeholderColor('#CCCCCC')
          .padding(16)
          .onChange((value: string) => {
            this.editedContent = value;
          })
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 8 })
      .borderRadius(8)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}