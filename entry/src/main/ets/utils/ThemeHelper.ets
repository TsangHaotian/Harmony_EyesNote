// ThemeHelper.ets - 主题初始化工具
import { ThemePreset } from './Types';
import { storage } from './Storage';
import { DEFAULT_THEME_ID, cloneThemePreset, cloneThemePresets, getThemeById, getThemeColorValue } from './Theme';
import { ThemeColorKey } from './Theme';

// 返回值接口
interface ThemeLoadResult {
  themePresets: ThemePreset[];
  selectedThemeId: string;
}

// 同步主题预设（从存储加载自定义主题）
async function syncThemePresetsFromStorage(): Promise<ThemePreset[]> {
  const presets = cloneThemePresets();
  const customTheme = await storage.getCustomThemePreset();
  if (customTheme) {
    presets.push(cloneThemePreset(customTheme));
  }
  return presets;
}

// 刷新主题（加载主题预设 + 读取已保存的主题偏好）
async function refreshTheme(): Promise<ThemeLoadResult> {
  const presets = await syncThemePresetsFromStorage();
  const savedThemeId = await storage.getThemePreference();
  let themeId: string;
  if (savedThemeId && presets.some((theme: ThemePreset) => theme.id === savedThemeId)) {
    themeId = savedThemeId;
  } else {
    themeId = DEFAULT_THEME_ID;
  }
  const result: ThemeLoadResult = { themePresets: presets, selectedThemeId: themeId };
  return result;
}

// 从 storage 加载主题偏好（简化版本）
async function loadThemePreference(): Promise<ThemeLoadResult> {
  const presets = cloneThemePresets();
  const savedThemeId = await storage.getThemePreference();
  let themeId: string;
  if (savedThemeId && presets.some((theme: ThemePreset) => theme.id === savedThemeId)) {
    themeId = savedThemeId;
  } else {
    themeId = DEFAULT_THEME_ID;
  }
  const result: ThemeLoadResult = { themePresets: presets, selectedThemeId: themeId };
  return result;
}

export { syncThemePresetsFromStorage, refreshTheme, loadThemePreference, ThemeLoadResult };
export type { ThemeColorKey };
export { DEFAULT_THEME_ID, getThemeById, getThemeColorValue, cloneThemePreset, cloneThemePresets };
