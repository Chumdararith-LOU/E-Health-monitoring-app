# Rith's Personal Task Checklist — E-Health Monitoring App

Plain-English tracker for all remaining tasks from Kick-off (Nov 26, 2026) through Final Presentation (Feb 15, 2027).
Items marked `[x]` are already prepared and verified; items marked `[ ]` are real-world actions (meetings, school website logins, or cloud account clicks) that only you can do.

See [docs/kickoff-and-demo-kit.md](kickoff-and-demo-kit.md) for copy-paste messages, the `gicitc.com` table, WHO/ADA health ranges, and your 5-minute demo script.

---

## Phase 1: Kick-off & Admin Setup *(Nov 26 – Dec 2, 2026)*

- [x] **Confirm normal health ranges (WHO / ADA reference)** — verified and documented in `docs/kickoff-and-demo-kit.md` (consistent across website, phone app, and database).
- [x] **Prepare kick-off messages & `gicitc.com` task table** — ready to copy-paste from `docs/kickoff-and-demo-kit.md`.
- [ ] **Hold team kick-off meeting** with Phayuk, Seyla, and Phak (send the kick-off message and confirm everyone pulled `main`).
- [ ] **Update the plan on `gicitc.com`**, paste your GitHub link in the **Code** field, and click **Save baseline** on the Timeline tab *(before Dec 2)*.
- [ ] **Pick test devices** with the team — borrow or buy 1 blood pressure monitor and 1 glucose meter *(needed by Dec 10 for Phak's camera test)*.
- [ ] **Tick off Kick-off** in `PLAN.md` and on `gicitc.com`.

## Phase 2: Design Week *(Dec 3 – Dec 9, 2026)*

- [ ] **Check in on teammates' design docs:** Phayuk (system/data plan), Seyla (mock-ups), Phak (test plan).
- [ ] **Send the 2 quick questions to the lecturer** (copy-paste ready in `docs/kickoff-and-demo-kit.md`).
- [ ] **Complete Design Review** milestone *(Dec 9)*.

## Phase 3: Sprint 1 — Khmer & English Polish *(Dec 10 – Dec 23, 2026)*

- [x] **Automated Khmer/English parity & numeral checks** — all 235 web strings and 263 mobile strings verified with zero missing keys.
- [ ] **Run Sprint 1 planning** with the team and update the task board *(Dec 10)*.
- [ ] **Native Khmer wording review** — skim the Khmer medical words with a teammate and tell me any wording tweaks you want.
- [ ] **Visual check on 1 real Android phone & 1 real iPhone** — confirm Khmer text looks sharp on physical screens.
- [ ] **Check in at Sprint 1 Review** *(Dec 23)* and tick off Khmer/English as done.

## Phase 4: Sprint 2 — Reports & Midterm Demo *(Dec 24, 2026 – Jan 11, 2027)*

- [x] **End-to-end patient journey test** — verified live server + SQLite + Web portal + patient create/delete + doctor summary/series + family read-only block (`403`).
- [ ] **Integrate & check teammates' PRs** as Phayuk (real login/links), Seyla (reminders/forms), and Phak (real camera OCR) submit their work.
- [ ] **Run the Midterm Demo** with the team *(Jan 11)* using the 5-minute script in `docs/kickoff-and-demo-kit.md`.

## Phase 5: Sprint 3 — Home, Family View & Going Live *(Jan 12 – Jan 25, 2027)*

- [x] **Test Patient Home & Family View-only mode** — verified via automated mobile tests and live server checks.
- [x] **Prepare one-click cloud deployment & PDF print layout** — Docker, Render (`render.yaml`), Railway, Fly.io configs, and Khmer-safe print-to-PDF stylesheet verified.
- [x] **Build shareable Android app file (`.apk`)** — compiled release APK ready for phone testing (`mobile/build/app/outputs/flutter-apk/app-release.apk`).
- [ ] **Publish the live demo online *(by Jan 22)*** — sign in to Render (or Railway/Fly.io), connect GitHub, and verify the live URL.
- [ ] **Rebuild Android APK pointing to your live cloud URL** (tell me the URL once live and I will build the final APK for you).
- [ ] **Paste the live Demo link on `gicitc.com`** *(hard deadline: **Jan 25, 11:59 PM**)*.
- [ ] **Check in at Sprint 3 Review** *(Jan 25)*.

## Phase 6 & 7: Testing, Release & Final Presentation *(Jan 26 – Feb 15, 2027)*

- [ ] **Keep the live demo updated** as bugs get fixed during testing *(Jan 26 – Feb 8)*.
- [ ] **Review teammates' closing docs:** Phak's test checklist, Phayuk's user guide *(Release: Feb 8)*, Seyla's final report, and Phak's presentation slides *(Feb 9 – Feb 14)*.
- [ ] **Rehearse the 5-minute demo** (plus keep the offline laptop backup ready).
- [ ] **Final Presentation** *(Feb 15)*.
