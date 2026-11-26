# Design review checklist — UI mock-ups (T74)

**Owner:** SARITH SEYLA · **Due:** Design reviewed 2026-12-09  
**GitHub:** [#17](https://github.com/Chumdararith-LOU/E-Health-monitoring-app/issues/17) · sub [#56](https://github.com/Chumdararith-LOU/E-Health-monitoring-app/issues/56) (mobile) · [#57](https://github.com/Chumdararith-LOU/E-Health-monitoring-app/issues/57) (web)

Use this in the team walkthrough. Tick when the group agrees. Do **not** close #17 until both sections are signed.

**How to run demos**

- Mobile: `mobile/README.md` → `setup.bat` / `flutter run` (demo patient `012 345 678` / `123456`).
- Web: from repo root `pnpm --filter @ehealth/web dev` → doctor `023 900 100` / `123456`, admin `admin@ehealth.kh` / `123456`.

**Design write-ups**

- Mobile: [`mobile/docs/DESIGN.md`](../mobile/docs/DESIGN.md)
- Web: [`web/docs/DESIGN.md`](../web/docs/DESIGN.md)

---

## A. Mobile (#56)

| # | Check | Pass? | Notes |
|---|---|---|---|
| A1 | Home, Record, History, Reports, Settings readable at Large / Extra large text | | |
| A2 | Touch targets feel large enough for elderly users | | |
| A3 | **Reading entry:** type values; safe-limit error blocks Save; out-of-range only warns | | |
| A4 | **Duplicate morning:** second save before 12:00 → Replace / Keep both / Cancel | | |
| A5 | **Custom fields:** field from seed appears on form + history detail | | |
| A6 | Edit reading + delete with Undo on toast | | |
| A7 | History newest-first; 7/30/90/custom; “Only out of range” | | |
| A8 | Khmer default strings look correct on Home + form (flag wording for later) | | |

**Mobile sign-off:** _____________ (name) · date _____________

---

## B. Web (#57)

| # | Check | Pass? | Notes |
|---|---|---|---|
| B1 | Doctor dashboard answers “who needs me today?” (sort / flags / Today) | | |
| B2 | Patient page: overview stats, charts, readings tab, notes, print/PDF | | |
| B3 | Admin **Tracked fields**: add → live preview → appears for mobile form contract | | |
| B4 | Admin Readings support: edit/delete with confirm + Undo | | |
| B5 | Sidebar → phone bottom bar keeps same order | | |
| B6 | `web/docs/DESIGN.md` matches what the demo shows (no surprise flows) | | |

**Web sign-off:** _____________ (name) · date _____________

---

## C. Flows the Design issue must confirm

From [#17](https://github.com/Chumdararith-LOU/E-Health-monitoring-app/issues/17):

| Flow | Where to try | Confirmed? |
|---|---|---|
| Reading entry | Mobile Record → form; web Admin → Readings support | |
| Duplicate warning | Mobile: two morning saves same day | |
| Custom field flows | Web Admin → Fields; then mobile form / history | |

**Epic #17 closed when:** A + B signed, C all confirmed, PLAN.md Design line ticked by Seyla after merge of any review fixes.

---

## D. Follow-ups (do not block sign-off if listed)

| Item | Owner | Later sprint |
|---|---|---|
| Local morning notifications | Seyla | Sprint 2 · US-17 |
| Wire FieldsPage / readings to live API | Seyla | Sprint 1–3 |
| Real OCR (not simulated) | Phak | Sprint 1–2 |
| Normal-range medical reference lock | Team / Rith kit | Design / Sprint 1 |
