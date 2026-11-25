# Demo Deployment Guide (Target: Jan 22, 2027)

This app ships as **one Docker container** that runs:
- **Express API + SQLite** at `/api/v1/*`
- **React Web Portal (Doctor & Admin)** at `/`

Because both live on the **same domain**, there are zero CORS errors and only one URL to paste into `gicitc.com`.

## Key Concepts (Plain English)
- **Dockerfile:** A recipe that packs Node 24, our compiled API, the built Web portal, and Drizzle SQL migrations into one portable box (container) that runs the same everywhere.
- **Persistent Volume (`/data`):** Cloud containers reset their local disk on every redeploy. Mounting a **persistent volume** at `/data` (like plugging an external hard drive into the server) ensures `ehealth.db` survives redeploys and restarts.
- **Idempotent Demo Seed (`SEED_DEMO=true`):** On first boot, the server automatically runs migrations (`api/drizzle/`) and seeds demo accounts + 90 days of readings if missing, without erasing real data added later.
- **Note on `DEV_LOGIN`:** `DEV_LOGIN` is always disabled when `NODE_ENV=production`. Until real `/auth/login` (US-01) is merged, you can preview dev-login in a staging deploy by setting `NODE_ENV=development` + a strong `JWT_SECRET` + `DEV_LOGIN=true`, then switch to `NODE_ENV=production` as soon as US-01 lands.

---

## Option 1: Render (Easiest One-Click Blueprint)
1. Push your `main` branch to GitHub.
2. Go to [dashboard.render.com](https://dashboard.render.com) → **New → Blueprint** → select `E-Health-monitoring-app`.
3. Render automatically reads [render.yaml](../render.yaml), creates the Docker web service + 1 GB `/data` disk in **Singapore**, generates `JWT_SECRET`, and deploys!
4. Verify `https://<your-app>.onrender.com/api/v1/health` returns `{"ok":true,"db":"ok"}`, and open `https://<your-app>.onrender.com/` for the Web Portal.

## Option 2: Railway
1. Go to [railway.app](https://railway.app) → **New Project → Deploy from GitHub repo** (`railway.toml` is detected automatically).
2. In the service → **Volumes** → **Add Volume** mounted at `/data`.
3. Under **Variables**, set:
   - `NODE_ENV=production`
   - `DB_FILE=/data/ehealth.db`
   - `WEB_DIST_DIR=/app/web/dist`
   - `SEED_DEMO=true`
   - `JWT_SECRET=<random 32+ char hex string>`
4. Click **Settings → Networking → Generate Domain** and test `/api/v1/health`.

## Option 3: Fly.io (Singapore region)
```zsh
brew install flyctl
fly auth login
fly apps create ehealth-monitoring-app
fly volumes create ehealth_data --region sin --size 1
fly secrets set JWT_SECRET="$(openssl rand -hex 32)"
fly deploy
```

## Option 4: Test the Production Container Locally with Docker
```zsh
docker build -t ehealth-app .
docker run --rm -p 3000:3000 \
  -v ehealth_data:/data \
  -e JWT_SECRET="local-test-secret-change-me" \
  -e SEED_DEMO=true \
  ehealth-app
```
Then open:
- Web portal: `http://localhost:3000`
- Health check: `http://localhost:3000/api/v1/health`

## Mobile App (Android APK pointing to your Deployed Demo)
Build a shareable APK for teammates and the teacher pointing directly at your live server:
```zsh
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://<your-deployed-domain>/api/v1
```
Share `mobile/build/app/outputs/flutter-apk/app-release.apk`.
