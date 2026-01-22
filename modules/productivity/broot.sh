#!/usr/bin/env bash
#
# LabRat Module: broot
# A new way to see and navigate directory trees
# https://github.com/Canop/broot
#

BROOT_GITHUB_REPO="Canop/broot"

install_broot() {
    log_step "Installing broot..."
    
    if command_exists broot; then
        local installed_version=$(broot --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "broot already installed (v${installed_version})"
        if ! confirm "Reinstall/update broot?" "n"; then
            mark_module_installed "broot" "${installed_version}"
            return 0
        fi
    fi
    
    install_broot_from_github
    
    if ! command_exists broot; then
        log_error "broot installation failed"
        return 1
    fi
    
    local version=$(broot --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "broot" "${version:-unknown}"
    
    # Install shell function
    setup_broot_shell
    
    log_success "broot installed successfully!"
    log_info "Run ${BOLD}broot${NC} to browse directories"
    log_info "Run ${BOLD}br${NC} for the shell function (cd on quit)"
}

install_broot_from_github() {
    log_step "Installing broot from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$BROOT_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest broot version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        armv7l|armhf) arch_suffix="armv7-unknown-linux-musleabihf" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${BROOT_GITHUB_REPO}/releases/download/${latest_version}/broot_${latest_version}.zip"
    local temp_file="${LABRAT_CACHE_DIR}/broot.zip"
    local extract_dir="${LABRAT_CACHE_DIR}/broot"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading broot"; then
        unzip -o -q "$temp_file" -d "$extract_dir"
        cp "$extract_dir/${arch_suffix}/broot" "$LABRAT_BIN_DIR/" 2>/dev/null || \
        find "$extract_dir" -name "broot" -type f -exec cp {} "$LABRAT_BIN_DIR/" \;
        chmod +x "$LABRAT_BIN_DIR/broot"
        rm -rf "$temp_file" "$extract_dir"
        log_success "broot installed from GitHub"
    else
        log_error "Failed to download broot"
        return 1
    fi
}

setup_broot_shell() {
    log_step "Setting up broot shell function..."
    
    # broot installs its shell function automatically when first run
    # Just show instructions
    log_info "Run ${BOLD}broot${NC} once to set up the br shell function"
    log_info "Or run: ${BOLD}broot --install${NC}"
}

uninstall_broot() {
    log_step "Uninstalling broot..."
    rm -f "$LABRAT_BIN_DIR/broot"
    rm -rf "$HOME/.config/broot"
    rm -f "${LABRAT_DATA_DIR}/installed/broot"
    log_success "broot uninstalled"
    log_info "Remove broot lines from your shell config files if present"
}
