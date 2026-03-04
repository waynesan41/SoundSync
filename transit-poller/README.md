# Transit Poller

A Python service that polls the [OneBusAway Puget Sound API](https://api.pugetsound.onebusaway.org) every 60 seconds and stores real-time arrival data for a set of stops into a PostgreSQL `arrivals` table. This data feeds the SoundSync prediction model.

## How it works

`poller.py` queries each configured stop, computes the delay between the scheduled and predicted arrival times, and inserts a row into the database:

```
delay_seconds = (predictedArrivalTime - scheduledArrivalTime) / 1000
```

Both timestamps come from the OBA API in milliseconds. Only arrivals that carry a live prediction (`predictedArrivalTime != 0`) are stored.

---

## Prediction Model Formulas

The Go backend (`backend/internal/predictions/service.go`) consumes historical report data from MongoDB to produce forecasts for a given route, stop, direction, and time window.

### Time binning

Before computing statistics, reports are grouped by **time-of-day bin** and **day type** so that, for example, a morning weekday query is only compared against other morning weekday observations.

| Bin | Hours (local UTC) |
|---|---|
| `morning` | 06:00 – 08:59 |
| `midday` | 09:00 – 14:59 |
| `afternoon` | 15:00 – 17:59 |
| `evening` | 18:00 – 20:59 |
| `night` | 21:00 – 05:59 |

Day types: `weekday` (Mon–Fri) and `weekend` (Sat–Sun).

Only reports from the **last 90 days** are used.

---

### Predicted value (mean delay / crowding level)

The core prediction is the arithmetic mean of all matching historical values:

```
predicted = round( Σ values / n , 2 )
```

Where `n` is the number of matching reports (sample size). Rounding is to 2 decimal places.

---

### 90th-percentile (worst-case estimate)

Used to give riders a sense of the upper bound they might experience:

```
idx   = ceil( 90/100 × n ) − 1
p90   = sorted_values[idx]
```

This is the nearest-rank method. The result is also rounded to 2 decimal places.

---

### Confidence score

Expresses how much weight to place on the prediction based on the number of data points. Ranges from 0 (no data) to just below 1 (very large sample):

```
confidence = 1 − e^(−n / 10)
```

The divisor `10` is the scaling factor. Representative values:

| Sample size (n) | Confidence |
|---|---|
| 0 | 0.00 |
| 3 | 0.26 |
| 5 | 0.39 |
| 10 | 0.63 |
| 20 | 0.86 |
| 30 | 0.95 |

Confidence never reaches exactly 1.0, reflecting that any prediction carries residual uncertainty.

---

## Setup

Copy `.env.example` to `.env` and fill in your credentials:

```
OBA_API_KEY=your_key_here
DB_HOST=localhost
DB_PORT=5432
DB_NAME=soundsync
DB_USER=postgres
DB_PASSWORD=yourpassword
```

Install dependencies and run:

```bash
pip install requests psycopg2-binary python-dotenv
python poller.py
```
