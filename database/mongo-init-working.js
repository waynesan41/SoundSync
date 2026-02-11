function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function waitForPrimary() {
    print("mongo-init: waiting for primary...");
    for (let i = 0; i < 30; i++) {
        try {
            const status = rs.status();
            if (status && status.myState === 1) {
                print("mongo-init: primary elected.");
                return true;
            }
        } catch (e) {
            // ignore and retry
        }
        await sleep(1000);
    }
    print("mongo-init: primary not elected after timeout.");
    return false;
}

async function initiateReplicaSet() {
    print("mongo-init: initiating replica set...");
    const config = {
        _id: "rs0",
        members: [
            { _id: 0, host: "mongo1:27017" },
            { _id: 1, host: "mongo2:27017" },
            { _id: 2, host: "mongo3:27017" }
        ]
    };

    for (let i = 0; i < 10; i++) {
        try {
            rs.initiate(config);
            print("mongo-init: rs.initiate() called.");
            break;
        } catch (e) {
            // likely already initiated or secondaries not ready yet
        }
        await sleep(1000);
    }
}

function createSoundsyncDb() {
    print("mongo-init: creating soundsync database...");
    const appDb = db.getSiblingDB("soundsync");
    appDb.createCollection("init");
    print("mongo-init: soundsync database ready.");
}

(async function () {
    print("mongo-init: starting.");
    await initiateReplicaSet();
    const isPrimary = await waitForPrimary();
    if (!isPrimary) {
        print("mongo-init: exiting without creating users (not primary).");
        return;
    }
    await sleep(5000);
    createSoundsyncDb();
    print("mongo-init: finished.");
})();
