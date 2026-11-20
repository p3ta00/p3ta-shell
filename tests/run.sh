#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$REPO_DIR/bin/p3ta-shell"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

[[ -x "$CLI" ]] || fail 'bin/p3ta-shell must exist and be executable'

if grep -Eq '^[[:space:]]*install_dotfile ' "$REPO_DIR/install.sh"; then
  fail 'install.sh must not activate dotfiles'
fi
if grep -Eq '^[[:space:]]*run chsh ' "$REPO_DIR/install.sh"; then
  fail 'install.sh must not change the login shell'
fi
pass 'installer leaves configuration inactive'

sandbox="$(mktemp -d)"
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/home" "$sandbox/payload"
cp -a "$REPO_DIR/dotfiles" "$sandbox/payload/dotfiles"

HOME="$sandbox/home" P3TA_SHELL_PAYLOAD="$sandbox/payload" "$CLI" enable --no-chsh --no-sync

for item in \
  .zshrc \
  .zprofile \
  .config/starship.toml \
  .config/zsh \
  .config/herdr \
  .config/nvim \
  .config/zellij \
  .config/alacritty; do
  [[ -e "$sandbox/home/$item" ]] || fail "enable did not install $item"
done
pass 'enable activates every managed dotfile'

printf 'original\n' > "$sandbox/home/.zshrc"
HOME="$sandbox/home" P3TA_SHELL_PAYLOAD="$sandbox/payload" "$CLI" enable --no-chsh --no-sync
compgen -G "$sandbox/home/.zshrc.p3ta-shell-*.bak" >/dev/null || fail 'enable did not back up existing dotfile'
pass 'enable backs up existing configuration'

status_output="$(HOME="$sandbox/home" P3TA_SHELL_PAYLOAD="$sandbox/payload" "$CLI" status)"
grep -q 'enabled' <<<"$status_output" || fail 'status did not report enabled'
pass 'status reports enabled configuration'
