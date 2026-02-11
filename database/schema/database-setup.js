/**
 * SoundSync (minimal) MongoDB setup script
 *
 * How to run:
 * 1) Open mongosh
 * 2) Paste this whole script
 *
 * Optional:
 *   use soundsync
 */

// use soundsync;
const fs = require("fs");
const path = require("path");
print("database-setup: start");
db = db.getSiblingDB("soundsync");
print("database-setup: using database -> " + db.getName());

function parseCsvLine(line) {
    const values = [];
    let current = "";
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const ch = line[i];
        const next = line[i + 1];

        if (ch === "\"" && inQuotes && next === "\"") {
            current += "\"";
            i++;
            continue;
        }

        if (ch === "\"") {
            inQuotes = !inQuotes;
            continue;
        }

        if (ch === "," && !inQuotes) {
            values.push(current);
            current = "";
            continue;
        }

        current += ch;
    }

    values.push(current);
    return values;
}

function parseCsv(text) {
    const lines = text
        .replace(/\r\n/g, "\n")
        .split("\n")
        .filter(line => line.trim().length > 0);

    if (lines.length < 2) return [];

    const headers = parseCsvLine(lines[0]);
    const rows = [];

    for (let i = 1; i < lines.length; i++) {
        const cols = parseCsvLine(lines[i]);
        const row = {};
        for (let j = 0; j < headers.length; j++) {
            row[headers[j]] = cols[j] ?? "";
        }
        rows.push(row);
    }

    return rows;
}

function readCsvFromCandidates(candidates) {
    for (const filePath of candidates) {
        if (fs.existsSync(filePath)) {
            print("Loading CSV: " + filePath);
            return fs.readFileSync(filePath, "utf8");
        }
    }
    throw new Error("CSV not found. Tried: " + candidates.join(", "));
}

function importRoutesAndStops() {
    print("database-setup: importing routes and stops from CSV");
    const cwd = process.cwd();
    const routesCsv = readCsvFromCandidates([
        path.join(cwd, "database/public_data/routes.csv"),
        path.join(cwd, "public_data/routes.csv"),
        "/docker-entrypoint-initdb.d/public_data/routes.csv",
        "/docker-entrypoint-initdb.d/script/public_data/routes.csv"
    ]);

    const stopsCsv = readCsvFromCandidates([
        path.join(cwd, "database/public_data/stops.csv"),
        path.join(cwd, "public_data/stops.csv"),
        "/docker-entrypoint-initdb.d/public_data/stops.csv",
        "/docker-entrypoint-initdb.d/script/public_data/stops.csv"
    ]);

    const routeRows = parseCsv(routesCsv);
    const stopRows = parseCsv(stopsCsv);

    const routeOps = routeRows.map(row => ({
        updateOne: {
            filter: { routeId: String(row.route_id) },
            update: {
                $set: {
                    routeId: String(row.route_id),
                    shortName: row.route_short_name || "",
                    longName: row.route_long_name || ""
                }
            },
            upsert: true
        }
    }));

    const stopOps = stopRows.map(row => ({
        updateOne: {
            filter: { stopId: String(row.stop_id) },
            update: {
                $set: {
                    stopId: String(row.stop_id),
                    name: row.stop_name || ""
                }
            },
            upsert: true
        }
    }));

    if (routeOps.length > 0) {
        print("database-setup: writing routes collection");
        db.routes.bulkWrite(routeOps, { ordered: false });
    }
    if (stopOps.length > 0) {
        print("database-setup: writing stops collection");
        db.stops.bulkWrite(stopOps, { ordered: false });
    }

    print("Imported routes: " + routeOps.length);
    print("Imported stops: " + stopOps.length);
}

// ---------- USERS ----------
print("database-setup: creating users collection + indexes");
db.createCollection("users");

// Optional unique handle (remove if you don't want uniqueness)
db.users.createIndex({ handle: 1 }, { unique: true, sparse: true });

// Optional: quick filter for enabled notifications
db.users.createIndex({ "notifications.enabled": 1 });


// ---------- ROUTES ----------
print("database-setup: creating routes collection + indexes");
db.createCollection("routes");
db.routes.createIndex({ routeId: 1 }, { unique: true });

// ---------- STOPS ----------
print("database-setup: creating stops collection + indexes");
db.createCollection("stops");
db.stops.createIndex({ stopId: 1 }, { unique: true });
importRoutesAndStops();


// ---------- REPORT COLLECTIONS ----------
print("database-setup: creating report collections");
db.createCollection("delay_reports");
db.createCollection("crowding_reports");
db.createCollection("cleanliness_reports");

// Common indexes for fast "latest reports" queries (apply to each report collection)
const commonIndexes = [
    { keys: { routeId: 1, directionId: 1, stopId: 1, at: -1 }, options: {} },
    { keys: { stopId: 1, at: -1 }, options: {} }
];

for (const idx of commonIndexes) {
    db.delay_reports.createIndex(idx.keys, idx.options);
    db.crowding_reports.createIndex(idx.keys, idx.options);
    db.cleanliness_reports.createIndex(idx.keys, idx.options);
}
print("database-setup: created common report indexes");

// Optional: index by user activity (handy for rate limiting / history)
db.delay_reports.createIndex({ userId: 1, at: -1 });
db.crowding_reports.createIndex({ userId: 1, at: -1 });
db.cleanliness_reports.createIndex({ userId: 1, at: -1 });
print("database-setup: created user activity indexes");


// ---------- OPTIONAL TTL (auto-delete old reports) ----------
// If you want TTL, uncomment these lines AND store expireAt in each report doc:
//
// db.delay_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });
// db.crowding_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });
// db.cleanliness_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });

print("database-setup: finished");
print("SoundSync collections + indexes created in DB: soundsync");
