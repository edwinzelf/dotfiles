#!/usr/bin/env bash
set -euo pipefail

DOTDIR="${HOME}/dotfiles"
BACKUP_DIR="${DOTDIR}/backups/$(date -u +%Y%m%dT%H%M%SZ)"
PACKAGES=(git curl wget zsh fzf micro nano bat btop fastfetch jq htop sudo zoxide command-not-found)
BOOTSTRAP=false
PUSH_REMOTE=false
USE_GH_CREATE=false
REMOTE_URL=""

log() { printf '%s\n' "$*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [--bootstrap] [--remote] [--gh-create] [--remote-url URL]

Options:
  --bootstrap      Install recommended packages via apt (interactive/automated).
  --remote         Interactively add a Git remote and push (asks for URL if none supplied).
  --gh-create      If --remote is used and 'gh' is installed, create the repo with GitHub CLI.
  --remote-url URL Provide remote URL non-interactively.
  -h, --help       Show this help.
EOF
  exit 0
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
    --bootstrap) BOOTSTRAP=true; shift;;
    --remote) PUSH_REMOTE=true; shift;;
    --gh-create) USE_GH_CREATE=true; shift;;
    --remote-url) REMOTE_URL="$2"; shift 2;;
    -h|--help) usage;;
    *) log "Unknown arg: $1"; usage;;
  esac
done

# Create backup dir
mkdir -p "${BACKUP_DIR}"

# Optional bootstrap (apt)
run_bootstrap() {
  if ! command -v apt >/dev/null 2>&1; then
    log "apt not found; bootstrap skipped."
    return
  fi

  log "Running apt update..."
  sudo apt update

  # Install packages (skip ones already installed)
  local to_install=()
  for pkg in "${PACKAGES[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      to_install+=("$pkg")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    log "Installing packages: ${to_install[*]}"
    sudo apt install -y "${to_install[@]}"
  else
    log "All packages already installed."
  fi

  # Optional extras: install micro plugin manager or other extras here if desired
  log "Bootstrap complete."
}

