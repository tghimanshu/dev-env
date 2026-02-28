#!/bin/sh

yay -S --noconfirm --needed rclone
rclone mount drive: ~/drive --vfs-cache-mode writes --daemon
