# Kali VM shell — same look AND behavior as Exegol
# Sourced from ~/.zshrc AFTER Oh My Zsh. Do not re-source OMZ plugins here.

export PATH="$HOME/.local/bin:$PATH"
export EDITOR="${EDITOR:-nvim}"
export XCURSOR_SIZE=24

# ── Prompt: Starship ───────────────────────────────────────────────────────
export EXEGOL_CONTAINER="${EXEGOL_CONTAINER:-kali}"
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Don't let leftover prompt hooks fight Starship
if typeset -f add-zsh-hook >/dev/null 2>&1; then
  add-zsh-hook -d precmd update_prompt 2>/dev/null || true
  add-zsh-hook -d precmd gentoo_precmd 2>/dev/null || true
fi
# Kali stock zshrc defined a function named precmd() which shadows hook arrays.
# If OMZ isn't in charge yet, drop it so Starship's precmd actually runs.
if typeset -f precmd >/dev/null 2>&1; then
  unfunction precmd 2>/dev/null || true
fi

# ── Live syntax colors (OMZ already loaded the plugin) ─────────────────────
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ff10f0,bold'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ff10f0,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#00ff9f'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#00ff9f'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#00ff9f'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#00ff9f'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#00ff9f'
ZSH_HIGHLIGHT_STYLES[default]='none'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=green'
ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'

# Fallback if OMZ plugins aren't installed yet
if [[ ${+ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE} -eq 1 ]] && ! typeset -f _zsh_autosuggest_start >/dev/null 2>&1; then
  [[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
if [[ -z ${ZSH_HIGHLIGHT_VERSION:-} ]]; then
  [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ── Modern CLI tools ───────────────────────────────────────────────────────
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi

export BAT_THEME="Dracula"
export FZF_DEFAULT_OPTS="--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export EZA_COLORS="da=1;34:gm=1;34"
export DELTA_FEATURES="+side-by-side"

# fzf keybindings (Ctrl-R history, Ctrl-T files, Alt-C cd) if OMZ didn't
if ! typeset -f fzf-history-widget >/dev/null 2>&1; then
  for _fzf_kb in \
    /usr/share/doc/fzf/examples/key-bindings.zsh \
    /usr/share/fzf/key-bindings.zsh \
    "$HOME/.fzf.zsh"
  do
    [[ -f "$_fzf_kb" ]] && source "$_fzf_kb" && break
  done
  unset _fzf_kb
fi

# ── Aliases ────────────────────────────────────────────────────────────────
BIN="$HOME/.local/bin"
alias home='cd ~'
alias ..='cd ..'
alias ...='cd ../..'
alias ls="$BIN/eza --icons --group-directories-first"
alias ll="$BIN/eza --icons --group-directories-first -l"
alias la="$BIN/eza --icons --group-directories-first -la"
alias lt="$BIN/eza --icons --group-directories-first --tree"
alias l="$BIN/eza --icons --group-directories-first -F"
alias cat="$BIN/bat --style=plain --paging=never --binary=as-text"
alias catp="$BIN/bat --style=full"
command -v fd >/dev/null && alias fd="$BIN/fd"
command -v delta >/dev/null && alias diff="$BIN/delta"
command -v btop >/dev/null && alias top="btop"
command -v rg >/dev/null && alias rg="$BIN/rg"
alias zj="$BIN/zellij options --theme dracula"
alias zellij="$BIN/zellij"
alias yazi="$BIN/yazi"
alias h='history'
alias ports='ss -tulanp'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'

# ── History (shared across panes) ──────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
# SHARE_HISTORY writes accepted commands immediately and imports commands from
# other Herdr panes. INC_APPEND_HISTORY conflicts with SHARE_HISTORY, so keep it
# disabled and explicitly import newly appended entries before every prompt.
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS
unsetopt INC_APPEND_HISTORY INC_APPEND_HISTORY_TIME
unsetopt HIST_VERIFY

_p3ta_history_sync() {
  fc -RI "$HISTFILE" 2>/dev/null || true
}
if typeset -f add-zsh-hook >/dev/null 2>&1; then
  add-zsh-hook precmd _p3ta_history_sync
fi
# Import HISTFILE now. zsh -c skips this; a real interactive shell needs it
# especially after converting mixed old/extended history formats.
if [[ -o interactive && -f "$HISTFILE" ]]; then
  fc -R "$HISTFILE" 2>/dev/null || true
fi

# ── Keybindings: type "nxc" then Up to walk matching history ───────────────
bindkey -e
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
HISTORY_SUBSTRING_SEARCH_FUZZY=
if typeset -f history-substring-search-up >/dev/null 2>&1; then
  _hist_up=history-substring-search-up
  _hist_down=history-substring-search-down
else
  _hist_up=up-line-or-beginning-search
  _hist_down=down-line-or-beginning-search
fi

bindkey '^P'  $_hist_up
bindkey '^N'  $_hist_down
bindkey '^[[A' $_hist_up
bindkey '^[[B' $_hist_down
bindkey '^[OA' $_hist_up
bindkey '^[OB' $_hist_down
# Herdr/Kitty keyboard protocol emits explicit unmodified parameters.
bindkey '^[[1A'   $_hist_up
bindkey '^[[1B'   $_hist_down
bindkey '^[[1;1A' $_hist_up
bindkey '^[[1;1B' $_hist_down
# extra CSI variants from Tabby / Windows Terminal / Ghostty
bindkey '^[[1;2A' $_hist_up
bindkey '^[[1;2B' $_hist_down
bindkey '^[[1;3A' $_hist_up
bindkey '^[[1;3B' $_hist_down
bindkey '^[[1;5A' $_hist_up
bindkey '^[[1;5B' $_hist_down
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" $_hist_up
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" $_hist_down
unset _hist_up _hist_down
# Home / End — every sequence Windows terminals send
bindkey '^[[H'  beginning-of-line
bindkey '^[[F'  end-of-line
bindkey '^[OH'  beginning-of-line
bindkey '^[OF'  end-of-line
bindkey '^[[1~' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^[[7~' beginning-of-line
bindkey '^[[8~' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[Z' undo
# Autosuggest accept
bindkey '^[[C' forward-char
bindkey '^ ' autosuggest-accept 2>/dev/null || true

# ── Functions ──────────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1" }
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz)  tar xzf "$1" ;;
      *.bz2)     bunzip2 "$1" ;;
      *.rar)     unrar e "$1" ;;
      *.gz)      gunzip "$1" ;;
      *.tar)     tar xf "$1" ;;
      *.tbz2)    tar xjf "$1" ;;
      *.tgz)     tar xzf "$1" ;;
      *.zip)     unzip "$1" ;;
      *.Z)       uncompress "$1" ;;
      *.7z)      7z x "$1" ;;
      *) echo "'$1' cannot be extracted" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

