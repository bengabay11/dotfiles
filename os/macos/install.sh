 #!/bin/bash

# macOS-specific installation script

set -uo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/dotfiles/shell-utils.sh"
source "$DOTFILES_ROOT/utils.sh"

# Global array to track failed installations
declare -a FAILED_INSTALLATIONS=()

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
        "openjdk"
        "watch"
        "bat"
        "eza"
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
            "openjdk")
                cmd_name="java"
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
                FAILED_INSTALLATIONS+=("$tool (CLI tool)")
            else
                log_success "$tool installed successfully"
                # Special handling for openjdk on macOS to make java available on PATH
                if [[ "$tool" == "openjdk" ]]; then
                    if command -v brew >/dev/null 2>&1; then
                        brew link --force --overwrite openjdk >/dev/null 2>&1 || true
                    fi
                fi
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
            FAILED_INSTALLATIONS+=("uv (Python package installer)")
        else
            log_success "uv installed successfully"
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
                FAILED_INSTALLATIONS+=("$display_name (application)")
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

main() {
    log_header "macOS Dotfiles Installation Script"
    log_info_interactive_mode_status
    
    echo ""
    log_step "Installation process includes the following stages:"
    echo -e "   ${BLUE}1.${NC} ${WHITE}🍺 Install/update Homebrew package manager${NC}"
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, etc.)${NC}"
    echo -e "   ${BLUE}3.${NC} ${WHITE}🦀 Install Rust programming language${NC}"
    echo -e "   ${BLUE}4.${NC} ${WHITE}💻 Install GUI applications (VS Code, Chrome, etc.)${NC}"
    echo -e "   ${BLUE}5.${NC} ${WHITE}🐚 Install and configure Oh My Zsh${NC}"
    echo -e "   ${BLUE}6.${NC} ${WHITE}🔌 Install Zsh plugins and themes${NC}"
    echo -e "   ${BLUE}7.${NC} ${WHITE}📝 Set up dotfiles and modular shell utilities${NC}"
    echo -e "   ${BLUE}8.${NC} ${WHITE}🐍 Configure Python environment with pyenv${NC}"
    echo ""
    
    local stages=(
        "install/update Homebrew package manager|install_homebrew|true|always"
        "install command-line development tools|install_cli_tools|false|always"
        "install Rust programming language|install_rust|false|always"
        "install GUI applications (IDEs, browsers, etc.)|install_applications|false|always"
        "install and configure Oh My Zsh shell framework|install_oh_my_zsh|false|always"
        "install Zsh plugins and themes (autosuggestions, syntax highlighting, powerlevel10k)|install_zsh_plugins|false|always"
        "set up dotfiles and modular shell utilities|setup_dotfiles|true|always"
        "configure Python environment with pyenv|install_latest_python|false|always"
    )
    process_stages

    show_failure_summary
    log_success "macOS dotfiles installation completed successfully!"
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
