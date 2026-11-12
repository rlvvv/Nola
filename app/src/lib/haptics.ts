import * as Haptics from 'expo-haptics';

const safe = (fn: () => Promise<void>) => {
  try {
    fn();
  } catch {
    // Haptics are best-effort; never surface an error.
  }
};

/** Fires once per slider detent / discrete step. */
export const hapticDetent = () => safe(() => Haptics.selectionAsync());

/** Fires when a snap settles. */
export const hapticSnap = () =>
  safe(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light));

/** Fires on save. */
export const hapticSave = () =>
  safe(() => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success));

/** Fires when a commitment is marked done. */
export const hapticDone = () =>
  safe(() => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium));
