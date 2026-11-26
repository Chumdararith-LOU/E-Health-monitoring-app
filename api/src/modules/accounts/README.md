# Accounts module

Owner: Phayuk. Users, sign-in, roles, patient links, invite codes and doctor notes (US-01, US-02, US-03, US-12).

## Files

| File                                         | What                                                                           |
| -------------------------------------------- | ------------------------------------------------------------------------------ |
| `schema.ts`                                  | Tables: `users`, `patient_links`, `invite_codes`, `doctor_notes`               |
| `routes.ts`                                  | All `/auth/*` routes below                                                     |
| `codes.ts`                                   | 6-digit email codes: issue, check, lock (used by verify email and reset)       |
| `mail.ts`                                    | `sendMail`: console in dev (`MAIL_ENABLED=false`), Resend when true            |
| `mail-templates.ts`                          | Khmer + English email texts                                                    |
| `email-verification.ts`, `password-reset.ts` | Issue a code and email it                                                      |
| `password.ts`                                | scrypt hashing (`hashPassword`, `verifyPassword`), format `scrypt$salt$hash`   |
| `rate-limit.ts`                              | Small per-IP limiter used on the public auth routes                            |
| `seed.ts`                                    | Demo users, links, invite code and notes. Safe to run twice. Password `123456` |
| `index.ts`                                   | Public API of the module and the access rule (`registerAccessChecker`)         |

## Auth routes

| Route                             | Auth | Limit    | What                                                                 |
| --------------------------------- | ---- | -------- | -------------------------------------------------------------------- |
| `POST /auth/register`             | none | 5 / min  | Create an account, returns `{ token, user }`. Never creates admins   |
| `POST /auth/login`                | none | 10 / min | Email or phone plus password, returns `{ token, user }`              |
| `GET /auth/me`                    | JWT  |          | The signed-in user                                                   |
| `POST /auth/verify-email/send`    | JWT  | 5 / min  | Email a new verification code (register sends the first one)         |
| `POST /auth/verify-email/confirm` | JWT  | 10 / min | `{ code }`, marks the email verified, returns the user               |
| `POST /auth/password/forgot`      | none | 5 / min  | `{ email }`, always `204`, emails a reset code if the account exists |
| `POST /auth/password/reset`       | none | 10 / min | `{ email, code, newPassword }`, `204`, then sign in again            |
| `POST /auth/password/change`      | JWT  | 10 / min | `{ currentPassword, newPassword }`, `204`                            |

- Tokens come only from `signToken()`.
- Email is required and stored in lowercase. Phone is optional; spaces and dashes are ignored when comparing.
- A wrong password and an unknown user both give `401 invalid_credentials`.
- `register` has a hidden `website` field (honeypot). Anything in it is a `400`.
- The limiter counts per IP in memory. Behind a proxy, set `trust proxy` in `app.ts`, or every user shares one IP.

## Email codes

- 6 digits, valid 15 minutes, work once, locked after 5 wrong tries. A new code replaces the old one, one per minute.
- Only an HMAC of the code is stored (table `auth_codes`). Verify and reset codes are separate.
- `MAIL_ENABLED=false` (default): nothing is sent, the email is printed in the API console, so copy the code from there.
- `MAIL_ENABLED=true`: sent with Resend. `RESEND_API_KEY` and `MAIL_FROM` are then required, or the API will not start.
- `forgot` never says whether the email exists. A good reset also marks the email as verified.
- Tokens are not revoked on a password change or reset; they expire after 7 days.
- Demo users (phone only, no email) cannot use verify or reset.

Error keys the apps must translate: `errors.invalid_credentials`, `errors.email_taken`, `errors.phone_taken`, `errors.too_many_requests`, `errors.invalid_code`, `errors.code_cooldown`, `errors.already_verified`, `errors.no_email`, `errors.mail_failed`, `errors.invalid_password`.
