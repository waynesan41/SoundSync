# Database Setup (Docker + Compass)

Mac Docker Compose and environment files live in this folder.

## Start MongoDB Replica Set

From the repo root:

```bash
cd database
```

Start:

```bash
docker compose -f docker-compose.mac.yml up -d
```

Wait 30-60 seconds for replica set init.

## MongoDB Compass (macOS)

Preferred (replica set, requires hostnames to resolve):

```
mongodb://admin:adminpassword@localhost:27017,localhost:27018,localhost:27019/?replicaSet=rs0&authSource=admin
```

If Compass shows `getaddrinfo ENOTFOUND mongo2`, use direct connection to the PRIMARY:

```
mongodb://admin:adminpassword@localhost:27017/?directConnection=true&authSource=admin
```

To find the PRIMARY port:

```bash
docker exec soundsync-mongo1 mongosh -u admin -p adminpassword --authenticationDatabase admin --eval "rs.status().members.map(m=>({name:m.name,stateStr:m.stateStr}))"
```

Use the port of the member with `stateStr: 'PRIMARY'` in the direct connection string.