#!/usr/bin/env bash
#
# LabRat Module: btop
# Modern resource monitor with mouse support and GPU monitoring
# https://github.com/aristocratos/btop
#

# Module metadata
BTOP_GITHUB_REPO="aristocratos/btop"

# ============================================================================
# Installation
# ============================================================================

install_btop() {
    log_step "Installing btop..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists btop; then
        installed_version=$(btop --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
        log_info "btop already installed (v${installed_version})"
        
        if ! confirm "Reinstall/update btop?" "n"; then
            mark_module_installed "btop" "${installed_version}"
            return 0
        fi
    fi
    
    # Try package manager first (may have older version)
    local pkg_installed=false
    
    case "$OS_FAMILY" in
        debian)
            # btop is available in Ubuntu 22.04+ and Debian 12+
            if pkg_install btop 2>/dev/null; then
                pkg_installed=true
            fi
            ;;
        rhel)
            # Try EPEL for RHEL-based systems
            if pkg_install btop 2>/dev/null; then
                pkg_installed=true
            fi
            ;;
    esac
    
    # If package manager failed or user wants latest, install from GitHub
    if [[ "$pkg_installed" != "true" ]]; then
        install_btop_from_github
    fi
    
    # Verify installation
    if ! command_exists btop; then
        log_error "btop installation failed"
        return 1
    fi
    
    installed_version=$(btop --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
    
    # Deploy configuration
    deploy_btop_config
    
    # Mark as installed
    mark_module_installed "btop" "${installed_version:-unknown}"
    
    log_success "btop installed successfully!"
    log_info "Run ${BOLD}btop${NC} to launch the resource monitor"
}

# ============================================================================
# GitHub Binary Installation
# ============================================================================

install_btop_from_github() {
    log_step "Installing btop from GitHub..."
    
    local latest_version
    latest_version=$(get_github_latest_release "$BTOP_GITHUB_REPO")
    
    if [[ -z "$latest_version" ]]; then
        log_error "Failed to get latest btop version"
        return 1
    fi
    
    log_info "Latest version: $latest_version"
    
    # Determine architecture
    local arch_suffix=""
    case "$ARCH" in
        x86_64|amd64)
            arch_suffix="x86_64"
            ;;
        aarch64|arm64)
            arch_suffix="aarch64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # btop releases use format: btop-x86_64-linux-musl.tbz
    local download_url="https://github.com/${BTOP_GITHUB_REPO}/releases/download/${latest_version}/btop-${arch_suffix}-linux-musl.tbz"
    local temp_file="${LABRAT_CACHE_DIR}/btop.tbz"
    local extract_dir="${LABRAT_CACHE_DIR}/btop"
    
    ensure_dir "$extract_dir"
    
    # Download
    if ! download_file "$download_url" "$temp_file" "Downloading btop"; then
        log_error "Failed to download btop"
        return 1
    fi
    
    # Extract (tbz = tar.bz2)
    log_step "Extracting btop..."
    tar -xjf "$temp_file" -C "$extract_dir"
    
    # Install binary
    if [[ -f "$extract_dir/btop/bin/btop" ]]; then
        cp "$extract_dir/btop/bin/btop" "$LABRAT_BIN_DIR/"
        chmod +x "$LABRAT_BIN_DIR/btop"
        log_success "btop binary installed to $LABRAT_BIN_DIR"
    else
        log_error "btop binary not found in archive"
        rm -rf "$temp_file" "$extract_dir"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_file" "$extract_dir"
    
    log_success "btop installed from GitHub"
}

# ============================================================================
# Configuration
# ============================================================================

deploy_btop_config() {
    log_step "Deploying btop configuration..."
    
    local config_dir="$HOME/.config/btop"
    ensure_dir "$config_dir"
    
    # Create a sensible default config if it doesn't exist
    if [[ ! -f "$config_dir/btop.conf" ]]; then
        cat > "$config_dir/btop.conf" << 'EOF'
#? Config file for btop v. 1.2.13

#* Color theme, see /usr/share/btop/themes for available themes
color_theme = "Default"

#* If the theme set above is not found, use this as fallback
theme_background = False

#* Sets if 24-bit truecolor should be used
truecolor = True

#* Set to true to force tty mode regardless if a real tty is detected
force_tty = False

#* Define presets for the layout
presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty"

#* Set to True to enable vim keys for navigation
vim_keys = True

#* Rounded corners on boxes
rounded_corners = True

#* Default symbols to use for graph creation
graph_symbol = "braille"

#* Show boxes
shown_boxes = "cpu mem net proc"

#* Update time in milliseconds
update_ms = 1000

#* Processes sorting
proc_sorting = "cpu lazy"

#* Reverse sorting order
proc_reversed = False

#* Show processes as a tree
proc_tree = False

#* Use the cpu graph colors in the process list
proc_colors = True

#* Use a darkening gradient in the process list
proc_gradient = True

#* If process cpu usage should be of the core it's running on or total
proc_per_core = False

#* Show process memory as bytes instead of percent
proc_mem_bytes = True

#* Show cpu graph for each process
proc_cpu_graphs = True

#* Filter processes tied to init (PID 1)
proc_filter_kernel = False

#* Show GPU info
show_gpu_info = "Auto"

#* Which gpu to use for gpu stats
gpu_mirror_graph = True

#* Manually set which Network interface to use
net_iface = ""

#* Show battery stats in top right corner
show_battery = True

#* Which battery to show stats for
selected_battery = "Auto"

#* Set loglevel for the log file
log_level = "WARNING"
EOF
        log_success "btop configuration created"
    else
        log_info "btop configuration already exists, skipping"
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_btop() {
    log_step "Uninstalling btop..."
    
    # Remove binary if installed by us
    if [[ -f "$LABRAT_BIN_DIR/btop" ]]; then
        rm -f "$LABRAT_BIN_DIR/btop"
        log_success "Removed btop binary"
    fi
    
    # Optionally remove config
    if confirm "Remove btop configuration?" "n"; then
        rm -rf "$HOME/.config/btop"
        log_success "Removed btop configuration"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/btop"
    
    log_success "btop uninstalled"
    log_info "Note: If installed via package manager, use 'apt remove btop' or 'dnf remove btop'"
}
