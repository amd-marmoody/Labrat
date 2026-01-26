#!/usr/bin/env bash
#
# LabRat Module: zoxide
# Smarter cd command that learns your habits
#

# Module metadata
ZOXIDE_GITHUB_REPO="ajeetdsouza/zoxide"

# ============================================================================
# Installation
# ============================================================================

install_zoxide() {
    log_step "Installing zoxide..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists zoxide; then
        installed_version=$(zoxide --version | awk '{print $2}')
        log_info "zoxide already installed (version: $installed_version)"
        
        if ! confirm "Reinstall/update zoxide?" "n"; then
            setup_zoxide_integration
            mark_module_installed "zoxide" "$installed_version"
            return 0
        fi
    fi
    
    # Install zoxide binary
    install_zoxide_binary
    
    # Get version
    installed_version=$(zoxide --version | awk '{print $2}')
    log_info "zoxide version: $installed_version"
    
    # Setup shell integration using new API
    setup_zoxide_integration
    
    # Mark as installed
    mark_module_installed "zoxide" "$installed_version"
    
    log_success "zoxide installed!"
    log_info "Use 'z' command instead of 'cd' to navigate"
    log_info "Helper functions: ${BOLD}zoxide-enable${NC}, ${BOLD}zoxide-disable${NC}"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_zoxide_binary() {
    log_step "Installing zoxide from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${ZOXIDE_GITHUB_REPO}/releases/latest"
    local arch_pattern=""
    
    # Determine architecture pattern for download URL
    case "$ARCH" in
        amd64|x86_64)
            arch_pattern="x86_64-unknown-linux-musl"
            ;;
        arm64|aarch64)
            arch_pattern="aarch64-unknown-linux-musl"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Get latest version tag
    local version
    version=$(curl -fsSL "$release_url" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"\([^"]*\)"/\1/')
    
    if [[ -n "$version" ]]; then
        # Construct download URL for tarball
        local download_url="https://github.com/${ZOXIDE_GITHUB_REPO}/releases/download/${version}/zoxide-${version#v}-${arch_pattern}.tar.gz"
        log_debug "Download URL: $download_url"
    else
        log_error "Could not determine latest zoxide version"
        return 1
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/zoxide"
    ensure_dir "$extract_dir"
    
    if download_and_extract "$download_url" "$extract_dir" "Downloading zoxide"; then
        # Copy binary
        if [[ -f "$extract_dir/zoxide" ]]; then
            cp "$extract_dir/zoxide" "$LABRAT_BIN_DIR/zoxide"
            chmod +x "$LABRAT_BIN_DIR/zoxide"
            log_success "zoxide installed to $LABRAT_BIN_DIR"
        else
            log_error "Failed to find zoxide binary after extraction"
            return 1
        fi
    else
        log_error "Failed to download zoxide"
        return 1
    fi
    
    # Cleanup
    rm -rf "$extract_dir"
}

# ============================================================================
# Shell Integration (using new modular API)
# ============================================================================

setup_zoxide_integration() {
    log_step "Setting up zoxide shell integration..."
    
    # Define helper functions for bash
    local bash_functions='
# Disable zoxide (use regular cd)
zoxide-disable() {
    unset -f z zi
    alias z="cd"
    echo "zoxide disabled. Using regular cd."
}

# Re-enable zoxide
zoxide-enable() {
    unalias z 2>/dev/null
    if command -v zoxide &>/dev/null; then
        eval "$(zoxide init bash)"
        echo "zoxide enabled!"
    else
        echo "Error: zoxide not found"
        return 1
    fi
}

# Show zoxide database stats
zoxide-stats() {
    if command -v zoxide &>/dev/null; then
        echo "Top directories by frecency:"
        zoxide query -l | head -20
    fi
}'

    # Define helper functions for zsh
    local zsh_functions='
# Disable zoxide (use regular cd)
zoxide-disable() {
    unfunction z zi 2>/dev/null
    alias z="cd"
    echo "zoxide disabled. Using regular cd."
}

# Re-enable zoxide
zoxide-enable() {
    unalias z 2>/dev/null
    if (( $+commands[zoxide] )); then
        eval "$(zoxide init zsh)"
        echo "zoxide enabled!"
    else
        echo "Error: zoxide not found"
        return 1
    fi
}

# Show zoxide database stats
zoxide-stats() {
    if (( $+commands[zoxide] )); then
        echo "Top directories by frecency:"
        zoxide query -l | head -20
    fi
}'

    # Define helper functions for fish
    local fish_functions='
# Disable zoxide
function zoxide-disable
    functions -e z zi
    alias z="cd"
    echo "zoxide disabled. Using regular cd."
end

# Re-enable zoxide
function zoxide-enable
    functions -e z
    if command -v zoxide &>/dev/null
        zoxide init fish | source
        echo "zoxide enabled!"
    else
        echo "Error: zoxide not found"
        return 1
    end
end

# Show zoxide database stats
function zoxide-stats
    if command -v zoxide &>/dev/null
        echo "Top directories by frecency:"
        zoxide query -l | head -20
    end
end'

    # Register shell integration using new modular API
    register_shell_module "zoxide" \
        --init-bash 'eval "$(zoxide init bash)"' \
        --init-zsh 'eval "$(zoxide init zsh)"' \
        --init-fish 'zoxide init fish | source' \
        --functions-bash "$bash_functions" \
        --functions-zsh "$zsh_functions" \
        --functions-fish "$fish_functions" \
        --description "Smarter cd command"
    
    log_success "zoxide shell integration configured"
    log_info "Commands: ${BOLD}z${NC} (jump to directory), ${BOLD}zi${NC} (interactive)"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_zoxide() {
    log_step "Uninstalling zoxide..."
    
    # Remove binary
    rm -f "$LABRAT_BIN_DIR/zoxide"
    
    # Remove shell integration (using new API)
    unregister_shell_module "zoxide"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/zoxide"
    
    # Optional: remove zoxide data
    if [[ -d "$HOME/.local/share/zoxide" ]]; then
        if confirm "Remove zoxide database (~/.local/share/zoxide)?" "n"; then
            rm -rf "$HOME/.local/share/zoxide"
            log_info "Removed zoxide database"
        fi
    fi
    
    log_success "zoxide uninstalled"
}
