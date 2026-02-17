db.createCollection("users");
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ handle: 1 }, { unique: true, sparse: true });
db.users.createIndex({ "notifications.enabled": 1 });

db.createCollection("routes");
db.routes.createIndex({ id: 1 }, { unique: true });

db.createCollection("stops");
db.stops.createIndex({ id: 1 }, { unique: true });

db.createCollection("reports");
db.reports.createIndex({ routeId: 1, directionId: 1, stopId: 1, at: -1 });
db.reports.createIndex({ stopId: 1, at: -1 });
db.reports.createIndex({ userId: 1, at: -1 });
db.reports.createIndex({ type: 1, at: -1 });

print("SoundSync collections + indexes created in DB: soundsync");