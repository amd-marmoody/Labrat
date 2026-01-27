#!/usr/bin/env bash
#
# LabRat Module: ssh-keys
# SSH Key Management - Secure key storage and agent integration
#

# Module metadata
LABRAT_SSH_DIR="${LABRAT_SSH_DIR:-$HOME/.ssh/labrat}"
LABRAT_SSH_CONFIG="$HOME/.ssh/config"
LABRAT_SSH_CONFIG_D="$HOME/.ssh/config.d"

# ============================================================================
# Security Messaging
# ============================================================================

show_security_info() {
    echo ""
    echo -e "${BOLD}${YELLOW}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}  ${BOLD}🔒 SECURITY INFORMATION${NC}                                                  ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}                                                                           ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}  Your private key will be:                                                ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}    ${GREEN}•${NC} Stored in: ${CYAN}~/.ssh/labrat/<key-name>${NC}                                  ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}    ${GREEN}•${NC} Permissions set to: ${CYAN}600${NC} (owner read/write only)                      ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}    ${GREEN}•${NC} ${BOLD}NOT${NC} transmitted anywhere - stays local on this machine               ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}    ${GREEN}•${NC} Added to ssh-agent on shell startup for passwordless auth            ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}                                                                           ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}  ${RED}⚠️  Never share your private key. Only the PUBLIC key should be shared.${NC}  ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}║${NC}                                                                           ${BOLD}${YELLOW}║${NC}"
    echo -e "${BOLD}${YELLOW}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_usage_instructions() {
    local key_name="$1"
    local key_path="${LABRAT_SSH_DIR}/${key_name}"
    
    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${GREEN}║${NC}  ${BOLD}✓ SSH Key Configured Successfully${NC}                                      ${BOLD}${GREEN}║${NC}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}📁 Key Location:${NC}    ${CYAN}${key_path}${NC}"
    echo -e "  ${BOLD}📋 Public Key:${NC}      ${CYAN}${key_path}.pub${NC}"
    echo -e "  ${BOLD}🔑 Permissions:${NC}     ${GREEN}600${NC} (owner read/write only)"
    echo ""
    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│${NC}  ${BOLD}📝 HOW TO USE YOUR SSH KEY${NC}                                             ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}├─────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BOLD}${CYAN}│${NC}                                                                         ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}  ${BOLD}1.${NC} Your key is ${GREEN}automatically loaded${NC} into ssh-agent on shell startup    ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     If your key has a passphrase, you'll be prompted on first use.      ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}                                                                         ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}  ${BOLD}2.${NC} To copy your ${BOLD}PUBLIC${NC} key (for GitHub, servers, etc.):                ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ cat ~/.ssh/labrat/${key_name}.pub${NC}                                    ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     or                                                                  ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ labrat-ssh show ${key_name}${NC}                                            ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}                                                                         ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}  ${BOLD}3.${NC} To test your connection (example for GitHub):                        ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ ssh -T git@github.com${NC}                                               ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}                                                                         ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}  ${BOLD}4.${NC} To manage SSH keys:                                                  ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ labrat-ssh list${NC}          # List all managed keys                   ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ labrat-ssh add${NC}           # Add a new key                          ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ labrat-ssh remove <name>${NC} # Remove a key                           ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}     ${YELLOW}\$ labrat-ssh show <name>${NC}   # Show public key                        ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}│${NC}                                                                         ${BOLD}${CYAN}│${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ============================================================================
# Installation
# ============================================================================

install_ssh_keys() {
    log_step "SSH Key Management Setup"
    
    # Ensure directories exist with proper permissions
    ensure_ssh_directories
    
    # Check for non-interactive mode
    if [[ "${SKIP_CONFIRM:-false}" == "true" ]] || [[ ! -t 0 ]]; then
        log_info "Non-interactive mode: skipping SSH key setup menu"
        log_info "Run 'labrat-ssh' after installation to manage SSH keys"
        
        # Setup shell integration (non-interactive part)
        setup_ssh_shell_integration
        
        # Mark as installed
        mark_module_installed "ssh-keys" "1.0.0"
        
        log_success "SSH key management configured!"
        log_info "Use 'labrat-ssh add' to add keys interactively"
        return 0
    fi
    
    # Show the main menu (interactive mode only)
    ssh_setup_menu
    
    # Setup shell integration
    setup_ssh_shell_integration
    
    # Mark as installed
    mark_module_installed "ssh-keys" "1.0.0"
    
    log_success "SSH key management configured!"
}

