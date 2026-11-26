// Email texts. The API answers with i18n keys, but an email has no app around it to translate it,
// so each email carries Khmer and English together.

import type { Mail } from './mail';

export const CODE_MINUTES = 15;

type Template = Omit<Mail, 'to'>;

export function verifyEmailTemplate(code: string): Template {
  return {
    subject: 'កូដផ្ទៀងផ្ទាត់អ៊ីមែល / Verify your email',
    text: [
      'កូដផ្ទៀងផ្ទាត់អ៊ីមែលរបស់អ្នកសម្រាប់ E-Health៖',
      '',
      code,
      '',
      `កូដនេះមានសុពលភាព ${CODE_MINUTES} នាទី។ បើអ្នកមិនបានបង្កើតគណនីទេ សូមមិនអើពើអ៊ីមែលនេះ។`,
      '',
      '---',
      'Your E-Health email verification code:',
      '',
      code,
      '',
      `It is valid for ${CODE_MINUTES} minutes. If you did not create an account, ignore this email.`,
    ].join('\n'),
  };
}

export function resetPasswordTemplate(code: string): Template {
  return {
    subject: 'កូដកំណត់ពាក្យសម្ងាត់ឡើងវិញ / Reset your password',
    text: [
      'កូដកំណត់ពាក្យសម្ងាត់ E-Health របស់អ្នកឡើងវិញ៖',
      '',
      code,
      '',
      `កូដនេះមានសុពលភាព ${CODE_MINUTES} នាទី។ បើអ្នកមិនបានស្នើសុំទេ សូមមិនអើពើអ៊ីមែលនេះ ពាក្យសម្ងាត់របស់អ្នកនៅដដែល។`,
      '',
      '---',
      'Your E-Health password reset code:',
      '',
      code,
      '',
      `It is valid for ${CODE_MINUTES} minutes. If you did not ask for it, ignore this email; your password stays the same.`,
    ].join('\n'),
  };
}
