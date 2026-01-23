#!/usr/bin/env bash
#
# LabRat Module: gping
# Ping, but with a graph - graphical ping utility
# https://github.com/orf/gping
#

GPING_GITHUB_REPO="orf/gping"

install_gping() {
    log_step "Installing gping..."
    
    if command_exists gping; then
        local installed_version=$(gping --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "gping already installed (v${installed_version})"
        if ! confirm "Reinstall/update gping?" "n"; then
            mark_module_installed "gping" "${installed_version}"
            return 0
        fi
    fi
    
    install_gping_from_github
    
    if ! command_exists gping; then
        log_error "gping installation failed"
        return 1
    fi
    
    local version=$(gping --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "gping" "${version:-unknown}"
    
    log_success "gping installed successfully!"
    log_info "Run ${BOLD}gping google.com${NC} to ping with graph"
    log_info "Run ${BOLD}gping google.com cloudflare.com${NC} to compare multiple hosts"
}

install_gping_from_github() {
    log_step "Installing gping from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$GPING_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest gping version"
        return 1
    fi
    
    # gping uses format: gping-Linux-x86_64.tar.gz
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="Linux-x86_64" ;;
        aarch64|arm64) arch_suffix="Linux-aarch64" ;;
        armv7l|armhf) arch_suffix="Linux-arm" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${GPING_GITHUB_REPO}/releases/download/${latest_version}/gping-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/gping.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/gping"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading gping"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        cp "$extract_dir/gping" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/gping"
        rm -rf "$temp_file" "$extract_dir"
        log_success "gping installed from GitHub"
    else
        log_error "Failed to download gping"
        return 1
    fi
}

uninstall_gping() {
    log_step "Uninstalling gping..."
    rm -f "$LABRAT_BIN_DIR/gping"
    rm -f "${LABRAT_DATA_DIR}/installed/gping"
    log_success "gping uninstalled"
}
