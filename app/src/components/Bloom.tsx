import React from 'react';
import { Canvas, Circle, Path, vec } from '@shopify/react-native-skia';
import { usePathValue } from '@shopify/react-native-skia';
import { useDerivedValue, useSharedValue } from 'react-native-reanimated';
import type { SharedValue } from 'react-native-reanimated';
import { buildRing, moodTWorklet } from './bloomGeometry';
import { desaturateRgb, mixRgb, rgba } from '@/lib/color';
import type { RGB } from '@/lib/color';

const OUTER_LOW: RGB = [62, 47, 91];
const OUTER_HIGH: RGB = [138, 106, 58];
const MID_LOW: RGB = [90, 74, 122];
const MID_HIGH: RGB = [200, 154, 90];
const INNER_LOW: RGB = [139, 123, 184];
const INNER_HIGH: RGB = [232, 184, 122];
const CORE_LOW: RGB = [200, 162, 232];
const CORE_HIGH: RGB = [245, 217, 168];
const STROKE_LOW: RGB = [155, 138, 200];
const STROKE_HIGH: RGB = [240, 216, 168];

export type BloomProps = {
  /** 1..7, animated. */
  mood: SharedValue<number>;
  /** 0 = full colour, 1 = fully desaturated. */
  desaturated?: SharedValue<number>;
  size?: number;
};

/**
 * Parametric Skia bloom. Petal count, width, length, twist and colour are all
 * functions of the mood value, so the flower morphs as the value changes.
 */
export function Bloom({ mood, desaturated, size = 220 }: BloomProps) {
  const internalDesat = useSharedValue(0);
  const desat = desaturated ?? internalDesat;
  const R = size / 2;

  const outerPath = usePathValue((b) => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const fullness = 0.55 + 0.6 * t;
    const lenScale = 0.82 + 0.22 * t;
    const twist = (t - 0.5) * 0.5;
    buildRing(b, R, R, 12, R * 0.95 * lenScale, R * 0.26 * fullness, twist);
  });

  const midPath = usePathValue((b) => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const fullness = 0.6 + 0.55 * t;
    const lenScale = 0.85 + 0.18 * t;
    const twist = (t - 0.5) * -0.35;
    buildRing(b, R, R, 10, R * 0.64 * lenScale, R * 0.24 * fullness, twist + Math.PI / 10);
  });

  const innerPath = usePathValue((b) => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const fullness = 0.65 + 0.5 * t;
    const lenScale = 0.88 + 0.15 * t;
    const twist = (t - 0.5) * 0.2;
    buildRing(b, R, R, 8, R * 0.4 * lenScale, R * 0.22 * fullness, twist + Math.PI / 8);
  });

  const outerFill = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const d = desat.value;
    return rgba(
      desaturateRgb(mixRgb(OUTER_LOW, OUTER_HIGH, t), d * 0.85),
      0.82 * (1 - d * 0.5),
    );
  });

  const outerStroke = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const d = desat.value;
    return rgba(
      desaturateRgb(mixRgb(STROKE_LOW, STROKE_HIGH, t), d * 0.7),
      0.9 * (1 - d * 0.4),
    );
  });

  const midFill = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const d = desat.value;
    return rgba(
      desaturateRgb(mixRgb(MID_LOW, MID_HIGH, t), d * 0.85),
      0.92 * (1 - d * 0.45),
    );
  });

  const innerFill = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const d = desat.value;
    return rgba(
      desaturateRgb(mixRgb(INNER_LOW, INNER_HIGH, t), d * 0.85),
      1 * (1 - d * 0.35),
    );
  });

  const coreFill = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    const d = desat.value;
    return rgba(
      desaturateRgb(mixRgb(CORE_LOW, CORE_HIGH, t), d * 0.8),
      1 * (1 - d * 0.3),
    );
  });

  const glowColor = useDerivedValue(() => {
    "worklet";
    const t = moodTWorklet(mood.value);
    return rgba(mixRgb(CORE_LOW, CORE_HIGH, t), 1);
  });

  const glowOpacity = useDerivedValue(() => {
    "worklet";
    return 0.16 * (1 - desat.value * 0.7);
  });

  return (
    <Canvas style={{ width: size, height: size }}>
      <Circle c={vec(R, R)} r={R * 0.95} color={glowColor} opacity={glowOpacity} />
      <Path path={outerPath} color={outerFill} />
      <Path
        path={outerPath}
        color={outerStroke}
        style="stroke"
        strokeWidth={1.5}
      />
      <Path path={midPath} color={midFill} />
      <Path path={innerPath} color={innerFill} />
      <Circle c={vec(R, R)} r={R * 0.14} color={coreFill} />
    </Canvas>
  );
}
