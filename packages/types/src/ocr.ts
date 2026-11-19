// Owner: Phak. Draft from the skeleton – owner reviews it by Dec 9.

import type { BuiltinFieldKey } from './readings';

export type OcrDevice = 'bp_monitor' | 'glucose_meter';

export interface OcrResult {
  device: OcrDevice;
  values: Partial<Record<BuiltinFieldKey, number>>;
  confidence: number; // 0–1
  photoUrl?: string;
}
