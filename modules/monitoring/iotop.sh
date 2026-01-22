#!/usr/bin/env bash
#
# LabRat Module: iotop
# I/O monitoring tool - shows I/O usage by process
# https://github.com/Tomas-M/iotop (iotop-c) or classic iotop
#

install_iotop() {
    log_step "Installing iotop..."
    
    if command_exists iotop; then
        log_info "iotop already installed"
        if ! confirm "Reinstall iotop?" "n"; then
            mark_module_installed "iotop" "installed"
            return 0
        fi
    fi
    
    case "$OS_FAMILY" in
        debian)
            pkg_install iotop
            ;;
        rhel)
            pkg_install iotop || { pkg_install epel-release && pkg_install iotop; }
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            return 1
            ;;
    esac
    
    if ! command_exists iotop; then
        log_error "iotop installation failed"
        return 1
    fi
    
    mark_module_installed "iotop" "installed"
    log_success "iotop installed successfully!"
    log_info "Run ${BOLD}sudo iotop${NC} to monitor I/O by process"
    log_info "Run ${BOLD}sudo iotop -o${NC} to show only processes doing I/O"
}

uninstall_iotop() {
    log_step "Uninstalling iotop..."
    rm -f "${LABRAT_DATA_DIR}/installed/iotop"
    log_success "iotop marker removed"
    log_info "Use package manager to remove: apt remove iotop / dnf remove iotop"
}
