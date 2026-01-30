#!/usr/bin/env bash
#
# LabRat Module: bat
# Cat clone with syntax highlighting
#

# Module metadata
BAT_GITHUB_REPO="sharkdp/bat"

# ============================================================================
# Installation
# ============================================================================

install_bat() {
    log_step "Installing bat..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists bat || command_exists batcat; then
        if command_exists bat; then
            installed_version=$(bat --version | awk '{print $2}')
        else
            installed_version=$(batcat --version | awk '{print $2}')
        fi
        log_info "bat already installed (version: $installed_version)"
        
        if ! confirm "Reinstall/update bat?" "n"; then
            setup_bat_alias
            mark_module_installed "bat" "$installed_version"
            return 0
        fi
    fi
    
    # Install bat
    case "$OS_FAMILY" in
        debian)
            pkg_install bat
            # On Debian/Ubuntu, the binary is called batcat
            setup_bat_alias
            ;;
        rhel)
            install_bat_binary
            ;;
        arch)
            pkg_install bat
            ;;
        *)
            install_bat_binary
            ;;
    esac
    
    # Get version
    if command_exists bat; then
        installed_version=$(bat --version | awk '{print $2}')
    elif command_exists batcat; then
        installed_version=$(batcat --version | awk '{print $2}')
    fi
    log_info "bat version: $installed_version"
    
    # Setup configuration
    setup_bat_config
    
    # Mark as installed
    mark_module_installed "bat" "$installed_version"
    
    log_success "bat installed and configured!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_bat_binary() {
    log_step "Installing bat from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${BAT_GITHUB_REPO}/releases/latest"
    local download_url=""
    
    # Get latest release download URL
    case "$ARCH" in
        amd64)
            download_url=$(curl -fsSL "$release_url" | grep -oP '"browser_download_url": "\K[^"]+x86_64-unknown-linux-musl\.tar\.gz')
            ;;
        arm64)
            download_url=$(curl -fsSL "$release_url" | grep -oP '"browser_download_url": "\K[^"]+aarch64-unknown-linux-gnu\.tar\.gz')
            ;;
        *)
            log_warn "Unsupported architecture: $ARCH, trying package manager"
            pkg_install bat
            return
            ;;
    esac
    
    if [[ -z "$download_url" ]]; then
        log_warn "Could not find download URL, trying package manager"
        pkg_install bat
        return
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/bat"
    download_and_extract "$download_url" "$extract_dir" "Downloading bat"
    
    # Find and copy binary
    local bat_bin=$(find "$extract_dir" -name "bat" -type f -executable | head -1)
    if [[ -n "$bat_bin" ]]; then
        cp "$bat_bin" "$LABRAT_BIN_DIR/bat"
        chmod +x "$LABRAT_BIN_DIR/bat"
        log_success "bat installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find bat binary"
        return 1
    fi
}

# ============================================================================
# Configuration
# ============================================================================

setup_bat_alias() {
    # On Debian/Ubuntu, bat is installed as batcat
    if command_exists batcat && ! command_exists bat; then
        log_info "Creating bat alias for batcat"
        ln -sf "$(which batcat)" "$LABRAT_BIN_DIR/bat"
    fi
}

setup_bat_config() {
    local config_dir="$HOME/.config/bat"
    local config_file="$config_dir/config"
    local themes_dir="$config_dir/themes"
    
    ensure_dir "$config_dir"
    ensure_dir "$themes_dir"
    
    # Deploy themes from LabRat configs
    if [[ -d "${LABRAT_CONFIGS_DIR}/bat/themes" ]]; then
        log_step "Deploying bat themes..."
        cp -f "${LABRAT_CONFIGS_DIR}/bat/themes/"*.tmTheme "$themes_dir/" 2>/dev/null || true
        local theme_count
        theme_count=$(find "$themes_dir" -name "*.tmTheme" 2>/dev/null | wc -l)
        log_success "Deployed $theme_count bat themes"
    fi
    
    cat > "$config_file" << 'BAT_CONFIG'
# bat configuration (added by LabRat)

# Theme (use "Catppuccin Mocha" with space - matches .tmTheme filename)
--theme="Catppuccin Mocha"

# Show line numbers
--style="numbers,changes,header"

# Use italic text
--italic-text=always

# Pager
--pager="less -FR"
BAT_CONFIG

    # Build bat cache for themes
    if command_exists bat; then
        bat cache --build 2>/dev/null || true
    fi
    
    log_success "bat configuration deployed"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_bat() {
    log_step "Uninstalling bat..."
    
    rm -f "$LABRAT_BIN_DIR/bat"
    rm -rf "$HOME/.config/bat"
    rm -f "${LABRAT_DATA_DIR}/installed/bat"
    
    log_success "bat removed"
}
