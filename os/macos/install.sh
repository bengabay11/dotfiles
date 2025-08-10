 #!/bin/bash

# macOS-specific installation script

set -uo pipefail

# Parse command line arguments (inherit from parent script or parse directly)
if [[ -z "${AUTO_YES:-}" ]]; then
    AUTO_YES=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_YES=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -y, --yes    Auto-confirm all prompts (non-interactive mode)"
                echo "  -h, --help   Show this help message"
                echo ""
                echo "This script installs dotfiles and development tools for macOS."
                exit 0
                ;;
            *)
                # Silently ignore unknown options to allow flexibility
                shift
                ;;
        esac
    done
fi

# Export AUTO_YES for any child scripts
export AUTO_YES

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared utilities
source "$DOTFILES_ROOT/dotfiles/.shell-utils"
source "$DOTFILES_ROOT/utils.sh"



# Check if we're on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        local version=$(brew --version | head -1)
        log_found "Homebrew is already installed ($version)"
        # Skip update in CI or when explicitly disabled
        if [[ -z "${CI:-}" ]] && [[ -z "${HOMEBREW_NO_AUTO_UPDATE:-}" ]] && [[ -z "${AUTO_YES:-}" ]]; then
            log_info "Updating Homebrew..."
            if ! brew update; then
                log_warning "Failed to update Homebrew - continuing with installation"
            fi
        else
            log_info "Skipping brew update (CI/auto-update disabled)"
        fi
    else
        log_install "Homebrew package manager"
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            log_error "Failed to install Homebrew - this will affect other installations"
            return 1
        fi
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        log_success "Homebrew installed successfully"
    fi
}

install_cli_tools() {
    log_info "Installing command-line tools..."
    
    local tools=(
        "git"
        "python@3.11"
        "pyenv"
        "vim"
        "tmux"
        "yarn"
        "node"
        "npm"
        "typescript"
        "bat"
        "exa"
        "zsh"
        "ruff"
        "pre-commit"
        "btop"
        "nmap"
        "htop"
        "ipython"
        "ripgrep"
        "helm"
        "speedtest-cli"
        "fzf"
        "git-delta"
    )
    
    # Check and install each tool using utility functions
    for tool in "${tools[@]}"; do
        local cmd_name="$tool"
        
        # Handle special cases where command name differs from brew package name
        case "$tool" in
            "python@3.11")
                cmd_name="python3"
                ;;
            "typescript")
                cmd_name="tsc"
                ;;
            "git-delta")
                cmd_name="delta"
                ;;
        esac
        
        if is_cli_tool_installed "$tool" "$cmd_name"; then
            local source
            source=$(get_cli_tool_source "$tool" "$cmd_name")
            local version
            version=$(get_cli_tool_version "$cmd_name")
            
            case "$source" in
                "system")
                    log_found "$tool is already available on system ($version)"
                    ;;
                "homebrew")
                    log_found "$tool is already installed via Homebrew ($version)"
                    ;;
            esac
        else
            log_install "$tool"
            if ! brew install "$tool"; then
                log_error "Failed to install $tool - continuing with remaining tools"
            else
                log_success "$tool installed successfully"
            fi
        fi
    done
    
    # Install uv (Python package installer) - special case with custom installer
    if command -v uv >/dev/null 2>&1; then
        local version
        version=$(uv --version 2>/dev/null || echo "version unknown")
        log_found "uv is already installed ($version)"
    else
        log_install "uv (Python package installer)"
        if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log_error "Failed to install uv - continuing with installation"
        else
            log_success "uv installed successfully"
        fi
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
        else
            source "$HOME/.cargo/env"
            log_success "Rust installed successfully"
        fi
    fi
}

