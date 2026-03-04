#!/usr/bin/env bash
# Run these commands one line at a time after: docker compose up -d

# mongo1

docker exec soundsync-mongo1 mkdir -p /docker-entrypoint-initdb.d/script
docker exec soundsync-mongo1 mkdir -p /docker-entrypoint-initdb.d/script/test-data
docker cp ./mongo-replica-setup.js soundsync-mongo1:/docker-entrypoint-initdb.d/mongo-replica-setup.js
docker cp ./schema/shcema-data-setup.js soundsync-mongo1:/docker-entrypoint-initdb.d/script/shcema-data-setup.js
docker cp ./schema/test-data/. soundsync-mongo1:/docker-entrypoint-initdb.d/script/test-data/

# mongo2

docker exec soundsync-mongo2 mkdir -p /docker-entrypoint-initdb.d/script
docker exec soundsync-mongo2 mkdir -p /docker-entrypoint-initdb.d/script/test-data
docker cp ./mongo-replica-setup.js soundsync-mongo2:/docker-entrypoint-initdb.d/mongo-replica-setup.js
docker cp ./schema/shcema-data-setup.js soundsync-mongo2:/docker-entrypoint-initdb.d/script/shcema-data-setup.js
docker cp ./schema/test-data/. soundsync-mongo2:/docker-entrypoint-initdb.d/script/test-data/

# mongo3

docker exec soundsync-mongo3 mkdir -p /docker-entrypoint-initdb.d/script
docker exec soundsync-mongo3 mkdir -p /docker-entrypoint-initdb.d/script/test-data
docker cp ./mongo-replica-setup.js soundsync-mongo3:/docker-entrypoint-initdb.d/mongo-replica-setup.js
docker cp ./schema/shcema-data-setup.js soundsync-mongo3:/docker-entrypoint-initdb.d/script/shcema-data-setup.js
docker cp ./schema/test-data/. soundsync-mongo3:/docker-entrypoint-initdb.d/script/test-data/

# Verify files are present in mongo1 before running scripts

docker exec soundsync-mongo1 ls -la /docker-entrypoint-initdb.d/script/test-data

# Run scripts on mongo1 after copy

docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/mongo-replica-setup.js
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/script/shcema-data-setup.js
