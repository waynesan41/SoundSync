import requests
import psycopg2
import time
import os
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

API_KEY = os.getenv("OBA_API_KEY")
BASE_URL = "https://api.pugetsound.onebusaway.org/api/where"

TEST_STOPS = [    
    # Bellevue Transit Center - Route 550
    "1_67652",  # BTC Bay 9 - 550 to Seattle
    "1_68007",  # BTC Bay 12 - 550 to Bellevue

    # Kelsey Creek Rd (Bellevue College) - Routes 221, 226, 245, 271
    "1_72984",  # Northbound toward Bellevue TC
    "1_72983",  # Southbound toward Eastgate
]

def get_db():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        port=os.getenv("DB_PORT"),
        dbname=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD")
    )

def init_db():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS arrivals (
            id SERIAL PRIMARY KEY,
            stop_id TEXT,
            route_id TEXT,
            trip_id TEXT,
            headsign TEXT,
            scheduled_arrival BIGINT,
            predicted_arrival BIGINT,
            delay_seconds INTEGER,
            recorded_at TIMESTAMP DEFAULT NOW()
        )
    """)
    conn.commit()
    cur.close()
    conn.close()
    print("Database initialized.")

def fetch_arrivals(stop_id):
    url = f"{BASE_URL}/arrivals-and-departures-for-stop/{stop_id}.json"
    params = {"key": API_KEY, "minutesAfter": 60}
    response = requests.get(url, params=params)
    if response.status_code != 200:
        print(f"Error fetching stop {stop_id}: {response.status_code}")
        return []
    data = response.json()
    return data.get("data", {}).get("entry", {}).get("arrivalsAndDepartures", [])

def store_arrivals(stop_id, arrivals):
    conn = get_db()
    cur = conn.cursor()
    count = 0
    for a in arrivals:
        scheduled = a.get("scheduledArrivalTime")
        predicted = a.get("predictedArrivalTime")

        # Only store if we have both scheduled and a real prediction
        if not scheduled or not predicted or predicted == 0:
            continue

        delay_seconds = (predicted - scheduled) // 1000  # convert ms to seconds

        cur.execute("""
            INSERT INTO arrivals 
                (stop_id, route_id, trip_id, headsign, scheduled_arrival, predicted_arrival, delay_seconds)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            stop_id,
            a.get("routeId"),
            a.get("tripId"),
            a.get("tripHeadsign"),
            scheduled,
            predicted,
            delay_seconds
        ))
        count += 1

    conn.commit()
    cur.close()
    conn.close()
    return count

def run():
    init_db()
    print(f"Starting poller. Checking {len(TEST_STOPS)} stops every 60 seconds...\n")
    while True:
        timestamp = datetime.now().strftime("%H:%M:%S")
        total = 0
        for stop_id in TEST_STOPS:
            arrivals = fetch_arrivals(stop_id)
            saved = store_arrivals(stop_id, arrivals)
            total += saved
            print(f"[{timestamp}] Stop {stop_id}: {len(arrivals)} arrivals fetched, {saved} with predictions stored")
        print(f"  → Total stored this cycle: {total}\n")
        time.sleep(60)

if __name__ == "__main__":
    run()