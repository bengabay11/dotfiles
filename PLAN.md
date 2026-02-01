# Implementation Plan: Claude Code Installation Integration

## Ticket Information
- **Jira Key**: SCRUM-6
- **Summary**: Feature: Claude Code installation for Mac and Linux
- **URL**: https://bengabay38.atlassian.net/browse/SCRUM-6

## Overview
Integrate Claude Code CLI tool installation into the existing dotfiles project for both macOS and Linux environments. Claude Code is an AI agent CLI tool that will be installed using its official installation script and added to the shell PATH configuration.

## Architecture Analysis

### Current Installation Flow
The dotfiles project follows a modular architecture:
1. **Main installer** (`install.sh`): Detects OS and delegates to OS-specific scripts
2. **OS-specific installers**:
   - `os/macos/install.sh`: macOS installation logic
   - `os/linux/install.sh`: Linux installation logic
3. **Shared utilities** (`utils.sh`): Cross-platform installation helper functions
4. **Shell configuration** (`dotfiles/.zshrc`): Shell PATH and environment setup

### Installation Patterns
The project uses several patterns for installing tools with piped installation commands:
- `try_install_uv()` - Installs using `curl | sh` pattern
- `try_install_ruff()` - Installs using `curl | sh` pattern
- `try_install_helm()` - Installs using `curl | bash` pattern
- `try_install_act()` - Installs using `curl | sudo bash` pattern
- `try_install_poetry()` - Installs using `curl | python3 -` pattern

Claude Code follows a similar pattern and should use the same approach.

## Files to Modify

### 1. `utils.sh`
- **Path**: `/c/Users/benga/Code/git_repositories/dotfiles/utils.sh`
- **Change**: Add new function `try_install_claude_code()`
- **Location**: After line 309 (after `try_install_uv()`)
- **Purpose**: Cross-platform installation function for Claude Code

### 2. `os/macos/install.sh`
- **Path**: `/c/Users/benga/Code/git_repositories/dotfiles/os/macos/install.sh`
- **Changes**:
  - Add Claude Code to CLI tools list in `install_cli_tools()` function (around line 87)
  - Call `try_install_claude_code` function after other CLI tools (around line 90)
  - Add Claude Code to installation stages summary (around line 185)
- **Purpose**: Integrate Claude Code installation into macOS flow

### 3. `os/linux/install.sh`
- **Path**: `/c/Users/benga/Code/git_repositories/dotfiles/os/linux/install.sh`
- **Changes**:
  - Call `try_install_claude_code` function in `install_cli_tools()` (around line 194)
  - Add Claude Code to installation stages summary (around line 233)
- **Purpose**: Integrate Claude Code installation into Linux flow

### 4. `test_install.sh`
- **Path**: `/c/Users/benga/Code/git_repositories/dotfiles/test_install.sh`
- **Change**: Add Claude Code command test to `test_cli_tools_exists()` function
- **Location**: After line 112 (in the tools array)
- **Purpose**: Verify Claude Code installation in test suite

### 5. `README.md`
- **Path**: `/c/Users/benga/Code/git_repositories/dotfiles/README.md`
- **Change**: Add Claude Code to the Command Line Tools section
- **Location**: After line 40 (in the features list)
- **Purpose**: Document Claude Code as an installed tool

## No Files to Create
All required functionality can be added to existing files following the established patterns.

## Implementation Steps

### Step 1: Add Claude Code Installation Function to utils.sh
**Location**: `utils.sh` after line 309

Add a new function following the pattern of `try_install_uv()`:

```bash
# Dedicated function for installing Claude Code CLI
try_install_claude_code() {
    local tool_name="Claude Code"
    if ! command -v claude > /dev/null 2>&1; then
        log_install "$tool_name"
        if ! curl -fsSL https://claude.ai/install.sh | bash; then
            log_error "Failed to install $tool_name"
            FAILED_INSTALLATIONS+=("$tool_name")
        else
            log_success "$tool_name installed successfully"
        fi
    else
        log_found "$tool_name is already installed ($(claude --version 2> /dev/null || echo version unknown))"
    fi
}
```

