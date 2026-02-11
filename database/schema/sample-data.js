/**
 * SoundSync sample data (mongosh)
 *
 * Assumes you already ran the setup script and are using DB "soundsync".
 * This inserts:
 * - 6 users
 * - 5 routes
 * - 8 stops
 * - 36 report docs (12 delay + 12 crowding + 12 cleanliness) into ONE collection: reports
 */
// Optional: clean existing sample data (comment out if you don't want to wipe)
db.users.deleteMany({});
db.routes.deleteMany({});
db.stops.deleteMany({});
db.reports.deleteMany({});

// -------------------- ROUTES --------------------
const routes = [
  { routeId: "102592", shortName: "E" }, // RapidRide E Line (example mapping)
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
// Inserts users with email + passwordHash for login flow.
// NOTE: passwordHash values are placeholders for dev sample data.
const u1 = {
  _id: new ObjectId(),
  email: "wayne+dev@example.com",
  passwordHash: "dev_hash_1",
  handle: "waynesan41dev",
  favoriteBusRoutes: ["102592", "100112"],
  notifications: { enabled: true, subscriptions: [{ routeId: "102592" }, { routeId: "100112", directionId: 0, stopId: "59540" }] }
};

const u2 = {
  _id: new ObjectId(),
  email: "wayne@example.com",
  passwordHash: "dev_hash_2",
  handle: "waynesan41",
  favoriteBusRoutes: ["100213", "100310"],
  notifications: { enabled: true, subscriptions: [{ routeId: "100213" }, { routeId: "100310", directionId: 1 }] }
};

const u3 = {
  _id: new ObjectId(),
  email: "amy@example.com",
  passwordHash: "dev_hash_3",
  handle: "rider_amy",
  favoriteBusRoutes: ["102592"],
  notifications: { enabled: true, subscriptions: [{ routeId: "102592", directionId: 0, stopId: "61012" }] }
};

const u4 = {
  _id: new ObjectId(),
  email: "ben@example.com",
  passwordHash: "dev_hash_4",
  handle: "rider_ben",
  favoriteBusRoutes: [],
  notifications: { enabled: false, subscriptions: [] }
};

const u5 = {
  _id: new ObjectId(),
  email: "chris@example.com",
  passwordHash: "dev_hash_5",
  handle: "rider_chris",
  favoriteBusRoutes: ["100112", "100501"],
  notifications: { enabled: true, subscriptions: [{ routeId: "100112" }, { routeId: "100501" }] }
};

const u6 = {
  _id: new ObjectId(),
  email: "dina@example.com",
  passwordHash: "dev_hash_6",
  handle: "rider_dina",
  favoriteBusRoutes: ["102592", "100310"],
  notifications: { enabled: true, subscriptions: [{ routeId: "102592", directionId: 1 }, { routeId: "100310", stopId: "54008" }] }
};

db.users.insertMany([u1, u2, u3, u4, u5, u6]);

// Creates timestamps around "now" so the sample reports look realistic.
const now = new Date();
function minutesAgo(m) {
  return new Date(now.getTime() - m * 60 * 1000);
}

// -------------------- REPORTS (UNIFIED) --------------------
// Inserts 36 reports into ONE collection with { type, value }.
// type: "delay" uses value = delayMin
// type: "crowding" uses value = crowding (1-5)
// type: "cleanliness" uses value = cleanliness (1-5)

db.reports.insertMany([
  // ---- DELAY (12) ----
  { userId: u1._id, type: "delay", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(8), value: 6 },
  { userId: u3._id, type: "delay", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(6), value: 9 },
  { userId: u6._id, type: "delay", routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(14), value: 4 },
  { userId: u2._id, type: "delay", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(22), value: 11 },
  { userId: u5._id, type: "delay", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(18), value: 7 },
  { userId: u1._id, type: "delay", routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(40), value: 3 },
  { userId: u4._id, type: "delay", routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(12), value: 5 },
  { userId: u2._id, type: "delay", routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(28), value: 2 },
  { userId: u5._id, type: "delay", routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(16), value: 8 },
  { userId: u6._id, type: "delay", routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(20), value: 10 },
  { userId: u3._id, type: "delay", routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(34), value: 12 },
  { userId: u1._id, type: "delay", routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(44), value: 1 },

  // ---- CROWDING (12) ----
  { userId: u3._id, type: "crowding", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(7), value: 4 },
  { userId: u1._id, type: "crowding", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(5), value: 5 },
  { userId: u6._id, type: "crowding", routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(13), value: 3 },
  { userId: u5._id, type: "crowding", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(19), value: 4 },
  { userId: u2._id, type: "crowding", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(17), value: 3 },
  { userId: u1._id, type: "crowding", routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(39), value: 2 },
  { userId: u4._id, type: "crowding", routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(11), value: 3 },
  { userId: u2._id, type: "crowding", routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(27), value: 2 },
  { userId: u6._id, type: "crowding", routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(21), value: 5 },
  { userId: u5._id, type: "crowding", routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(15), value: 4 },
  { userId: u3._id, type: "crowding", routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(33), value: 3 },
  { userId: u1._id, type: "crowding", routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(43), value: 2 },

  // ---- CLEANLINESS (12) ----
  { userId: u1._id, type: "cleanliness", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(9), value: 3 },
  { userId: u3._id, type: "cleanliness", routeId: "102592", directionId: 0, stopId: "61012", at: minutesAgo(6), value: 2 },
  { userId: u6._id, type: "cleanliness", routeId: "102592", directionId: 1, stopId: "61018", at: minutesAgo(14), value: 4 },
  { userId: u2._id, type: "cleanliness", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(23), value: 3 },
  { userId: u5._id, type: "cleanliness", routeId: "100112", directionId: 0, stopId: "59540", at: minutesAgo(18), value: 4 },
  { userId: u1._id, type: "cleanliness", routeId: "100112", directionId: 1, stopId: "59420", at: minutesAgo(41), value: 5 },
  { userId: u4._id, type: "cleanliness", routeId: "100213", directionId: 0, stopId: "53044", at: minutesAgo(12), value: 3 },
  { userId: u2._id, type: "cleanliness", routeId: "100213", directionId: 1, stopId: "59540", at: minutesAgo(29), value: 4 },
  { userId: u5._id, type: "cleanliness", routeId: "100310", directionId: 0, stopId: "54008", at: minutesAgo(16), value: 2 },
  { userId: u6._id, type: "cleanliness", routeId: "100310", directionId: 1, stopId: "54008", at: minutesAgo(20), value: 3 },
  { userId: u3._id, type: "cleanliness", routeId: "100501", directionId: 0, stopId: "55099", at: minutesAgo(35), value: 4 },
  { userId: u1._id, type: "cleanliness", routeId: "100501", directionId: 1, stopId: "55099", at: minutesAgo(45), value: 3 }
]);

print(" Inserted sample data counts:");
print("users: " + db.users.countDocuments());
print("routes: " + db.routes.countDocuments());
print("stops: " + db.stops.countDocuments());
print("reports: " + db.reports.countDocuments());

// Example: show latest reports for routeId=102592 directionId=0 stopId=61012
print("\n Latest reports for routeId=102592 directionId=0 stopId=61012:");
printjson(
  db.reports
    .find({ routeId: "102592", directionId: 0, stopId: "61012" })
    .sort({ at: -1 })
    .limit(3)
    .toArray()
);