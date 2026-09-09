# OA Risk API Backend

Receives sensor windows from the ESP32 (via the phone app), scores them
with the trained model from `train_model.py`, stores sessions, and serves
trend history.

## Setup & run

```bash
cd backend
pip install -r requirements.txt
cd app
uvicorn main:app --reload --port 8000
```

Interactive API docs (Swagger UI) will be at `http://localhost:8000/docs`
once it's running — useful for demoing the API live to judges without
needing the app UI built yet.

## Test without running a server

```bash
cd backend/app
python3 test_api.py
```

This uses FastAPI's in-process TestClient (no network/port needed) and
exercises every endpoint, including error cases. Read it top to bottom —
it's also the reference for exactly how the ESP32/app side should format
requests.

## API contract

### `POST /sessions` — submit one recording window

```json
{
  "device_id": "esp32-aa11bb22",
  "gyro":  [x0,y0,z0, x1,y1,z1, ...],
  "piezo": [s0, s1, s2, ...],
  "fs_gyro": 100,
  "fs_piezo": 4000
}
```

Hardware is two sensors only: gyroscope (motion) + piezo disc (joint
sound/vibration). No accelerometer, no separate mic/EMG in this version.

- `gyro` is a **flat** list (length divisible by 3) — flat arrays are far
  simpler to build in embedded C than nested JSON arrays.
- `piezo` is a flat raw ADC waveform.
- Response includes `risk_score` (0-1), `risk_label`, and — if the trained
  model supports it — `top_contributing_features` (which features drove
  this particular score, useful for an explainable "why" in the app UI).

### `GET /trend/{device_id}` — rolling average + direction

Returns `rolling_average`, `trend_direction` (`worsening` / `stable` /
`improving` / `insufficient_data`), and the full session history. This is
the more clinically meaningful endpoint — a single session's risk_score is
noisy; the trend across sessions is the actual signal worth acting on.

### `GET /sessions/{device_id}` — full history

### `GET /health` — check the model loaded correctly

## Design notes

- **SQLite** for now (`oa_app.db`, created automatically on first run) —
  zero setup for a hackathon demo. Swap `DATABASE_URL` in `database.py` for
  Postgres later; nothing else changes since SQLAlchemy abstracts the DB.
- **Who calls this API**: most likely the phone app, not the ESP32 directly
  — ESP32 talks BLE to the phone, phone has the WiFi/data connection and
  calls this HTTP API. Structure your app-side BLE-receive code to build
  the JSON payload above and POST it here.
- **CORS is wide open** (`allow_origins=["*"]`) for demo convenience —
  tighten this before any real deployment.
- Malformed sensor windows (wrong length, garbage values) return **422**
  with a message, not a silent bad prediction — important for a health app
  where a bad reading should be visibly rejected, not scored anyway.
