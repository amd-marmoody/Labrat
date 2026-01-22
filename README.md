# 🐀 LabRat

> Your trusty environment for every test cage

**LabRat** is a modular, portable environment configurator designed for developers and testers who frequently SSH into remote servers. With a single command, you can install and configure your preferred tools, shell enhancements, and development environment.

## ✨ Features

- **One-liner deployment** - Bootstrap with `curl` or `wget`
- **Modular architecture** - Install only what you need
- **User-local installation** - No root required for most tools
- **Cross-distro support** - Ubuntu, CentOS, RHEL, and more
- **Version pinning** - Lock specific tool versions
- **Portable configs** - Consistent environment across all servers
- **Interactive & non-interactive modes** - Perfect for automation

## 🚀 Quick Start

### One-liner Installation

```bash
# Full installation with interactive menu
curl -fsSL https://raw.githubusercontent.com/YOUR_USER/labrat/main/labrat_bootstrap.sh | bash

# Or with wget
wget -qO- https://raw.githubusercontent.com/YOUR_USER/labrat/main/labrat_bootstrap.sh | bash
```

### Non-interactive Installation

```bash
# Install specific modules
curl -fsSL ... | bash -s -- --modules tmux,fzf,neovim --yes

# Install everything
curl -fsSL ... | bash -s -- --all --yes
```

## 📦 Available Modules

### Terminal
| Module | Description |
|--------|-------------|
| `tmux` | Terminal multiplexer with 8 themes, plugins, mouse support, scratchpad |

### Fonts
| Module | Description |
|--------|-------------|
| `nerdfonts` | Install Nerd Fonts (JetBrainsMono, FiraCode, Hack, etc.) for icons |

### Shell Enhancements
| Module | Description |
|--------|-------------|
| `zsh` | Z Shell with Oh My Zsh, plugins, and sensible defaults |
| `fish` | Friendly interactive shell |
| `starship` | Cross-shell prompt with rich customization |

### Editors
| Module | Description |
|--------|-------------|
| `neovim` | Hyperextensible Vim-based editor with modern Lua config |
| `vim` | Classic Vim with enhanced configuration |

### Utilities
| Module | Description |
|--------|-------------|
| `fzf` | Fuzzy finder for command-line |
| `ripgrep` | Fast regex-based search (rg) |
| `bat` | Cat clone with syntax highlighting |
| `htop` | Interactive process viewer |
| `lazygit` | Terminal UI for git |
| `eza` | Modern replacement for ls |
| `zoxide` | Smarter cd command |
| `fd` | Fast find alternative |

## 💻 Usage

### Interactive Mode

```bash
./install.sh
```

This launches an interactive menu where you can select tool bundles or individual modules.

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
  --dry-run               Show what would be done
```

### Examples

```bash
# Install shell enhancement bundle
./install.sh -m zsh,starship,fzf,zoxide -y

# Install development tools
./install.sh -m neovim,tmux,lazygit,ripgrep -y

# Update all installed modules
./install.sh --update

# Install to custom prefix
./install.sh --prefix /opt/mytools -m tmux
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LABRAT_PREFIX` | `~/.local` | Installation prefix for binaries |
| `LABRAT_CONFIG_DIR` | `~/.config` | Configuration directory |
| `LABRAT_REPO` | GitHub URL | Repository to clone from |
| `LABRAT_BRANCH` | `main` | Git branch to use |
| `LABRAT_VERBOSE` | `0` | Enable verbose output |
| `LABRAT_DEBUG` | `0` | Enable debug output |

### Settings File

Create `~/.config/labrat/settings.yaml` for persistent configuration:

```yaml
# Installation settings
prefix: ~/.local
config_dir: ~/.config

# Module settings
modules:
  tmux:
    prefix_key: C-a
    theme: catppuccin
  neovim:
    colorscheme: catppuccin-mocha
  starship:
    show_hostname: true

# Version pinning
versions:
  neovim: "0.9.5"
  tmux: latest
  fzf: ">=0.44.0"

