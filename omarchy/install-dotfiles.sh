#!/usr/bin/env bash

REPO_URL="git@github.com:tghimanshu/dotfiles.git"
REPO_NAME="$HOME/personal/dotfiles/"

is_stow_installed() {
  pacman -Qi "stow" &> /dev/null
}

add_ctrl_f() {
    if [[ -f $HOME/.zshrc ]]; then
        grep -qF "bindkey -s '^f' 'tmux-sessionizer^M'" ~/.zshrc || echo "bindkey -s '^f' 'tmux-sessionizer^M'" >>~/.zshrc
    fi
    if [[ -f $HOME/.bashrc ]]; then
        grep -qF "bind '\"\\C-f\":\"tmux-sessionizer\\n\"'" ~/.bashrc || echo "bind '\"\\C-f\":\"tmux-sessionizer\\n\"'" >>~/.bashrc
    fi

}
add_to_path() {
    if [[ -f $HOME/.zshrc ]]; then
        grep -qF "export PATH=\$PATH:$1" ~/.zshrc || echo "export PATH=\$PATH:$1" >>~/.zshrc
    fi
    if [[ -f $HOME/.bashrc ]]; then
        grep -qF "export PATH=\$PATH:$1" ~/.bashrc || echo "export PATH=\$PATH:$1" >>~/.bashrc
    fi
}


if ! is_stow_installed; then
  echo "Install stow first"
  exit 1
fi

cd ~

# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL" $REPO_NAME
fi

# Install TPM (TMUX)
if [ -d "$HOME/.local/share/tmux" ]; then
    echo "Repository '' already exists, Skipping clone"
else
    mkdir ~/.local/share/tmux
    git clone https://github.com/tmux-plugins/tpm ~/.local/share/tmux
fi

# Proceed if the repo is present (cloned above or already existed)
if [ -d "$REPO_NAME" ]; then
  echo "removing old configs"
  # rm -rf ~/.config/nvim ~/.config/starship.toml ~/.local/share/nvim/ ~/.cache/nvim/ ~/.config/ghostty/config
  mkdir -p ~/.config/backup/
  mv ~/.config/nvim  ~/.config/backup/nvim.backup  2>/dev/null || true
  mv ~/.config/tmux  ~/.config/backup/tmux.backup  2>/dev/null || true
  mv ~/.config/wtf   ~/.config/backup/wtf.backup   2>/dev/null || true
  # glance backup disabled — keeping glance config in dotfiles for easy rollback
  # mv ~/.config/glance ~/.config/backup/glance.backup 2>/dev/null || true
  mv ~/.config/homepage ~/.config/backup/homepage.backup 2>/dev/null || true

  cd "$REPO_NAME"
  # stow zshrc
  # stow ghostty
  stow -R -t ~ tmux
  stow -R -t ~ nvim
  stow -R -t ~ zsh
  stow -R -t ~ ohmyposh
  # stow starship
  stow -R -t ~ local
  stow -R -t ~ wtf
  stow -R -t ~ taskwarrior
  stow -R -t ~ startpage
  # stow -R -t ~ glance     # disabled — replaced by custom HTML startpage (keep for rollback)
  # stow -R -t ~ homepage   # disabled — keep for rollback
  stow -R -t ~ notes

  add_to_path "$HOME/.local/scripts"
  add_ctrl_f

  # Source taskwarrior aliases into shell
  ALIAS_LINE="source \$HOME/.config/taskwarrior/taskrc_aliases.sh"
  if [[ -f $HOME/.zshrc ]]; then
    grep -qF "$ALIAS_LINE" ~/.zshrc || echo "$ALIAS_LINE" >> ~/.zshrc
  fi
  if [[ -f $HOME/.bashrc ]]; then
    grep -qF "$ALIAS_LINE" ~/.bashrc || echo "$ALIAS_LINE" >> ~/.bashrc
  fi

  # Taskwarrior reads ~/.taskrc by default — symlink to the stowed config
  TASKRC_LINK="$HOME/.taskrc"
  TASKRC_TARGET="$HOME/.config/taskwarrior/.taskrc"
  if [ ! -e "$TASKRC_LINK" ]; then
    ln -sf "$TASKRC_TARGET" "$TASKRC_LINK"
    echo "Linked ~/.taskrc → ~/.config/taskwarrior/.taskrc"
  else
    echo "~/.taskrc already exists — skipping symlink."
  fi

else
  echo "Failed to clone the repository."
  exit 1
fi
