# Life OS — Setup Guide & Testing Reference

Everything in this setup is version-controlled across two repos:

| Repo | Purpose |
|------|---------|
| `~/personal/dotfiles` | Config files (stowed to `~` via GNU Stow) |
| `~/personal/dev-env` | Install scripts (idempotent, re-runnable anytime) |

---

## Directory Map

```
~/personal/
├── dotfiles/                   ← GNU Stow packages (configs)
│   ├── nvim/                   → ~/.config/nvim/
│   ├── tmux/                   → ~/.config/tmux/
│   ├── zsh/                    → ~/.zshrc
│   ├── wtf/                    → ~/.config/wtf/
│   ├── taskwarrior/            → ~/.config/taskwarrior/
│   ├── startpage/              → startpage served via systemd on :4000
│   ├── notes/                  → ~/personal/notes/
│   ├── ohmyposh/               → ~/.config/ohmyposh/
│   ├── glance/                 → ~/.config/glance/  (disabled — keep for rollback)
│   ├── homepage/               → ~/.config/homepage/ (disabled — keep for rollback)
│   └── local/                  → ~/.local/scripts/
│
└── dev-env/omarchy/            ← Install scripts
    ├── master.sh               ← Run everything at once
    ├── install-dotfiles.sh     ← Clone dotfiles + stow all packages
    ├── install-dev-tools.sh    ← CLI tools (lazygit, gh, clang, anki...)
    ├── install-yazi.sh         ← Yazi file manager + deps (fd, rg, fzf, zoxide)
    ├── install-taskwarrior.sh  ← task, timew, vit
    ├── install-wtf.sh          ← wtfutil terminal dashboard
    ├── install-ollama.sh       ← Ollama (local LLMs) + Open WebUI
    ├── install-startpage.sh    ← Custom HTML startpage via systemd on :4000
    ├── install-lifeos.sh       ← LifeOS notes structure + Hyprland keybinds
    ├── install-glance.sh       ← Glance dashboard via Docker (disabled — keep for rollback)
    ├── install-ghostty.sh      ← Ghostty terminal
    ├── install-stow.sh         ← GNU Stow
    ├── install-zsh.sh          ← Zsh
    ├── install-lua.sh          ← Lua + luarocks
    ├── install-rust.sh         ← Rust toolchain
    ├── install-rclone.sh       ← rclone (Google Drive mount)
    ├── install-oh-my-posh.sh   ← Oh My Posh prompt
    └── set-shell.sh            ← Set zsh as default shell
```

---

## Fresh Machine Setup

```bash
# 1. Clone dev-env
git clone git@github.com:tghimanshu/dev-env.git ~/personal/dev-env

# 2. Run master (installs everything + stows dotfiles)
cd ~/personal/dev-env/omarchy
sh master.sh
```

That's it. Every script is idempotent — safe to re-run anytime.

---

## Individual Scripts — What They Do & How to Test

---

### 1. Neovim Config (`dotfiles/nvim/`)

**What changed from your original:**

