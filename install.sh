#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
FULL=0
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    --full) FULL=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) printf 'Usage: %s [--full] [--dry-run]\n' "$0"; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
  esac
done

run() { printf '+ '; printf '%q ' "$@"; printf '\n'; (( DRY_RUN )) || "$@"; }
as_user() { if [[ $(id -u) -eq 0 && "$TARGET_USER" != root ]]; then run sudo -u "$TARGET_USER" -H "$@"; else run "$@"; fi; }
backup_path() {
  local p="$1"
  [[ ! -e "$p" && ! -L "$p" ]] && return 0
  local stamp; stamp="$(date +%Y%m%d-%H%M%S)"
  run mv "$p" "${p}.p3ta-shell-${stamp}.bak"
}
install_dotfile() {
  local rel="$1" src="$REPO_DIR/dotfiles/$1" dst="$TARGET_HOME/$1"
  run mkdir -p "$(dirname "$dst")"
  backup_path "$dst"
  run cp -a "$src" "$dst"
  run chown -R "$TARGET_USER:$TARGET_USER" "$dst"
}

[[ -r /etc/os-release ]] || { echo 'Unsupported system: /etc/os-release missing' >&2; exit 1; }
. /etc/os-release
[[ "${ID:-}" == kali || "${ID_LIKE:-}" == *debian* ]] || echo "Warning: designed for Kali/Debian, found ${ID:-unknown}" >&2

if [[ $(id -u) -ne 0 ]]; then
  exec sudo --preserve-env=USER bash "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
run apt-get update
BASE_PACKAGES=(
  alacritty bat btop build-essential ca-certificates curl eza fd-find fontconfig fzf
  git git-delta jq neovim pipx ripgrep starship tmux unzip wget zoxide zsh
  zsh-autosuggestions zsh-syntax-highlighting
)
run apt-get install -y "${BASE_PACKAGES[@]}"
if (( FULL )); then
  run apt-get install -y kali-linux-default
fi

# Predictable command names on Debian/Kali.
run mkdir -p "$TARGET_HOME/.local/bin"
[[ -x /usr/bin/batcat ]] && run ln -sfn /usr/bin/batcat "$TARGET_HOME/.local/bin/bat"
[[ -x /usr/bin/fdfind ]] && run ln -sfn /usr/bin/fdfind "$TARGET_HOME/.local/bin/fd"

# Oh My Zsh and the plugins referenced by the checked-in .zshrc.
if [[ ! -d "$TARGET_HOME/.oh-my-zsh/.git" ]]; then
  as_user git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$TARGET_HOME/.oh-my-zsh"
fi
ZCUSTOM="$TARGET_HOME/.oh-my-zsh/custom/plugins"
for spec in \
  'zsh-users/zsh-completions:zsh-completions' \
  'zsh-users/zsh-autosuggestions:zsh-autosuggestions' \
  'zsh-users/zsh-syntax-highlighting:zsh-syntax-highlighting' \
  'zsh-users/zsh-history-substring-search:zsh-history-substring-search'; do
  repo="${spec%%:*}" name="${spec##*:}"
  [[ -d "$ZCUSTOM/$name/.git" ]] || as_user git clone --depth 1 "https://github.com/$repo.git" "$ZCUSTOM/$name"
done

# Static tools not currently packaged by Kali rolling.
install_github_archive() {
  local repo="$1" asset="$2" binary="$3" extra_binary="${4:-}"
  [[ -x "$TARGET_HOME/.local/bin/$binary" ]] && return 0
  local tmp url
  tmp="$(mktemp -d)"
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | jq -r --arg a "$asset" '.assets[] | select(.name == $a) | .browser_download_url' | head -n1)"
  [[ -n "$url" && "$url" != null ]] || { echo "Could not resolve $repo asset $asset" >&2; return 1; }
  run curl -fsSL -o "$tmp/archive" "$url"
  case "$asset" in
    *.zip) run unzip -q "$tmp/archive" -d "$tmp/out" ;;
    *.tar.gz|*.tgz) run mkdir -p "$tmp/out"; run tar -xzf "$tmp/archive" -C "$tmp/out" ;;
  esac
  run find "$tmp/out" -type f -name "$binary" -exec install -m 0755 '{}' "$TARGET_HOME/.local/bin/$binary" \;
  if [[ -n "$extra_binary" ]]; then
    run find "$tmp/out" -type f -name "$extra_binary" -exec install -m 0755 '{}' "$TARGET_HOME/.local/bin/$extra_binary" \;
  fi
  run chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/$binary"
  [[ -z "$extra_binary" ]] || run chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.local/bin/$extra_binary"
  run rm -rf "$tmp"
}
case "$(uname -m)" in
  x86_64)
    install_github_archive sxyazi/yazi "yazi-x86_64-unknown-linux-gnu.zip" yazi ya
    install_github_archive zellij-org/zellij "zellij-x86_64-unknown-linux-musl.tar.gz" zellij
    ;;
  *) echo "Warning: Yazi/Zellij static installation is currently configured for x86_64 only." >&2 ;;
esac

# Herdr's canonical installer installs to the target user's ~/.local/bin.
if [[ ! -x "$TARGET_HOME/.local/bin/herdr" ]]; then
  as_user sh -c 'curl -fsSL https://herdr.dev/install.sh | sh'
fi

# Nerd Font used by Alacritty/Herdr/NvChad icons.
FONT_DIR="$TARGET_HOME/.local/share/fonts/JetBrainsMonoNerd"
if [[ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
  tmp="$(mktemp -d)"
  run curl -fsSL -o "$tmp/font.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
  run mkdir -p "$FONT_DIR"
  run unzip -q "$tmp/font.zip" -d "$FONT_DIR"
  run chown -R "$TARGET_USER:$TARGET_USER" "$FONT_DIR"
  run rm -rf "$tmp"
  run fc-cache -f
fi

for item in .zshrc .zprofile .config/starship.toml .config/zsh .config/herdr .config/nvim .config/zellij .config/alacritty; do
  install_dotfile "$item"
done

run chsh -s /usr/bin/zsh "$TARGET_USER"

# Prime NvChad plugins headlessly; a network hiccup should not erase configs.
as_user nvim --headless '+Lazy! sync' +qa || echo 'Warning: NvChad plugin sync failed; run nvim later to retry.' >&2

printf '\nInstalled p3ta-shell for %s. Start a new login shell with: exec zsh -l\n' "$TARGET_USER"
printf 'Herdr shortcuts: Ctrl+A then N (vertical), Ctrl+A then M (horizontal), Ctrl+A then comma (rename tab).\n'
