# Dev Setup

## Setup Process

### Cloning the Repo

Note: This is currently configured to work best with an ubuntu system (apt)

```bash
mkdir ~/personal
cd ~/personal
git clone https://github.com/tghimanshu/dev-env.git
```

### Installing all the libararies

```bash
./run
./run neovim # Use the second parameter as a way to fuzzy install files from the rusn folder
```

### Updating the Configs

```bash
mkdir ~/.config # Optional
./dev-env
```

| You should have a working neovim, tmux and fzf. Enjoy!

| Start by pressing `Ctrl + f` to start exploring all the capabilities

###

## Ansible Based Workflow (Deprecated)

The ansible workflow works to build neovim from source

Ref: (https://frontendmasters.github.io/dev-prod-2/lessons/your-env/ansible)

## Extras

`Ctrl+X Ctrl+F` -> Expands file path in neovim

## Tmux

| After Installing tmux plugin manager please use prefix + I (ctrl+a I) to install tpm
