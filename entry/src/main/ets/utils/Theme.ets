import { ThemePreset } from './Types';

type ThemeColorKey = 'backgroundColor' | 'cardColor' | 'textColor' | 'accentColor' | 'mutedTextColor' | 'glassBorder';

const THEME: ThemePreset = {
  id: 'glass',
  name: '液态玻璃',
  backgroundColor: '#1a1a2e',
  cardColor: 'rgba(255, 255, 255, 0.15)',
  textColor: '#FFFFFF',
  accentColor: '#60A5FA',
  mutedTextColor: 'rgba(255, 255, 255, 0.6)'
};

function getTheme(): ThemePreset {
  return THEME;
}

function getThemeColorValue(theme: ThemePreset, key: string): string {
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
      return theme.backgroundColor;
    case 'glassBorder':
      return 'rgba(255, 255, 255, 0.25)';
    default:
      return theme.backgroundColor;
  }
}

export { ThemeColorKey, getTheme, getThemeColorValue };
