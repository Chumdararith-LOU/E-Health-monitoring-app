import { accountsEn } from './modules/accounts';
import { ocrEn } from './modules/ocr';
import { readingsEn } from './modules/readings';
import { reportsEn } from './modules/reports';
import { sharedEn } from './modules/shared';

/**
 * Merged English dictionary for the web app.
 * Edit strings in your module file under `web/src/i18n/modules/` instead of here.
 */
export const en = {
  ...sharedEn,
  ...accountsEn,
  ...readingsEn,
  ...ocrEn,
  ...reportsEn,
};

export type Strings = typeof en;
export type StringKey = keyof Strings;
