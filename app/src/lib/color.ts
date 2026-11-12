export type RGB = [number, number, number];

const HEX_CHARS = '0123456789abcdef';

const hexVal = (c: string): number => {
  "worklet";
  const i = HEX_CHARS.indexOf(c.toLowerCase());
  return i < 0 ? 0 : i;
};

export const hexToRgb = (hex: string): RGB => {
  "worklet";
  let h = hex;
  if (h[0] === '#') h = h.slice(1);
  if (h.length === 3) h = `${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}`;
  const r = hexVal(h[0]) * 16 + hexVal(h[1]);
  const g = hexVal(h[2]) * 16 + hexVal(h[3]);
  const b = hexVal(h[4]) * 16 + hexVal(h[5]);
  return [r, g, b];
};

export const mixRgb = (a: RGB, b: RGB, t: number): RGB => {
  "worklet";
  return [
    a[0] + (b[0] - a[0]) * t,
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
  ];
};

export const desaturateRgb = (c: RGB, amount: number): RGB => {
  "worklet";
  const l = 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
  return mixRgb(c, [l, l, l], amount);
};

export const rgba = (c: RGB, a: number): string => {
  "worklet";
  const r = Math.round(c[0]);
  const g = Math.round(c[1]);
  const b = Math.round(c[2]);
  return `rgba(${r},${g},${b},${Math.max(0, Math.min(1, a))})`;
};
