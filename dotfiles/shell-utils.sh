#!/usr/bin/env bash

# Shared utility functions for dotfiles scripts
# This file should be sourced by other scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Beautiful logging functions with icons
log_info() {
    echo -e "${BLUE}ℹ️  ${WHITE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ ${WHITE}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${WHITE}$1${NC}"
}

log_error() {
    echo -e "${RED}❌ ${WHITE}$1${NC}"
}

log_install() {
    echo -e "${CYAN}📦 ${WHITE}Installing $1...${NC}"
}

log_found() {
    echo -e "${GREEN}✨ ${WHITE}$1${NC}"
}

log_skip() {
    echo -e "${YELLOW}⏭️  ${WHITE}Skipping: $1${NC}"
}

log_stage() {
    echo -e "${PURPLE}🚀 ${WHITE}$1${NC}"
}

# Test logging functions
log_test() {
    echo -e "${BLUE}🧪 ${WHITE}$1${NC}"
}

log_pass() {
    echo -e "${GREEN}✅ ${WHITE}$1${NC}"
}

log_fail() {
    echo -e "${RED}❌ ${WHITE}$1${NC}"
}

log_check() {
    echo -e "${YELLOW}🔍 ${WHITE}$1${NC}"
}

log_setting() {
    echo -e "${GREEN}⚙️  ${WHITE}$1${NC}"
}

log_header() {
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}$1${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
}

log_complete() {
    echo ""
    echo -e "${CYAN}╭─────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${GREEN}🎉 Installation Complete!${NC}                     ${CYAN}│${NC}"
    echo -e "${CYAN}╰─────────────────────────────────────────────────╯${NC}"
    echo ""
}

log_step() {
    echo -e "${BLUE}📋 ${WHITE}$1${NC}"
}

# Extract various archive formats
function extract() {
    if [ -f $1 ]; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar e $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)     echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create directory and navigate to it in one command
function mkcd() {
    if [ $# -ne 1 ]; then
        echo "Usage: mkcd <directory>"
        return 1
    fi
    
    mkdir -p "$1" && cd "$1"
}

# Function to search for code owners
function owner() {
    grep -E "^\S*$1\S*\s.*$" --color=never ~/code/medigator/.github/CODEOWNERS
}

# Function to ask for user confirmation before proceeding with an installation stage
# Usage: confirm_stage "Stage description" [default_yes]
# Returns 0 if user wants to proceed, 1 if they want to skip
confirm_stage() {
    local stage_description="$1"
    local default_yes="${2:-false}"
    
    # Skip prompts in CI, non-interactive mode, or when AUTO_YES is enabled
    if [[ -n "${CI:-}" ]] || [[ -n "${NONINTERACTIVE:-}" ]] || [[ "${AUTO_YES:-false}" == "true" ]]; then
        if [[ "${AUTO_YES:-false}" == "true" ]]; then
            log_info "Auto-proceeding with $stage_description (-y flag enabled)"
        else
            log_info "Auto-proceeding with $stage_description (CI/non-interactive mode)"
        fi
        return 0
    fi
    
    while true; do
        echo ""
        echo -e "${CYAN}❓ ${WHITE}Do you want to $stage_description?${NC}"
        
        if [[ "$default_yes" == "true" ]]; then
            echo -ne "${YELLOW}   Press Enter or 'y' for Yes, or 'n' for No (Y/n): ${NC}"
            read -k 1 REPLY 2>/dev/null || read -n 1 REPLY 2>/dev/null || read REPLY
            echo ""
            
            if [[ -z "$REPLY" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
                # Empty reply (Enter key) or y/Y means yes for default_yes=true
                log_stage "Proceeding with $stage_description"
                return 0
            elif [[ $REPLY =~ ^[Nn]$ ]]; then
                log_skip "$stage_description"
                return 1
            else
                # Invalid input - show error and loop
                log_warning "Invalid input: '$REPLY'. Please press Enter, 'y' for Yes, or 'n' for No."
                continue
            fi
        else
            echo -ne "${YELLOW}   Press 'y' for Yes, or 'n' for No (y/n): ${NC}"
            read -k 1 REPLY 2>/dev/null || read -n 1 REPLY 2>/dev/null || read REPLY
            echo ""
            
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_stage "Proceeding with $stage_description"
                return 0
            elif [[ $REPLY =~ ^[Nn]$ ]]; then
                log_skip "$stage_description"
                return 1
            else
                # Invalid input - show error and loop
                if [[ -z "$REPLY" ]]; then
                    log_warning "Please provide a clear answer: press 'y' for Yes or 'n' for No."
                else
                    log_warning "Invalid input: '$REPLY'. Please press 'y' for Yes or 'n' for No."
                fi
                continue
            fi
        fi
    done
}

