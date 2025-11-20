# Harmony EyesNote

> 面向 HarmonyOS NEXT 的一体化“笔记 + 健康 + AI”工作台，让琐碎信息在眨眼之间完成整理、洞察与备份。

## 项目简介

Harmony EyesNote（眨眼笔记）在原有快速记事的基础上，引入 AI 智能整理、健康数据驾驶舱、数据统计面板与系统级备份扩展，帮助你在一个 App 内完成 **记录 → 分析 → 洞察 → 备份** 的完整闭环。适配 DevEco Studio 4.1+，支持真机与 NEXT 模拟器调试。


## 项目截图
<img width="300" height="645" alt="Screenshot_2025-11-20T174335" src="https://github.com/user-attachments/assets/407cba6d-65ce-4594-97db-78a966324e02" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174342" src="https://github.com/user-attachments/assets/9f2f6de0-f29d-469f-b776-cdb4043c8e2a" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174427" src="https://github.com/user-attachments/assets/4cc40b0e-0e0f-4c8f-acf3-07dfd7136941" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174358" src="https://github.com/user-attachments/assets/5c0b8630-aea1-4418-b474-ee2cee7a93eb" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174349" src="https://github.com/user-attachments/assets/5626a02b-9e88-4e3b-981c-1edffaf51e99" />

## 功能亮点

- **多模态笔记工作台**
  - 即时笔记/历史笔记双面板，实时字数统计、模板一键插入、快捷工具栏（日期/时间/待办/分隔线等）。
  - 自定义模板永久保存，会议、学习、购物、健康等场景随时复用。

- **DeepSeek AI 整理官**
  - `NoteEditor.ets` 内置 DeepSeek Chat 接口，自动判断笔记类型并输出结构化文本。
  - 检测到饮食/健康关键词后切换为“营养师模式”，生成三餐食材清单、营养估算与储存建议。

- **健康中心 & 记录回溯**
  - `Index.ets` 集成饮水、睡眠、步数、心情四大指标，一键记录并写入 `@ohos.data.preferences`。
  - `HealthCalculator.ets` 根据每日打卡计算健康评分、趋势和改进建议，生成可视化卡片。

- **数据统计驾驶舱**
  - `Statistics.ets` 展示笔记总览、健康均值、今日健康评分、趋势洞察与建议列表，可导出原始 JSON。
  - 支持周度对比、最常见心情、近期记录列表等多维呈现。

- **主题与个性化**
  - 预设多套主题 + 自定义调色板，`Theme.ets` 提供 clone/持久化工具，所有页面实时同步。
  - 动画化主题选择器、图标化设置页，细节体验更贴近 HarmonyOS 设计语言。

- **数据安全与备份**
  - `EntryBackupAbility.ets` 对接 HarmonyOS Backup Kit，可接入系统级备份/恢复流程。
  - 设置页提供数据导出、清空与一键跳转统计页，方便手动备份或迁移。

- **HarmonyOS 能力预留**
  - `HealthKitSync.ets` 提供 Health Kit 同步骨架（步数/睡眠/权限申请），便于后续打通华为运动健康。

## 系统结构

```
entry/
├── src/main/ets
│   ├── entryability/EntryAbility.ets          # UIAbility 入口
│   ├── entrybackupability/EntryBackupAbility  # 系统备份扩展
│   ├── pages/
│   │   ├── Index.ets                          # 主工作台（笔记+健康+AI快捷入口）
│   │   ├── NoteEditor.ets                     # 编辑器 & DeepSeek AI
│   │   ├── NoteDetail.ets                     # 历史笔记详情
│   │   ├── Settings.ets                       # 设置、数据管理、主题中心
│   │   └── Statistics.ets                     # 数据统计 & 健康洞察
│   └── utils/
│       ├── Storage.ets                        # Preferences 数据读写封装
│       ├── Theme.ets                          # 主题预设/克隆/取色
│       ├── HealthCalculator.ets               # 健康得分与建议算法
│       ├── HealthKitSync.ets                  # Health Kit 接口骨架
│       └── Types.ets                          # 公共类型声明
├── src/main/resources                         # 资源（主题、媒体、Profile）
└── hvigorfile.ts / oh-package.json5           # 构建与依赖配置
```

## 运行环境

- HarmonyOS NEXT / DevEco Studio 5.0+

## 快速上手

```bash
# 1. 克隆代码
git clone https://github.com/TsangHaotian/Harmony_EyesNote.git
cd Harmony_EyesNote
```

## 数据与备份策略

- 所有业务数据（当前笔记、历史笔记、模板、健康记录、主题偏好等）均通过 `@ohos.data.preferences` 写入本地 `noteApp` 实例，封装在 `storage` 单例中统一调用。
- `Statistics.ets`、`Settings.ets` 调用 `storage.exportAllData()` 生成结构化 JSON，方便人工备份或同步到云端。
- `EntryBackupAbility.ets` 已实现 `onBackup/onRestore` 骨架，可在真实环境中接入系统备份通道，实现无感迁移。
- `HealthKitSync.ets` 保留了权限申请、步数/睡眠同步的示例伪代码，接入 `@ohos.health` 后即可启用自动拉取。

## 测试与质量

- Ability/页面测试样例（Hypium）：`entry/src/main/ohosTest/ets`
- 本地单元测试样例：`entry/src/main/test/ets`
- 运行方式：`hvigorw test` 或 DevEco Studio 测试面板

建议在引入新的数据结构或算法时补充 `Storage.test.ets`、`List.test.ets` 等文件，保持缓存逻辑可回归。

## 开发路线

- [x] DeepSeek AI 智能整理 & 模板系统
- [x] 可视化健康中心 + 统计驾驶舱
- [x] 主题编辑器 & 自定义调色板
- [x] 数据导出 / 系统备份能力骨架
- [ ] HarmonyOS Health Kit 实机同步
- [ ] 云端备份与多设备协同
- [ ] 更丰富的图表与成就体系

## 反馈与支持

- 开发者：TsangHaotian
- 邮箱：TsangHaotian@hotmail.com
- GitHub：<https://github.com/TsangHaotian/Harmony_EyesNote>
