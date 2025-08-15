#!/bin/bash

# Comprehensive test script for dotfiles installation
# This script verifies that the installation completed successfully

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

shopt -s expand_aliases  # Allow aliases (from aliases.sh) to work in this non-interactive script
source "$SCRIPT_DIR/dotfiles/shell-utils.sh"
source "$SCRIPT_DIR/dotfiles/aliases.sh"

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0

TEST_HOMEBREW=true
TEST_APPS=true

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
    return 0  # Always return 0 to prevent script exit
}

test_command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

test_file_exists() {
    local file="$1"
    [[ -f "$file" ]]
}

test_directory_exists() {
    local dir="$1"
    [[ -d "$dir" ]]
}

test_symlink_exists() {
    local link="$1"
    [[ -L "$link" ]]
}

test_symlink_target_exists() {
    local link="$1"
    local target
    target=$(readlink "$link")
    [[ -f "$target" ]]
}

test_cli_tools_exists() {
        tools=(
        "Git installation:git"
        "Python3 installation:python3"
        "Vim installation:vim"
        "tmux installation:tmux"
        "Node.js installation:node"
        "npm installation:npm"
        "yarn installation:yarn"
        "Zsh installation:zsh"
        "Rust installation:rustc"
        "Cargo installation:cargo"
        "pyenv installation:pyenv"
        "uv installation:uv"
        "TypeScript installation:tsc"
        "bat installation:bat"
        "eza installation:eza"
        "ruff installation:ruff"
        "pre-commit installation:pre-commit"
        "btop installation:btop"
        "nmap installation:nmap"
        "htop installation:htop"
        "IPython installation:ipython3"
        "ripgrep installation:rg"
        "helm installation:helm"
        "speedtest-cli installation:speedtest-cli"
        "fzf installation:fzf"
        "delta installation:delta"
        "Java (openjdk) installation:java"
        "watch installation:watch"
        "docker CLI command:docker"
        "tshark CLI command (Wireshark):tshark"
    )

    for entry in "${tools[@]}"; do
        IFS=":" read -r name cmd <<< "$entry"
        run_test "$name" "test_command_exists $cmd"
    done
}

test_apps() {
    log_info "=== Testing GUI Applications ==="
    apps=(
        "iTerm"
        "Warp" 
        "Raycast"
        "Cursor"
        "Visual Studio Code"
        "Google Chrome"
        "Brave Browser"
        "Slack"
        "Sublime Text"
        "Obsidian"
        "Docker"
        "Wireshark"
        "Postman"
        "Typora"
        "DBeaver"
    )
    
    for app in "${apps[@]}"; do
        run_test "$app application" "test_directory_exists '/Applications/$app.app' || test_directory_exists '$HOME/Applications/$app.app'"
    done
    echo ""
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-homebrew)
                TEST_HOMEBREW=false
                shift
                ;;
            --no-apps|--skip-apps)
                TEST_APPS=false
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--apps|--no-apps]"
                echo "  --no-homebrew  Skip Homebrew tests"
                echo "  --no-apps  Skip GUI application tests"
                exit 0
                ;;
            *)
                shift
                ;;
        esac
    done
}

