#!/bin/bash

yay -S --noconfirm --needed rclone fuse3

# If the drive: remote isn't configured yet, there's nothing to mount.
# Run 'rclone config' to set it up, then re-run this script.
if ! rclone listremotes | grep -q '^drive:$'; then
    echo "rclone remote 'drive' not configured — skipping mount setup."
    echo "Run 'rclone config' to add a remote named 'drive', then re-run this script."
    exit 0
fi

# Expand $HOME eagerly so the service file contains the real absolute path,
# not the literal string "${HOME}" which systemd does not expand.
DRIVE_DIR="${HOME}/drive"
mkdir -p "$DRIVE_DIR"

# --- systemd user service for startup mount ---
SERVICE_FILE="$HOME/.config/systemd/user/rclone-drive.service"
DESIRED_SERVICE="[Unit]
Description=rclone mount — Google Drive at ${DRIVE_DIR}
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/usr/bin/rclone mount drive: ${DRIVE_DIR} --vfs-cache-mode writes --log-level INFO
ExecStop=/usr/bin/fusermount -u ${DRIVE_DIR}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target"

mkdir -p "$(dirname "$SERVICE_FILE")"

if [ ! -f "$SERVICE_FILE" ] || [ "$DESIRED_SERVICE" != "$(cat "$SERVICE_FILE")" ]; then
    echo "Writing rclone-drive.service"
    printf '%s\n' "$DESIRED_SERVICE" > "$SERVICE_FILE"
    systemctl --user daemon-reload
fi

# Enable so it starts on every login
systemctl --user enable rclone-drive.service

# Start now if not already mounted
if ! mountpoint -q "$DRIVE_DIR" 2>/dev/null; then
    echo "Starting rclone mount..."
    systemctl --user start rclone-drive.service
    # Give it a moment and confirm
    sleep 2
    if mountpoint -q "$DRIVE_DIR" 2>/dev/null; then
        echo "$DRIVE_DIR mounted successfully"
    else
        echo "Warning: mount may still be starting. Check: systemctl --user status rclone-drive"
    fi
else
    echo "$DRIVE_DIR already mounted, skipping"
fi
