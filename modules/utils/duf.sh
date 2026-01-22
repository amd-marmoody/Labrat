#!/usr/bin/env bash
#
# LabRat Module: duf
# Disk Usage/Free Utility - a better 'df' alternative
# https://github.com/muesli/duf
#

# Module metadata
DUF_GITHUB_REPO="muesli/duf"

# ============================================================================
# Installation
# ============================================================================

install_duf() {
    log_step "Installing duf..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists duf; then
        installed_version=$(duf --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "duf already installed (v${installed_version})"
        
        if ! confirm "Reinstall/update duf?" "n"; then
            mark_module_installed "duf" "${installed_version}"
            return 0
        fi
    fi
    
    # Try package manager first
    local pkg_installed=false
    
    case "$OS_FAMILY" in
        debian)
            if pkg_install duf 2>/dev/null; then
                pkg_installed=true
            fi
            ;;
        rhel)
            if pkg_install duf 2>/dev/null; then
                pkg_installed=true
            fi
            ;;
    esac
    
    # If package manager failed, install from GitHub
    if [[ "$pkg_installed" != "true" ]]; then
        install_duf_from_github
    fi
    
    # Verify installation
    if ! command_exists duf; then
        log_error "duf installation failed"
        return 1
    fi
    
    installed_version=$(duf --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    
    # Mark as installed
    mark_module_installed "duf" "${installed_version:-unknown}"
    
    log_success "duf installed successfully!"
    log_info "Run ${BOLD}duf${NC} to display disk usage"
}

# ============================================================================
# GitHub Binary Installation
# ============================================================================

install_duf_from_github() {
    log_step "Installing duf from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$DUF_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest duf version"
        return 1
    fi
    
    log_info "Latest version: $latest_version"
    
    # Determine architecture and package type
    local arch_suffix=""
    local pkg_ext=""
    
    case "$ARCH" in
        x86_64|amd64)
            arch_suffix="amd64"
            ;;
        aarch64|arm64)
            arch_suffix="arm64"
            ;;
        armv7l|armhf)
            arch_suffix="armv7"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Prefer deb/rpm for easier installation, fallback to tar.gz
    case "$OS_FAMILY" in
        debian)
            pkg_ext="deb"
            local download_url="https://github.com/${DUF_GITHUB_REPO}/releases/download/${latest_version}/duf_${latest_version#v}_linux_${arch_suffix}.deb"
            local temp_file="${LABRAT_CACHE_DIR}/duf.deb"
            
            if download_file "$download_url" "$temp_file" "Downloading duf"; then
                sudo dpkg -i "$temp_file" || sudo apt-get install -f -y
                rm -f "$temp_file"
            else
                log_error "Failed to download duf"
                return 1
            fi
            ;;
        rhel)
            pkg_ext="rpm"
            local download_url="https://github.com/${DUF_GITHUB_REPO}/releases/download/${latest_version}/duf_${latest_version#v}_linux_${arch_suffix}.rpm"
            local temp_file="${LABRAT_CACHE_DIR}/duf.rpm"
            
            if download_file "$download_url" "$temp_file" "Downloading duf"; then
                sudo rpm -i "$temp_file" 2>/dev/null || sudo dnf install -y "$temp_file" 2>/dev/null || sudo yum install -y "$temp_file"
                rm -f "$temp_file"
            else
                log_error "Failed to download duf"
                return 1
            fi
            ;;
        *)
            # Generic tar.gz installation
            local download_url="https://github.com/${DUF_GITHUB_REPO}/releases/download/${latest_version}/duf_${latest_version#v}_linux_${arch_suffix}.tar.gz"
            local temp_file="${LABRAT_CACHE_DIR}/duf.tar.gz"
            local extract_dir="${LABRAT_CACHE_DIR}/duf"
            
            ensure_dir "$extract_dir"
            
            if download_file "$download_url" "$temp_file" "Downloading duf"; then
                tar -xzf "$temp_file" -C "$extract_dir"
                cp "$extract_dir/duf" "$LABRAT_BIN_DIR/"
                chmod +x "$LABRAT_BIN_DIR/duf"
                rm -rf "$temp_file" "$extract_dir"
            else
                log_error "Failed to download duf"
                return 1
            fi
            ;;
    esac
    
    log_success "duf installed from GitHub"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_duf() {
    log_step "Uninstalling duf..."
    
    # Remove binary if installed by us
    if [[ -f "$LABRAT_BIN_DIR/duf" ]]; then
        rm -f "$LABRAT_BIN_DIR/duf"
        log_success "Removed duf binary"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/duf"
    
    log_success "duf uninstalled"
    log_info "Note: If installed via package manager, use 'apt remove duf' or 'dnf remove duf'"
}
