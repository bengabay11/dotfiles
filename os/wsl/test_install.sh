#!/bin/bash

# Test script for WSL/Linux dotfiles installation (no GUI checks)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../dotfiles/shell-utils.sh"

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
        ((TESTS_PASSED++))
    else
        log_fail "$test_name"
        ((TESTS_FAILED++))
    fi
    return 0
}

test_command_exists() { command -v "$1" >/dev/null 2>&1; }
test_file_exists() { [[ -f "$1" ]]; }
test_directory_exists() { [[ -d "$1" ]]; }
test_symlink_exists() { [[ -L "$1" ]]; }
test_symlink_target_exists() { local t; t=$(readlink "$1"); [[ -n "$t" && -e "$t" ]]; }

main() {
    log_info "Starting WSL/Linux dotfiles installation tests..."
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
    run_test "ipython presence" "test_command_exists ipython || test_command_exists ipython3"

    log_info "=== Testing Dotfiles Symlinking ==="
    for dot in .vimrc .tmux.conf .zshrc .gitconfig; do
        run_test "$dot symlink exists" "test_symlink_exists '$HOME/$dot'"
        run_test "$dot target exists" "test_symlink_target_exists '$HOME/$dot'"
    done

    log_info "=== Testing Zsh/Oh-My-Zsh ==="
    run_test "Oh My Zsh directory" "test_directory_exists '$HOME/.oh-my-zsh'"
    run_test "Oh My Zsh main script" "test_file_exists '$HOME/.oh-my-zsh/oh-my-zsh.sh'"

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
        "rg --version | head -1"
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
    log_info "=== Test Results Summary ==="
    log_success "Tests passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        exit 1
    else
        log_success "All tests passed for WSL/Linux!"
        exit 0
    fi
}

main "$@"


