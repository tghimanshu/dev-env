#!/usr/bin/env bash
# install-caddy.sh
# Runs Caddy as a Docker container — reverse proxy for all hub.home services.
# Idempotent: safe to run multiple times.
#
# What this does:
#   1. Stows the Caddyfile from dotfiles (falls back to a built-in default if missing)
#   2. Recreates the Caddy container on host networking so localhost upstreams work reliably
#
# Prerequisites:
#   - AdGuard Home should publish its web UI on host port 3100
#   - AdGuard DNS rewrite *.hub.home → <LAN IP> must be active for hostnames to resolve
#
# Services proxied:
#   hub.home          → python startpage (host:4000)
#   webui.hub.home    → Open WebUI on host (port 3000)
#   adguard.hub.home  → AdGuard Home on host port 3100
#   ollama.hub.home   → ollama on host (port 11434)
#
# To revert: docker stop caddy && docker rm caddy
#
# Docs: https://caddyserver.com/docs/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="caddy"
CADDY_CONFIG_DIR="$HOME/.config/caddy"
DOTFILES_CADDY="$HOME/personal/dotfiles/caddy"
IMAGE="caddy:latest"

if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker not found. Install docker first."
  exit 1
fi

# ── 1. Stow or generate Caddyfile ────────────────────────────────────────────

mkdir -p "$CADDY_CONFIG_DIR"

if [ -d "$DOTFILES_CADDY" ] && command -v stow > /dev/null 2>&1; then
  echo "Stowing Caddy config from dotfiles..."
  stow --restow -t ~ -d "$HOME/personal/dotfiles" caddy
elif [ ! -f "$CADDY_CONFIG_DIR/Caddyfile" ]; then
  echo "WARNING: dotfiles/caddy not found. Writing a default Caddyfile..."
  cat > "$CADDY_CONFIG_DIR/Caddyfile" <<'CADDYFILE'
{
    auto_https off
    admin localhost:2019
}

http://hub.home {
    reverse_proxy 127.0.0.1:4000
}

http://webui.hub.home {
    reverse_proxy 127.0.0.1:3000
}

http://adguard.hub.home {
    reverse_proxy 127.0.0.1:3100
}

http://ollama.hub.home {
    reverse_proxy 127.0.0.1:11434
}
CADDYFILE
  echo "  Written: $CADDY_CONFIG_DIR/Caddyfile"
  echo "  (Run install-dotfiles.sh to replace with the managed Caddyfile from dotfiles)"
else
  echo "Caddyfile already exists — leaving as-is."
fi

if [ ! -f "$CADDY_CONFIG_DIR/Caddyfile" ]; then
  echo "ERROR: $CADDY_CONFIG_DIR/Caddyfile not found. Cannot continue."
  exit 1
fi

# ── 2. Determine if Caddy needs to be (re)created ────────────────────────────
# Always recreate to pick up any Caddyfile changes (Caddy config is bind-mounted).
# This is safe: Caddy has no state of its own that we care about; certs/data use
# named Docker volumes (caddy-data, caddy-config) that persist across recreates.

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping and removing existing Caddy container to apply latest config..."
  docker stop "$CONTAINER_NAME" 2>/dev/null || true
  docker rm   "$CONTAINER_NAME" 2>/dev/null || true
fi

# ── 3. Create Caddy container ─────────────────────────────────────────────────

echo "Creating Caddy container..."
docker run -d \
  --name "$CONTAINER_NAME" \
  --network host \
  -v "$CADDY_CONFIG_DIR/Caddyfile:/etc/caddy/Caddyfile:ro" \
  -v caddy-data:/data \
  -v caddy-config:/config \
  --restart unless-stopped \
  "$IMAGE"

if docker ps --format '{{.Names}}' | grep -q '^adguard$'; then
  if ! docker inspect adguard --format '{{json .NetworkSettings.Ports}}' | grep -q '3100/tcp'; then
    echo "WARNING: AdGuard is running but host port 3100 is not published."
    echo "         adguard.hub.home will return 502 until AdGuard is recreated correctly."
  fi
fi

if ! getent hosts hub.home >/dev/null 2>&1; then
  echo "WARNING: hub.home names do not resolve on this machine yet."
  echo "         Run: sudo bash $SCRIPT_DIR/install-hub-hosts.sh"
fi

echo ""
echo "Caddy is running on port 80."
echo ""
echo "Services (once AdGuard DNS rewrites for *.hub.home are active):"
echo "  http://hub.home          → startpage"
echo "  http://webui.hub.home    → Open WebUI (LLM chat)"
echo "  http://adguard.hub.home  → AdGuard Home"
echo "  http://ollama.hub.home   → Ollama API"
echo ""
echo "Direct port access (always works, no DNS needed):"
echo "  http://localhost:3000    → Open WebUI"
echo "  http://localhost:3100    → AdGuard Home"
echo "  http://localhost:4000    → startpage"
