#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
REPO_SSH="git@github.com:edwinzelf/dotfiles.git"
DOTDIR="$HOME/dotfiles"
PACKAGES=(git curl wget zsh fzf micro nano bat btop fastfetch jq htop sudo)

log() { printf "\e[34m[INFO]\e[0m %s\n" "$*"; }

# 1. APT Bootstrap
log "Updating system and installing requirements..."
sudo apt update && sudo apt install -y "${PACKAGES[@]}"

# 2. Handle GitHub Authentication (The Easy Way)
if command -v gh >/dev/null 2>&1; then
    log "GitHub CLI found. Let's authenticate (this handles SSH keys automatically)."
    gh auth login -w -p ssh
else
    log "GitHub CLI not found. Falling back to manual SSH setup."
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        ssh-keygen -t ed25519 -C "root@debian13" -N "" -f ~/.ssh/id_ed25519
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
    fi
    echo "-------------------------------------------------------"
    cat ~/.ssh/id_ed25519.pub
    echo "-------------------------------------------------------"
    echo "COPY the key above to: https://github.com/settings/ssh/new"
    read -p "Press [Enter] once added to GitHub..."
fi

# 3. Clone Dotfiles
if [ ! -d "$DOTDIR" ]; then
    log "Cloning dotfiles..."
    git clone "$REPO_SSH" "$DOTDIR"
else
    log "Dotfiles already exist. Pulling latest..."
    git -C "$DOTDIR" pull
fi

# 4. Run the Production Installer
log "Running Mocha Production Installer..."
cd "$DOTDIR"
chmod +x install.sh
./install.sh --bootstrap

log "Setup Complete! Restart your terminal or type 'zsh' to enter the Mocha zone."
