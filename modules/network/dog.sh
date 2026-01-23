#!/usr/bin/env bash
#
# LabRat Module: dog
# Command-line DNS client (better dig alternative)
# https://github.com/ogham/dog
#

DOG_GITHUB_REPO="ogham/dog"

install_dog() {
    log_step "Installing dog..."
    
    if command_exists dog; then
        local installed_version=$(dog --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "dog already installed (v${installed_version})"
        if ! confirm "Reinstall/update dog?" "n"; then
            mark_module_installed "dog" "${installed_version}"
            return 0
        fi
    fi
    
    install_dog_from_github
    
    if ! command_exists dog; then
        log_error "dog installation failed"
        return 1
    fi
    
    local version=$(dog --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "dog" "${version:-unknown}"
    
    log_success "dog installed successfully!"
    log_info "Run ${BOLD}dog google.com${NC} for DNS lookup"
    log_info "Run ${BOLD}dog google.com A AAAA MX${NC} for multiple record types"
}

install_dog_from_github() {
    log_step "Installing dog from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$DOG_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest dog version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-gnu" ;;
        *) log_error "dog only provides x86_64 binaries. Arch: $ARCH"; return 1 ;;
    esac
    
    # Strip 'v' prefix from version for filename
    local version_no_v="${latest_version#v}"
    local download_url="https://github.com/${DOG_GITHUB_REPO}/releases/download/${latest_version}/dog-${version_no_v}-${arch_suffix}.zip"
    local temp_file="${LABRAT_CACHE_DIR}/dog.zip"
    local extract_dir="${LABRAT_CACHE_DIR}/dog"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading dog"; then
        unzip -o -q "$temp_file" -d "$extract_dir"
        cp "$extract_dir/bin/dog" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/dog"
        rm -rf "$temp_file" "$extract_dir"
        log_success "dog installed from GitHub"
    else
        log_error "Failed to download dog"
        return 1
    fi
}

uninstall_dog() {
    log_step "Uninstalling dog..."
    rm -f "$LABRAT_BIN_DIR/dog"
    rm -f "${LABRAT_DATA_DIR}/installed/dog"
    log_success "dog uninstalled"
}
