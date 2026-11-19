// Owner: Rith (shared). Every module router, mounted by app.ts under /api/v1.
import { accountsRouter } from './accounts';
import { ocrRouter } from './ocr';
import { readingsRouter } from './readings';
import { reportsRouter } from './reports';

export const moduleRouters = [accountsRouter, readingsRouter, ocrRouter, reportsRouter];
