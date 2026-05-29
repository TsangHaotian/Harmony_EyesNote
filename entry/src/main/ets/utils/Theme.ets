import { ThemePreset } from './Types';

type ThemeColorKey = 'backgroundColor' | 'cardColor' | 'textColor' | 'accentColor' | 'mutedTextColor';

const DEFAULT_THEME_ID: string = 'fresh';

// 固定配色 — 薄荷晨光，不跟随系统暗色/亮色切换
const THEME: ThemePreset = {
  id: 'fresh',
  name: '薄荷晨光',
  backgroundColor: '#F0F9F4',
  cardColor: '#FFFFFF',
  textColor: '#1E293B',
  accentColor: '#0D9488',
  mutedTextColor: '#475569'
};

function getTheme(): ThemePreset {
  return THEME;
}

function getThemeColorValue(theme: ThemePreset, key: ThemeColorKey): string {
  switch (key) {
    case 'cardColor':
      return theme.cardColor;
    case 'textColor':
      return theme.textColor;
    case 'accentColor':
      return theme.accentColor;
    case 'mutedTextColor':
      return theme.mutedTextColor;
    case 'backgroundColor':
    default:
      return theme.backgroundColor;
  }
}

export { DEFAULT_THEME_ID, ThemeColorKey, getTheme, getThemeColorValue };
