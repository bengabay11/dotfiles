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

# Detect bash with nameref support (>= 4.3)
_supports_nameref() {
  [[ -n ${BASH_VERSINFO+x} ]] || return 1
  local major=${BASH_VERSINFO[0]} minor=${BASH_VERSINFO[1]}
  (( major > 4 )) || { (( major == 4 && minor >= 3 )) ; }
}

_install_tools_with_pm_impl() {
  local package_manager_name="$1"
  local package_manager_command="$2"
  local package_manager_install_command="$3"
  shift 3  # now "$@" = entries

  if ! command -v "$package_manager_command" >/dev/null 2>&1; then
    log_warning "$package_manager_name not available; skipping ${package_manager_command}-based installations"
    for entry in "$@"; do
      IFS=":" read -r display_name command version_command package_name <<< "$entry"
      FAILED_INSTALLATIONS+=("$display_name")
    done
    return 0
  fi

  for entry in "$@"; do
    IFS=":" read -r display_name command version_command package_name <<< "$entry"
    try_install_tool "$display_name" "$command" \
      "$package_manager_install_command $package_name" "$version_command"
  done
}

install_tools_with_package_manager() {
  local package_manager_name="$1"
  local package_manager_command="$2"
  local package_manager_install_command="$3"
  local arrname="$4"

  if _supports_nameref; then
    # Linux/new bash: use nameref to expand array items safely
    local -n _tools_ref="$arrname"
    _install_tools_with_pm_impl \
      "$package_manager_name" "$package_manager_command" "$package_manager_install_command" \
      "${_tools_ref[@]}"
  else
    # macOS/old bash: expand the array by name via eval
    eval "_install_tools_with_pm_impl \
      \"\$package_manager_name\" \"\$package_manager_command\" \"\$package_manager_install_command\" \
      \"\${$arrname[@]}\""
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
    # Stages has to be set before calling this function
    for stage_info in "${stages[@]}"; do
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
    if [[ -f "$DOTFILES_ROOT/dotfiles/functions.sh" ]]; then
        cp "$DOTFILES_ROOT/dotfiles/functions.sh" "$HOME/.config/shell-utils/functions.sh"
        log_success "Shell utilities installed to ~/.config/shell-utils/"
    else
        log_warning "functions.sh not found - skipping utilities setup"
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

# Dedicated function for trying install uv (Can't use try_install_tool because the install command has pipe inside)
try_install_uv () {
    if ! command -v uv >/dev/null 2>&1; then
        log_install uv
        curl -LsSf https://astral.sh/ruff/install.sh | sh

        if ! curl -LsSf https://astral.sh/uv/install.sh | sh; then
            log_error "Failed to install uv"
            FAILED_INSTALLATIONS+=("uv")
        else
            log_success "uv installed successfully"
        fi
    else
        log_found "uv is already installed ($(uv --version 2>/dev/null || echo version unknown))"
    fi
}

try_install_python () {
    local python_version=$1
    local tool_name="Python $python_version"
    if ! pyenv versions --bare | grep -Fx "$python_version" >/dev/null 2>&1; then
        log_install $tool_name
        if ! pyenv install $python_version --skip-existing; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
            return 1
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(PYENV_VERSION=$python_version python --version 2>/dev/null || echo "Python $python_version"))"
    fi
}

install_latest_python() {
    local latest_python
    latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    
    if [[ -n "$latest_python" ]]; then
        check_python_version_cmd='[[ "$(pyenv versions --bare)" == $latest_python_version ]]'
        if try_install_python $latest_python; then
            log_info "Setting global python version to $latest_python"
            if ! pyenv global "$latest_python"; then
                log_error "Failed to set global Python version - continuing with installation"
            else
                log_success "Python $latest_python set as the global version"
            fi
        fi
    else
        log_warning "Could not determine latest Python version"
    fi
}
