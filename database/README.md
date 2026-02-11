# Database Setup (Docker + Compass)

Mac Docker Compose and environment files live in this folder.

## Start MongoDB Replica Set

From the repo root:

```bash
cd database
```

Start:

```bash
docker compose up -d --build
```

Wait 30-60 seconds for replica set init.

### Check if the Database is set up after a minute.
```bash
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin --eval "rs.status().members.map(m=>({name:m.name,stateStr:m.stateStr}))"
```
## If it return the following it is good to continue running the scripts.
```MongoServerError: no replset config has been received```
### Run the follwing line by line

Setup Replica Script
```bash
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/mongo-init.js
```

Set up Database Index and Collection
```bash
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/script/database-setup.js
```

Set up Sample Data
```bash
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin /docker-entrypoint-initdb.d/sample-data.js
```

#### Use this in MongoDB Compass to connect to Database
```bash
mongodb://admin:adminpassword@localhost:27017/?directConnection=true
```
