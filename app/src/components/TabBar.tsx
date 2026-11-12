import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { router, Tabs } from 'expo-router';
import type { ComponentProps } from 'react';
import { colors, spacing, type } from '@/lib/tokens';

type TabBarProps = Parameters<
  NonNullable<ComponentProps<typeof Tabs>['tabBar']>
>[0];

const TABS = [
  { label: 'Today', href: '/', route: 'index' },
  { label: 'Chat', href: '/chat', route: 'chat' },
  { label: 'Progress', href: '/progress', route: 'progress' },
  { label: 'Look', href: '/look', route: 'look' },
] as const;

export function TabBar({ state }: TabBarProps) {
  const insets = useSafeAreaInsets();
  const activeRoute = state?.routes?.[state.index]?.name;

  return (
    <View style={[styles.bar, { paddingBottom: insets.bottom + spacing.xs }]}>
      <View style={styles.row}>
        {TABS.map((tab) => {
          const isLook = tab.route === 'look';
          const focused = !isLook && activeRoute === tab.route;
          return (
            <Pressable
              key={tab.label}
              style={styles.tab}
              onPress={() => {
                if (isLook) {
                  router.push('/look');
                } else {
                  router.push(tab.href);
                }
              }}
              accessibilityRole="tab"
              accessibilityState={{ selected: focused }}
            >
              <Text style={[styles.label, focused && styles.labelActive]}>
                {tab.label}
              </Text>
              <View style={[styles.dot, focused && styles.dotActive]} />
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    backgroundColor: colors.bg,
    paddingTop: spacing.sm,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    height: 44,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
  },
  label: {
    ...type.meta,
    color: colors.muted,
  },
  labelActive: {
    color: colors.text,
    fontWeight: '600',
  },
  dot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: 'transparent',
  },
  dotActive: {
    backgroundColor: colors.accent,
  },
});
