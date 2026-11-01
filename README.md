# Iridium Shell — Hyprland + Quickshell dotfiles

Hyprland (Lua config) desktop with a full Quickshell shell: bar/island, control center,
launcher, notifications, lockscreen, wallpaper picker, infinite desktop, gaming panel and
built-in apps (file explorer, text editor, gallery, music player).

## Install (Arch Linux)

One line (clones into `~/dotfiles`, or updates it, then runs the installer):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sarodscommits/IridumShell-IridiumDots/main/bootstrap.sh)
```

Arguments after `bootstrap.sh` are passed to `install.sh`. Running it again pulls the
latest changes and re-links everything.

Then log out and pick the **Hyprland** session.

Options:

| Flag | Effect |
|---|---|
| `--skip-packages` | only link configs and do system setup |
| `--skip-system` | skip groups, `i2c-dev` and services |
| `--dry-run` | print what would be done |

What the installer does:

1. Installs `packages/pacman.txt`, `yay` (if missing), `packages/aur.txt` and `packages/pipx.txt`.
2. Symlinks `config/*` into `~/.config/` and `home/.bashrc` into `~/`.
   Existing files are moved to `~/.dotfiles-backup/<date>/`.
3. Creates `~/Wallpapers` and the cache folders the shell uses.
4. Adds you to the `input` and `i2c` groups, loads `i2c-dev`, enables NetworkManager,
   bluetooth, power-profiles-daemon, lactd, ydotool and sddm (if no display manager is set).

## Layout

```
config/quickshell   the shell (shell.qml entry point, backends in scripts/)
config/hypr         hyprland.lua + window scripts used by binds (scripts/)
config/matugen      color templates
config/kitty        terminal
config/cava         visualizer
config/fastfetch    fetch
config/yazi         file manager (TUI)
config/MangoHud     FPS logging for the gaming panel
home/.bashrc
packages/           pacman / AUR / pipx lists
```

Files the shell generates per machine (`hypr/monitors.lua`, `hypr/keyboard.lua`,
`hypr/appearance.lua`, `quickshell/prefs.json`, colors…) are git-ignored; `hyprland.lua`
falls back to defaults when they're missing.

## Wallpapers

Put images or videos in `~/Wallpapers` and open the picker with **Super+W**.
