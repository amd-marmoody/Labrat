#!/usr/bin/env bash
#
# LabRat Module: mise
# Polyglot tool version manager (successor to asdf)
# https://github.com/jdx/mise
#

MISE_GITHUB_REPO="jdx/mise"

install_mise() {
    log_step "Installing mise..."
    
    if command_exists mise; then
        local installed_version=$(mise --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "mise already installed (v${installed_version})"
        if ! confirm "Reinstall/update mise?" "n"; then
            mark_module_installed "mise" "${installed_version}"
            return 0
        fi
    fi
    
    install_mise_from_github
    
    if ! command_exists mise; then
        log_error "mise installation failed"
        return 1
    fi
    
    local version=$(mise --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "mise" "${version:-unknown}"
    
    # Setup shell integration
    setup_mise_shell
    
    log_success "mise installed successfully!"
    log_info "Run ${BOLD}mise use node@20${NC} to install Node.js 20"
    log_info "Run ${BOLD}mise use python@3.11${NC} to install Python 3.11"
    log_info "Run ${BOLD}mise doctor${NC} to check setup"
}

install_mise_from_github() {
    log_step "Installing mise from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$MISE_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest mise version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="linux-x64" ;;
        aarch64|arm64) arch_suffix="linux-arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    # Strip 'v' prefix from version for filename
    local version_no_v="${latest_version#v}"
    local download_url="https://github.com/${MISE_GITHUB_REPO}/releases/download/${latest_version}/mise-${version_no_v}-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/mise.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/mise"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading mise"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        cp "$extract_dir/mise/bin/mise" "$LABRAT_BIN_DIR/" 2>/dev/null || \
        find "$extract_dir" -name "mise" -type f -executable -exec cp {} "$LABRAT_BIN_DIR/" \;
        chmod +x "$LABRAT_BIN_DIR/mise"
        rm -rf "$temp_file" "$extract_dir"
        log_success "mise installed from GitHub"
    else
        log_error "Failed to download mise"
        return 1
    fi
}

setup_mise_shell() {
    log_step "Setting up mise shell integration..."
    
    # Bash
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "mise activate" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# mise (tool version manager)" >> "$bashrc"
        echo 'eval "$(mise activate bash)"' >> "$bashrc"
        log_info "Added mise to .bashrc"
    fi
    
    # Zsh
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q "mise activate" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "# mise (tool version manager)" >> "$zshrc"
        echo 'eval "$(mise activate zsh)"' >> "$zshrc"
        log_info "Added mise to .zshrc"
    fi
}

uninstall_mise() {
    log_step "Uninstalling mise..."
    rm -f "$LABRAT_BIN_DIR/mise"
    rm -f "${LABRAT_DATA_DIR}/installed/mise"
    log_success "mise uninstalled"
    log_info "Remove 'eval \"\$(mise activate ...)\"' from your shell config"
    log_info "Optionally remove ~/.local/share/mise"
}
