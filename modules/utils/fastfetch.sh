#!/usr/bin/env bash
#
# LabRat Module: fastfetch
# Fast neofetch alternative for system info display
#

# Module metadata
FASTFETCH_GITHUB_REPO="fastfetch-cli/fastfetch"

# ============================================================================
# Installation
# ============================================================================

install_fastfetch() {
    log_step "Installing fastfetch..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists fastfetch; then
        installed_version=$(fastfetch --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
        log_info "fastfetch already installed (v${installed_version})"
    else
        # Try package manager first
        case "$OS_FAMILY" in
            debian)
                # Ubuntu PPA or direct package
                if [[ "$OS" == "ubuntu" ]]; then
                    # Try PPA for latest version
                    if confirm "Add fastfetch PPA for latest version?" "y"; then
                        sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch 2>/dev/null || true
                        pkg_update
                    fi
                fi
                if ! pkg_install fastfetch; then
                    install_fastfetch_from_github
                fi
                ;;
            rhel)
                if ! pkg_install fastfetch; then
                    install_fastfetch_from_github
                fi
                ;;
            *)
                install_fastfetch_from_github
                ;;
        esac
        
        installed_version=$(fastfetch --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
    fi
    
    # Deploy configurations
    deploy_fastfetch_config
    
    # Configure shell startup (optional)
    configure_fastfetch_startup
    
    # Mark as installed
    mark_module_installed "fastfetch" "${installed_version:-unknown}"
    
    log_success "fastfetch installed and configured!"
    log_info "Run ${BOLD}fastfetch${NC} for full output"
    log_info "Run ${BOLD}fastfetch -c ~/.config/fastfetch/config-minimal.jsonc${NC} for minimal output"
}

# ============================================================================
# GitHub Binary Installation
# ============================================================================

install_fastfetch_from_github() {
    log_step "Installing fastfetch from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$FASTFETCH_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest fastfetch version"
        return 1
    fi
    
    log_info "Latest version: $latest_version"
    
    # Determine architecture and package type
    local arch_suffix=""
    local pkg_type=""
    
    case "$ARCH" in
        x86_64|amd64)
            arch_suffix="amd64"
            ;;
        aarch64|arm64)
            arch_suffix="aarch64"
            ;;
        armv7l|armhf)
            arch_suffix="armv7l"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Prefer deb/rpm packages, fall back to binary
    case "$OS_FAMILY" in
        debian)
            pkg_type="deb"
            local download_url="https://github.com/${FASTFETCH_GITHUB_REPO}/releases/download/${latest_version}/fastfetch-linux-${arch_suffix}.deb"
            local temp_file="${LABRAT_CACHE_DIR}/fastfetch.deb"
            
            if download_file "$download_url" "$temp_file" "Downloading fastfetch"; then
                sudo dpkg -i "$temp_file" || sudo apt-get install -f -y
                rm -f "$temp_file"
            else
                log_error "Failed to download fastfetch"
                return 1
            fi
            ;;
        rhel)
            pkg_type="rpm"
            local download_url="https://github.com/${FASTFETCH_GITHUB_REPO}/releases/download/${latest_version}/fastfetch-linux-${arch_suffix}.rpm"
            local temp_file="${LABRAT_CACHE_DIR}/fastfetch.rpm"
            
            if download_file "$download_url" "$temp_file" "Downloading fastfetch"; then
                sudo rpm -i "$temp_file" || sudo dnf install -y "$temp_file"
                rm -f "$temp_file"
            else
                log_error "Failed to download fastfetch"
                return 1
            fi
            ;;
        *)
            # Generic binary installation
            local download_url="https://github.com/${FASTFETCH_GITHUB_REPO}/releases/download/${latest_version}/fastfetch-linux-${arch_suffix}.tar.gz"
            local temp_file="${LABRAT_CACHE_DIR}/fastfetch.tar.gz"
            local extract_dir="${LABRAT_CACHE_DIR}/fastfetch"
            
            ensure_dir "$extract_dir"
            
            if download_file "$download_url" "$temp_file" "Downloading fastfetch"; then
                tar -xzf "$temp_file" -C "$extract_dir"
                cp "$extract_dir/fastfetch-linux-${arch_suffix}/usr/bin/fastfetch" "$LABRAT_BIN_DIR/"
                chmod +x "$LABRAT_BIN_DIR/fastfetch"
                rm -rf "$temp_file" "$extract_dir"
            else
                log_error "Failed to download fastfetch"
                return 1
            fi
            ;;
    esac
    
    log_success "fastfetch installed from GitHub"
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_fastfetch_config() {
    log_step "Deploying fastfetch configuration..."
    
    local config_dir="$HOME/.config/fastfetch"
    local source_dir="${LABRAT_CONFIGS_DIR}/fastfetch"
    
    ensure_dir "$config_dir"
    
    # Copy full config
    if [[ -f "${source_dir}/config.jsonc" ]]; then
        cp "${source_dir}/config.jsonc" "${config_dir}/config.jsonc"
        log_success "Full config deployed"
    fi
    
    # Copy minimal config
    if [[ -f "${source_dir}/config-minimal.jsonc" ]]; then
        cp "${source_dir}/config-minimal.jsonc" "${config_dir}/config-minimal.jsonc"
        log_success "Minimal config deployed"
    fi
    
    # Copy all logo files
    local logo_count=0
    for logo_file in "${source_dir}"/logo*.txt "${source_dir}"/labrat-logo.txt; do
        if [[ -f "$logo_file" ]]; then
            cp "$logo_file" "${config_dir}/"
            ((logo_count++))
        fi
    done
    
    if ((logo_count > 0)); then
        log_success "Deployed $logo_count logo files"
        log_info "Available logos:"
        log_info "  • logo-knife-rat.txt (default - rat with knife 🔪)"
        log_info "  • labrat-logo.txt (original)"
        log_info "  • logo-option1-5.txt (alternatives)"
    fi
    
    log_info "Configs deployed to ${config_dir}"
}

