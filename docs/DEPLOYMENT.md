# Deployment Guide

## Prerequisites

### For Local Deployment
- Docker Desktop 4.0+ (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2.0+
- Git
- 2GB free disk space
- Ports 5432 and 5050 available

### For AWS Deployment
- AWS Account with appropriate permissions
- Terraform 1.0+
- AWS CLI v2 configured with credentials
- SSH key pair created in target AWS region
- Minimum permissions: EC2, VPC, Security Groups, IAM PassRole

## Local Deployment (Quick Start)

### 1. Clone or Navigate to Project
```bash
cd postgres-docker-lab
```

### 2. Configure Environment
```bash
cp .env.example .env

# Edit .env with desired credentials
# IMPORTANT: Change DB_PASSWORD to a secure password!
nano .env
```

### 3. Start Services
```bash
docker-compose up -d
```

### 4. Verify Deployment
```bash
# Check containers are running
docker-compose ps

# Check PostgreSQL health
docker-compose exec postgres pg_isready -U postgres

# View startup logs
docker-compose logs postgres
```

### 5. Access Services

**PostgreSQL**:
```bash
docker-compose exec postgres psql -U postgres -d myapp_db

# Or use external client
psql -h localhost -U postgres -d myapp_db
```

**PgAdmin Web UI**:
- URL: http://localhost:5050
- Email: admin@example.com
- Password: admin

### 6. Test Database Connection
```bash
# From inside PostgreSQL
SELECT version();
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
SELECT * FROM users;
```

## AWS Deployment (Production)

### Step 1: Prepare AWS Environment

#### Create SSH Key Pair
```bash
# Generate key (or use existing one)
aws ec2 create-key-pair \
    --key-name postgres-lab-key \
    --region us-east-1 \
    --query 'KeyMaterial' \
    --output text > postgres-lab-key.pem

chmod 400 postgres-lab-key.pem
```

#### Set AWS Credentials
```bash
# Configure AWS CLI
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

### Step 2: Customize Terraform Variables

#### Create terraform.tfvars
```bash
cd terraform

cat > terraform.tfvars <<EOF
aws_region         = "us-east-1"
instance_type      = "t3.small"
root_volume_size   = 20
key_pair_name      = "postgres-lab-key"

db_user            = "postgres"
db_password        = "YourSecurePassword123!" # Change this!
db_name            = "myapp_db"

# SECURITY: Restrict these in production!
allowed_ssh_cidr       = ["YOUR_IP/32"]  # Replace with your IP
allowed_pgadmin_cidr   = ["YOUR_IP/32"]  # Restrict web access

project_name = "postgres-docker-lab"
```

**Get Your IP**:
```bash
curl https://checkip.amazonaws.com
# or
curl https://icanhazip.com
```

### Step 3: Deploy with Terraform

#### Initialize Terraform
```bash
terraform init
```

#### Plan Deployment
```bash
terraform plan -out=tfplan

# Review the plan output for expected resources
```

#### Apply Configuration
```bash
terraform apply tfplan

# Terraform will create:
# - VPC and networking
# - Security groups
# - EC2 instance
# - Elastic IP
# - EBS volume
```

#### Capture Outputs
```bash
terraform output

# Save these for reference:
# - instance_public_ip
# - postgres_connection_string
# - pgadmin_url
# - ssh_command
```

### Step 4: Connect to EC2 Instance

```bash
# SSH into instance
ssh -i postgres-lab-key.pem ubuntu@<instance_public_ip>

# Verify Docker and containers
docker ps
docker-compose ps

# Check PostgreSQL logs
docker-compose logs postgres

# Wait for initialization (should see "database system is ready to accept connections")
sleep 30
docker-compose logs postgres | tail -20
```

### Step 5: Verify Services

```bash
# Test PostgreSQL from EC2 instance
docker-compose exec postgres psql -U postgres -d myapp_db -c "SELECT version();"

# From local machine
psql -h <instance_public_ip> -U postgres -d myapp_db

# Test PgAdmin
curl -s http://localhost:5050 | head -20
```

## Post-Deployment Configuration

### 1. Database Initialization

Verify that tables were created:
```bash
docker-compose exec postgres psql -U postgres -d myapp_db

myapp_db=# \dt              # List tables
myapp_db=# SELECT * FROM users;    # View sample data
myapp_db=# \q               # Quit
```

### 2. PgAdmin Setup

1. Access PgAdmin at http://<ip>:5050
2. Create Server connection:
   - Name: "PostgreSQL Lab"
   - Host: `postgres` (or `localhost`)
   - Port: 5432
   - Username: postgres
   - Password: (from your environment)

### 3. Configure Backups

#### Automated Database Backups
```bash
# Create backup directory
mkdir -p backups

# Create cron job for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * docker-compose -f /opt/postgres-lab/docker-compose.yml exec -T postgres pg_dump -U postgres myapp_db > /opt/postgres-lab/backups/db_backup_\$(date +\\%Y\\%m\\%d_\\%H\\%M\\%S).sql") | crontab -
```

#### Volume Snapshots (AWS)
```bash
# Get volume ID
aws ec2 describe-instances \
    --instance-ids <instance_id> \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId'

# Create snapshot
aws ec2 create-snapshot \
    --volume-id <volume_id> \
    --description "PostgreSQL data backup $(date +%Y-%m-%d)"
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check container health
docker-compose ps

# View health details
docker inspect --format='{{.State.Health.Status}}' postgres_db
```

### Log Monitoring

```bash
# Real-time logs
docker-compose logs -f

# PostgreSQL specific
docker-compose logs -f postgres

# Last 100 lines
docker-compose logs --tail=100 postgres
```

### Performance Monitoring

```bash
# Container resource usage
docker stats

# PostgreSQL connections
docker-compose exec postgres psql -U postgres -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Cache hit ratio
docker-compose exec postgres psql -U postgres -c "SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit) as heap_hit, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;"
```

## Troubleshooting

### PostgreSQL Won't Start

```bash
# Check logs
docker-compose logs postgres

# Common issues:
# 1. Port already in use
netstat -tulpn | grep 5432

# 2. Data directory permissions
docker-compose down -v  # Remove volume
docker-compose up -d    # Recreate
```

### Can't Connect to Database

```bash
# Verify container is running
docker-compose ps

# Test connection from EC2
docker-compose exec postgres pg_isready -U postgres

# Check network connectivity
docker-compose exec postgres ping pgadmin
```

### PgAdmin Not Accessible

```bash
# Verify PgAdmin container
docker-compose ps pgadmin

# Check port forwarding
netstat -tulpn | grep 5050

# Check security group (AWS)
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# If needed, expand EBS volume
# See AWS documentation for resizing EBS volumes
```

## Scaling Up

### Local to AWS Migration

If you outgrow the local setup:

```bash
# 1. Export data
docker-compose exec postgres pg_dump -Fc -U postgres myapp_db > production_backup.dump

# 2. Provision AWS RDS (more managed option)
# Or increase EC2 instance size:
# Edit terraform.tfvars: instance_type = "t3.medium"
# terraform apply

# 3. Restore data
docker-compose exec -T postgres pg_restore -U postgres -d myapp_db < production_backup.dump
```

### Database Optimization

```bash
# Regular maintenance
docker-compose exec postgres psql -U postgres -c "VACUUM ANALYZE;"

# Monitor slow queries
docker-compose exec postgres psql -U postgres -c "
  ALTER DATABASE myapp_db SET log_min_duration_statement = 1000;
"

# Check slow query logs
docker-compose logs postgres | grep "duration:"
```

## Cost Optimization (AWS)

### Reduce Costs
- Use t3.nano or t2 instances for development
- Stop instance when not in use: `aws ec2 stop-instances --instance-ids <id>`
- Delete unused snapshots and volumes
- Use spot instances for non-critical environments

### Cost Monitoring
```bash
aws ce get-cost-and-usage \
    --time-period Start=2024-01-01,End=2024-01-31 \
    --granularity DAILY \
    --metrics "UnblendedCost"
```

## Cleanup

### Local Cleanup
```bash
# Stop and remove containers
docker-compose down

# Remove volumes (delete data!)
docker-compose down -v

# Remove images
docker rmi postgres:16-alpine dpage/pgadmin4:latest
```

### AWS Cleanup
```bash
cd terraform

# Review what will be deleted
terraform plan -destroy

# Delete all resources
terraform destroy

# Confirm by typing 'yes'
```

## Security Checklist

- [ ] Change default database passwords
- [ ] Restrict SSH access to your IP (use IP/32)
- [ ] Restrict PgAdmin access in production
- [ ] Enable encryption for EBS volumes
- [ ] Use AWS Secrets Manager for credentials
- [ ] Enable CloudWatch monitoring
- [ ] Set up regular backups
- [ ] Implement database user permissions
- [ ] Use SSL/TLS for remote connections
- [ ] Regular security updates and patching

## Support and Further Learning

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Administration](https://www.postgresql.org/docs/current/admin.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [PgAdmin Documentation](https://www.pgadmin.org/docs/)
- [AWS Best Practices](https://aws.amazon.com/architecture/best-practices/)
