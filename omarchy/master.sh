#!/bin/sh

. ./install-ghostty.sh
. ./install-stow.sh
. ./install-zsh.sh
. ./install-dotfiles.sh
. ./install-lua.sh
. ./install-rust.sh
. ./install-rclone.sh
. ./install-oh-my-posh.sh

. ./install-dev-tools.sh
. ./install-yazi.sh
. ./install-taskwarrior.sh
. ./install-wtf.sh
. ./install-ollama.sh
. ./install-startpage.sh
# . ./install-glance.sh     # disabled — replaced by custom HTML startpage (keep for rollback)
# . ./install-homepage.sh   # disabled — keep for rollback
. ./install-lifeos.sh

. ./set-shell.sh
