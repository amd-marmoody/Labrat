#!/usr/bin/env bash
#
# LabRat Module: nmap
# Network exploration tool and security/port scanner
# https://nmap.org/
#

install_nmap() {
    log_step "Installing nmap..."
    
    if command_exists nmap; then
        local installed_version=$(nmap --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
        log_info "nmap already installed (v${installed_version})"
        if ! confirm "Reinstall nmap?" "n"; then
            mark_module_installed "nmap" "${installed_version}"
            return 0
        fi
    fi
    
    case "$OS_FAMILY" in
        debian)
            pkg_install nmap
            ;;
        rhel)
            pkg_install nmap
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            return 1
            ;;
    esac
    
    if ! command_exists nmap; then
        log_error "nmap installation failed"
        return 1
    fi
    
    local version=$(nmap --version 2>/dev/null | head -1 | grep -oP '[\d.]+' | head -1)
    mark_module_installed "nmap" "${version:-unknown}"
    
    log_success "nmap installed successfully!"
    log_info "Run ${BOLD}nmap -sP 192.168.1.0/24${NC} for host discovery"
    log_info "Run ${BOLD}nmap -sV hostname${NC} for service detection"
}

uninstall_nmap() {
    log_step "Uninstalling nmap..."
    rm -f "${LABRAT_DATA_DIR}/installed/nmap"
    log_success "nmap marker removed"
    log_info "Use package manager to remove: apt remove nmap / dnf remove nmap"
}
