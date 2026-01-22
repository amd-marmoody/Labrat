#!/usr/bin/env bash
#
# LabRat Module: ripgrep
# Fast regex-based search tool
#

# Module metadata
RIPGREP_GITHUB_REPO="BurntSushi/ripgrep"

# ============================================================================
# Installation
# ============================================================================

install_ripgrep() {
    log_step "Installing ripgrep..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists rg; then
        installed_version=$(rg --version | head -1 | awk '{print $2}')
        log_info "ripgrep already installed (version: $installed_version)"
        mark_module_installed "ripgrep" "$installed_version"
        return 0
    fi
    
    # Install ripgrep
    case "$OS_FAMILY" in
        debian)
            pkg_install ripgrep
            ;;
        rhel)
            # Try package manager first, fall back to binary
            if pkg_install ripgrep 2>/dev/null; then
                :
            else
                install_ripgrep_binary
            fi
            ;;
        arch)
            pkg_install ripgrep
            ;;
        *)
            install_ripgrep_binary
            ;;
    esac
    
    # Get version
    installed_version=$(rg --version | head -1 | awk '{print $2}')
    log_info "ripgrep version: $installed_version"
    
    # Setup configuration
    setup_ripgrep_config
    
    # Mark as installed
    mark_module_installed "ripgrep" "$installed_version"
    
    log_success "ripgrep installed!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_ripgrep_binary() {
    log_step "Installing ripgrep from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${RIPGREP_GITHUB_REPO}/releases/latest"
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
        log_error "Could not find download URL for ripgrep"
        return 1
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/ripgrep"
    download_and_extract "$download_url" "$extract_dir" "Downloading ripgrep"
    
    # Find and copy binary
    local rg_bin=$(find "$extract_dir" -name "rg" -type f -executable | head -1)
    if [[ -n "$rg_bin" ]]; then
        cp "$rg_bin" "$LABRAT_BIN_DIR/rg"
        chmod +x "$LABRAT_BIN_DIR/rg"
        log_success "ripgrep installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find rg binary"
        return 1
    fi
}

# ============================================================================
# Configuration
# ============================================================================

setup_ripgrep_config() {
    local config_file="$HOME/.ripgreprc"
    
    cat > "$config_file" << 'RIPGREP_CONFIG'
# ripgrep configuration (added by LabRat)

# Smart case (case-insensitive unless uppercase used)
--smart-case

# Follow symbolic links
--follow

# Search hidden files (except .git)
--hidden
--glob=!.git/

# Add line numbers
--line-number

# Use colors
--color=auto

# Max columns (truncate long lines)
--max-columns=200
--max-columns-preview

# Show context lines
--context=2
RIPGREP_CONFIG

    export RIPGREP_CONFIG_PATH="$config_file"
    
    log_success "ripgrep configuration deployed"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_ripgrep() {
    log_step "Uninstalling ripgrep..."
    
    rm -f "$LABRAT_BIN_DIR/rg"
    rm -f "$HOME/.ripgreprc"
    rm -f "${LABRAT_DATA_DIR}/installed/ripgrep"
    
    log_success "ripgrep removed"
}
