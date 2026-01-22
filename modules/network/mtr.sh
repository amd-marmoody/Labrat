#!/usr/bin/env bash
#
# LabRat Module: mtr
# Combines traceroute and ping in a single network diagnostic tool
# https://www.bitwizard.nl/mtr/
#

install_mtr() {
    log_step "Installing mtr..."
    
    if command_exists mtr; then
        log_info "mtr already installed"
        if ! confirm "Reinstall mtr?" "n"; then
            mark_module_installed "mtr" "installed"
            return 0
        fi
    fi
    
    case "$OS_FAMILY" in
        debian)
            pkg_install mtr-tiny || pkg_install mtr
            ;;
        rhel)
            pkg_install mtr
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            return 1
            ;;
    esac
    
    if ! command_exists mtr; then
        log_error "mtr installation failed"
        return 1
    fi
    
    mark_module_installed "mtr" "installed"
    log_success "mtr installed successfully!"
    log_info "Run ${BOLD}mtr google.com${NC} for interactive traceroute"
    log_info "Run ${BOLD}mtr -r google.com${NC} for report mode"
}

uninstall_mtr() {
    log_step "Uninstalling mtr..."
    rm -f "${LABRAT_DATA_DIR}/installed/mtr"
    log_success "mtr marker removed"
    log_info "Use package manager to remove: apt remove mtr / dnf remove mtr"
}
