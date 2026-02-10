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

use soundsync;

// ---------- USERS ----------
db.createCollection("users");

// Optional unique handle (remove if you don't want uniqueness)
db.users.createIndex({ handle: 1 }, { unique: true, sparse: true });

// Optional: quick filter for enabled notifications
db.users.createIndex({ "notifications.enabled": 1 });


// ---------- ROUTES ----------
db.createCollection("routes");
db.routes.createIndex({ routeId: 1 }, { unique: true });

// ---------- STOPS ----------
db.createCollection("stops");
db.stops.createIndex({ stopId: 1 }, { unique: true });


// ---------- REPORT COLLECTIONS ----------
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

// Optional: index by user activity (handy for rate limiting / history)
db.delay_reports.createIndex({ userId: 1, at: -1 });
db.crowding_reports.createIndex({ userId: 1, at: -1 });
db.cleanliness_reports.createIndex({ userId: 1, at: -1 });


// ---------- OPTIONAL TTL (auto-delete old reports) ----------
// If you want TTL, uncomment these lines AND store expireAt in each report doc:
//
// db.delay_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });
// db.crowding_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });
// db.cleanliness_reports.createIndex({ expireAt: 1 }, { expireAfterSeconds: 0 });

print("✅ SoundSync collections + indexes created in DB: soundsync");
