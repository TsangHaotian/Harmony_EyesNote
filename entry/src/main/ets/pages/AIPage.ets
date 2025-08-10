import router from '@ohos.router';
import http from '@ohos.net.http';
import { HealthData } from '../utils/Types'; // 导入共享接口

interface Message {
  role: string;
  content: string;
}

// 简化接口定义
interface DeepSeekMessage {
  content: string;
}

interface DeepSeekChoice {
  message: DeepSeekMessage;
}

interface DeepSeekResponse {
  choices: DeepSeekChoice[];
}

interface AIPageParams {
  healthData?: HealthData;
}

@Entry
@Component
struct AIPage {
  @State aiMessages: Message[] = [];
  @State aiInput: string = '';
  @State isAIChatting: boolean = false;
  @State healthData: HealthData = {
    waterCount: 0,
    sleepHours: 7,
    stepsCount: 0,
    mood: '开心'
  };

  async aboutToAppear() {
    // 获取传递过来的健康数据
    const params = router.getParams() as AIPageParams;
    if (params && params.healthData) {
      this.healthData = params.healthData;

      // 初始消息，介绍健康数据
      const initialMessage: Message = {
        role: 'assistant',
        content: `欢迎使用健康AI助手！根据您提供的健康数据：
` +
          `- 饮水量：${this.healthData.waterCount}杯
` +
          `- 睡眠时间：${this.healthData.sleepHours}小时
` +
          `- 步数：${this.healthData.stepsCount}步
` +
          `- 心情：${this.healthData.mood}

` +
          `您有什么健康问题想要咨询吗？`
      };
      this.aiMessages.push(initialMessage);
    }
  }

  async sendAIMessage() {
    if (this.aiInput.trim().length === 0) {
      return;
    }

    // 添加用户消息
    const userMessage: Message = {
      role: 'user',
      content: this.aiInput
    };
    this.aiMessages.push(userMessage);
    this.aiInput = '';
    this.isAIChatting = true;

    // 准备健康数据
    const healthDataStr = `健康数据：
` +
      `- 饮水量：${this.healthData.waterCount}杯
` +
      `- 睡眠时间：${this.healthData.sleepHours}小时
` +
      `- 步数：${this.healthData.stepsCount}步
` +
      `- 心情：${this.healthData.mood}`;

    const client = http.createHttp();
    try {
      const resp = await client.request(
        'https://api.deepseek.com/v1/chat/completions',
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer sk-20faf5c818224258a495651e2d663907'
          },
          extraData: JSON.stringify({
            model: 'deepseek-chat',
            messages: [
              {
                role: 'system',
                content: '你是「健康顾问AI助手」，你的任务是：' +
                  '1. 分析用户提供的健康数据（饮水量、睡眠时间、步数、心情）' +
                  '2. 提供个性化的健康建议和生活方式改进意见' +
                  '3. 回答用户关于健康、营养、运动等方面的问题' +
                  '4. 保持友好、专业的语气，用通俗易懂的语言解释健康知识' +
                  '5. 结合用户的健康数据给出具体的、可操作的建议'
              } as Message,
              ...this.aiMessages,
              {
                role: 'system',
                content: healthDataStr
              } as Message
            ] as Message[],
            max_tokens: 1000
          })
        }
      );

      if (resp.responseCode === 200) {
        const response: DeepSeekResponse = JSON.parse(resp.result.toString());
        const aiResponse: Message = {
          role: 'assistant',
          content: response.choices[0].message.content.trim()
        };
        this.aiMessages.push(aiResponse);
      } else {
        const errorMessage: Message = {
          role: 'assistant',
          content: `请求失败，错误码：${resp.responseCode}`
        };
        this.aiMessages.push(errorMessage);
      }
    } catch (error) {
      const errorMessage: Message = {
        role: 'assistant',
        content: `发生错误：${JSON.stringify(error)}`
      };
      this.aiMessages.push(errorMessage);
    } finally {
      this.isAIChatting = false;
      client.destroy();
    }
  }

  build() {
    Column() {
      // 顶部标题栏 - 已确认没有额外图标，保持简洁
      Row() {
        Text('健康AI助手')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
        Blank()
      }
      .width('100%')
      .height(66)
      .padding(16)
      .backgroundColor('#ffffff')
      .border({
        width: { bottom: 1 }, // 仅指定下边框宽度
        color: '#888888',
        style: BorderStyle.Solid
      })

      // 聊天记录区域
      Scroll() {
        Column() {
          // 添加日期分隔符（微信风格）
          Text('今天')
            .fontSize(12)
            //.color('#888888')
            .backgroundColor('#f5f5f5')
            .padding({ left: 10, right: 10, top: 2, bottom: 2 })
            .borderRadius(4)
            .margin(10)

          ForEach(this.aiMessages, (message: Message, index: number) => {
            if (message.role === 'user') {
              // 用户消息 - 右对齐，蓝色背景
              Row() {
                Blank()
                Column() {
                  Text(message.content)
                    .backgroundColor('#007AFF')
                    //.color('#ffffff')
                    .padding(12)
                    .borderRadius(18)
                    .borderRadius({
                    topRight: 4  // 仅设置右上角圆角
                  })
                    .constraintSize({ maxWidth: '80%' })
                  Text('') // 空文本占位，用于调整间距
                    .height(8)
                }
              }
              .width('100%')
              .padding({ right: 12, bottom: 6 })
            } else {
              // AI消息 - 左对齐，白色背景，带头像
              Row() {
                Image($r('app.media.ic_ai'))
                  .width(30)
                  .height(30)
                  .borderRadius(20)
                  .margin({ right: 8 })
                Column() {
                  Text(message.content)
                    .backgroundColor('#ffffff')
                    .padding({ right: 22 })
                    .borderRadius(18)
                    .borderRadius({
                      topLeft: 4,
                      topRight: 0,
                      bottomLeft: 0,
                      bottomRight: 0
                    })
                    .constraintSize({ maxWidth: '80%' })
                    .shadow({ radius: 2, color: '#00000010', offsetX: 0, offsetY: 1 })
                  Text('') // 空文本占位，用于调整间距
                    .height(8)
                }
                Blank()
              }
              .width('100%')
              .padding({ left: 12, bottom: 6 })
            }
          })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .backgroundColor('#f5f5f5')

      // 输入区域
      Row() {
        TextInput({
          placeholder: '输入你的问题...',
          text: $$this.aiInput
        })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('#ffffff')
          .borderRadius(22)
          .padding({ left: 16, right: 16 })
          .borderWidth(1)
          .borderColor('#eeeeee')

        Button('发送')
          .width(80)
          .height(44)
          .backgroundColor('#007AFF')
          .borderRadius(22)
          .margin({ left: 8 })
          .onClick(() => {
            this.sendAIMessage();
          })
          .enabled(!this.isAIChatting)
      }
      .width('100%')
      .padding(12)
      .backgroundColor('#ffffff')
      .border({
        width: { top: 1 }, // 只设上边框宽度
        color: '#888888',
        style: BorderStyle.Solid
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}