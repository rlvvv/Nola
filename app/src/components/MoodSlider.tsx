import React, { useRef } from 'react';
import { PanResponder, StyleSheet, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withSpring,
} from 'react-native-reanimated';
import type { SharedValue } from 'react-native-reanimated';
import { colors, motion } from '@/lib/tokens';

const TRACK_HEIGHT = 16;
const THUMB = 28;
const WRAP_HEIGHT = 44;

type Props = {
  value: SharedValue<number>;
  onStep: (step: number) => void;
  onSnap?: () => void;
};

export function MoodSlider({ value, onStep, onSnap }: Props) {
  const trackWidth = useSharedValue(0);
  const lastStep = useRef(Math.round(value.value));
  const onStepRef = useRef(onStep);
  const onSnapRef = useRef(onSnap);
  onStepRef.current = onStep;
  onSnapRef.current = onSnap;

  const applyX = (x: number) => {
    const w = trackWidth.value;
    if (w <= 0) return;
    const t = Math.min(1, Math.max(0, x / w));
    value.value = 1 + t * 6;
    const step = Math.round(value.value);
    if (step !== lastStep.current) {
      lastStep.current = step;
      onStepRef.current(step);
    }
  };

  const snap = () => {
    const step = Math.round(value.value);
    value.value = withSpring(step, motion.spring);
    lastStep.current = step;
    onSnapRef.current?.();
  };

  const pan = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderGrant: (evt) => applyX(evt.nativeEvent.locationX),
      onPanResponderMove: (evt) => applyX(evt.nativeEvent.locationX),
      onPanResponderRelease: snap,
      onPanResponderTerminate: snap,
    }),
  ).current;

  const thumbStyle = useAnimatedStyle(() => {
    const usable = Math.max(0, trackWidth.value - THUMB);
    const t = (value.value - 1) / 6;
    return { transform: [{ translateX: t * usable }] };
  });

  return (
    <View
      style={styles.wrap}
      onLayout={(e) => {
        trackWidth.value = e.nativeEvent.layout.width;
      }}
      {...pan.panHandlers}
      accessibilityRole="adjustable"
      accessibilityLabel="Mood"
      accessibilityValue={{
        min: 1,
        max: 7,
        now: Math.round(value.value),
      }}
    >
      <View style={styles.track} />
      <Animated.View style={[styles.thumb, thumbStyle]} />
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    height: WRAP_HEIGHT,
    justifyContent: 'center',
  },
  track: {
    height: TRACK_HEIGHT,
    borderRadius: TRACK_HEIGHT / 2,
    backgroundColor: colors.surfaceRaised,
  },
  thumb: {
    position: 'absolute',
    left: 0,
    top: (WRAP_HEIGHT - THUMB) / 2,
    width: THUMB,
    height: THUMB,
    borderRadius: THUMB / 2,
    backgroundColor: colors.text,
  },
});
