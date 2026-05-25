#!/bin/bash
set -e

echo "==> Waiting for PostgreSQL..."
until pg_isready -h localhost -U postgres; do
  sleep 1
done

echo "==> Waiting for Redis..."
until redis-cli -h localhost ping 2>/dev/null | grep -q PONG; do
  sleep 1
done

echo "==> Setting up database..."
npx nx run twenty-server:database:init 2>/dev/null || echo "DB already initialized"

echo "==> Starting Twenty CRM..."
echo ""
echo "  Server:   http://localhost:3000"
echo "  Frontend: http://localhost:3001"
echo ""
echo "  Run manually if needed:"
echo "    npx nx start twenty-server"
echo "    npx nx start twenty-front"
echo ""

# Start server + frontend concurrently
npx concurrently --kill-others \
  "npx nx start twenty-server" \
  "npx nx start twenty-front"
