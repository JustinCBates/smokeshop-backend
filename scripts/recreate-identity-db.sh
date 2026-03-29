#!/usr/bin/env bash

set -euo pipefail

ENV_FILE="${1:-.env.postgres.local}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing env file: $ENV_FILE" >&2
  exit 1
fi

compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    docker compose -f docker-compose.postgres.yml --env-file "$ENV_FILE" "$@"
  elif command -v docker-compose >/dev/null 2>&1; then
    docker-compose -f docker-compose.postgres.yml --env-file "$ENV_FILE" "$@"
  else
    echo "Docker Compose is not installed." >&2
    exit 1
  fi
}

echo "Recreating smokeshop Postgres volume and container..."
compose_cmd down -v
compose_cmd up -d

echo "Waiting for database to become healthy..."
for _ in {1..30}; do
  if compose_cmd exec -T postgres pg_isready -U smokeshop_user -d smokeshop >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

compose_cmd exec -T postgres psql -U smokeshop_user -d smokeshop -c "SELECT PostGIS_Version();"
compose_cmd exec -T postgres psql -U smokeshop_user -d smokeshop -c "\dt auth.*"
compose_cmd exec -T postgres psql -U smokeshop_user -d smokeshop -c "\dt public.*"

echo "Database recreated with PostGIS and identity tables only."