TARGET_ENV_FILE="${TARGET_ENV_FILE:-$HOME/.target.env}"
[ -f "$TARGET_ENV_FILE" ] && source "$TARGET_ENV_FILE"
tset() {
  if [ $# -lt 2 ]; then echo "usage: tset KEY value" >&2; return 1; fi
  local k="$1"; shift; local v="$*"
  touch "$TARGET_ENV_FILE"
  sed -i "/^export ${k}=/d" "$TARGET_ENV_FILE"
  printf 'export %s=%q\n' "$k" "$v" >> "$TARGET_ENV_FILE"
  export "$k=$v"
  echo "set $k"
}
alias treload='source "$TARGET_ENV_FILE"'
alias tclear='> "$TARGET_ENV_FILE" && echo "cleared $TARGET_ENV_FILE"'
alias tshow='[ -f "$TARGET_ENV_FILE" ] && cat "$TARGET_ENV_FILE" || echo "(empty)"'

# Zellij autostart disabled - launch manually with `zellij` or the `zj` alias.
# if [[ -o interactive ]] && [[ -z "$ZELLIJ" ]] && [[ -z "$SSH_CONNECTION" ]] && [[ -n "$DISPLAY" ]] && command -v zellij >/dev/null 2>&1; then
#   exec zellij
# fi

# SSH: drop leftover xterm mouse/window reports so clicks do not dump CSI into zsh.
if [[ -o interactive ]] && [[ -n "$SSH_CONNECTION" ]]; then
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1015l\e[?9l'
  unset zle_bracketed_paste 2>/dev/null || true
fi
