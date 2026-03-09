#!/usr/bin/env bash
# install-hub-hosts.sh
# Idempotently installs local /etc/hosts entries for hub.home domains.
# This only affects the current machine. LAN-wide resolution should still be
# handled by your DNS server (for example, AdGuard Home rewrites).

set -euo pipefail

HOSTS_FILE="/etc/hosts"
TARGET_IP="${HUB_HOSTS_IP:-127.0.0.1}"

if [ "$EUID" -ne 0 ]; then
  if sudo -n true >/dev/null 2>&1; then
    exec sudo --preserve-env=HUB_HOSTS_IP bash "$0" "$@"
  fi

  echo "ERROR: root privileges are required to update $HOSTS_FILE"
  echo "Run: sudo HUB_HOSTS_IP=$TARGET_IP bash $0"
  exit 1
fi

python3 - "$HOSTS_FILE" "$TARGET_IP" <<'PY'
from pathlib import Path
import sys

hosts_path = Path(sys.argv[1])
target_ip = sys.argv[2]

start_marker = "# >>> omarchy hub.home >>>"
end_marker = "# <<< omarchy hub.home <<<"
hostnames = [
    "hub.home",
    "webui.hub.home",
    "adguard.hub.home",
    "ollama.hub.home",
]

existing = hosts_path.read_text() if hosts_path.exists() else ""
lines = existing.splitlines()

new_lines = []
inside_block = False
for line in lines:
    if line == start_marker:
        inside_block = True
        continue
    if line == end_marker:
        inside_block = False
        continue
    if not inside_block:
        new_lines.append(line)

while new_lines and new_lines[-1] == "":
    new_lines.pop()

new_lines.extend([
    "",
    start_marker,
    f"{target_ip} hub.home webui.hub.home adguard.hub.home ollama.hub.home",
    end_marker,
    "",
])

hosts_path.write_text("\n".join(new_lines))
PY

echo "Installed local hub.home host entries in $HOSTS_FILE -> $TARGET_IP"
