/**
 * SoundSync schema + test data setup (mongosh)
 *
 * Assumes replica setup was already run and DB "soundsync" exists.
 */

const fs = require("fs");
const path = require("path");

print("shcema-data-setup: start");
db = db.getSiblingDB("soundsync");
print("shcema-data-setup: dropping existing database -> " + db.getName());
db.dropDatabase();
db = db.getSiblingDB("soundsync");
print("shcema-data-setup: using database -> " + db.getName());

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
    print("shcema-data-setup: importing routes and stops from CSV");
    const cwd = process.cwd();
    const routesCsv = readCsvFromCandidates([
        path.join(cwd, "database/schema/test-data/routes.csv"),
        path.join(cwd, "schema/test-data/routes.csv"),
        path.join(cwd, "database/public_data/routes.csv"),
        path.join(cwd, "public_data/routes.csv"),
        "/docker-entrypoint-initdb.d/script/test-data/routes.csv",
        "/docker-entrypoint-initdb.d/public_data/routes.csv",
        "/docker-entrypoint-initdb.d/script/public_data/routes.csv"
    ]);

    const stopsCsv = readCsvFromCandidates([
        path.join(cwd, "database/schema/test-data/stops.csv"),
        path.join(cwd, "schema/test-data/stops.csv"),
        path.join(cwd, "database/public_data/stops.csv"),
        path.join(cwd, "public_data/stops.csv"),
        "/docker-entrypoint-initdb.d/script/test-data/stops.csv",
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
        print("shcema-data-setup: writing routes collection");
        db.routes.bulkWrite(routeOps, { ordered: false });
    }
    if (stopOps.length > 0) {
        print("shcema-data-setup: writing stops collection");
        db.stops.bulkWrite(stopOps, { ordered: false });
    }

    print("Imported routes: " + routeOps.length);
    print("Imported stops: " + stopOps.length);
}

function readJsonFile(fileName) {
    const candidates = [
        "/docker-entrypoint-initdb.d/script/test-data/" + fileName,
        path.join(process.cwd(), "schema/test-data/" + fileName),
        path.join(process.cwd(), "database/schema/test-data/" + fileName),
        "./schema/test-data/" + fileName,
        "./test-data/" + fileName,
        fileName
    ];

    for (const filePath of candidates) {
        if (fs.existsSync(filePath)) {
            print("Loading JSON: " + filePath);
            return JSON.parse(fs.readFileSync(filePath, "utf8"));
        }
    }

    throw new Error("Unable to read JSON file: " + fileName);
}

function normalizeReports(reportDocs, userIdByHandle) {
    return reportDocs.map((doc) => {
        const userId = userIdByHandle[doc.userHandle];
        if (!userId) {
            throw new Error("Unknown userHandle in report data: " + doc.userHandle);
        }

        const out = Object.assign({}, doc, {
            userId,
            report_time: new Date(doc.report_time)
        });

        delete out.userHandle;
        return out;
    });
}

print("shcema-data-setup: creating users collection + indexes");
db.createCollection("users");
db.users.createIndex({ handle: 1 }, { unique: true, sparse: true });
db.users.createIndex({ "notifications.enabled": 1 });

print("shcema-data-setup: creating routes collection + indexes");
db.createCollection("routes");
db.routes.createIndex({ routeId: 1 }, { unique: true });

print("shcema-data-setup: creating stops collection + indexes");
db.createCollection("stops");
db.stops.createIndex({ stopId: 1 }, { unique: true });
importRoutesAndStops();

print("shcema-data-setup: creating report collections");
db.createCollection("delay_reports");
db.createCollection("crowding_reports");
db.createCollection("cleanliness_reports");

const commonIndexes = [
    { keys: { routeId: 1, directionId: 1, stopId: 1, at: -1 }, options: {} },
    { keys: { stopId: 1, at: -1 }, options: {} }
];

for (const idx of commonIndexes) {
    db.delay_reports.createIndex(idx.keys, idx.options);
    db.crowding_reports.createIndex(idx.keys, idx.options);
    db.cleanliness_reports.createIndex(idx.keys, idx.options);
}
print("shcema-data-setup: created common report indexes");

db.delay_reports.createIndex({ userId: 1, at: -1 });
db.crowding_reports.createIndex({ userId: 1, at: -1 });
db.cleanliness_reports.createIndex({ userId: 1, at: -1 });
print("shcema-data-setup: created user activity indexes");

print("shcema-data-setup: clearing users and report collections");
db.users.deleteMany({});
db.delay_reports.deleteMany({});
db.crowding_reports.deleteMany({});
db.cleanliness_reports.deleteMany({});

const usersData = readJsonFile("users.json");
const delayReportsData = readJsonFile("delay_reports.json");
const crowdingReportsData = readJsonFile("crowding_reports.json");
const cleanlinessReportsData = readJsonFile("cleanliness_reports.json");

print("shcema-data-setup: creating users test data");
const users = usersData.map((user) => Object.assign({ _id: new ObjectId() }, user));
const userIdByHandle = {};
for (const user of users) {
    userIdByHandle[user.handle] = user._id;
}
db.users.insertMany(users);

print("shcema-data-setup: inserting delay reports");
db.delay_reports.insertMany(normalizeReports(delayReportsData, userIdByHandle));

print("shcema-data-setup: inserting crowding reports");
db.crowding_reports.insertMany(normalizeReports(crowdingReportsData, userIdByHandle));

print("shcema-data-setup: inserting cleanliness reports");
db.cleanliness_reports.insertMany(normalizeReports(cleanlinessReportsData, userIdByHandle));

print("shcema-data-setup: counts");
print("users: " + db.users.countDocuments());
print("delay_reports: " + db.delay_reports.countDocuments());
print("crowding_reports: " + db.crowding_reports.countDocuments());
print("cleanliness_reports: " + db.cleanliness_reports.countDocuments());

print("shcema-data-setup: finished");
print("SoundSync collections + indexes + test data created in DB: soundsync");
