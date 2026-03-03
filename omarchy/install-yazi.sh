#!/bin/sh
# install-yazi.sh
# Installs yazi — blazing fast terminal file manager with Neovim integration
# Also installs required optional dependencies for full feature set
# Idempotent: --needed skips if already installed

yay -S --noconfirm --needed yazi
yay -S --noconfirm --needed ffmpegthumbnailer  # video thumbnails
yay -S --noconfirm --needed unar               # archive preview
yay -S --noconfirm --needed jq                 # JSON preview
yay -S --noconfirm --needed poppler            # PDF preview
yay -S --noconfirm --needed fd                 # fast file search (used by yazi)
yay -S --noconfirm --needed ripgrep            # fast grep (used by yazi + nvim telescope)
yay -S --noconfirm --needed fzf                # fuzzy finder (used by nvim + shell)
yay -S --noconfirm --needed zoxide             # smart cd — jump to any project fast
