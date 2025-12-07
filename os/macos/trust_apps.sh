#!/bin/bash

# macOS App Trust Script
# Removes quarantine attributes from installed applications to avoid security warnings
# This script uses xattr to trust all apps in /Applications and common brew cask locations

set -euo pipefail

# Source shared utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$DOTFILES_ROOT/dotfiles/functions.sh"
source "$DOTFILES_ROOT/utils.sh"

# Check if we're on macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    log_error "This script is designed for macOS only"
    exit 1
fi

# Function to remove quarantine attribute from a path
remove_quarantine() {
    local path="$1"
    local display_name="$2"

    if [[ -e "$path" ]]; then
        # Check if the quarantine attribute exists
        if xattr -l "$path" 2> /dev/null | grep -q "com.apple.quarantine"; then
            log_info "Trusting $display_name..."
            sudo xattr -rd com.apple.quarantine "$path" 2> /dev/null || {
                log_warning "Failed to remove quarantine from $display_name (may already be trusted)"
            }
        else
            log_info "$display_name is already trusted"
        fi
    fi
}

# Function to trust apps in a directory
trust_apps_in_directory() {
    local directory="$1"
    local description="$2"

    if [[ ! -d "$directory" ]]; then
        log_info "Directory $directory not found, skipping"
        return
    fi

    log_step "Processing $description..."

    local count=0
    while IFS= read -r -d '' app_path; do
        local app_name=$(basename "$app_path")
        remove_quarantine "$app_path" "$app_name"
        ((count++))
    done < <(find "$directory" -maxdepth 1 -name "*.app" -print0 2> /dev/null)

    if [[ $count -eq 0 ]]; then
        log_info "No applications found in $directory"
    else
        log_success "Processed $count applications in $description"
    fi
}

# Function to trust specific apps by name
trust_specific_apps() {
    local app_names=("$@")

    log_step "Trusting specific applications..."

    local found_count=0
    local trusted_count=0

    for app_name in "${app_names[@]}"; do
        local found=false

        # Common locations to search for the app
        local search_paths=(
            "/Applications"
            "$HOME/Applications"
        )

        # Add Homebrew Cask path if available
        if command -v brew > /dev/null 2>&1; then
            local brew_prefix
            brew_prefix=$(brew --prefix)
            search_paths+=("$brew_prefix/Caskroom")
        fi

        for search_path in "${search_paths[@]}"; do
            if [[ -d "$search_path" ]]; then
                # Look for the app (case-insensitive search)
                while IFS= read -r -d '' app_path; do
                    if [[ -n "$app_path" ]]; then
                        local found_app_name=$(basename "$app_path" .app)
                        log_info "Found and trusting: $found_app_name"
                        remove_quarantine "$app_path" "$found_app_name"
                        found=true
                        ((trusted_count++))
                        break
                    fi
                done < <(find "$search_path" -maxdepth 3 -iname "*${app_name}*.app" -print0 2> /dev/null)

                if [[ "$found" == true ]]; then
                    break
                fi
            fi
        done

        if [[ "$found" == true ]]; then
            ((found_count++))
        else
            log_warning "Could not find application: $app_name"
        fi
    done

    if [[ $found_count -eq 0 ]]; then
        log_warning "No specified applications were found"
    else
        log_success "Found and processed $found_count out of ${#app_names[@]} specified applications"
    fi
}

