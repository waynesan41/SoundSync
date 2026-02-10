function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function waitForPrimary() {
  for (let i = 0; i < 30; i++) {
    try {
      const status = rs.status();
      if (status && status.myState === 1) return true;
    } catch (e) {
      // ignore and retry
    }
    await sleep(1000);
  }
  return false;
}

async function initiateReplicaSet() {
  await sleep(20000);
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
      break;
    } catch (e) {
      // likely already initiated or secondaries not ready yet
    }
    await sleep(1000);
  }
}

async function createAppUsers() {
  const appDb = db.getSiblingDB("soundsync");

  appDb.createUser({
    user: "backend",
    pwd: process.env.MONGO_BACKEND_PASSWORD || "backendpassword",
    roles: [{ role: "readWrite", db: "soundsync" }]
  });

  appDb.createUser({
    user: "frontend",
    pwd: process.env.MONGO_FRONTEND_PASSWORD || "frontendpassword",
    roles: [{ role: "readWrite", db: "soundsync" }]
  });

  appDb.createUser({
    user: "business",
    pwd: process.env.MONGO_BUSINESS_PASSWORD || "businesspassword",
    roles: [{ role: "readWrite", db: "soundsync" }]
  });
}

(async function() {
  await initiateReplicaSet();
  const isPrimary = await waitForPrimary();
  if (!isPrimary) return;
  await createAppUsers();
  try {
    load("/docker-entrypoint-initdb.d/script/create-collections.js");
  } catch (e) {
    // ignore if missing
  }
})();
