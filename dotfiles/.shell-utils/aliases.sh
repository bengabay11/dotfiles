#!/usr/bin/env bash

# Cross shell compatible aliases
# This file can be sources by bash, zsh, and other POSIX-compliant shell

# Core
alias cat="bat"
alias ls="eza --icons --hyperlink --sort=type"
alias quit="exit"
alias speedtest="speedtest-cli"
alias ipython="ipython3"
alias cd="z"
alias grep="rg"
alias cp="cp -irv"

# Python
alias source_poetry='source "$(poetry env info --path)/bin/activate"'

# AWS
alias sso="aws sso login"

# Platform specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias open='xdg-open'
    alias bat="batcat"
    alias fd="fdfind"
fi