# Helper: backup and symlink a single file
link_file() {
  local src="$1" dst="$2"
  if [ ! -e "${src}" ]; then
    return 0
  fi

  # If destination exists and isn't already a symlink to src, back it up
  if [ -e "${dst}" ] && { [ ! -L "${dst}" ] || [ "$(readlink -f "${dst}")" != "$(readlink -f "${src}")" ]; }; then
    log "Backing up ${dst} -> ${BACKUP_DIR}/"
    mkdir -p "${BACKUP_DIR}/$(dirname "${dst#$HOME/}")"
    mv -v "${dst}" "${BACKUP_DIR}/${dst#$HOME/}"
  fi

  mkdir -p "$(dirname "${dst}")"
  ln -sfn "${src}" "${dst}"
  log "Linked ${dst} -> ${src}"
}

# Ensure target directories exist (whitelist)
mkdir -p "${HOME}/.config/bat" "${HOME}/.config/btop" "${HOME}/.config/fastfetch" \
         "${HOME}/.config/htop" "${HOME}/.config/micro/colorschemes" \
         "${HOME}/.config/nano/themes" "${HOME}/.config/vivid"

# Home-level whitelist
link_file "${DOTDIR}/.zshrc" "${HOME}/.zshrc"
link_file "${DOTDIR}/.nanorc" "${HOME}/.nanorc"
link_file "${DOTDIR}/.gitconfig" "${HOME}/.gitconfig"

# Config-level whitelist
[ -f "${DOTDIR}/.config/fastfetch/config.jsonc" ] && link_file "${DOTDIR}/.config/fastfetch/config.jsonc" "${HOME}/.config/fastfetch/config.jsonc"
[ -f "${DOTDIR}/.config/micro/settings.json" ] && link_file "${DOTDIR}/.config/micro/settings.json" "${HOME}/.config/micro/settings.json"
[ -f "${DOTDIR}/.config/micro/colorschemes/mocha.micro" ] && link_file "${DOTDIR}/.config/micro/colorschemes/mocha.micro" "${HOME}/.config/micro/colorschemes/mocha.micro"
[ -f "${DOTDIR}/.config/nano/themes/mocha.nanorc" ] && link_file "${DOTDIR}/.config/nano/themes/mocha.nanorc" "${HOME}/.config/nano/themes/mocha.nanorc"

# Link directories (replace if present in DOTDIR)
if [ -d "${DOTDIR}/.config/vivid" ]; then
  ln -sfn "${DOTDIR}/.config/vivid" "${HOME}/.config/vivid"
  log "Linked ~/.config/vivid"
fi
if [ -d "${DOTDIR}/.config/bat" ]; then
  ln -sfn "${DOTDIR}/.config/bat" "${HOME}/.config/bat"
  log "Linked ~/.config/bat"
fi
if [ -d "${DOTDIR}/.config/btop" ]; then
  ln -sfn "${DOTDIR}/.config/btop" "${HOME}/.config/btop"
  log "Linked ~/.config/btop"
fi

# Install common Zsh plugins (if missing)
install_git_clone_if_missing() {
  local repo="$1" dest="$2"
  if [ ! -d "${dest}" ]; then
    log "Installing ${repo##*/} -> ${dest}"
    git clone --depth 1 "https://github.com/${repo}.git" "${dest}"
  else
    log "${dest} already present"
  fi
}

install_git_clone_if_missing "zsh-users/zsh-history-substring-search" "${HOME}/.zsh-history-substring-search"
install_git_clone_if_missing "zsh-users/zsh-autosuggestions" "${HOME}/.zsh-autosuggestions"
install_git_clone_if_missing "zsh-users/zsh-syntax-highlighting" "${HOME}/.zsh-syntax-highlighting"

# Optional: make zsh the login shell for the current user (safe prompt)
if [ "$(id -u)" -ne 0 ]; then
  if [ -n "${SHELL-}" ] && [ "$(basename "${SHELL}")" != "zsh" ]; then
    if command -v chsh >/dev/null 2>&1; then
      log "You can change your login shell to zsh with: chsh -s $(command -v zsh)"
    fi
  fi
else
  log "Running as root; skipping automatic chsh."
fi

# Git init & commit (idempotent)
cd "${DOTDIR}"
if [ ! -d .git ]; then
  git init
  git add --all
  git commit -m "Initial import of strict dotfiles"
  log "Local git repo created in ${DOTDIR}. Add a remote with: git remote add origin <url>"
else
  git add --all
  if ! git diff --cached --quiet; then
    git commit -m "Update dotfiles: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  else
    log "No changes to commit."
  fi
fi

# Remote handling / pushing
create_or_add_remote_and_push() {
  # Ensure git identity (local) is set
  if ! git config user.email >/dev/null; then
    log "Git user.email not set for this repo. Set it now (local only):"
    read -rp "Your Name: " g_name
    read -rp "Your Email: " g_email
    git config user.name "$g_name"
    git config user.email "$g_email"
  fi

  if [ -n "${REMOTE_URL}" ]; then
    remote="${REMOTE_URL}"
  else
    read -rp "Remote URL (leave blank to use interactive GitHub creation if available): " remote
  fi

  if [ -z "${remote}" ] && command -v gh >/dev/null 2>&1 && [ "${USE_GH_CREATE}" = true ]; then
    log "Creating GitHub repo using 'gh' (interactive)."
    # Try to create private repo by default
    gh repo create --private --source="${DOTDIR}" --remote=origin --push || {
      log "gh create failed or cancelled. Please add remote manually."
      return
    }
    log "Repo created and pushed using gh."
    return
  fi

  if [ -n "${remote}" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
      log "Origin exists; updating url to ${remote}"
      git remote set-url origin "${remote}"
    else
      git remote add origin "${remote}"
    fi
    git branch -M main || true
    log "Pushing to origin main..."
    git push -u origin main
    log "Push complete."
  else
    log "No remote specified. Skipping push."
  fi
}

# Run bootstrap if requested
if [ "${BOOTSTRAP}" = true ]; then
  run_bootstrap
fi

# Run remote push if requested
if [ "${PUSH_REMOTE}" = true ]; then
  create_or_add_remote_and_push
fi

log "Install script finished. Backups (if any) are in: ${BACKUP_DIR}"