ensure_ssh_directories() {
    # Create main .ssh directory if it doesn't exist
    if [[ ! -d "$HOME/.ssh" ]]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        log_info "Created ~/.ssh directory"
    fi
    
    # Create labrat-managed SSH directory
    if [[ ! -d "$LABRAT_SSH_DIR" ]]; then
        mkdir -p "$LABRAT_SSH_DIR"
        chmod 700 "$LABRAT_SSH_DIR"
        log_info "Created $LABRAT_SSH_DIR directory"
    fi
    
    # Create config.d for modular config
    if [[ ! -d "$LABRAT_SSH_CONFIG_D" ]]; then
        mkdir -p "$LABRAT_SSH_CONFIG_D"
        chmod 700 "$LABRAT_SSH_CONFIG_D"
        log_info "Created $LABRAT_SSH_CONFIG_D directory"
    fi
}

# ============================================================================
# Main Setup Menu
# ============================================================================

ssh_setup_menu() {
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${CYAN}║${NC}  ${BOLD}LabRat SSH Key Management${NC}                                               ${BOLD}${CYAN}║${NC}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}🔐 SSH Key Setup${NC}"
    echo -e "${DIM}────────────────${NC}"
    echo ""
    echo "How would you like to configure SSH authentication?"
    echo ""
    echo -e "  ${BOLD}1)${NC} Paste an existing private key"
    echo -e "  ${BOLD}2)${NC} Specify path to an existing key file"
    echo -e "  ${BOLD}3)${NC} Generate a new ED25519 key"
    echo -e "  ${BOLD}4)${NC} Skip SSH setup"
    echo ""
    
    local choice
    read -p "Select option [1-4]: " choice
    
    case "$choice" in
        1)
            add_key_from_paste
            ;;
        2)
            add_key_from_path
            ;;
        3)
            generate_new_key
            ;;
        4)
            log_info "Skipping SSH setup"
            return 0
            ;;
        *)
            log_warn "Invalid choice, skipping SSH setup"
            return 0
            ;;
    esac
    
    # Ask if user wants to add another key
    echo ""
    if confirm "Would you like to add another SSH key?" "n"; then
        ssh_setup_menu
    fi
}

# ============================================================================
# Key Input Methods
# ============================================================================

add_key_from_paste() {
    show_security_info
    
    # Get key label
    local key_name
    read -p "Enter a label for this key (e.g., github, work, personal): " key_name
    key_name="${key_name:-default}"
    
    # Sanitize key name
    key_name=$(echo "$key_name" | tr -cd '[:alnum:]_-')
    
    if [[ -z "$key_name" ]]; then
        log_error "Invalid key name"
        return 1
    fi
    
    # Check if key already exists
    local key_path="${LABRAT_SSH_DIR}/${key_name}"
    if [[ -f "$key_path" ]]; then
        if ! confirm "Key '$key_name' already exists. Overwrite?" "n"; then
            log_info "Key not overwritten"
            return 0
        fi
    fi
    
    echo ""
    echo -e "${BOLD}Paste your private key below.${NC}"
    echo -e "${DIM}(Press Ctrl-D on an empty line when done)${NC}"
    echo ""
    
    # Read multi-line input
    local key_content=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        key_content+="$line"$'\n'
    done
    
    # Validate key format
    if ! validate_private_key "$key_content"; then
        log_error "Invalid SSH private key format"
        return 1
    fi
    
    # Save key with proper permissions
    save_private_key "$key_path" "$key_content"
    
    # Generate public key from private key
    generate_public_key_from_private "$key_path"
    
    # Add to SSH config
    prompt_ssh_config "$key_name"
    
    # Show usage instructions
    show_usage_instructions "$key_name"
}

