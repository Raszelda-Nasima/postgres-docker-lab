# Portfolio Setup Guide

## 🎓 Getting Your Lab on GitHub

### Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `postgres-docker-lab` (or similar)
3. Description: "PostgreSQL & Docker lab for systems engineer portfolio"
4. Add README: ✓ (we already have one)
5. Add .gitignore: ✓ (we already have one)
6. Choose a License: MIT (recommended for portfolio)

### Step 2: Initialize Git Locally

```bash
cd C:\Users\A270505\postgres-docker-lab

# Initialize git
git init

# Configure user
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Or configure globally
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Step 3: Commit and Push

```bash
# Add all files
git add .

# Check what's being committed
git status

# Commit with message
git commit -m "Initial commit: PostgreSQL Docker lab with Terraform deployment

- Multi-container Docker Compose setup with PostgreSQL and PgAdmin
- Terraform infrastructure as code for AWS EC2 deployment
- Complete documentation and deployment guides
- Database initialization scripts with sample schema
- Convenience Makefile for common operations"

# Add remote
git remote add origin https://github.com/YOUR_USERNAME/postgres-docker-lab.git

# Create main branch and push
git branch -M main
git push -u origin main
```

### Step 4: Add to Your Portfolio Website

**Example README section for your portfolio:**

```markdown
## PostgreSQL Docker Lab
**Technologies**: Docker, PostgreSQL, Terraform, AWS, Linux

A production-ready containerized PostgreSQL environment demonstrating:
- Docker multi-container orchestration with health checks
- PostgreSQL database administration with sample schema
- Infrastructure as Code (Terraform) for AWS EC2 deployment
- VPC networking, security groups, and best practices
- Complete deployment automation and documentation

[View on GitHub](https://github.com/YOUR_USERNAME/postgres-docker-lab)
```

---

