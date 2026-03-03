#!/bin/sh
# install-lifeos.sh
# Sets up the LifeOS — the productivity layer on top of Omarchy.
# Idempotent: safe to run multiple times, will not duplicate or overwrite.
#
# What this does:
#   1. Ensures the lifeos-startpage systemd user service is running (port 4000)
#      (install-startpage.sh handles the full setup; this just ensures it's active)
#   2. Creates ~/personal/notes/ directory structure
#   3. Injects Hyprland keybinds into ~/.config/hypr/bindings.conf
#      - SUPER+D       → open Life OS startpage (http://localhost:4000) in browser
#      - SUPER+SHIFT+T → open WTF terminal dashboard in Ghostty
#
# Prereqs: python3, systemd user session, stow (handled by master.sh)
# Docs/config: ~/personal/claude-code-daily/README.md

set -e

NOTES_DIR="$HOME/personal/notes"
BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"

# ── 1. Dashboard: ensure lifeos-startpage service is running ───────────────────

if systemctl --user is-active --quiet lifeos-startpage 2>/dev/null; then
  echo "lifeos-startpage.service already running at http://localhost:4000"
else
  echo "Starting lifeos-startpage.service..."
  systemctl --user start lifeos-startpage 2>/dev/null || \
    echo "Warning: lifeos-startpage.service not found — run install-startpage.sh first."
fi

# ── 2. Notes directory structure ───────────────────────────────────────────

echo "Setting up ~/personal/notes/..."

mkdir -p "$NOTES_DIR/daily"
mkdir -p "$NOTES_DIR/projects"
mkdir -p "$NOTES_DIR/learning"
mkdir -p "$NOTES_DIR/templates"

# Create tasks.md only if it doesn't already exist
if [ ! -f "$NOTES_DIR/tasks.md" ]; then
  cat > "$NOTES_DIR/tasks.md" << 'EOF'
# Tasks

<!-- WTF dashboard reads this file. Use [ ] and [x] for checkboxes. -->
<!-- Edit with: nvim ~/personal/notes/tasks.md                       -->

## Today

- [ ] Example task — replace me

## This Week

- [ ] 

## Backlog

- [ ] 

EOF
  echo "Created $NOTES_DIR/tasks.md"
else
  echo "$NOTES_DIR/tasks.md already exists — skipping."
fi

# Create daily note template only if not present
if [ ! -f "$NOTES_DIR/templates/daily.md" ]; then
  cat > "$NOTES_DIR/templates/daily.md" << 'EOF'
# {{date}}

## Focus

- 

## Done

- [ ] 

## Notes

## Blockers

EOF
  echo "Created $NOTES_DIR/templates/daily.md"
fi

# Create project template only if not present
if [ ! -f "$NOTES_DIR/templates/project.md" ]; then
  cat > "$NOTES_DIR/templates/project.md" << 'EOF'
# Project: {{name}}

## Goal

## Tasks

- [ ] 

## Notes

## Links

EOF
  echo "Created $NOTES_DIR/templates/project.md"
fi

# Create learning template only if not present
if [ ! -f "$NOTES_DIR/templates/learning.md" ]; then
  cat > "$NOTES_DIR/templates/learning.md" << 'EOF'
# {{topic}}

## Summary

## Key Concepts

## Examples

## Resources

EOF
  echo "Created $NOTES_DIR/templates/learning.md"
fi

echo "Notes structure ready at $NOTES_DIR"

# ── 3. Hyprland keybinds (idempotent) ─────────────────────────────────────
# Appends keybinds only if they are not already present in bindings.conf.

if [ -f "$BINDINGS_FILE" ]; then
  DASHBOARD_BIND='bindd = SUPER, D, Life OS Dashboard, exec, omarchy-launch-webapp "http://localhost:4000"'
  WTF_BIND='bindd = SUPER SHIFT, T, WTF Dashboard, exec, uwsm-app -- xdg-terminal-exec wtf'

  if ! grep -qF 'SUPER, D, ' "$BINDINGS_FILE"; then
    echo "" >> "$BINDINGS_FILE"
    echo "# LifeOS dashboard bindings (added by install-lifeos.sh)" >> "$BINDINGS_FILE"
    echo "$DASHBOARD_BIND" >> "$BINDINGS_FILE"
    echo "Added SUPER+D → Life OS keybind"
  else
    echo "SUPER+D keybind already present — skipping."
  fi

  if ! grep -qF 'SUPER SHIFT, T, WTF Dashboard' "$BINDINGS_FILE"; then
    echo "$WTF_BIND" >> "$BINDINGS_FILE"
    echo "Added SUPER+SHIFT+T → WTF keybind"
  else
    echo "SUPER+SHIFT+T keybind already present — skipping."
  fi
else
  echo "Warning: $BINDINGS_FILE not found — skipping Hyprland keybind injection."
  echo "Manually add these to your bindings.conf:"
  echo '  bindd = SUPER, D, Life OS Dashboard, exec, omarchy-launch-webapp "http://localhost:4000"'
  echo '  bindd = SUPER SHIFT, T, WTF Dashboard, exec, uwsm-app -- xdg-terminal-exec wtf'
fi

echo ""
echo "LifeOS setup complete."
echo "  Web dashboard : http://localhost:4000  (SUPER+D)"
echo "  TUI dashboard : wtf                    (SUPER+SHIFT+T)"
echo "  Tasks file    : $NOTES_DIR/tasks.md"
echo ""
echo "To manage the startpage service:"
echo "  systemctl --user status  lifeos-startpage"
echo "  systemctl --user restart lifeos-startpage"
echo "  journalctl --user -u lifeos-startpage -f"
