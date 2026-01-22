#!/usr/bin/env bash
#
# LabRat Module: glances
# Cross-platform system monitoring tool with web UI support
# https://github.com/nicolargo/glances
#

# Module metadata
GLANCES_GITHUB_REPO="nicolargo/glances"

# ============================================================================
# Installation
# ============================================================================

install_glances() {
    log_step "Installing glances..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists glances; then
        installed_version=$(glances --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
        log_info "glances already installed (v${installed_version})"
        
        if ! confirm "Reinstall/update glances?" "n"; then
            mark_module_installed "glances" "${installed_version}"
            return 0
        fi
    fi
    
    # glances is best installed via pip for latest version
    # but also available in package managers
    
    local install_method="pip"
    
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]] && [[ -t 0 ]]; then
        echo ""
        echo "Glances installation options:"
        echo "  1) pip (recommended - latest version, web UI support)"
        echo "  2) Package manager (may be older version)"
        echo ""
        read -p "Select installation method [1-2] (default: 1): " choice
        case "$choice" in
            2) install_method="pkg" ;;
            *) install_method="pip" ;;
        esac
    fi
    
    case "$install_method" in
        pip)
            install_glances_pip
            ;;
        pkg)
            install_glances_pkg
            ;;
    esac
    
    # Verify installation
    if ! command_exists glances; then
        log_error "glances installation failed"
        return 1
    fi
    
    installed_version=$(glances --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
    
    # Deploy configuration
    deploy_glances_config
    
    # Mark as installed
    mark_module_installed "glances" "${installed_version:-unknown}"
    
    log_success "glances installed successfully!"
    log_info "Run ${BOLD}glances${NC} for TUI mode"
    log_info "Run ${BOLD}glances -w${NC} for web UI (http://localhost:61208)"
}

# ============================================================================
# pip Installation
# ============================================================================

install_glances_pip() {
    log_step "Installing glances via pip..."
    
    # Ensure pip is available
    if ! command_exists pip3 && ! command_exists pip; then
        log_info "Installing pip..."
        case "$OS_FAMILY" in
            debian)
                pkg_install python3-pip
                ;;
            rhel)
                pkg_install python3-pip
                ;;
            *)
                log_error "Cannot install pip on this system"
                return 1
                ;;
        esac
    fi
    
    local pip_cmd="pip3"
    command_exists pip3 || pip_cmd="pip"
    
    # Install glances with optional dependencies for full functionality
    # Using --user to install in user directory (no sudo needed)
    log_step "Installing glances with extras..."
    
    # Base installation with common extras
    $pip_cmd install --user --upgrade glances[web,docker,gpu]
    
    # Add ~/.local/bin to PATH hint
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log_warn "Add ~/.local/bin to your PATH:"
        log_info "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    
    log_success "glances installed via pip"
}

# ============================================================================
# Package Manager Installation
# ============================================================================

install_glances_pkg() {
    log_step "Installing glances via package manager..."
    
    case "$OS_FAMILY" in
        debian)
            pkg_install glances
            ;;
        rhel)
            # May need EPEL
            pkg_install glances || {
                log_warn "glances not in repos, trying pip..."
                install_glances_pip
            }
            ;;
        *)
            log_warn "Package manager not supported, using pip..."
            install_glances_pip
            ;;
    esac
}

# ============================================================================
# Configuration
# ============================================================================

deploy_glances_config() {
    log_step "Deploying glances configuration..."
    
    local config_dir="$HOME/.config/glances"
    ensure_dir "$config_dir"
    
    # Create a sensible default config if it doesn't exist
    if [[ ! -f "$config_dir/glances.conf" ]]; then
        cat > "$config_dir/glances.conf" << 'EOF'
##############################################################################
# Glances Configuration File
##############################################################################

[global]
# Refresh rate (in seconds)
refresh=2
# Check for update (true/false)
check_update=false

[outputs]
# Theme name (black, white or default)
curse_theme=black
# Enable bold mode (true/false)
bold=true

[quicklook]
# CPU percentage to trigger alert (default 50/70/90)
cpu_careful=50
cpu_warning=70
cpu_critical=90
# MEM percentage to trigger alert
mem_careful=50
mem_warning=70
mem_critical=90
# SWAP percentage to trigger alert
swap_careful=50
swap_warning=70
swap_critical=90

[cpu]
# Show individual CPU usage (true/false)
user_careful=50
user_warning=70
user_critical=90
system_careful=50
system_warning=70
system_critical=90
steal_careful=50
steal_warning=70
steal_critical=90

[percpu]
# Show per-CPU stats
enable=true

[gpu]
# Enable GPU monitoring
enable=true

[mem]
careful=50
warning=70
critical=90

[memswap]
careful=50
warning=70
critical=90

[load]
# Load average thresholds (per CPU core)
careful=0.7
warning=1.0
critical=5.0

[network]
# Hide loopback interface
hide=lo
# Network bandwidth thresholds (in Mb/s)
rx_careful=70
rx_warning=80
rx_critical=90
tx_careful=70
tx_warning=80
tx_critical=90

[diskio]
# Disk I/O thresholds (in bytes/s)
hide=loop.*,dm-.*

[fs]
# Filesystem thresholds (in percentage)
careful=50
warning=70
critical=90
# Hide filesystems (comma-separated)
hide=/boot.*,/snap.*

[folders]
# Monitor specific folders (optional)
# folder_1_path=/var/log
# folder_1_careful=2000
# folder_1_warning=3000
# folder_1_critical=4000

[sensors]
# Temperature sensor thresholds (in Celsius)
temperature_core_careful=60
temperature_core_warning=70
temperature_core_critical=80
temperature_hdd_careful=40
temperature_hdd_warning=45
temperature_hdd_critical=50

[processlist]
# Number of processes to display
max=50
# Sort by (auto, cpu, mem, user, time, io)
sort_key=auto

[docker]
# Enable Docker container monitoring
enable=true

[amps]
# Application Monitoring Process (custom process monitoring)
enable=true

[webserver]
# Web server configuration (for glances -w)
host=0.0.0.0
port=61208
# Password protection (optional)
# password=secret
EOF
        log_success "glances configuration created"
    else
        log_info "glances configuration already exists, skipping"
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_glances() {
    log_step "Uninstalling glances..."
    
    # Try pip first
    if command_exists pip3; then
        pip3 uninstall -y glances 2>/dev/null || true
    elif command_exists pip; then
        pip uninstall -y glances 2>/dev/null || true
    fi
    
    # Optionally remove config
    if confirm "Remove glances configuration?" "n"; then
        rm -rf "$HOME/.config/glances"
        log_success "Removed glances configuration"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/glances"
    
    log_success "glances uninstalled"
    log_info "Note: If installed via package manager, use 'apt remove glances' or 'dnf remove glances'"
}
