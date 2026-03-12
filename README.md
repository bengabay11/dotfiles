# Development Environment Setup

Complete development environment automation for macOS and Linux (Ubuntu/Debian-based; includes WSL).

## What This Repository Does

A complete development environment setup that:

- **Installs CLI tools** - Development tools, programming languages, package managers
- **Installs applications** - IDEs, browsers, productivity apps (macOS)
- **Configures your shell** - Zsh with Oh My Zsh, Starship prompt, and custom utilities
- **Manages dotfiles** - Configuration files via GNU Stow
- **Sets up environments** - Python with pyenv, Rust with cargo, Node.js, and more

See [dotfiles/README.md](dotfiles/README.md) for detailed documentation about configuration files.

## Features

### 🛠️ Command Line Tools

#### Programming Languages & Runtimes

|                                   |                                    |                                |                                               |
| --------------------------------- | ---------------------------------- | ------------------------------ | --------------------------------------------- |
| [Python](https://www.python.org/) | [Rust](https://www.rust-lang.org/) | [Node.js](https://nodejs.org/) | [TypeScript](https://www.typescriptlang.org/) |
| [OpenJDK](https://openjdk.org/)   |                                    |                                |                                               |

#### Package & Version Management

|                                         |                              |                                       |                                      |
| --------------------------------------- | ---------------------------- | ------------------------------------- | ------------------------------------ |
| [pyenv](https://github.com/pyenv/pyenv) | [Yarn](https://yarnpkg.com/) | [uv](https://github.com/astral-sh/uv) | [poetry](https://python-poetry.org/) |
| [pre-commit](https://pre-commit.com/)   |                              |                                       |                                      |

#### Terminal & Shell Enhancement

|                                              |                                               |                                        |                                                 |
| -------------------------------------------- | --------------------------------------------- | -------------------------------------- | ----------------------------------------------- |
| [Zsh](https://www.zsh.org/)                  | [Oh My Zsh](https://ohmyz.sh/)                | [Starship](https://starship.rs/)       | [Tmux](https://github.com/tmux/tmux)            |
| [bat](https://github.com/sharkdp/bat)        | [eza](https://github.com/eza-community/eza)   | [fzf](https://github.com/junegunn/fzf) | [zoxide](https://github.com/ajeetdsouza/zoxide) |
| [delta](https://github.com/dandavison/delta) | [glow](https://github.com/charmbracelet/glow) | [tldr](https://tldr.sh/)               | [yazi](https://github.com/sxyazi/yazi)          |
| [watch](https://linux.die.net/man/1/watch)   |                                               |                                        |                                                 |

#### Development Tools

|                                                  |                                    |                                           |                                                       |
| ------------------------------------------------ | ---------------------------------- | ----------------------------------------- | ----------------------------------------------------- |
| [Git](https://git-scm.com/)                      | [Vim](https://www.vim.org/)        | [ruff](https://github.com/astral-sh/ruff) | [ShellCheck](https://www.shellcheck.net/)             |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | [jq](https://jqlang.github.io/jq/) | [fd](https://github.com/sharkdp/fd)       | [tree](https://gitlab.com/OldManProgrammer/unix-tree) |
| [ipython](https://ipython.org/)                  | [prettier](https://prettier.io/)   | [act](https://github.com/nektos/act)      | [GitHub CLI](https://cli.github.com/)                 |
| [Claude Code](https://claude.ai/code)            | [GNU Stow](https://www.gnu.org/software/stow/)   |                                           |                                                       |

#### System & DevOps Tools

|                                              |                                                                |                                                    |                                                          |
| -------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------- |
| [btop](https://github.com/aristocratos/btop) | [htop](https://htop.dev/)                                      | [nmap](https://nmap.org/)                          | [speedtest-cli](https://github.com/sivel/speedtest-cli)  |
| [AWS CLI](https://aws.amazon.com/cli/)       | [helm](https://helm.sh/)                                       | [kubectx](https://github.com/ahmetb/kubectx)       | [kubectl](https://kubernetes.io/docs/reference/kubectl/) |
| [k9s](https://k9scli.io/)                    | [TShark](https://www.wireshark.org/docs/man-pages/tshark.html) | [neofetch](https://github.com/dylanaraps/neofetch) | [cloudflared](https://github.com/cloudflare/cloudflared) |

### 📱 Applications (macOS)

GUI applications automatically installed via Homebrew Cask:

|                                                      |                                                  |                                                                   |                                          |
| ---------------------------------------------------- | ------------------------------------------------ | ----------------------------------------------------------------- | ---------------------------------------- |
| [iTerm2](https://iterm2.com/)                        | [Warp](https://www.warp.dev/)                    | [Ghostty](https://ghostty.org/)                                   | [Raycast](https://www.raycast.com/)      |
| [Cursor](https://cursor.sh/)                         | [Visual Studio Code](https://code.visualstudio.com/) | [Google Chrome](https://www.google.com/chrome/)               | [Brave Browser](https://brave.com/)      |
| [Slack](https://slack.com/)                          | [Sublime Text](https://www.sublimetext.com/)     | [Obsidian](https://obsidian.md/)                                  | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| [Wireshark](https://www.wireshark.org/)              | [Postman](https://www.postman.com/)              | [Paintbrush](https://paintbrush.sourceforge.io/)                  | [Typora](https://typora.io/)             |
| [DBeaver Community](https://dbeaver.io/)             | [GitKraken](https://www.gitkraken.com/)          | [Zoom](https://zoom.us/)                                          | [Rectangle](https://rectangleapp.com/)   |
| [AltTab](https://alt-tab-macos.netlify.app/)         |                                                  |                                                                   |                                          |

### ⚙️ Dotfiles

The `dotfiles/` subdirectory contains configuration files managed via GNU Stow:

- Configuration files for Vim, Tmux, Zsh, Git, and more
- Symlinked to your home directory (not copied)
- Can be used as a standalone dotfiles project (independent from the main installation)
- Modular shell utilities system (`~/.shell-utils/`)

See [dotfiles/README.md](dotfiles/README.md) for standalone usage and comprehensive documentation

## Installation

### Prerequisites

- macOS or Linux (Ubuntu/Debian-based; includes WSL)
- Internet connection
- Administrative privileges (sudo access)

### Quick Install

```bash
# Clone the repository
git clone https://github.com/bengabay11/dev-environment-setup.git ~/dev-environment-setup
cd ~/dev-environment-setup

# Run the installation script
./install.sh

# Or run in non-interactive mode (auto-confirm all prompts)
./install.sh -y
```

## Post-Installation

### 1. Restart Your Shell

```bash
# Apply changes
source ~/.zshrc

# Or restart your terminal
```

### 2. Install a Nerd Font

A [Nerd Font](https://www.nerdfonts.com/) is required for terminal icons to display correctly in Starship, eza, and other modern CLI tools.

**Installation:**

- Download from [nerdfonts.com/font-downloads](https://www.nerdfonts.com/font-downloads)
- Install the font on your system
- Configure your terminal to use it as the default font

### 3. Handle macOS Security Warnings (macOS Only)

macOS shows security warnings for apps not downloaded from the App Store. This is normal for Homebrew Cask installations.

**To resolve:**

- **Method 1:** Right-click app in Applications → "Open" → click "Open" in dialog
- **Method 2:** System Settings → Privacy & Security → "Allow Anyway"

Only needed once per application.

### 4. Configure Git Identity

Set your personal Git details in a local file (not tracked in the repository):

```bash
cat > ~/.gitconfig.local <<'EOF'
[user]
  name = Your Name
  email = your.email@example.com
  username = your-username
EOF
```

## Shell

- **Ghostty** - Terminal emulator with configuration in `dotfiles/.config/ghostty/`
- **Zsh** - Default interactive shell with modern features
- **Starship** - Active prompt with gruvbox-rainbow preset
- **Oh My Zsh** - Plugin manager (themes disabled in favor of Starship)
- **Plugins** - Autosuggestions, syntax highlighting, evalcache for fast startup
- **Custom Utilities** - Functions and aliases loaded from `~/.shell-utils/`

## Verify Installation

Test your installation with the comprehensive verification script:

```bash
./test_install.sh
```

The test script checks:

- CLI tool installations
- GUI applications (macOS)
- Configuration file symlinks
- Shell environment setup
- Programming language runtimes

Detailed output shows which components passed or failed.

## License

This project is open source and available under the [MIT License](LICENSE).
