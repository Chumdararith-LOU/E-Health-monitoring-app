# Auth how-to

Shared code: `api/src/shared/auth.ts` (tokens, `requireAuth`, `requireRole`) and
`api/src/shared/access.ts` (`canView`, `requirePatientAccess`). Types `Role`, `ROLES` and
`AuthUser` come from `@ehealth/types`.

## 1. How tokens work

- A token is a JWT signed with HS256 and `JWT_SECRET` (from `api/.env`; a fixed dev value
  outside production). It expires after 7 days.
- It holds the user's `id` (as `sub`), `role` and `name`. Nothing else, so no secrets in it.
- Create tokens only with `signToken(user)`. Clients send them as
  `Authorization: Bearer <token>`.
- `requireAuth` checks the token and sets `req.user` (an `AuthUser`). Missing, bad or expired
  token → `401 { error: { code: 'unauthorized', messageKey: 'errors.unauthorized' } }`.
- `requireRole('admin', ...)` → `403 forbidden` when the role does not match.
- `requirePatientAccess()` → `403 forbidden` when `canView(req.user, req.params.patientId)` is
  false.

## 2. Protect a route

Every route that returns or changes patient data uses `requireAuth` + `requirePatientAccess`.
This is an **example only**, not a real route:

```ts
// api/src/modules/reports/routes.ts
import { requirePatientAccess } from '../../shared/access';
import { requireAuth, requireRole } from '../../shared/auth';

reportsRouter.get(
  '/patients/:patientId/reports',
  requireAuth, // always first: sets req.user
  requirePatientAccess(), // reads :patientId; pass another name if your param differs
  (req, res) => {
    res.json({ patientId: req.params.patientId, viewer: req.user!.id });
  },
);

// Role-only routes (no patient involved)
reportsRouter.get('/reports/admin/stats', requireAuth, requireRole('admin'), (_req, res) => {
  res.json({ ok: true });
});
```

## 3. Test login (development only)

Mounted at `/api/v1/dev` only when `DEV_LOGIN` is true (the default in development, always off
in production). Otherwise every `/api/v1/dev/*` route is a 404.

There are 5 fixed users, one per role (`api/src/shared/dev/dev-users.ts`):

| role      | name            | id                                     |
| --------- | --------------- | -------------------------------------- |
| patient   | Sok Dara        | `00000000-0000-4000-8000-000000000001` |
| caretaker | Chan Sophea     | `00000000-0000-4000-8000-000000000002` |
| family    | Sok Vanna       | `00000000-0000-4000-8000-000000000003` |
| doctor    | Dr. Keo Rathana | `00000000-0000-4000-8000-000000000004` |
| admin     | Admin           | `00000000-0000-4000-8000-000000000005` |

```sh
# List the users
curl localhost:3000/api/v1/dev/users

# Log in by role (or by id: -d '{"userId":"00000000-0000-4000-8000-000000000001"}')
curl -X POST localhost:3000/api/v1/dev/login \
  -H 'Content-Type: application/json' -d '{"role":"doctor"}'
# → { "token": "eyJ...", "user": { "id": "...", "role": "doctor", "name": "Dr. Keo Rathana" } }

# Use the token
TOKEN=eyJ...
curl localhost:3000/api/v1/dev/whoami -H "Authorization: Bearer $TOKEN"
```

A future accounts seed may create these test users in the database with the same ids, so data
seeded for them lines up with dev login.

## 4. For accounts (Phayuk): real login and the real access rule

- **Real login:** the accounts module checks the password itself, then returns
  `{ token: await signToken({ id, role, name }), user }`. Never sign tokens any other way.
- **Real access rule:** until then, `canView` uses a placeholder: a patient sees only
  themselves, every other role sees everyone. Replace it from the accounts `startup` hook in
  `api/src/modules/accounts/index.ts`; never edit `shared/access.ts`:

```ts
import { registerAccessChecker } from '../../shared/access';

export async function startup(db: Db) {
  registerAccessChecker(async (user, patientId) => {
    if (user.role === 'admin') return true;
    if (user.role === 'patient') return user.id === patientId;
    return hasLink(db, user.id, patientId); // caretaker/family/doctor: check the links table
  });
}
```
