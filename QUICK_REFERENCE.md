# Quick Reference Card

## 🏃 Quick Start Commands

```bash
# Local Setup
cd postgres-docker-lab
docker-compose up -d

# Check Status
docker-compose ps

# Access Database
docker-compose exec postgres psql -U postgres -d myapp_db

# View Logs
docker-compose logs -f postgres

# Stop Services
docker-compose down
```

## 📍 Service URLs (Local)

| Service | URL | Credentials |
|---------|-----|-------------|
| PostgreSQL | `localhost:5432` | User: `postgres` |
| PgAdmin | `http://localhost:5050` | admin@example.com / admin |

## 🔧 Using Make Commands

```bash
make up              # Start services
make down            # Stop services
make status          # Show running services
make logs            # View logs
make backup          # Backup database
make restore         # Restore database
make clean           # Clean everything
make help            # Show all commands
```

## AWS Deployment

```bash
# 1. Create SSH key
aws ec2 create-key-pair --key-name postgres-lab-key \
  --region us-east-1 --query 'KeyMaterial' \
  --output text > postgres-lab-key.pem

# 2. Configure
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars

# 3. Deploy
cd terraform
terraform init
terraform apply

# 4. Connect
ssh -i postgres-lab-key.pem ubuntu@$(terraform output -raw instance_public_ip)
```

## 📊 Database Operations

```sql
-- View all users
SELECT * FROM users;

-- View products
SELECT * FROM products;

-- Check table structure
\dt

-- View all tables
\d

-- Check connections
SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;
```

## 🐳 Docker Commands

```bash
# List containers
docker-compose ps

# View logs
docker-compose logs -f

# Execute command in container
docker-compose exec postgres psql -U postgres

# Stop everything
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild containers
docker-compose build --no-cache
```

## 📁 Project Structure

```
postgres-docker-lab/
├── docker-compose.yml      # Local setup
├── Makefile               # Commands
├── .env.example           # Configuration template
├── terraform/             # AWS deployment
│   ├── main.tf           # VPC, EC2, Security
│   ├── variables.tf      # Input variables
│   ├── outputs.tf        # Outputs
│   └── user_data.sh      # EC2 init script
├── docs/                 # Documentation
│   ├── ARCHITECTURE.md   # System design
│   └── DEPLOYMENT.md     # Deploy guide
└── init-scripts/         # DB initialization
    └── 01-init-db.sql    # Sample schema
```

## 🔐 Security Notes

| Item | Local | AWS Production |
|------|-------|-----------------|
| DB Password | .env file | AWS Secrets Manager |
| SSH Access | N/A | Restrict to your IP/32 |
| PgAdmin | No auth (dev) | VPN required |
| Data | Unencrypted (dev) | EBS encrypted |
| Backups | Manual | Automated snapshots |

## 🆘 Troubleshooting

**Port already in use**
```bash
docker-compose down
# Change port in docker-compose.yml or:
lsof -i :5432
```

**Can't connect to PostgreSQL**
```bash
docker-compose logs postgres
docker-compose restart postgres
```

**Permission denied on volumes**
```bash
# On Linux
sudo chown -R 999:999 postgres_data/
```

**Terraform apply fails**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Validate syntax
terraform validate

# Check state
terraform show
```

## 📖 Documentation

| File | Purpose |
|------|---------|
| README.md | Main documentation |
| docs/ARCHITECTURE.md | System design & components |
| docs/DEPLOYMENT.md | Detailed deployment guide |
| terraform/README.md | Terraform setup guide |
| Makefile | Command shortcuts |

## 💡 Tips

- Use `make help` for all available commands
- Check logs first: `docker-compose logs -f`
- Use `docker-compose exec -T` for scripts (non-interactive)
- Always test locally before deploying to AWS
- Keep `.env` file secure (not in git)
- Backup before major changes

