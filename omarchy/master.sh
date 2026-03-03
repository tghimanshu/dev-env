#!/usr/bin/env bash
# master.sh — runs every install script as a subprocess (not sourced).
# Each script gets its own shell: working directory changes, set -e, and exit 1
# are fully isolated and cannot bleed into this session or subsequent scripts.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run() {
  echo ""
  echo "══════════════════════════════════════"
  echo "  Running: $1"
  echo "══════════════════════════════════════"
  bash "$SCRIPT_DIR/$1"
}

run install-ghostty.sh
run install-stow.sh
run install-zsh.sh
run install-dotfiles.sh
run install-lua.sh
run install-rust.sh
run install-rclone.sh
run install-oh-my-posh.sh

run install-dev-tools.sh
run install-yazi.sh
run install-taskwarrior.sh
run install-wtf.sh
run install-ollama.sh
run install-startpage.sh
# run install-glance.sh     # disabled — replaced by custom HTML startpage (keep for rollback)
# run install-homepage.sh   # disabled — keep for rollback
run install-lifeos.sh

run set-shell.sh
