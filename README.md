# Harmony EyesNote

Harmony EyesNote（眨眼笔记）是一款面向 HarmonyOS NEXT 的多功能个人助理应用，集 **高效笔记**、**健康数据跟踪**、**AI 智能整理** 与 **主题美化** 于一体。它强调轻量、快捷和可视化，适合会议记录、日常待办、学习计划以及个人健康管理等多场景使用。

## ✨ 核心特性

- **笔记管理**
  - 支持当前笔记与历史笔记分区存储，自动统计字数与搜索过滤。
  - 提供会议、购物、学习等模板，允许创建自定义模板并永久保存。
  - 内置文本工具栏，可快速插入日期、时间、标题、列表等格式。

- **AI 智能整理**
  - 集成 DeepSeek Chat API，自动识别笔记类型并输出结构化结果。
  - 针对饮食/健康笔记自动切换为营养师模式，生成食材清单与建议。

- **健康中心**
  - 记录饮水、睡眠、步数、心情等指标，并可计算统计数据与趋势。
  - 预留 HarmonyOS Health Kit 接口位置（当前功能待开发）。

- **主题与个性化**
  - 预置多套主题，支持用户自定义调色板并即时预览。
  - 主题偏好与自定义颜色通过 `Preferences` 持久化，所有页面同步生效。

## 📦 环境要求

- HarmonyOS NEXT / DevEco Studio 4.1+（Beta5 或更新）
- Node.js 16+（用于 hvigor 构建工具）
- 媒体资源位于 `entry/src/main/resources/`
- 若需 AI 功能，请准备 DeepSeek API Key

## 🚀 快速开始

```bash
# 1. 克隆项目
git clone https://github.com/TsangHaotian/Harmony_EyesNote.git
cd Harmony_EyesNote

# 2. 安装依赖
ohpm install

# 3. 打包/运行（DevEco Studio hvigor）
hvigorw assembleDebug
```

也可直接在 DevEco Studio 中导入项目，选择 `entry` 模块运行到设备或模拟器。

## 📂 目录结构

```
entry/
├── src/main/ets
│   ├── entryability/EntryAbility.ets         # Ability 入口
│   ├── pages/
│   │   ├── Index.ets                         # 主页面（笔记/健康/AI）
│   │   ├── NoteEditor.ets                    # 编辑器 & AI 整理
│   │   ├── NoteDetail.ets                    # 历史笔记详情
│   │   └── Settings.ets                      # 设置页 & 主题中心
│   └── utils/
│       ├── Theme.ets                         # 主题预设与工具
│       ├── Storage.ets                       # 数据存储抽象
│       └── Types.ets                         # 共享类型定义
└── hvigorfile.ts / oh-package.json5          # 构建与依赖配置
```

## 🧪 测试

项目附带基础 UI/单元测试样例，位于：

- `entry/src/main/ohosTest/ets`（Ability 测试）
- `entry/src/main/test/ets`（本地单元测试）

使用 DevEco Studio 的测试面板或 `hvigorw test` 即可运行。

## 🛠 开发路线

- [x] AI 笔记整理与模板系统
- [x] 自定义主题编辑器
- [ ] HarmonyOS Health Kit 数据同步
- [ ] 云端备份与多设备同步