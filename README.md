# p3ta-shell

Two-stage Kali/Debian terminal workstation bootstrap. The installer installs every requirement without touching your current dotfiles. Run `p3ta-shell enable` later to activate p3ta's complete theme, prompt, editor, multiplexer, and keyboard configuration.

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

This stage installs the applications, plugins, font, and an inactive copy of the configuration. It does **not** replace dotfiles, change the login shell, or initialize NvChad.

To also install Kali's full default tool metapackage:

```bash
./install.sh --full
```

Preview actions without modifying the machine:

```bash
./install.sh --dry-run
```

## Enable the configuration

When you are ready to load the dotfiles and themes:

```bash
p3ta-shell enable
```

This activates Zsh, Starship, Alacritty, Herdr, NvChad, and Zellij configuration, changes the login shell to Zsh, and synchronizes NvChad plugins. Existing managed files are first timestamped as `*.p3ta-shell-*.bak`.

Useful commands:

```bash
p3ta-shell status
p3ta-shell enable --dry-run
p3ta-shell enable --no-chsh
p3ta-shell enable --no-sync
```

The installer and enable command are idempotent. Running `enable` again backs up the currently active files before refreshing them from the installed payload.

## Herdr keys

Prefix is `Ctrl+A`.

| Action | Key |
|---|---|
| Split vertical | `Ctrl+A`, then `N` |
| Split horizontal | `Ctrl+A`, then `M` |
| Rename tab | `Ctrl+A`, then `,` |

## Notes

- Run on a fresh Kali/Debian install as your normal user; the script elevates with `sudo`.
- NvChad plugins are synced by `p3ta-shell enable` and can retry on first `nvim` launch.
- No histories, credentials, SSH keys, logs, sockets, or machine-specific secrets are included.
