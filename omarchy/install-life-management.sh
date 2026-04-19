#!/bin/env bash

# Install life management tools
yay -S --noconfirm --needed nb taskwarrior buku
yay -S --noconfirm --needed taskwarrior-tui

# If task warrior-tui fails
git clone https://aur.archlinux.org/taskwarrior-tui.git
cd taskwarrior-tui
makepkg -si

# 3. Point nb at your brain
nb env set NB_DIR ~/personal/notes
nb env set NB_DEFAULT_EXTENSION md
nb env set EDITOR nvim
