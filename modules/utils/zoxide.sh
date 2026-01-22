#!/usr/bin/env bash
#
# LabRat Module: zoxide
# Smarter cd command that learns your habits
#

# Module metadata
ZOXIDE_INSTALL_URL="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"

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
        setup_zoxide_integration
        mark_module_installed "zoxide" "$installed_version"
        return 0
    fi
    
    # Install zoxide
    install_zoxide_binary
    
    # Get version
    installed_version=$(zoxide --version | awk '{print $2}')
    log_info "zoxide version: $installed_version"
    
    # Setup shell integration
    setup_zoxide_integration
    
    # Mark as installed
    mark_module_installed "zoxide" "$installed_version"
    
    log_success "zoxide installed!"
    log_info "Use 'z' command instead of 'cd' to navigate"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_zoxide_binary() {
    log_step "Installing zoxide from GitHub releases..."
    
    local github_repo="ajeetdsouza/zoxide"
    local release_url="https://api.github.com/repos/${github_repo}/releases/latest"
    local download_url=""
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
        download_url="https://github.com/${github_repo}/releases/download/${version}/zoxide-${version#v}-${arch_pattern}.tar.gz"
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
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_zoxide_integration() {
    log_step "Setting up zoxide shell integration..."
    
    # Bash integration
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q 'zoxide init bash' "$bashrc"; then
        {
            echo ""
            echo "# zoxide (added by LabRat)"
            echo 'eval "$(zoxide init bash)"'
        } >> "$bashrc"
    fi
    
    # Zsh integration (usually in .zshrc already from our template)
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q 'zoxide init zsh' "$zshrc"; then
        {
            echo ""
            echo "# zoxide (added by LabRat)"
            echo 'eval "$(zoxide init zsh)"'
        } >> "$zshrc"
    fi
    
    log_success "zoxide shell integration configured"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_zoxide() {
    log_step "Uninstalling zoxide..."
    
    rm -f "$LABRAT_BIN_DIR/zoxide"
    rm -f "${LABRAT_DATA_DIR}/installed/zoxide"
    
    log_success "zoxide removed"
    log_info "Note: Shell integration lines may need to be manually removed"
}
