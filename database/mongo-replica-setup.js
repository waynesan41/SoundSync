function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function waitForPrimary() {
    print("mongo-replica-setup: waiting for primary...");
    for (let i = 0; i < 30; i++) {
        try {
            const status = rs.status();
            if (status && status.myState === 1) {
                print("mongo-replica-setup: primary elected.");
                return true;
            }
        } catch (e) {
            // ignore and retry
        }
        await sleep(1000);
    }
    print("mongo-replica-setup: primary not elected after timeout.");
    return false;
}

async function initiateReplicaSet() {
    print("mongo-replica-setup: initiating replica set...");
    const envHosts = (process.env.MONGO_RS_HOSTS || "")
        .split(",")
        .map(h => h.trim())
        .filter(Boolean);
    const membersHosts = envHosts.length === 3
        ? envHosts
        : ["mongo1:27017", "mongo2:27017", "mongo3:27017"];
    print("mongo-replica-setup: replica hosts -> " + membersHosts.join(", "));
    const config = {
        _id: "rs0",
        members: [
            { _id: 0, host: membersHosts[0] },
            { _id: 1, host: membersHosts[1] },
            { _id: 2, host: membersHosts[2] }
        ]
    };

    for (let i = 0; i < 10; i++) {
        try {
            rs.initiate(config);
            print("mongo-replica-setup: rs.initiate() called.");
            break;
        } catch (e) {
            // likely already initiated or secondaries not ready yet
        }
        await sleep(1000);
    }
}

function createSoundsyncDb() {
    print("mongo-replica-setup: creating soundsync database...");
    const appDb = db.getSiblingDB("soundsync");
    appDb.createCollection("init");
    print("mongo-replica-setup: soundsync database ready.");
}

(async function () {
    print("mongo-replica-setup: starting.");
    await initiateReplicaSet();
    const isPrimary = await waitForPrimary();
    if (!isPrimary) {
        print("mongo-replica-setup: exiting without creating users (not primary).");
        return;
    }
    await sleep(5000);
    createSoundsyncDb();
    print("mongo-replica-setup: finished.");
})();

