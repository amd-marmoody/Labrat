#!/usr/bin/env bash
#
# LabRat Module: ncdu
# NCurses Disk Usage - interactive disk usage analyzer
# https://dev.yorhel.nl/ncdu
#

# ============================================================================
# Installation
# ============================================================================

install_ncdu() {
    log_step "Installing ncdu..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists ncdu; then
        installed_version=$(ncdu --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
        log_info "ncdu already installed (v${installed_version})"
        
        if ! confirm "Reinstall/update ncdu?" "n"; then
            mark_module_installed "ncdu" "${installed_version}"
            return 0
        fi
    fi
    
    # ncdu is widely available in package managers
    case "$OS_FAMILY" in
        debian)
            pkg_install ncdu
            ;;
        rhel)
            pkg_install ncdu || pkg_install epel-release && pkg_install ncdu
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            return 1
            ;;
    esac
    
    # Verify installation
    if ! command_exists ncdu; then
        log_error "ncdu installation failed"
        return 1
    fi
    
    installed_version=$(ncdu --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
    
    # Mark as installed
    mark_module_installed "ncdu" "${installed_version:-unknown}"
    
    log_success "ncdu installed successfully!"
    log_info "Run ${BOLD}ncdu${NC} to analyze disk usage interactively"
    log_info "Run ${BOLD}ncdu /path/to/dir${NC} to scan a specific directory"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_ncdu() {
    log_step "Uninstalling ncdu..."
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/ncdu"
    
    log_success "ncdu marker removed"
    log_info "Use package manager to remove: apt remove ncdu / dnf remove ncdu"
}
