#!/bin/bash
set -e

echo "Starting EC2 initialization..."

# Update system packages
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose standalone
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional useful tools
sudo apt-get install -y \
    git \
    htop \
    curl \
    wget \
    jq \
    postgresql-client

# Create application directory
sudo mkdir -p /opt/postgres-lab
sudo chown ubuntu:ubuntu /opt/postgres-lab
cd /opt/postgres-lab

# Create docker-compose.yml
cat > docker-compose.yml <<'COMPOSE_EOF'
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    container_name: postgres_db
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    networks:
      - postgres_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
      SCRIPT_NAME: /pgadmin
    ports:
      - "5050:80"
    networks:
      - postgres_network
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"

volumes:
  postgres_data:
    driver: local

networks:
  postgres_network:
    driver: bridge
COMPOSE_EOF

# Create .env file
cat > .env <<ENV_EOF
DB_USER=${db_user}
DB_PASSWORD=${db_password}
DB_NAME=${db_name}
ENV_EOF

# Create init-scripts directory
mkdir -p init-scripts

# Create initialization script
cat > init-scripts/01-init-db.sql <<'SQL_EOF'
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email) VALUES
    ('admin', 'admin@example.com'),
    ('user1', 'user1@example.com')
ON CONFLICT DO NOTHING;

INSERT INTO products (name, price) VALUES
    ('Product 1', 29.99),
    ('Product 2', 49.99)
ON CONFLICT DO NOTHING;
SQL_EOF

# Fix permissions
chmod 600 .env

# Start Docker containers
echo "Starting Docker containers..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U ${db_user} > /dev/null 2>&1; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Attempt $i/30: Waiting for PostgreSQL..."
    sleep 2
done

# Display status
echo "======================================"
echo "PostgreSQL Docker Lab is Ready!"
echo "======================================"
docker-compose ps

echo ""
echo "Services running on:"
echo "  PostgreSQL: localhost:5432"
echo "  PgAdmin: http://localhost:5050"
echo ""
echo "Connect to PostgreSQL:"
echo "  psql -h localhost -U ${db_user} -d ${db_name}"
echo ""
echo "Docker Compose commands:"
echo "  docker-compose logs -f            # View logs"
echo "  docker-compose ps                 # View services"
echo "  docker-compose restart postgres   # Restart PostgreSQL"
