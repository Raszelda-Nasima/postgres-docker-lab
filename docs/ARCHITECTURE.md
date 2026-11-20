# Architecture Overview

## System Design

### Local Development Setup

```
┌─────────────────────────────────────────────────────┐
│          Docker Compose Environment                 │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │      PostgreSQL 16 Container                │   │
│  ├────────────────────────────────────────────┤   │
│  │  - Alpine Linux Base (minimal)              │   │
│  │  - Volume-mounted persistent data           │   │
│  │  - Health checks enabled                    │   │
│  │  - Custom initialization scripts            │   │
│  │  Port: 5432                                 │   │
│  └────────────────────────────────────────────┘   │
│                      ▲                              │
│                      │                              │
│                      │ (network: postgres_network)  │
│                      │                              │
│  ┌────────────────────────────────────────────┐   │
│  │      PgAdmin 4 Container                    │   │
│  ├────────────────────────────────────────────┤   │
│  │  - Web-based database management            │   │
│  │  - Dependent on PostgreSQL health check     │   │
│  │  Port: 5050 (HTTP)                          │   │
│  └────────────────────────────────────────────┘   │
│                                                     │
│  ┌────────────────────────────────────────────┐   │
│  │    Volume: postgres_data                    │   │
│  │  - Persistent storage for database files    │   │
│  │  - Survives container restarts              │   │
│  │  - Located in Docker's managed storage      │   │
│  └────────────────────────────────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### AWS EC2 Deployment

```
┌────────────────────────────────────────────────────────────┐
│                         AWS Account                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────────────────────────────────────┐     │
│  │  VPC: 10.0.0.0/16                               │     │
│  │  ┌────────────────────────────────────────────┐ │     │
│  │  │  Subnet: 10.0.1.0/24 (Public)              │ │     │
│  │  │                                            │ │     │
│  │  │  ┌─────────────────────────────────────┐  │ │     │
│  │  │  │ EC2 Instance (t3.small)             │  │ │     │
│  │  │  │ - Ubuntu 22.04 LTS                  │  │ │     │
│  │  │  │ - Docker + Docker Compose           │  │ │     │
│  │  │  │ - PostgreSQL & PgAdmin containers   │  │ │     │
│  │  │  │ - EBS gp3 (20GB, encrypted)         │  │ │     │
│  │  │  └─────────────────────────────────────┘  │ │     │
│  │  │            ▲                               │ │     │
│  │  │            │ (Elastic IP)                  │ │     │
│  │  │  ┌────────────────────────────────────┐  │ │     │
│  │  │  │ Security Group                      │  │ │     │
│  │  │  │ - SSH (22): From your IP           │  │ │     │
│  │  │  │ - PostgreSQL (5432): VPC CIDR      │  │ │     │
│  │  │  │ - PgAdmin (5050): Public           │  │ │     │
│  │  │  └────────────────────────────────────┘  │ │     │
│  │  └────────────────────────────────────────────┘ │     │
│  │                                                 │     │
│  │  ┌────────────────────────────────────────────┐ │     │
│  │  │ Internet Gateway                           │ │     │
│  │  └────────────────────────────────────────────┘ │     │
│  └──────────────────────────────────────────────────┘     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Component Details

### PostgreSQL Container

**Base Image**: `postgres:16-alpine`
- Minimal footprint (~40MB)
- LTS support
- Built-in health checks

**Configuration**:
- Environment-based credentials
- Custom SQL initialization scripts
- JSON file logging with rotation
- Restart policy: `unless-stopped`

**Data Persistence**:
- Docker volume mount: `postgres_data:/var/lib/postgresql/data`
- Survives container restarts and recreation
- Can be backed up independently

**Health Checks**:
```
Test: pg_isready -U postgres
Interval: 10 seconds
Timeout: 5 seconds
Retries: 5
```

### PgAdmin Container

**Purpose**: Web-based PostgreSQL administration
- No database credentials needed after startup
- Service dependency on PostgreSQL health check
- Lightweight Python application

**Features**:
- Visual schema browser
- Query tool with syntax highlighting
- Backup/restore utilities
- Server connection management

### Docker Networking

**Network Type**: Bridge network (`postgres_network`)
- Isolates containers from host network
- Containers can communicate by name
- Cleaner multi-container environment

### Volumes and Storage

**Types**:
- **Named Volume**: `postgres_data` (managed by Docker)
- **Bind Mount**: `./init-scripts` (host directory)

**Backup Strategy**:
```bash
# Backup database
docker-compose exec postgres pg_dump -U postgres myapp_db > backup.sql

# Backup volume data
docker cp postgres_db:/var/lib/postgresql/data ./postgres_data_backup
```

## Data Flow

1. **Application** → PostgreSQL (5432)
   - Standard TCP connections
   - SQL queries execute

2. **PgAdmin UI** → PostgreSQL (5432)
   - Via Docker network
   - Administrative operations

3. **User Browser** → PgAdmin (5050)
   - HTTP requests
   - Web-based management interface

## Security Considerations

### Local Development
✓ Network isolation via Docker bridge
✓ Credentials in `.env` file (not in source control)
✓ Database initialized with strong defaults
⚠️ PgAdmin accessible without authentication (fine for dev)

### AWS Production
✓ Security groups restrict traffic
✓ IMDSv2 enforced (instance metadata)
✓ EBS encryption enabled
✓ CloudWatch monitoring enabled
⚠️ SSH: Restrict to your IP address
⚠️ PgAdmin: Use VPN or restrict CIDR
⚠️ Credentials: Use AWS Secrets Manager

## Scaling Considerations

### Vertical Scaling
- Upgrade `instance_type` in Terraform
- Increase `root_volume_size` for more storage
- More container resources via limits

### Horizontal Scaling
- Deploy read replicas (PostgreSQL streaming replication)
- Use AWS RDS instead of self-managed containers
- Implement load balancing with Application Load Balancer

### High Availability
- Multi-AZ RDS deployment
- Automated backups with point-in-time recovery
- Failover replicas in different availability zones

## Monitoring & Logging

### Container Logs
```bash
docker-compose logs postgres     # PostgreSQL logs
docker-compose logs pgadmin      # PgAdmin logs
docker-compose logs -f           # Follow logs in real-time
```

### Log Configuration
- Driver: `json-file`
- Max file size: 10MB (PostgreSQL), 5MB (PgAdmin)
- Max files: 3 (rotation)

### AWS CloudWatch
- EC2 detailed monitoring available
- Can integrate with CloudWatch agent
- Set alarms on CPU, memory, disk usage

## Disaster Recovery

### Backup Strategy
1. **Database Backups**
   ```bash
   docker-compose exec postgres pg_dump -Fc -U postgres myapp_db > backup.dump
   ```

2. **Volume Snapshots** (AWS)
   ```bash
   aws ec2 create-snapshot --volume-id vol-xxx --description "postgres-data"
   ```

3. **Full Instance Image** (AWS AMI)
   - Create AMI from configured instance
   - Quick recovery via launch from AMI

### Recovery Procedure
1. Restore from backup dump
2. Verify data integrity
3. Run test queries
4. Confirm application connectivity

## Performance Tuning

### PostgreSQL Settings
- Modify `postgresql.conf` for memory/CPU optimization
- Connection pooling with PgBouncer
- Query optimization and indexing

### Container Resources
- Set memory limits in `docker-compose.yml`
- CPU shares for fair distribution
- Swap memory limit to prevent OOM kills

### Database Optimization
- Regular VACUUM and ANALYZE
- Index creation on frequently queried columns
- Partition large tables by date/range
