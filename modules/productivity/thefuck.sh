#!/usr/bin/env bash
#
# LabRat Module: thefuck
# Corrects your previous console command
# https://github.com/nvbn/thefuck
#

install_thefuck() {
    log_step "Installing thefuck..."
    
    if command_exists thefuck; then
        log_info "thefuck already installed"
        if ! confirm "Reinstall/update thefuck?" "n"; then
            mark_module_installed "thefuck" "installed"
            return 0
        fi
    fi
    
    # thefuck is best installed via pip
    if ! command_exists pip3 && ! command_exists pip; then
        log_info "Installing pip..."
        case "$OS_FAMILY" in
            debian) pkg_install python3-pip ;;
            rhel) pkg_install python3-pip ;;
            *) log_error "Cannot install pip on this system"; return 1 ;;
        esac
    fi
    
    local pip_cmd="pip3"
    command_exists pip3 || pip_cmd="pip"
    
    log_step "Installing thefuck via pip..."
    $pip_cmd install --user --upgrade thefuck
    
    if ! command_exists thefuck && [[ -f "$HOME/.local/bin/thefuck" ]]; then
        # Make sure ~/.local/bin is in PATH
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    if ! command_exists thefuck; then
        log_error "thefuck installation failed"
        return 1
    fi
    
    mark_module_installed "thefuck" "installed"
    
    # Setup shell integration
    setup_thefuck_shell
    
    log_success "thefuck installed successfully!"
    log_info "Type ${BOLD}fuck${NC} after a failed command to correct it"
}

setup_thefuck_shell() {
    log_step "Setting up thefuck shell integration..."
    
    # Bash
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q "thefuck --alias" "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# thefuck command corrector" >> "$bashrc"
        echo 'eval "$(thefuck --alias)"' >> "$bashrc"
        log_info "Added thefuck to .bashrc"
    fi
    
    # Zsh
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]] && ! grep -q "thefuck --alias" "$zshrc"; then
        echo "" >> "$zshrc"
        echo "# thefuck command corrector" >> "$zshrc"
        echo 'eval "$(thefuck --alias)"' >> "$zshrc"
        log_info "Added thefuck to .zshrc"
    fi
}

uninstall_thefuck() {
    log_step "Uninstalling thefuck..."
    
    if command_exists pip3; then
        pip3 uninstall -y thefuck 2>/dev/null || true
    elif command_exists pip; then
        pip uninstall -y thefuck 2>/dev/null || true
    fi
    
    rm -f "${LABRAT_DATA_DIR}/installed/thefuck"
    log_success "thefuck uninstalled"
    log_info "Remove 'eval \"\$(thefuck --alias)\"' from your shell config"
}
