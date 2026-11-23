# 🏗️ COMPLETE SYSTEM ARCHITECTURE & DATA FLOW

## PART 1: HIGH-LEVEL PROJECT OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                     YOUR LOCAL MACHINE                           │
│                    (Windows/Mac/Linux Host)                      │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  DOCKER DESKTOP (Virtualization Layer)                     │ │
│  │  - Runs containers in isolated environment                 │ │
│  │  - Manages networking between containers                   │ │
│  │  - Maps ports from containers to your machine              │ │
│  │                                                              │ │
│  │  ┌──────────────────┐    ┌──────────────────┐             │ │
│  │  │  PostgreSQL 16   │    │   PgAdmin 4      │             │ │
│  │  │  Container       │    │   Container      │             │ │
│  │  │                  │    │                  │             │ │
│  │  │  Port: 5432      │    │  Port: 80        │             │ │
│  │  │  (internal)      │    │  (internal)      │             │ │
│  │  └──────────────────┘    └──────────────────┘             │ │
│  │         ↕                      ↕                           │ │
│  │  Network Bridge: postgres_network                         │ │
│  │  (Containers communicate via this)                        │ │
│  │                                                              │ │
│  └────────────────────────────────────────────────────────────┘ │
│         ↕                                    ↕                   │
│    Port Mapping                        Port Mapping             │
│    5433 (host) → 5432 (container)    5050 (host) → 80 (container)
│         ↓                                    ↓                   │
│  http://localhost:5433               http://localhost:5050      │
│  (psql client, apps)                 (PgAdmin web UI)           │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

**Key Terms Explained:**
- **Docker Desktop**: Virtual machine that runs containers isolated from your OS
- **Container**: A lightweight, self-contained environment with its own OS, software, and configuration
- **Port Mapping**: Forwarding traffic from your machine's port to a container's port
  - `5433→5432`: You connect to localhost:5433, Docker routes it to PostgreSQL's 5432
  - `5050→80`: You connect to localhost:5050, Docker routes it to PgAdmin's 80
- **Network Bridge**: Virtual network connecting containers so they can communicate
  - PostgreSQL container is reachable at hostname "postgres" from other containers
  - PgAdmin can connect to PostgreSQL using hostname "postgres" (not IP address)

---

## PART 2: DOCKER COMPOSE ORCHESTRATION

```
┌─────────────────────────────────────────────────────────────────┐
│          docker-compose.yml (Your Configuration File)            │
│  - Tells Docker how to build, start, and connect containers     │
│  - Everything defined in ONE file                                │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ version: '3.9'  ← Docker Compose file format version    │   │
│  │                                                           │   │
│  │ services:  ← Define two services                        │   │
│  │   postgres:  ← PostgreSQL database service              │   │
│  │   pgadmin:   ← PgAdmin management service               │   │
│  │                                                           │   │
│  │ volumes:  ← Define data persistence storage             │   │
│  │   postgres_data  ← Keeps database files between restarts│   │
│  │                                                           │   │
│  │ networks:  ← Define networking                          │   │
│  │   postgres_network  ← Bridge connecting both containers │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                   │
│  When you run: docker-compose up -d                             │
│  Docker Compose reads this file and:                            │
│  1. Pulls PostgreSQL & PgAdmin images                           │
│  2. Creates containers from images                              │
│  3. Creates postgres_network bridge                             │
│  4. Creates postgres_data volume                                │
│  5. Starts both containers                                      │
│  6. Connects them to the network                                │
│  7. Maps ports (5433→5432, 5050→80)                            │
└─────────────────────────────────────────────────────────────────┘
```

**Key Concepts:**

**Images vs Containers:**
- **Image**: A blueprint (like a recipe) that describes how to build a container
- **Container**: A running instance of an image (like a cake made from the recipe)
- Example: `postgres:16-alpine` is an image → PostgreSQL container is created from it

