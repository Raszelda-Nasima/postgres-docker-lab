# Architecture Overview

The lab runs PostgreSQL 16 and PgAdmin 4 as containers on a private Docker bridge network named `postgres_network`.

- **PostgreSQL:** `postgres:16-alpine`, initialized using environment settings and SQL files from `init-scripts/`.
- **PgAdmin:** `dpage/pgadmin4:latest`, exposed on host port 5050 and started after PostgreSQL passes its health check.
- **Persistence:** the `postgres_data` named volume stores the PostgreSQL data directory across container restarts and recreation.
- **Networking:** containers resolve one another by Compose service name. PostgreSQL is published on host port 5433 and listens on container port 5432.
- **Operations:** backup scripts and database health checks are provided in `backup-scripts/` and `monitoring/`.

## Data flow

1. Docker Compose creates the network and persistent volume, then starts PostgreSQL.
2. On first database initialization, PostgreSQL runs the mounted SQL scripts.
3. PgAdmin waits until PostgreSQL reports healthy, then connects over the Compose network using the `postgres` service name.
4. Host tools connect to PostgreSQL at `localhost:5433`; a browser accesses PgAdmin at `http://localhost:5050`.
5. Database files remain in `postgres_data` when containers are stopped or recreated. Removing the volume deletes the stored data.
