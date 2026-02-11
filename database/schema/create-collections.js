const appDb = db.getSiblingDB("soundsync");

// Creates the `users` collection with validation for login-based accounts.
try {
  appDb.createCollection("users", {
    validator: {
      $jsonSchema: {
        bsonType: "object",
        required: ["email", "passwordHash"],
        properties: {
          email: { bsonType: "string" },
          passwordHash: { bsonType: "string" },

          handle: { bsonType: "string" },

          favoriteBusRoutes: {
            bsonType: "array",
            items: { bsonType: "string" }
          },

          notifications: {
            bsonType: "object",
            properties: {
              enabled: { bsonType: "bool" },
              subscriptions: {
                bsonType: "array",
                items: {
                  bsonType: "object",
                  required: ["routeId"],
                  properties: {
                    routeId: { bsonType: "string" },
                    directionId: { bsonType: "int" },
                    stopId: { bsonType: "string" }
                  }
                }
              }
            }
          }
        }
      }
    }
  });
} catch (e) {
  // Collection may already exist
}

// Ensures emails are unique for account login.
try {
  appDb.users.createIndex({ email: 1 }, { unique: true });
} catch (e) {
  // Index may already exist
}

// Optionally ensures handles are unique (nice for display usernames).
try {
  appDb.users.createIndex({ handle: 1 }, { unique: true, sparse: true });
} catch (e) {
  // Index may already exist
}