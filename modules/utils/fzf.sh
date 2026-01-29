#!/usr/bin/env bash
#
# LabRat Module: fzf
# Fuzzy finder for command-line
#

# Module metadata
FZF_REPO="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"
FZF_CONFIG_DIR="$HOME/.config/labrat/fzf"
FZF_THEME_DIR="$FZF_CONFIG_DIR/themes"

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
    
    # Run fzf install script (binary only, no shell integration - we handle that)
    log_step "Running fzf installer..."
    "$FZF_DIR/install" --bin
    
    # Install binary to local bin
    if [[ -f "$FZF_DIR/bin/fzf" ]]; then
        cp "$FZF_DIR/bin/fzf" "$LABRAT_BIN_DIR/"
        cp "$FZF_DIR/bin/fzf-tmux" "$LABRAT_BIN_DIR/" 2>/dev/null || true
    fi
    
    # Get version
    installed_version=$("$LABRAT_BIN_DIR/fzf" --version | awk '{print $1}')
    log_info "fzf version: $installed_version"
    
    # Deploy configuration and themes
    setup_fzf_config
    
    # Setup shell integration
    setup_fzf_integration
    
    # Mark as installed
    mark_module_installed "fzf" "$installed_version"
    
    log_success "fzf installed and configured!"
}

# ============================================================================
# Configuration Setup
# ============================================================================

setup_fzf_config() {
    log_step "Setting up fzf configuration..."
    
    # Create config directories
    mkdir -p "$FZF_CONFIG_DIR"
    mkdir -p "$FZF_THEME_DIR"
    mkdir -p "$HOME/.local/state/labrat"
    
    # Copy main config file
    cp "${LABRAT_ROOT}/configs/fzf/config" "$FZF_CONFIG_DIR/config"
    
    # Copy all theme files
    for theme_file in "${LABRAT_ROOT}/configs/fzf/themes/"*.sh; do
        if [[ -f "$theme_file" ]]; then
            cp "$theme_file" "$FZF_THEME_DIR/"
        fi
    done
    
    # Set default theme if not already set
    local state_file="$HOME/.local/state/labrat/fzf_theme"
    local current_theme="catppuccin-mocha"
    
    if [[ -f "$state_file" ]]; then
        current_theme=$(cat "$state_file")
    else
        echo "$current_theme" > "$state_file"
    fi
    
    # Create symlink to current theme
    local current_theme_file="$FZF_CONFIG_DIR/current-theme.sh"
    rm -f "$current_theme_file"
    ln -sf "$FZF_THEME_DIR/${current_theme}.sh" "$current_theme_file"
    
    log_success "fzf configuration deployed to $FZF_CONFIG_DIR"
}

# ============================================================================
# Shell Integration (using official fzf --bash/--zsh)
# ============================================================================

setup_fzf_integration() {
    log_step "Setting up fzf shell integration..."
    
    # Create bash integration file that uses official fzf --bash
    local fzf_config="$HOME/.fzf.bash"
    cat > "$fzf_config" << 'FZF_BASH'
# fzf configuration (managed by LabRat)
# Uses official fzf shell integration with customizations

# Add fzf to PATH if needed
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Source theme first (sets FZF_DEFAULT_OPTS colors)
FZF_LABRAT_THEME="${HOME}/.config/labrat/fzf/current-theme.sh"
if [[ -f "$FZF_LABRAT_THEME" ]]; then
    source "$FZF_LABRAT_THEME"
fi

# Point to config file for additional options
export FZF_DEFAULT_OPTS_FILE="${HOME}/.config/labrat/fzf/config"

# Use fd if available for file finding
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview with bat for Ctrl+T
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right:50%:wrap'"
fi

# Preview with tree for Alt+C
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"

# Use official fzf shell integration
# Disable Ctrl+R (atuin owns it) by setting FZF_CTRL_R_COMMAND to empty
if command -v fzf &> /dev/null; then
    FZF_CTRL_R_COMMAND= eval "$(fzf --bash)"
fi

# Add Alt+R as alternative fzf history search (for when atuin is not wanted)
__fzf_history_alt__() {
    local output opts
    opts="--height 40% --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort +m --read0"
    output=$(
        builtin fc -lnr -2147483648 |
        last_hist=$(HISTTIMEFORMAT='' builtin history 1) perl -n -l0 -e 'BEGIN { getc; $/ = "\n\t"; $LAST = shift @ARGV } s/^[ *]//; print if !$seen{$_}++ && $_ ne $LAST' "$last_hist" |
        FZF_DEFAULT_OPTS="$opts" fzf --query "$READLINE_LINE"
    ) || return
    READLINE_LINE=${output#*$'\t'}
    if [[ -z "$READLINE_POINT" ]]; then
        echo "$READLINE_LINE"
    else
        READLINE_POINT=0x7fffffff
    fi
}
bind -x '"\er": __fzf_history_alt__'
FZF_BASH

    # Create zsh integration file
    local fzf_zsh="$HOME/.fzf.zsh"
    cat > "$fzf_zsh" << 'FZF_ZSH'
# fzf configuration (managed by LabRat)
# Uses official fzf shell integration with customizations

# Add fzf to PATH if needed
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Source theme first (sets FZF_DEFAULT_OPTS colors)
FZF_LABRAT_THEME="${HOME}/.config/labrat/fzf/current-theme.sh"
if [[ -f "$FZF_LABRAT_THEME" ]]; then
    source "$FZF_LABRAT_THEME"
fi

# Point to config file for additional options
export FZF_DEFAULT_OPTS_FILE="${HOME}/.config/labrat/fzf/config"

# Use fd if available for file finding
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview with bat for Ctrl+T
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}' --preview-window 'right:50%:wrap'"
fi

# Preview with tree for Alt+C
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -100'"

# Use official fzf shell integration
# Disable Ctrl+R (atuin owns it) by setting FZF_CTRL_R_COMMAND to empty
if command -v fzf &> /dev/null; then
    FZF_CTRL_R_COMMAND= source <(fzf --zsh)
fi

# Add Alt+R as alternative fzf history search (for when atuin is not wanted)
fzf-history-widget-alt() {
    local selected num
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
    selected="$(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
        FZF_DEFAULT_OPTS="--height 40% ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort --query=${(qqq)LBUFFER} +m" fzf)"
    local ret=$?
    if [ -n "$selected" ]; then
        num=$(awk '{print $1}' <<< "$selected")
        if [[ "$num" =~ ^[1-9][0-9]*$ ]]; then
            zle vi-fetch-history -n $num
        else
            BUFFER="$selected"
        fi
    fi
    zle reset-prompt
    return $ret
}
zle -N fzf-history-widget-alt
bindkey '\er' fzf-history-widget-alt
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
    
    # Remove config directory
    rm -rf "$FZF_CONFIG_DIR"
    
    # Remove state file
    rm -f "$HOME/.local/state/labrat/fzf_theme"
    
    # Remove from PATH
    rm -f "$LABRAT_BIN_DIR/fzf"
    rm -f "$LABRAT_BIN_DIR/fzf-tmux"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/fzf"
    
    log_success "fzf removed"
}
