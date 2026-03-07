# Dev Environment — LifeOS Setup

This repo contains idempotent install scripts for the LifeOS running on **Omarchy (Arch Linux + Hyprland)**.
Every script is safe to re-run at any time — it will skip work that is already done.

## Prerequisites

- Arch Linux / Omarchy installed
- `yay` AUR helper available
- SSH key added to GitHub (for dotfiles clone)

## Fresh Machine Setup

```bash
# 1. Clone this repo
mkdir -p ~/personal
git clone git@github.com:tghimanshu/dev-env.git ~/personal/dev-env

# 2. Run everything in one shot
cd ~/personal/dev-env/omarchy
sh master.sh
```

`master.sh` runs every `install-*.sh` script in order, then sets zsh as the default shell.
Each script runs in its own subprocess — failures are isolated and don't affect subsequent steps.

## What Gets Installed

| Script | Installs / Configures |
|---|---|
| `install-ghostty.sh` | Ghostty terminal |
| `install-stow.sh` | GNU Stow (dotfile manager) |
| `install-zsh.sh` | Zsh shell |
| `install-dotfiles.sh` | Clones dotfiles repo + stows all config packages |
| `install-lua.sh` | Lua + luarocks + imagemagick |
| `install-rust.sh` | Rust toolchain via rustup |
| `install-rclone.sh` | rclone + systemd mount service for Google Drive |
| `install-oh-my-posh.sh` | Oh My Posh prompt |
| `install-dev-tools.sh` | lazygit, gh, clang, lldb, cmake, stylua, anki, node, npm |
| `install-yazi.sh` | Yazi file manager + fd, ripgrep, fzf, zoxide |
| `install-taskwarrior.sh` | task, timew, vit |
| `install-wtf.sh` | wtfutil terminal dashboard |
| `install-ollama.sh` | Ollama (local LLMs) + Open WebUI |
| `install-startpage.sh` | Custom HTML startpage via systemd on :4000 |
| `install-lifeos.sh` | Notes structure + Hyprland keybinds |
| `set-shell.sh` | Sets zsh as default shell |

## Re-running After Changes

```bash
# Re-run a single script (idempotent — skips already-done work):
bash ~/personal/dev-env/omarchy/install-dotfiles.sh

# Re-run everything:
cd ~/personal/dev-env/omarchy && sh master.sh
```

## Dotfiles

Config files live in a separate repo: `~/personal/dotfiles/`
They are managed with GNU Stow — see `install-dotfiles.sh` for what gets stowed.

## Key Keybindings (after setup)

| Key | Action |
|---|---|
| `Ctrl+F` | Open tmux-sessionizer (project switcher) |
| `SUPER+D` | Open LifeOS startpage (http://localhost:4000) |
| `SUPER+SHIFT+T` | Open wtf terminal dashboard |
| `<leader>nd` | Open today's daily note in Neovim |

## Legacy / Deprecated

The `runs/` directory and `dev-env` script are from an older Ubuntu/apt-based workflow
and are no longer used. The `omarchy/` scripts are the current standard.
