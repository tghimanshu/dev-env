#!/bin/sh

yay -S --noconfirm --needed rclone

# Mount only if not already mounted
if ! mountpoint -q ~/drive 2>/dev/null; then
    mkdir -p ~/drive
    rclone mount drive: ~/drive --vfs-cache-mode writes --daemon
else
    echo "~/drive already mounted, skipping"
fi
