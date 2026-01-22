#!/usr/bin/env bash
#
# LabRat Module: fd
# Fast and user-friendly alternative to find
#

# Module metadata
FD_GITHUB_REPO="sharkdp/fd"

# ============================================================================
# Installation
# ============================================================================

install_fd() {
    log_step "Installing fd..."
    
    local installed_version=""
    
    # Check if already installed (note: Debian/Ubuntu uses 'fdfind')
    if command_exists fd; then
        installed_version=$(fd --version | awk '{print $2}')
        log_info "fd already installed (version: $installed_version)"
        mark_module_installed "fd" "$installed_version"
        return 0
    elif command_exists fdfind; then
        installed_version=$(fdfind --version | awk '{print $2}')
        log_info "fd already installed as fdfind (version: $installed_version)"
        setup_fd_alias
        mark_module_installed "fd" "$installed_version"
        return 0
    fi
    
    # Install fd
    case "$OS_FAMILY" in
        debian)
            pkg_install fd-find
            setup_fd_alias
            ;;
        rhel)
            install_fd_binary
            ;;
        arch)
            pkg_install fd
            ;;
        *)
            install_fd_binary
            ;;
    esac
    
    # Get version
    if command_exists fd; then
        installed_version=$(fd --version | awk '{print $2}')
    elif command_exists fdfind; then
        installed_version=$(fdfind --version | awk '{print $2}')
    fi
    log_info "fd version: $installed_version"
    
    # Mark as installed
    mark_module_installed "fd" "$installed_version"
    
    log_success "fd installed!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_fd_binary() {
    log_step "Installing fd from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${FD_GITHUB_REPO}/releases/latest"
    local download_url=""
    
    case "$ARCH" in
        amd64)
            download_url=$(curl -fsSL "$release_url" | grep -oP '"browser_download_url": "\K[^"]+x86_64-unknown-linux-musl\.tar\.gz' | head -1)
            ;;
        arm64)
            download_url=$(curl -fsSL "$release_url" | grep -oP '"browser_download_url": "\K[^"]+aarch64-unknown-linux-gnu\.tar\.gz' | head -1)
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    if [[ -z "$download_url" ]]; then
        log_error "Could not find download URL for fd"
        return 1
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/fd"
    download_and_extract "$download_url" "$extract_dir" "Downloading fd"
    
    # Find and copy binary
    local fd_bin=$(find "$extract_dir" -name "fd" -type f -executable | head -1)
    if [[ -n "$fd_bin" ]]; then
        cp "$fd_bin" "$LABRAT_BIN_DIR/fd"
        chmod +x "$LABRAT_BIN_DIR/fd"
        log_success "fd installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find fd binary"
        return 1
    fi
}

# ============================================================================
# Configuration
# ============================================================================

setup_fd_alias() {
    # On Debian/Ubuntu, fd is installed as fdfind
    if command_exists fdfind && ! command_exists fd; then
        log_info "Creating fd alias for fdfind"
        ln -sf "$(which fdfind)" "$LABRAT_BIN_DIR/fd"
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_fd() {
    log_step "Uninstalling fd..."
    
    rm -f "$LABRAT_BIN_DIR/fd"
    rm -f "${LABRAT_DATA_DIR}/installed/fd"
    
    log_success "fd removed"
}
