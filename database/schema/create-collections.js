const appDb = db.getSiblingDB("soundsync");

// User collection with basic validation
try {
  appDb.createCollection("users", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["email", "password", "favoriteBusRoutes"],
        properties: {
          email: { bsonType: "string" },
          password: { bsonType: "string" },
          favoriteBusRoutes: {
            bsonType: "array",
            items: { bsonType: "string" }
          }
        }
      }
    }
  });
} catch (e) {
  // collection may already exist
}

// Ensure unique emails
try {
  appDb.users.createIndex({ email: 1 }, { unique: true });
} catch (e) {
  // index may already exist
}