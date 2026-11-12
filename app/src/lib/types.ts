export type Entry = {
  id: string;
  date: string; // YYYY-MM-DD, unique
  mood: number; // 1..7
  sleep: number | null; // 1..5
  note: string | null;
  createdAt: number;
  updatedAt: number;
};

export type Commitment = {
  id: string;
  entryDate: string; // the day it belongs to
  text: string;
  done: number | null; // 0 | 1 | null (not yet marked)
  edited: number; // 0 | 1
  createdAt: number;
};

export type Message = {
  id: string;
  role: 'user' | 'ai';
  text: string;
  createdAt: number;
};

export type Detection = {
  id: string;
  kind: string;
  sentence: string;
  dataPoints: number;
  createdAt: number;
};

export const newId = (): string =>
  `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
