/**
 * SoundSync test data (mongosh)
 *
 * Assumes setup was already run and DB "soundsync" exists.
 */

print("test-data: start");
db = db.getSiblingDB("soundsync");
print("test-data: using database -> " + db.getName());

function readJsonFile(fileName) {
    const candidates = [
        "/docker-entrypoint-initdb.d/script/test-data/" + fileName,
        "./schema/test-data/" + fileName,
        "./test-data/" + fileName,
        fileName
    ];

    for (const path of candidates) {
        try {
            return JSON.parse(cat(path));
        } catch (err) {
            // Try next path candidate.
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

print("test-data: clearing users and report collections");
db.users.deleteMany({});
db.delay_reports.deleteMany({});
db.crowding_reports.deleteMany({});
db.cleanliness_reports.deleteMany({});

const usersData = readJsonFile("users.json");
const delayReportsData = readJsonFile("delay_reports.json");
const crowdingReportsData = readJsonFile("crowding_reports.json");
const cleanlinessReportsData = readJsonFile("cleanliness_reports.json");

print("test-data: creating users");
const users = usersData.map((user) => Object.assign({ _id: new ObjectId() }, user));
const userIdByHandle = {};
for (const user of users) {
    userIdByHandle[user.handle] = user._id;
}
db.users.insertMany(users);

print("test-data: inserting delay reports");
db.delay_reports.insertMany(normalizeReports(delayReportsData, userIdByHandle));

print("test-data: inserting crowding reports");
db.crowding_reports.insertMany(normalizeReports(crowdingReportsData, userIdByHandle));

print("test-data: inserting cleanliness reports");
db.cleanliness_reports.insertMany(normalizeReports(cleanlinessReportsData, userIdByHandle));

print("test-data: counts");
print("users: " + db.users.countDocuments());
print("delay_reports: " + db.delay_reports.countDocuments());
print("crowding_reports: " + db.crowding_reports.countDocuments());
print("cleanliness_reports: " + db.cleanliness_reports.countDocuments());

print("test-data: finished");