# ============================================================================
# Shell Startup Integration
# ============================================================================

configure_fastfetch_startup() {
    local enable_startup="${LABRAT_FASTFETCH_STARTUP:-}"
    
    # Interactive prompt if not pre-configured
    if [[ -z "$enable_startup" ]] && [[ "${SKIP_CONFIRMATION:-false}" != "true" ]] && [[ -t 0 ]]; then
        echo ""
        if confirm "Run fastfetch on shell startup (SSH login)?" "n"; then
            enable_startup="true"
        else
            enable_startup="false"
        fi
    fi
    
    if [[ "$enable_startup" == "true" ]]; then
        add_fastfetch_to_shell
    else
        log_info "Shell startup integration skipped"
    fi
}

add_fastfetch_to_shell() {
    log_step "Adding fastfetch to shell startup..."
    
    local startup_snippet='
# LabRat: fastfetch on login
if command -v fastfetch &>/dev/null && [[ $- == *i* ]] && [[ -z "$TMUX" ]]; then
    fastfetch --config ~/.config/fastfetch/config-minimal.jsonc 2>/dev/null
fi
'
    
    local marker="# LabRat: fastfetch on login"
    
    # Add to .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "$marker" "$HOME/.bashrc"; then
            echo "$startup_snippet" >> "$HOME/.bashrc"
            log_success "Added to .bashrc"
        else
            log_info "Already in .bashrc"
        fi
    fi
    
    # Add to .zshrc if it exists
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "$marker" "$HOME/.zshrc"; then
            echo "$startup_snippet" >> "$HOME/.zshrc"
            log_success "Added to .zshrc"
        else
            log_info "Already in .zshrc"
        fi
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_fastfetch() {
    log_step "Uninstalling fastfetch..."
    
    # Remove config directory
    rm -rf "$HOME/.config/fastfetch"
    
    # Remove from shell startup
    local marker="# LabRat: fastfetch on login"
    
    if [[ -f "$HOME/.bashrc" ]]; then
        sed -i "/$marker/,/^fi$/d" "$HOME/.bashrc" 2>/dev/null || true
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        sed -i "/$marker/,/^fi$/d" "$HOME/.zshrc" 2>/dev/null || true
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/fastfetch"
    
    log_success "fastfetch configuration removed"
    log_info "Note: fastfetch binary was not removed (use package manager to uninstall)"
}
