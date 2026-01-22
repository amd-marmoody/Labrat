#!/usr/bin/env bash
#
# LabRat Module: fzf
# Fuzzy finder for command-line
#

# Module metadata
FZF_REPO="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"

# ============================================================================
# Installation
# ============================================================================

install_fzf() {
    log_step "Installing fzf..."
    
    local installed_version=""
    
    # Clone or update fzf
    if [[ -d "$FZF_DIR" ]]; then
        log_info "fzf directory exists, updating..."
        (cd "$FZF_DIR" && git pull --quiet)
    else
        git_clone_or_update "$FZF_REPO" "$FZF_DIR" "master"
    fi
    
    # Run fzf install script
    log_step "Running fzf installer..."
    "$FZF_DIR/install" --all --no-update-rc --no-bash --no-zsh --no-fish
    
    # Install binary to local bin
    if [[ -f "$FZF_DIR/bin/fzf" ]]; then
        cp "$FZF_DIR/bin/fzf" "$LABRAT_BIN_DIR/"
        cp "$FZF_DIR/bin/fzf-tmux" "$LABRAT_BIN_DIR/" 2>/dev/null || true
    fi
    
    # Get version
    installed_version=$(fzf --version | awk '{print $1}')
    log_info "fzf version: $installed_version"
    
    # Setup shell integration
    setup_fzf_integration
    
    # Mark as installed
    mark_module_installed "fzf" "$installed_version"
    
    log_success "fzf installed and configured!"
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_fzf_integration() {
    log_step "Setting up fzf shell integration..."
    
    # Create fzf config
    local fzf_config="$HOME/.fzf.bash"
    cat > "$fzf_config" << 'FZF_BASH'
# fzf configuration (added by LabRat)

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
source "$HOME/.fzf/shell/key-bindings.bash"

# Default options
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd if available for file finding
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview file content using bat
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="
        --preview 'bat --style=numbers --color=always --line-range :500 {}'
        --preview-window 'right:50%:wrap'
    "
fi
FZF_BASH

    # Create zsh version
    local fzf_zsh="$HOME/.fzf.zsh"
    cat > "$fzf_zsh" << 'FZF_ZSH'
# fzf configuration (added by LabRat)

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "$HOME/.fzf/shell/key-bindings.zsh"

# Default options
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd if available
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview with bat
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="
        --preview 'bat --style=numbers --color=always --line-range :500 {}'
        --preview-window 'right:50%:wrap'
    "
fi
FZF_ZSH

    # Add to bashrc if needed
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q '\.fzf\.bash' "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# fzf (added by LabRat)" >> "$bashrc"
        echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> "$bashrc"
    fi
    
    log_success "fzf shell integration configured"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_fzf() {
    log_step "Uninstalling fzf..."
    
    # Remove fzf directory
    if confirm "Remove fzf installation (~/.fzf)?" "y"; then
        rm -rf "$FZF_DIR"
    fi
    
    # Remove config files
    rm -f "$HOME/.fzf.bash"
    rm -f "$HOME/.fzf.zsh"
    
    # Remove from PATH
    rm -f "$LABRAT_BIN_DIR/fzf"
    rm -f "$LABRAT_BIN_DIR/fzf-tmux"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/fzf"
    
    log_success "fzf removed"
}
