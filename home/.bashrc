#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# --- Import pywal colors ---
if [ -f ~/.cache/wal/sequences ]; then
    (cat ~/.cache/wal/sequences &)

alias lavat='lavat -c yellow'

fi

# Created by `pipx` on 2026-05-13 01:18:25
export PATH="$PATH:$HOME/.local/bin"

export EDITOR="mousepad"

alias f='fastfetch'
alias gf='fastfetch --logo gentoo'
alias sgf='fastfetch --logo gentoo_small'
alias vf='fastfetch --logo void'
alias lf='fastfetch --logo lfs'
alias af='fastfetch --logo arch'
alias saf='fastfetch --logo arch_small'
alias y='yazi'
alias c='cava'
alias l='lavat'
alias p='peaclock'
alias b='btop'
alias u='unimatrix'

export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:~/.local/share/flatpak/exports/share"

export PS1="$> "
