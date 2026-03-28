# PostgreSQL Setup on VPS with Docker

## Overview

This guide sets up PostgreSQL with PostGIS extension in a Docker container on your VPS (srv1407636.hstgr.cloud).

## Prerequisites

- Docker and Docker Compose installed on VPS
- SSH access to VPS
- Migration scripts in `scripts/` directory

## Step 1: Check Docker on VPS

```bash
# SSH to VPS
ssh -i C:\Users\justi\.ssh\id_ed25519_vps -p 22022 opsdf55jrdjxsadgh@srv1407636.hstgr.cloud

# Check Docker
docker --version
docker-compose --version

# If not installed:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes

# Install Docker Compose
sudo apt install -y docker-compose-plugin
```

## Step 2: Upload Docker Configuration

### Option A: From your local machine

```powershell
# Copy docker-compose file to VPS
scp -i C:\Users\justi\.ssh\id_ed25519_vps -P 22022 `
  docker-compose.postgres.yml `
  opsdf55jrdjxsadgh@srv1407636.hstgr.cloud:~/smokeshop/

# Copy scripts directory
scp -i C:\Users\justi\.ssh\id_ed25519_vps -P 22022 -r `
  scripts `
  opsdf55jrdjxsadgh@srv1407636.hstgr.cloud:~/smokeshop/
```

### Option B: Clone from GitHub on VPS

```bash
# On VPS
cd ~
git clone https://github.com/JustinCBates/Smokeshop.git smokeshop
cd smokeshop
```

## Step 3: Set PostgreSQL Password

```bash
# On VPS
cd ~/smokeshop

# Generate strong password
openssl rand -base64 32

# Create environment file
cat > .env.postgres.local << 'EOF'
POSTGRES_PASSWORD=paste_generated_password_here
EOF

chmod 600 .env.postgres.local
```

## Step 4: Start PostgreSQL Container

```bash
# Start container
docker-compose -f docker-compose.postgres.yml --env-file .env.postgres.local up -d

# Check status
docker ps
docker logs smokeshop_postgres

# Verify PostGIS is available
docker exec smokeshop_postgres psql -U smokeshop_user -d smokeshop -c "SELECT PostGIS_Version();"
```

## Step 5: Run Migration Scripts

The `000_full_migration.sql` script will be automatically executed on first container start from the `/docker-entrypoint-initdb.d` mount.

To manually run migrations:

```bash
# Copy migration script into container and execute
docker exec -i smokeshop_postgres psql -U smokeshop_user -d smokeshop < scripts/000_full_migration.sql

# Verify tables created
docker exec smokeshop_postgres psql -U smokeshop_user -d smokeshop -c "\dt"

# Check products table
docker exec smokeshop_postgres psql -U smokeshop_user -d smokeshop -c "SELECT COUNT(*) FROM products;"
```

## Step 6: Configure Firewall (if needed)

```bash
# Allow PostgreSQL port (only if needed for external connections)
sudo ufw allow 5432/tcp

# Or restrict to specific IP (your application server)
sudo ufw allow from 82.29.199.157 to any port 5432
```

## Step 7: Get Connection String

Your database is now available at:

**Internal (from VPS):**

```
postgresql://smokeshop_user:YOUR_PASSWORD@localhost:5432/smokeshop
```

**External (from Hostinger shared hosting):**

```
postgresql://smokeshop_user:YOUR_PASSWORD@187.77.212.203:5432/smokeshop
```

## Container Management

### Start/Stop Database

```bash
# Stop
docker-compose -f docker-compose.postgres.yml --env-file .env.postgres.local down

# Start
docker-compose -f docker-compose.postgres.yml --env-file .env.postgres.local up -d

# Restart
docker-compose -f docker-compose.postgres.yml --env-file .env.postgres.local restart
```

### Backup Database

```bash
# Backup to file
docker exec smokeshop_postgres pg_dump -U smokeshop_user smokeshop > backup_$(date +%Y%m%d).sql

# Restore from backup
docker exec -i smokeshop_postgres psql -U smokeshop_user smokeshop < backup_20260327.sql
```

### View Logs

```bash
docker logs smokeshop_postgres
docker logs -f smokeshop_postgres  # Follow logs
```

### Access PostgreSQL CLI

```bash
docker exec -it smokeshop_postgres psql -U smokeshop_user -d smokeshop
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker logs smokeshop_postgres

# Check if port is already in use (native PostgreSQL)
sudo systemctl stop postgresql
sudo systemctl disable postgresql
```

### Connection refused

```bash
# Check container is running
docker ps | grep smokeshop_postgres

# Check port mapping
docker port smokeshop_postgres

# Test connection from VPS
docker exec smokeshop_postgres psql -U smokeshop_user -d smokeshop -c "SELECT 1;"
```

### Permission issues

```bash
# Fix volume permissions
docker-compose -f docker-compose.postgres.yml down
sudo chown -R 999:999 postgres_data/
docker-compose -f docker-compose.postgres.yml --env-file .env.postgres.local up -d
```

## Security Notes

- PostgreSQL runs on port 5432 (standard port)
- Container restarts automatically on reboot
- Data persists in Docker volume `postgres_data`
- Password stored securely in `.env.postgres.local` (gitignored)
- Only expose port 5432 externally if needed (add firewall rules)
- Use SSL connections in production (configure pg_hba.conf)

## Next Steps

1. Update application `.env` with DATABASE_URL
2. Test connection from application
3. Seed sample data if needed
4. Set up regular backups
5. Monitor database performance
