#!/bin/sh
# install-taskwarrior.sh
# Installs taskwarrior (task manager) and timewarrior (time tracker)
# Idempotent: --needed skips if already installed

yay -S --noconfirm --needed task
yay -S --noconfirm --needed timew
yay -S --noconfirm --needed vit
