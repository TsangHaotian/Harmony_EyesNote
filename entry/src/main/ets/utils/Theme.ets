import { ThemePreset } from './Types';

type ThemeColorKey = 'backgroundColor' | 'cardColor' | 'textColor' | 'accentColor' | 'mutedTextColor';

const DEFAULT_THEME_ID: string = 'fresh';
const CUSTOM_THEME_ID: string = 'custom';

function cloneThemePreset(preset: ThemePreset): ThemePreset {
  const clonedPreset: ThemePreset = {
    id: preset.id,
    name: preset.name,
    backgroundColor: preset.backgroundColor,
    cardColor: preset.cardColor,
    textColor: preset.textColor,
    accentColor: preset.accentColor,
    mutedTextColor: preset.mutedTextColor
  };
  return clonedPreset;
}

function createDefaultCustomTheme(): ThemePreset {
  const customTheme: ThemePreset = {
    id: CUSTOM_THEME_ID,
    name: '自定义主题',
    backgroundColor: '#F8FAFC',
    cardColor: '#FFFFFF',
    textColor: '#0F172A',
    accentColor: '#2563EB',
    mutedTextColor: '#64748B'
  };
  return customTheme;
}

const THEME_PRESETS: ThemePreset[] = [
  {
    id: 'fresh',
    name: '薄荷晨光',
    backgroundColor: '#F4FFFB',
    cardColor: '#FFFFFF',
    textColor: '#0F172A',
    accentColor: '#0FAF97',
    mutedTextColor: '#6B7280'
  },
  {
    id: 'sunset',
    name: '暮光暖阳',
    backgroundColor: '#FFF8F1',
    cardColor: '#FFFFFF',
    textColor: '#3C1F0F',
    accentColor: '#FF7A00',
    mutedTextColor: '#A16207'
  },
  {
    id: 'lavender',
    name: '薰衣草夜',
    backgroundColor: '#F7F5FF',
    cardColor: '#FFFFFF',
    textColor: '#1F1D2B',
    accentColor: '#7C3AED',
    mutedTextColor: '#6B7280'
  },
  {
    id: 'midnight',
    name: '深空蓝',
    backgroundColor: '#ff133353',
    cardColor: '#ff000000',
    textColor: '#F8FAFC',
    accentColor: '#38BDF8',
    mutedTextColor: '#94A3B8'
  }
];

const FALLBACK_THEME: ThemePreset = {
  id: 'default',
  name: '默认',
  backgroundColor: '#FFFFFF',
  cardColor: '#FFFFFF',
  textColor: '#000000',
  accentColor: '#007AFF',
  mutedTextColor: '#8E8E93'
};

function cloneThemePresets(): ThemePreset[] {
  return THEME_PRESETS.map((preset: ThemePreset) => cloneThemePreset(preset));
}

function getThemeById(themeId?: string, presets?: ThemePreset[]): ThemePreset {
  const availablePresets = presets && presets.length > 0 ? presets : THEME_PRESETS;
  if (themeId) {
    const matched = availablePresets.find((theme: ThemePreset) => theme.id === themeId);
    if (matched) {
      return matched;
    }
  }
  if (availablePresets.length > 0) {
    return availablePresets[0];
  }
  return FALLBACK_THEME;
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

export { DEFAULT_THEME_ID, CUSTOM_THEME_ID, THEME_PRESETS, FALLBACK_THEME, ThemeColorKey, cloneThemePreset, cloneThemePresets, createDefaultCustomTheme, getThemeById, getThemeColorValue };

