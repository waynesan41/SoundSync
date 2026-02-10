/**
 * SoundSync sample data (mongosh)
 *
 * Assumes you already ran the setup script and are using DB "soundsync".
 * This inserts:
 * - 6 users
 * - 5 routes
 * - 8 stops
 * - 36 report docs (12 delay + 12 crowding + 12 cleanliness)
 * Total docs inserted: 6 + 5 + 8 + 36 = 55
 */

use soundsync;

// Optional: clean existing sample data (comment out if you don't want to wipe)
db.users.deleteMany({});
db.routes.deleteMany({});
db.stops.deleteMany({});
db.delay_reports.deleteMany({});
db.crowding_reports.deleteMany({});
db.cleanliness_reports.deleteMany({});

// -------------------- ROUTES --------------------
const routes = [
    { routeId: "102592", shortName: "E" },   // RapidRide E Line (example mapping)
    { routeId: "100112", shortName: "40" },
    { routeId: "100213", shortName: "8" },
    { routeId: "100310", shortName: "44" },
    { routeId: "100501", shortName: "1" }
];

db.routes.insertMany(routes);

// -------------------- STOPS --------------------
const stops = [
    { stopId: "59540", name: "3rd Ave & Pike St" },
    { stopId: "59420", name: "3rd Ave & Pine St" },
    { stopId: "61012", name: "Aurora Ave N & N 85th St" },
    { stopId: "61018", name: "Aurora Ave N & N 105th St" },
    { stopId: "52001", name: "Ballard Ave NW & NW Market St" },
    { stopId: "53044", name: "Denny Way & Westlake Ave" },
    { stopId: "54008", name: "15th Ave NW & NW 85th St" },
    { stopId: "55099", name: "Rainier Ave S & S Alaska St" }
];

db.stops.insertMany(stops);

// -------------------- USERS --------------------
const u1 = { _id: new ObjectId(), handle: "waynesan41dev", notifications: { enabled: true, subscriptions: [{ routeId: "102592" }, { routeId: "100112", directionId: 0, stopId: "59540" }] } };
const u2 = { _id: new ObjectId(), handle: "waynesan41", notifications: { enabled: true, subscriptions: [{ routeId: "100213" }, { routeId: "100310", directionId: 1 }] } };
const u3 = { _id: new ObjectId(), handle: "rider_amy", notifications: { enabled: true, subscriptions: [{ routeId: "102592", directionId: 0, stopId: "61012" }] } };
const u4 = { _id: new ObjectId(), handle: "rider_ben", notifications: { enabled: false, subscriptions: [] } };
const u5 = { _id: new ObjectId(), handle: "rider_chris", notifications: { enabled: true, subscriptions: [{ routeId: "100112" }, { routeId: "100501" }] } };
const u6 = { _id: new ObjectId(), handle: "rider_dina", notifications: { enabled: true, subscriptions: [{ routeId: "102592", directionId: 1 }, { routeId: "100310", stopId: "54008" }] } };

db.users.insertMany([u1, u2, u3, u4, u5, u6]);

// Helper: timestamps around "now" (so it looks realistic)
const now = new Date();
function minutesAgo(m) { return new Date(now.getTime() - m * 60 * 1000); }

// -------------------- DELAY REPORTS (12) --------------------
db.delay_reports.insertMany([
    { userId: u1._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(8), delayMin: 6 },
    { userId: u3._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(6), delayMin: 9 },
    { userId: u6._id, routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(14), delayMin: 4 },
    { userId: u2._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(22), delayMin: 11 },
    { userId: u5._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(18), delayMin: 7 },
    { userId: u1._id, routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(40), delayMin: 3 },
    { userId: u4._id, routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(12), delayMin: 5 },
    { userId: u2._id, routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(28), delayMin: 2 },
    { userId: u5._id, routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(16), delayMin: 8 },
    { userId: u6._id, routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(20), delayMin: 10 },
    { userId: u3._id, routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(34), delayMin: 12 },
    { userId: u1._id, routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(44), delayMin: 1 }
]);

// -------------------- CROWDING REPORTS (12) --------------------
db.crowding_reports.insertMany([
    { userId: u3._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(7), crowding: 4 },
    { userId: u1._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(5), crowding: 5 },
    { userId: u6._id, routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(13), crowding: 3 },

    { userId: u5._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(19), crowding: 4 },
    { userId: u2._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(17), crowding: 3 },
    { userId: u1._id, routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(39), crowding: 2 },

    { userId: u4._id, routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(11), crowding: 3 },
    { userId: u2._id, routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(27), crowding: 2 },

    { userId: u6._id, routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(21), crowding: 5 },
    { userId: u5._id, routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(15), crowding: 4 },

    { userId: u3._id, routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(33), crowding: 3 },
    { userId: u1._id, routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(43), crowding: 2 }
]);

// -------------------- CLEANLINESS REPORTS (12) --------------------
db.cleanliness_reports.insertMany([
    { userId: u1._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(9), cleanliness: 3 },
    { userId: u3._id, routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(6), cleanliness: 2 },
    { userId: u6._id, routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(14), cleanliness: 4 },

    { userId: u2._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(23), cleanliness: 3 },
    { userId: u5._id, routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(18), cleanliness: 4 },
    { userId: u1._id, routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(41), cleanliness: 5 },

    { userId: u4._id, routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(12), cleanliness: 3 },
    { userId: u2._id, routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(29), cleanliness: 4 },

    { userId: u5._id, routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(16), cleanliness: 2 },
    { userId: u6._id, routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(20), cleanliness: 3 },

    { userId: u3._id, routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(35), cleanliness: 4 },
    { userId: u1._id, routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(45), cleanliness: 3 }
]);

// -------------------- QUICK VERIFICATION OUTPUT --------------------
print("✅ Inserted sample data counts:");
print("users: " + db.users.countDocuments());
print("routes: " + db.routes.countDocuments());
print("stops: " + db.stops.countDocuments());
print("delay_reports: " + db.delay_reports.countDocuments());
print("crowding_reports: " + db.crowding_reports.countDocuments());
print("cleanliness_reports: " + db.cleanliness_reports.countDocuments());

// Example: show latest E-line northbound stop 61012 reports
print("\n🔎 Latest reports for routeId=102592 directionId=0 stopId=61012:");
printjson({
    delay: db.delay_reports.find({ routeId: "102592", directionId: 0, stopId: "61012" }).sort({ at: -1 }).limit(1).toArray(),
    crowding: db.crowding_reports.find({ routeId: "102592", directionId: 0, stopId: "61012" }).sort({ at: -1 }).limit(1).toArray(),
    cleanliness: db.cleanliness_reports.find({ routeId: "102592", directionId: 0, stopId: "61012" }).sort({ at: -1 }).limit(1).toArray()
});
