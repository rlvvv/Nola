import React, {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
} from 'react';
import type { Commitment, Detection, Entry, Message } from '@/lib/types';
import { newId } from '@/lib/types';

export type UpsertEntryInput = {
  date: string;
  mood: number;
  sleep: number | null;
  note: string | null;
};

type JournalContextValue = {
  entries: Entry[];
  commitments: Commitment[];
  messages: Message[];
  detections: Detection[];
  entryFor: (date: string) => Entry | undefined;
  upsertEntry: (input: UpsertEntryInput) => void;
  addCommitment: (entryDate: string, text: string) => void;
  setCommitmentDone: (id: string, done: number | null) => void;
  deleteCommitment: (id: string) => void;
};

const JournalContext = createContext<JournalContextValue | null>(null);

export function JournalProvider({ children }: { children: React.ReactNode }) {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [commitments, setCommitments] = useState<Commitment[]>([]);
  const [messages, setMessages] = useState<Message[]>([]);
  const [detections, setDetections] = useState<Detection[]>([]);

  const entryFor = useCallback(
    (date: string) => entries.find((e) => e.date === date),
    [entries],
  );

  const upsertEntry = useCallback((input: UpsertEntryInput) => {
    setEntries((prev) => {
      const now = Date.now();
      const existing = prev.find((e) => e.date === input.date);
      if (existing) {
        return prev.map((e) =>
          e.date === input.date
            ? {
                ...e,
                mood: input.mood,
                sleep: input.sleep,
                note: input.note,
                updatedAt: now,
              }
            : e,
        );
      }
      return [
        ...prev,
        {
          id: newId(),
          date: input.date,
          mood: input.mood,
          sleep: input.sleep,
          note: input.note,
          createdAt: now,
          updatedAt: now,
        },
      ];
    });
  }, []);

  const addCommitment = useCallback((entryDate: string, text: string) => {
    const trimmed = text.trim();
    if (!trimmed) return;
    setCommitments((prev) => [
      ...prev,
      {
        id: newId(),
        entryDate,
        text: trimmed,
        done: null,
        edited: 0,
        createdAt: Date.now(),
      },
    ]);
  }, []);

  const setCommitmentDone = useCallback((id: string, done: number | null) => {
    setCommitments((prev) =>
      prev.map((c) => (c.id === id ? { ...c, done } : c)),
    );
  }, []);

  const deleteCommitment = useCallback((id: string) => {
    setCommitments((prev) => prev.filter((c) => c.id !== id));
  }, []);

  const value = useMemo<JournalContextValue>(
    () => ({
      entries,
      commitments,
      messages,
      detections,
      entryFor,
      upsertEntry,
      addCommitment,
      setCommitmentDone,
      deleteCommitment,
    }),
    [
      entries,
      commitments,
      messages,
      detections,
      entryFor,
      upsertEntry,
      addCommitment,
      setCommitmentDone,
      deleteCommitment,
    ],
  );

  return (
    <JournalContext.Provider value={value}>{children}</JournalContext.Provider>
  );
}

export function useJournal(): JournalContextValue {
  const ctx = useContext(JournalContext);
  if (!ctx) throw new Error('useJournal must be used inside JournalProvider');
  return ctx;
}
