#!/usr/bin/env bash
#
# LabRat Module: procs
# Modern replacement for ps written in Rust
# https://github.com/dalance/procs
#

PROCS_GITHUB_REPO="dalance/procs"

install_procs() {
    log_step "Installing procs..."
    
    local installed_version=""
    
    if command_exists procs; then
        installed_version=$(procs --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "procs already installed (v${installed_version})"
        if ! confirm "Reinstall/update procs?" "n"; then
            mark_module_installed "procs" "${installed_version}"
            return 0
        fi
    fi
    
    install_procs_from_github
    
    if ! command_exists procs; then
        log_error "procs installation failed"
        return 1
    fi
    
    installed_version=$(procs --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "procs" "${installed_version:-unknown}"
    
    log_success "procs installed successfully!"
    log_info "Run ${BOLD}procs${NC} to list processes"
}

install_procs_from_github() {
    log_step "Installing procs from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$PROCS_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest procs version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-linux" ;;
        aarch64|arm64) arch_suffix="aarch64-linux" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    # Strip 'v' prefix from version for filename
    local version_no_v="${latest_version#v}"
    local download_url="https://github.com/${PROCS_GITHUB_REPO}/releases/download/${latest_version}/procs-${version_no_v}-${arch_suffix}.zip"
    local temp_file="${LABRAT_CACHE_DIR}/procs.zip"
    
    ensure_dir "${LABRAT_CACHE_DIR}"
    
    if download_file "$download_url" "$temp_file" "Downloading procs"; then
        unzip -o -q "$temp_file" -d "${LABRAT_CACHE_DIR}"
        cp "${LABRAT_CACHE_DIR}/procs" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/procs"
        rm -f "$temp_file" "${LABRAT_CACHE_DIR}/procs"
        log_success "procs installed from GitHub"
    else
        log_error "Failed to download procs"
        return 1
    fi
}

uninstall_procs() {
    log_step "Uninstalling procs..."
    rm -f "$LABRAT_BIN_DIR/procs"
    rm -f "${LABRAT_DATA_DIR}/installed/procs"
    log_success "procs uninstalled"
}
