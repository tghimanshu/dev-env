#!/bin/sh
# install-dev-tools.sh
# Installs general developer CLI tools used across the whole setup
# Idempotent: --needed skips if already installed

# Install Google Chrome
yay -S --noconfirm --needed google-chrome

# Terminal multiplexer (already likely installed via tmux stow)
yay -S --noconfirm --needed tmux

# Neovim LSP / formatter dependencies
yay -S --noconfirm --needed stylua            # Lua formatter (used by none-ls in nvim)
yay -S --noconfirm --needed python-pip        # pip for Python LSP tools
yay -S --noconfirm --needed python-virtualenv # venv support

# C / C++ toolchain (for clangd LSP + learning)
yay -S --noconfirm --needed clang
# yay -S --noconfirm --needed lldb               # debugger (codelldb)
yay -S --noconfirm --needed cmake
yay -S --noconfirm --needed make

# Node / npm (for LSPs like ts_ls, tailwindcss)
yay -S --noconfirm --needed nodejs
yay -S --noconfirm --needed npm
yay -S --noconfirm --needed pnpm

# GitHub CLI — manage repos, PRs, issues from terminal
yay -S --noconfirm --needed github-cli

# Anki — spaced repetition flashcards
yay -S --noconfirm --needed anki

# lazygit — git TUI (great inside nvim terminal)
yay -S --noconfirm --needed lazygit

yay -S --noconfirm --needed doppler-cli