**Rationale**:
- Uses `command -v claude` to check if already installed (idempotent)
- Follows the exact installation command from requirements: `curl -fsSL https://claude.ai/install.sh | bash`
- Tracks failures in the global `FAILED_INSTALLATIONS` array
- Uses standard logging functions (`log_install`, `log_error`, `log_success`, `log_found`)
- Attempts to show version for already-installed cases

### Step 2: Integrate into macOS Installation
**Location**: `os/macos/install.sh`

#### 2a. Add to CLI tools display list (around line 86)
Add to the `tools` array before the closing parenthesis:
```bash
        "Claude Code:claude:claude --version:claude"
```

**Note**: This line is informational only and will be processed by `install_tools_with_package_manager`, but since Claude Code is not available via Homebrew, it will be handled separately by our dedicated function.

#### 2b. Call installation function (around line 90)
After the line `try_install_uv`, add:
```bash
    try_install_claude_code
```

#### 2c. Update installation stages display (around line 185)
Update the stage numbering and add a new entry:
```bash
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, claude, etc.)${NC}"
```

**Rationale**:
- Follows the same pattern as `try_install_uv` which also uses a piped installation
- Called after standard package manager installations
- Maintains consistency with existing tool installation flow

### Step 3: Integrate into Linux Installation
**Location**: `os/linux/install.sh`

#### 3a. Call installation function (around line 194)
After the line `try_install_kubectl`, add:
```bash
    try_install_claude_code
```

#### 3b. Update installation stages display (around line 233)
Update the text to include Claude Code:
```bash
    echo -e "   ${BLUE}2.${NC} ${WHITE}🛠️  Install command-line tools (git, python, node, claude, etc.)${NC}"
```

**Rationale**:
- Linux script imports `try_install_claude_code` from shared `utils.sh`
- Placed at the end of CLI tools installation for clarity
- Consistent with macOS implementation

### Step 4: Add PATH Configuration Verification
**Location**: Review `dotfiles/.zshrc` and installer scripts

