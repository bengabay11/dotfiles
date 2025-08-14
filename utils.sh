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
        "openjdk")
            cmd_name="java"
            ;;
        "default-jdk")
            cmd_name="java"
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
        "openjdk")
            cmd_name="java"
            ;;
        "default-jdk")
            cmd_name="java"
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
        "java")
            # Prefer modern --version, fallback to -version (stderr)
            java --version 2>/dev/null | head -1 || java -version 2>&1 | head -1 || echo "version unknown"
            ;;
        "watch")
            watch --version 2>/dev/null | head -1 || echo "version unknown"
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

try_install_tool () {
    local tool_name="$1"
    local tool_command_name="$2"
    local tool_install_command="$3"
    local tool_version_command="$4"
    if ! command -v $tool_command_name >/dev/null 2>&1; then
        log_install $tool_name
        if ! $tool_install_command; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($($tool_version_command 2>/dev/null || echo version unknown))"
    fi
}

installation_success_message() {
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}🎉 Installation Complete!${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
}

show_failure_summary() {
    if [[ ${#FAILED_INSTALLATIONS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}╭─────────────────────────────────────────────────╮${NC}"
        echo -e "${RED}│${NC} ${YELLOW}⚠️  Installation Failures Summary${NC}              ${RED}│${NC}"
        echo -e "${RED}╰─────────────────────────────────────────────────╯${NC}"
        echo ""
        log_warning "The following items failed to install:"
        echo ""
        for failed_item in "${FAILED_INSTALLATIONS[@]}"; do
            log_error "  • $failed_item"
        done
        echo ""
        log_info "These failures do not affect the successfully installed tools."
        log_info "You can try installing the failed items manually later."
        echo ""
    fi
}

process_stages() {
    local -n stages_ref="$1"
    for stage_info in "${stages_ref[@]}"; do
        IFS='|' read -r description function_name default_yes condition <<< "$stage_info"
        if confirm_stage "$description" "$default_yes"; then
            if ! "$function_name"; then
                log_error "Stage '$description' failed - continuing"
            fi
        fi
    done
}

log_info_interactive_mode_status() {
    if [[ -n "${CI:-}" ]] || [[ -n "${NONINTERACTIVE:-}" ]] || [[ "${AUTO_YES:-false}" == "true" ]]; then
        if [[ "${AUTO_YES:-false}" == "true" ]]; then
            log_info "Running in auto-yes mode - proceeding with all stages"
        else
            log_info "Running in automated mode - proceeding with all stages"
        fi
    else
        log_info "Interactive mode - you'll be prompted for each stage"
        log_info "Tip: Use -y or --yes flag to skip all prompts"
    fi
}

install_rust() {
    if command -v rustc >/dev/null 2>&1; then
        local version=$(rustc --version 2>/dev/null || echo "version unknown")
        log_found "Rust is already installed ($version)"
    else
        log_install "Rust programming language"
        if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
            log_error "Failed to install Rust - continuing with installation"
            FAILED_INSTALLATIONS+=("Rust (programming language)")
        else
            source "$HOME/.cargo/env"
            log_success "Rust installed successfully"
        fi
    fi
}

setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    # Create necessary directories
    mkdir -p "$HOME/.config"
    mkdir -p "$HOME/.config/shell-utils"
    
    local dotfiles=(".vimrc" ".tmux.conf" ".zshrc" ".gitconfig")
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$dotfile" ]]; then
            log_warning "Backing up existing $dotfile to $dotfile.backup"
            mv "$HOME/$dotfile" "$HOME/$dotfile.backup"
        fi
        ln -sf "$DOTFILES_ROOT/dotfiles/$dotfile" "$HOME/$dotfile"
    done
    
    log_info "Setting up modular shell utilities..."
    if [[ -f "$DOTFILES_ROOT/dotfiles/shell-utils.sh" ]]; then
        cp "$DOTFILES_ROOT/dotfiles/shell-utils.sh" "$HOME/.config/shell-utils/shell-utils.sh"
        log_success "Shell utilities installed to ~/.config/shell-utils/"
    else
        log_warning "shell-utils.sh not found - skipping utilities setup"
    fi
    if [[ -f "$DOTFILES_ROOT/dotfiles/aliases.sh" ]]; then
        cp "$DOTFILES_ROOT/dotfiles/aliases.sh" "$HOME/.config/shell-utils/aliases.sh"
        log_success "Aliases installed to ~/.config/shell-utils/"
    else
        log_warning "aliases.sh not found - skipping aliases setup"
    fi
    
    log_info "You can now add more utility files to ~/.config/shell-utils/ and they will be automatically loaded"
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_found "Oh My Zsh is already installed"
    else
        log_install "Oh My Zsh shell framework"
        if ! RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_error "Failed to install Oh My Zsh - continuing with installation"
            FAILED_INSTALLATIONS+=("Oh My Zsh (shell framework)")
        else
            log_success "Oh My Zsh installed successfully"
        fi
    fi
}

# Install Oh My Zsh plugins and themes
install_zsh_plugins() {
    log_info "Installing Zsh plugins and themes..."
    
    # Ensure Oh My Zsh is installed first
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "Oh My Zsh must be installed before installing plugins"
        return 1
    fi
    
    # Set ZSH_CUSTOM if not already set
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # Create custom plugins and themes directories if they don't exist
    mkdir -p "$zsh_custom/plugins"
    mkdir -p "$zsh_custom/themes"
    
    # Define plugins to install
    local plugins=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|plugins"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git|plugins"
        "powerlevel10k|https://github.com/romkatv/powerlevel10k.git|themes"
    )
    
    # Install each plugin/theme
    for plugin_info in "${plugins[@]}"; do
        # Parse plugin information (name|repo_url|type)
        IFS='|' read -r name repo_url install_type <<< "$plugin_info"
        
        local install_path="$zsh_custom/$install_type/$name"
        
        if [[ -d "$install_path" ]]; then
            log_found "$name is already installed"
        else
            log_install "$name"
            
            # Special handling for powerlevel10k (shallow clone for performance)
            if [[ "$name" == "powerlevel10k" ]]; then
                if ! git clone --depth=1 "$repo_url" "$install_path"; then
                    log_error "Failed to install $name - continuing with remaining plugins"
                    FAILED_INSTALLATIONS+=("$name (Zsh plugin/theme)")
                    continue
                fi
            else
                if ! git clone "$repo_url" "$install_path"; then
                    log_error "Failed to install $name - continuing with remaining plugins"
                    FAILED_INSTALLATIONS+=("$name (Zsh plugin/theme)")
                    continue
                fi
            fi
            
            log_success "$name installed successfully"
        fi
    done
    
    log_success "All Zsh plugins and themes installed successfully"
}

install_latest_python() {
    local latest_python
    latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    
    if [[ -n "$latest_python" ]]; then
        try_install_tool "Latest Python $latest_python" "pyenv versions --bare | grep -Fx $latest_python" \
        "pyenvs install "$latest_python" --skip-existing" "echo $latest_python"
        # log_install "Python $latest_python (via pyenv)"
        # if ! pyenv install "$latest_python" --skip-existing; then
        #     log_error "Failed to install Python $latest_python - continuing with installation"
        #     FAILED_INSTALLATIONS+=("Python $latest_python (via pyenv)")
        # else
        #     if ! pyenv global "$latest_python"; then
        #         log_error "Failed to set global Python version - continuing with installation"
        #         FAILED_INSTALLATIONS+=("Python $latest_python global setup (via pyenv)")
        #     else
        #         log_success "Python $latest_python installed and set as global version"
        #     fi
        # fi
    else
        log_warning "Could not determine latest Python version"
    fi
}