add_key_from_path() {
    show_security_info
    
    # Get source path
    local source_path
    read -p "Enter path to existing private key: " source_path
    
    # Expand tilde
    source_path="${source_path/#\~/$HOME}"
    
    if [[ ! -f "$source_path" ]]; then
        log_error "File not found: $source_path"
        return 1
    fi
    
    # Read and validate key
    local key_content
    key_content=$(cat "$source_path")
    
    if ! validate_private_key "$key_content"; then
        log_error "Invalid SSH private key format in $source_path"
        return 1
    fi
    
    # Get key label
    local default_name
    default_name=$(basename "$source_path" | sed 's/^id_//')
    
    local key_name
    read -p "Enter a label for this key [${default_name}]: " key_name
    key_name="${key_name:-$default_name}"
    
    # Sanitize key name
    key_name=$(echo "$key_name" | tr -cd '[:alnum:]_-')
    
    if [[ -z "$key_name" ]]; then
        log_error "Invalid key name"
        return 1
    fi
    
    # Check if key already exists
    local key_path="${LABRAT_SSH_DIR}/${key_name}"
    if [[ -f "$key_path" ]]; then
        if ! confirm "Key '$key_name' already exists. Overwrite?" "n"; then
            log_info "Key not overwritten"
            return 0
        fi
    fi
    
    # Copy key with proper permissions
    save_private_key "$key_path" "$key_content"
    
    # Check for existing public key
    if [[ -f "${source_path}.pub" ]]; then
        cp "${source_path}.pub" "${key_path}.pub"
        chmod 644 "${key_path}.pub"
        log_info "Public key copied"
    else
        generate_public_key_from_private "$key_path"
    fi
    
    # Add to SSH config
    prompt_ssh_config "$key_name"
    
    # Show usage instructions
    show_usage_instructions "$key_name"
}

generate_new_key() {
    show_security_info
    
    echo ""
    echo -e "${BOLD}Generate New SSH Key${NC}"
    echo -e "${DIM}Using ED25519 (modern, secure, recommended)${NC}"
    echo ""
    
    # Get key label
    local key_name
    read -p "Enter a label for this key (e.g., github, work, personal): " key_name
    key_name="${key_name:-default}"
    
    # Sanitize key name
    key_name=$(echo "$key_name" | tr -cd '[:alnum:]_-')
    
    if [[ -z "$key_name" ]]; then
        log_error "Invalid key name"
        return 1
    fi
    
    # Check if key already exists
    local key_path="${LABRAT_SSH_DIR}/${key_name}"
    if [[ -f "$key_path" ]]; then
        if ! confirm "Key '$key_name' already exists. Overwrite?" "n"; then
            log_info "Key not generated"
            return 0
        fi
        rm -f "$key_path" "${key_path}.pub"
    fi
    
    # Get email for key comment
    local email
    read -p "Enter email for key comment (optional): " email
    email="${email:-labrat@$(hostname)}"
    
    # Ask about passphrase
    echo ""
    echo -e "${BOLD}Passphrase Protection${NC}"
    echo -e "${DIM}A passphrase adds an extra layer of security. You'll be prompted${NC}"
    echo -e "${DIM}to enter it the first time you use the key after login.${NC}"
    echo ""
    
    local use_passphrase
    if confirm "Add passphrase protection?" "y"; then
        use_passphrase="yes"
    else
        use_passphrase="no"
        echo -e "${YELLOW}⚠️  Key will be created without passphrase protection${NC}"
    fi
    
    # Generate key
    log_step "Generating ED25519 key..."
    
    if [[ "$use_passphrase" == "yes" ]]; then
        ssh-keygen -t ed25519 -C "$email" -f "$key_path"
    else
        ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N ""
    fi
    
    if [[ $? -eq 0 ]]; then
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        log_success "SSH key generated successfully"
        
        # Add to SSH config
        prompt_ssh_config "$key_name"
        
        # Show usage instructions
        show_usage_instructions "$key_name"
        
        # Show public key
        echo ""
        echo -e "${BOLD}Your public key (copy this to GitHub, servers, etc.):${NC}"
        echo -e "${CYAN}$(cat "${key_path}.pub")${NC}"
        echo ""
    else
        log_error "Failed to generate SSH key"
        return 1
    fi
}

# ============================================================================
# Key Validation and Storage
# ============================================================================

validate_private_key() {
    local key_content="$1"
    
    # Check for common private key headers
    if echo "$key_content" | grep -q "BEGIN OPENSSH PRIVATE KEY" || \
       echo "$key_content" | grep -q "BEGIN RSA PRIVATE KEY" || \
       echo "$key_content" | grep -q "BEGIN EC PRIVATE KEY" || \
       echo "$key_content" | grep -q "BEGIN DSA PRIVATE KEY"; then
        return 0
    fi
    
    return 1
}

save_private_key() {
    local key_path="$1"
    local key_content="$2"
    
    # Write key with restricted permissions
    echo "$key_content" > "$key_path"
    chmod 600 "$key_path"
    
    log_success "Private key saved to $key_path (permissions: 600)"
}

