import { HealthData, DailyHealthRecord, HealthScore, HealthAnalysis, WeekComparison, HealthLevel } from './Types';

/**
 * 健康评分计算工具类
 */
export class HealthCalculator {
  /**
   * 计算健康评分
   */
  static calculateHealthScore(healthData: HealthData, records: DailyHealthRecord[]): HealthScore {
    const waterGoal = healthData.waterGoal || 8;
    const sleepGoal = healthData.sleepGoal || 8;
    const stepsGoal = healthData.stepsGoal || 10000;

    // 饮水得分 (0-25分)
    const waterRatio = Math.min(healthData.waterCount / waterGoal, 1.2); // 允许120%超额
    const waterScore = Math.round(waterRatio * 25);

    // 睡眠得分 (0-25分)
    const sleepRatio = Math.min(healthData.sleepHours / sleepGoal, 1.2);
    const sleepScore = Math.round(sleepRatio * 25);

    // 步数得分 (0-25分)
    const stepsRatio = Math.min(healthData.stepsCount / stepsGoal, 1.2);
    const stepsScore = Math.round(stepsRatio * 25);

    // 心情得分 (0-25分)
    const moodScoreMap: Record<string, number> = {
      '开心': 25,
      '兴奋': 23,
      '平静': 20,
      '疲惫': 12,
      '焦虑': 8
    };
    const moodScore = moodScoreMap[healthData.mood] || 15;

    const totalScore = waterScore + sleepScore + stepsScore + moodScore;

    // 生成改进建议
    const suggestions: string[] = [];
    if (waterScore < 20) {
      suggestions.push(`今日饮水量不足，建议多喝水，目标${waterGoal}杯`);
    }
    if (sleepScore < 20) {
      suggestions.push(`睡眠时间不足，建议保证${sleepGoal}小时睡眠`);
    }
    if (stepsScore < 20) {
      suggestions.push(`运动量不足，建议增加步行，目标${stepsGoal}步`);
    }
    if (moodScore < 15) {
      suggestions.push('心情状态不佳，建议适当休息或进行放松活动');
    }
    if (suggestions.length === 0) {
      suggestions.push('今日健康状态良好，继续保持！');
    }

    const healthScore: HealthScore = {
      totalScore: Math.min(totalScore, 100),
      waterScore: waterScore,
      sleepScore: sleepScore,
      stepsScore: stepsScore,
      moodScore: moodScore,
      suggestions: suggestions
    };

    return healthScore;
  }

  /**
   * 计算健康分析
   */
  static calculateHealthAnalysis(
    currentData: HealthData,
    records: DailyHealthRecord[]
  ): HealthAnalysis {
    const score = HealthCalculator.calculateHealthScore(currentData, records);

    // 计算周对比
    const today = new Date().toISOString().split('T')[0];
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    
    const weekRecords = records.filter(r => r.date >= weekAgo && r.date < today);
    const todayRecord: DailyHealthRecord = {
      date: today,
      waterCount: currentData.waterCount,
      sleepHours: currentData.sleepHours,
      stepsCount: currentData.stepsCount,
      mood: currentData.mood
    };
    const currentWeekRecords: DailyHealthRecord[] = [...weekRecords, todayRecord];

    let waterChange = 0;
    let sleepChange = 0;
    let stepsChange = 0;

    if (weekRecords.length > 0) {
      const avgWater = weekRecords.reduce((sum, r) => sum + r.waterCount, 0) / weekRecords.length;
      const avgSleep = weekRecords.reduce((sum, r) => sum + r.sleepHours, 0) / weekRecords.length;
      const avgSteps = weekRecords.reduce((sum, r) => sum + r.stepsCount, 0) / weekRecords.length;

      waterChange = currentData.waterCount - avgWater;
      sleepChange = currentData.sleepHours - avgSleep;
      stepsChange = currentData.stepsCount - avgSteps;
    }

    // 判断趋势
    let trend = '稳定';
    if (score.totalScore > 80) {
      trend = '上升';
    } else if (score.totalScore < 60) {
      trend = '下降';
    }

    // 生成洞察
    const insights: string[] = [];
    if (waterChange > 0) {
      insights.push(`本周饮水量较上周平均增加${waterChange.toFixed(1)}杯`);
    } else if (waterChange < 0) {
      insights.push(`本周饮水量较上周平均减少${Math.abs(waterChange).toFixed(1)}杯`);
    }

    if (sleepChange > 0) {
      insights.push(`本周睡眠时间较上周平均增加${sleepChange.toFixed(1)}小时`);
    } else if (sleepChange < 0) {
      insights.push(`本周睡眠时间较上周平均减少${Math.abs(sleepChange).toFixed(1)}小时`);
    }

    if (stepsChange > 0) {
      insights.push(`本周步数较上周平均增加${Math.round(stepsChange)}步`);
    } else if (stepsChange < 0) {
      insights.push(`本周步数较上周平均减少${Math.round(Math.abs(stepsChange))}步`);
    }

    if (insights.length === 0) {
      insights.push('本周健康数据保持稳定');
    }

    // 生成推荐
    const recommendations: string[] = [];
    if (score.waterScore < 20) {
      recommendations.push('建议设置饮水提醒，确保每日饮水量达标');
    }
    if (score.sleepScore < 20) {
      recommendations.push('建议建立规律的作息时间，保证充足睡眠');
    }
    if (score.stepsScore < 20) {
      recommendations.push('建议增加日常活动量，如步行上下班、爬楼梯等');
    }
    if (score.moodScore < 15) {
      recommendations.push('建议进行放松活动，如冥想、听音乐、散步等');
    }

    if (recommendations.length === 0) {
      recommendations.push('继续保持当前的健康习惯');
    }

    const weekComparison: WeekComparison = {
      waterChange: waterChange,
      sleepChange: sleepChange,
      stepsChange: stepsChange
    };

    const analysis: HealthAnalysis = {
      score: score,
      trend: trend,
      weekComparison: weekComparison,
      insights: insights,
      recommendations: recommendations
    };

    return analysis;
  }

  /**
   * 获取健康等级
   */
  static getHealthLevel(score: number): HealthLevel {
    if (score >= 90) {
      const level: HealthLevel = { level: '优秀', color: '#34C759', description: '健康状态非常棒！' };
      return level;
    } else if (score >= 80) {
      const level: HealthLevel = { level: '良好', color: '#007AFF', description: '健康状态不错，继续保持！' };
      return level;
    } else if (score >= 70) {
      const level: HealthLevel = { level: '中等', color: '#FF9500', description: '健康状态一般，有改进空间' };
      return level;
    } else if (score >= 60) {
      const level: HealthLevel = { level: '需改善', color: '#FF9500', description: '健康状态需要关注' };
      return level;
    } else {
      const level: HealthLevel = { level: '较差', color: '#FF3B30', description: '健康状态需要立即改善' };
      return level;
    }
  }
}

