#!/usr/bin/env bash
#
# LabRat Module: direnv
# Extension for your shell that loads/unloads env vars per directory
# https://github.com/direnv/direnv
#

DIRENV_GITHUB_REPO="direnv/direnv"

install_direnv() {
    log_step "Installing direnv..."
    
    if command_exists direnv; then
        local installed_version=$(direnv version 2>/dev/null)
        log_info "direnv already installed (v${installed_version})"
        if ! confirm "Reinstall/update direnv?" "n"; then
            mark_module_installed "direnv" "${installed_version}"
            return 0
        fi
    fi
    
    # Try package manager first
    local pkg_installed=false
    case "$OS_FAMILY" in
        debian)
            if pkg_install direnv 2>/dev/null; then pkg_installed=true; fi
            ;;
        rhel)
            if pkg_install direnv 2>/dev/null; then pkg_installed=true; fi
            ;;
    esac
    
    if [[ "$pkg_installed" != "true" ]]; then
        install_direnv_from_github
    fi
    
    if ! command_exists direnv; then
        log_error "direnv installation failed"
        return 1
    fi
    
    local version=$(direnv version 2>/dev/null)
    mark_module_installed "direnv" "${version:-unknown}"
    
    # Setup shell hook
    setup_direnv_hook
    
    log_success "direnv installed successfully!"
    log_info "Add ${BOLD}eval \"\$(direnv hook bash)\"${NC} to your .bashrc"
    log_info "Create ${BOLD}.envrc${NC} file in project directory"
}

install_direnv_from_github() {
    log_step "Installing direnv from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$DIRENV_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest direnv version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="linux-amd64" ;;
        aarch64|arm64) arch_suffix="linux-arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${DIRENV_GITHUB_REPO}/releases/download/${latest_version}/direnv.${arch_suffix}"
    local temp_file="${LABRAT_CACHE_DIR}/direnv"
    
    if download_file "$download_url" "$temp_file" "Downloading direnv"; then
        cp "$temp_file" "$LABRAT_BIN_DIR/direnv"
        chmod +x "$LABRAT_BIN_DIR/direnv"
        rm -f "$temp_file"
        log_success "direnv installed from GitHub"
    else
        log_error "Failed to download direnv"
        return 1
    fi
}

setup_direnv_hook() {
    log_step "Setting up direnv shell hook..."
    
    local hook_line='eval "$(direnv hook bash)"'
    local bashrc="$HOME/.bashrc"
    
    if [[ -f "$bashrc" ]] && ! grep -q "direnv hook" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# direnv hook" >> "$bashrc"
        echo "$hook_line" >> "$bashrc"
        log_info "Added direnv hook to .bashrc"
    fi
    
    # For zsh
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q "direnv hook" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "# direnv hook" >> "$zshrc"
        echo 'eval "$(direnv hook zsh)"' >> "$zshrc"
        log_info "Added direnv hook to .zshrc"
    fi
}

uninstall_direnv() {
    log_step "Uninstalling direnv..."
    rm -f "$LABRAT_BIN_DIR/direnv"
    rm -f "${LABRAT_DATA_DIR}/installed/direnv"
    log_success "direnv uninstalled"
    log_info "Remove 'eval \"\$(direnv hook ...)\"' from your shell config"
}
