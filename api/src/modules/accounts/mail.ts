// Sends email. Two drivers, picked by MAIL_ENABLED:
//   false → nothing is sent; the message is printed in the API console (development)
//   true  → sent with Resend (https://resend.com/docs/api-reference/emails/send-email)

import { config } from '../../config';
import { AppError } from '../../shared/errors';

export interface Mail {
  to: string;
  subject: string;
  text: string;
}

// The last messages the console driver "sent". Tests read the code from here.
export const sentMail: Mail[] = [];

export async function sendMail(mail: Mail): Promise<void> {
  if (!config.MAIL_ENABLED) {
    sentMail.push(mail);
    if (sentMail.length > 50) sentMail.shift();
    if (config.NODE_ENV !== 'test') {
      console.log(
        [
          '',
          '[mail:dev] MAIL_ENABLED=false, so nothing was sent. The message would be:',
          `  to:      ${mail.to}`,
          `  subject: ${mail.subject}`,
          ...mail.text.split('\n').map((line) => `  | ${line}`),
          '',
        ].join('\n'),
      );
    }
    return;
  }

  let res: Response;
  try {
    res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: config.MAIL_FROM,
        to: [mail.to],
        subject: mail.subject,
        text: mail.text,
      }),
      signal: AbortSignal.timeout(10_000),
    });
  } catch (cause) {
    throw new AppError(502, 'mail_failed', 'errors.mail_failed', { cause });
  }
  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    console.error(`resend rejected the email (${res.status}): ${detail}`);
    throw new AppError(502, 'mail_failed', 'errors.mail_failed');
  }
}
