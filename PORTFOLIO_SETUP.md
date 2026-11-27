# Portfolio Setup Guide

## Publish this project

1. Create a GitHub repository named `postgres-docker-lab`.
2. Initialize Git locally and add the repository as a remote.
3. Ensure `.env` and other secrets are not tracked.
4. Commit and push the project.

```bash
git init
git add .
git status
git commit -m "Add PostgreSQL Docker lab"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/postgres-docker-lab.git
git push -u origin main
```

**Suggested technologies:** Docker Compose, PostgreSQL, SQL, Bash, Make.

## Portfolio description

This project demonstrates local multi-container orchestration with PostgreSQL and PgAdmin, persistent database storage, initialization SQL, health checks, operational scripts, and database backup/restore workflows.
