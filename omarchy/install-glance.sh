#!/bin/sh
# install-glance.sh
# Runs Glance (personal dashboard) as a Docker container on port 4000
# Idempotent: checks if container already running before starting
# Config lives in dotfiles: glance/.config/glance/glance.yml (stowed by install-dotfiles.sh)
# Access at: http://localhost:4000
# Docs: https://github.com/glanceapp/glance

CONTAINER_NAME="glance"
CONFIG_DIR="$HOME/.config/glance"

if ! command -v docker &> /dev/null; then
  echo "Docker not found. Install docker first."
  exit 1
fi

# Stop and remove old dashy container if it exists
if docker ps -a --format '{{.Names}}' | grep -q "^dashy$"; then
  echo "Removing old Dashy container..."
  docker stop dashy 2>/dev/null || true
  docker rm dashy 2>/dev/null || true
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Glance container already exists. Starting if stopped..."
  docker start "$CONTAINER_NAME" 2>/dev/null || true
else
  echo "Creating and starting Glance container..."
  docker run -d \
    -p 4000:8080 \
    -v "$CONFIG_DIR:/app/config" \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    glanceapp/glance
fi

echo "Glance running at http://localhost:4000"
