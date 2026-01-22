#!/usr/bin/env bash
#
# LabRat Module: atuin
# Magical shell history - sync, search, and backup
# https://github.com/atuinsh/atuin
#

ATUIN_GITHUB_REPO="atuinsh/atuin"

install_atuin() {
    log_step "Installing atuin..."
    
    if command_exists atuin; then
        local installed_version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "atuin already installed (v${installed_version})"
        if ! confirm "Reinstall/update atuin?" "n"; then
            mark_module_installed "atuin" "${installed_version}"
            return 0
        fi
    fi
    
    install_atuin_from_github
    
    if ! command_exists atuin; then
        log_error "atuin installation failed"
        return 1
    fi
    
    local version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "atuin" "${version:-unknown}"
    
    # Setup shell integration
    setup_atuin_shell
    
    log_success "atuin installed successfully!"
    log_info "Run ${BOLD}atuin import auto${NC} to import existing history"
    log_info "Press ${BOLD}Ctrl+R${NC} for interactive search"
}

install_atuin_from_github() {
    log_step "Installing atuin from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$ATUIN_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest atuin version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${ATUIN_GITHUB_REPO}/releases/download/${latest_version}/atuin-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/atuin.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/atuin"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading atuin"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        find "$extract_dir" -name "atuin" -type f -executable -exec cp {} "$LABRAT_BIN_DIR/" \;
        chmod +x "$LABRAT_BIN_DIR/atuin"
        rm -rf "$temp_file" "$extract_dir"
        log_success "atuin installed from GitHub"
    else
        log_error "Failed to download atuin"
        return 1
    fi
}

setup_atuin_shell() {
    log_step "Setting up atuin shell integration..."
    
    # Bash
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "atuin init" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# atuin shell history" >> "$bashrc"
        echo 'eval "$(atuin init bash)"' >> "$bashrc"
        log_info "Added atuin to .bashrc"
    fi
    
    # Zsh
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q "atuin init" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "# atuin shell history" >> "$zshrc"
        echo 'eval "$(atuin init zsh)"' >> "$zshrc"
        log_info "Added atuin to .zshrc"
    fi
}

uninstall_atuin() {
    log_step "Uninstalling atuin..."
    rm -f "$LABRAT_BIN_DIR/atuin"
    rm -f "${LABRAT_DATA_DIR}/installed/atuin"
    log_success "atuin uninstalled"
    log_info "Remove 'eval \"\$(atuin init ...)\"' from your shell config"
    log_info "Optionally remove ~/.local/share/atuin"
}
