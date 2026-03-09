#!/usr/bin/env bash
# install-adguard.sh
# Runs AdGuard Home in Docker using host networking with the web UI on port 3100.
# Idempotent: safe to run multiple times.
#
# What this does:
#   1. Creates persistent config and data directories
#   2. Recreates the container only when it does not match the desired setup
#   3. Starts AdGuard Home with DNS on port 53 and the admin UI on port 3100
#
# Notes:
#   - Port 53 must be free on the host before AdGuard can start
#   - Initial setup is available at http://localhost:3100
#   - Caddy can proxy this at http://adguard.hub.home after DNS rewrites are set

set -euo pipefail

CONTAINER_NAME="adguard"
LEGACY_CONTAINER_NAME="adguardhome"
IMAGE="adguard/adguardhome"
WORK_DIR="$HOME/.local/share/adguardhome/work"
CONF_DIR="$HOME/.config/adguardhome"
WEB_ADDR="0.0.0.0:3100"

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

legacy_container_exists() {
  docker ps -a --format '{{.Names}}' | grep -q "^${LEGACY_CONTAINER_NAME}$"
}

container_needs_recreate() {
  if ! container_exists; then
    return 0
  fi

  local network_mode image restart_policy args mounts

  network_mode="$(docker inspect "$CONTAINER_NAME" --format '{{.HostConfig.NetworkMode}}' 2>/dev/null || true)"
  image="$(docker inspect "$CONTAINER_NAME" --format '{{.Config.Image}}' 2>/dev/null || true)"
  restart_policy="$(docker inspect "$CONTAINER_NAME" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || true)"
  args="$(docker inspect "$CONTAINER_NAME" --format '{{range .Args}}{{println .}}{{end}}' 2>/dev/null || true)"
  mounts="$(docker inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{printf "%s:%s\n" .Source .Destination}}{{end}}' 2>/dev/null || true)"

  [ "$network_mode" = "host" ] || return 0
  [ "$restart_policy" = "unless-stopped" ] || return 0

  case "$image" in
    "$IMAGE"|"$IMAGE:latest") ;;
    *) return 0 ;;
  esac

  printf '%s\n' "$args" | grep -qx -- '--no-check-update' || return 0
  printf '%s\n' "$args" | grep -qx -- '--web-addr' || return 0
  printf '%s\n' "$args" | grep -qx -- "$WEB_ADDR" || return 0
  printf '%s\n' "$mounts" | grep -Fqx -- "$WORK_DIR:/opt/adguardhome/work" || return 0
  printf '%s\n' "$mounts" | grep -Fqx -- "$CONF_DIR:/opt/adguardhome/conf" || return 0

  return 1
}

show_port_53_hint() {
  if ss -H -ltnup 2>/dev/null | grep -q '127.0.0.53:53'; then
    echo ""
    echo "Hint: systemd-resolved appears to be holding port 53 on 127.0.0.53."
    echo "Disable DNSStubListener before running AdGuard Home on the host."
  fi
}

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker not found. Install docker first."
  exit 1
fi

mkdir -p "$WORK_DIR" "$CONF_DIR"

FIRST_RUN=false
if [ ! -f "$CONF_DIR/AdGuardHome.yaml" ]; then
  FIRST_RUN=true
fi

if legacy_container_exists; then
  echo "Stopping legacy ${LEGACY_CONTAINER_NAME} container to avoid port conflicts..."
  docker stop "$LEGACY_CONTAINER_NAME" >/dev/null 2>&1 || true
fi

if container_needs_recreate; then
  if container_exists; then
    echo "Recreating AdGuard container to apply the desired config..."
    docker rm -f "$CONTAINER_NAME" >/dev/null
  else
    echo "Creating AdGuard container..."
  fi

  docker run -d \
    --name "$CONTAINER_NAME" \
    --network host \
    -v "$WORK_DIR:/opt/adguardhome/work" \
    -v "$CONF_DIR:/opt/adguardhome/conf" \
    --restart unless-stopped \
    "$IMAGE" \
    --no-check-update \
    --web-addr "$WEB_ADDR" >/dev/null
else
  echo "AdGuard container already matches desired config - ensuring it is running."
  docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

sleep 3

if ! container_running; then
  echo "ERROR: AdGuard container is not running. Recent logs:"
  docker logs --tail 100 "$CONTAINER_NAME" 2>/dev/null || true
  show_port_53_hint
  exit 1
fi

echo ""
echo "AdGuard Home is running."
echo "  Admin UI : http://localhost:3100"
echo "  DNS      : port 53 on the host"
echo "  Config   : $CONF_DIR"
echo "  Data     : $WORK_DIR"

if [ "$FIRST_RUN" = true ]; then
  echo ""
  echo "First run detected. Complete the AdGuard setup wizard at http://localhost:3100"
  echo "After setup, add DNS rewrites for hub.home and *.hub.home to your LAN IP if you want hub.home URLs to resolve across your network."
fi
