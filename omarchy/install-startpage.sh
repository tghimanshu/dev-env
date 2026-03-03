#!/usr/bin/env bash
# install-startpage.sh
# Serves the custom HTML startpage at http://localhost:4000 as a systemd user service.
# Idempotent: safe to run multiple times.
#
# What this does:
#   0. Ensures ~/.config/startpage exists — stows from ~/personal/dotfiles if missing
#   1. Stops and removes the Glance Docker container if running (no longer needed)
#   2. Installs the systemd user service: lifeos-startpage.service
#      - Runs: python3 -m http.server 4000 --directory ~/.config/startpage
#      - Starts on login, restarts automatically
#   3. Enables and starts the service
#
# Prereqs: python3 (always present on Arch), systemd user session
# Startpage config: ~/personal/dotfiles/startpage/.config/startpage/index.html
# Stowed to: ~/.config/startpage/ by install-dotfiles.sh
# Docs: ~/personal/claude-code-daily/README.md

set -e

SERVICE_NAME="lifeos-startpage"
SERVICE_FILE="$HOME/.config/systemd/user/${SERVICE_NAME}.service"
STARTPAGE_DIR="$HOME/.config/startpage"
DOTFILES_STARTPAGE="$HOME/personal/dotfiles/startpage"

# ── 0. Ensure startpage is stowed from dotfiles ────────────────────────────────

if [ ! -d "$STARTPAGE_DIR" ]; then
  if [ -d "$DOTFILES_STARTPAGE" ] && command -v stow > /dev/null 2>&1; then
    echo "~/.config/startpage not found — stowing from dotfiles..."
    stow -t ~ -d "$HOME/personal/dotfiles" startpage
    echo "Stowed startpage to ~/.config/startpage"
  else
    echo "ERROR: ~/.config/startpage does not exist."
    echo "Run install-dotfiles.sh first, or manually stow: stow -t ~ -d ~/personal/dotfiles startpage"
    exit 1
  fi
fi

# ── 1. Stop & remove Glance container if present ───────────────────────────────

if command -v docker > /dev/null 2>&1; then
  if docker ps -a --format '{{.Names}}' | grep -q "^glance$"; then
    echo "Stopping and removing Glance container (replaced by custom startpage)..."
    docker stop glance > /dev/null 2>&1 || true
    docker rm   glance > /dev/null 2>&1 || true
    echo "Glance container removed."
  else
    echo "Glance container not present — skipping."
  fi
fi

# ── 2. Write systemd user service (only if content changed) ───────────────────

mkdir -p "$HOME/.config/systemd/user"

DESIRED_SERVICE="[Unit]
Description=LifeOS Startpage — custom HTML dashboard served on port 4000
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server 4000 --directory ${STARTPAGE_DIR}
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target"

if [ ! -f "$SERVICE_FILE" ] || [ "$DESIRED_SERVICE" != "$(cat "$SERVICE_FILE")" ]; then
  printf '%s\n' "$DESIRED_SERVICE" > "$SERVICE_FILE"
  echo "Wrote $SERVICE_FILE"
  SERVICE_CHANGED=true
else
  echo "Service file unchanged — skipping write."
  SERVICE_CHANGED=false
fi

# ── 3. Enable and (re)start the service ────────────────────────────────────────

systemctl --user enable "$SERVICE_NAME"

if [ "$SERVICE_CHANGED" = true ]; then
  systemctl --user daemon-reload
  systemctl --user restart "$SERVICE_NAME"
else
  # Ensure it's running in case it was stopped, but don't restart if healthy
  if ! systemctl --user is-active --quiet "$SERVICE_NAME"; then
    systemctl --user start "$SERVICE_NAME"
  else
    echo "Service already running — skipping restart."
  fi
fi

sleep 1

if systemctl --user is-active --quiet "$SERVICE_NAME"; then
  echo "lifeos-startpage.service is running."
  echo "Startpage available at http://localhost:4000"
else
  echo "WARNING: lifeos-startpage.service failed to start."
  echo "Check: systemctl --user status $SERVICE_NAME"
  exit 1
fi
