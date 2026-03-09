#!/usr/bin/env bash
# install-ollama.sh
# Installs Ollama (local LLM runner) and Open WebUI (browser interface)
# Idempotent for the host-Ollama + localhost:3000 Open WebUI setup.
#
# Changes from original:
#   - Ollama is configured to listen on 0.0.0.0 (LAN-accessible) via OLLAMA_HOST env
#   - A user-level Ollama systemd service is created if missing
#   - Open WebUI runs on Docker host networking, but still serves on localhost:3000
#   - Open WebUI is explicitly pointed at the local Ollama API
#   - Caddy will proxy Open WebUI at http://webui.hub.home
#   - Caddy will proxy Ollama API at http://ollama.hub.home
#
# Access:
#   Local:   http://localhost:3000  (Open WebUI)
#   LAN:     http://webui.hub.home  (via Caddy, after AdGuard DNS setup)
#   API:     http://ollama.hub.home (via Caddy)

set -e

CONTAINER_NAME="open-webui"
OPEN_WEBUI_IMAGE="ghcr.io/open-webui/open-webui:main"
OLLAMA_UNIT_DIR="$HOME/.config/systemd/user"
OLLAMA_UNIT_FILE="$OLLAMA_UNIT_DIR/ollama.service"
OLLAMA_OVERRIDE_DIR="$OLLAMA_UNIT_DIR/ollama.service.d"
OLLAMA_OVERRIDE_FILE="$OLLAMA_OVERRIDE_DIR/override.conf"

ensure_ollama_unit() {
  mkdir -p "$OLLAMA_UNIT_DIR"

  local desired_unit
  desired_unit='[Unit]
Description=Ollama Service
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
Restart=always
RestartSec=3

[Install]
WantedBy=default.target'

  if [ ! -f "$OLLAMA_UNIT_FILE" ] || [ "$(cat "$OLLAMA_UNIT_FILE")" != "$desired_unit" ]; then
    printf '%s\n' "$desired_unit" > "$OLLAMA_UNIT_FILE"
    echo "Wrote Ollama user service: $OLLAMA_UNIT_FILE"
    OLLAMA_UNIT_CHANGED=true
  else
    echo "Ollama user service already present - skipping."
    OLLAMA_UNIT_CHANGED=false
  fi
}

ensure_open_webui_config() {
  docker exec "$CONTAINER_NAME" python - <<'PY'
import json
import sqlite3

conn = sqlite3.connect('/app/backend/data/webui.db')
cur = conn.cursor()
row = cur.execute('select id, data from config where id=1').fetchone()
if row is None:
    raise SystemExit('Open WebUI config row not found')

config = json.loads(row[1])
ollama = config.setdefault('ollama', {})
ollama['enable'] = True
ollama['base_urls'] = ['http://127.0.0.1:11434']
ollama['api_configs'] = {
    '0': {
        'enable': True,
        'tags': [],
        'prefix_id': '',
        'model_ids': [],
    }
}

cur.execute('update config set data=? where id=1', (json.dumps(config),))
conn.commit()
print('Open WebUI Ollama config updated')
PY
}

recreate_open_webui() {
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Removing existing Open WebUI container to apply desired config..."
    docker rm -f "$CONTAINER_NAME" >/dev/null
  fi

  echo "Creating Open WebUI container..."
  docker run -d \
    --name "$CONTAINER_NAME" \
    --network host \
    -e PORT=3000 \
    -e OLLAMA_BASE_URL=http://127.0.0.1:11434 \
    -v open-webui:/app/backend/data \
    --restart unless-stopped \
    "$OPEN_WEBUI_IMAGE" >/dev/null

  wait_for_open_webui
  ensure_open_webui_config >/dev/null
  docker restart "$CONTAINER_NAME" >/dev/null
}

