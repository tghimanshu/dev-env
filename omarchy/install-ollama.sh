#!/usr/bin/env bash
# install-ollama.sh
# Installs Ollama (local LLM runner) and Open WebUI (browser interface)
# Idempotent: checks before installing/pulling
# Open WebUI access at: http://localhost:3000

# Install Ollama
if ! command -v ollama &> /dev/null; then
  echo "Installing Ollama..."
  yay -S --noconfirm --needed ollama
else
  echo "Ollama already installed, skipping."
fi

# Enable and start Ollama service
systemctl --user enable ollama 2>/dev/null || true
systemctl --user start ollama 2>/dev/null || true

# Pull a default lightweight model (fast, good for coding)
if ! ollama list | grep -q "qwen2.5-coder"; then
  echo "Pulling qwen2.5-coder:7b (good coding model, ~4GB)..."
  ollama pull qwen2.5-coder:7b
else
  echo "qwen2.5-coder already pulled, skipping."
fi

# Open WebUI via Docker
CONTAINER_NAME="open-webui"

if ! command -v docker &> /dev/null; then
  echo "Docker not found — skipping Open WebUI. Install docker to get the web interface."
else
  if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Open WebUI container already exists. Starting if stopped..."
    docker start "$CONTAINER_NAME" 2>/dev/null || true
  else
    echo "Creating Open WebUI container..."
    docker run -d \
      -p 3000:8080 \
      --add-host=host.docker.internal:host-gateway \
      -v open-webui:/app/backend/data \
      --name "$CONTAINER_NAME" \
      --restart unless-stopped \
      ghcr.io/open-webui/open-webui:main
  fi
  echo "Open WebUI running at http://localhost:3000"
fi
