// ThemeHelper.ets - 主题初始化工具
import { ThemePreset } from './Types';
import { DEFAULT_THEME_ID, getTheme, getThemeColorValue } from './Theme';
import { ThemeColorKey } from './Theme';

// 同步主题预设（现在使用固定配色）
async function syncThemePresetsFromStorage(): Promise<ThemePreset[]> {
  return [getTheme()];
}

// 刷新主题（简化版，仅返回固定主题）
async function refreshTheme(): Promise<{ themePresets: ThemePreset[]; selectedThemeId: string }> {
  const result = { themePresets: [getTheme()], selectedThemeId: DEFAULT_THEME_ID };
  return result;
}

// 从 storage 加载主题偏好（简化版）
async function loadThemePreference(): Promise<{ themePresets: ThemePreset[]; selectedThemeId: string }> {
  const result = { themePresets: [getTheme()], selectedThemeId: DEFAULT_THEME_ID };
  return result;
}

export { syncThemePresetsFromStorage, refreshTheme, loadThemePreference };
export type { ThemeColorKey };
export { DEFAULT_THEME_ID, getTheme, getThemeColorValue };
