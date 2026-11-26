# Kick-off, Team Messages & Demo Walkthrough Kit (Rith)

Everything you need to copy-paste for `gicitc.com`, your teammates, your lecturer, and your Midterm / Final Demo — in plain English.

---

## 1. Task Table to Copy into `gicitc.com`

*(Update the plan on `gicitc.com` so the weekly progress check matches `PLAN.md`, then click **Save baseline** on the Timeline tab before Dec 2.)*

| Phase | Dates | Task | Owner |
|---|---|---|---|
| **1. Start** | Nov 26 – Nov 27 | Kick-off: roles, repository, task board | All 4 |
| **1. Start** | Nov 30 – Dec 2 | Requirements and user stories *(Done)* | Rith |
| **2. Design** | Dec 3 – Dec 9 | Architecture and data model | Phayuk |
| **2. Design** | Dec 3 – Dec 9 | User interface mock-ups | Seyla |
| **2. Design** | Dec 3 – Dec 7 | Test plan | Phak |
| **2. Design** | Dec 3 – Dec 9 | Skeleton, dev login, OpenAPI mock server and CI *(Done)* | Rith |
| **3. Sprint 1** | Dec 10 | Sprint planning and backlog | Rith |
| **3. Sprint 1** | Dec 11 – Dec 23 | Sign-in and roles (US-01, US-02) | Phayuk |
| **3. Sprint 1** | Dec 11 – Dec 23 | Record, edit and list readings (US-04 to US-06) | Seyla |
| **3. Sprint 1** | Dec 11 – Dec 23 | OCR spike and glucose meter OCR (US-08) | Phak |
| **3. Sprint 1** | Dec 11 – Dec 23 | Khmer / English set-up (US-15) | Rith |
| **4. Sprint 2** | Dec 24 – Jan 11 | Patient links (US-03) | Phayuk |
| **4. Sprint 2** | Dec 24 – Jan 11 | Morning reminder (US-17) | Seyla |
| **4. Sprint 2** | Dec 24 – Jan 11 | OCR for BP monitor (US-07) | Phak |
| **4. Sprint 2** | Dec 24 – Jan 11 | Reports: max/min/average and charts (US-10, US-11) | Rith |
| **4. Sprint 2** | Dec 24 – Jan 11 | Unit and integration tests | Rith |
| **5. Sprint 3** | Jan 12 – Jan 25 | Doctor dashboard (US-12) | Phayuk |
| **5. Sprint 3** | Jan 12 – Jan 25 | Admin custom fields (US-16) | Seyla |
| **5. Sprint 3** | Jan 12 – Jan 25 | OCR fallback and accuracy (US-09) | Phak |
| **5. Sprint 3** | Jan 12 – Jan 25 | Patient home and family view (US-14, US-13) | Rith |
| **5. Sprint 3** | Jan 18 – Jan 22 | Deployment of the demo (done by Jan 22) | Rith |

---

## 2. Copy-Paste Message for Your Teammates (Kick-off)

> Hi team, our proposal is approved and `main` on GitHub is now fully set up with the doctor/admin website, the Flutter mobile app, Khmer/English language files (split per module so we don't get merge conflicts), and a working test database with 90 days of sample patient readings.
>
> Please run `git pull origin main` and check `README.md` + `AGENTS.md` to see your own module folders:
> - **Phayuk:** Accounts & Doctor View (`US-01`, `US-02`, `US-03`, `US-12`)
> - **Seyla:** Readings, Reminders & Custom Fields (`US-04`–`US-06`, `US-17`, `US-16`)
> - **Phak:** Camera OCR (`US-07`, `US-08`, `US-09` + OCR spike)
> - **Rith:** Reports, Home, Family View, Khmer/English, Testing & Deployment (`US-10`, `US-11`, `US-13`, `US-14`, `US-15`)
>
> **Two quick things to decide this week:**
> 1. Which blood pressure monitor and glucose meter can we borrow/buy before Dec 10 for Phak's camera test?
> 2. Please check the Khmer wording in your screens when you run the app so we can polish any medical terms early.

---

## 3. Copy-Paste Message for Your Lecturer (2 Quick Questions)

> Dear Professor,
>
> Our team (Kong Vong — E-Health Monitoring App) is starting Design week and would like to confirm two quick points:
> 1. For our Midterm and Final Demos, should we use made-up sample patient data only (no real patient records)?
> 2. Does the January 25 edit deadline on `gicitc.com` only freeze the project description and links, or does it also freeze code updates in GitHub?
>
> Thank you very much!

---

## 4. Health Normal Ranges Reference (for Design Review & Report)

These adult morning (fasting) reference bands are used consistently across the website, phone app, and database flags:

| Measure | Normal Flag Band | Safe Input Limit (blocks typos) | Clinical Reference |
|---|---|---|---|
| **Systolic BP** | 90 – 129 mmHg | 50 – 260 mmHg | WHO / ESH guidelines (normal & high-normal < 130; hypertension ≥ 140) |
| **Diastolic BP** | 60 – 84 mmHg | 30 – 160 mmHg | WHO / ESH guidelines (normal < 85; hypertension ≥ 90) |
| **Resting Pulse** | 60 – 100 bpm | 30 – 220 bpm | WHO / AHA standard adult resting heart rate |
| **Fasting Blood Sugar** | 70 – 130 mg/dL | 20 – 600 mg/dL | WHO fasting hypoglycemia floor (70) & ADA fasting target for adults with diabetes (≤ 130 mg/dL) |

*(Values outside the **Normal Flag Band** show a warning badge for the patient and doctor; they never block saving. Values outside the **Safe Input Limit** are rejected to stop typing mistakes.)*

---

## 5. Live Demo Walkthrough Script (5 Minutes)

1. **Khmer First (`US-15`):** Open the website and phone app — point out that everything starts in **Khmer** with clean Khmer fonts, and toggle to **English** and **Khmer numerals (`១២៣`)** in Settings.
2. **Patient Home & Recording (`US-14`, `US-04`, `US-07`/`US-09`):** Sign in as Patient (*Sok Chantha*) → show "Not recorded yet today" → record a morning blood pressure & blood sugar reading (or demo camera photo + blurry fallback).
3. **Family Read-Only View (`US-13`):** Switch to Family member (*Sok Sreyleak*) → show the **View only** banner and prove there is no Record tab or Edit button.
4. **Doctor Triage & Live Reports (`US-10`, `US-11`, `US-12`, `US-18`):** On the website, sign in as *Dr. Lim Bunthoeun* → show patients needing attention sorted at the top → open *Sok Chantha* → switch between 7 / 30 / 90 days & Custom dates → switch Chart ↔ Table → click **Export PDF** to show the clean print-ready Khmer report.
5. **Admin Custom Fields (`US-16`):** Sign in as *System Admin* → add a new health field (e.g., *Temperature / សីតុណ្ហភាព*) → show it saved live to the database without any code change.

### Backup Offline Demo (if Wi-Fi is slow on presentation day)
Run `pnpm dev` on your laptop before going on stage — both the website (`http://localhost:5173`) and the database (`api/data/ehealth.db`) run 100% locally with zero internet needed.
