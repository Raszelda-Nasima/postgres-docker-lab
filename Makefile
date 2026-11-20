.PHONY: help up down logs ps exec-db exec-admin shell-db shell-admin clean restart status health-check init destroy

help: ## Show this help message
	@echo "PostgreSQL Docker Lab - Available Commands"
	@echo "==========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Docker Compose Commands
up: ## Start all services
	docker-compose up -d
	@echo "✓ Services started"
	@make status

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart
	@make status

ps: status

status: ## Show status of running services
	@docker-compose ps
	@echo ""
	@echo "Service URLs:"
	@echo "  PostgreSQL:  localhost:5432"
	@echo "  PgAdmin:     http://localhost:5050"

logs: ## Show logs from all services (follow mode)
	docker-compose logs -f

logs-db: ## Show PostgreSQL logs
	docker-compose logs -f postgres

logs-admin: ## Show PgAdmin logs
	docker-compose logs -f pgadmin

# Database Access
exec-db: ## Open PostgreSQL psql shell
	docker-compose exec postgres psql -U postgres -d myapp_db

exec-admin: ## Open PostgreSQL as admin
	docker-compose exec postgres psql -U postgres

shell-db: ## Open bash shell in PostgreSQL container
	docker-compose exec postgres /bin/sh

shell-admin: ## Open bash shell as admin
	docker-compose exec postgres /bin/bash

query: ## Execute a SQL query (usage: make query SQL="SELECT * FROM users;")
	docker-compose exec -T postgres psql -U postgres -d myapp_db -c "$(SQL)"

# Maintenance
init: ## Initialize/reinitialize database
	docker-compose down -v
	docker-compose up -d
	@echo "✓ Database reinitialized"

clean: ## Clean up containers, volumes, and images
	docker-compose down -v
	docker system prune -f
	@echo "✓ Cleanup complete"

backup: ## Backup database to SQL file
	@mkdir -p backups
	docker-compose exec -T postgres pg_dump -U postgres myapp_db > backups/db_backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✓ Database backed up to backups/db_backup_$$(date +%Y%m%d_%H%M%S).sql"

restore: ## Restore database from backup (usage: make restore BACKUP=backups/db_backup_20231119_120000.sql)
	@if [ -z "$(BACKUP)" ]; then \
		echo "Usage: make restore BACKUP=path/to/backup.sql"; \
		exit 1; \
	fi
	docker-compose exec -T postgres psql -U postgres -d myapp_db < $(BACKUP)
	@echo "✓ Database restored from $(BACKUP)"

health-check: ## Check health of PostgreSQL container
	@echo "PostgreSQL Health Status:"
	@docker inspect --format='{{.State.Health.Status}}' postgres_db
	@docker-compose exec -T postgres pg_isready -U postgres

# System Information
stats: ## Show container resource usage
	docker stats

size: ## Show disk usage of containers and volumes
	@echo "Container sizes:"
	@docker-compose ps --format "table {{.Service}}\t{{.State}}" | head -n 1
	@echo ""
	@echo "Volume usage:"
	@docker volume ls | grep postgres-docker-lab || echo "No volumes found"

version: ## Show versions of Docker and Docker Compose
	@echo "Docker version:"
	@docker --version
	@echo "Docker Compose version:"
	@docker-compose --version

# Database Operations
users: ## List all users in the database
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT * FROM users;"

products: ## List all products
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT * FROM products;"

tables: ## List all tables
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "\dt"

schema: ## Show database schema
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "\d"

connections: ## Show active connections
	@docker-compose exec -T postgres psql -U postgres -c "SELECT datname, count(*) as connections FROM pg_stat_activity GROUP BY datname;"

cache-ratio: ## Show cache hit ratio
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT sum(heap_blks_read) as heap_read, sum(heap_blks_hit) as heap_hit, sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) as ratio FROM pg_statio_user_tables;"

# AWS/Terraform Commands
tf-init: ## Initialize Terraform
	cd terraform && terraform init

tf-plan: ## Plan Terraform deployment
	cd terraform && terraform plan -out=tfplan

tf-apply: ## Apply Terraform deployment
	cd terraform && terraform apply tfplan

tf-destroy: ## Destroy AWS resources
	cd terraform && terraform destroy

tf-output: ## Show Terraform outputs
	cd terraform && terraform output

# Development Utilities
dev-logs: ## Show real-time combined logs with timestamps
	docker-compose logs -f --timestamps

prune: ## Remove unused Docker resources
	@echo "Pruning Docker system..."
	docker system prune -f
	docker volume prune -f
	@echo "✓ Pruned unused Docker resources"

freeze: ## Export Docker environment to freeze.txt
	@echo "Docker Compose freeze:"
	docker-compose images
	@echo "" > freeze.txt
	docker-compose images >> freeze.txt
	@echo "✓ Frozen to freeze.txt"

test: ## Run basic connectivity tests
	@echo "Testing PostgreSQL connectivity..."
	@docker-compose exec -T postgres pg_isready -U postgres && echo "✓ PostgreSQL is running" || echo "✗ PostgreSQL failed"
	@docker-compose exec -T postgres psql -U postgres -d myapp_db -c "SELECT 1;" > /dev/null 2>&1 && echo "✓ Can connect to database" || echo "✗ Cannot connect"
	@docker-compose exec -T postgres psql -U postgres -d myapp_db -c "SELECT COUNT(*) FROM users;" > /dev/null 2>&1 && echo "✓ Can query database" || echo "✗ Cannot query"

.DEFAULT_GOAL := help
