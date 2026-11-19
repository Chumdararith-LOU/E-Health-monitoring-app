export class AppError extends Error {
  readonly status: number;
  readonly code: string;
  readonly messageKey: string; // i18n key, translated by the apps

  constructor(status: number, code: string, messageKey: string) {
    super(code);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
    this.messageKey = messageKey;
  }
}

export const badRequest = (code = 'bad_request', messageKey = 'errors.bad_request') =>
  new AppError(400, code, messageKey);

export const unauthorized = (code = 'unauthorized', messageKey = 'errors.unauthorized') =>
  new AppError(401, code, messageKey);

export const forbidden = (code = 'forbidden', messageKey = 'errors.forbidden') =>
  new AppError(403, code, messageKey);

export const notFound = (code = 'not_found', messageKey = 'errors.not_found') =>
  new AppError(404, code, messageKey);

export function toAppError(err: unknown): AppError {
  if (err instanceof AppError) return err;
  // express.json() errors (bad JSON, body too large) carry a 4xx status
  const status = (err as { status?: unknown } | null)?.status;
  if (typeof status === 'number' && status >= 400 && status < 500) {
    return new AppError(status, 'bad_request', 'errors.bad_request');
  }
  return new AppError(500, 'internal_error', 'errors.internal_error');
}
