#!/usr/bin/env bash
# Installs the Hyprland + Quickshell environment on Arch Linux.
#   ./install.sh                 full install
#   ./install.sh --skip-packages only links configs + system setup
#   ./install.sh --skip-system   no groups / services / kernel modules
#   ./install.sh --dry-run       print what would be done
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
CONFIGS=(quickshell hypr matugen kitty cava fastfetch yazi MangoHud)
HOME_FILES=(.bashrc)

SKIP_PACKAGES=0 SKIP_SYSTEM=0 DRY=0
for a in "$@"; do
    case "$a" in
        --skip-packages) SKIP_PACKAGES=1 ;;
        --skip-system)   SKIP_SYSTEM=1 ;;
        --dry-run)       DRY=1 ;;
        -h|--help)       sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $a" >&2; exit 1 ;;
    esac
done

c_info=$'\e[1;34m' c_ok=$'\e[1;32m' c_warn=$'\e[1;33m' c_err=$'\e[1;31m' c_off=$'\e[0m'
info() { printf '%s==>%s %s\n' "$c_info" "$c_off" "$*"; }
ok()   { printf '%s  ✓%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '%s  !%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '%serror:%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }
run()  { if (( DRY )); then echo "  [dry-run] $*"; else "$@"; fi; }

# Package list without comments / blank lines
pkglist() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

# checks
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root (sudo is used when needed)."
[[ -f /etc/arch-release ]] || die "This installer only supports Arch Linux."
command -v sudo >/dev/null || die "sudo is required."

# ── packages ──
install_aur_helper() {
    if command -v yay >/dev/null; then AUR=yay; return; fi
    if command -v paru >/dev/null; then AUR=paru; return; fi
    info "Installing yay (AUR helper)"
    local tmp; tmp="$(mktemp -d)"
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && run makepkg -si --noconfirm)
    rm -rf "$tmp"
    AUR=yay
}

install_packages() {
    info "Updating system and installing official packages"
    run sudo pacman -Syu --needed --noconfirm $(pkglist "$REPO/packages/pacman.txt")
    ok "pacman packages"

    install_aur_helper
    info "Installing AUR packages with $AUR"
    run "$AUR" -S --needed --noconfirm $(pkglist "$REPO/packages/aur.txt")
    ok "AUR packages"

    info "Installing pipx apps"
    run pipx ensurepath >/dev/null
    for p in $(pkglist "$REPO/packages/pipx.txt"); do
        if pipx list --short 2>/dev/null | grep -q "^$p "; then ok "$p already installed"
        else run pipx install "$p"; fi
    done
}

# ── config links ──
link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        ok "$dst already linked"; return
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        run mkdir -p "$BACKUP"
        run mv "$dst" "$BACKUP/"
        warn "backed up $dst → $BACKUP/"
    fi
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
    ok "$dst → $src"
}

link_configs() {
    info "Linking configs"
    for d in "${CONFIGS[@]}"; do link "$REPO/config/$d" "$HOME/.config/$d"; done
    for f in "${HOME_FILES[@]}"; do link "$REPO/home/$f" "$HOME/$f"; done
    run chmod +x "$REPO"/config/hypr/scripts/*.py "$REPO"/config/quickshell/scripts/*.sh "$REPO"/config/quickshell/scripts/*.py
}

# ── user folders / caches the shell expects ──
setup_dirs() {
    info "Creating user folders"
    run xdg-user-dirs-update
    run mkdir -p "$HOME/Wallpapers" "$HOME/.cache/wal" "$HOME/.cache/wallpaper-selector" \
                 "$HOME/.cache/mangohud-logs" "$HOME/.config/easyeffects/output"
    if [[ -z "$(ls -A "$HOME/Wallpapers" 2>/dev/null)" ]]; then
        warn "~/Wallpapers is empty: add images/videos there and pick one with Super+W"
    fi
    ok "folders"
}

# groups, kernel modules, services
setup_system() {
    info "Adding $USER to the input (infinite desktop) and i2c (ddcutil) groups"
    getent group i2c >/dev/null || run sudo groupadd -r i2c
    run sudo usermod -aG input,i2c "$USER"

    info "Loading i2c-dev at boot (external monitor brightness)"
    if (( DRY )); then echo "  [dry-run] write /etc/modules-load.d/i2c-dev.conf"
    else echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null; fi
    run sudo modprobe i2c-dev || true

    info "Enabling services"
    for s in NetworkManager bluetooth power-profiles-daemon lactd; do
        run sudo systemctl enable --now "$s" || warn "could not enable $s"
    done
    run systemctl --user enable --now ydotool 2>/dev/null || warn "could not enable ydotool (user)"
    if ! systemctl is-enabled display-manager.service >/dev/null 2>&1; then
        run sudo systemctl enable sddm
        ok "sddm enabled (pick the Hyprland session at login)"
    else
        ok "a display manager is already enabled"
    fi
}

info "Installing from $REPO"
(( SKIP_PACKAGES )) || install_packages
link_configs
setup_dirs
(( SKIP_SYSTEM )) || setup_system

echo
ok "Done. Log out and back in (or reboot) so the new groups and services apply."
[[ -d "$BACKUP" ]] && warn "Your previous configs were saved in $BACKUP"
exit 0
