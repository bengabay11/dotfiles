#!/usr/bin/env bash

# Installation utility functions for dotfiles setup
# Cross-platform compatibility: supports both macOS and Linux
# This file should be sourced by installation scripts

# OS Detection utilities
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Get package manager for current OS
get_package_manager() {
    if is_macos; then
        echo "brew"
    elif is_linux; then
        if command -v apt >/dev/null 2>&1; then
            echo "apt"
        elif command -v yum >/dev/null 2>&1; then
            echo "yum"
        elif command -v pacman >/dev/null 2>&1; then
            echo "pacman"
        elif command -v zypper >/dev/null 2>&1; then
            echo "zypper"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# Function to check if an application is installed (cross-platform)
# Usage: is_app_installed "AppName" [package_name]
# For macOS: "Google Chrome" or "Visual Studio Code"
# For Linux: package names like "firefox", "code", "chromium-browser"
is_app_installed() {
    local app_name="$1"
    local package_name="$2"
    
    if is_macos; then
        # macOS application detection
        local app_path="/Applications/${app_name}.app"
        local user_app_path="$HOME/Applications/${app_name}.app"
        
        # Check system Applications directory
        if [[ -d "$app_path" ]]; then
            return 0
        fi
        
        # Check user Applications directory
        if [[ -d "$user_app_path" ]]; then
            return 0
        fi
        
        # Check if installed via Homebrew Cask (fallback)
        if [[ -n "$package_name" ]] && brew list --cask "$package_name" >/dev/null 2>&1; then
            return 0
        fi
    elif is_linux; then
        # Linux application detection
        local search_name="${package_name:-$app_name}"
        
        # Check if it's available as a command
        if command -v "$search_name" >/dev/null 2>&1; then
            return 0
        fi
        
        # Check common Linux package managers
        local pkg_manager=$(get_package_manager)
        case "$pkg_manager" in
            "apt")
                if dpkg -l | grep -q "^ii.*$search_name" 2>/dev/null; then
                    return 0
                fi
                ;;
            "yum"|"dnf")
                if rpm -qa | grep -q "$search_name" 2>/dev/null; then
                    return 0
                fi
                ;;
            "pacman")
                if pacman -Qi "$search_name" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            "zypper")
                if zypper se -i "$search_name" | grep -q "^i" 2>/dev/null; then
                    return 0
                fi
                ;;
        esac
        
        # Check for flatpak
        if command -v flatpak >/dev/null 2>&1; then
            if flatpak list | grep -q "$search_name" 2>/dev/null; then
                return 0
            fi
        fi
        
        # Check for snap
        if command -v snap >/dev/null 2>&1; then
            if snap list | grep -q "$search_name" 2>/dev/null; then
                return 0
            fi
        fi
    fi
    
    return 1
}

# Function to get the proper application name for display/detection (cross-platform)
# Maps package names to display names and Linux equivalents
get_app_display_name() {
    local package_name="$1"
    
    if is_macos; then
        # macOS app display names
        case "$package_name" in
            "google-chrome")
                echo "Google Chrome"
                ;;
            "brave-browser")
                echo "Brave Browser"
                ;;
            "visual-studio-code")
                echo "Visual Studio Code"
                ;;
            "sublime-text")
                echo "Sublime Text"
                ;;
            "iterm2")
                echo "iTerm"
                ;;
            "raycast")
                echo "Raycast"
                ;;
            "cursor")
                echo "Cursor"
                ;;
            "pycharm")
                echo "PyCharm CE"
                ;;
            "slack")
                echo "Slack"
                ;;
            "obsidian")
                echo "Obsidian"
                ;;
            "warp")
                echo "Warp"
                ;;
            "dbeaver-community")
                echo "DBeaver"
                ;;
            *)
                # Default: capitalize first letter of each word, replace dashes with spaces
                echo "$package_name" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g'
                ;;
        esac
    elif is_linux; then
        # Linux package/command names
        case "$package_name" in
            "google-chrome")
                echo "google-chrome"
                ;;
            "brave-browser")
                echo "brave-browser"
                ;;
            "visual-studio-code")
                echo "code"
                ;;
            "sublime-text")
                echo "subl"
                ;;
            "cursor")
                echo "cursor"
                ;;
            "slack")
                echo "slack"
                ;;
            "obsidian")
                echo "obsidian"
                ;;
            "dbeaver-community")
                echo "dbeaver"
                ;;
            "firefox")
                echo "firefox"
                ;;
            "chromium")
                echo "chromium-browser"
                ;;
            *)
                # Default: use as-is for Linux
                echo "$package_name"
                ;;
        esac
    else
        # Fallback for unknown OS
        echo "$package_name"
    fi
}

# Function to check if a CLI tool is installed (cross-platform)
# Usage: is_cli_tool_installed "tool-name" [command-name]
# Returns 0 if installed, 1 if not installed
is_cli_tool_installed() {
    local package_name="$1"
    local cmd_name="${2:-$1}"  # Use package_name as default if cmd_name not provided
    
    # Handle special cases where command name differs from package name
    case "$package_name" in
        "python@3.11"|"python3")
            cmd_name="python3"
            ;;
        "typescript")
            cmd_name="tsc"
            ;;
        "git-delta")
            cmd_name="delta"
            ;;
        "ripgrep")
            cmd_name="rg"
            ;;
        "fd-find")
            cmd_name="fd"
            ;;
    esac
    
    # First check if command is available in system PATH
    if command -v "$cmd_name" >/dev/null 2>&1; then
        return 0
    fi
    
    if is_macos; then
        # Check if installed via Homebrew on macOS
        if brew list "$package_name" >/dev/null 2>&1; then
            return 0
        fi
    elif is_linux; then
        # Check Linux package managers
        local pkg_manager=$(get_package_manager)
        case "$pkg_manager" in
            "apt")
                if dpkg -l | grep -q "^ii.*$package_name" 2>/dev/null; then
                    return 0
                fi
                ;;
            "yum"|"dnf")
                if rpm -qa | grep -q "$package_name" 2>/dev/null; then
                    return 0
                fi
                ;;
            "pacman")
                if pacman -Qi "$package_name" >/dev/null 2>&1; then
                    return 0
                fi
                ;;
            "zypper")
                if zypper se -i "$package_name" | grep -q "^i" 2>/dev/null; then
                    return 0
                fi
                ;;
        esac
    fi
    
    return 1
}

