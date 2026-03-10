#!/usr/bin/env bash
set -euo pipefail
DOTDIR="$HOME/dotfiles"

# Create required target dirs
mkdir -p ~/.config/bat ~/.config/btop ~/.config/fastfetch ~/.config/htop \
         ~/.config/micro/colorschemes ~/.config/nano/themes ~/.config/vivid

# Symlink home files
ln -sfn "$DOTDIR/.zshrc" ~/.zshrc       || true
ln -sfn "$DOTDIR/.nanorc" ~/.nanorc     || true
ln -sfn "$DOTDIR/.gitconfig" ~/.gitconfig || true

# Symlink config files (whitelist)
[ -f "$DOTDIR/.config/fastfetch/config.jsonc" ] && ln -sfn "$DOTDIR/.config/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
[ -f "$DOTDIR/.config/micro/settings.json" ] && ln -sfn "$DOTDIR/.config/micro/settings.json" ~/.config/micro/settings.json
[ -f "$DOTDIR/.config/micro/colorschemes/mocha.micro" ] && ln -sfn "$DOTDIR/.config/micro/colorschemes/mocha.micro" ~/.config/micro/colorschemes/mocha.micro
[ -f "$DOTDIR/.config/nano/themes/mocha.nanorc" ] && ln -sfn "$DOTDIR/.config/nano/themes/mocha.nanorc" ~/.config/nano/themes/mocha.nanorc

# Link other folders if present
if [ -d "$DOTDIR/.config/vivid" ]; then
  ln -sfn "$DOTDIR/.config/vivid" ~/.config/vivid
fi

if [ -d "$DOTDIR/.config/bat" ]; then
  ln -sfn "$DOTDIR/.config/bat" ~/.config/bat
fi

if [ -d "$DOTDIR/.config/btop" ]; then
  ln -sfn "$DOTDIR/.config/btop" ~/.config/btop
fi

# Git init (if not already a repo)
cd "$DOTDIR"
if [ ! -d .git ]; then
  git init
  git add --all
  git commit -m "Initial import of strict dotfiles"
  echo "Local git repo created in $DOTDIR. Add a remote with: git remote add origin https://github.com/YOUR_USER/dotfiles.git"
else
  echo "Git repo already exists in $DOTDIR"
fi

echo "Symlinks created. Done."
