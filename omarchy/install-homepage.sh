#!/bin/sh
# install-homepage.sh
# Runs Homepage (personal dashboard) as a Docker container on port 4000
# Idempotent: checks if container already running before starting
# Config lives in dotfiles: homepage/.config/homepage/ (stowed by install-dotfiles.sh)
# Access at: http://localhost:4000
# Docs: https://gethomepage.dev

CONTAINER_NAME="homepage"
CONFIG_DIR="$HOME/.config/homepage"

if ! command -v docker &> /dev/null; then
  echo "Docker not found. Install docker first."
  exit 1
fi

# Stop and remove old glance container if it exists (switching from glance)
if docker ps -a --format '{{.Names}}' | grep -q "^glance$"; then
  echo "Stopping old Glance container (keeping config, just disabling container)..."
  docker stop glance 2>/dev/null || true
fi

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Homepage container already exists. Starting if stopped..."
  docker start "$CONTAINER_NAME" 2>/dev/null || true
else
  echo "Creating and starting Homepage container..."
  docker run -d \
    -p 4000:3000 \
    -e HOMEPAGE_ALLOWED_HOSTS=localhost:4000 \
    --add-host=host.docker.internal:host-gateway \
    -v "$CONFIG_DIR:/app/config" \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    ghcr.io/gethomepage/homepage:latest
fi

echo "Homepage running at http://localhost:4000"
