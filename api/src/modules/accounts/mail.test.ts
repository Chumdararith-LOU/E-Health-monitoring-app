import { afterEach, describe, expect, it, vi } from 'vitest';

// Run the Resend driver: MAIL_ENABLED=true, with fetch replaced so nothing leaves the machine.
vi.mock('../../config', () => ({
  config: {
    MAIL_ENABLED: true,
    RESEND_API_KEY: 're_test_key',
    MAIL_FROM: 'E-Health <no-reply@example.com>',
    NODE_ENV: 'test',
    JWT_SECRET: 'test-secret',
  },
}));

const { sendMail, sentMail } = await import('./mail');

const mail = { to: 'someone@example.com', subject: 'Hi', text: 'Code 123456' };

afterEach(() => vi.unstubAllGlobals());

describe('sendMail with MAIL_ENABLED=true', () => {
  it('posts the message to Resend with the key and sender, and does not use the console outbox', async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response('{"id":"1"}', { status: 200 }));
    vi.stubGlobal('fetch', fetchMock);

    await sendMail(mail);

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe('https://api.resend.com/emails');
    expect(init.method).toBe('POST');
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer re_test_key');
    expect(JSON.parse(init.body as string)).toEqual({
      from: 'E-Health <no-reply@example.com>',
      to: ['someone@example.com'],
      subject: 'Hi',
      text: 'Code 123456',
    });
    expect(sentMail).toHaveLength(0);
  });

  it('turns a Resend error and a network failure into a 502 mail_failed', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => {});

    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response('nope', { status: 403 })));
    await expect(sendMail(mail)).rejects.toMatchObject({ status: 502, code: 'mail_failed' });

    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('offline')));
    await expect(sendMail(mail)).rejects.toMatchObject({ status: 502, code: 'mail_failed' });
  });
});
