// ThemeHelper.ets - 主题初始化工具
import { ThemePreset } from './Types';
import { getTheme, getThemeColorValue } from './Theme';
import { ThemeColorKey } from './Theme';

async function syncThemePresetsFromStorage(): Promise<ThemePreset[]> {
  return [getTheme()];
}

export { syncThemePresetsFromStorage };
export type { ThemeColorKey };
export { getTheme, getThemeColorValue };
