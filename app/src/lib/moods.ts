export const MOOD_MIN = 1;
export const MOOD_MAX = 7;

export const MOOD_WORDS = [
  'Very unpleasant',
  'Unpleasant',
  'Slightly unpleasant',
  'Neutral',
  'Slightly pleasant',
  'Pleasant',
  'Very pleasant',
] as const;

export const moodWord = (mood: number): string =>
  MOOD_WORDS[Math.min(MOOD_MAX, Math.max(MOOD_MIN, Math.round(mood))) - 1];

/** 0 at mood 1, 1 at mood 7. */
export const moodT = (mood: number): number =>
  (Math.min(MOOD_MAX, Math.max(MOOD_MIN, mood)) - MOOD_MIN) / (MOOD_MAX - MOOD_MIN);

export const SLEEP_WORDS = ['', 'Very poor', 'Poor', 'Okay', 'Good', 'Great'] as const;
