
.PHONY: security-roles audit-enable performance

security-roles: ## Apply optional least-privilege group role grants
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < security/setup_roles.sql

 audit-enable: ## Install row-change audit triggers for users, products, and orders
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < security/enable_auditing.sql

performance: ## Run read-only PostgreSQL performance/statistics checks
	docker-compose exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -U "$$POSTGRES_USER" -d "$$POSTGRES_DB"' < monitoring/performance.sql
