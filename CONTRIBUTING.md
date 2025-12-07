# Customization and Contributing

## Customization

### Adding New Tools

Edit the OS-specific installer(s):

- On macOS: update `os/macos/install.sh` (add to the `tools` list or `apps` list)
- On Linux: update `os/linux/install.sh` (check `install_cli_tools` function)

### Modifying Dotfiles

All dotfiles are located in the `dotfiles/` directory:

- `dotfiles/.vimrc` - Vim configuration
- `dotfiles/.tmux.conf` - Tmux configuration
- `dotfiles/.zshrc` - Zsh configuration
- `dotfiles/.gitconfig` - Git configuration
- `dotfiles/functions.sh` - Shared utility functions
- `dotfiles/aliases.sh` - Shared aliases

After modifying, re-run the installer or create symlinks manually:

```bash
ln -sf ~/.dotfiles/dotfiles/.vimrc ~/.vimrc
```

### Adding OS Support

To add support for other operating systems:

1. Create a new directory: `os/[osname]/`
2. Add an `install.sh` script following existing examples
3. The main installer will automatically detect and use it

Example structure:

```text
os/
├── macos/
│   ├── install.sh
└── linux/
    ├── install.sh
```

## Contributing

Feel free to submit issues and enhancement requests! This dotfiles setup is designed to be:

- **Modular** - Easy to add/remove components
- **Cross-platform** - Built for easy OS support addition
- **Configurable** - Simple to customize for personal preferences
