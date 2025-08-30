#!/bin/bash

# Linux-specific installation script (Ubuntu/Debian-based distros preferred)

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/dotfiles/functions.sh"
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
        git unzip xz-utils pkg-config net-tools
}

install_cli_tools_with_apt() {
    local tools=(
        "Git:git:git --version:git"
        "Python 3:python3:python3 --version:python3"
        "pip3:pip3:pip3 --version:pip"
        "vim:vim:echo unknown version:vim" # vim version output is too long. can be solved with head command, but the script will need some changes.
        "tmux:tmux:tmux -V:tmux"
        "Node.js:node:node --version:nodejs"
        "npm:npm:npm --version:npm"
        "bat:bat:bat --version:bat"
        "Zsh:zsh:zsh --version:zsh"
        "btop:btop:btop --version:btop"
        "htop:htop:htop --version:htop"
        "nmap:nmap:nmap --version:nmap"
        "ripgrep:rg:rg --version:ripgrep"
        "fd (fd-find):fdfind:fdfind --version:fd-find"
        "IPython3:ipython3:ipython3 --version:ipython3"
        "zoxide:zoxide:zoxide --version:zoxide"
        "fzf:fzf:fzf --version:fzf"
        "Speedtest CLI:speedtest-cli:speedtest-cli --version:speedtest-cli"
        "Java JDK:javac:javac -version:default-jdk"
        "TShark:tshark:tshark --version:tshark"
        "GitHub CLI:gh:gh --version:gh"
    )
    install_tools_with_package_manager "apt" "apt" \
    "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y" tools

}

install_cli_tools_with_cargo() {
    local tools=(
        "eza:eza:eza --version:eza"
        "git-delta:delta:delta --version:git-delta"
    )
    install_tools_with_package_manager "cargo" "cargo" "cargo install" tools
}

install_tools_with_npm() {
    local tools=(
        "Typescript:tsc:tsc --version:typescript"
        "yarn:yarn:yarn --version:yarn"
    )
    install_tools_with_package_manager "npm" "npm" "npm install -g" tools
}

try_install_ruff () {
    local tool_name="ruff"
    if ! command -v ruff >/dev/null 2>&1; then
        log_install $tool_name
        if ! curl -LsSf https://astral.sh/ruff/install.sh | sh; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(ruff --version 2>/dev/null || echo version unknown))"
    fi
}

# Dedicated function for trying install helm (Can't use try_install_tool because the install command has pipe inside)
try_install_helm () {
    local tool_name="helm"
    if ! command -v helm >/dev/null 2>&1; then
        log_install $tool_name
        if ! curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(helm version --short 2>/dev/null || echo version unknown))"
    fi
}

try_install_act () {
    local tool_name="act"
    if ! command -v act >/dev/null 2>&1; then
        log_install $tool_name
        if ! curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(act --version 2>/dev/null || echo version unknown))"
    fi
}

try_install_pre_commit() {
    local tool_name="pre-commit"
    if ! command -v pre-commit >/dev/null 2>&1; then
        log_install $tool_name
        if ! pip install pre-commit; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(pre-commit --version 2>/dev/null || echo version unknown))"
    fi
}

try_install_poetry() {
    local tool_name="poetry"
    if ! command -v poetry >/dev/null 2>&1; then
        log_install $tool_name
        if ! curl -sSL https://install.python-poetry.org | python3 -; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(poetry --version 2>/dev/null || echo version unknown))"
    fi
}

install_cli_tools() {
    log_info "Installing command-line tools..."

    install_cli_tools_with_apt
    install_cli_tools_with_cargo
    install_tools_with_npm

    try_install_uv
    try_install_ruff
    try_install_helm
    try_install_act
    try_install_pre_commit
    try_install_poetry
}

install_pyenv() {
     if ! command -v pyenv >/dev/null 2>&1; then
        log_install "pyenv"
        curl -fsSL https://pyenv.run | bash

        # Initialize for current shell session
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"

        if command -v pyenv >/dev/null 2>&1; then
            log_success "pyenv"
        else
            log_error "pyenv installation may have failed"
            FAILED_INSTALLATIONS+=("pyenv")
        fi
    else
        log_found "pyenv already installed ($(pyenv --version 2>/dev/null || echo version unknown))"
    fi
}

configure_python_env() {
    install_pyenv
    log_install "linux libraries for Python"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y make build-essential libssl-dev zlib1g-dev \
            libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev \
            libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev || true
    install_latest_python
}


main() {
    log_header "🚀 Linux Dotfiles Installation Script"
    log_info_interactive_mode_status
    echo ""
    log_step "Installation process includes the following stages:"
    echo -e "   ${BLUE}1.${NC} ${WHITE}🔄 Update apt and base packages${NC}"
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, etc.)${NC}"
    echo -e "   ${BLUE}3.${NC} ${WHITE}🦀 Install Rust programming language${NC}"
    echo -e "   ${BLUE}4.${NC} ${WHITE}🧰 Install tools via cargo (eza, git-delta)${NC}"
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
        "install and configure Oh My Zsh shell framework|install_oh_my_zsh|false|always"
        "install Zsh plugins and themes (autosuggestions, syntax highlighting, powerlevel10k)|install_zsh_plugins|false|always"
        "set up dotfiles and modular shell utilities|setup_dotfiles|true|always"
        "configure Python environment with pyenv|configure_python_env|false|always"
    )
    process_stages

    show_failure_summary
    log_success "linux dotfiles installation completed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
