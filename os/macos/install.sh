#!/bin/bash

# macOS-specific installation script

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/dotfiles/functions.sh"
source "$DOTFILES_ROOT/utils.sh"

# Global array to track failed installations
declare -a FAILED_INSTALLATIONS=()

# Check if we're on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

install_homebrew() {
    if command -v brew > /dev/null 2>&1; then
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
        "Git:git:git --version:git"
        "Python 3.11:python3:python3 --version:python@3.11"
        "pyenv:pyenv:pyenv --version:pyenv"
        "Vim:vim:vim --version:vim"
        "tmux:tmux:tmux -V:tmux"
        "Yarn:yarn:yarn --version:yarn"
        "Node.js:node:node --version:node"
        "npm:npm:npm --version:npm"
        "TypeScript:tsc:tsc --version:typescript"
        "Java (OpenJDK):java:java --version:openjdk"
        "watch:watch:watch --version:watch"
        "bat:bat:bat --version:bat"
        "eza:eza:eza --version:eza"
        "Zsh:zsh:zsh --version:zsh"
        "ruff:ruff:ruff --version:ruff"
        "pre-commit:pre-commit:pre-commit --version:pre-commit"
        "Poetry:poetry:poetry --version:poetry"
        "btop:btop:btop --version:btop"
        "nmap:nmap:nmap --version:nmap"
        "htop:htop:htop --version:htop"
        "IPython:ipython:ipython --version:ipython"
        "ripgrep:rg:rg --version:ripgrep"
        "fd:fd:fd --version:fd"
        "Helm:helm:helm version --short:helm"
        "kubectl:kubectl:kubectl version --client:kubernetes-cli"
        "speedtest-cli:speedtest-cli:speedtest-cli --version:speedtest-cli"
        "fzf:fzf:fzf --version:fzf"
        "zoxide:zoxide:zoxide --version:zoxide"
        "delta:delta:delta --version:git-delta"
        "act:act:act --version:act"
        "GitHub CLI:gh:gh --version:gh"
    )
    install_tools_with_package_manager "Homebrew" "brew" "brew install" tools

    try_install_uv
}

install_applications() {
    log_info "Installing applications..."

    local apps=(
        "iTerm:iterm2"
        "Warp:warp"
        "Raycast:raycast"
        "Cursor:cursor"
        "Visual Studio Code:visual-studio-code"
        "Google Chrome:google-chrome"
        "Brave Browser:brave-browser"
        "Slack:slack"
        "Sublime Text:sublime-text"
        "Obsidian:obsidian"
        "Docker:docker"
        "Wireshark:wireshark-app"
        "Postman:postman"
        "Paintbrush:paintbrush"
        "Typora:typora"
        "DBeaver:dbeaver-community"
        "GitKraken:gitkraken"
    )

    local newly_installed_apps=()

    for app in "${apps[@]}"; do
        IFS=':' read -r display_name package_name <<< "$app"
        if is_app_installed "$display_name" "$package_name"; then
            log_found "$display_name is already installed"
        else
            log_install "$display_name"
            if ! brew install --cask "$package_name"; then
                log_error "Failed to install $display_name - continuing with remaining applications"
                FAILED_INSTALLATIONS+=("$display_name")
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