| File | Change |
|------|--------|
| `obsidian.lua` | Fully enabled — vault at `~/notes`, all note keymaps under `<leader>n`, LeetCode daily fetcher wired |
| `alpha.lua` | Added Notes shortcuts on dashboard, rotating dev quotes as footer |
| `misc.lua` | Fixed duplicate `scrollEOF`, enabled `flash.nvim` (`<leader>j/J`), added `yazi.nvim` (`<leader>Y`) |
| `lsp.lua` | Removed `copilot` from LSP servers (it's not an LSP), replaced `pylsp` → `basedpyright` + `ruff`, added `marksman` (markdown), `bashls` |

**Apply:**
```bash
cd ~/personal/dotfiles
stow -t ~ nvim
```

**Test:**
```bash
nvim                          # open dashboard — check new buttons + quote footer
<leader>nd                    # open today's daily note (needs obsidian.nvim installed)
<leader>j                     # flash jump (type a 2-char target)
<leader>Y                     # open yazi file manager (needs yazi installed)
:Mason                        # verify basedpyright, ruff, marksman, bashls are listed
:Lazy                         # verify obsidian.nvim, flash.nvim, yazi.nvim are loaded
```

**Notes vault structure (stowed from `dotfiles/notes/`):**
```
~/personal/notes/
├── daily/       ← daily notes (one per day)
├── projects/    ← one note per project
├── learning/    ← one note per topic
├── dsa/         ← LeetCode / algorithm notes
├── ai/          ← LLM / ML experiment notes
├── systems/     ← C/C++, OS, systems notes
└── templates/   ← daily_template.md, project_template.md, learning_template.md
```

> Note: obsidian.nvim workspace path should point to `~/personal/notes` in `obsidian.lua`

---

### 2. Taskwarrior (`dotfiles/taskwarrior/`)

**What it is:** Free, offline, terminal-native task manager. `task add` in under 1 second. No app, no browser, no slow load.

**Apply:**
```bash
cd ~/personal/dotfiles
stow -t ~ taskwarrior

# Stow puts .taskrc at ~/.config/taskwarrior/.taskrc
# but taskwarrior reads from ~/.taskrc by default — symlink it:
ln -sf ~/.config/taskwarrior/.taskrc ~/.taskrc

# Source aliases (or restart shell after install-dotfiles adds it to .zshrc)
source ~/.config/taskwarrior/taskrc_aliases.sh
```

**Install:**
```bash
sh ~/personal/dev-env/omarchy/install-taskwarrior.sh
```

**Test:**
```bash
task --version                        # should print version

# Add test tasks
task add "Test task 1" project:work priority:H due:today
task add "Read obsidian.nvim docs" project:learn +review
task add "Solve Two Sum" project:dsa +quick
task add "Set up Ollama" project:ship priority:M

task next                             # see urgency-sorted list
today                                 # alias: tasks due today
morning                               # alias: full morning standup view
twork                                 # alias: all work tasks
tdsa                                  # alias: all dsa tasks

task 1 done                           # mark first task done
timew start project:learn             # start time tracking
timew stop                            # stop
twday                                 # alias: see today's tracked time
```

**Your project buckets:**

| Project | Command | Purpose |
|---------|---------|---------|
| `work` | `twork` | Office tasks |
| `learn` | `tlearn` | Courses, reading |
| `dsa` | `tdsa` | LeetCode, algorithms |
| `ai` | `tai` | LLM experiments |
| `systems` | `tsys` | C/C++, OS internals |
| `ship` | `tship` | Side projects to deploy |
| `life` | `tlife` | Personal admin |

**iPhone sync (Inthe.AM):**
1. Sign up at [inthe.am](https://inthe.am) (free, login with Google)
2. Follow setup — get your cert files
3. Uncomment the sync block at the bottom of `~/.taskrc`
4. Run `task sync`

---

### 3. wtf Terminal Dashboard (`dotfiles/wtf/`)

**What it is:** A modular, keyboard-driven terminal dashboard. Opens in your terminal — shows tasks, system stats, git activity, GitHub, weather. No browser needed.

**Apply:**
```bash
cd ~/personal/dotfiles
stow -t ~ wtf
```

**Install:**
```bash
sh ~/personal/dev-env/omarchy/install-wtf.sh
```

**Test:**
```bash
wtf                                   # launch the dashboard
# Use arrow keys / mouse to focus panels
# Press '?' inside wtf for help
# Press 'q' or Ctrl+C to quit
```

**Modules in your config:**

| Panel | Location | Shows |
|-------|----------|-------|
| Clock | Top-left | IST + UTC time |
| System | Mid-left | CPU, RAM, disk |
| Git Repos | Bottom-left | Uncommitted changes across projects |
| Taskwarrior | Top-center | Your pending tasks |
| Scratch Pad | Bottom-center | Quick editable todo list (`~/.config/wtf/todo.md`) |
| GitHub | Top-right | PRs, issues (needs `GITHUB_TOKEN` env var) |
| Weather | Bottom-right | Auto-detected location, Celsius |

**GitHub token (for the GitHub panel):**
```bash
# Add to ~/.zshrc:
export GITHUB_TOKEN="ghp_your_token_here"
# Get a token: github.com → Settings → Developer Settings → Personal Access Tokens
# Use your Student Pack account
```

---

### 4. Startpage (`dotfiles/startpage/`, `install-startpage.sh`)

**What it is:** A custom HTML startpage served locally via a Python `http.server` systemd user service on port 4000. Accessible from the browser at `http://localhost:4000`. Glance and Homepage configs are kept in dotfiles for easy rollback.

**Apply:**
```bash
cd ~/personal/dotfiles
stow -R -t ~ startpage
```

**Install & run:**
```bash
sh ~/personal/dev-env/omarchy/install-startpage.sh
```

**Test:**
```bash
# Open in browser
xdg-open http://localhost:4000

# Check service status
systemctl --user status lifeos-startpage

# Restart
systemctl --user restart lifeos-startpage
```

**Rollback to Glance:**
```bash
systemctl --user stop lifeos-startpage
cd ~/personal/dotfiles
stow -R -t ~ glance
sh ~/personal/dev-env/omarchy/install-glance.sh
```

---

### 5. Ollama + Open WebUI (`install-ollama.sh`)

**What it is:** Run LLMs locally on your laptop. 100% private, no API keys, no cost. Open WebUI gives you a ChatGPT-like browser interface talking to your local models.

**Install:**
```bash
sh ~/personal/dev-env/omarchy/install-ollama.sh
```

**Test:**
```bash
# CLI
ollama list                           # see pulled models
ollama run qwen2.5-coder:7b           # chat in terminal (Ctrl+D to exit)
ollama run qwen2.5-coder:7b "explain recursion in C"

# Web UI
xdg-open http://localhost:3000        # Open WebUI in browser

# Pull more models (all free)
ollama pull llama3.2                  # Meta's Llama — great general model
ollama pull mistral                   # Mistral 7B — fast, good reasoning
ollama pull nomic-embed-text          # embeddings model for RAG projects
```

**Use inside Neovim (avante.nvim):**
```lua
-- In your copilot.lua, you can switch avante provider to ollama:
provider = 'ollama',
providers = {
  ollama = { model = 'qwen2.5-coder:7b' }
}
```

---

### 6. Yazi File Manager (`install-yazi.sh`)

**What it is:** A blazing fast terminal file manager with image previews, archive browsing, and native Neovim integration.

**Install:**
```bash
sh ~/personal/dev-env/omarchy/install-yazi.sh
```

**Test:**
```bash
yazi                                  # open in terminal
# Navigate: hjkl or arrow keys
# Open file: Enter
# Quit: q

# Inside Neovim (after stowing dotfiles):
# <leader>Y   → open yazi at current file
# <leader>fy  → open yazi at cwd
```

---

### 7. Dev Tools (`install-dev-tools.sh`)

Installs: `lazygit`, `gh` (GitHub CLI), `clang`, `lldb`, `cmake`, `stylua`, `anki`, `nodejs`, `npm`, `python-pip`

**Install:**
```bash
sh ~/personal/dev-env/omarchy/install-dev-tools.sh
```

**Test:**
```bash
lazygit                               # git TUI (run inside any git repo)
gh auth login                         # authenticate GitHub CLI
gh repo list                          # list your repos
clangd --version                      # C/C++ LSP
stylua --version                      # Lua formatter
anki                                  # open Anki flashcards app
```

---

## Quick Reference — All Keymaps Added

### Neovim — Notes (`<leader>n`)

| Keymap | Action |
|--------|--------|
| `<leader>nd` | Open today's daily note |
| `<leader>ny` | Open yesterday's note |
| `<leader>nm` | Open tomorrow's note |
| `<leader>nn` | Create new note |
| `<leader>nf` | Search notes (full-text grep) |
| `<leader>no` | Quick switch note (fuzzy) |
| `<leader>nb` | Show backlinks |
| `<leader>nt` | Browse by tag |
| `<leader>nl` | Show links in current note |
| `<leader>ni` | Insert template |
| `<leader>nk` | Link to existing note |
| `<leader>nDd` | Fetch today's LeetCode daily → create note in `dsa/` |

### Neovim — Navigation

| Keymap | Action |
|--------|--------|
| `<leader>j` | Flash jump (2-char label anywhere on screen) |
| `<leader>J` | Flash Treesitter jump |
| `<leader>Y` | Open Yazi at current file |
| `<leader>fy` | Open Yazi at cwd |

### Neovim — Git (new additions)

| Keymap | Action |
|--------|--------|
| `<leader>gs` | Git status (fugitive) |
| `<leader>gd` | Git diff split |
| `<leader>gb` | Git blame |

### Shell Aliases (taskwarrior)

| Alias | Command |
|-------|---------|
| `tn` | `task next` — what to work on now |
| `ta` | `task add` |
| `td` | `task done` |
| `twork/tlearn/tdsa/tai/tsys/tship` | Filter by project |
| `today` | Tasks due today |
| `overdue` | Past due tasks |
| `morning` | Full standup view |
| `twday` | Today's tracked time |

---

## Re-applying After Any Change

```bash
# After editing any dotfile:
cd ~/personal/dotfiles
git add .
git commit -m "your message"
git push

# After adding a new stow package:
cd ~/personal/dotfiles
stow -t ~ <package-name>

# Full nuclear reset (fresh machine or something broke):
cd ~/personal/dev-env/omarchy
sh master.sh
```
