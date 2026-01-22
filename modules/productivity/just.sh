#!/usr/bin/env bash
#
# LabRat Module: just
# Just a command runner - handy way to save and run project-specific commands
# https://github.com/casey/just
#

JUST_GITHUB_REPO="casey/just"

install_just() {
    log_step "Installing just..."
    
    if command_exists just; then
        local installed_version=$(just --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "just already installed (v${installed_version})"
        if ! confirm "Reinstall/update just?" "n"; then
            mark_module_installed "just" "${installed_version}"
            return 0
        fi
    fi
    
    install_just_from_github
    
    if ! command_exists just; then
        log_error "just installation failed"
        return 1
    fi
    
    local version=$(just --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    mark_module_installed "just" "${version:-unknown}"
    
    # Setup shell completion
    setup_just_completion
    
    log_success "just installed successfully!"
    log_info "Run ${BOLD}just${NC} to list available recipes"
    log_info "Run ${BOLD}just --init${NC} to create a justfile"
}

install_just_from_github() {
    log_step "Installing just from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$JUST_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest just version"
        return 1
    fi
    
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64) arch_suffix="x86_64-unknown-linux-musl" ;;
        aarch64|arm64) arch_suffix="aarch64-unknown-linux-musl" ;;
        armv7l|armhf) arch_suffix="armv7-unknown-linux-musleabihf" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac
    
    local download_url="https://github.com/${JUST_GITHUB_REPO}/releases/download/${latest_version}/just-${latest_version}-${arch_suffix}.tar.gz"
    local temp_file="${LABRAT_CACHE_DIR}/just.tar.gz"
    local extract_dir="${LABRAT_CACHE_DIR}/just"
    
    ensure_dir "$extract_dir"
    
    if download_file "$download_url" "$temp_file" "Downloading just"; then
        tar -xzf "$temp_file" -C "$extract_dir"
        cp "$extract_dir/just" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/just"
        rm -rf "$temp_file" "$extract_dir"
        log_success "just installed from GitHub"
    else
        log_error "Failed to download just"
        return 1
    fi
}

setup_just_completion() {
    log_step "Setting up just shell completion..."
    
    # Bash completion
    if [[ -d "$HOME/.bash_completion.d" ]] || mkdir -p "$HOME/.bash_completion.d"; then
        just --completions bash > "$HOME/.bash_completion.d/just.bash" 2>/dev/null
    fi
    
    # Zsh completion
    if [[ -d "$HOME/.zsh/completions" ]] || mkdir -p "$HOME/.zsh/completions"; then
        just --completions zsh > "$HOME/.zsh/completions/_just" 2>/dev/null
    fi
}

uninstall_just() {
    log_step "Uninstalling just..."
    rm -f "$LABRAT_BIN_DIR/just"
    rm -f "$HOME/.bash_completion.d/just.bash"
    rm -f "$HOME/.zsh/completions/_just"
    rm -f "${LABRAT_DATA_DIR}/installed/just"
    log_success "just uninstalled"
}
