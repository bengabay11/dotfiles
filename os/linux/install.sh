#!/bin/bash

# Linux-specific installation script (Ubuntu/Debian-based distros preferred)

set -uo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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
        zsh
        btop nmap htop
        ripgrep
        ipython3
        fzf
        speedtest-cli
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

install_pyenv() {
     if ! command -v pyenv >/dev/null 2>&1; then
        log_install "pyenv"
        curl -fsSL https://pyenv.run | bash
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
        log_found "pyenv already installed ($(tsc --version 2>/dev/null || echo version unknown))"
    fi
}

configure_python_env() {
    log_info "Installing pyenv"
    install_pyenv
    log_info "Installing Latest python version via pyenv"
    install_latest_python
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


main() {
    log_header "🚀 Linux Dotfiles Installation Script"
    log_info_interactive_mode_status
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
        "configure Python environment with pyenv|configure_python_env|false|always"
    )
    process_stages "${stages[@]}"

    show_failure_summary
    log_success "linux dotfiles installation completed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
