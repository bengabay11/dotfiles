#!/bin/bash

# Linux-specific installation script (Ubuntu/Debian-based distros preferred)

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
                echo "This script installs dotfiles and development tools for Linux (apt-based)."
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
source "$DOTFILES_ROOT/dotfiles/shell-utils.sh"
source "$DOTFILES_ROOT/utils.sh"

# Global array to track failed installations
declare -a FAILED_INSTALLATIONS=()

# Ensure we're on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    log_error "This script is designed for Linux only"
    exit 1
fi

# Confirm apt is available (we target Debian/Ubuntu)
if ! command -v apt >/dev/null 2>&1; then
    log_error "This Linux installer currently supports apt-based distros (Debian/Ubuntu)."
    exit 1
fi

# Ensure common user bin paths are available in current session
export PATH="$HOME/.local/bin:$PATH"

apt_update_and_basics() {
    log_info "Refreshing apt package lists and installing base packages..."
    sudo apt-get update -y || true
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y || true
    # Common basics
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        build-essential curl wget ca-certificates gnupg lsb-release software-properties-common \
        git unzip xz-utils pkg-config
}

install_cli_tools() {
    log_info "Installing command-line tools..."

    # Core CLI via apt
    local apt_pkgs=(
        git
        python3 python3-pip python3-venv
        vim tmux
        nodejs npm
        bat
        eza
        zsh
        btop nmap htop
        ripgrep
        ipython3
        fzf
        speedtest-cli
        git-delta
        default-jdk
    )

    # Some packages might not exist on older distros; attempt install and continue on failure
    for pkg in "${apt_pkgs[@]}"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            # Determine the corresponding command name for version output
            cmd_name="$pkg"
            case "$pkg" in
                nodejs)
                    # Prefer node if available, otherwise fall back to nodejs
                    if command -v node >/dev/null 2>&1; then
                        cmd_name="node"
                    else
                        cmd_name="nodejs"
                    fi
                    ;;
                git-delta)
                    cmd_name="delta"
                    ;;
                ripgrep)
                    cmd_name="rg"
                    ;;
                bat)
                    if command -v bat >/dev/null 2>&1; then
                        cmd_name="bat"
                    elif command -v batcat >/dev/null 2>&1; then
                        cmd_name="batcat"
                    else
                        cmd_name="bat"
                    fi
                    ;;
                python3)
                    cmd_name="python3"
                    ;;
                ipython3)
                    # Prefer ipython if a shim/symlink exists; else use ipython3
                    if command -v ipython >/dev/null 2>&1; then
                        cmd_name="ipython"
                    else
                        cmd_name="ipython3"
                    fi
                    ;;
                default-jdk)
                    cmd_name="java"
                    ;;
                *)
                    cmd_name="$pkg"
                    ;;
            esac

            if command -v "$cmd_name" >/dev/null 2>&1; then
                # Use shared version helper for consistent formatting
                local version
                version=$(get_cli_tool_version "$cmd_name")
                log_found "$pkg is already installed ($version)"
            else
                # Command is not available (e.g., bat provides batcat); show apt package version instead
                local pkg_ver
                pkg_ver=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null || echo "version unknown")
                log_found "$pkg is already installed (apt package $pkg_ver)"
            fi
        else
            log_install "$pkg"
            if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"; then
                log_error "Failed to install $pkg - continuing"
                FAILED_INSTALLATIONS+=("$pkg (apt)")
            else
                log_success "$pkg installed successfully"
            fi
        fi
    done

    # Ensure 'bat' command exists (Ubuntu may provide 'batcat')
    if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
        log_info "Creating symlink for bat -> batcat"
        sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat || true
    fi

    # Ensure 'fd' command exists if package name is fd-find
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        log_info "Creating symlink for fd -> fdfind"
        sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd || true
    fi

    # exa fallback alias if only 'exa' exists and 'eza' not available
    if ! command -v eza >/dev/null 2>&1 && command -v exa >/dev/null 2>&1; then
        log_info "Creating convenience wrapper for eza -> exa"
        echo -e "#!/usr/bin/env bash\nexec exa \"$@\"" | sudo tee /usr/local/bin/eza >/dev/null
        sudo chmod +x /usr/local/bin/eza || true
    fi

    # Ensure 'ipython' command exists when only 'ipython3' is present
    if ! command -v ipython >/dev/null 2>&1 && command -v ipython3 >/dev/null 2>&1; then
        log_info "Creating symlink for ipython -> ipython3"
        sudo ln -sf "$(command -v ipython3)" /usr/local/bin/ipython || true
    fi

    # Node often ships as nodejs; ensure `node` command exists
    if ! command -v node >/dev/null 2>&1 && command -v nodejs >/dev/null 2>&1; then
        log_info "Creating symlink for node -> nodejs"
        sudo ln -sf "$(command -v nodejs)" /usr/local/bin/node || true
    fi

    # Typescript (tsc) and yarn via npm
    if ! command -v tsc >/dev/null 2>&1; then
        log_install "typescript"
        if ! sudo npm install -g typescript; then
            log_error "Failed to install typescript"
            FAILED_INSTALLATIONS+=("typescript (npm)")
        else
            log_success "typescript installed successfully"
        fi
    else
        log_found "typescript is already installed ($(tsc --version 2>/dev/null || echo version unknown))"
    fi

    if ! command -v yarn >/dev/null 2>&1; then
        log_install "yarn"
        if ! sudo npm install -g yarn; then
            log_error "Failed to install yarn"
            FAILED_INSTALLATIONS+=("yarn (npm)")
        else
            log_success "yarn installed successfully"
        fi
    else
        log_found "yarn is already installed ($(yarn --version 2>/dev/null || echo version unknown))"
    fi

    # ruff and pre-commit via apt or pipx fallback
    if ! command -v pipx >/dev/null 2>&1; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y pipx || true
    fi
    if ! command -v pipx >/dev/null 2>&1; then
        # Fallback: install pipx via pip
        python3 -m pip install --user pipx || true
        python3 -m pipx ensurepath || true
    fi

    if ! command -v ruff >/dev/null 2>&1; then
        if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ruff; then
            log_success "ruff installed successfully"
        else
            log_install "ruff"
            if ! pipx install ruff; then
                log_error "Failed to install ruff"
                FAILED_INSTALLATIONS+=("ruff")
            else
                log_success "ruff installed successfully"
            fi
        fi
    else
        log_found "ruff is already installed ($(ruff --version 2>/dev/null || echo version unknown))"
    fi

    if ! command -v pre-commit >/dev/null 2>&1; then
        if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y pre-commit; then
            log_success "pre-commit installed successfully"
        else
            log_install "pre-commit"
            if ! pipx install pre-commit; then
                log_error "Failed to install pre-commit"
                FAILED_INSTALLATIONS+=("pre-commit")
            else
                log_success "pre-commit installed successfully"
            fi
        fi
    else
        log_found "pre-commit is already installed ($(pre-commit --version 2>/dev/null || echo version unknown))"
    fi

    if command -v uv >/dev/null 2>&1; then
        local version
        version=$(uv --version 2>/dev/null || echo "version unknown")
        log_found "uv is already installed ($version)"
    else
        log_install "uv (Python package installer)"
        if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log_error "Failed to install uv"
            FAILED_INSTALLATIONS+=("uv (Python package installer)")
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
            log_error "Failed to install Rust - continuing"
            FAILED_INSTALLATIONS+=("Rust (programming language)")
        else
            source "$HOME/.cargo/env"
            log_success "Rust installed successfully"
        fi
    fi
}

