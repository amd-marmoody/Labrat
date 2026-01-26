#!/usr/bin/env bash
#
# LabRat Module: atuin
# Magical shell history - sync, search, and backup
# https://github.com/atuinsh/atuin
#

ATUIN_GITHUB_REPO="atuinsh/atuin"

install_atuin() {
    log_step "Installing atuin..."
    
    if command_exists atuin; then
        local installed_version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "atuin already installed (v${installed_version})"
        if ! confirm "Reinstall/update atuin?" "n"; then
            setup_atuin_integration
            mark_module_installed "atuin" "${installed_version}"
            return 0
        fi
    fi
    
    install_atuin_from_github
    
    if ! command_exists atuin; then
        log_error "atuin installation failed"
        return 1
    fi
    
    local version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    
    # Setup shell integration using new API
    setup_atuin_integration
    
    mark_module_installed "atuin" "${version:-unknown}"
    
    log_success "atuin installed successfully!"
    log_info "Run ${BOLD}atuin import auto${NC} to import existing history"
    log_info "Press ${BOLD}Ctrl+R${NC} for interactive search"
    log_info "Helper functions: ${BOLD}atuin-enable${NC}, ${BOLD}atuin-disable${NC}"
}

install_atuin_from_github() {
    log_step "Installing atuin from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$ATUIN_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest atuin version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${ATUIN_GITHUB_REPO}/releases/download/${latest_version}/atuin-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/atuin.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/atuin"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading atuin"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        find "$extract_dir" -name "atuin" -type f -executable -exec cp {} "$LABRAT_BIN_DIR/" \;
        chmod +x "$LABRAT_BIN_DIR/atuin"
        rm -rf "$temp_file" "$extract_dir"
        log_success "atuin installed from GitHub"
    else
        log_error "Failed to download atuin"
        return 1
    fi
}

# ============================================================================
# Shell Integration (using new modular API)
# ============================================================================

setup_atuin_integration() {
    log_step "Setting up atuin shell integration..."
    
    # Define helper functions for bash
    local bash_functions='
# Disable atuin history (use default Ctrl+R)
atuin-disable() {
    # Restore default bash history search
    bind '"'"'"\C-r": reverse-search-history'"'"'
    echo "atuin disabled. Using default Ctrl+R history search."
}

# Re-enable atuin
atuin-enable() {
    if command -v atuin &>/dev/null; then
        eval "$(atuin init bash)"
        echo "atuin enabled!"
    else
        echo "Error: atuin not found"
        return 1
    fi
}

# Show atuin stats
atuin-stats() {
    if command -v atuin &>/dev/null; then
        atuin stats
    fi
}

# Search history with atuin
atuin-search() {
    if command -v atuin &>/dev/null; then
        atuin search "$@"
    fi
}'

    # Define helper functions for zsh
    local zsh_functions='
# Disable atuin history
atuin-disable() {
    # Restore default zsh history search
    bindkey "^R" history-incremental-search-backward
    echo "atuin disabled. Using default Ctrl+R history search."
}

# Re-enable atuin
atuin-enable() {
    if (( $+commands[atuin] )); then
        eval "$(atuin init zsh)"
        echo "atuin enabled!"
    else
        echo "Error: atuin not found"
        return 1
    fi
}

# Show atuin stats
atuin-stats() {
    if (( $+commands[atuin] )); then
        atuin stats
    fi
}

# Search history with atuin
atuin-search() {
    if (( $+commands[atuin] )); then
        atuin search "$@"
    fi
}'

    # Define helper functions for fish
    local fish_functions='
# Disable atuin
function atuin-disable
    # Remove atuin keybinding
    bind -e \cr
    echo "atuin disabled."
end

# Re-enable atuin
function atuin-enable
    if command -v atuin &>/dev/null
        atuin init fish | source
        echo "atuin enabled!"
    else
        echo "Error: atuin not found"
        return 1
    end
end

# Show atuin stats
function atuin-stats
    if command -v atuin &>/dev/null
        atuin stats
    end
end'

    # Register shell integration using new modular API
    register_shell_module "atuin" \
        --init-bash 'eval "$(atuin init bash)"' \
        --init-zsh 'eval "$(atuin init zsh)"' \
        --init-fish 'atuin init fish | source' \
        --functions-bash "$bash_functions" \
        --functions-zsh "$zsh_functions" \
        --functions-fish "$fish_functions" \
        --description "Shell history with sync and search"
    
    log_success "atuin shell integration configured"
}

uninstall_atuin() {
    log_step "Uninstalling atuin..."
    
    # Remove binary
    rm -f "$LABRAT_BIN_DIR/atuin"
    
    # Remove shell integration
    unregister_shell_module "atuin"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/atuin"
    
    # Optional: remove atuin data
    if [[ -d "$HOME/.local/share/atuin" ]]; then
        if confirm "Remove atuin data (~/.local/share/atuin)? This includes your synced history." "n"; then
            rm -rf "$HOME/.local/share/atuin"
            log_info "Removed atuin data"
        else
            log_info "Kept atuin data at ~/.local/share/atuin"
        fi
    fi
    
    log_success "atuin uninstalled"
    log_info "Your shell history data was preserved unless you chose to remove it"
}