generate_public_key_from_private() {
    local key_path="$1"
    local pub_path="${key_path}.pub"
    
    # Generate public key from private
    if ssh-keygen -y -f "$key_path" > "$pub_path" 2>/dev/null; then
        chmod 644 "$pub_path"
        log_success "Public key generated: ${pub_path}"
    else
        log_warn "Could not generate public key (key may be encrypted)"
        log_info "You may need to enter your passphrase to extract the public key"
    fi
}

# ============================================================================
# SSH Config Management
# ============================================================================

prompt_ssh_config() {
    local key_name="$1"
    local key_path="${LABRAT_SSH_DIR}/${key_name}"
    
    echo ""
    echo -e "${BOLD}SSH Config Setup${NC}"
    echo -e "${DIM}Automatically add this key to your SSH config for specific hosts.${NC}"
    echo ""
    
    if ! confirm "Configure SSH hosts for this key?" "y"; then
        return 0
    fi
    
    local config_file="${LABRAT_SSH_CONFIG_D}/${key_name}.conf"
    
    echo ""
    echo "Common host patterns:"
    echo "  - github.com            (for GitHub)"
    echo "  - gitlab.com            (for GitLab)"  
    echo "  - *.internal.company    (wildcard for internal servers)"
    echo "  - server.example.com    (specific server)"
    echo ""
    
    local hosts
    read -p "Enter host pattern(s) (comma-separated, or press Enter to skip): " hosts
    
    if [[ -z "$hosts" ]]; then
        log_info "No hosts configured for this key"
        return 0
    fi
    
    # Create config file
    {
        echo "# LabRat SSH Config for: ${key_name}"
        echo "# Generated: $(date)"
        echo ""
        
        # Process each host
        IFS=',' read -ra HOST_ARRAY <<< "$hosts"
        for host in "${HOST_ARRAY[@]}"; do
            host=$(echo "$host" | xargs)  # Trim whitespace
            if [[ -n "$host" ]]; then
                echo "Host ${host}"
                echo "    IdentityFile ${key_path}"
                echo "    AddKeysToAgent yes"
                echo "    IdentitiesOnly yes"
                echo ""
            fi
        done
    } > "$config_file"
    
    chmod 600 "$config_file"
    log_success "SSH config created: $config_file"
    
    # Ensure main config includes config.d
    ensure_ssh_config_includes
}

