#!/usr/bin/env bash
#
# LabRat Module: nethogs
# NetHogs - Linux 'net top' tool grouping bandwidth by process
# https://github.com/raboof/nethogs
#

install_nethogs() {
    log_step "Installing nethogs..."
    
    if command_exists nethogs; then
        log_info "nethogs already installed"
        if ! confirm "Reinstall nethogs?" "n"; then
            mark_module_installed "nethogs" "installed"
            return 0
        fi
    fi
    
    case "$OS_FAMILY" in
        debian)
            pkg_install nethogs
            ;;
        rhel)
            pkg_install nethogs || { pkg_install epel-release && pkg_install nethogs; }
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            return 1
            ;;
    esac
    
    if ! command_exists nethogs; then
        log_error "nethogs installation failed"
        return 1
    fi
    
    mark_module_installed "nethogs" "installed"
    log_success "nethogs installed successfully!"
    log_info "Run ${BOLD}sudo nethogs${NC} to monitor bandwidth by process"
}

uninstall_nethogs() {
    log_step "Uninstalling nethogs..."
    rm -f "${LABRAT_DATA_DIR}/installed/nethogs"
    log_success "nethogs marker removed"
    log_info "Use package manager to remove: apt remove nethogs / dnf remove nethogs"
}
