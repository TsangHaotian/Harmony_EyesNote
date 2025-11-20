// 定义共享的类型接口
interface HealthData {
  waterCount: number;
  sleepHours: number;
  stepsCount: number;
  mood: string;
  lastResetDate?: string; // 上次重置日期
  waterGoal?: number; // 每日饮水目标
  sleepGoal?: number; // 每日睡眠目标
  stepsGoal?: number; // 每日步数目标
}

// 每日健康记录
interface DailyHealthRecord {
  date: string; // 日期 YYYY-MM-DD
  waterCount: number;
  sleepHours: number;
  stepsCount: number;
  mood: string;
}

// 笔记项（带分类和标签）
interface NoteItem {
  id: string; // 唯一ID
  content: string; // 笔记内容
  category?: string; // 分类
  tags?: string[]; // 标签数组
  createTime: string; // 创建时间
  updateTime: string; // 更新时间
  isFavorite?: boolean; // 是否收藏
  isPinned?: boolean; // 是否置顶
}

// 统计数据
interface StatisticsData {
  totalNotes: number; // 总笔记数
  totalWords: number; // 总字数
  avgWaterCount: number; // 平均饮水量
  avgSleepHours: number; // 平均睡眠时间
  avgStepsCount: number; // 平均步数
  healthRecordsCount: number; // 健康记录天数
  mostCommonMood: string; // 最常见心情
}

// 健康评分
interface HealthScore {
  totalScore: number; // 总分 0-100
  waterScore: number; // 饮水得分
  sleepScore: number; // 睡眠得分
  stepsScore: number; // 步数得分
  moodScore: number; // 心情得分
  suggestions: string[]; // 改进建议
}

// 周对比数据
interface WeekComparison {
  waterChange: number; // 周对比变化
  sleepChange: number;
  stepsChange: number;
}

// 健康分析
interface HealthAnalysis {
  score: HealthScore; // 健康评分
  trend: string; // 趋势：上升/下降/稳定
  weekComparison: WeekComparison;
  insights: string[]; // 洞察
  recommendations: string[]; // 推荐
}

// 成就
interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlocked: boolean;
  unlockDate?: string;
}

// 健康等级
interface HealthLevel {
  level: string;
  color: string;
  description: string;
}

// 健康报告
interface HealthReport {
  period: string; // 报告周期：week/month
  startDate: string;
  endDate: string;
  score: HealthScore;
  analysis: HealthAnalysis;
  achievements: Achievement[];
  summary: string; // 报告摘要
}

// 模板接口
interface Template {
  id: string; // 唯一标识
  name: string; // 模板名称
  icon: string; // 图标（emoji或图标名称）
  content: string; // 模板内容
  category?: string; // 分类
  description?: string; // 描述
}

interface ThemePreset {
  id: string; // 主题唯一标识
  name: string; // 展示名称
  backgroundColor: string; // 页面背景色
  cardColor: string; // 卡片/容器背景色
  textColor: string; // 主文本颜色
  accentColor: string; // 强调色（按钮/高亮）
  mutedTextColor: string; // 次级文本颜色
}

// AI对话消息接口
interface Message {
  role: string; // 'user' | 'assistant' | 'system'
  content: string; // 消息内容
}

export { HealthData, DailyHealthRecord, NoteItem, StatisticsData, HealthScore, WeekComparison, HealthAnalysis, Achievement, HealthLevel, HealthReport, Template, ThemePreset, Message };