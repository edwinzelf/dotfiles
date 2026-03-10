#!/usr/bin/env bash
set -euo pipefail

DOTDIR="${HOME}/dotfiles"
BACKUP_DIR="${DOTDIR}/backups/$(date -u +%Y%m%dT%H%M%SZ)"

# Ensure directories exist
mkdir -p "${BACKUP_DIR}"
mkdir -p "${HOME}/.config/bat" "${HOME}/.config/btop" "${HOME}/.config/fastfetch" \
         "${HOME}/.config/htop" "${HOME}/.config/micro/colorschemes" \
         "${HOME}/.config/nano/themes" "${HOME}/.config/vivid"

# Helper: backup and symlink a single file
link_file() {
  local src="$1" dst="$2"
  if [ ! -e "${src}" ]; then
    return 0
  fi

  # If destination exists and isn't already a symlink to src, back it up
  if [ -e "${dst}" ] && [ ! -L "${dst}" -o "$(readlink -f "${dst}")" != "$(readlink -f "${src}")" ]; then
    echo "Backing up ${dst} -> ${BACKUP_DIR}/"
    mkdir -p "$(dirname "${BACKUP_DIR}/${dst#$HOME/}")"
    mv -v "${dst}" "${BACKUP_DIR}/${dst#$HOME/}"
  fi

  # Ensure target parent dir exists
  mkdir -p "$(dirname "${dst}")"

  # Create/replace symlink
  ln -sfn "${src}" "${dst}"
  echo "Linked ${dst} -> ${src}"
}

# Symlink home-level files (whitelist)
link_file "${DOTDIR}/.zshrc" "${HOME}/.zshrc"
link_file "${DOTDIR}/.nanorc" "${HOME}/.nanorc"
link_file "${DOTDIR}/.gitconfig" "${HOME}/.gitconfig"

# Symlink config-level files (whitelist)
[ -f "${DOTDIR}/.config/fastfetch/config.jsonc" ] && link_file "${DOTDIR}/.config/fastfetch/config.jsonc" "${HOME}/.config/fastfetch/config.jsonc"
[ -f "${DOTDIR}/.config/micro/settings.json" ] && link_file "${DOTDIR}/.config/micro/settings.json" "${HOME}/.config/micro/settings.json"
[ -f "${DOTDIR}/.config/micro/colorschemes/mocha.micro" ] && link_file "${DOTDIR}/.config/micro/colorschemes/mocha.micro" "${HOME}/.config/micro/colorschemes/mocha.micro"
[ -f "${DOTDIR}/.config/nano/themes/mocha.nanorc" ] && link_file "${DOTDIR}/.config/nano/themes/mocha.nanorc" "${HOME}/.config/nano/themes/mocha.nanorc"

# Link directories (replace if present in DOTDIR)
if [ -d "${DOTDIR}/.config/vivid" ]; then
  ln -sfn "${DOTDIR}/.config/vivid" "${HOME}/.config/vivid"
  echo "Linked ~/.config/vivid"
fi

if [ -d "${DOTDIR}/.config/bat" ]; then
  ln -sfn "${DOTDIR}/.config/bat" "${HOME}/.config/bat"
  echo "Linked ~/.config/bat"
fi

if [ -d "${DOTDIR}/.config/btop" ]; then
  ln -sfn "${DOTDIR}/.config/btop" "${HOME}/.config/btop"
  echo "Linked ~/.config/btop"
fi

# --- Install common Zsh plugins (if missing) ---
install_git_clone_if_missing() {
  local repo="$1" dest="$2"
  if [ ! -d "${dest}" ]; then
    echo "Installing ${repo##*/} -> ${dest}"
    git clone --depth 1 "https://github.com/${repo}.git" "${dest}"
  else
    echo "${dest} already present"
  fi
}

install_git_clone_if_missing "zsh-users/zsh-history-substring-search" "${HOME}/.zsh-history-substring-search"
install_git_clone_if_missing "zsh-users/zsh-autosuggestions" "${HOME}/.zsh-autosuggestions"
install_git_clone_if_missing "zsh-users/zsh-syntax-highlighting" "${HOME}/.zsh-syntax-highlighting"

# Optional: make zsh the login shell for the current user (uncomment if desired)
# if command -v chsh >/dev/null 2>&1; then
#   echo "Changing default shell to zsh for user ${USER}"
#   chsh -s "$(command -v zsh)" "${USER}" || true
# fi

# Git init & commit if needed
cd "${DOTDIR}"
if [ ! -d .git ]; then
  git init
  git add --all
  git commit -m "Initial import of strict dotfiles"
  echo "Local git repo created in ${DOTDIR}. Add a remote with: git remote add origin <url>"
else
  # Stage changes and make a commit if any
  git add --all
  if ! git diff --cached --quiet; then
    git commit -m "Update dotfiles: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  else
    echo "No changes to commit."
  fi
fi

echo "Install script finished. Backups (if any) are in: ${BACKUP_DIR}"