install_helm() {
    if command -v helm >/dev/null 2>&1; then
        log_found "helm is already installed ($(helm version --short 2>/dev/null || echo version unknown))"
        return 0
    fi
    log_install "helm"
    if ! curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
        log_error "Failed to install helm"
        FAILED_INSTALLATIONS+=("helm")
        return 1
    fi
    log_success "helm installed successfully"
}

post_rust_fallbacks() {
    # Some tools may not be available in apt repos; install via cargo as fallback
    if command -v cargo >/dev/null 2>&1; then
        if ! command -v eza >/dev/null 2>&1; then
            log_install "eza"
            if ! cargo install eza; then
                log_error "Failed to install eza via cargo"
                FAILED_INSTALLATIONS+=("eza (cargo)")
            else
                log_success "eza installed successfully"
            fi
        fi
        if ! command -v delta >/dev/null 2>&1; then
            log_install "git-delta"
            if ! cargo install git-delta; then
                log_error "Failed to install git-delta via cargo"
                FAILED_INSTALLATIONS+=("git-delta (cargo)")
            else
                log_success "git-delta installed successfully"
            fi
        fi
    else
        log_warning "Cargo not available; skipping cargo-based fallbacks"
    fi
}

# No GUI apps on Linux; we explicitly skip that stage

install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_found "Oh My Zsh is already installed"
    else
        log_install "Oh My Zsh shell framework"
        if ! RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            log_error "Failed to install Oh My Zsh - continuing"
            FAILED_INSTALLATIONS+=("Oh My Zsh (shell framework)")
        else
            log_success "Oh My Zsh installed successfully"
        fi
    fi
}

install_zsh_plugins() {
    log_info "Installing Zsh plugins and themes..."
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log_error "Oh My Zsh must be installed before installing plugins"
        return 1
    fi
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    mkdir -p "$zsh_custom/plugins" "$zsh_custom/themes"
    local plugins=(
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|plugins"
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git|plugins"
        "powerlevel10k|https://github.com/romkatv/powerlevel10k.git|themes"
    )
    for plugin_info in "${plugins[@]}"; do
        IFS='|' read -r name repo_url install_type <<< "$plugin_info"
        local install_path="$zsh_custom/$install_type/$name"
        if [[ -d "$install_path" ]]; then
            log_found "$name is already installed"
        else
            log_install "$name"
            if [[ "$name" == "powerlevel10k" ]]; then
                if ! git clone --depth=1 "$repo_url" "$install_path"; then
                    log_error "Failed to install $name"
                    FAILED_INSTALLATIONS+=("$name (Zsh plugin/theme)")
                    continue
                fi
            else
                if ! git clone "$repo_url" "$install_path"; then
                    log_error "Failed to install $name"
                    FAILED_INSTALLATIONS+=("$name (Zsh plugin/theme)")
                    continue
                fi
            fi
            log_success "$name installed successfully"
        fi
    done
}

