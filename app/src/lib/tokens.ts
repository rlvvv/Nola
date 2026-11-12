export const colors = {
  bg: '#0B0B0C',
  surface: '#161618',
  surfaceRaised: '#1F1F22',
  text: '#F2F1EF',
  muted: '#8A8783',
  accent: '#C8A2E8',
  accentWarm: '#E8B87A',
  danger: '#E88A8A',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

export const radius = {
  sm: 12,
  bubble: 18,
  button: 26,
  sheet: 28,
} as const;

export const type = {
  display: { fontSize: 44, fontWeight: '600', lineHeight: 50 },
  title: { fontSize: 28, fontWeight: '600', lineHeight: 34 },
  body: { fontSize: 17, fontWeight: '400', lineHeight: 24 },
  secondary: { fontSize: 15, fontWeight: '400', lineHeight: 21 },
  meta: { fontSize: 13, fontWeight: '400', lineHeight: 18 },
} as const;

export const motion = {
  micro: 180,
  sheet: 320,
  spring: { damping: 0.82, stiffness: 180 },
  sheetShadow: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.45,
    shadowRadius: 32,
    elevation: 16,
  },
} as const;

export const layout = {
  screenWidth: 375,
  screenHeight: 812,
  safeTop: 59,
  safeBottom: 34,
  margin: 24,
} as const;
