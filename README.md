# LabRat

**Your trusty environment for every test cage**

LabRat is a modular, portable environment configurator designed for developers and testers who frequently SSH into remote servers. With a single command, you can install and configure your preferred tools, shell enhancements, and development environment.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation Methods](#installation-methods)
- [Available Modules](#available-modules)
- [Usage](#usage)
- [Configuration](#configuration)
- [tmux Configuration](#tmux-configuration)
- [fastfetch Configuration](#fastfetch-configuration)
- [Directory Structure](#directory-structure)
- [Supported Distributions](#supported-distributions)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **One-liner deployment** - Bootstrap with curl or wget from any server
- **Modular architecture** - Install only what you need
- **User-local installation** - No root required for most tools
- **Cross-distro support** - Ubuntu, Debian, CentOS, RHEL, Fedora, and more
- **Version pinning** - Lock specific tool versions for reproducibility
- **Portable configs** - Consistent environment across all servers
- **Interactive and non-interactive modes** - Perfect for automation and CI/CD
- **Backup and restore** - Automatically backs up existing configurations
- **Update support** - Keep your tools current with a single command

---

## Requirements

### Minimum Requirements

- Bash 4.0 or later
- curl or wget
- git
- Internet connectivity (for downloading packages)

### Optional Requirements

- sudo access (for system package installation)
- unzip (for some binary installations)
- fontconfig (for font cache updates)

### Supported Architectures

- x86_64 / amd64
- aarch64 / arm64
- armv7l (limited support)

---

## Quick Start

### One-liner Installation (Interactive)

```bash
# Using curl
curl -fsSL https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash

# Using wget
wget -qO- https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash
```

### One-liner Installation (Non-interactive)

```bash
# Install specific modules silently
curl -fsSL https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash -s -- --modules tmux,fzf,neovim --yes

# Install everything
curl -fsSL https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash -s -- --all --yes
```

### Clone and Install

```bash
git clone https://github.com/amd-marmoody/Labrat.git
cd Labrat
./install.sh
```

---

## Installation Methods

### Method 1: Bootstrap Script (Recommended)

The bootstrap script handles everything automatically:

1. Detects your OS and package manager
2. Installs minimal dependencies (git, curl)
3. Clones the LabRat repository
4. Launches the interactive installer

```bash
curl -fsSL https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash
```

### Method 2: Direct Clone

For more control over the installation:

```bash
git clone https://github.com/amd-marmoody/Labrat.git ~/.labrat
cd ~/.labrat
./install.sh
```

### Method 3: Download and Extract

If git is not available:

```bash
curl -L https://github.com/amd-marmoody/Labrat/archive/refs/heads/main.tar.gz | tar xz
cd Labrat-main
./install.sh
```

---

## Available Modules

### Terminal Multiplexer

| Module | Description | Version |
|--------|-------------|---------|
| `tmux` | Terminal multiplexer with 8 themes, plugins, mouse support, scratchpad | Latest or pinned |

### Fonts

| Module | Description | Options |
|--------|-------------|---------|
| `nerdfonts` | Nerd Fonts for terminal icons and glyphs | JetBrainsMono, FiraCode, Hack, CascadiaCode, UbuntuMono, SourceCodePro |

### Shell Enhancements

| Module | Description | Features |
|--------|-------------|----------|
| `zsh` | Z Shell with Oh My Zsh | Plugins, themes, completions |
| `starship` | Cross-shell prompt | Customizable, fast, minimal config |

### Editors

| Module | Description | Configuration |
|--------|-------------|---------------|
| `neovim` | Modern Vim-based editor | Lua-based config, LSP support |
| `vim` | Classic Vim editor | Enhanced vimrc with sensible defaults |

### Utilities

| Module | Description | Replaces |
|--------|-------------|----------|
| `fzf` | Fuzzy finder for command-line | - |
| `ripgrep` | Fast regex-based search | grep |
| `bat` | Cat clone with syntax highlighting | cat |
| `htop` | Interactive process viewer | top |
| `lazygit` | Terminal UI for git | - |
| `eza` | Modern ls replacement | ls |
| `zoxide` | Smarter cd command | cd |
| `fd` | Fast find alternative | find |
| `fastfetch` | System information display | neofetch |

---

## Usage

### Interactive Mode

Launch the interactive menu:

```bash
./install.sh
```

The menu allows you to:
- Select tool bundles (essentials, development, all)
- Choose individual modules
- Configure installation options

### Command-line Options

```bash
./install.sh [OPTIONS]

Options:
  -h, --help              Show help message
  -a, --all               Install all modules
  -m, --modules LIST      Install specific modules (comma-separated)
  -u, --update            Update existing installation
  -l, --list              List available modules
  -y, --yes               Skip confirmation prompts
  -v, --verbose           Verbose output
  -d, --debug             Debug output
  --prefix PATH           Installation prefix (default: ~/.local)
  --dry-run               Show what would be done without making changes
  --uninstall MODULE      Uninstall a specific module
  --status                Show installation status of all modules
```

### Installation Examples

```bash
# Install shell enhancement bundle
./install.sh -m zsh,starship,fzf,zoxide -y

# Install development tools
./install.sh -m neovim,tmux,lazygit,ripgrep -y

# Install with custom prefix
./install.sh --prefix /opt/mytools -m tmux

# Dry run to see what would be installed
./install.sh --dry-run -a

# Update all installed modules
./install.sh --update

# Check status of installed modules
./install.sh --status
```

### Module Bundles

| Bundle | Modules Included |
|--------|------------------|
| `essentials` | tmux, fzf, ripgrep, bat |
| `shell` | zsh, starship, zoxide |
| `development` | neovim, lazygit, fd |
| `all` | All available modules |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LABRAT_PREFIX` | `~/.local` | Installation prefix for binaries |
| `LABRAT_CONFIG_DIR` | `~/.config` | Configuration directory |
| `LABRAT_DATA_DIR` | `~/.local/share/labrat` | LabRat data directory |
| `LABRAT_CACHE_DIR` | `~/.cache/labrat` | Cache for downloads |
| `LABRAT_REPO` | GitHub URL | Repository to clone from |
| `LABRAT_BRANCH` | `main` | Git branch to use |
| `LABRAT_VERBOSE` | `0` | Enable verbose output (1 to enable) |
| `LABRAT_DEBUG` | `0` | Enable debug output (1 to enable) |
| `SKIP_CONFIRMATION` | `false` | Skip all confirmation prompts |

### Settings File

Create `~/.config/labrat/settings.yaml` for persistent configuration:

```yaml
# Installation paths
prefix: ~/.local
config_dir: ~/.config

# Module-specific settings
modules:
  tmux:
    prefix_key: C-a          # Change prefix from C-b to C-a
    theme: catppuccin-mocha  # Default theme
    mouse: true              # Enable mouse support
  neovim:
    colorscheme: catppuccin-mocha
    line_numbers: relative
  starship:
    show_hostname: true
    show_username: true
  fastfetch:
    startup: false           # Run on shell login

# Version pinning
versions:
  neovim: "0.9.5"           # Pin to specific version
  tmux: latest              # Always use latest
  fzf: ">=0.44.0"           # Minimum version constraint

# Repository configuration (for enterprise/internal use)
repositories:
  artifactory:
    enabled: false
    base_url: https://artifactory.company.com
    repo_key: tools-generic-local
```

### Configuration Precedence

Configuration is loaded in the following order (later overrides earlier):

1. Built-in defaults
2. `~/.config/labrat/settings.yaml`
3. Environment variables
4. Command-line arguments

---

## tmux Configuration

The tmux module provides a production-ready configuration with extensive customization options.

### Default Key Bindings

| Binding | Action |
|---------|--------|
| `Ctrl+b` | Prefix key (configurable) |
| `Prefix + \|` | Split pane horizontally |
| `Prefix + -` | Split pane vertically |
| `Prefix + h/j/k/l` | Navigate panes (vim-style) |
| `Prefix + H/J/K/L` | Resize panes |
| `Prefix + z` | Zoom/unzoom current pane |
| `Prefix + x` | Kill current pane |
| `Prefix + c` | Create new window |
| `Prefix + n/p` | Next/previous window |
| `Alt + 1-9` | Switch to window N directly |
| `Alt + g` | Toggle scratchpad popup |
| `Prefix + [` | Enter copy mode |
| `Prefix + I` | Install TPM plugins |
| `Prefix + U` | Update TPM plugins |
| `Prefix + r` | Reload tmux configuration |

### Available Themes

| Theme | Description |
|-------|-------------|
| `catppuccin-mocha` | Dark pastel theme (default) |
| `catppuccin-latte` | Light pastel theme |
| `dracula` | Purple and pink dark theme |
| `nord` | Arctic blue theme |
| `tokyo-night` | VS Code inspired dark theme |
| `gruvbox` | Retro warm colors |
| `onedark` | Atom editor inspired theme |
| `minimal` | Clean theme without icons |

### Theme Management

```bash
# List all available themes
tmux-theme --list

# Switch to a different theme (persists across sessions)
tmux-theme dracula

# Preview a theme without saving
tmux-theme --preview nord

# Toggle icon display on/off
tmux-theme --icons off

# Reset to default theme
tmux-theme catppuccin-mocha
```

### Included Plugins

The following plugins are installed via TPM (Tmux Plugin Manager):

- **tmux-sensible** - Sensible default settings
- **tmux-resurrect** - Save and restore sessions
- **tmux-continuum** - Automatic session saving
- **tmux-yank** - Clipboard integration
- **tmux-pain-control** - Pane navigation bindings
- **tmux-prefix-highlight** - Show when prefix is active

### Mouse Support

Mouse support is enabled by default:
- Click to select panes
- Drag to resize panes
- Scroll to navigate history
- Right-click for context menu (terminal dependent)

---

## fastfetch Configuration

fastfetch displays system information with a custom LabRat logo.

### Configuration Files

- `~/.config/fastfetch/config.jsonc` - Full configuration with all modules
- `~/.config/fastfetch/config-minimal.jsonc` - Minimal configuration for quick display

### Available Logos

- `logo-knife-rat.txt` - Default logo (rat with knife)
- `labrat-logo.txt` - Original circular design
- `logo-option1.txt` through `logo-option5.txt` - Alternative designs

### Custom Modules

The configuration includes custom command modules for:

- ROCm version detection (AMD GPU)
- AMDGPU driver status
- Package status checking (customizable list)
- Language version checks (Python, Node, Go, Rust)
- Container tool status (Docker, Podman, kubectl)

### Changing the Logo

Edit `~/.config/fastfetch/config.jsonc`:

```json
"logo": {
    "source": "~/.config/fastfetch/labrat-logo.txt",
    "type": "file"
}
```

---

## Directory Structure

After installation, LabRat creates the following directory structure:

```
~/.labrat/                  # LabRat installation directory
    install.sh              # Main installer
    labrat_bootstrap.sh     # Bootstrap script
    Makefile                # Development utilities
    lib/                    # Library functions
        colors.sh           # Color definitions
        common.sh           # Common utilities
        package_manager.sh  # Package manager abstraction
    modules/                # Module installers
        editors/
        fonts/
        shell/
        terminal/
        utils/
    configs/                # Default configurations
        fastfetch/
        tmux/
    bin/                    # Helper scripts
    tests/                  # Test suite

~/.local/                   # User-local installation (default prefix)
    bin/                    # Installed binaries
        nvim
        fzf
        lazygit
        tmux-theme
        ...
    share/
        labrat/
            installed/      # Module installation markers
            backups/        # Configuration backups

~/.config/                  # User configuration
    nvim/                   # Neovim configuration
    starship.toml           # Starship prompt config
    htop/                   # htop configuration
    lazygit/                # lazygit configuration
    fastfetch/              # fastfetch configuration
    labrat/                 # LabRat settings
        settings.yaml
```

---

## Supported Distributions

### Fully Tested

| Distribution | Versions | Package Manager |
|--------------|----------|-----------------|
| Ubuntu | 20.04, 22.04, 24.04 | apt |
| Debian | 11, 12 | apt |
| CentOS | 7, 8, Stream 9 | yum/dnf |
| RHEL | 7, 8, 9 | yum/dnf |
| Fedora | 38, 39, 40 | dnf |

### Experimental Support

| Distribution | Notes |
|--------------|-------|
| Alpine Linux | apk package manager |
| Arch Linux | pacman package manager |
| openSUSE | zypper package manager |
| macOS | Homebrew package manager |

---

## Troubleshooting

### Common Issues

**Problem: Command not found after installation**

Solution: Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Add this line to your `~/.bashrc` or `~/.zshrc`.

**Problem: tmux plugins not loading**

Solution: Install plugins manually:

1. Open tmux
2. Press `Prefix + I` (capital I)
3. Wait for plugins to install

**Problem: Nerd Font icons showing as boxes or question marks**

Solution: Install a Nerd Font on your local machine (not the server):

1. Download from https://www.nerdfonts.com/
2. Install on your local operating system
3. Configure your terminal emulator to use the font

**Problem: Permission denied errors**

Solution: Check directory permissions:

```bash
chmod -R u+rwX ~/.local ~/.config/labrat ~/.cache/labrat
```

**Problem: GitHub API rate limiting**

Solution: Wait or authenticate:

```bash
# Check rate limit status
curl -s https://api.github.com/rate_limit | jq .rate

# Authenticate (optional, increases limit)
export GITHUB_TOKEN="your_token_here"
```

### Getting Help

1. Check the verbose output: `./install.sh -v -m <module>`
2. Enable debug mode: `./install.sh -d -m <module>`
3. Check logs in `~/.cache/labrat/logs/`
4. Open an issue on GitHub: https://github.com/amd-marmoody/Labrat/issues

---

## Development

### Running Tests

```bash
# Run all tests
make test

# Test on Ubuntu (Docker)
make test-ubuntu

# Test on CentOS (Docker)
make test-centos
```

### Building Documentation

```bash
make docs
```

### Code Style

- Use ShellCheck for linting: `shellcheck install.sh lib/*.sh modules/**/*.sh`
- Follow Google Shell Style Guide
- Use 4-space indentation
- Include function documentation headers

---

## Contributing

Contributions are welcome. Please follow these guidelines:

### Adding a New Module

1. Create a new file in `modules/<category>/<tool>.sh`
2. Implement the required functions:
   - `install_<tool>()` - Main installation function
   - `uninstall_<tool>()` - Cleanup function (optional)
3. Add module to the registry in `install.sh`
4. Test on Ubuntu and CentOS
5. Submit a pull request

### Module Template

```bash
#!/usr/bin/env bash
#
# LabRat Module: <tool>
# <Description of the tool>
#

# Module metadata
TOOL_VERSION="latest"
TOOL_GITHUB_REPO="owner/repo"

install_<tool>() {
    log_step "Installing <tool>..."
    
    # Check if already installed
    if command_exists <tool>; then
        local version=$(<tool> --version | head -1)
        log_info "<tool> already installed: $version"
        return 0
    fi
    
    # Installation logic
    pkg_install <tool>
    
    # Deploy configuration
    deploy_<tool>_config
    
    # Get installed version
    local version=$(<tool> --version | head -1)
    
    # Mark as installed
    mark_module_installed "<tool>" "$version"
    
    log_success "<tool> installed successfully!"
}

deploy_<tool>_config() {
    log_step "Deploying <tool> configuration..."
    # Configuration deployment logic
}

uninstall_<tool>() {
    log_step "Uninstalling <tool>..."
    # Cleanup logic
    rm -f "${LABRAT_DATA_DIR}/installed/<tool>"
    log_success "<tool> uninstalled"
}
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run tests: `make test`
5. Commit with descriptive messages
6. Push to your fork
7. Open a pull request

---

## License

This project is open source. See the repository for license details.

---

## Acknowledgments

This project builds upon the work of many excellent open source projects:

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Neovim plugin manager
- [Catppuccin](https://github.com/catppuccin) - Color scheme
- [Starship](https://starship.rs/) - Cross-shell prompt
- [fastfetch](https://github.com/fastfetch-cli/fastfetch) - System information tool
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- [ripgrep](https://github.com/BurntSushi/ripgrep) - Fast grep replacement
- [bat](https://github.com/sharkdp/bat) - Cat with syntax highlighting
- [eza](https://github.com/eza-community/eza) - Modern ls replacement
- [zoxide](https://github.com/ajeetdsouza/zoxide) - Smarter cd command
- [lazygit](https://github.com/jesseduffield/lazygit) - Terminal UI for git
- [Nerd Fonts](https://www.nerdfonts.com/) - Patched fonts with icons

---

## Links

- **Repository**: https://github.com/amd-marmoody/Labrat
- **Issues**: https://github.com/amd-marmoody/Labrat/issues
- **Pull Requests**: https://github.com/amd-marmoody/Labrat/pulls

---

*LabRat - Because every lab needs a trusty rat.*
