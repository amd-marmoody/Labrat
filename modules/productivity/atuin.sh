#!/usr/bin/env bash
#
# LabRat Module: atuin
# Magical shell history - sync, search, and backup
# https://github.com/atuinsh/atuin
#

ATUIN_GITHUB_REPO="atuinsh/atuin"
ATUIN_CONFIG_DIR="${HOME}/.config/atuin"
ATUIN_THEME_DIR="${HOME}/.config/atuin/themes"

install_atuin() {
    log_step "Installing atuin..."
    
    if command_exists atuin; then
        local installed_version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
        log_info "atuin already installed (v${installed_version})"
        if ! confirm "Reinstall/update atuin?" "n"; then
            setup_atuin_integration
            mark_module_installed "atuin" "${installed_version}"
            return 0
        fi
    fi
    
    install_atuin_from_github
    
    if ! command_exists atuin; then
        log_error "atuin installation failed"
        return 1
    fi
    
    # Install bash-preexec for bash history capture
    install_bash_preexec
    
    local version=$(atuin --version 2>/dev/null | grep -oP '[\d.]+' | head -1)
    
    # Deploy configuration and themes
    deploy_atuin_config
    
    # Setup shell integration using new API
    setup_atuin_integration
    
    mark_module_installed "atuin" "${version:-unknown}"
    
    log_success "atuin installed successfully!"
    log_info "Run ${BOLD}atuin import auto${NC} to import existing history"
    log_info "Press ${BOLD}Ctrl+R${NC} for interactive search (up-arrow disabled by default)"
    log_info "Helper functions: ${BOLD}atuin-enable${NC}, ${BOLD}atuin-disable${NC}"
    log_info "Change theme with: ${BOLD}atuin-theme${NC}"
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_atuin_config() {
    log_step "Deploying atuin configuration..."
    
    # Create config directories
    ensure_dir "$ATUIN_CONFIG_DIR"
    ensure_dir "$ATUIN_THEME_DIR"
    
    # Source configs directory (LABRAT_CONFIGS_DIR is set by install.sh)
    local labrat_config_dir="${LABRAT_CONFIGS_DIR}/atuin"
    
    # Deploy main config file (don't overwrite if exists)
    if [[ -f "${labrat_config_dir}/config.toml" ]]; then
        if [[ ! -f "${ATUIN_CONFIG_DIR}/config.toml" ]]; then
            cp "${labrat_config_dir}/config.toml" "${ATUIN_CONFIG_DIR}/config.toml"
            log_success "Deployed atuin config.toml"
        else
            log_info "Atuin config already exists, skipping (use atuin-theme to change theme)"
        fi
    fi
    
    # Deploy all themes
    if [[ -d "${labrat_config_dir}/themes" ]]; then
        for theme_file in "${labrat_config_dir}/themes"/*.toml; do
            if [[ -f "$theme_file" ]]; then
                local theme_name=$(basename "$theme_file")
                cp "$theme_file" "${ATUIN_THEME_DIR}/${theme_name}"
            fi
        done
        log_success "Deployed atuin themes to ${ATUIN_THEME_DIR}"
    fi
}

# Install bash-preexec (required for atuin to capture commands in bash)
install_bash_preexec() {
    log_step "Installing bash-preexec (required for atuin in bash)..."
    
    local preexec_url="https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh"
    local preexec_path="$HOME/.bash-preexec.sh"
    
    if [[ -f "$preexec_path" ]]; then
        log_info "bash-preexec already installed"
        return 0
    fi
    
    if download_file "$preexec_url" "$preexec_path" "Downloading bash-preexec"; then
        log_success "bash-preexec installed to $preexec_path"
    else
        log_warn "Failed to download bash-preexec - atuin may not capture history in bash"
        return 1
    fi
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

# ============================================================================
# Shell Integration (using new modular API)
# ============================================================================

setup_atuin_integration() {
    log_step "Setting up atuin shell integration..."
    
    # Define helper functions for bash
    local bash_functions='
# Disable atuin history (use default Ctrl+R)
atuin-disable() {
    # Restore default bash history search
    bind '"'"'"\C-r": reverse-search-history'"'"'
    echo "atuin disabled. Using default Ctrl+R history search."
}

# Re-enable atuin (with optional up-arrow)
atuin-enable() {
    local with_up_arrow="${1:-}"
    if command -v atuin &>/dev/null; then
        if [[ "$with_up_arrow" == "--with-up-arrow" ]] || [[ "$with_up_arrow" == "-u" ]]; then
            eval "$(atuin init bash)"
            echo "atuin enabled with up-arrow binding!"
        else
            eval "$(atuin init bash --disable-up-arrow)"
            echo "atuin enabled! (use atuin-enable --with-up-arrow to enable up-arrow)"
        fi
    else
        echo "Error: atuin not found"
        return 1
    fi
}

# Show atuin stats
atuin-stats() {
    if command -v atuin &>/dev/null; then
        atuin stats
    fi
}

# Search history with atuin
atuin-search() {
    if command -v atuin &>/dev/null; then
        atuin search "$@"
    fi
}'

    # Define helper functions for zsh
    local zsh_functions='
# Disable atuin history
atuin-disable() {
    # Restore default zsh history search
    bindkey "^R" history-incremental-search-backward
    echo "atuin disabled. Using default Ctrl+R history search."
}

# Re-enable atuin (with optional up-arrow)
atuin-enable() {
    local with_up_arrow="${1:-}"
    if (( $+commands[atuin] )); then
        if [[ "$with_up_arrow" == "--with-up-arrow" ]] || [[ "$with_up_arrow" == "-u" ]]; then
            eval "$(atuin init zsh)"
            echo "atuin enabled with up-arrow binding!"
        else
            eval "$(atuin init zsh --disable-up-arrow)"
            echo "atuin enabled! (use atuin-enable --with-up-arrow to enable up-arrow)"
        fi
    else
        echo "Error: atuin not found"
        return 1
    fi
}

# Show atuin stats
atuin-stats() {
    if (( $+commands[atuin] )); then
        atuin stats
    fi
}

# Search history with atuin
atuin-search() {
    if (( $+commands[atuin] )); then
        atuin search "$@"
    fi
}'

    # Define helper functions for fish
    local fish_functions='
# Disable atuin
function atuin-disable
    # Remove atuin keybinding
    bind -e \cr
    echo "atuin disabled."
end

# Re-enable atuin (with optional up-arrow)
function atuin-enable
    set with_up_arrow $argv[1]
    if command -v atuin &>/dev/null
        if test "$with_up_arrow" = "--with-up-arrow" -o "$with_up_arrow" = "-u"
            atuin init fish | source
            echo "atuin enabled with up-arrow binding!"
        else
            atuin init fish --disable-up-arrow | source
            echo "atuin enabled! (use atuin-enable --with-up-arrow to enable up-arrow)"
        end
    else
        echo "Error: atuin not found"
        return 1
    end
end

# Show atuin stats
function atuin-stats
    if command -v atuin &>/dev/null
        atuin stats
    end
end'

    # Register shell integration using new modular API
    # NOTE: --disable-up-arrow is used by default to avoid conflicts with shell defaults
    # NOTE: bash-preexec must be sourced BEFORE atuin init for history capture to work
    register_shell_module "atuin" \
        --init-bash '[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh; eval "$(atuin init bash --disable-up-arrow)"' \
        --init-zsh 'eval "$(atuin init zsh --disable-up-arrow)"' \
        --init-fish 'atuin init fish --disable-up-arrow | source' \
        --functions-bash "$bash_functions" \
        --functions-zsh "$zsh_functions" \
        --functions-fish "$fish_functions" \
        --description "Shell history with sync and search"
    
    log_success "atuin shell integration configured"
}

uninstall_atuin() {
    log_step "Uninstalling atuin..."
    
    # Remove binary
    rm -f "$LABRAT_BIN_DIR/atuin"
    
    # Remove shell integration
    unregister_shell_module "atuin"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/atuin"
    
    # Optional: remove atuin data
    if [[ -d "$HOME/.local/share/atuin" ]]; then
        if confirm "Remove atuin data (~/.local/share/atuin)? This includes your synced history." "n"; then
            rm -rf "$HOME/.local/share/atuin"
            log_info "Removed atuin data"
        else
            log_info "Kept atuin data at ~/.local/share/atuin"
        fi
    fi
    
    log_success "atuin uninstalled"
    log_info "Your shell history data was preserved unless you chose to remove it"
}
