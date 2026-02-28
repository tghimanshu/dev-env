#!/bin/sh

ORIGINAL_DIR=$(pwd)
REPO_URL="git@github.com:tghimanshu/dotfiles.git"
REPO_NAME="$HOME/personal/dotfiles/"

is_stow_installed() {
  pacman -Qi "stow" &> /dev/null
}

add_ctrl_f() {
    if [[ -f $HOME/.zshrc ]]; then
        grep "bindkey -s '^f' 'tmux-sessionizer^M'" ~/.zshrc || echo "bindkey -s '^f' 'tmux-sessionizer^M'" >>~/.zshrc
    fi
    if [[ -f $HOME/.bashrc ]]; then
        grep "bind \"\\C-f\": \"tmux-sessionizer\n \" " ~/.zshrc || echo "bindkey -s '^f' 'tmux-sessionizer^M'" >>~/.zshrc
    fi

}
add_to_path() {
    if [[ -f $HOME/.zshrc ]]; then
        grep "export PATH=\$PATH:$@" ~/.zshrc || echo "export PATH=\$PATH:$@" >>~/.zshrc
    fi
    if [[ -f $HOME/.bashrc ]]; then
        grep "export PATH=\$PATH:$@" ~/.bashrc || echo "export PATH=\$PATH:$@" >>~/.bashrc
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

# Check if the clone was successful
if [ $? -eq 0 ]; then
  echo "removing old configs"
  # rm -rf ~/.config/nvim ~/.config/starship.toml ~/.local/share/nvim/ ~/.cache/nvim/ ~/.config/ghostty/config
  mkdir -p ~/.config/backup/
  mv ~/.config/nvim ~/.config/backup/nvim.backup
  mv ~/.config/tmux ~/.config/backup/tmux.backup

  cd "$REPO_NAME"
  # stow zshrc
  # stow ghostty
  stow -t ~ tmux
  stow -t ~ nvim
  # stow starship
  stow -t ~ local

  add_to_path "$HOME/.local/scripts"
  add_ctrl_f
else
  echo "Failed to clone the repository."
  exit 1
fi
