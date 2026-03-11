#!/usr/bin/env bash

# FZF Configuration
if command -v fzf > /dev/null 2>&1; then
    # Prefer built-in initializer when available (typically on macOS/Homebrew)
    if fzf --zsh > /dev/null 2>&1; then
        source <(fzf --zsh)
    else
        # Linux/WSL fallback: source from common distro paths or user install
        for f in \
            /usr/share/doc/fzf/examples/key-bindings.zsh \
            /usr/share/doc/fzf/examples/completion.zsh \
            /usr/share/fzf/key-bindings.zsh \
            /usr/share/fzf/completion.zsh \
            "$HOME/.fzf.zsh"; do
            [[ -f "$f" ]] && source "$f"
        done
    fi

    # FZF options
    export FZF_DEFAULT_OPTS="
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=fg:#e4e4e4,bg:#24283b,hl:#f7768e
        --color=fg+:#e4e4e4,bg+:#414868,hl+:#f7768e
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7
        --color=marker:#9ece6a,spinner:#bb9af7,header:#73daca"

    # Use ripgrep if available for better search performance
    if command -v rg > /dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs -g "!{.git,node_modules}/*" 2>/dev/null'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # FZF completion settings
    export FZF_COMPLETION_TRIGGER='**'

    # Custom fzf functions

    # fe - edit file with fzf
    fe() {
        local files
        IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
        [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
    }
fi
