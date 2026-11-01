#!/usr/bin/env bash
# Downloads the dotfiles into ~/dotfiles (or updates them) and runs install.sh.
#   bash <(curl -fsSL https://raw.githubusercontent.com/sarodscommits/IridumShell-IridiumDots/main/bootstrap.sh)
# Extra arguments are passed to install.sh (e.g. --skip-packages, --dry-run).
# Env: DOTFILES_DIR (default ~/dotfiles), DOTFILES_BRANCH (default main).
set -euo pipefail

REPO_SLUG="sarodscommits/IridumShell-IridiumDots"
REPO_URL="https://github.com/$REPO_SLUG.git"
DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"

c_info=$'\e[1;34m' c_warn=$'\e[1;33m' c_err=$'\e[1;31m' c_off=$'\e[0m'
info() { printf '%s==>%s %s\n' "$c_info" "$c_off" "$*"; }
warn() { printf '%s  !%s %s\n' "$c_warn" "$c_off" "$*"; }
die()  { printf '%serror:%s %s\n' "$c_err" "$c_off" "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."
[[ -f /etc/arch-release ]] || die "Only Arch Linux is supported."

need() { command -v "$1" >/dev/null || { info "Installing $2"; sudo pacman -S --needed --noconfirm "$2"; }; }
need git git

# Public repo: plain clone. Private repo: authenticate with GitHub CLI first.
clone() {
    if GIT_TERMINAL_PROMPT=0 git ls-remote "$REPO_URL" >/dev/null 2>&1; then
        git clone --branch "$BRANCH" "$REPO_URL" "$DIR"
        return
    fi
    warn "Repository is private or unreachable; using GitHub CLI"
    need gh github-cli
    gh auth status >/dev/null 2>&1 || gh auth login --hostname github.com --git-protocol https --web
    gh auth setup-git
    gh repo clone "$REPO_SLUG" "$DIR" -- --branch "$BRANCH"
}

if [[ -d "$DIR/.git" ]]; then
    info "Updating $DIR"
    git -C "$DIR" pull --ff-only origin "$BRANCH" || die "Could not fast-forward $DIR (local changes?). Resolve it and rerun."
else
    if [[ -e "$DIR" ]]; then
        bak="$DIR.bak-$(date +%Y%m%d-%H%M%S)"
        warn "$DIR exists and is not a git repo; moving it to $bak"
        mv "$DIR" "$bak"
    fi
    info "Cloning $REPO_SLUG into $DIR"
    clone
fi

info "Running installer"
exec bash "$DIR/install.sh" "$@"
