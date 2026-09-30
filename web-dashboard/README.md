# JointSaathi — Web Dashboard

React (Vite) dashboard for the JointSaathi field OA-screening backend. Same
color theme, typography direction, and risk semantics as the Flutter mobile
app, aimed at health workers reviewing patients, screenings, and analytics
from a desktop.

## Setup

```bash
npm install
```

Create/edit `.env` (already scaffolded) to point at your running Express backend:

```
VITE_API_BASE_URL=http://localhost:5000/api/v1
```

Run the dev server:

```bash
npm run dev
```

Build for production:

```bash
npm run build   # outputs to dist/
npm run preview # serve the production build locally
```

## What's included

- **Landing page** (`/`) — public marketing page introducing JointSaathi,
  links to sign in / register.
- **Auth** (`/login`, `/register`) — health worker signup (name, phone,
  password, health center ID, location) and phone+password login. Access +
  refresh tokens are stored in `localStorage` and auto-refreshed on 401s
  (see `src/api/client.js`).
- **Dashboard** (`/dashboard/*`, protected):
  - **Overview** — stat cards, 30-day trend line, risk mix, recent screenings.
  - **Patients** — search (name/village), village + risk filters, pagination,
    add/edit/delete, jump straight into a new screening.
  - **Patient detail** — full record + screening history.
  - **Screenings** — filter by risk level and date range, paginated list.
  - **New screening** — the core flow: pick a patient, set pain/stiffness/
    swelling/injury, "capture" a gait reading, submit to the AI service and
    land on the result.
  - **Screening detail** — risk result, confidence, AI reasoning, contributing
    factors, recommendations, and a PDF report download.
  - **Analytics** — trend chart (7/30/90 day toggle), risk distribution pie
    chart, villages ranked by high-risk case count.
  - **Preventive care** — category (exercises/diet/lifestyle) and language
    (en/hi) filtered content cards.
  - **Sync** — read-only sync status (server time, last patient/screening
    update) plus a small demo panel to POST a batch payload and see the
    per-item reconciliation result, mirroring what the mobile app does when
    it reconnects after an offline camp.
  - **Profile** — the signed-in worker's own account (`/auth/me`).

## Theme

`src/theme.css` defines CSS custom properties ported 1:1 from the Flutter
app's `AppColors` (primary teal `#0D7377`, accent coral `#FF784E`, risk
colors, gray scale, hairline borders as the main depth technique instead of
heavy shadows). Typography is Manrope (display) + Inter (body/data) via
`@fontsource`.

## Notes

- CORS: the backend's `app.js` currently allows `origin: "*"`. If you lock
  that down later, make sure your dashboard's origin is in `CORS_ORIGINS`.
- The screenings list endpoint doesn't populate patient info, so the
  Screenings page resolves patient names client-side via a small per-page
  lookup/cache against `GET /patients/:id`.
