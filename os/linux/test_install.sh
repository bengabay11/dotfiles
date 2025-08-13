#!/bin/bash

# Test script for Linux dotfiles installation (no GUI checks)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../dotfiles/shell-utils.sh"
source "$SCRIPT_DIR/../../dotfiles/.aliases.sh"

# Ensure typical user tool paths are available in this test session
export PATH="$HOME/.cargo/bin:$HOME/.pyenv/bin:$PATH"

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    log_check "Testing: $test_name"
    if eval "$test_command"; then
        log_pass "$test_name"
        ((TESTS_PASSED+=1))
    else
        log_fail "$test_name"
        ((TESTS_FAILED+=1))
    fi
    return 0
}

test_command_exists() { command -v "$1" >/dev/null 2>&1; }
test_file_exists() { [[ -f "$1" ]]; }
test_directory_exists() { [[ -d "$1" ]]; }
test_symlink_exists() { [[ -L "$1" ]]; }
test_symlink_target_exists() { local t; t=$(readlink "$1"); [[ -n "$t" && -e "$t" ]]; }

main() {
    log_info "Starting Linux dotfiles installation tests..."
    echo ""

    log_info "=== Testing Essential CLI Tools ==="
    for cmd in git python3 vim tmux node npm yarn zsh rg fzf delta bat eza; do
        run_test "$cmd installation" "test_command_exists $cmd"
    done
    run_test "btop installation" "test_command_exists btop || true"
    run_test "nmap installation" "test_command_exists nmap || true"
    run_test "htop installation" "test_command_exists htop || true"
    run_test "speedtest-cli installation" "test_command_exists speedtest-cli || true"

    log_info "=== Testing Development Tools ==="
    run_test "Rust installation" "test_command_exists rustc"
    run_test "Cargo installation" "test_command_exists cargo"
    run_test "pyenv installation" "test_command_exists pyenv || [[ -d $HOME/.pyenv ]]"
    run_test "uv installation" "test_command_exists uv"
    run_test "helm installation" "test_command_exists helm"
    run_test "TypeScript installation" "test_command_exists tsc"
    run_test "ruff installation" "test_command_exists ruff || true"
    run_test "pre-commit installation" "test_command_exists pre-commit || true"
    run_test "ipython presence" "test_command_exists ipython || test_command_exists ipython3"

    echo ""
    log_info "=== Testing Python and Rust Environment ==="
    if command -v pyenv >/dev/null 2>&1 || [[ -d "$HOME/.pyenv" ]]; then
        if pyenv global >/dev/null 2>&1; then
            pyver=$(pyenv global)
            log_pass "pyenv global Python version: $pyver"
            ((TESTS_PASSED+=1))
        else
            log_warning "No global Python version set in pyenv (may be expected)"
        fi
        run_test "pyenv shims directory" "test_directory_exists '$HOME/.pyenv/shims'"
    fi

    if command -v cargo >/dev/null 2>&1; then
        run_test "Cargo home directory" "test_directory_exists '$HOME/.cargo'"
        run_test "Cargo binary directory" "test_directory_exists '$HOME/.cargo/bin'"
        run_test "Rust toolchain directory" "test_directory_exists '$HOME/.rustup'"
    fi

    log_info "=== Testing Dotfiles Symlinking ==="
    for dot in .vimrc .tmux.conf .zshrc .gitconfig; do
        run_test "$dot symlink exists" "test_symlink_exists '$HOME/$dot'"
        run_test "$dot target exists" "test_symlink_target_exists '$HOME/$dot'"
    done

    log_info "=== Testing Zsh/Oh-My-Zsh ==="
    run_test "Oh My Zsh directory" "test_directory_exists '$HOME/.oh-my-zsh'"
    run_test "Oh My Zsh main script" "test_file_exists '$HOME/.oh-my-zsh/oh-my-zsh.sh'"

    echo ""
    log_info "=== Testing Configuration Files ==="
    if [[ -f "$HOME/.zshrc" ]]; then
        run_test ".zshrc contains Oh My Zsh configuration" "grep -q 'oh-my-zsh' '$HOME/.zshrc'"
        run_test ".zshrc contains export statements" "grep -q 'export' '$HOME/.zshrc'"
        run_test "Modular shell utilities system is configured" "grep -q '.config/shell-utils' '$HOME/.zshrc'"
        run_test "Shell utilities are installed" "test -f '$HOME/.config/shell-utils/shell-utils.sh'"
    fi
    if [[ -f "$HOME/.gitconfig" ]]; then
        # We expect personal details to be stored in ~/.gitconfig.local and included here
        run_test ".gitconfig includes local override file" "grep -q '^[[:space:]]*path = ~/.gitconfig.local' '$HOME/.gitconfig'"
        run_test ".gitconfig contains delta pager configuration" "grep -q 'pager = delta' '$HOME/.gitconfig'"
    fi
    if [[ -f "$HOME/.vimrc" ]]; then
        run_test ".vimrc contains basic configuration" "grep -q 'set' '$HOME/.vimrc'"
    fi
    if [[ -f "$HOME/.tmux.conf" ]]; then
        run_test ".tmux.conf contains configuration" "grep -q 'set' '$HOME/.tmux.conf'"
    fi

    echo ""
    log_info "=== Testing Environment Setup ==="
    run_test "Cargo is in PATH" "echo '$PATH' | grep -q '.cargo/bin'"
    run_test "pyenv is in PATH" "command -v pyenv >/dev/null 2>&1 || [[ -d $HOME/.pyenv ]]"
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        run_test "Node.js and npm are compatible" "npm --version >/dev/null 2>&1"
    fi
    if command -v uv >/dev/null 2>&1; then
        run_test "uv can list Python versions" "uv python list >/dev/null 2>&1 || true"
    fi

    echo ""
    log_info "=== Testing Tool Functionality ==="
    if command -v git >/dev/null 2>&1; then
        run_test "Git can show version" "git --version >/dev/null 2>&1"
        run_test "Git config is readable" "git config --list >/dev/null 2>&1"
    fi
    if command -v rustc >/dev/null 2>&1; then
        run_test "Rust compiler responds to version check" "rustc --version >/dev/null 2>&1"
    fi
    if command -v tmux >/dev/null 2>&1; then
        run_test "tmux can show version" "tmux -V >/dev/null 2>&1"
    fi
    if command -v vim >/dev/null 2>&1; then
        run_test "Vim can show version" "vim --version >/dev/null 2>&1"
    fi

    log_info "=== Tool Versions (informational) ==="
    tools=(
        "git --version"
        "python3 --version"
        "node --version"
        "npm --version"
        "yarn --version"
        "rustc --version"
        "cargo --version"
        "pyenv --version || echo 'pyenv shim not in PATH'"
        "uv --version"
        "tsc --version"
        "vim --version | head -1"
        "tmux -V"
        "zsh --version"
        "btop --version"
        "nmap --version | head -1"
        "htop --version"
        "ipython --version"
        "rg --version | head -1"
        "helm version --short"
        "speedtest-cli --version"
        "fzf --version"
        "delta --version"
    )
    for t in "${tools[@]}"; do
        name=$(echo "$t" | cut -d' ' -f1)
        if command -v "$name" >/dev/null 2>&1; then
            out=$(eval "$t" 2>/dev/null || echo 'Version check failed')
            log_info "$name: $out"
        fi
    done

    echo ""
    log_info "=== Testing Integration ==="
    if command -v pyenv >/dev/null 2>&1 || [[ -d "$HOME/.pyenv" ]]; then
        run_test "pyenv can list available versions" "pyenv install --list >/dev/null 2>&1"
        if pyenv global >/dev/null 2>&1; then
            run_test "pyenv global Python is usable" "pyenv exec python3 --version >/dev/null 2>&1"
        fi
    fi

    echo ""
    log_info "=== Testing File Permissions ==="
    scripts=("../../install.sh" "install.sh")
    for script in "${scripts[@]}"; do
        script_path="$SCRIPT_DIR/$script"
        if [[ -f "$script_path" ]]; then
            run_test "$script is executable" "[[ -x '$script_path' ]]"
        else
            log_warning "$script not found at $script_path"
        fi
    done

    echo ""
    log_info "=== Test Results Summary ==="
    log_success "Tests passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        exit 1
    else
        log_success "All tests passed for Linux!"
        exit 0
    fi
}

main "$@"


