# p3ta-shell

One-command Kali/Debian terminal workstation bootstrap. It installs the same shell tools, Tokyo Night neon theme, prompt, editor, multiplexer, and keyboard behavior used by p3ta's Kali environment.

## Included

- Alacritty with the matching Tokyo Night neon palette and JetBrainsMono Nerd Font
- Herdr with p3ta's theme and shortcuts
- Zsh + Oh My Zsh + completions, autosuggestions, syntax highlighting, and substring history
- Starship prompt with p3ta's palette
- NvChad/Neovim configuration and locked plugins
- Yazi/Zoxide-style modern navigation stack, plus eza, bat, fd, fzf, ripgrep, btop, Zellij, and tmux
- Kali-safe TTY handling for Herdr/Sliver and the same arrows/Home/End/Ctrl key behavior

## Install

```bash
git clone https://github.com/p3ta00/p3ta-shell.git
cd p3ta-shell
./install.sh
```

To also install Kali's full default tool metapackage:

```bash
./install.sh --full
```

Preview actions without modifying the machine:

```bash
./install.sh --dry-run
```

The installer is idempotent. Existing managed files are timestamped as `*.p3ta-shell-YYYYmmdd-HHMMSS.bak` before replacement.

## Herdr keys

Prefix is `Ctrl+A`.

| Action | Key |
|---|---|
| Split vertical | `Ctrl+A`, then `N` |
| Split horizontal | `Ctrl+A`, then `M` |
| Rename tab | `Ctrl+A`, then `,` |

## Notes

- Run on a fresh Kali/Debian install as your normal user; the script elevates with `sudo`.
- NvChad plugins are synced headlessly during install and can retry on first `nvim` launch.
- No histories, credentials, SSH keys, logs, sockets, or machine-specific secrets are included.