**Services:**
- Each container is defined as a "service"
- Services can depend on each other (PgAdmin waits for PostgreSQL's health check)

**Health Checks:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U postgres"]
  interval: 10s          # Check every 10 seconds
  timeout: 5s            # Wait max 5 seconds for response
  retries: 5             # Fail after 5 failed checks
  
# This runs "pg_isready" command every 10s to verify PostgreSQL is accepting connections
```

**Volumes:**
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
  
# Left side: Volume name (created by Docker)
# Right side: Container's internal path (where PostgreSQL stores data)
# Effect: Data persists on host machine, survives container deletion
```

---

## PART 3: DATA FLOW - FROM FILE TO RUNNING DATABASE

```
Step 1: DOCKER COMPOSE READS CONFIGURATION
┌─────────────────────────────────────────────────────────────────┐
│ docker-compose.yml                                               │
│ - Specifies postgres:16-alpine image                            │
│ - Defines environment variables: DB_USER, DB_PASSWORD, DB_NAME  │
│ - Maps volume: postgres_data → /var/lib/postgresql/data         │
│ - Maps init scripts: ./init-scripts → /docker-entrypoint-initdb.d
└─────────────────────────────────────────────────────────────────┘
                           ↓

Step 2: CONTAINER STARTS & VOLUME MOUNTS
┌─────────────────────────────────────────────────────────────────┐
│ PostgreSQL Container Initializes                                 │
│ - Docker creates empty postgres_data volume (first time)        │
│ - Mounts postgres_data to container's /var/lib/postgresql/data  │
│ - Mounts ./init-scripts to /docker-entrypoint-initdb.d          │
│ - PostgreSQL starts                                             │
└─────────────────────────────────────────────────────────────────┘
                           ↓

Step 3: INITIALIZATION SCRIPT RUNS AUTOMATICALLY
┌─────────────────────────────────────────────────────────────────┐
│ When PostgreSQL starts, it auto-runs all .sql files in:         │
│ /docker-entrypoint-initdb.d (which is ./init-scripts)           │
│                                                                   │
│ init-scripts/01-init-db.sql executes:                           │
│ 1. CREATE TABLE users (...)    ← Creates users table            │
│ 2. CREATE TABLE products (...) ← Creates products table         │
│ 3. CREATE TABLE orders (...)   ← Creates orders table           │
│ 4. CREATE INDEX ...            ← Creates indexes for speed      │
│ 5. INSERT INTO users VALUES... ← Adds sample data               │
│ 6. INSERT INTO products VALUES... ← Adds sample products        │
└─────────────────────────────────────────────────────────────────┘
                           ↓

Step 4: DATABASE READY, DATA PERSISTED
┌─────────────────────────────────────────────────────────────────┐
│ postgres_data volume now contains:                               │
│ - Database files and metadata                                   │
│ - All tables (users, products, orders)                          │
│ - All sample data (john_doe, products, etc)                     │
│ - Indexes                                                       │
│                                                                   │
│ This data lives on YOUR HOST MACHINE, not just in the container │
│ ✓ Survives container restart                                    │
│ ✓ Survives container deletion                                   │
│ ✓ Can be backed up independently                                │
└─────────────────────────────────────────────────────────────────┘
                           ↓

Step 5: CONTAINERS CONNECT VIA BRIDGE NETWORK
┌─────────────────────────────────────────────────────────────────┐
│ postgres_network bridge created:                                 │
│                                                                   │
│ ┌─────────────────┐              ┌─────────────────┐           │
│ │  PostgreSQL     │              │   PgAdmin       │           │
│ │  Container      │◄────────────►│   Container     │           │
│ │  hostname:      │  Network     │  hostname:      │           │
│ │  "postgres"     │   Bridge     │  "pgadmin"      │           │
│ │  (172.19.0.2)   │              │  (172.19.0.3)   │           │
│ └─────────────────┘              └─────────────────┘           │
│                                                                   │
│ Docker's DNS resolves:                                          │
│ - "postgres" → 172.19.0.2 (PostgreSQL container)               │
│ - "pgadmin" → 172.19.0.3 (PgAdmin container)                   │
│                                                                   │
│ PgAdmin can connect to PostgreSQL using:                        │
│ Host: "postgres"                                                │
│ Port: 5432 (internal port, NOT 5433)                           │
└─────────────────────────────────────────────────────────────────┘
```

**Why use hostname instead of IP?**
- IPs can change, but hostnames are stable
- Containers can be recreated with new IPs
- Using "postgres" hostname keeps configuration flexible

---

## PART 4: DATABASE SCHEMA & RELATIONSHIPS

```
┌─────────────────────────────────────────────────────────────────┐
│                        DATABASE DESIGN                           │
│                    (3 Normalized Tables)                         │
│                                                                   │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │      USERS           │  │      PRODUCTS        │             │
│  ├──────────────────────┤  ├──────────────────────┤             │
│  │ id (PK)              │  │ id (PK)              │             │
│  │ username (UNIQUE)    │  │ name                 │             │
│  │ email (UNIQUE)       │  │ description          │             │
│  │ created_at           │  │ price (CHECK > 0)    │             │
│  │ updated_at           │  │ stock_quantity (≥ 0) │             │
│  │                      │  │ created_at           │             │
│  └──────────────────────┘  └──────────────────────┘             │
│           ▲                           ▲                          │
│           │                           │                          │
│           │ user_id (FK)              │ product_id (FK)         │
│           │                           │                          │
│           └───────────┬───────────────┘                          │
│                       │                                          │
│               ┌───────▼─────────┐                               │
│               │      ORDERS     │                               │
│               ├─────────────────┤                               │
│               │ id (PK)         │                               │
│               │ user_id (FK)    │◄─── References Users.id      │
│               │ product_id (FK) │◄─── References Products.id   │
│               │ quantity > 0    │                               │
│               │ total_price > 0 │                               │
│               │ order_date      │                               │
│               └─────────────────┘                               │
│                                                                   │
│  Relationships (How tables connect):                             │
│  - ORDERS.user_id → USERS.id                                   │
│    "Each order belongs to exactly one user"                     │
│    Foreign Key: Prevents orders for non-existent users          │
│    ON DELETE CASCADE: If user deleted, their orders deleted too │
│                                                                   │
│  - ORDERS.product_id → PRODUCTS.id                             │
│    "Each order contains exactly one product type"               │
│    Foreign Key: Prevents orders for non-existent products       │
│                                                                   │
│  CHECK Constraints (Data Validation):                           │
│  - products.price > 0  (No negative prices)                     │
│  - products.stock_quantity >= 0  (No negative stock)            │
│  - orders.quantity > 0  (Must order at least 1 item)            │
│  - orders.total_price > 0  (Order total must be positive)       │
│                                                                   │
│  UNIQUE Constraints (No Duplicates):                            │
│  - users.username  (Each username appears once)                 │
│  - users.email  (Each email appears once)                       │
│                                                                   │
│  PRIMARY KEY (Unique Identifier):                               │
│  - id column in each table (auto-increments 1, 2, 3...)        │
│                                                                   │
│  INDEXES (For Query Performance):                               │
│  - idx_users_email  → Fast email lookups                        │
│  - idx_orders_user_id  → Fast queries like "get user's orders"  │
│  - idx_orders_order_date  → Fast date-range queries             │
└─────────────────────────────────────────────────────────────────┘
```

---

## PART 5: USER INTERACTION FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                 HOW YOU USE THE SYSTEM                           │
│                                                                   │
│ Step 1: YOU (on Windows/Mac/Linux)                              │
│ ├─ Open browser                                                  │
│ ├─ Navigate to http://localhost:5050                            │
│ └─ See PgAdmin login screen                                     │
│                           ↓                                       │
│ Step 2: LOGIN TO PgAdmin                                        │
│ ├─ Email: admin@example.com                                     │
│ ├─ Password: admin                                               │
│ └─ This is PgAdmin's OWN authentication (not database)          │
│                           ↓                                       │
│ Step 3: PgAdmin REGISTERS PostgreSQL SERVER                     │
│ ├─ Within PgAdmin web UI, add new server:                       │
│ │  - Name: "My Lab PostgreSQL" (just a label)                   │
│ │  - Hostname: "postgres" (Docker DNS resolves this)            │
│ │  - Port: 5432 (internal container port)                       │
│ │  - Username: postgres                                         │
│ │  - Password: MySecurePassword2024! (from .env)                │
│ └─ PgAdmin CONNECTS to PostgreSQL container via bridge network  │
│                           ↓                                       │
│ Step 4: YOU WRITE A SQL QUERY                                   │
│ ├─ In PgAdmin Query Tool, type:                                 │
│ │  SELECT * FROM users;                                         │
│ └─ Click Execute                                                │
│                           ↓                                       │
│ Step 5: QUERY EXECUTION FLOW                                    │
│ ├─ PgAdmin sends query to PostgreSQL container                  │
│ ├─ Query travels through postgres_network bridge               │
│ ├─ PostgreSQL receives query at hostname "postgres"             │
│ ├─ PostgreSQL looks up "users" table in memory/disk             │
│ ├─ PostgreSQL retrieves data from postgres_data volume          │
│ ├─ PostgreSQL returns results to PgAdmin                        │
│ └─ PgAdmin displays results in browser table format             │
│                           ↓                                       │
│ Step 6: YOU SEE RESULTS                                         │
│ └─ Browser shows table with user data                           │
│                                                                   │
│ NOTE: ALL of this happens on YOUR MACHINE!                      │
│ - No internet required                                          │
│ - No AWS/cloud needed                                           │
│ - Everything is local and isolated                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## PART 6: DATA PERSISTENCE MAGIC

```
┌─────────────────────────────────────────────────────────────────┐
│          HOW DATA SURVIVES CONTAINER RESTARTS                    │
│                                                                   │
│ ┌─ Scenario 1: Container RESTARTS (docker-compose restart)     │
│ │                                                                 │
│ │  BEFORE: Container running, postgres_data volume on disk      │
│ │  ACTION: docker-compose restart postgres                      │
│ │  AFTER:  Container stopped, volume data remains on disk       │
│ │          Docker starts new container, remounts volume         │
│ │  RESULT: ✓ All data intact, nothing lost                      │
│ │                                                                 │
│ │                                                                 │
│ ├─ Scenario 2: Container DELETED (docker-compose down)         │
│ │                                                                 │
│ │  BEFORE: Container running, postgres_data volume on disk      │
│ │  ACTION: docker-compose down                                  │
│ │  AFTER:  Container deleted, BUT volume remains on disk        │
│ │          Run docker-compose up                                │
│ │          Docker creates new container, remounts same volume   │
│ │  RESULT: ✓ All data intact, nothing lost                      │
│ │                                                                 │
│ │                                                                 │
│ ├─ Scenario 3: Volume DELETED (docker volume rm)               │
│ │                                                                 │
│ │  BEFORE: Container deleted, postgres_data volume on disk      │
│ │  ACTION: docker volume rm postgres-docker-lab_postgres_data  │
│ │  AFTER:  Volume deleted from disk, all data GONE              │
│ │          Run docker-compose up                                │
│ │          Docker creates NEW empty volume                      │
│ │          init-scripts/01-init-db.sql runs again              │
│ │  RESULT: ✗ All previous data lost (fresh database)            │
│ │                                                                 │
│ │                                                                 │
│ └─ Volume Storage Location:                                      │
│    Windows: C:\ProgramData\Docker\volumes\<volume_id>\_data    │
│    Linux: /var/lib/docker/volumes/<volume_id>/_data             │
│    Mac: ~/Library/Containers/com.docker.docker/Data/vms/0/...  │
│                                                                   │
│    You can browse these on your machine to verify data exists!   │
└─────────────────────────────────────────────────────────────────┘
```

---

## PART 7: WHAT HAPPENS WHEN YOU INSERT DATA

```
Step-by-Step Flow: INSERT INTO orders (user_id, product_id, quantity, total_price) VALUES (1, 2, 1, 39.99);

┌──────────────────┐
│  You type query  │
│  in PgAdmin UI   │
└────────┬─────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ PgAdmin sends query through postgres_network │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ PostgreSQL receives INSERT command           │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│ PostgreSQL VALIDATION CHECKS                                │
│                                                              │
│ ✓ user_id=1 exists in users table?                         │
│   YES (john_doe) → Continue                                │
│   NO → REJECTED: Foreign Key Constraint Violation          │
│                                                              │
│ ✓ product_id=2 exists in products table?                   │
│   YES (Docker Handbook) → Continue                         │
│   NO → REJECTED: Foreign Key Constraint Violation          │
│                                                              │
│ ✓ quantity > 0?                                             │
│   YES (1 > 0) → Continue                                   │
│   NO → REJECTED: Check Constraint Violation                │
│                                                              │
│ ✓ total_price > 0?                                          │
│   YES (39.99 > 0) → Continue                               │
│   NO → REJECTED: Check Constraint Violation                │
│                                                              │
│ ✓ All NOT NULL fields provided?                            │
│   YES → Continue                                            │
│   NO → REJECTED: Not-Null Constraint Violation             │
│                                                              │
│ ALL CHECKS PASSED! ✓                                        │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│ PostgreSQL PERFORMS INSERT                                  │
│                                                              │
│ 1. Auto-generate id=X (using SERIAL auto-increment)         │
│ 2. Record current timestamp in order_date                   │
│ 3. Write row to orders table in memory                      │
│ 4. Write row to postgres_data volume on disk                │
│ 5. Create transaction log entry                             │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│ PostgreSQL returns SUCCESS message                           │
│ "Query returned successfully"                               │
└────────┬─────────────────────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│ PgAdmin displays success in Query Tool                       │
│ User can verify by running:                                 │
│ SELECT * FROM orders;                                       │
│                                                              │
│ New order appears in table! ✓                               │
└──────────────────────────────────────────────────────────────┘
```

---

## PART 8: CONSTRAINT PROTECTION IN ACTION

```
Scenario: User tries to INSERT INVALID DATA

┌─────────────────────────────────────────────────────────────┐
│ Test 1: NEGATIVE PRICE                                      │
├─────────────────────────────────────────────────────────────┤
│ INSERT INTO products (name, price) VALUES ('Bad', -99.99)   │
│                                                              │
│ PostgreSQL checks: price > 0?                               │
│ FAILED: -99.99 is NOT > 0                                   │
│                                                              │
│ RESULT: ❌ REJECTED                                          │
│ ERROR: "violates check constraint 'products_price_check'"   │
│                                                              │
│ Database remains clean (bad data never stored)              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Test 2: INVALID FOREIGN KEY                                 │
├─────────────────────────────────────────────────────────────┤
│ INSERT INTO orders (user_id, product_id, quantity, total_)  │
│ VALUES (99, 2, 1, 39.99)                                    │
│                                                              │
│ PostgreSQL checks: user_id=99 exists?                       │
│ FAILED: No user with id=99                                  │
│                                                              │
│ RESULT: ❌ REJECTED                                          │
│ ERROR: "violates foreign key constraint"                    │
│                                                              │
│ Database remains consistent (can't orphan orders)           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Test 3: ZERO QUANTITY                                       │
├─────────────────────────────────────────────────────────────┤
│ INSERT INTO orders (...quantity...) VALUES (...0...)        │
│                                                              │
│ PostgreSQL checks: quantity > 0?                            │
│ FAILED: 0 is NOT > 0                                        │
│                                                              │
│ RESULT: ❌ REJECTED                                          │
│ ERROR: "violates check constraint 'orders_quantity_check'"  │
│                                                              │
│ Database remains valid (no nonsense orders)                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Test 4: VALID DATA (All checks pass)                        │
├─────────────────────────────────────────────────────────────┤
│ INSERT INTO products (name, price) VALUES ('Good', 29.99)   │
│                                                              │
│ PostgreSQL checks:                                          │
│ ✓ name provided (NOT NULL)                                  │
│ ✓ price > 0 (29.99 is valid)                                │
│                                                              │
│ RESULT: ✅ ACCEPTED                                          │
│ MESSAGE: "Query returned successfully"                      │
│                                                              │
│ Data stored in database                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## SUMMARY: The Complete Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                  YOUR PROJECT'S COMPLETE FLOW                     │
│                                                                    │
│  1. SETUP PHASE                                                   │
│     docker-compose.yml → Docker reads config                     │
│                       → Creates & starts containers              │
│                       → Sets up networking & volumes              │
│                       → PostgreSQL initializes                    │
│                       → Runs init-scripts/01-init-db.sql         │
│                       → Database ready with tables & data         │
│                                                                    │
│  2. USAGE PHASE                                                   │
│     You in browser → http://localhost:5050 (PgAdmin)            │
│                   → Login (admin/admin)                           │
│                   → Register PostgreSQL server                    │
│                   → Write SQL queries                             │
│                   → View results                                  │
│                                                                    │
│  3. DATA FLOW PHASE                                               │
│     Your query → PgAdmin → postgres_network → PostgreSQL         │
│               ← Results ← postgres_network ← PostgreSQL          │
│                                                                    │
│  4. VALIDATION PHASE                                              │
│     All data checked against:                                    │
│     - NOT NULL constraints (required fields)                     │
│     - UNIQUE constraints (no duplicates)                         │
│     - CHECK constraints (price > 0, quantity > 0, etc)          │
│     - FOREIGN KEY constraints (valid references)                │
│     - Data type constraints (numbers, text, etc)                │
│                                                                    │
│  5. PERSISTENCE PHASE                                             │
│     Data written to postgres_data volume (on your disk)          │
│     ✓ Survives container restarts                               │
│     ✓ Survives container deletion                               │
│     ✓ Can be backed up independently                            │
│     ✓ Remains after docker-compose down                         │
│                                                                    │
│  6. ANALYSIS PHASE (Optional)                                     │
│     Run JOIN queries combining users + products + orders         │
│     Run aggregate queries (COUNT, SUM, AVG) for insights         │
│     Run GROUP BY queries for business intelligence               │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

---

**End of Detailed Architecture Guide**
