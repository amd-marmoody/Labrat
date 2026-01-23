#!/usr/bin/env bash
#
# LabRat Module: trippy
# A network diagnostic tool with rich TUI - beautiful traceroute
# https://github.com/fujiapple852/trippy
#

TRIPPY_GITHUB_REPO="fujiapple852/trippy"

install_trippy() {
    log_step "Installing trippy..."
    
    if command_exists trip; then
        local installed_version=$(trip --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "trippy already installed (v${installed_version})"
        if ! confirm "Reinstall/update trippy?" "n"; then
            mark_module_installed "trippy" "${installed_version}"
            return 0
        fi
    fi
    
    install_trippy_from_github
    
    if ! command_exists trip; then
        log_error "trippy installation failed"
        return 1
    fi
    
    local version=$(trip --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "trippy" "${version:-unknown}"
    
    log_success "trippy installed successfully!"
    log_info "Run ${BOLD}sudo trip google.com${NC} for beautiful traceroute"
}

install_trippy_from_github() {
    log_step "Installing trippy from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$TRIPPY_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest trippy version"
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
    local download_url="https://github.com/${TRIPPY_GITHUB_REPO}/releases/download/${latest_version}/trippy-${version_no_v}-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/trippy.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/trippy"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading trippy"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        cp "$extract_dir/trippy-${version_no_v}-${arch_suffix}/trip" "$LABRAT_BIN_DIR/" 2>/dev/null || \
        cp "$extract_dir/trip" "$LABRAT_BIN_DIR/" 2>/dev/null || \
        find "$extract_dir" -name "trip" -type f -exec cp {} "$LABRAT_BIN_DIR/" \;
        chmod +x "$LABRAT_BIN_DIR/trip"
        rm -rf "$temp_file" "$extract_dir"
        log_success "trippy installed from GitHub"
    else
        log_error "Failed to download trippy"
        return 1
    fi
}

uninstall_trippy() {
    log_step "Uninstalling trippy..."
    rm -f "$LABRAT_BIN_DIR/trip"
    rm -f "${LABRAT_DATA_DIR}/installed/trippy"
    log_success "trippy uninstalled"
}