# Artifactory integration (for internal tools)
repositories:
  artifactory:
    enabled: false
    base_url: https://artifactory.company.com
    repo_key: tools-generic-local
```

## 🔧 tmux Configuration Highlights

The tmux module includes a production-ready configuration with:

- **Prefix**: `Ctrl+b` (configurable)
- **Mouse support**: Scrolling, pane selection, resizing
- **Vi-style navigation**: `hjkl` for pane movement
- **Scratchpad**: `Alt+g` for quick popup terminal
- **Session persistence**: Auto-save/restore with tmux-resurrect
- **8 Color Themes**: Switch themes on the fly!
- **Plugins** (via TPM):
  - tmux-sensible, tmux-resurrect, tmux-continuum
  - tmux-yank, tmux-pain-control, tmux-prefix-highlight
  - Optional: tmux-logging, tmux-copycat, tmux-cpu, tmux-online-status

### 🎨 Available Themes

| Theme | Description |
|-------|-------------|
| `catppuccin-mocha` | Dark pastel (default) |
| `catppuccin-latte` | Light pastel |
| `dracula` | Purple/pink dark |
| `nord` | Arctic blue |
| `tokyo-night` | VS Code inspired |
| `gruvbox` | Retro warm colors |
| `onedark` | Atom editor theme |
| `minimal` | Clean, no icons |

### Theme Switching

```bash
# List available themes
tmux-theme --list

# Switch theme (instant, persists)
tmux-theme dracula

# Preview without saving
tmux-theme --preview nord

# Toggle icons on/off
tmux-theme --icons off
```

### Key Bindings

| Binding | Action |
|---------|--------|
| `Prefix + \|` | Split pane horizontally |
| `Prefix + -` | Split pane vertically |
| `Prefix + hjkl` | Navigate panes |
| `Prefix + z` | Zoom/unzoom pane |
| `Alt + 1-9` | Switch to window N |
| `Alt + g` | Scratchpad popup |
| `Prefix + I` | Install TPM plugins |
| `Prefix + r` | Reload config |

## 📁 Directory Structure

```
~/.local/
├── bin/                    # Installed binaries
│   ├── nvim
│   ├── fzf
│   ├── lazygit
│   └── ...
└── share/
    └── labrat/
        ├── installed/      # Module installation markers
        └── backups/        # Config backups

~/.config/
├── nvim/                   # Neovim config
├── starship.toml           # Starship prompt config
├── htop/                   # htop config
├── lazygit/                # lazygit config
└── labrat/
    └── settings.yaml       # LabRat settings

~/.labrat/                  # LabRat installation
├── install.sh
├── lib/
├── modules/
└── configs/
```

## 🔄 Updating

```bash
# Update LabRat itself
cd ~/.labrat && git pull

# Update all installed modules
./install.sh --update

# Update specific modules
./install.sh -m tmux,neovim
```

## 🗑️ Uninstalling

```bash
# Remove LabRat and all configs
rm -rf ~/.labrat ~/.local/share/labrat

# Remove individual tool configs (optional)
rm -rf ~/.config/nvim ~/.tmux.conf ~/.config/starship.toml
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your module in `modules/<category>/<tool>.sh`
4. Test on Ubuntu and CentOS
5. Submit a pull request

### Module Template

```bash
#!/usr/bin/env bash
#
# LabRat Module: <tool>
# Description of the tool
#

install_<tool>() {
    log_step "Installing <tool>..."
    
    # Installation logic
    pkg_install <tool>
    
    # Get version
    local version=$(<tool> --version | ...)
    
    # Deploy config
    deploy_<tool>_config
    
    # Mark installed
    mark_module_installed "<tool>" "$version"
    
    log_success "<tool> installed!"
}

uninstall_<tool>() {
    log_step "Uninstalling <tool>..."
    # Cleanup logic
}
```


## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [TPM](https://github.com/tmux-plugins/tpm) - Tmux Plugin Manager
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Neovim plugin manager
- [Catppuccin](https://github.com/catppuccin) - Color scheme
- [Starship](https://starship.rs/) - Cross-shell prompt


---
