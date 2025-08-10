# Dotfiles

A comprehensive dotfiles setup for macOS with support for development tools and applications. Built with extensibility in mind to easily add support for other operating systems.

## Features

### 🛠️ Command Line Tools

- **Git** - Version control with optimized configuration
- **Python 3.11** (via pyenv) - Python version management
- **Rust** - Systems programming language with Cargo
- **Node.js & npm** - JavaScript runtime and package manager
- **Yarn** - Fast package manager
- **TypeScript** - Typed JavaScript
- **Vim** - Text editor with comprehensive configuration
- **Tmux** - Terminal multiplexer with modern setup
- **Zsh + Oh My Zsh + Powerlevel10k** - Advanced shell with beautiful theme
- **bat** - Enhanced cat with syntax highlighting
- **eza** - Modern ls replacement
- **ruff** - Fast Python linter
- **uv** - Ultra-fast Python package installer
- **pre-commit** - Git hooks framework
- **pyenv** - Python version management
- **btop** - Modern system monitor (alternative to htop)
- **nmap** - Network discovery and security auditing utility
- **htop** - Interactive process viewer
- **ipython** - Enhanced interactive Python shell
- **ripgrep** - Fast text search tool (rg command)
- **helm** - Kubernetes package manager
- **speedtest-cli** - Command-line internet speed test tool

### 📱 Applications (macOS)

- **iTerm2** - Advanced terminal emulator
- **Warp** - Modern terminal with AI features
- **Raycast** - Productivity launcher
- **Cursor** - AI-powered code editor
- **Visual Studio Code** - Popular code editor

- **Google Chrome** - Web browser
- **Brave Browser** - Privacy-focused browser
- **Slack** - Team communication
- **Sublime Text** - Lightweight text editor
- **Obsidian** - Knowledge management and note-taking
- **Docker Desktop** - Container development platform
- **Wireshark** - Network protocol analyzer
- **Postman** - API development and testing tool
- **Typora** - Markdown editor
- **DBeaver Community** - Universal database management tool

### ⚙️ Configuration Files

- `.vimrc` - Comprehensive Vim configuration with modern features, keybindings, and language-specific settings
- `.tmux.conf` - Tmux setup with Ctrl-a prefix, mouse support, and improved splitting
- `.zshrc` - Zsh configuration with Oh My Zsh, Powerlevel10k theme, and development aliases
- `.gitconfig` - Git configuration with user settings and credential helpers
- `.shell-utils` - Shared utility functions and logging for installation scripts

## Installation

### Prerequisites

- macOS (other OS support planned)
- Internet connection
- Administrative privileges

### Quick Install

```bash
# Clone the repository
git clone <your-repository-url> ~/.dotfiles
cd ~/.dotfiles

# Run the installation script
./install.sh

# Or run in non-interactive mode (auto-confirm all prompts)
./install.sh -y
```

### Command Line Options

- `./install.sh` - Interactive mode (prompts for each installation stage)
- `./install.sh -y` or `./install.sh --yes` - Non-interactive mode (auto-confirms all prompts)
- `./install.sh -h` or `./install.sh --help` - Show help message

### What the installer does

1. **OS Detection** - Automatically detects your operating system
2. **Homebrew Setup** - Installs Homebrew if not present
3. **Tool Installation** - Installs all command-line tools via Homebrew
4. **App Installation** - Installs applications via Homebrew Cask
5. **Oh My Zsh** - Installs and configures Oh My Zsh
6. **Dotfiles Setup** - Creates symlinks to configuration files
7. **Python Setup** - Configures pyenv with latest Python version
8. **System Preferences** - Optionally configures macOS system settings

## Usage

### After Installation

1. Restart your terminal or run `source ~/.zshrc`

2. **Handle macOS Security Warnings (Important!)**

   When you first open newly installed applications, macOS may show security warnings because they weren't downloaded from the App Store. This is normal and expected.

   **To resolve security warnings:**

   - **Method 1:** Right-click the app in Applications folder → select "Open" → click "Open" in the dialog
   - **Method 2:** Go to System Settings → Privacy & Security → click "Allow Anyway" next to the blocked app

   This only needs to be done once per application.

3. Update your Git configuration:

   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

### Key Features

#### Vim Configuration

- Modern vim setup with sensible defaults and true color support
- Comprehensive syntax highlighting and file type detection
- Space as leader key with intuitive key mappings
- Persistent undo, backup, and swap file management
- Language-specific indentation (Python, JavaScript, TypeScript, Rust, YAML, HTML/CSS)
- Window and buffer navigation shortcuts
- Automatic whitespace cleanup and spell checking
- Enhanced status line with file information

