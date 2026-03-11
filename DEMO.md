# SoundSync Demo Guide

## Prerequisites

- Docker + Docker Compose
- Go 1.22+
- Node.js 18+

---

## Step 1 — Start the databases and transit poller

```bash
cd ~/SoundSync
docker compose up -d --build
```

This starts four containers:

| Container | What | Port |
|---|---|---|
| `soundsync_postgres` | PostgreSQL (transit arrivals) | 5432 |
| `soundsync_mongo` | MongoDB (users, reports) | 27017 |
| `soundsync_mongo_express` | Mongo admin UI | 8081 |
| `soundsync_poller` | Transit poller — polls OBA every 60s | — |

The poller starts collecting data immediately. Verify all containers are running:

```bash
docker compose ps
```

---

## Step 2 — Start the Go backend

```bash
cd ~/SoundSync/api
go run main.go
```

You should see:

```
Loaded env from ../.env
Connected to MongoDB: soundsync
Connected to PostgreSQL: localhost/soundsync
SoundSync API listening on :8080
```

If port 8080 is already in use:

```bash
kill $(lsof -t -i:8080)
go run main.go
```

---

## Step 3 — Start the Vue web frontend

Open a new terminal:

```bash
cd ~/SoundSync/web
npm install        # first time only
npm run dev
```

Open **http://localhost:5173** in your browser.

---

## Step 4 — Demo the reliability scores

The poller only tracks 4 stops in the Bellevue area. Navigate to one of them:

| Stop ID | Location | Coordinates |
|---|---|---|
| `1_67652` | Bellevue Transit Center — Bay 9 (550 to Seattle) | 47.6155, -122.1947 |
| `1_68007` | Bellevue Transit Center — Bay 12 (550 to Bellevue) | near above |
| `1_72984` | Kelsey Creek Rd & Tye River Rd — Northbound | 47.5856, -122.1482 |
| `1_72983` | Kelsey Creek Rd & Tye River Rd — Southbound | 47.5858, -122.1484 |

1. Pan the map to **Bellevue, WA** (east of Seattle across Lake Washington)
2. Zoom in to **level 13 or higher** — white stop markers appear on the map
3. **Click a stop marker** — the sidebar shows arrivals and the reliability card
4. The reliability card shows:
   - A **0–100 score** (green ≥ 80, yellow 50–79, red < 50)
   - On-time rate % and average delay
   - Time-of-day breakdown (morning / midday / afternoon / evening)

> The reliability card only appears after the poller has run at least one cycle (~60 seconds after `docker compose up`).

---

## Reliability score formula

```
score = (on_time_rate / 100) × 50       ← 50%: arrivals within ±120s of schedule
      + max(0, 1 - std_dev / 300) × 30  ← 30%: consistency (lower variance = better)
      + max(0, 1 - |avg_delay| / 600) × 20  ← 20%: how late the bus typically runs
```

---

## Verify the API directly

```bash
# All tracked routes ranked by score
curl "http://localhost:8080/api/v1/reliability/summary"

# All routes at Kelsey Creek Rd (northbound)
curl "http://localhost:8080/api/v1/reliability/1_72984"

# Predicted delay for current time of day
curl "http://localhost:8080/api/v1/prediction/1_72984/1_102752"
```

---

## Tear down

```bash
# Stop containers, keep data volumes
docker compose down

# Stop and wipe all data (clean slate)
docker compose down -v
```