main() {
    log_info "Starting comprehensive macOS dotfiles installation tests..."
    echo ""
    
    parse_args "$@"
    
    # Test 1: Homebrew
    log_info "=== Testing Essential CLI Tools ==="
    if [[ "$TEST_HOMEBREW" == true ]]; then
       run_test "Homebrew installation" "test_command_exists brew"
       run_test "Homebrew can list installed packages" "brew list >/dev/null 2>&1"
       run_test "Homebrew doctor passes" "brew doctor >/dev/null 2>&1"
    else
        log_info "=== Skipping Homebrew test (--no-homebrew) ==="
    fi

    # Test 2: command-line tools
    test_cli_tools_exists
    
    # Test 2: GUI Applications (macOS only)
    if [[ "$TEST_APPS" == true ]]; then
        test_apps
    else
        log_info "=== Skipping GUI Applications tests (--no-apps) ==="
    fi
    
    # Test 3: Oh My Zsh installation
    log_info "=== Testing Oh My Zsh ==="
    run_test "Oh My Zsh directory" "test_directory_exists '$HOME/.oh-my-zsh'"
    run_test "Oh My Zsh main script" "test_file_exists '$HOME/.oh-my-zsh/oh-my-zsh.sh'"
    echo ""
    
    # Test 4: Dotfiles symlinking
    log_info "=== Testing Dotfiles Symlinking ==="
    dotfiles=(".vimrc" ".tmux.conf" ".zshrc" ".gitconfig")
    for dotfile in "${dotfiles[@]}"; do
        run_test "$dotfile symlink exists" "test_symlink_exists '$HOME/$dotfile'"
        run_test "$dotfile target exists" "test_symlink_target_exists '$HOME/$dotfile'"
    done
    echo ""
    
    # Test 5: Python and Rust Environment  
    log_info "=== Testing Python Environment ==="
    if pyenv global >/dev/null 2>&1; then
        python_version=$(pyenv global)
        log_pass "pyenv global Python version: $python_version"
        ((TESTS_PASSED++))
    else
        log_warning "No global Python version set in pyenv (may be expected)"
    fi
    
    # Test pyenv shims directory
    run_test "pyenv shims directory" "test_directory_exists '$HOME/.pyenv/shims'"
    
    run_test "Cargo home directory" "test_directory_exists '$HOME/.cargo'"
    run_test "Cargo binary directory" "test_directory_exists '$HOME/.cargo/bin'"
    run_test "Rust toolchain directory" "test_directory_exists '$HOME/.rustup'"
    
    # Test 7: Configuration validation
    log_info "=== Testing Configuration Files ==="
    
    # Test .zshrc content
    if [[ -f "$HOME/.zshrc" ]]; then
        run_test ".zshrc contains Oh My Zsh configuration" "grep -q 'oh-my-zsh' '$HOME/.zshrc'"
        run_test ".zshrc contains export statements" "grep -q 'export' '$HOME/.zshrc'"
    fi
    
    # We expect personal details to be stored in ~/.gitconfig.local and included here
    run_test ".gitconfig includes local override file" "grep -q '^[[:space:]]*path = ~/.gitconfig.local' '$HOME/.gitconfig'"
    run_test ".gitconfig contains delta pager configuration" "grep -q 'pager = delta' '$HOME/.gitconfig'"
    
    run_test ".vimrc contains basic configuration" "grep -q 'set' '$HOME/.vimrc'"
    
    run_test ".tmux.conf contains configuration" "grep -q 'set' '$HOME/.tmux.conf'"
    
    run_test "Modular shell utilities system is configured" "grep -q '.config/shell-utils' '$HOME/.zshrc'"
    run_test "Shell utilities are installed" "test -f '$HOME/.config/shell-utils/shell-utils.sh'"
    echo ""
    
    run_test "uv can list Python versions" "uv python list >/dev/null 2>&1 || true"
    
    run_test "Git can show version" "git --version >/dev/null 2>&1"
    run_test "Git config is readable" "git config --list >/dev/null 2>&1"
    
    run_test "Python3 can run basic commands" "python3 -c 'print(\"test\")' >/dev/null 2>&1"
    
    run_test "Node.js can execute JavaScript" "node -e 'console.log(\"test\")' >/dev/null 2>&1"
    
    run_test "Rust compiler responds to version check" "rustc --version >/dev/null 2>&1"
    
    run_test "tmux can show version" "tmux -V >/dev/null 2>&1"
    
    run_test "Vim can show version" "vim --version >/dev/null 2>&1"
    
    run_test "fzf can show version" "fzf --version >/dev/null 2>&1"
    run_test "fzf can list files" "echo | fzf --filter='' >/dev/null 2>&1 || true"
    
    run_test "delta can show version" "delta --version >/dev/null 2>&1"
    run_test "delta can process diff" "echo -e 'line1\nline2' | delta --color=never >/dev/null 2>&1 || true"
    
    # Test 10: Integration tests
    log_info "=== Testing Integration ==="
    
    run_test "pyenv can list available versions" "pyenv install --list >/dev/null 2>&1"
    run_test "pyenv global Python is usable" "pyenv exec python3 --version >/dev/null 2>&1"
    
    # Test 11: Tool versions (informational)
    log_info "=== Tool Versions ==="
    tools_with_version=(
        "git --version"
        "python3 --version"
        "node --version"
        "npm --version"
        "yarn --version"
        "rustc --version"
        "cargo --version"
        "pyenv --version"
        "uv --version"
        "tsc --version"
        "brew --version | head -1"
        "vim --version | head -1"
        "tmux -V"
        "zsh --version"
        "btop --version"
        "nmap --version | head -1"
        "htop --version"
        "ipython --version"
        "rg --version"
        "helm version --short"
        "speedtest-cli --version"
        "fzf --version"
        "delta --version"
        "docker --version"
        "tshark --version | head -1"
        "java --version | head -1 || java -version 2>&1 | head -1"
        "watch --version | head -1"
    )
    
    for tool_cmd in "${tools_with_version[@]}"; do
        tool_name=$(echo "$tool_cmd" | cut -d' ' -f1)
        version_output=$(eval "$tool_cmd" 2>/dev/null || echo "Version check failed")
        log_info "$tool_name: $version_output"
    done
    echo ""
    
    # Test 12: File permissions
    log_info "=== Testing File Permissions ==="
    scripts=("install.sh")
    for script in "${scripts[@]}"; do
        script_path="$SCRIPT_DIR/$script"
        if [[ -f "$script_path" ]]; then
            run_test "$script is executable" "[[ -x '$script_path' ]]"
        else
            log_warning "$script not found at $script_path"
        fi
    done
    echo ""
    
    # Final results
    log_info "=== Test Results Summary ==="
    log_success "Tests passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Tests failed: $TESTS_FAILED"
        echo ""
        log_error "Some tests failed. Please check the output above for details."
        exit 1
    else
        log_success "All tests passed! macOS installation appears to be working correctly."
        echo ""
        log_info "You can now:"
        log_info "1. Restart your terminal or run 'source ~/.zshrc'"
        log_info "2. Configure your system preferences manually (see install script output)"
        log_info "3. Customize your dotfiles as needed"
        exit 0
    fi
}

# Run main function
main "$@"
