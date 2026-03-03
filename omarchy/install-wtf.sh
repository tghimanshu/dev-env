#!/bin/sh
# install-wtf.sh
# Installs wtfutil — modular terminal dashboard
# Idempotent: --needed skips if already installed
# Config lives in dotfiles: wtf/.config/wtf/config.yml (stowed by install-dotfiles.sh)

yay -S --noconfirm --needed wtfutil

# wtfutil installs as 'wtfutil' on Arch — add 'wtf' alias for convenience
ALIAS_LINE="alias wtf='wtfutil'"
if [[ -f $HOME/.zshrc ]]; then
  grep -qF "$ALIAS_LINE" ~/.zshrc || echo "$ALIAS_LINE" >> ~/.zshrc
fi
if [[ -f $HOME/.bashrc ]]; then
  grep -qF "$ALIAS_LINE" ~/.bashrc || echo "$ALIAS_LINE" >> ~/.bashrc
fi
