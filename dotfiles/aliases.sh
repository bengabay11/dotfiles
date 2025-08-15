#!/usr/bin/env bash

# Cross shell compatible aliases
# This file can be sources by bash, zsh, and other POSIX-compliant shell

# Core
alias cat=bat
alias ls="eza --icons --hyperlink --sort=type"
alias locate=mdfind
alias quit="exit"
alias speedtest="speedtest-cli"
alias ipython=ipython3

# AWS
alias sso="aws sso login"

# Platform specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias open='xdg-open'
    alias bat="batcat"
fi