ensure_ssh_config_includes() {
    local include_line="Include ~/.ssh/config.d/*.conf"
    
    # Create main config if it doesn't exist
    if [[ ! -f "$LABRAT_SSH_CONFIG" ]]; then
        {
            echo "# SSH Configuration"
            echo "# LabRat managed - includes config.d directory"
            echo ""
            echo "$include_line"
            echo ""
        } > "$LABRAT_SSH_CONFIG"
        chmod 600 "$LABRAT_SSH_CONFIG"
        log_success "Created SSH config with Include directive"
    elif ! grep -q "Include.*config\.d" "$LABRAT_SSH_CONFIG"; then
        # Add include at the beginning of the file
        local temp_file
        temp_file=$(mktemp)
        {
            echo "# LabRat managed SSH includes"
            echo "$include_line"
            echo ""
            cat "$LABRAT_SSH_CONFIG"
        } > "$temp_file"
        mv "$temp_file" "$LABRAT_SSH_CONFIG"
        chmod 600 "$LABRAT_SSH_CONFIG"
        log_success "Added Include directive to SSH config"
    fi
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_ssh_shell_integration() {
    log_step "Setting up SSH agent shell integration..."
    
    # Bash integration
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        if ! grep -q 'LabRat SSH Agent' "$bashrc"; then
            log_info "Adding SSH agent to .bashrc"
            {
                echo ""
                echo "# LabRat SSH Agent Management"
                echo "# Starts ssh-agent if not running and adds managed keys"
                echo 'if [ -z "$SSH_AUTH_SOCK" ]; then'
                echo '    eval "$(ssh-agent -s)" > /dev/null 2>&1'
                echo 'fi'
                echo ''
                echo '# Add labrat-managed SSH keys (prompts for passphrase on first use)'
                echo '_labrat_load_ssh_keys() {'
                echo '    local key_dir="$HOME/.ssh/labrat"'
                echo '    if [[ -d "$key_dir" ]]; then'
                echo '        for key in "$key_dir"/*; do'
                echo '            [[ -f "$key" && "$key" != *.pub ]] || continue'
                echo '            # Check if key is already loaded'
                echo '            local fingerprint'
                echo '            fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk "{print \$2}")'
                echo '            if [[ -n "$fingerprint" ]] && ! ssh-add -l 2>/dev/null | grep -q "$fingerprint"; then'
                echo '                ssh-add "$key" 2>/dev/null'
                echo '            fi'
                echo '        done'
                echo '    fi'
                echo '}'
                echo '_labrat_load_ssh_keys'
            } >> "$bashrc"
        fi
    fi
    
    # Zsh integration
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        if ! grep -q 'LabRat SSH Agent' "$zshrc"; then
            log_info "Adding SSH agent to .zshrc"
            {
                echo ""
                echo "# LabRat SSH Agent Management"
                echo "# Starts ssh-agent if not running and adds managed keys"
                echo 'if [ -z "$SSH_AUTH_SOCK" ]; then'
                echo '    eval "$(ssh-agent -s)" > /dev/null 2>&1'
                echo 'fi'
                echo ''
                echo '# Add labrat-managed SSH keys (prompts for passphrase on first use)'
                echo '_labrat_load_ssh_keys() {'
                echo '    local key_dir="$HOME/.ssh/labrat"'
                echo '    if [[ -d "$key_dir" ]]; then'
                echo '        for key in "$key_dir"/*; do'
                echo '            [[ -f "$key" && "$key" != *.pub ]] || continue'
                echo '            local fingerprint'
                echo '            fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk "{print \$2}")'
                echo '            if [[ -n "$fingerprint" ]] && ! ssh-add -l 2>/dev/null | grep -q "$fingerprint"; then'
                echo '                ssh-add "$key" 2>/dev/null'
                echo '            fi'
                echo '        done'
                echo '    fi'
                echo '}'
                echo '_labrat_load_ssh_keys'
            } >> "$zshrc"
        fi
    fi
    
    # Fish integration
    local fish_config="$HOME/.config/fish/config.fish"
    if [[ -f "$fish_config" ]]; then
        if ! grep -q 'LabRat SSH Agent' "$fish_config"; then
            log_info "Adding SSH agent to fish config"
            {
                echo ""
                echo "# LabRat SSH Agent Management"
                echo 'if test -z "$SSH_AUTH_SOCK"'
                echo '    eval (ssh-agent -c) > /dev/null 2>&1'
                echo 'end'
                echo ''
                echo '# Add labrat-managed SSH keys'
                echo 'function _labrat_load_ssh_keys'
                echo '    set key_dir "$HOME/.ssh/labrat"'
                echo '    if test -d "$key_dir"'
                echo '        for key in $key_dir/*'
                echo '            test -f "$key"; and not string match -q "*.pub" "$key"; or continue'
                echo '            set fingerprint (ssh-keygen -lf "$key" 2>/dev/null | awk "{print \$2}")'
                echo '            if test -n "$fingerprint"; and not ssh-add -l 2>/dev/null | grep -q "$fingerprint"'
                echo '                ssh-add "$key" 2>/dev/null'
                echo '            end'
                echo '        end'
                echo '    end'
                echo 'end'
                echo '_labrat_load_ssh_keys'
            } >> "$fish_config"
        fi
    fi
    
    log_success "SSH agent shell integration configured"
    log_info "Keys will be loaded automatically on shell startup"
    log_info "Passphrase-protected keys will prompt on first use"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_ssh_keys() {
    log_step "Uninstalling SSH key management..."
    
    if confirm "Remove all LabRat-managed SSH keys?" "n"; then
        if [[ -d "$LABRAT_SSH_DIR" ]]; then
            rm -rf "$LABRAT_SSH_DIR"
            log_success "Removed $LABRAT_SSH_DIR"
        fi
        
        if [[ -d "$LABRAT_SSH_CONFIG_D" ]]; then
            rm -rf "$LABRAT_SSH_CONFIG_D"
            log_success "Removed $LABRAT_SSH_CONFIG_D"
        fi
    else
        log_info "SSH keys preserved"
    fi
    
    rm -f "${LABRAT_DATA_DIR}/installed/ssh-keys"
    
    log_success "SSH key management removed"
    log_info "Note: Shell integration lines may need to be manually removed"
}
