```md
# SoundSync — Bellevue Transit Reliability App

A localized transit reliability platform built for the Bellevue, WA region.

---

## 👥 Team

- **Tony Che** — Integration Lead  
- **Abshira** — Frontend (Flutter)  
- **Wayne** — Backend (Go + MongoDB)  
- **Nolan** — Analysis / LLM Integration  

---

## Overview

SoundSync addresses public transit reliability challenges in Bellevue by:

- Providing real-time route information
- Collecting structured rider reports (delay, crowding, cleanliness)
- Generating reliability / confidence indicators
- Maintaining a versioned REST API (`/v1`)
- Supporting clean separation between frontend, backend, and database


---

## Architecture

```
        FRONTEND

   Flutter Application
   (iOS / Android)

            │ HTTPS
            ▼

         BACKEND

   Go REST API (/v1)

      • GET /v1/routes
      • GET /v1/routes/:id
      • Standardized JSON response envelope
      • Reliability scoring logic

            │
            ▼

   MongoDB

      • users
      • routes
      • stops
      • reports (unified event model)

            │
            ▼

   EXTERNAL SERVICES

   - OneBusAway API
   (Bellevue real-time transit data)

   - Sound Transit Open Transit Data (OTD)
   (Static schedules / GTFS data)

   - Power BI Government Transit Dashboard
   (Public transit analytics & metrics)

```                               

## Tech Stack

**Frontend:** Flutter (iOS / Android)  
**Backend:** Go (REST API)  
**Database:** MongoDB  
**External Data:** OneBusAway API, Sound Transit Open Transit Data, Power BI Government Transit Dashboard

---

API Design

Endpoint specifications are documented in:

docs/API_CONTRACT_v1.md

```

---

## Data Model

MongoDB collections:

* `users`
* `routes`
* `stops`
* `reports`

### Unified Report Structure

```json
{
  "userId": "...",
  "type": "delay | crowding | cleanliness",
  "routeId": "string",
  "stopId": "string",
  "directionId": 0,
  "value": number,
  "at": "Mongo Date",
  "expiresAt": "Mongo Date (optional)"
}
```

## Database Setup

See `database/README.md` for MongoDB setup instructions.