# Install applications via Homebrew Cask
install_applications() {
    log_info "Installing applications..."
    
    # Important security notice
    echo ""
    log_warning "📋 Important: macOS Security Notice"
    log_info "After installation, when you first open these applications, macOS may show"
    log_info "security warnings because they weren't downloaded from the App Store."
    log_info ""
    log_info "To resolve security warnings:"
    log_info "1. Right-click the app in Applications folder → 'Open'"
    log_info "2. Or go to System Settings → Privacy & Security → 'Allow Anyway'"
    log_info "3. This only needs to be done once per application"
    echo ""
    
    local apps=(
        "iterm2"
        "warp"
        "raycast"
        "cursor"
        "visual-studio-code"
        "google-chrome"
        "brave-browser"
        "slack"
        "sublime-text"
        "obsidian"
        "docker"
        "wireshark-app"
        "postman"
        "typora"
        "dbeaver-community"
    )
    
    local newly_installed_apps=()
    
    for app in "${apps[@]}"; do
        local display_name
        display_name=$(get_app_display_name "$app")
        
        if is_app_installed "$display_name" "$app"; then
            log_found "$display_name is already installed"
        else
            log_install "$display_name"
            if ! brew install --cask "$app"; then
                log_error "Failed to install $display_name - continuing with remaining applications"
            else
                log_success "$display_name installed successfully"
                newly_installed_apps+=("$display_name")
            fi
        fi
    done
    
    # Provide specific guidance for newly installed apps
    if [[ ${#newly_installed_apps[@]} -gt 0 ]]; then
        echo ""
        log_info "🔐 Security Setup Required"
        log_warning "The following newly installed applications will need security approval:"
        for app_name in "${newly_installed_apps[@]}"; do
            log_info "  • $app_name"
        done
        echo ""
        log_info "You have two options to handle app security:"
        log_info ""
        log_info "Option 1 - Manual approach (more secure):"
        log_info "1. Click 'Cancel' or 'Don't Open' in the initial dialog"
        log_info "2. Go to Applications folder in Finder"
        log_info "3. Right-click the app → select 'Open'"
        log_info "4. Click 'Open' in the confirmation dialog"
        log_info "5. The app will then work normally for all future launches"
        echo ""
        log_info "Option 2 - Automated approach (convenience):"
        log_info "Run the trust_apps.sh script to automatically trust all apps"
        echo ""
        
        # Offer to run trust script for newly installed apps
        if [[ -z "${CI:-}" ]] && [[ -z "${NONINTERACTIVE:-}" ]]; then
            if confirm_stage "automatically trust newly installed applications using xattr" "false"; then
                if [[ -f "$SCRIPT_DIR/trust_apps.sh" ]]; then
                    log_info "Running application trust script for newly installed apps..."
                    # Convert display names to app names for the trust script
                    local app_args=()
                    for app_name in "${newly_installed_apps[@]}"; do
                        app_args+=("$app_name")
                    done
                    bash "$SCRIPT_DIR/trust_apps.sh" -y "${app_args[@]}"
                else
                    log_warning "trust_apps.sh script not found in $SCRIPT_DIR"
                fi
            elif confirm_stage "open Applications folder in Finder for manual app setup" "false"; then
                open /Applications
                log_info "Applications folder opened in Finder"
            fi
        fi
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_found "Oh My Zsh is already installed"
    else
        log_install "Oh My Zsh shell framework"
        if ! RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_error "Failed to install Oh My Zsh - continuing with installation"
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
                    continue
                fi
            else
                if ! git clone "$repo_url" "$install_path"; then
                    log_error "Failed to install $name - continuing with remaining plugins"
                    continue
                fi
            fi
            
            log_success "$name installed successfully"
        fi
    done
    
    log_success "All Zsh plugins and themes installed successfully"
}

setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    # Create dotfiles directory if it doesn't exist
    mkdir -p "$HOME/.config"
    
    # Backup existing dotfiles
    local dotfiles=(".vimrc" ".tmux.conf" ".zshrc" ".gitconfig")
    
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$dotfile" ]]; then
            log_warning "Backing up existing $dotfile to $dotfile.backup"
            mv "$HOME/$dotfile" "$HOME/$dotfile.backup"
        fi
    done
    
    # Symlink new dotfiles
    log_info "Creating symlinks for dotfiles..."
    ln -sf "$DOTFILES_ROOT/dotfiles/.vimrc" "$HOME/.vimrc"
    ln -sf "$DOTFILES_ROOT/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_ROOT/dotfiles/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_ROOT/dotfiles/.gitconfig" "$HOME/.gitconfig"
}

configure_pyenv() {
    log_info "Configuring pyenv..."
    
    # Install latest Python version
    local latest_python
    latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    
    if [[ -n "$latest_python" ]]; then
        log_info "Installing Python $latest_python..."
        if ! pyenv install "$latest_python" --skip-existing; then
            log_error "Failed to install Python $latest_python - continuing with installation"
        else
            if ! pyenv global "$latest_python"; then
                log_error "Failed to set global Python version - continuing with installation"
            else
                log_success "Python $latest_python installed and set as global version"
            fi
        fi
    else
        log_warning "Could not determine latest Python version"
    fi
}

main() {
    # Beautiful welcome header
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}🚀 macOS Dotfiles Installation Script${NC}         ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
    
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
    
    echo ""
    log_step "Installation process includes the following stages:"
    echo -e "   ${BLUE}1.${NC} ${WHITE}🍺 Install/update Homebrew package manager${NC}"
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, etc.)${NC}"
    echo -e "   ${BLUE}3.${NC} ${WHITE}🦀 Install Rust programming language${NC}"
    echo -e "   ${BLUE}4.${NC} ${WHITE}💻 Install GUI applications (VS Code, Chrome, etc.)${NC}"
    echo -e "   ${BLUE}5.${NC} ${WHITE}🐚 Install and configure Oh My Zsh${NC}"
    echo -e "   ${BLUE}6.${NC} ${WHITE}🔌 Install Zsh plugins and themes${NC}"
    echo -e "   ${BLUE}7.${NC} ${WHITE}📝 Set up dotfiles (.shell-utils, .gitconfig, .zshrc, .tmux.conf, .vimrc)${NC}"
    echo -e "   ${BLUE}8.${NC} ${WHITE}🐍 Configure Python environment with pyenv${NC}"
    echo ""
    
    # Define installation stages
    local stages=(
        "install/update Homebrew package manager|install_homebrew|true|always"
        "install command-line development tools|install_cli_tools|false|always"
        "install Rust programming language|install_rust|false|always"
        "install GUI applications (IDEs, browsers, etc.)|install_applications|false|no_ci"
        "install and configure Oh My Zsh shell framework|install_oh_my_zsh|false|always"
        "install Zsh plugins and themes (autosuggestions, syntax highlighting, powerlevel10k)|install_zsh_plugins|false|always"
        "set up dotfiles (.vimrc, .tmux.conf, .gitconfig, etc.)|setup_dotfiles|true|always"
        "configure Python environment with pyenv|configure_pyenv|false|always"
    )
    
    # Process each stage
    for stage_info in "${stages[@]}"; do
        # Parse stage information (description|function|default_yes|condition)
        IFS='|' read -r description function_name default_yes condition <<< "$stage_info"
        
        # Check if stage should be skipped based on condition
        if [[ "$condition" == "no_ci" && -n "${CI:-}" ]]; then
            log_info "Skipping GUI applications in CI environment"
            continue
        fi
        
        # Run stage if confirmed
        if confirm_stage "$description" "$default_yes"; then
            if ! "$function_name"; then
                log_error "Stage '$description' failed - continuing with remaining stages"
            fi
        fi
    done
    
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}🎉 Installation Complete!${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
    log_success "macOS dotfiles installation completed successfully!"
    echo ""
    log_info "Next steps:"
    log_info "1. Restart your terminal or run 'source ~/.zshrc' to apply changes"
    log_info "2. Sign in to VS Code to sync settings and extensions"
    log_info "3. Sign in to Cursor to sync settings and extensions" 
    log_info "4. Sync Obsidian notes with your vault"
    echo ""
    log_info "Optional system configuration:"
    log_info "You may want to configure these macOS system preferences:"
    log_info "• Dock preferences (size, position, auto-hide)"
    log_info "• Trackpad settings (tap to click, tracking speed)"
    log_info "• Keyboard settings (key repeat rate, modifier keys)"
    log_info "• Finder preferences (show hidden files, default view)"
    log_info "• Security & Privacy settings"
    log_info "• Energy Saver preferences"
    echo ""
    log_info "These can be configured manually in System Preferences or"
    log_info "you can create your own system configuration script as needed."
}

# Only run main if this script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
