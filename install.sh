#!/bin/bash

# Main dotfiles installation script
# Supports: macOS (with easy extensibility for other OSs)

set -uo pipefail

# Parse command line arguments
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
            echo "This script installs dotfiles and development tools for your system."
            echo "Currently supports: macOS, Linux (Ubuntu/Debian-based, including WSL)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Export AUTO_YES for child scripts
export AUTO_YES

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source shared utilities
source "$SCRIPT_DIR/dotfiles/shell-utils.sh"



# OS Detection
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

check_os_support() {
    local os="$1"
    case "$os" in
        macos)
            log_info "Detected macOS - fully supported"
            return 0
            ;;
        linux)
            log_info "Detected Linux - supported"
            return 0
            ;;
        windows)
            log_error "Windows support is not yet implemented"
            log_info "To add Windows support, create scripts in the 'os/windows/' directory"
            return 1
            ;;
        *)
            log_error "Unknown or unsupported operating system"
            log_info "Supported systems: macOS"
            log_info "Planned support: Linux, Windows"
            return 1
            ;;
    esac
}

main() {
    log_info "Starting dotfiles installation..."
    
    local os
    os=$(detect_os)
    
    if ! check_os_support "$os"; then
        exit 1
    fi
    
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Source OS-specific installation script
    local os_script="${script_dir}/os/${os}/install.sh"
    
    if [[ ! -f "$os_script" ]]; then
        log_error "Installation script not found: $os_script"
        exit 1
    fi
    
    # Ensure the OS-specific script is executable
    if [[ ! -x "$os_script" ]]; then
        log_info "Making $os installation script executable..."
        chmod +x "$os_script"
    fi
    
    log_info "Running $os installation script..."
    if [[ "$AUTO_YES" == "true" ]]; then
        "$os_script" -y
    else
        "$os_script"
    fi    

    # Cross-platform next steps (moved from macOS script)
    echo ""
    log_info "Next steps:"
    log_info "• Restart your terminal or run 'source ~/.zshrc' to apply changes"
    if command -v code >/dev/null 2>&1; then
        log_info "• Sign in to VS Code to sync settings and extensions"
    fi
    if command -v cursor >/dev/null 2>&1; then
        log_info "• Sign in to Cursor to sync settings and extensions"
    fi
    if command -v obsidian >/dev/null 2>&1; then
        log_info "• Sync Obsidian notes with your vault"
    fi
}

# Run main function
main "$@"
