.PHONY: help up down logs logs-db logs-admin ps exec-db exec-admin shell-db shell-admin clean restart status health-check init backup restore query stats size version users products tables schema connections cache-ratio dev-logs prune freeze test

.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "PostgreSQL Docker Lab - Available Commands"
	@echo "==========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

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
	@echo "  PostgreSQL:  localhost:5433"
	@echo "  PgAdmin:     http://localhost:5050"

logs: ## Follow logs from all services
	docker-compose logs -f

logs-db: ## Follow PostgreSQL logs
	docker-compose logs -f postgres

logs-admin: ## Follow PgAdmin logs
	docker-compose logs -f pgadmin

exec-db: ## Open PostgreSQL psql shell
	docker-compose exec postgres psql -U postgres -d myapp_db

exec-admin: ## Open PostgreSQL as admin
	docker-compose exec postgres psql -U postgres

shell-db: ## Open shell in PostgreSQL container
	docker-compose exec postgres /bin/sh

shell-admin: ## Open bash shell in PostgreSQL container
	docker-compose exec postgres /bin/bash

query: ## Execute SQL (usage: make query SQL="SELECT * FROM users;")
	docker-compose exec -T postgres psql -U postgres -d myapp_db -c "$(SQL)"

init: ## Reinitialize database (deletes volume data)
	docker-compose down -v
	docker-compose up -d
	@echo "✓ Database reinitialized"

clean: ## Remove containers, volumes, and unused images
	docker-compose down -v
	docker system prune -f
	@echo "✓ Cleanup complete"

backup: ## Backup database to SQL file
	@mkdir -p backups
	docker-compose exec -T postgres pg_dump -U postgres myapp_db > backups/db_backup_$$(date +%Y%m%d_%H%M%S).sql
	@echo "✓ Database backup created"

restore: ## Restore database (usage: make restore BACKUP=path/to/file.sql)
	@if [ -z "$(BACKUP)" ]; then echo "Usage: make restore BACKUP=path/to/backup.sql"; exit 1; fi
	docker-compose exec -T postgres psql -U postgres -d myapp_db < $(BACKUP)
	@echo "✓ Database restored from $(BACKUP)"

health-check: ## Check PostgreSQL health
	@echo "PostgreSQL Health Status:"
	@docker inspect --format='{{.State.Health.Status}}' postgres_db
	@docker-compose exec -T postgres pg_isready -U postgres

stats: ## Show container resource usage
	docker stats

size: ## Show Docker volume usage
	@docker volume ls | grep postgres-docker-lab || echo "No volumes found"

version: ## Show Docker and Compose versions
	@docker --version
	@docker-compose --version

users: ## List database users
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT * FROM users;"

products: ## List products
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT * FROM products;"

tables: ## List tables
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "\\dt"

schema: ## Show database schema
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "\\d"

connections: ## Show active connections
	@docker-compose exec -T postgres psql -U postgres -c "SELECT datname, count(*) as connections FROM pg_stat_activity GROUP BY datname;"

cache-ratio: ## Show cache hit ratio
	@docker-compose exec -T postgres psql -U postgres myapp_db -c "SELECT sum(heap_blks_read) AS heap_read, sum(heap_blks_hit) AS heap_hit, round(sum(heap_blks_hit)::numeric / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 4) AS ratio FROM pg_statio_user_tables;"

dev-logs: ## Follow logs with timestamps
	docker-compose logs -f --timestamps

prune: ## Remove unused Docker resources
	docker system prune -f
	docker volume prune -f

freeze: ## Export Docker image list to freeze.txt
	@docker-compose images > freeze.txt
	@echo "✓ Frozen to freeze.txt"

test: ## Run basic connectivity tests
	@docker-compose exec -T postgres pg_isready -U postgres && echo "✓ PostgreSQL is running" || echo "✗ PostgreSQL failed"
	@docker-compose exec -T postgres psql -U postgres -d myapp_db -c "SELECT 1;" > /dev/null 2>&1 && echo "✓ Can connect to database" || echo "✗ Cannot connect"
	@docker-compose exec -T postgres psql -U postgres -d myapp_db -c "SELECT COUNT(*) FROM users;" > /dev/null 2>&1 && echo "✓ Can query database" || echo "✗ Cannot query"
