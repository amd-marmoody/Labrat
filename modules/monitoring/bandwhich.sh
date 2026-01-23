#!/usr/bin/env bash
#
# LabRat Module: bandwhich
# Terminal bandwidth utilization tool - shows which processes use network
# https://github.com/imsnif/bandwhich
#

BANDWHICH_GITHUB_REPO="imsnif/bandwhich"

install_bandwhich() {
    log_step "Installing bandwhich..."
    
    local installed_version=""
    
    if command_exists bandwhich; then
        installed_version=$(bandwhich --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "bandwhich already installed (v${installed_version})"
        if ! confirm "Reinstall/update bandwhich?" "n"; then
            mark_module_installed "bandwhich" "${installed_version}"
            return 0
        fi
    fi
    
    install_bandwhich_from_github
    
    if ! command_exists bandwhich; then
        log_error "bandwhich installation failed"
        return 1
    fi
    
    # bandwhich needs capabilities to run without sudo
    if [[ -f "$LABRAT_BIN_DIR/bandwhich" ]]; then
        log_info "Setting capabilities for bandwhich (requires sudo)..."
        sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep "$LABRAT_BIN_DIR/bandwhich" 2>/dev/null || \
            log_warn "Could not set capabilities. Run bandwhich with sudo."
    fi
    
    installed_version=$(bandwhich --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "bandwhich" "${installed_version:-unknown}"
    
    log_success "bandwhich installed successfully!"
    log_info "Run ${BOLD}bandwhich${NC} to monitor network usage by process"
    log_info "May require sudo if capabilities not set"
}

install_bandwhich_from_github() {
    log_step "Installing bandwhich from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$BANDWHICH_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest bandwhich version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    # Strip 'v' prefix from version for filename
    local version_no_v="${latest_version#v}"
    local download_url="https://github.com/${BANDWHICH_GITHUB_REPO}/releases/download/${latest_version}/bandwhich-${version_no_v}-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/bandwhich.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/bandwhich"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading bandwhich"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        cp "$extract_dir/bandwhich" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/bandwhich"
        rm -rf "$temp_file" "$extract_dir"
        log_success "bandwhich installed from GitHub"
    else
        log_error "Failed to download bandwhich"
        return 1
    fi
}

uninstall_bandwhich() {
    log_step "Uninstalling bandwhich..."
    rm -f "$LABRAT_BIN_DIR/bandwhich"
    rm -f "${LABRAT_DATA_DIR}/installed/bandwhich"
    log_success "bandwhich uninstalled"
}
