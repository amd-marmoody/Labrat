#!/usr/bin/env bash
#
# LabRat Module: zsh
# Z Shell with Oh My Zsh framework and sensible defaults
#

# Module metadata
ZSH_OMZ_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
ZSH_OMZ_DIR="$HOME/.oh-my-zsh"

# ============================================================================
# Installation
# ============================================================================

install_zsh() {
    log_step "Installing zsh..."
    
    # Install zsh via package manager
    if ! command_exists zsh; then
        pkg_install zsh
    else
        log_info "zsh already installed"
    fi
    
    # Get installed version
    local installed_version
    installed_version=$(zsh --version | awk '{print $2}')
    log_info "zsh version: $installed_version"
    
    # Install Oh My Zsh
    install_oh_my_zsh
    
    # Install useful plugins
    install_zsh_plugins
    
    # Deploy configuration
    deploy_zsh_config
    
    # Mark as installed
    mark_module_installed "zsh" "$installed_version"
    
    log_success "zsh installed and configured!"
    
    # Offer to change default shell (only in interactive mode)
    if [[ "$SHELL" != *"zsh"* ]]; then
        # Skip in non-interactive mode since chsh requires password input
        if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]] && [[ -t 0 ]]; then
            if confirm "Set zsh as your default shell?" "y"; then
                change_default_shell
            fi
        else
            log_info "Run ${BOLD}chsh -s \$(which zsh)${NC} to set zsh as your default shell"
        fi
    fi
}

# ============================================================================
# Oh My Zsh Installation
# ============================================================================

install_oh_my_zsh() {
    log_step "Installing Oh My Zsh..."
    
    if [[ -d "$ZSH_OMZ_DIR" ]]; then
        log_info "Oh My Zsh already installed, updating..."
        (cd "$ZSH_OMZ_DIR" && git pull --quiet)
    else
        # Clone Oh My Zsh
        git clone --depth=1 "$ZSH_OMZ_REPO" "$ZSH_OMZ_DIR" --quiet
    fi
    
    log_success "Oh My Zsh installed at $ZSH_OMZ_DIR"
}

# ============================================================================
# Plugin Installation
# ============================================================================

