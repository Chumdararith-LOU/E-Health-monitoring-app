import type { Strings } from './en';
import { accountsKm } from './modules/accounts';
import { ocrKm } from './modules/ocr';
import { readingsKm } from './modules/readings';
import { reportsKm } from './modules/reports';
import { sharedKm } from './modules/shared';

/**
 * Merged Khmer dictionary for the web app (default language).
 * Edit strings in your module file under `web/src/i18n/modules/` instead of here.
 */
export const km: Strings = {
  ...sharedKm,
  ...accountsKm,
  ...readingsKm,
  ...ocrKm,
  ...reportsKm,
};
