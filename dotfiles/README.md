# Dotfiles

This directory contains configuration files (dotfiles) managed with [GNU Stow](https://www.gnu.org/software/stow/). These dotfiles can be used standalone or as part of the full development environment setup.

## What's Included

This directory mirrors your home directory structure and contains:

- **Configuration files** - Standard dotfiles for various tools
- **XDG config directory** - `.config/` for modern application configurations
- **Modular shell utilities** - `.shell-utils/` for reusable functions and aliases

## How It Works

This setup uses [GNU Stow](https://www.gnu.org/software/stow/) for symlink management. Files in this directory are symlinked to your home directory:

```text
dotfiles/.<file>     → ~/.<file>
dotfiles/.config/    → ~/.config/
dotfiles/.shell-utils/ → ~/.shell-utils/
```

## Usage

### Standalone Installation

You can use these dotfiles independently without the full development environment setup:

```bash
# Clone the repository
git clone https://github.com/bengabay11/dev-environment-setup.git ~/dev-environment-setup
cd ~/dev-environment-setup/dotfiles

# Install GNU Stow if needed
# macOS:
brew install stow
# Linux:
sudo apt install stow

# Create symlinks
./setup.sh
```

This will symlink all configuration files to your home directory.

### Adding New Dotfiles

1. Add the file to this directory (e.g., `dotfiles/.bashrc`)
2. Run `./setup.sh` to create the symlink
3. The file will now be symlinked to your home directory (`~/.bashrc`)

**Example:**

```bash
# Add a new configuration file
echo "export MY_VAR=value" > dotfiles/.my-config

# Create the symlink
cd dotfiles && ./setup.sh

# Verify
ls -la ~/.my-config
```

### Modifying Existing Dotfiles

Simply edit the files in this directory. Changes take effect immediately because they're symlinked:

```bash
# Edit in the repo
vim dotfiles/.vimrc
```

### Removing Dotfiles

```bash
cd dotfiles
stow -D .  # Remove all symlinks
```

## Integration with Development Environment Setup

This directory can be used in two ways:

**Standalone:**

```bash
cd dotfiles && ./setup.sh
```

Directly creates symlinks without backing up existing files.

**Via parent installer:**

```bash
cd .. && ./install.sh
```

Full environment setup that backs up existing dotfiles to `.backup` before symlinking, and installs additional dependencies.

## Customization

### Local Overrides

Configuration files support local override files for machine-specific or private settings. These `.local` files are not tracked in the repository. Check individual config files to see which overrides are supported and how to use them.

### Modifying Configurations

Customize any configuration file to match your preferences:

1. Edit files in `dotfiles/`
2. Changes are immediately reflected (due to symlinks)
3. Commit your changes to sync across machines

### Adding Custom Utilities

Add your own shell utilities to `.shell-utils/`:

```bash
# Create your utility file
echo 'my_function() { echo "Hello!"; }' > dotfiles/.shell-utils/my-utils.sh

# Symlink and reload
cd dotfiles && ./setup.sh
source ~/.zshrc
```

All `.sh` files in `.shell-utils/` are automatically loaded.

## Platform Support

These dotfiles are designed to work on UNIX-like systems. Platform-specific configurations automatically adjust based on your system when applicable.