install_zsh_plugins() {
    local plugins_dir="${ZSH_OMZ_DIR}/custom/plugins"
    
    log_step "Installing zsh plugins..."
    
    # zsh-autosuggestions
    local autosuggestions_dir="${plugins_dir}/zsh-autosuggestions"
    if [[ ! -d "$autosuggestions_dir" ]]; then
        git_clone_or_update \
            "https://github.com/zsh-users/zsh-autosuggestions.git" \
            "$autosuggestions_dir" \
            "master"
    fi
    
    # zsh-syntax-highlighting
    local syntax_dir="${plugins_dir}/zsh-syntax-highlighting"
    if [[ ! -d "$syntax_dir" ]]; then
        git_clone_or_update \
            "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
            "$syntax_dir" \
            "master"
    fi
    
    # zsh-completions
    local completions_dir="${plugins_dir}/zsh-completions"
    if [[ ! -d "$completions_dir" ]]; then
        git_clone_or_update \
            "https://github.com/zsh-users/zsh-completions.git" \
            "$completions_dir" \
            "master"
    fi
    
    # fast-syntax-highlighting (alternative to zsh-syntax-highlighting)
    local fast_syntax_dir="${plugins_dir}/fast-syntax-highlighting"
    if [[ ! -d "$fast_syntax_dir" ]]; then
        git_clone_or_update \
            "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
            "$fast_syntax_dir" \
            "master"
    fi
    
    log_success "zsh plugins installed"
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_zsh_config() {
    local config_source="${LABRAT_CONFIGS_DIR}/zsh/.zshrc"
    local config_target="$HOME/.zshrc"
    
    log_step "Deploying zsh configuration..."
    
    # Backup existing config
    if [[ -f "$config_target" ]] && [[ ! -L "$config_target" ]]; then
        backup_file "$config_target"
    fi
    
    # Create symlink or copy config
    if [[ -f "$config_source" ]]; then
        safe_symlink "$config_source" "$config_target"
        log_success "zsh config deployed"
    else
        log_warn "Config source not found, creating default config"
        create_default_zsh_config "$config_target"
    fi
}

create_default_zsh_config() {
    local config_file="$1"
    
    cat > "$config_file" << 'ZSHRC'
# ============================================================================
# LabRat Zsh Configuration
# Your trusty environment for every test cage 🐀
# ============================================================================

# ----------------------------------------------------------------------------
# Oh My Zsh Configuration
# ----------------------------------------------------------------------------

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme (set to empty if using starship)
# ZSH_THEME="robbyrussell"
ZSH_THEME=""

# Case-sensitive completion
CASE_SENSITIVE="false"

# Hyphen-insensitive completion
HYPHEN_INSENSITIVE="true"

# Auto-update behavior
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7

# Disable auto-setting terminal title
DISABLE_AUTO_TITLE="false"

# Enable command auto-correction
ENABLE_CORRECTION="false"

# Display dots while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Disable marking untracked files as dirty (faster for large repos)
DISABLE_UNTRACKED_FILES_DIRTY="true"

# History timestamp format
HIST_STAMPS="yyyy-mm-dd"

# Plugins
plugins=(
    git
    docker
    kubectl
    python
    pip
    virtualenv
    sudo
    history
    colored-man-pages
    command-not-found
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# ----------------------------------------------------------------------------
# Environment Variables
# ----------------------------------------------------------------------------

# Preferred editor
export EDITOR='nvim'
export VISUAL='nvim'

# Language
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# Less options
export LESS='-R --use-color -Dd+r$Du+b'
export LESSHISTFILE=-

# Man pages with colors
export MANPAGER="less -R --use-color -Dd+r -Du+b"

# PATH additions
export PATH="$HOME/.local/bin:$PATH"

# ----------------------------------------------------------------------------
# History Configuration
# ----------------------------------------------------------------------------

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history

setopt EXTENDED_HISTORY       # Write timestamps to history
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicates first
setopt HIST_IGNORE_DUPS       # Ignore duplicates
setopt HIST_IGNORE_SPACE      # Ignore commands starting with space
setopt HIST_VERIFY            # Show command before executing from history
setopt SHARE_HISTORY          # Share history between sessions
setopt APPEND_HISTORY         # Append to history file

# ----------------------------------------------------------------------------
# Keybindings
# ----------------------------------------------------------------------------

# Use emacs keybindings
bindkey -e

# Better history search with up/down arrows
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Ctrl+R for history search
bindkey '^R' history-incremental-search-backward

# Home/End keys
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Delete key
bindkey '^[[3~' delete-char

# Ctrl+Left/Right for word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ----------------------------------------------------------------------------
# Aliases
# ----------------------------------------------------------------------------

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# List directory contents
alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Use eza if available
if command -v eza &> /dev/null; then
    alias ls='eza --icons'
    alias ll='eza -alF --icons --git'
    alias la='eza -a --icons'
    alias lt='eza --tree --level=2 --icons'
fi

# Use bat if available
if command -v bat &> /dev/null; then
    alias cat='bat --style=plain'
    alias catp='bat'
fi

# Git shortcuts
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -n 20'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System
alias df='df -h'
alias du='du -h'
alias free='free -h'

# Tmux
alias ta='tmux attach -t'
alias tl='tmux list-sessions'
alias tn='tmux new-session -s'

# Quick edit configs
alias zshrc='${EDITOR} ~/.zshrc'
alias vimrc='${EDITOR} ~/.config/nvim/init.lua'
alias tmuxrc='${EDITOR} ~/.tmux.conf'

# Reload zsh config
alias reload='source ~/.zshrc'

# ----------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract various archive formats
extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"    ;;
            *.tar.gz)    tar xzf "$1"    ;;
            *.tar.xz)    tar xJf "$1"    ;;
            *.bz2)       bunzip2 "$1"    ;;
            *.gz)        gunzip "$1"     ;;
            *.tar)       tar xf "$1"     ;;
            *.tbz2)      tar xjf "$1"    ;;
            *.tgz)       tar xzf "$1"    ;;
            *.zip)       unzip "$1"      ;;
            *.Z)         uncompress "$1" ;;
            *.7z)        7z x "$1"       ;;
            *.rar)       unrar x "$1"    ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find process by name
psg() {
    ps aux | grep -v grep | grep -i "$1"
}

# Quick HTTP server
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# ----------------------------------------------------------------------------
# Completions
# ----------------------------------------------------------------------------

# Load completions
autoload -Uz compinit
compinit -d ~/.zcompdump

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'

# ----------------------------------------------------------------------------
# Integrations
# ----------------------------------------------------------------------------

# fzf integration
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
fi

# zoxide integration
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt (OFF by default)
# Run 'starship-on' to enable the fancy prompt
# Toggle: starship-on / starship-off

# Toggle starship prompt on/off
starship-off() { 
    export STARSHIP_DISABLE=1
    # Clear starship hooks
    precmd_functions=()
    preexec_functions=()
    PROMPT='%n@%m:%~%# '
    echo "Starship disabled."
}

starship-on() { 
    unset STARSHIP_DISABLE
    if command -v starship &> /dev/null; then
        eval "$(starship init zsh)"
        echo "Starship enabled."
    else
        echo "Starship not installed. Run: labrat install starship"
    fi
}

# ----------------------------------------------------------------------------
# Local overrides
# ----------------------------------------------------------------------------

# Source local config if exists
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
ZSHRC

    log_success "Default zsh config created"
}

# ============================================================================
# Shell Change
# ============================================================================

change_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)
    
    log_step "Changing default shell to zsh..."
    
    # Ensure zsh is in /etc/shells
    if ! grep -q "$zsh_path" /etc/shells; then
        log_info "Adding zsh to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi
    
    # Change shell
    chsh -s "$zsh_path"
    
    log_success "Default shell changed to zsh"
    log_info "Log out and back in for the change to take effect"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_zsh() {
    log_step "Uninstalling zsh configuration..."
    
    # Remove config
    if [[ -L "$HOME/.zshrc" ]]; then
        rm "$HOME/.zshrc"
    fi
    
    # Optionally remove Oh My Zsh
    if confirm "Remove Oh My Zsh and all plugins?" "n"; then
        rm -rf "$ZSH_OMZ_DIR"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/zsh"
    
    log_success "zsh configuration removed"
}