#### Tmux Configuration

- `Ctrl-a` as prefix key (instead of default `Ctrl-b`)
- Mouse support enabled for easier pane interaction
- Intuitive pane splitting with `\` (vertical) and `-` (horizontal)
- Easy config reloading with `Ctrl-a r`
- Simplified, clean configuration focused on essential features

#### Zsh Configuration

- Oh My Zsh with Powerlevel10k theme for beautiful, informative prompt
- Enhanced ls commands using `eza`
- Enhanced cat using `bat`
- Comprehensive git aliases and development shortcuts
- Useful functions for productivity
- Command history optimization and plugin support

### System Preferences

The installer can optionally configure macOS system preferences to optimize your development environment:

```bash
# During installation, you'll be prompted:
# "Do you want to configure macOS system preferences? (y/N):"

# Or run separately:
./os/macos/system_settings.sh
```

**What gets configured:**

- **Finder**: Show hidden files, file extensions, path bar, and status bar
- **Menu Bar**: Show battery percentage
- **Security**: Administrative password prompts for configuration changes
- **Development**: Disable file extension change warnings for better development workflow

The system configuration script is minimal but can be extended to include additional macOS settings as needed.

## Customization

### Adding New Tools

1. Edit `os/macos/install.sh`
2. Add the tool name to the appropriate array:
   - `tools` array for command-line tools
   - `apps` array for GUI applications

### Modifying Dotfiles

All dotfiles are located in the `dotfiles/` directory:

- `dotfiles/.vimrc` - Vim configuration
- `dotfiles/.tmux.conf` - Tmux configuration
- `dotfiles/.zshrc` - Zsh configuration
- `dotfiles/.gitconfig` - Git configuration
- `dotfiles/.shell-utils` - Shared utility functions and logging

After modifying, re-run the installer or create symlinks manually:

```bash
ln -sf ~/.dotfiles/dotfiles/.vimrc ~/.vimrc
```

### Adding OS Support

To add support for other operating systems:

1. Create a new directory: `os/[osname]/`
2. Add an `install.sh` script following the macOS example
3. The main installer will automatically detect and use it

Example structure:

```text
os/
├── macos/
│   └── install.sh
├── linux/          # Future support
│   └── install.sh
└── windows/         # Future support
    └── install.sh
```

## Testing Your Installation

After running the installer, you can verify that everything was installed correctly using the comprehensive test script:

```bash
./os/macos/test_install.sh
```

**What the test script checks:**

- ✅ **Essential CLI Tools** - Verifies git, python3, vim, tmux, node, npm, yarn, zsh
- ✅ **Development Tools** - Checks rust, cargo, pyenv, uv, TypeScript, bat, eza, ruff, pre-commit, btop, nmap, htop, ipython, ripgrep, helm
- ✅ **Oh My Zsh** - Validates Oh My Zsh installation and configuration
- ✅ **Dotfiles Symlinking** - Ensures all dotfiles are properly symlinked
- ✅ **Python Environment** - Verifies pyenv and Python version setup
- ✅ **Configuration Files** - Validates content of .zshrc, .gitconfig, and other configs
- ✅ **Environment Setup** - Checks PATH configuration for Homebrew and Cargo
- ✅ **Tool Versions** - Displays version information for installed tools
- ✅ **File Permissions** - Ensures scripts are executable

The test script provides detailed output showing which components passed or failed, making it easy to identify any issues with your installation.

## File Structure

```text
dotfiles/
├── install.sh              # Main installation script
├── LICENSE                 # MIT License
├── README.md               # This documentation
├── os/
│   └── macos/
│       ├── install.sh      # macOS-specific installer
│       ├── system_settings.sh # macOS system preferences
│       └── test_install.sh # Comprehensive test script
└── dotfiles/
    ├── .vimrc              # Vim configuration
    ├── .tmux.conf          # Tmux configuration
    ├── .zshrc              # Zsh configuration with Oh My Zsh
    ├── .gitconfig          # Git configuration
    └── .shell-utils        # Shared utility functions and logging
```

## Contributing

Feel free to submit issues and enhancement requests! This dotfiles setup is designed to be:

- **Modular** - Easy to add/remove components
- **Cross-platform** - Built for easy OS support addition
- **Configurable** - Simple to customize for personal preferences

## License

This project is open source and available under the [MIT License](LICENSE).
