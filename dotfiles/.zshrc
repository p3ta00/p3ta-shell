# ~/.zshrc — Kali host, Exegol-equivalent stack
# Oh My Zsh + plugins, Starship prompt, modern CLI tools.
# Stock Kali zshrc is saved as ~/.zshrc.kali-stock

# WSL convenience mode: interactive shells elevate once, while retaining
# p3ta's HOME and Zsh configuration. UID 0 prevents recursive elevation.
if [[ -o interactive && $EUID -ne 0 && -z ${WSL_NO_AUTO_ROOT:-} ]]; then
  exec sudo -E HOME="$HOME" ZDOTDIR="$HOME" /usr/bin/zsh -l
fi

export PATH="$HOME/.local/bin:$PATH"

# Don't clobber a capable client TERM (Tabby/Ghostty/WT). Only fix empties.
if [[ -z "$TERM" || "$TERM" == "dumb" ]]; then
  export TERM=xterm-256color
fi
export EDITOR="${EDITOR:-nvim}"

# Keep Herdr/Windows Terminal in normal line mode. Kitty CSI-u can otherwise
# turn Enter into literal ^M inside raw interactive programs such as Sliver.
if [[ -o interactive && -t 0 ]]; then
  printf '\033[<u' > /dev/tty 2>/dev/null
  stty sane icrnl onlcr echo 2>/dev/null
fi

# Sliver uses a raw remote shell, so normalize the TTY immediately before and
# after every client run instead of relying only on shell startup state.
sliver-client() {
  printf '\033[<u' > /dev/tty 2>/dev/null
  stty sane icrnl onlcr echo 2>/dev/null
  command sliver-client "$@"
  local rc=$?
  stty sane icrnl onlcr echo 2>/dev/null
  printf '\033[<u' > /dev/tty 2>/dev/null
  return $rc
}

# ── Oh My Zsh ──────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""                          # Starship owns the prompt
# Auto-root mode intentionally reuses p3ta-owned completion trees. Their
# group/other write bits are removed, so suppress only OMZ's owner mismatch.
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"        # faster paste
DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_AUTOSUGGEST_USE_ASYNC=1
HIST_STAMPS="yyyy-mm-dd"

# zsh-completions (custom plugin) must be on fpath before omz.sh
fpath+="${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src"

plugins=(
  git
  sudo
  extract
  colored-man-pages
  command-not-found
  docker
  fzf
  zsh-completions
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-history-substring-search   # after highlighting; type nxc then Up
)

# OMZ fzf plugin: binary is in PATH (~/.local/bin or /usr/bin)
export FZF_BASE="${FZF_BASE:-$HOME/.local/bin}"

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  autoload -Uz compinit
  mkdir -p "$HOME/.cache"
  compinit -d "$HOME/.cache/zcompdump"
fi

# ── Exegol overlay (starship, zoxide, eza/bat aliases, history) ────────────
[[ -f "$HOME/.config/zsh/exegol.zsh" ]] && source "$HOME/.config/zsh/exegol.zsh"

# Added by cua-driver-rs installer — see https://github.com/trycua/cua
export PATH="$HOME/.local/bin:$PATH"

# loadout tool PATHs
[ -f /etc/profile.d/loadout.sh ] && . /etc/profile.d/loadout.sh
if [[ -x "$HOME/pk/omnidigit/tvenv/bin/python" ]]; then
  alias python="$HOME/pk/omnidigit/tvenv/bin/python"
  alias python3="$HOME/pk/omnidigit/tvenv/bin/python"
fi

# grok installer
export PATH="$HOME/.grok/bin:$PATH"
[[ -d "$HOME/.grok/completions/zsh" ]] && fpath=("$HOME/.grok/completions/zsh" $fpath)
# <<< grok installer <<<

# kimi-code
[[ -d "$HOME/.kimi-code/bin" ]] && export PATH="$HOME/.kimi-code/bin:$PATH"

# --- local LLM on pve (coder :8097, 27B :8095, big :8096) ---
export LLM_HOST=192.168.1.206
coder() { python3 ~/.local/bin/llm-stream.py 8097 qwen3-coder "$@"; }   # Qwen3-Coder, tool-building
big()   { python3 ~/.local/bin/llm-stream.py 8096 cyber-frost "$@"; }   # CYBER-FROST 180B
ask()   { python3 ~/.local/bin/llm-stream.py 8095 qwen3.8-27b "$@"; }   # general 27B
llm-status() {
  for pm in "8097:coder" "8095:27B" "8096:big"; do
    p=${pm%%:*}; printf "%-5s %s: " "$p" "${pm##*:}"
    curl -s --max-time 3 http://$LLM_HOST:$p/v1/models | jq -er ".data[0].id" 2>/dev/null || echo down
  done
}
# --- end local LLM ---
