/**
 * SoundSync MongoDB setup script
 *
 * How to run:
 * 1) Open mongosh
 * 2) Paste this whole script
 */
// ---------- USERS ----------
// Creates the users collection for login-based accounts.
db.createCollection("users");

// Enforces unique email for login.
db.users.createIndex({ email: 1 }, { unique: true });

// Optional unique handle (remove if you don't want uniqueness).
db.users.createIndex({ handle: 1 }, { unique: true, sparse: true });

// Optional: quick filter for enabled notifications.
db.users.createIndex({ "notifications.enabled": 1 });

// ---------- ROUTES ----------
// Stores route metadata used by the UI (shortName, etc.)
db.createCollection("routes");
db.routes.createIndex({ routeId: 1 }, { unique: true });

// ---------- STOPS ----------
// Stores stop metadata used by the map/stop detail UI.
db.createCollection("stops");
db.stops.createIndex({ stopId: 1 }, { unique: true });

// ---------- REPORTS (UNIFIED) ----------
// Stores crowd intel reports: delay, crowding, cleanliness (single collection).
db.createCollection("reports");

// Fast "latest reports" lookups for a stop/route/direction.
db.reports.createIndex({ routeId: 1, directionId: 1, stopId: 1, at: -1 });
db.reports.createIndex({ stopId: 1, at: -1 });

// Useful for rate limiting / showing a user's recent activity.
db.reports.createIndex({ userId: 1, at: -1 });

// Useful for filtering by type.
db.reports.createIndex({ type: 1, at: -1 });

print("SoundSync collections + indexes created in DB: soundsync");