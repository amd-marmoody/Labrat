#!/usr/bin/env bash
#
# LabRat Module: eza
# Modern replacement for ls
#

# Module metadata
EZA_GITHUB_REPO="eza-community/eza"

# ============================================================================
# Installation
# ============================================================================

install_eza() {
    log_step "Installing eza..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists eza; then
        installed_version=$(eza --version | head -1 | awk '{print $2}')
        log_info "eza already installed (version: $installed_version)"
        mark_module_installed "eza" "$installed_version"
        return 0
    fi
    
    # Install eza
    case "$OS_FAMILY" in
        debian)
            # eza may not be in standard repos, install from GitHub
            install_eza_binary
            ;;
        arch)
            pkg_install eza
            ;;
        *)
            install_eza_binary
            ;;
    esac
    
    # Get version
    if command_exists eza; then
        installed_version=$(eza --version | head -1 | awk '{print $2}' | tr -d 'v')
    fi
    log_info "eza version: $installed_version"
    
    # Mark as installed
    mark_module_installed "eza" "$installed_version"
    
    log_success "eza installed!"
    log_info "eza is aliased to 'ls' in your shell config"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_eza_binary() {
    log_step "Installing eza from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${EZA_GITHUB_REPO}/releases/latest"
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
        log_error "Could not find download URL for eza"
        return 1
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/eza"
    download_and_extract "$download_url" "$extract_dir" "Downloading eza"
    
    # Find and copy binary
    local eza_bin=$(find "$extract_dir" -name "eza" -type f | head -1)
    if [[ -n "$eza_bin" ]]; then
        cp "$eza_bin" "$LABRAT_BIN_DIR/eza"
        chmod +x "$LABRAT_BIN_DIR/eza"
        log_success "eza installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find eza binary"
        return 1
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_eza() {
    log_step "Uninstalling eza..."
    
    rm -f "$LABRAT_BIN_DIR/eza"
    rm -f "${LABRAT_DATA_DIR}/installed/eza"
    
    log_success "eza removed"
}
