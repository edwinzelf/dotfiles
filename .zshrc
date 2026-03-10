# ~/.zshrc - Catppuccin Mocha (cleaned & fixed)
# ------------------------------------------------------------------------------

# 0) Basic options
setopt PROMPT_SUBST            # allow variable/command expansion in PROMPT
setopt appendhistory sharehistory

# 1) Environment
export BAT_THEME="Catppuccin Mocha"
export MICRO_TRUECOLOR=1
export COLORTERM=truecolor
export HISTTIMEFORMAT="%d/%m/%y %T "
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# 2) History / completion setup
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
autoload -Uz compinit && compinit

# 3) fzf keybindings & completion (if installed)
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# 4) LS / colors (vivid)
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-mocha)"
fi

# 5) Aliases
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first --git --color-scale all"
  alias ll="ls -lgh"
  alias la="ll -a"
  alias lt="ls --tree"
  alias tree="lt"
else
  alias ls='ls --color=auto'
  alias ll='ls -alF'
  alias la='ls -A'
fi

alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias conf-zsh='micro ~/.zshrc'
alias conf-fetch='micro ~/.config/fastfetch/config.jsonc'
alias reload='source ~/.zshrc && echo "Zsh reloaded!"'
alias dot-push='cd ~/dotfiles && git add . && git commit -m "Update: $(date)" && git push'


# 6) Fastfetch (interactive-only)
if [[ -o interactive ]] && command -v fastfetch &>/dev/null; then
  clear
  fastfetch
fi

# 7) Prompt (Mocha)
PROMPT='%F{147}%n%f@%F{224}%m%f %F{183}%~%f %(?:%F{121}#:%F{167}#)%f '

# 8) Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# 9) Plugins - load autosuggestions first (so it doesn't capture keys we bind later)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# 10) History substring search - ensure plugin exists, source it
if [ -f ~/.zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
  source ~/.zsh-history-substring-search/zsh-history-substring-search.zsh
else
  # fallback: try system package path (if installed via apt)
  if [ -f /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh ]; then
    source /usr/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  fi
fi

# 11) Other plugins: syntax highlighting should be last
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# 12) Force arrow-key bindings AT THE VERY END (prevent overrides)
# Use terminfo if available, otherwise fall back to common escapes.
if [[ -n $terminfo[kcuu1] && -n $terminfo[kcud1] ]]; then
  bindkey "${terminfo[kcuu1]}" history-substring-search-up
  bindkey "${terminfo[kcud1]}" history-substring-search-down
else
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^[OA' history-substring-search-up
  bindkey '^[OB' history-substring-search-down
fi

# 13) Highlighting options for history-substring-search (Mocha-ish)
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=magenta,bold'
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='fg=red,bold'

# 14) Optional: thefuck alias (if installed)
if command -v thefuck &>/dev/null; then
  eval $(thefuck --alias)
fi

eval "$(zoxide init zsh)"
alias cd="z"

alias -g G='| grep --color=auto'
alias -g L='| less'
alias -g M='| micro'
alias -g H='| head -n 20'

source /etc/zsh_command_not_found


# End of file
# ------------------------------------------------------------------------------