open_webui_needs_recreate() {
  if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    return 0
  fi

  local network_mode
  local image
  local port_env
  local ollama_env
  local has_volume

  network_mode="$(docker inspect "$CONTAINER_NAME" --format '{{.HostConfig.NetworkMode}}' 2>/dev/null || true)"
  image="$(docker inspect "$CONTAINER_NAME" --format '{{.Config.Image}}' 2>/dev/null || true)"
  port_env="$(docker inspect "$CONTAINER_NAME" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^PORT=' || true)"
  ollama_env="$(docker inspect "$CONTAINER_NAME" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null | grep '^OLLAMA_BASE_URL=' || true)"
  has_volume="$(docker inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{printf "%s:%s\n" .Name .Destination}}{{end}}' 2>/dev/null | grep '^open-webui:/app/backend/data$' || true)"

  if [ "$network_mode" != "host" ]; then
    return 0
  fi
  if [ "$image" != "$OPEN_WEBUI_IMAGE" ]; then
    return 0
  fi
  if [ "$port_env" != "PORT=3000" ]; then
    return 0
  fi
  if [ "$ollama_env" != "OLLAMA_BASE_URL=http://127.0.0.1:11434" ]; then
    return 0
  fi
  if [ -z "$has_volume" ]; then
    return 0
  fi

  if ! docker exec "$CONTAINER_NAME" python - <<'PY' >/dev/null 2>&1
import json
import sqlite3

conn = sqlite3.connect('/app/backend/data/webui.db')
cur = conn.cursor()
row = cur.execute('select data from config where id=1').fetchone()
if row is None:
    raise SystemExit(1)

config = json.loads(row[0])
ollama = config.get('ollama', {})
if ollama.get('enable') is not True:
    raise SystemExit(1)
if ollama.get('base_urls') != ['http://127.0.0.1:11434']:
    raise SystemExit(1)

api_configs = ollama.get('api_configs', {})
entry = api_configs.get('0')
if not entry or entry.get('enable') is not True:
    raise SystemExit(1)
PY
  then
    return 0
  fi

  return 1
}

wait_for_open_webui() {
  local i
  for i in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:3000/health >/dev/null 2>&1; then
      return 0
    fi
    sleep 2
  done

  echo "ERROR: Open WebUI did not become healthy on http://127.0.0.1:3000"
  docker logs --tail 100 "$CONTAINER_NAME" || true
  exit 1
}

verify_ollama_api() {
  if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null; then
    echo "ERROR: Ollama API is not reachable on http://127.0.0.1:11434"
    exit 1
  fi
}

# ── Install Ollama ─────────────────────────────────────────────────────────────

if ! command -v ollama &> /dev/null; then
  echo "Installing Ollama..."
  yay -S --noconfirm --needed ollama
else
  echo "Ollama already installed, skipping."
fi

# ── Configure Ollama to listen on all interfaces ───────────────────────────────
# By default Ollama binds to 127.0.0.1:11434.
# Setting OLLAMA_HOST=0.0.0.0 makes it reachable from LAN and from Docker via
# host.docker.internal. The systemd user override file persists across updates.

ensure_ollama_unit

mkdir -p "$OLLAMA_OVERRIDE_DIR"

DESIRED_OVERRIDE="[Service]
Environment=OLLAMA_HOST=0.0.0.0:11434"

if [ ! -f "$OLLAMA_OVERRIDE_FILE" ] || [ "$DESIRED_OVERRIDE" != "$(cat "$OLLAMA_OVERRIDE_FILE")" ]; then
  printf '%s\n' "$DESIRED_OVERRIDE" > "$OLLAMA_OVERRIDE_FILE"
  echo "Wrote Ollama systemd override: OLLAMA_HOST=0.0.0.0:11434"
  OLLAMA_OVERRIDE_CHANGED=true
else
  echo "Ollama override already set — skipping."
  OLLAMA_OVERRIDE_CHANGED=false
fi

# ── Enable and start Ollama service ───────────────────────────────────────────

if [ "$OLLAMA_UNIT_CHANGED" = true ] || [ "$OLLAMA_OVERRIDE_CHANGED" = true ]; then
  systemctl --user daemon-reload
fi

systemctl --user enable --now ollama
echo "Ollama user service enabled and started."

verify_ollama_api

# ── Pull a default model ───────────────────────────────────────────────────────

if ! ollama list | grep -q "qwen2.5-coder"; then
  echo "Pulling qwen2.5-coder:7b (good coding model, ~4GB)..."
  ollama pull qwen2.5-coder:7b
else
  echo "qwen2.5-coder already pulled, skipping."
fi

# ── Open WebUI via Docker ──────────────────────────────────────────────────────

if ! command -v docker &> /dev/null; then
  echo "Docker not found — skipping Open WebUI."
  exit 0
fi

# Ensure hub network exists (install-caddy.sh also creates it, but be safe)
if ! docker network ls --format '{{.Name}}' | grep -q "^hub$"; then
  echo "Creating Docker network 'hub'..."
  docker network create hub >/dev/null
fi

if open_webui_needs_recreate; then
  recreate_open_webui
else
  echo "Open WebUI container already matches desired config - ensuring it is running."
  docker start "$CONTAINER_NAME" >/dev/null 2>&1 || true
  wait_for_open_webui
  ensure_open_webui_config >/dev/null
fi

echo ""
echo "Ollama running on 0.0.0.0:11434 (LAN-accessible)"
echo "Open WebUI running:"
echo "  Local: http://localhost:3000"
echo "  LAN:   http://webui.hub.home  (after Caddy + AdGuard setup)"
