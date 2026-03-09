#!/usr/bin/env bash
# install-dns-stub.sh
# Idempotently disables or re-enables systemd-resolved listeners on port 53.
# This is designed for AdGuard Home, which needs to bind host port 53.
#
# File-only changes:
#   - writes/removes a managed drop-in under /etc/systemd/resolved.conf.d/
#   - swaps /etc/resolv.conf between systemd's non-stub and prior mode
#   - stores restore state under /etc/omarchy/
#
# Usage:
#   sudo bash install-dns-stub.sh           # disable port-53 listeners (default)
#   sudo bash install-dns-stub.sh disable   # same as above
#   sudo bash install-dns-stub.sh enable    # restore previous resolver setup
#   bash install-dns-stub.sh status         # show current state

set -euo pipefail

ACTION="${1:-disable}"

DROPIN_DIR="/etc/systemd/resolved.conf.d"
DROPIN_FILE="$DROPIN_DIR/30-omarchy-adguard-port53.conf"
STATE_DIR="/etc/omarchy"
STATE_FILE="$STATE_DIR/adguard-port53.state"
RESOLV_BACKUP="$STATE_DIR/resolv.conf.before-adguard"

SYSTEM_RESOLV="/run/systemd/resolve/resolv.conf"
STUB_RESOLV="/run/systemd/resolve/stub-resolv.conf"

usage() {
  echo "Usage: $0 [disable|enable|status]"
}

need_root() {
  if [ "$EUID" -eq 0 ]; then
    return 0
  fi

  if [ "$ACTION" = "status" ]; then
    return 0
  fi

  if sudo -n true >/dev/null 2>&1; then
    exec sudo bash "$0" "$@"
  fi

  echo "ERROR: root privileges are required for '$ACTION'."
  echo "Run: sudo bash $0 $ACTION"
  exit 1
}

ensure_resolved_present() {
  if ! systemctl cat systemd-resolved.service >/dev/null 2>&1; then
    echo "ERROR: systemd-resolved.service was not found on this system."
    exit 1
  fi
}

ensure_dirs() {
  mkdir -p "$DROPIN_DIR" "$STATE_DIR"
}

set_resolv_symlink() {
  local target="$1"

  if [ ! -e "$target" ]; then
    echo "ERROR: expected resolver target '$target' does not exist."
    exit 1
  fi

  rm -f /etc/resolv.conf
  ln -s "$target" /etc/resolv.conf
}

save_state_once() {
  if [ -f "$STATE_FILE" ]; then
    return 0
  fi

  if [ -L /etc/resolv.conf ]; then
    local target
    target="$(readlink /etc/resolv.conf)"
    cat > "$STATE_FILE" <<EOF
RESOLV_CONF_MODE=symlink
RESOLV_CONF_TARGET=$target
EOF
    return 0
  fi

  if [ -f /etc/resolv.conf ]; then
    cp /etc/resolv.conf "$RESOLV_BACKUP"
    cat > "$STATE_FILE" <<EOF
RESOLV_CONF_MODE=file
RESOLV_CONF_BACKUP=$RESOLV_BACKUP
EOF
    return 0
  fi

  cat > "$STATE_FILE" <<'EOF'
RESOLV_CONF_MODE=missing
EOF
}

restore_state() {
  local mode target backup

  if [ -f "$STATE_FILE" ]; then
    # shellcheck disable=SC1090
    . "$STATE_FILE"
  fi

  mode="${RESOLV_CONF_MODE:-symlink}"
  target="${RESOLV_CONF_TARGET:-$STUB_RESOLV}"
  backup="${RESOLV_CONF_BACKUP:-$RESOLV_BACKUP}"

  case "$mode" in
    symlink)
      set_resolv_symlink "$target"
      ;;
    file)
      if [ ! -f "$backup" ]; then
        echo "ERROR: resolver backup '$backup' is missing; cannot restore /etc/resolv.conf."
        exit 1
      fi
      rm -f /etc/resolv.conf
      cp "$backup" /etc/resolv.conf
      ;;
    missing)
      rm -f /etc/resolv.conf
      ;;
    *)
      echo "ERROR: unrecognized resolver state '$mode'."
      exit 1
      ;;
  esac
}

restart_resolved() {
  systemctl restart systemd-resolved
}

disable_stub() {
  ensure_dirs
  save_state_once

  cat > "$DROPIN_FILE" <<'EOF'
[Resolve]
DNSStubListener=no
DNSStubListenerExtra=
EOF

  set_resolv_symlink "$SYSTEM_RESOLV"
  restart_resolved

  echo "Disabled systemd-resolved listeners on port 53 for AdGuard."
  echo "Managed drop-in: $DROPIN_FILE"
  echo "Resolver target : /etc/resolv.conf -> $SYSTEM_RESOLV"
}

enable_stub() {
  rm -f "$DROPIN_FILE"
  restore_state
  restart_resolved

  rm -f "$STATE_FILE" "$RESOLV_BACKUP"

  echo "Re-enabled the previous systemd-resolved port-53 setup."
}

show_status() {
  local resolv_state="missing"
  local dropin_state="absent"
  local listener_state="active"

  if [ -L /etc/resolv.conf ]; then
    resolv_state="$(readlink /etc/resolv.conf)"
  elif [ -f /etc/resolv.conf ]; then
    resolv_state="regular file"
  fi

  if [ -f "$DROPIN_FILE" ]; then
    dropin_state="present"
    listener_state="disabled"
  fi

  echo "systemd-resolved: $(systemctl is-active systemd-resolved 2>/dev/null || true)"
  echo "systemd-resolved port 53 listeners: $listener_state"
  echo "managed drop-in: $dropin_state ($DROPIN_FILE)"
  echo "/etc/resolv.conf: $resolv_state"
  echo "listeners on :53:"
  ss -H -ltnup 2>/dev/null | grep ':53' || echo "  none"
}

case "$ACTION" in
  disable)
    need_root "$@"
    ensure_resolved_present
    disable_stub
    ;;
  enable)
    need_root "$@"
    ensure_resolved_present
    enable_stub
    ;;
  status)
    ensure_resolved_present
    show_status
    ;;
  *)
    usage
    exit 1
    ;;
esac
