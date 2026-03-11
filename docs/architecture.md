# SoundSync – High-Level Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL DATA SOURCES                                 │
├──────────────────┬─────────────────┬──────────────────┬───────────────┬─────────┤
│  Sound Transit   │  Google Maps    │  OpenWeatherMap  │  OneBusAway   │   NWS   │
│  GTFS-RT Feed    │  Directions &   │  Current Weather │  Arrivals &   │ Weather │
│  (Protobuf/S3)   │  Routes API     │  & Forecasts     │  Details API  │   API   │
└────────┬─────────┴────────┬────────┴────────┬─────────┴───────┬───────┴────┬────┘
         │                  │                 │                 │            │
         ▼                  ▼                 ▼                 ▼            ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        GO REST API  (:8080)                                     │
│                                                                                 │
│  ┌─── Middleware ───────────────────────────────────────────────────────────┐   │
│  │  JWT Auth  │  CORS  │  Request Logging                                  │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─── Handlers ─────────────────────────────────────────────────────────────┐   │
│  │  auth │ transit │ routes │ weather │ reliability │ user │ notification  │   │
│  │  vehicleReport                                                           │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─── Services (Business Logic) ────────────────────────────────────────────┐   │
│  │  Auth Service    │ Transit Service (15s cache) │ Route Service           │   │
│  │  Weather Service │ Reliability Service (ML scoring)                      │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
│  ┌─── Repositories (Data Access) ───────────────────────────────────────────┐   │
│  │  UserRepo │ FavoriteRepo │ ReportRepo │ VehicleReportRepo │ Notification │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
└────────────┬────────────────────────────────────────────────────┬───────────────┘
             │                                                    │
             ▼                                                    ▼
┌────────────────────────────┐                   ┌───────────────────────────────┐
│   MongoDB  (:27017)        │                   │   PostgreSQL  (:5432)         │
│                            │                   │                               │
│  users                     │                   │  arrivals                     │
│  favorite_routes           │                   │  (stop_id, route_id,         │
│  reports (30d TTL)         │                   │   scheduled/predicted time,  │
│  vehicle_*_reports (30d)   │                   │   delay_seconds,             │
│  notifications (7d TTL)    │                   │   recorded_at)               │
└────────────────────────────┘                   └───────────────┬───────────────┘
                                                                 ▲
                                                                 │ writes every 60s
                                                 ┌───────────────┴───────────────┐
                                                 │   Transit Poller (Python)     │
                                                 │                               │
                                                 │  OneBusAway API               │
                                                 │       → Parse arrivals        │
                                                 │       → Store to PostgreSQL   │
                                                 └───────────────────────────────┘

                        ┌── API Responses (JSON / REST) ──┐
                        │                                 │
                        ▼                                 ▼
┌──────────────────────────────┐       ┌─────────────────────────────────────┐
│   Web Client (Vue 3 + Vite)  │       │   Mobile Client (Flutter + Riverpod)│
│   (:5173 dev / :4173 prod)   │       │                                     │
│                              │       │  Providers:                         │
│  Pinia Stores:               │       │  auth │ transit │ map │ weather     │
│  auth │ map │ route          │       │                                     │
│  weather │ notifications     │       │  HTTP Client: Dio                   │
│                              │       │  Maps: Google Maps Flutter          │
│  HTTP Client: Axios          │       │  Auth: Flutter Secure Storage       │
│  Maps: Google Maps JS API    │       │  Nav: GoRouter                      │
│  Auth: localStorage (JWT)    │       │                                     │
│  Nav: Vue Router             │       │  Screens:                           │
│                              │       │  Home │ RouteDetail │ Account       │
│  Views:                      │       │  Login │ Register                   │
│  Home │ RouteDetail │ Account│       └─────────────────────────────────────┘
│  Login │ Register            │
└──────────────────────────────┘
```

---

## Component Responsibilities

| Component | Technology | Role |
|---|---|---|
| **Web Client** | Vue 3, Vite, TypeScript, Pinia | Browser-based UI — map, route planning, user account |
| **Mobile Client** | Flutter, Riverpod, Dio | iOS/Android app with equivalent feature set |
| **Go API** | Go 1.22, chi router | REST backend — auth, transit, weather, reliability, user data |
| **Transit Poller** | Python 3.11, psycopg2 | Background worker — polls OneBusAway and stores arrivals |
| **MongoDB** | v7.0 | User accounts, saved routes, crowd-sourced reports, notifications |
| **PostgreSQL** | v16 | Historical arrival data used by the reliability scoring engine |

---

## Authentication Flow

```
Client                          Go API                       MongoDB
  │                                │                             │
  ├─ POST /auth/register ─────────►│                             │
  │  { email, password, name }     │── bcrypt hash password      │
  │                                │── INSERT user ─────────────►│
  │◄─ { token, user } ────────────┤◄─ user document ────────────┤
  │                                │                             │
  ├─ POST /auth/login ────────────►│                             │
  │  { email, password }           │── FIND user ───────────────►│
  │                                │◄─ user document ────────────┤
  │                                │── bcrypt.Compare            │
  │◄─ { token, user } ────────────┤── sign JWT (72h, HS256)     │
  │                                │                             │
  ├─ GET /api/v1/users/me ────────►│                             │
  │  Authorization: Bearer <token> │── validate JWT middleware    │
  │◄─ { user profile } ───────────┤                             │
```

---

## Reliability Scoring Engine

```
PostgreSQL arrivals table
        │
        │  Query last N arrivals per stop/route
        ▼
Reliability Service (Go)
        │
        ├─ On-Time Rate  (50%)  ─── arrivals within ±120s of schedule
        ├─ Consistency   (30%)  ─── lower delay variance = higher score
        └─ Typical Delay (20%)  ─── average delay magnitude
        │
        ▼
Composite score 0–100  +  time-of-day breakdown  +  predicted delay
        │
        ▼
GET /api/v1/reliability/:stopId/:routeId
GET /api/v1/prediction/:stopId/:routeId
```

---

## Docker Compose Services

```
┌────────────────────────────────────────────────────┐
│                  soundsync_net                      │
│                                                    │
│  ┌──────────────┐  ┌────────────┐  ┌────────────┐ │
│  │  postgres:16 │  │  mongo:7.0 │  │  mongo-    │ │
│  │  :5432       │  │  :27017    │  │  express   │ │
│  │              │  │            │  │  :8081     │ │
│  └──────────────┘  └────────────┘  └────────────┘ │
│                                                    │
│  ┌──────────────────────────────────────────────┐  │
│  │  transit-poller (Python)                     │  │
│  │  polls OBA API every 60s → postgres          │  │
│  └──────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────┘

Go API & Vue/Flutter clients run outside Docker in development.
```

---

## Key Design Decisions

- **Two databases:** MongoDB for flexible document data (users, reports); PostgreSQL for structured time-series arrival data enabling reliability analytics.
- **Backend caching:** GTFS-RT vehicle positions are cached for 15 seconds to reduce load on Sound Transit's feed.
- **Stateless API:** JWT tokens carry all session state — the Go API holds no per-request session.
- **Separate poller service:** The Python transit poller is decoupled from the API so polling failures don't affect API availability.
- **TTL indexes:** Reports expire after 30 days and notifications after 7 days automatically via MongoDB TTL indexes, keeping storage bounded.
