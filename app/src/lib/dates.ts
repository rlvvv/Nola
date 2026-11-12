const pad = (n: number) => String(n).padStart(2, '0');

/** Local-date key, "YYYY-MM-DD". Never use UTC for day logic. */
export const toKey = (d: Date): string =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;

export const fromKey = (key: string): Date => {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(y, (m ?? 1) - 1, d ?? 1);
};

export const addDays = (d: Date, n: number): Date =>
  new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);

export const todayKey = (): string => toKey(new Date());

export const WEEKDAY_LETTERS = ['S', 'M', 'T', 'W', 'T', 'F', 'S'] as const;

export const weekdayLetter = (d: Date): string => WEEKDAY_LETTERS[d.getDay()];

/** Days between two date keys (b - a), local. */
export const daysBetween = (aKey: string, bKey: string): number => {
  const a = fromKey(aKey);
  const b = fromKey(bKey);
  const ms =
    new Date(b.getFullYear(), b.getMonth(), b.getDate()).getTime() -
    new Date(a.getFullYear(), a.getMonth(), a.getDate()).getTime();
  return Math.round(ms / 86_400_000);
};

/** Monday-first weekday index, 0..6. */
export const weekdayIndex = (d: Date): number => (d.getDay() + 6) % 7;
