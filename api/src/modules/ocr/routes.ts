import { Router } from 'express';

export const router = Router();

router.get('/ocr/ping', (_req, res) => {
  res.json({ module: 'ocr', ok: true });
});
