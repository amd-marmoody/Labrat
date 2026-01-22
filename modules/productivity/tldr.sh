#!/usr/bin/env bash
#
# LabRat Module: tldr (tealdeer)
# Fast implementation of tldr in Rust - simplified man pages
# https://github.com/dbrgn/tealdeer
#

TLDR_GITHUB_REPO="dbrgn/tealdeer"

install_tldr() {
    log_step "Installing tealdeer (tldr)..."
    
    if command_exists tldr; then
        local installed_version=$(tldr --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "tldr already installed (v${installed_version})"
        if ! confirm "Reinstall/update tldr?" "n"; then
            mark_module_installed "tldr" "${installed_version}"
            return 0
        fi
    fi
    
    install_tldr_from_github
    
    if ! command_exists tldr; then
        log_error "tldr installation failed"
        return 1
    fi
    
    # Update tldr cache
    log_step "Updating tldr cache..."
    tldr --update 2>/dev/null || true
    
    local version=$(tldr --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "tldr" "${version:-unknown}"
    
    log_success "tldr installed successfully!"
    log_info "Run ${BOLD}tldr tar${NC} for simplified tar help"
    log_info "Run ${BOLD}tldr --update${NC} to update pages"
}

install_tldr_from_github() {
    log_step "Installing tealdeer from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$TLDR_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest tealdeer version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        armv7l|armhf) arch_suffix="armv7-unknown-linux-musleabihf" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${TLDR_GITHUB_REPO}/releases/download/${latest_version}/tealdeer-${arch_suffix}"
    local temp_file="${LABRAT_CACHE_DIR}/tldr"
    
    if download_file "$download_url" "$temp_file" "Downloading tealdeer"; then
        cp "$temp_file" "$LABRAT_BIN_DIR/tldr"
        chmod +x "$LABRAT_BIN_DIR/tldr"
        rm -f "$temp_file"
        log_success "tealdeer installed from GitHub"
    else
        log_error "Failed to download tealdeer"
        return 1
    fi
}

uninstall_tldr() {
    log_step "Uninstalling tldr..."
    rm -f "$LABRAT_BIN_DIR/tldr"
    rm -rf "$HOME/.cache/tealdeer"
    rm -f "${LABRAT_DATA_DIR}/installed/tldr"
    log_success "tldr uninstalled"
}
