#!/bin/bash
set -e

# Ensure the keyfile is mounted before we copy it.
if [ ! -f /etc/mongo-keyfile-src ]; then
  echo "Keyfile source not found at /etc/mongo-keyfile-src" >&2
  exit 1
fi

cp /etc/mongo-keyfile-src /tmp/mongo-keyfile
chmod 400 /tmp/mongo-keyfile
chown mongodb:mongodb /tmp/mongo-keyfile

# Give Docker volumes and mongod a moment before init scripts run
sleep 10

exec /usr/local/bin/docker-entrypoint.sh "$@"

sleep 10

# Building docker Compose
docker compose up -d --build
docker compose up -d
docker compose down

# Initialize the replica set
# docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin --eval "rs.initiate({_id:'rs0',members:[{_id:0,host:'mongo1:27017'},{_id:1,host:'mongo2:27017'},{_id:2,host:'mongo3:27017'}]})"

# Check the status of the replica set
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin --eval "rs.status().members.map(m=>({name:m.name,stateStr:m.stateStr}))"

# Run mongo-init.js to create the admin users
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/mongo-init.js
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/script/database-setup.js
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/script/sample-data.js


# Connecting to Replica set inside container within network.
# Go Application will need to run inside this container
docker exec soundsync-mongo1 mongosh "mongodb://admin:adminpassword@mongo1:27017,mongo2:27017,mongo3:27017/?replicaSet=rs0&authSource=admin" --eval "db.adminCommand({ ping: 1 })"



