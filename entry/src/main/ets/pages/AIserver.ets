
import http from '@ohos.net.http';

interface Message {
  role: string;
  content: string;
}

interface GeneratedTypeLiteralInterface_2 {
  content: string;
}

interface GeneratedTypeLiteralInterface_1 {
  message: GeneratedTypeLiteralInterface_2;
}

@Entry
@Component
struct Index {
  @State answer: string = '等待返回…';

  aboutToAppear() {
    this.testDeepSeek();
  }

  async testDeepSeek() {
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
              { role: 'system', content: 'You are a concise assistant.' } as Message,
              { role: 'user', content: '用一句话介绍鸿蒙系统。' } as Message
            ] as Message[],
            max_tokens: 60
          })
        }
      );

      if (resp.responseCode === 200) {
interface Body {
  choices: GeneratedTypeLiteralInterface_1[];
}
const body: Body = JSON.parse(resp.result.toString());
        this.answer = body.choices[0].message.content.trim();
      } else {
        this.answer = `HTTP 错误码：${resp.responseCode}`;
      }
    } catch (err) {
      this.answer = `请求异常：${JSON.stringify(err)}`;
    } finally {
      client.destroy();
    }
  }

  build() {
    Column({ space: 20 }) {
      Text('DeepSeek 调用测试')
        .fontSize(24).fontWeight(FontWeight.Bold)
      Text(this.answer)
        .fontSize(18).padding(10)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
  }
}