# Function to determine installation source for a CLI tool (cross-platform)
# Usage: get_cli_tool_source "package-name" "command-name"
get_cli_tool_source() {
    local package_name="$1"
    local cmd_name="${2:-$1}"
    
    # Handle special cases
    case "$package_name" in
        "python@3.11"|"python3")
            cmd_name="python3"
            ;;
        "typescript")
            cmd_name="tsc"
            ;;
        "git-delta")
            cmd_name="delta"
            ;;
        "ripgrep")
            cmd_name="rg"
            ;;
        "fd-find")
            cmd_name="fd"
            ;;
    esac
    
    # Check if command is available
    if ! command -v "$cmd_name" >/dev/null 2>&1; then
        echo "not_installed"
        return
    fi
    
    if is_macos; then
        # Check if installed via Homebrew on macOS
        if brew list "$package_name" >/dev/null 2>&1; then
            echo "homebrew"
        else
            echo "system"
        fi
    elif is_linux; then
        # Check Linux package managers
        local pkg_manager=$(get_package_manager)
        case "$pkg_manager" in
            "apt")
                if dpkg -l | grep -q "^ii.*$package_name" 2>/dev/null; then
                    echo "apt"
                else
                    echo "system"
                fi
                ;;
            "yum"|"dnf")
                if rpm -qa | grep -q "$package_name" 2>/dev/null; then
                    echo "$pkg_manager"
                else
                    echo "system"
                fi
                ;;
            "pacman")
                if pacman -Qi "$package_name" >/dev/null 2>&1; then
                    echo "pacman"
                else
                    echo "system"
                fi
                ;;
            "zypper")
                if zypper se -i "$package_name" | grep -q "^i" 2>/dev/null; then
                    echo "zypper"
                else
                    echo "system"
                fi
                ;;
            *)
                echo "system"
                ;;
        esac
    else
        echo "system"
    fi
}

# Function to get version info for a CLI tool (cross-platform)
# Usage: get_cli_tool_version "command-name"
get_cli_tool_version() {
    local cmd_name="$1"
    
    case "$cmd_name" in
        "git")
            git --version 2>/dev/null || echo "version unknown"
            ;;
        "vim")
            vim --version 2>/dev/null | head -1 || echo "version unknown"
            ;;
        "tmux")
            tmux -V 2>/dev/null || echo "version unknown"
            ;;
        "zsh")
            zsh --version 2>/dev/null || echo "version unknown"
            ;;
        "python3")
            python3 --version 2>/dev/null || echo "version unknown"
            ;;
        "node")
            node --version 2>/dev/null || echo "version unknown"
            ;;
        "npm")
            npm --version 2>/dev/null || echo "version unknown"
            ;;
        "yarn")
            yarn --version 2>/dev/null || echo "version unknown"
            ;;
        "tsc")
            tsc --version 2>/dev/null || echo "version unknown"
            ;;
        "fzf")
            fzf --version 2>/dev/null || echo "version unknown"
            ;;
        "delta")
            delta --version 2>/dev/null || echo "version unknown"
            ;;
        "rg"|"ripgrep")
            rg --version 2>/dev/null || echo "version unknown"
            ;;
        "bat"|"batcat")
            { command -v bat >/dev/null 2>&1 && bat --version; } 2>/dev/null || \
            { command -v batcat >/dev/null 2>&1 && batcat --version; } 2>/dev/null || \
            echo "version unknown"
            ;;
        "rustc")
            rustc --version 2>/dev/null || echo "version unknown"
            ;;
        "cargo")
            cargo --version 2>/dev/null || echo "version unknown"
            ;;
        "pyenv")
            pyenv --version 2>/dev/null || echo "version unknown"
            ;;
        "uv")
            uv --version 2>/dev/null || echo "version unknown"
            ;;
        "helm")
            helm version --short 2>/dev/null || helm version 2>/dev/null | head -1 || echo "version unknown"
            ;;
        "kubectl")
            kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null || echo "version unknown"
            ;;
        "docker")
            docker --version 2>/dev/null || echo "version unknown"
            ;;
        "terraform")
            terraform version 2>/dev/null | head -1 || echo "version unknown"
            ;;
        "aws")
            aws --version 2>/dev/null || echo "version unknown"
            ;;
        "btop")
            btop --version 2>/dev/null || echo "version unknown"
            ;;
        "htop")
            htop --version 2>/dev/null || echo "version unknown"
            ;;
        "nmap")
            nmap --version 2>/dev/null | head -1 || echo "version unknown"
            ;;
        "speedtest-cli")
            speedtest-cli --version 2>/dev/null || echo "version unknown"
            ;;
        *)
            # Try common version flags in order of preference
            "$cmd_name" --version 2>/dev/null || \
            "$cmd_name" -version 2>/dev/null || \
            "$cmd_name" version 2>/dev/null || \
            echo "version unknown"
            ;;
    esac
}
