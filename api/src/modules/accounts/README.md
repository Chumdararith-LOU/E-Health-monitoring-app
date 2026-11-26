# Accounts module

Owner: Phayuk. Users, sign-in, roles, patient links, invite codes and doctor notes (US-01, US-02, US-03, US-12).

## Files

| File            | What                                                                           |
| --------------- | ------------------------------------------------------------------------------ |
| `schema.ts`     | Tables: `users`, `patient_links`, `invite_codes`, `doctor_notes`               |
| `routes.ts`     | `/auth/register`, `/auth/login`, `/auth/me`                                    |
| `password.ts`   | scrypt hashing (`hashPassword`, `verifyPassword`), format `scrypt$salt$hash`   |
| `rate-limit.ts` | Small per-IP limiter used on the public auth routes                            |
| `seed.ts`       | Demo users, links, invite code and notes. Safe to run twice. Password `123456` |
| `index.ts`      | Public API of the module and the access rule (`registerAccessChecker`)         |

## Auth routes

| Route                 | Auth | Limit    | What                                                               |
| --------------------- | ---- | -------- | ------------------------------------------------------------------ |
| `POST /auth/register` | none | 5 / min  | Create an account, returns `{ token, user }`. Never creates admins |
| `POST /auth/login`    | none | 10 / min | Email or phone plus password, returns `{ token, user }`            |
| `GET /auth/me`        | JWT  |          | The signed-in user                                                 |

- Tokens come only from `signToken()`.
- Email is required and stored in lowercase. Phone is optional; spaces and dashes are ignored when comparing.
- A wrong password and an unknown user both give `401 invalid_credentials`.
- `register` has a hidden `website` field (honeypot). Anything in it is a `400`.
- The limiter counts per IP in memory. Behind a proxy, set `trust proxy` in `app.ts`, or every user shares one IP.

Error keys the apps must translate: `errors.invalid_credentials`, `errors.email_taken`, `errors.phone_taken`, `errors.too_many_requests`.
