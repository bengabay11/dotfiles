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

# Function to check if an application is installed (currently supported in macos only)
# Usage: is_app_installed "AppName" [package_name]
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
        if [[ -n "$package_name" ]] && brew list --cask "$package_name" > /dev/null 2>&1; then
            return 0
        fi
    elif is_linux; then
        log_error "is_app_installed is not supported on Linux"
        return 1
    fi

    return 1
}

try_install_tool() {
    local tool_name="$1"
    local tool_command_name="$2"
    local tool_install_command="$3"
    local tool_version_command="$4"
    if ! command -v $tool_command_name > /dev/null 2>&1; then
        log_install $tool_name
        if ! eval "$tool_install_command"; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($($tool_version_command 2> /dev/null || echo version unknown))"
    fi
}

# Detect bash with nameref support (>= 4.3)
_supports_nameref() {
    [[ -n ${BASH_VERSINFO+x} ]] || return 1
    local major=${BASH_VERSINFO[0]} minor=${BASH_VERSINFO[1]}
    ((major > 4)) || { ((major == 4 && minor >= 3)); }
}

_install_tools_with_pm_impl() {
    local package_manager_name="$1"
    local package_manager_command="$2"
    local package_manager_install_command="$3"
    shift 3 # now "$@" = entries

    if ! command -v "$package_manager_command" > /dev/null 2>&1; then
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
    if command -v rustc > /dev/null 2>&1; then
        local version=$(rustc --version 2> /dev/null || echo "version unknown")
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

    if ! command -v stow > /dev/null 2>&1; then
        log_error "GNU Stow is not installed - skipping dotfiles setup"
        FAILED_INSTALLATIONS+=("dotfiles setup (stow not available)")
        return 1
    fi

    local dotfiles=(".vimrc" ".tmux.conf" ".zshrc" ".gitconfig")
    for dotfile in "${dotfiles[@]}"; do
        if [[ -f "$HOME/$dotfile" ]]; then
            log_warning "Backing up existing $dotfile to $dotfile.backup"
            mv "$HOME/$dotfile" "$HOME/$dotfile.backup"
        fi
    done

    log_info "Running stow to symlink dotfiles..."
    if (cd "$DOTFILES_ROOT/dotfiles" && bash setup.sh); then
        log_success "Dotfiles symlinked successfully via GNU Stow"
    else
        log_error "Failed to setup dotfiles with stow"
        FAILED_INSTALLATIONS+=("dotfiles setup")
        return 1
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
        "evalcache|https://github.com/mroth/evalcache.git|plugins"
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

try_install_starship_preset() {
    local preset="gruvbox-rainbow"
    local config="$HOME/.config/starship.toml"
    if [[ -f "$config" ]]; then
        log_found "starship config already exists ($config)"
    else
        log_install "starship $preset preset"
        if starship preset "$preset" -o "$config"; then
            log_success "starship $preset preset installed to $config"
        else
            log_error "Failed to install starship $preset preset"
            FAILED_INSTALLATIONS+=("starship-preset-$preset")
        fi
    fi
}

try_install_claude_code() {
    try_install_tool "Claude Code" "claude" \
        "curl -fsSL https://claude.ai/install.sh | bash" \
        "claude --version"
    # Ensure PATH is updated if the installer added the binary
    [[ -f "$HOME/.claude/bin/claude" ]] && export PATH="$HOME/.claude/bin:$PATH"
}

try_install_python() {
    local python_version=$1
    local tool_name="Python $python_version"
    if ! pyenv versions --bare | grep -Fx "$python_version" > /dev/null 2>&1; then
        log_install $tool_name
        if ! pyenv install $python_version --skip-existing; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
            return 1
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(PYENV_VERSION=$python_version python --version 2> /dev/null || echo "Python $python_version"))"
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
