/**
 * SoundSync sample data (mongosh)
 *
 * Assumes setup was already run and DB "soundsync" exists.
 */

// use soundsync;
print("sample-data: start");
db = db.getSiblingDB("soundsync");
print("sample-data: using database -> " + db.getName());

print("sample-data: clearing users and report collections");
db.users.deleteMany({});
db.delay_reports.deleteMany({});
db.crowding_reports.deleteMany({});
db.cleanliness_reports.deleteMany({});

print("sample-data: creating users");
const u1 = { _id: new ObjectId(), handle: "wayne_dev", notifications: { enabled: true, subscriptions: [{ routeId: "100001" }] } };
const u2 = { _id: new ObjectId(), handle: "wayne_user", notifications: { enabled: true, subscriptions: [{ routeId: "100002" }] } };
const u3 = { _id: new ObjectId(), handle: "rider_amy", notifications: { enabled: true, subscriptions: [{ routeId: "100003" }] } };
const u4 = { _id: new ObjectId(), handle: "rider_ben", notifications: { enabled: false, subscriptions: [] } };
const u5 = { _id: new ObjectId(), handle: "rider_chris", notifications: { enabled: true, subscriptions: [{ routeId: "100004" }] } };
const u6 = { _id: new ObjectId(), handle: "rider_dina", notifications: { enabled: true, subscriptions: [{ routeId: "100001" }, { routeId: "100002" }] } };
db.users.insertMany([u1, u2, u3, u4, u5, u6]);

print("sample-data: inserting delay reports");
db.delay_reports.insertMany([
    { userId: u1._id, routeId: "100001", stopId: "100", directionId: 0, vehicle_id: "veh_100001_001", report_time: new Date("2026-02-10T20:01:00Z"), delay_minutes: 3 },
    { userId: u2._id, routeId: "100002", stopId: "10005", directionId: 1, vehicle_id: "veh_100002_001", report_time: new Date("2026-02-10T20:03:00Z"), delay_minutes: 6 },
    { userId: u3._id, routeId: "100003", stopId: "10010", directionId: 0, vehicle_id: "veh_100003_001", report_time: new Date("2026-02-10T20:06:00Z"), delay_minutes: 2 },
    { userId: u4._id, routeId: "100004", stopId: "10020", directionId: 1, vehicle_id: "veh_100004_001", report_time: new Date("2026-02-10T20:09:00Z"), delay_minutes: 8 },
    { userId: u5._id, routeId: "100001", stopId: "100", directionId: 1, vehicle_id: "veh_100001_002", report_time: new Date("2026-02-10T20:12:00Z"), delay_minutes: 1 },
    { userId: u6._id, routeId: "100002", stopId: "10005", directionId: 0, vehicle_id: "veh_100002_002", report_time: new Date("2026-02-10T20:15:00Z"), delay_minutes: 5 }
]);

print("sample-data: inserting crowding reports");
db.crowding_reports.insertMany([
    { userId: u3._id, routeId: "100001", stopId: "100", directionId: 0, vehicle_id: "veh_100001_011", report_time: new Date("2026-02-10T20:02:00Z"), crowding_level: 3 },
    { userId: u1._id, routeId: "100002", stopId: "10005", directionId: 1, vehicle_id: "veh_100002_011", report_time: new Date("2026-02-10T20:04:00Z"), crowding_level: 4 },
    { userId: u6._id, routeId: "100003", stopId: "10010", directionId: 0, vehicle_id: "veh_100003_011", report_time: new Date("2026-02-10T20:07:00Z"), crowding_level: 2 },
    { userId: u5._id, routeId: "100004", stopId: "10020", directionId: 1, vehicle_id: "veh_100004_011", report_time: new Date("2026-02-10T20:10:00Z"), crowding_level: 5 },
    { userId: u2._id, routeId: "100001", stopId: "100", directionId: 1, vehicle_id: "veh_100001_012", report_time: new Date("2026-02-10T20:13:00Z"), crowding_level: 2 },
    { userId: u4._id, routeId: "100002", stopId: "10005", directionId: 0, vehicle_id: "veh_100002_012", report_time: new Date("2026-02-10T20:16:00Z"), crowding_level: 3 }
]);

print("sample-data: inserting cleanliness reports");
db.cleanliness_reports.insertMany([
    { userId: u2._id, routeId: "100001", stopId: "100", directionId: 0, vehicle_id: "veh_100001_021", report_time: new Date("2026-02-10T20:00:00Z"), cleanliness_level: 4 },
    { userId: u5._id, routeId: "100002", stopId: "10005", directionId: 1, vehicle_id: "veh_100002_021", report_time: new Date("2026-02-10T20:05:00Z"), cleanliness_level: 3 },
    { userId: u1._id, routeId: "100003", stopId: "10010", directionId: 0, vehicle_id: "veh_100003_021", report_time: new Date("2026-02-10T20:08:00Z"), cleanliness_level: 5 },
    { userId: u3._id, routeId: "100004", stopId: "10020", directionId: 1, vehicle_id: "veh_100004_021", report_time: new Date("2026-02-10T20:11:00Z"), cleanliness_level: 2 },
    { userId: u4._id, routeId: "100001", stopId: "100", directionId: 1, vehicle_id: "veh_100001_022", report_time: new Date("2026-02-10T20:14:00Z"), cleanliness_level: 4 },
    { userId: u6._id, routeId: "100002", stopId: "10005", directionId: 0, vehicle_id: "veh_100002_022", report_time: new Date("2026-02-10T20:17:00Z"), cleanliness_level: 3 }
]);

print("sample-data: counts");
print("users: " + db.users.countDocuments());
print("delay_reports: " + db.delay_reports.countDocuments());
print("crowding_reports: " + db.crowding_reports.countDocuments());
print("cleanliness_reports: " + db.cleanliness_reports.countDocuments());

print("sample-data: finished");