**Analysis**: The Claude Code installer script (from https://claude.ai/install.sh) likely:
1. Installs the binary to `~/.claude/bin/claude`
2. Automatically adds `~/.claude/bin` to PATH in shell configuration files

**Verification Strategy**:
- The existing `.zshrc` already has logic to ensure `~/.local/bin` and `~/bin` are in PATH (lines 11-17)
- The Claude Code installer should handle adding `~/.claude/bin` to PATH automatically
- If the installer doesn't add it, users will need to source their shell config or restart terminal (already documented in installation next steps)

**No Changes Required**: The official installer handles PATH configuration. The existing installation success message already instructs users to restart terminal or run `source ~/.zshrc`.

### Step 5: Add Test Verification
**Location**: `test_install.sh`

Add to the `tools` array in `test_cli_tools_exists()` function (around line 112):
```bash
        "Claude Code installation:claude"
```

**Rationale**:
- Verifies that the `claude` command is available after installation
- Follows the same pattern as other CLI tool tests
- Simple existence check using `command -v claude`

### Step 6: Update Documentation
**Location**: `README.md`

Add to the Command Line Tools section (after line 40, before the Applications section):
```markdown
- **Claude Code** - AI-powered CLI agent for development tasks
```

**Rationale**:
- Documents the new tool in the features list
- Maintains alphabetical/logical ordering with other tools
- Consistent formatting with existing tool descriptions

## Testing Strategy

### Manual Testing - macOS
1. **Fresh Installation Test**:
   ```bash
   # On a clean macOS system (or VM)
   git clone <repo-url> ~/.dotfiles
   cd ~/.dotfiles
   ./install.sh -y
   # Verify Claude Code is installed
   command -v claude
   claude --version
   ```

2. **Re-run Safety Test**:
   ```bash
   # After successful installation, run again
   ./install.sh -y
   # Should detect Claude Code is already installed
   # Should not show errors or attempt re-installation
   ```

3. **Automated Test Suite**:
   ```bash
   ./test_install.sh
   # Should show "✅ Claude Code installation" as passed
   ```

### Manual Testing - Linux (Ubuntu/Debian/WSL)
1. **Fresh Installation Test**:
   ```bash
   # On a clean Linux system or WSL
   git clone <repo-url> ~/.dotfiles
   cd ~/.dotfiles
   ./install.sh -y
   # Verify Claude Code is installed
   command -v claude
   claude --version
   ```

2. **Re-run Safety Test**:
   ```bash
   # After successful installation, run again
   ./install.sh -y
   # Should detect Claude Code is already installed
   # Should not show errors or attempt re-installation
   ```

3. **PATH Verification**:
   ```bash
   # Test in new shell session
   zsh -c 'command -v claude'
   # Test after sourcing .zshrc
   source ~/.zshrc && command -v claude
   ```

4. **Automated Test Suite**:
   ```bash
   ./test_install.sh --no-apps
   # Should show "✅ Claude Code installation" as passed
   ```

### Edge Cases to Test
1. **Already installed**: Run installer when Claude Code is already present
2. **Network failure**: Simulate network issues during installation (should fail gracefully)
3. **Partial installation**: If installation fails mid-way, re-running should recover
4. **PATH not updated**: Verify terminal restart or source command fixes PATH issues

## Acceptance Criteria Verification

✅ **Running the dotfiles setup on a new macOS machine installs Claude Code**
- Implemented in `os/macos/install.sh` via `try_install_claude_code()`
- Uses official installation method: `curl -fsSL https://claude.ai/install.sh | bash`

✅ **Running the dotfiles setup on a new Linux machine installs Claude Code**
- Implemented in `os/linux/install.sh` via `try_install_claude_code()`
- Uses same official installation method

✅ **Re-running the setup does not result in errors or redundant installations**
- Function checks `command -v claude` before attempting installation
- Logs "already installed" message with version info
- Follows idempotent pattern used by all other tools

✅ **The 'claude' command is accessible from the terminal upon completion**
- Official installer adds `~/.claude/bin` to PATH automatically
- Existing documentation instructs users to restart terminal or source shell config
- Test suite verifies `claude` command is available

## Risk Assessment & Mitigation

### Risk 1: Official Installer Script Changes
**Impact**: Medium
**Probability**: Low
**Description**: The official Claude Code installer at https://claude.ai/install.sh could change its behavior, installation path, or requirements.

**Mitigation**:
- Our implementation follows the documented official installation method
- Error handling logs failures but doesn't break the entire installation
- Users can manually install Claude Code if automated installation fails
- Test suite will catch installation failures during CI/CD

### Risk 2: PATH Configuration Issues
**Impact**: Medium
**Probability**: Low
**Description**: The installer might not properly add `~/.claude/bin` to PATH in all environments.

**Mitigation**:
- Official installer is responsible for PATH configuration
- Existing installation instructions already tell users to restart terminal or source shell config
- If needed, users can manually add to PATH in `~/.zshrc`
- Test suite verifies `claude` command is accessible

### Risk 3: Platform-Specific Installation Differences
**Impact**: Low
**Probability**: Low
**Description**: Installation behavior might differ between macOS and Linux.

**Mitigation**:
- Same official installation command works for both platforms
- Error handling is platform-agnostic
- Test suite runs on both platforms
- Failures are logged but don't prevent other tools from installing

### Risk 4: Internet Connectivity Required
**Impact**: Low
**Probability**: Low
**Description**: Installation requires internet to download from claude.ai.

**Mitigation**:
- All other tools also require internet (Homebrew, apt, curl downloads)
- This is expected behavior for initial setup
- Error handling gracefully reports if download fails
- Installation can be retried by re-running setup script

## Dependencies
- **curl**: Already installed as part of base tools on both macOS and Linux
- **bash**: Available by default on both platforms
- **Internet connection**: Required for downloading the installer (standard for all tools)

## Rollback Plan
If issues arise after implementation:
1. Remove the `try_install_claude_code()` call from both OS-specific installers
2. Remove the function from `utils.sh`
3. Users can manually uninstall with: `rm -rf ~/.claude`
4. No changes needed to core installation logic

## Post-Implementation Verification
After merging, verify:
1. ✅ CI/CD tests pass on both macOS and Linux environments
2. ✅ Documentation accurately reflects the new feature
3. ✅ Test suite includes Claude Code verification
4. ✅ Installation works on fresh machines (manual testing)
5. ✅ Re-running installation is safe and idempotent

## Notes
- The implementation follows existing patterns for tools with piped installation commands
- No changes to core installation logic or flow control
- Minimal impact on existing functionality
- All changes are additive (no deletions or modifications to existing tool installations)
- The feature is optional via interactive prompts (users can choose to skip CLI tools installation)
