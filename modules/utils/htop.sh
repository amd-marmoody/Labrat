#!/usr/bin/env bash
#
# LabRat Module: htop
# Interactive process viewer
#

# ============================================================================
# Installation
# ============================================================================

install_htop() {
    log_step "Installing htop..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists htop; then
        installed_version=$(htop --version | head -1 | awk '{print $2}')
        log_info "htop already installed (version: $installed_version)"
        setup_htop_config
        mark_module_installed "htop" "$installed_version"
        return 0
    fi
    
    # Install htop via package manager
    pkg_install htop
    
    # Get version
    installed_version=$(htop --version | head -1 | awk '{print $2}')
    log_info "htop version: $installed_version"
    
    # Setup configuration
    setup_htop_config
    
    # Mark as installed
    mark_module_installed "htop" "$installed_version"
    
    log_success "htop installed and configured!"
}

# ============================================================================
# Configuration
# ============================================================================

setup_htop_config() {
    local config_dir="$HOME/.config/htop"
    local config_file="$config_dir/htoprc"
    
    ensure_dir "$config_dir"
    
    cat > "$config_file" << 'HTOP_CONFIG'
# htop configuration (added by LabRat)

# Fields displayed in the header
fields=0 48 17 18 38 39 40 2 46 47 49 1

# Sort by CPU percentage
sort_key=46
sort_direction=1

# Tree view
tree_view=1
tree_view_always_by_pid=0

# Hide kernel threads
hide_kernel_threads=1

# Hide userland threads
hide_userland_threads=0

# Show program path
show_program_path=1

# Highlight basename
highlight_base_name=1

# Highlight megabytes
highlight_megabytes=1

# Highlight threads
highlight_threads=1

# Show CPU percentage using color
cpu_count_from_one=0

# Update interval (in tenths of seconds)
update_process_names=0
delay=15

# Show custom thread names
show_thread_names=1

# Account guest time in CPU %
account_guest_in_cpu_meter=0

# Color scheme (0 = default, 1-6 = other schemes)
color_scheme=0

# Enable mouse
enable_mouse=1

# Header layout (3 columns)
header_layout=2

# Left column meters
column_meters_0=AllCPUs Memory Swap
column_meter_modes_0=1 1 1

# Right column meters
column_meters_1=Tasks LoadAverage Uptime
column_meter_modes_1=2 2 2
HTOP_CONFIG

    log_success "htop configuration deployed"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_htop() {
    log_step "Uninstalling htop configuration..."
    
    rm -rf "$HOME/.config/htop"
    rm -f "${LABRAT_DATA_DIR}/installed/htop"
    
    log_success "htop configuration removed"
    log_info "Note: htop binary was not removed (use package manager to uninstall)"
}
