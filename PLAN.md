# Project plan: E-Health monitoring app

Kong Vong · Final Year Project Team · IT Project Management (I5, 2026-2027 Semester 1)

Keep this file at the root of the repository (or in `docs/`) and update it every week: the weekly progress check compares it with the code. Tick a task when it is done (`- [x]`), and change the dates, the owners and the tasks when the plan changes; write why under "Changes to the plan".

## Team

| Member | Role |
|---|---|
| LOU CHUMDARARITH | Project manager |
| PHOLL CHANPHAYUK | Developer |
| SARITH SEYLA | Developer |
| SOPHEAP SOTHIPHAK | Developer |

## Milestones

| Milestone | Date |
|---|---|
| Proposal approved | 2026-12-02 |
| Design reviewed | 2026-12-09 |
| Sprint 1 review | 2026-12-23 |
| Midterm demo | 2027-01-11 |
| Sprint 3 review | 2027-01-25 |
| Release | 2027-02-08 |
| Final presentation | 2027-02-15 |

## 1. Start (weeks 1–2, 2026-11-26 to 2026-12-02)

- [ ] Kick-off: roles, repository, task board · 2026-11-26 to 2026-11-27 · LOU CHUMDARARITH, PHOLL CHANPHAYUK, SARITH SEYLA, SOPHEAP SOTHIPHAK
- [x] Requirements and user stories · 2026-11-30 to 2026-12-02 · LOU CHUMDARARITH
- [x] **Milestone: Proposal approved** · 2026-12-02

## 2. Design (weeks 2–3, 2026-12-03 to 2026-12-09)

- [ ] Architecture and data model · 2026-12-03 to 2026-12-09 · PHOLL CHANPHAYUK
- [ ] User interface mock-ups · 2026-12-03 to 2026-12-09 · SARITH SEYLA
- [ ] Test plan · 2026-12-03 to 2026-12-07 · SOPHEAP SOTHIPHAK
- [x] Skeleton, dev login, OpenAPI mock server and CI · 2026-12-03 to 2026-12-09 · LOU CHUMDARARITH
- [ ] **Milestone: Design reviewed** · 2026-12-09

## 3. Sprint 1 (weeks 3–5, 2026-12-10 to 2026-12-23)

- [ ] Sprint planning and backlog · 2026-12-10 · LOU CHUMDARARITH
- [ ] Sign-in and roles (US-01, US-02) · 2026-12-11 to 2026-12-23 · PHOLL CHANPHAYUK
- [ ] Record, edit and list readings (US-04 to US-06) · 2026-12-11 to 2026-12-23 · SARITH SEYLA
- [ ] OCR spike and glucose meter OCR (US-08) · 2026-12-11 to 2026-12-23 · SOPHEAP SOTHIPHAK
- [ ] Khmer / English set-up (US-15) · 2026-12-11 to 2026-12-23 · LOU CHUMDARARITH
- [ ] **Milestone: Sprint 1 review** · 2026-12-23

## 4. Sprint 2 (weeks 5–8, 2026-12-24 to 2027-01-11)

- [ ] Patient links (US-03) · 2026-12-24 to 2027-01-11 · PHOLL CHANPHAYUK
- [ ] Morning reminder (US-17) · 2026-12-24 to 2027-01-11 · SARITH SEYLA
- [ ] OCR for BP monitor (US-07) · 2026-12-24 to 2027-01-11 · SOPHEAP SOTHIPHAK
- [ ] Reports: max/min/average and charts (US-10, US-11) · 2026-12-24 to 2027-01-11 · LOU CHUMDARARITH
- [ ] Unit and integration tests · 2026-12-24 to 2027-01-11 · LOU CHUMDARARITH
- [ ] **Milestone: Midterm demo** · 2027-01-11

## 5. Sprint 3 (weeks 8–10, 2027-01-12 to 2027-01-25)

- [ ] Doctor dashboard (US-12) · 2027-01-12 to 2027-01-25 · PHOLL CHANPHAYUK
- [ ] Admin custom fields (US-16) · 2027-01-12 to 2027-01-25 · SARITH SEYLA
- [ ] OCR fallback and accuracy (US-09) · 2027-01-12 to 2027-01-25 · SOPHEAP SOTHIPHAK
- [ ] Patient home and family view (US-14, US-13) · 2027-01-12 to 2027-01-25 · LOU CHUMDARARITH
- [ ] Deployment of the demo (done by Jan 22) · 2027-01-18 to 2027-01-22 · LOU CHUMDARARITH
- [ ] **Milestone: Sprint 3 review** · 2027-01-25

## 6. Testing and release (weeks 10–12, 2027-01-26 to 2027-02-08)

- [ ] Acceptance tests and bug fixes · 2027-01-26 to 2027-02-08 · SOPHEAP SOTHIPHAK
- [ ] User guide · 2027-01-26 to 2027-02-01 · PHOLL CHANPHAYUK
- [ ] **Milestone: Release** · 2027-02-08

## 7. Closing (weeks 12–13, 2027-02-09 to 2027-02-15)

- [ ] Final report · 2027-02-09 to 2027-02-15 · SARITH SEYLA
- [ ] Slides and rehearsal · 2027-02-09 to 2027-02-15 · SOPHEAP SOTHIPHAK
- [ ] **Milestone: Final presentation** · 2027-02-15

## Risks

| Risk | Chance | Impact | What we do |
|---|---|---|---|
| A member is ill or leaves the team | Medium | High | Two members know each part; the code is pushed every day |
| The features take longer than planned | High | Medium | Core use cases first; the rest moves to Sprint 3 |
| The demo server or a service we use is down | Low | High | A local demo is ready too |
| OCR misreads the 7-segment screens of the BP monitor and glucose meter (target: 80% on clear photos) | Medium | High | Sprint 1 spike on 20 device photos; manual entry with the photo visible as a fallback (US-09) |
| Khmer text does not render well on Android, iOS or web | Medium | Medium | Use Noto Sans Khmer or Kantumruy Pro and test it in US-15 in Sprint 1 |
| The test devices are not available by Dec 10 | Medium | Medium | Choose the BP monitor and glucose meter models now; borrow or buy one of each |
| The demo is deployed on Jan 22, before Sprint 3 ends | Medium | Medium | Redeploy on every merge so the demo link stays current |

## Changes to the plan

| Date | Change | Why |
|---|---|---|
| 2026-11-19 | First plan | |
| 2026-11-23 | Generic sprint tasks renamed to the real features (US-01 to US-17); added Khmer / English set-up, OCR spike, Reports and Reminders and family view; demo deployment moved from Jan 26 to Feb 1 into Sprint 3, done by Jan 22 | Teacher's requirements and user stories: every member works in every sprint and the demo is ready before the Jan 25 deadline |
| 2026-11-25 | Aligned Sprint 1–3 story owners with the one-module-per-developer split (Accounts: Phayuk, Readings: Seyla, OCR: Phak, Reports & platform: Rith); ticked completed Start/Design items (Requirements & user stories; Skeleton, dev login, mock server and CI) | Match the agreed module ownership in Requirements & User Stories (T3) and reflect completed pre-kickoff platform work |
