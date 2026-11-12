import type { SkPathBuilder } from '@shopify/react-native-skia';

/** 0 at mood 1, 1 at mood 7. Worklet-safe copy of moodT. */
export const moodTWorklet = (mood: number): number => {
  "worklet";
  const clamped = Math.min(7, Math.max(1, mood));
  return (clamped - 1) / 6;
};

/**
 * Adds one closed petal contour to the builder.
 * The petal starts at (cx, cy), points along `angle`, and is `len` long and
 * `width` wide at its broadest point.
 */
export const buildPetal = (
  b: SkPathBuilder,
  cx: number,
  cy: number,
  angle: number,
  len: number,
  width: number,
): void => {
  "worklet";
  const ca = Math.cos(angle);
  const sa = Math.sin(angle);
  // Perpendicular to the petal axis.
  const px = -sa;
  const py = ca;
  const tipX = cx + ca * len;
  const tipY = cy + sa * len;
  const w = width;
  b.moveTo(cx, cy);
  b.cubicTo(
    cx + ca * len * 0.28 + px * w,
    cy + sa * len * 0.28 + py * w,
    cx + ca * len * 0.7 + px * w * 0.9,
    cy + sa * len * 0.7 + py * w * 0.9,
    tipX,
    tipY,
  );
  b.cubicTo(
    cx + ca * len * 0.7 - px * w * 0.9,
    cy + sa * len * 0.7 - py * w * 0.9,
    cx + ca * len * 0.28 - px * w,
    cy + sa * len * 0.28 - py * w,
    cx,
    cy,
  );
  b.close();
};

/** Adds `count` petals arranged in a ring. */
export const buildRing = (
  b: SkPathBuilder,
  cx: number,
  cy: number,
  count: number,
  len: number,
  width: number,
  rotation: number,
): void => {
  "worklet";
  for (let i = 0; i < count; i++) {
    const a = rotation + (i / count) * Math.PI * 2;
    buildPetal(b, cx, cy, a, len, width);
  }
};