# Main function
main() {
    local specific_apps=("$@")

    log_header "\033[0m \033[37m🔐 macOS Application Trust Script"

    if [[ ${#specific_apps[@]} -gt 0 ]]; then
        log_info "Targeting specific applications: ${specific_apps[*]}"
    else
        log_warning "This script will remove quarantine attributes from installed applications"
    fi

    log_info "This eliminates macOS security warnings when launching apps"
    log_info "Only apps already installed on your system will be affected"
    echo ""

    # Check if running with sudo
    if [[ $EUID -ne 0 ]]; then
        log_info "This script requires administrator privileges to modify app attributes"
        echo ""

        # Skip in CI environment entirely to avoid sudo prompts
        if [[ -n "${CI:-}" ]]; then
            log_warning "Skipping application trust in CI environment (no sudo access)"
            exit 0
        fi

        # Prompt for confirmation unless in automated mode or targeting specific apps
        if [[ -z "${AUTO_YES:-}" ]] && [[ ${#specific_apps[@]} -eq 0 ]]; then
            read -p "Do you want to continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Operation cancelled by user"
                exit 0
            fi
        fi

        # Ask for password upfront
        sudo -v

        # Keep-alive: update existing sudo time stamp until the script has finished
        while true; do
            sudo -n true
            sleep 60
            kill -0 "$$" || exit
        done 2> /dev/null &
    fi

    echo ""
    log_step "Starting application trust process..."
    echo ""

    if [[ ${#specific_apps[@]} -gt 0 ]]; then
        # Trust only specific applications
        trust_specific_apps "${specific_apps[@]}"
    else
        # Trust all applications (original behavior)
        trust_apps_in_directory "/Applications" "main Applications folder"
        trust_apps_in_directory "$HOME/Applications" "user Applications folder"

        # Trust Homebrew Cask applications
        if command -v brew > /dev/null 2>&1; then
            local brew_prefix
            brew_prefix=$(brew --prefix)
            trust_apps_in_directory "$brew_prefix/Caskroom" "Homebrew Cask applications"
        fi

        # Trust any apps in common development directories
        trust_apps_in_directory "/Developer/Applications" "Developer Applications"
        trust_apps_in_directory "/System/Library/CoreServices/Applications" "System Applications"
    fi

    echo ""
    log_success "Application trust process completed!"
    echo ""
    log_info "Benefits:"
    log_info "• No more 'unidentified developer' warnings"
    log_info "• Apps will launch immediately without security prompts"
    echo ""
    log_warning "Security Note:"
    log_info "Only run this script on a trusted system with apps from known sources"
    log_info "Newly installed apps may still require individual approval"
    echo ""

    # Offer to integrate with system settings if that script exists (only for full runs)
    if [[ ${#specific_apps[@]} -eq 0 ]] && [[ -f "$SCRIPT_DIR/system_settings.sh" ]] && [[ -z "${CI:-}" ]] && [[ -z "${AUTO_YES:-}" ]]; then
        echo ""
        read -p "Would you like to also run the system settings configuration script? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "Running system settings configuration..."
            bash "$SCRIPT_DIR/system_settings.sh"
        fi
    fi
}

show_help() {
    echo "macOS Application Trust Script"
    echo ""
    echo "Usage: $0 [OPTIONS] [APP_NAMES...]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -y, --yes      Automatic yes to prompts (non-interactive mode)"
    echo ""
    echo "Arguments:"
    echo "  APP_NAMES      Space-separated list of application names to trust"
    echo "                 If no app names provided, all apps will be processed"
    echo ""
    echo "Examples:"
    echo "  $0                          # Trust all installed applications"
    echo "  $0 \"Visual Studio Code\"     # Trust only VS Code"
    echo "  $0 Chrome Firefox           # Trust only Chrome and Firefox"
    echo "  $0 -y iTerm2 Cursor         # Trust iTerm2 and Cursor (non-interactive)"
    echo ""
    echo "This script removes quarantine attributes from installed applications"
    echo "to eliminate macOS security warnings when launching them."
    echo ""
    echo "When no specific apps are provided, the script will process:"
    echo "  • Applications in /Applications"
    echo "  • Applications in ~/Applications"
    echo "  • Homebrew Cask applications"
    echo "  • Developer and System applications"
    echo ""
}

# Parse command line arguments
declare -a APP_NAMES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h | --help)
            show_help
            exit 0
            ;;
        -y | --yes)
            export AUTO_YES=1
            shift
            ;;
        -*)
            log_error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
        *)
            # This is an app name
            APP_NAMES+=("$1")
            shift
            ;;
    esac
done

# Only run main if this script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${APP_NAMES[@]+"${APP_NAMES[@]}"}"
fi
