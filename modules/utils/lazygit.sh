#!/usr/bin/env bash
#
# LabRat Module: lazygit
# Terminal UI for git commands
#

# Module metadata
LAZYGIT_GITHUB_REPO="jesseduffield/lazygit"

# ============================================================================
# Installation
# ============================================================================

install_lazygit() {
    log_step "Installing lazygit..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists lazygit; then
        installed_version=$(lazygit --version | grep -oP 'version=\K[\d.]+' || lazygit --version | awk -F',' '{print $3}' | tr -d ' version=')
        log_info "lazygit already installed (version: $installed_version)"
        
        if ! confirm "Reinstall/update lazygit?" "n"; then
            mark_module_installed "lazygit" "$installed_version"
            return 0
        fi
    fi
    
    # Install lazygit
    install_lazygit_binary
    
    # Get version
    installed_version=$(lazygit --version | grep -oP 'version=\K[\d.]+' 2>/dev/null || echo "latest")
    log_info "lazygit version: $installed_version"
    
    # Deploy config
    setup_lazygit_config
    
    # Mark as installed
    mark_module_installed "lazygit" "$installed_version"
    
    log_success "lazygit installed and configured!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_lazygit_binary() {
    log_step "Installing lazygit from GitHub releases..."
    
    local release_url="https://api.github.com/repos/${LAZYGIT_GITHUB_REPO}/releases/latest"
    local download_url=""
    local arch_pattern=""
    
    # Determine architecture pattern for download URL
    case "$ARCH" in
        amd64|x86_64)
            arch_pattern="Linux_x86_64"
            ;;
        arm64|aarch64)
            arch_pattern="Linux_arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Get latest release download URL using grep with extended regex
    download_url=$(curl -fsSL "$release_url" | \
        grep -o '"browser_download_url": *"[^"]*'"${arch_pattern}"'[^"]*\.tar\.gz"' | \
        head -1 | \
        sed 's/"browser_download_url": *"\([^"]*\)"/\1/')
    
    if [[ -z "$download_url" ]]; then
        # Fallback: construct URL directly from latest version
        local version
        version=$(curl -fsSL "$release_url" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"\([^"]*\)"/\1/')
        if [[ -n "$version" ]]; then
            download_url="https://github.com/${LAZYGIT_GITHUB_REPO}/releases/download/${version}/lazygit_${version#v}_${arch_pattern}.tar.gz"
            log_debug "Constructed download URL: $download_url"
        else
            log_error "Could not find download URL for lazygit"
            return 1
        fi
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/lazygit"
    download_and_extract "$download_url" "$extract_dir" "Downloading lazygit"
    
    # Copy binary
    if [[ -f "$extract_dir/lazygit" ]]; then
        cp "$extract_dir/lazygit" "$LABRAT_BIN_DIR/lazygit"
        chmod +x "$LABRAT_BIN_DIR/lazygit"
        log_success "lazygit installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find lazygit binary"
        return 1
    fi
}

# ============================================================================
# Configuration
# ============================================================================

setup_lazygit_config() {
    local config_dir="$HOME/.config/lazygit"
    local config_file="$config_dir/config.yml"
    
    ensure_dir "$config_dir"
    
    cat > "$config_file" << 'LAZYGIT_CONFIG'
# lazygit configuration (added by LabRat)

gui:
  theme:
    activeBorderColor:
      - "#89b4fa"
      - bold
    inactiveBorderColor:
      - "#6c7086"
    optionsTextColor:
      - "#89b4fa"
    selectedLineBgColor:
      - "#313244"
    selectedRangeBgColor:
      - "#313244"
    cherryPickedCommitBgColor:
      - "#45475a"
    cherryPickedCommitFgColor:
      - "#f5c2e7"
    unstagedChangesColor:
      - "#f38ba8"
    defaultFgColor:
      - "#cdd6f4"
    searchingActiveBorderColor:
      - "#f9e2af"
  
  showFileTree: true
  showRandomTip: false
  showIcons: true
  nerdFontsVersion: "3"
  
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
  
  autoFetch: true
  autoRefresh: true
  
os:
  editPreset: "nvim"

keybinding:
  universal:
    quit: q
    quit-alt1: <c-c>
LAZYGIT_CONFIG

    log_success "lazygit configuration deployed"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_lazygit() {
    log_step "Uninstalling lazygit..."
    
    rm -f "$LABRAT_BIN_DIR/lazygit"
    rm -rf "$HOME/.config/lazygit"
    rm -f "${LABRAT_DATA_DIR}/installed/lazygit"
    
    log_success "lazygit removed"
}
