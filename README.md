# PostgreSQL & Docker Lab Project

A containerized PostgreSQL database environment for learning Docker, Linux systems administration, and database management.

## Project Structure

```
postgres-docker-lab/
├── docker-compose.yml      # Docker Compose configuration 
├── .env.example            # Environment variables template
├── init-scripts/           # Database initialization scripts
│   └── 01-init-db.sql     # Initial database schema
├── Makefile               # Convenience commands
├── terraform/             # Infrastructure as Code (AWS)
│   ├── main.tf           # EC2 instance configuration
│   ├── variables.tf      # Input variables
│   └── outputs.tf        # Outputs
└── docs/                  # Documentation
    ├── ARCHITECTURE.md    # System design
    └── DEPLOYMENT.md      # Deployment guide
``` 

## Quick Start (Local)

### Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose v2+
- 2GB free disk space
- Port 5432 and 5050 available

### Setup Steps

1. **Clone or navigate to the project**
   ```bash
   cd postgres-docker-lab
   ```

2. **Create environment file**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials if needed
   ```

3. **Start the services**
   ```bash
   docker-compose up -d
   ```

4. **Verify containers are running**
   ```bash
   docker-compose ps
   docker-compose logs postgres
   ```

5. **Connect to PostgreSQL**
   ```bash
   # Using psql
   docker-compose exec postgres psql -U postgres -d myapp_db
   
   # Or access via PgAdmin at http://localhost:5050
   ```

## Key Features Demonstrated

✅ **Docker Containerization**
- Multi-container orchestration with Docker Compose
- Volume management for persistent data
- Environment variable configuration
- Health checks and service dependencies
- Logging configuration with rotation

✅ **Linux & Database Skills**
- PostgreSQL database administration
- Database initialization scripts
- User and permission management
- PgAdmin web interface for GUI management

✅ **DevOps & Systems Engineering**
- Infrastructure as Code (Terraform)
- Network isolation with Docker networks
- Health monitoring and restart policies
- Production-ready configurations

## Available Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f postgres

# Access PostgreSQL CLI
docker-compose exec postgres psql -U postgres

# View running containers
docker-compose ps

# Remove data volumes (caution!)
docker-compose down -v

# Rebuild containers
docker-compose build --no-cache
```

## Accessing Services

- **PostgreSQL**: `localhost:5432`
  - User: `postgres`
  - Password: (see `.env` file)
  - Database: `myapp_db`

- **PgAdmin**: `http://localhost:5050`
  - Email: `admin@example.com`
  - Password: `admin`

## AWS Deployment (EC2)

For production deployment on AWS:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

See `docs/DEPLOYMENT.md` for detailed AWS setup instructions.

## Learning Outcomes

By completing this project, you'll understand:

1. **Docker**: Image layers, containers, networking, volumes, compose orchestration
2. **Linux**: File systems, permissions, package management, systemd services
3. **PostgreSQL**: Database initialization, user management, backup/restore
4. **IaC**: Terraform, AWS EC2, security groups, IAM roles
5. **DevOps**: CI/CD concepts, monitoring, logging, disaster recovery

## Production Considerations

For a real deployment:
- Use AWS Secrets Manager for credentials
- Configure RDS instead of self-managed PostgreSQL
- Set up automated backups
- Implement monitoring with CloudWatch
- Use VPC with private subnets
- Enable encryption at rest and in transit
- Set up auto-scaling groups
- Implement load balancing

## Troubleshooting

**Port already in use**
```bash
docker-compose down
# Change ports in docker-compose.yml or:
docker-compose -f docker-compose.yml up -d
```

**Database won't connect**
```bash
docker-compose logs postgres
docker-compose restart postgres
```

**Permission denied on volumes**
```bash
# On Linux, may need:
sudo chown -R 999:999 postgres_data/
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Official Docs](https://www.postgresql.org/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [PgAdmin Documentation](https://www.pgadmin.org/docs/)

## Author

Raszelda Sharon Nasima - Systems Engineer Portfolio Project