setup_dotfiles() {
    log_info "Setting up dotfiles..."
    mkdir -p "$HOME/.config" "$HOME/.config/shell-utils"

    local dotfiles=(".vimrc" ".tmux.conf" ".zshrc" ".gitconfig")
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$dotfile" || -L "$HOME/$dotfile" ]]; then
            log_warning "Backing up existing $dotfile to $dotfile.backup"
            mv -f "$HOME/$dotfile" "$HOME/$dotfile.backup" || true
        fi
    done
    ln -sf "$DOTFILES_ROOT/dotfiles/.vimrc" "$HOME/.vimrc"
    ln -sf "$DOTFILES_ROOT/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_ROOT/dotfiles/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_ROOT/dotfiles/.gitconfig" "$HOME/.gitconfig"

    if [[ -f "$DOTFILES_ROOT/dotfiles/shell-utils.sh" ]]; then
        cp "$DOTFILES_ROOT/dotfiles/shell-utils.sh" "$HOME/.config/shell-utils/shell-utils.sh"
        log_success "Shell utilities installed to ~/.config/shell-utils/"
    else
        log_warning "shell-utils.sh not found - skipping utilities setup"
    fi
}

configure_pyenv() {
    log_info "Configuring pyenv..."
    if ! command -v pyenv >/dev/null 2>&1; then
        log_install "pyenv (via git)"
        # Install dependencies
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y make build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev \
            libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev || true
        # Install pyenv
        git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv" || true
        # Initialize for current shell session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        if command -v pyenv >/dev/null 2>&1; then
            log_success "pyenv installed"
        else
            log_error "pyenv installation may have failed"
            FAILED_INSTALLATIONS+=("pyenv")
        fi
    else
        log_found "pyenv already installed"
    fi

    if command -v pyenv >/dev/null 2>&1; then
        local latest_python
        latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
        if [[ -n "$latest_python" ]]; then
            log_info "Installing Python $latest_python..."
            if ! pyenv install "$latest_python" --skip-existing; then
                log_error "Failed to install Python $latest_python via pyenv"
                FAILED_INSTALLATIONS+=("Python $latest_python (pyenv)")
            else
                if ! pyenv global "$latest_python"; then
                    log_error "Failed to set global Python version - continuing with installation"
                    FAILED_INSTALLATIONS+=("Python $latest_python global setup (via pyenv)")
                else
                    log_success "Python $latest_python installed and set as global version"
                fi
            fi
        fi
    fi
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

main() {
    # Beautiful welcome header (match macOS style)
    log_header "🚀 Linux Dotfiles Installation Script"

    # Mode info (interactive vs automated)
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
    echo -e "   ${BLUE}1.${NC} ${WHITE}🔄 Update apt and base packages${NC}"
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, etc.)${NC}"
    echo -e "   ${BLUE}3.${NC} ${WHITE}🦀 Install Rust programming language${NC}"
    echo -e "   ${BLUE}4.${NC} ${WHITE}🧰 Fallback install for tools via cargo (eza, git-delta)${NC}"
    echo -e "   ${BLUE}5.${NC} ${WHITE}⎈ Install helm CLI${NC}"
    echo -e "   ${BLUE}6.${NC} ${WHITE}🐚 Install and configure Oh My Zsh${NC}"
    echo -e "   ${BLUE}7.${NC} ${WHITE}🔌 Install Zsh plugins and themes${NC}"
    echo -e "   ${BLUE}8.${NC} ${WHITE}📝 Set up dotfiles and modular shell utilities${NC}"
    echo -e "   ${BLUE}9.${NC} ${WHITE}🐍 Configure Python environment with pyenv${NC}"
    echo ""

    local stages=(
        "update apt and base packages|apt_update_and_basics|true|always"
        "install command-line development tools|install_cli_tools|false|always"
        "install Rust programming language|install_rust|false|always"
        "fallback install for tools via cargo (eza, git-delta)|post_rust_fallbacks|false|always"
        "install helm CLI|install_helm|false|always"
        "install and configure Oh My Zsh shell framework|install_oh_my_zsh|false|always"
        "install Zsh plugins and themes (autosuggestions, syntax highlighting, powerlevel10k)|install_zsh_plugins|false|always"
        "set up dotfiles and modular shell utilities|setup_dotfiles|true|always"
        "configure Python environment with pyenv|configure_pyenv|false|always"
    )

    for stage_info in "${stages[@]}"; do
        IFS='|' read -r description function_name default_yes condition <<< "$stage_info"
        if confirm_stage "$description" "$default_yes"; then
            if ! "$function_name"; then
                log_error "Stage '$description' failed - continuing"
            fi
        fi
    done

    show_failure_summary
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}🎉 Installation Complete!${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
    log_success "Linux dotfiles installation completed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi


