
.PHONY: security-roles audit-enable performance backup restore

security-roles: ## Apply optional least-privilege group role grants
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < security/setup_roles.sql

 audit-enable: ## Install row-change audit triggers for users, products, and orders
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < security/enable_auditing.sql

performance: ## Run read-only PostgreSQL performance/statistics checks
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < monitoring/performance.sql

backup: ## Create a compressed backup and apply RETENTION_COUNT (default: 7)
	./backup-scripts/full_backup.sh

restore: ## Restore from BACKUP=path/to/full_backup.sql.gz (destructive)
	@if [ -z "$(BACKUP)" ]; then echo "Usage: make restore BACKUP=./backups/full_backup_YYYYMMDD_HHMMSS.sql.gz"; exit 1; fi
	./backup-scripts/restore_backup.sh "$(BACKUP)"
