import React, { useMemo } from 'react';
import {
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
} from 'react-native';
import { colors, spacing, type } from '@/lib/tokens';
import { addDays, fromKey, todayKey, toKey, weekdayLetter } from '@/lib/dates';

const PILL = 44;
const GAP = 8;
const STEP = PILL + GAP;
const DAYS = 29;
const CENTER = 14;

type Props = {
  selected: string;
  onSelect: (key: string) => void;
  isLogged: (key: string) => boolean;
};

export function DateCarousel({ selected, onSelect, isLogged }: Props) {
  const { width } = useWindowDimensions();
  const today = useMemo(() => todayKey(), []);
  const days = useMemo(() => {
    const base = fromKey(today);
    return Array.from({ length: DAYS }, (_, i) => toKey(addDays(base, i - CENTER)));
  }, [today]);

  const pad = Math.max(spacing.lg, (width - PILL) / 2);

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={{ paddingHorizontal: pad, gap: GAP }}
      contentOffset={{ x: CENTER * STEP, y: 0 }}
      accessibilityRole="tablist"
    >
      {days.map((key) => {
        const d = fromKey(key);
        const logged = isLogged(key);
        const isToday = key === today;
        const isSelected = key === selected;
        return (
          <Pressable
            key={key}
            onPress={() => onSelect(key)}
            style={[
              styles.pill,
              logged && styles.pillLogged,
              isToday && styles.pillToday,
            ]}
            accessibilityRole="button"
            accessibilityLabel={`${weekdayLetter(d)} ${d.getDate()}`}
            accessibilityState={{ selected: isSelected }}
          >
            <Text style={styles.letter}>{weekdayLetter(d)}</Text>
            <Text style={[styles.number, isSelected && styles.numberSelected]}>
              {d.getDate()}
            </Text>
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  pill: {
    width: PILL,
    height: PILL,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pillLogged: {
    backgroundColor: colors.surfaceRaised,
  },
  pillToday: {
    borderWidth: 1,
    borderColor: colors.accent,
  },
  letter: {
    ...type.meta,
    fontSize: 10,
    lineHeight: 12,
    color: colors.muted,
  },
  number: {
    ...type.secondary,
    color: colors.text,
  },
  numberSelected: {
    color: colors.accent,
    fontWeight: '600',
  },
});
