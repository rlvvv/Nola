import React from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { colors, motion, radius, spacing } from '@/lib/tokens';

type SheetProps = {
  children: React.ReactNode;
  onClose: () => void;
};

/** Bottom sheet surface used by modal routes. */
export function Sheet({ children, onClose }: SheetProps) {
  const insets = useSafeAreaInsets();
  return (
    <View style={styles.root}>
      <Pressable
        style={StyleSheet.absoluteFill}
        onPress={onClose}
        accessibilityLabel="Close"
        accessibilityRole="button"
      />
      <View
        style={[
          styles.sheet,
          { paddingTop: spacing.sm, paddingBottom: insets.bottom + spacing.md },
        ]}
      >
        <View style={styles.grabber} />
        {children}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.55)',
  },
  sheet: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: radius.sheet,
    borderTopRightRadius: radius.sheet,
    paddingHorizontal: spacing.lg,
    ...motion.sheetShadow,
  },
  grabber: {
    alignSelf: 'center',
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.surfaceRaised,
    marginBottom: spacing.md,
  },
});
