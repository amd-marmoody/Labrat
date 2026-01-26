#!/usr/bin/env bash
#
# LabRat - Enhanced Shell Integration Management
# Modular shell integration with support for multiple shells and clean uninstall
#
# This library provides:
# - Per-module shell snippets in ~/.config/labrat/modules/{bash,zsh,fish}/
# - register_shell_module() / unregister_shell_module() API
# - Automatic sourcing of all module snippets
# - Backup and restore of original shell configs
# - Migration from legacy direct-append style
#

# shellcheck source=./common.sh
source "${LABRAT_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/common.sh"

# ============================================================================
# Shell Configuration Paths
# ============================================================================

# Main labrat shell config directory
LABRAT_SHELL_CONFIG_DIR="${LABRAT_CONFIG_DIR}/labrat"

# Per-shell main config files (sourced from user's rc files)
LABRAT_BASH_RC="${LABRAT_SHELL_CONFIG_DIR}/bashrc.sh"
LABRAT_ZSH_RC="${LABRAT_SHELL_CONFIG_DIR}/zshrc.sh"
LABRAT_FISH_RC="${LABRAT_SHELL_CONFIG_DIR}/config.fish"

# Modular per-module snippets directory
LABRAT_SHELL_MODULES_DIR="${LABRAT_SHELL_CONFIG_DIR}/modules"
LABRAT_BASH_MODULES_DIR="${LABRAT_SHELL_MODULES_DIR}/bash"
LABRAT_ZSH_MODULES_DIR="${LABRAT_SHELL_MODULES_DIR}/zsh"
LABRAT_FISH_MODULES_DIR="${LABRAT_SHELL_MODULES_DIR}/fish"

# Backup directories
LABRAT_SHELL_BACKUP_DIR="${LABRAT_DATA_DIR}/shell_backups"
LABRAT_ORIGINAL_BACKUP_DIR="${LABRAT_SHELL_BACKUP_DIR}/original"
LABRAT_CURRENT_BACKUP_DIR="${LABRAT_SHELL_BACKUP_DIR}/current"

# Legacy compatibility (for migration)
LABRAT_LEGACY_SHELL_RC="${LABRAT_SHELL_CONFIG_DIR}/shellrc.sh"

# ============================================================================
# Directory Setup
# ============================================================================

# Ensure all shell integration directories exist
ensure_shell_dirs() {
    ensure_dir "$LABRAT_SHELL_CONFIG_DIR"
    ensure_dir "$LABRAT_SHELL_MODULES_DIR"
    ensure_dir "$LABRAT_BASH_MODULES_DIR"
    ensure_dir "$LABRAT_ZSH_MODULES_DIR"
    ensure_dir "$LABRAT_FISH_MODULES_DIR"
    ensure_dir "$LABRAT_SHELL_BACKUP_DIR"
    ensure_dir "$LABRAT_ORIGINAL_BACKUP_DIR"
    ensure_dir "$LABRAT_CURRENT_BACKUP_DIR"
}

# ============================================================================
# Backup Functions
# ============================================================================

# Backup original shell config files (one-time, before any LabRat modifications)
# These are preserved forever and never overwritten
backup_original_shell_configs() {
    ensure_shell_dirs
    
    local backed_up=0
    
    # Backup bashrc if exists and not already backed up
    if [[ -f "$HOME/.bashrc" ]] && [[ ! -f "${LABRAT_ORIGINAL_BACKUP_DIR}/bashrc" ]]; then
        cp "$HOME/.bashrc" "${LABRAT_ORIGINAL_BACKUP_DIR}/bashrc"
        log_debug "Backed up original ~/.bashrc"
        ((backed_up++))
    fi
    
    # Backup zshrc if exists and not already backed up
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -f "${LABRAT_ORIGINAL_BACKUP_DIR}/zshrc" ]]; then
        cp "$HOME/.zshrc" "${LABRAT_ORIGINAL_BACKUP_DIR}/zshrc"
        log_debug "Backed up original ~/.zshrc"
        ((backed_up++))
    fi
    
    # Backup profile if exists and not already backed up
    if [[ -f "$HOME/.profile" ]] && [[ ! -f "${LABRAT_ORIGINAL_BACKUP_DIR}/profile" ]]; then
        cp "$HOME/.profile" "${LABRAT_ORIGINAL_BACKUP_DIR}/profile"
        log_debug "Backed up original ~/.profile"
        ((backed_up++))
    fi
    
    # Backup bash_profile if exists and not already backed up
    if [[ -f "$HOME/.bash_profile" ]] && [[ ! -f "${LABRAT_ORIGINAL_BACKUP_DIR}/bash_profile" ]]; then
        cp "$HOME/.bash_profile" "${LABRAT_ORIGINAL_BACKUP_DIR}/bash_profile"
        log_debug "Backed up original ~/.bash_profile"
        ((backed_up++))
    fi
    
    # Backup fish config if exists and not already backed up
    if [[ -f "$HOME/.config/fish/config.fish" ]] && [[ ! -f "${LABRAT_ORIGINAL_BACKUP_DIR}/config.fish" ]]; then
        cp "$HOME/.config/fish/config.fish" "${LABRAT_ORIGINAL_BACKUP_DIR}/config.fish"
        log_debug "Backed up original ~/.config/fish/config.fish"
        ((backed_up++))
    fi
    
    if [[ $backed_up -gt 0 ]]; then
        log_success "Backed up $backed_up original shell config(s) to ${LABRAT_ORIGINAL_BACKUP_DIR}/"
    fi
}

# Backup current shell configs (called periodically, can be overwritten)
# Useful for restoring to a known-good labrat state
backup_current_shell_configs() {
    ensure_shell_dirs
    
    [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "${LABRAT_CURRENT_BACKUP_DIR}/bashrc"
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "${LABRAT_CURRENT_BACKUP_DIR}/zshrc"
    [[ -f "$HOME/.profile" ]] && cp "$HOME/.profile" "${LABRAT_CURRENT_BACKUP_DIR}/profile"
    [[ -f "$HOME/.bash_profile" ]] && cp "$HOME/.bash_profile" "${LABRAT_CURRENT_BACKUP_DIR}/bash_profile"
    [[ -f "$HOME/.config/fish/config.fish" ]] && cp "$HOME/.config/fish/config.fish" "${LABRAT_CURRENT_BACKUP_DIR}/config.fish"
    
    log_debug "Current shell configs backed up to ${LABRAT_CURRENT_BACKUP_DIR}/"
}

# Restore original shell configs (for complete uninstall)
restore_original_shell_configs() {
    local restored=0
    
    if [[ -f "${LABRAT_ORIGINAL_BACKUP_DIR}/bashrc" ]]; then
        cp "${LABRAT_ORIGINAL_BACKUP_DIR}/bashrc" "$HOME/.bashrc"
        log_success "Restored original ~/.bashrc"
        ((restored++))
    fi
    
    if [[ -f "${LABRAT_ORIGINAL_BACKUP_DIR}/zshrc" ]]; then
        cp "${LABRAT_ORIGINAL_BACKUP_DIR}/zshrc" "$HOME/.zshrc"
        log_success "Restored original ~/.zshrc"
        ((restored++))
    fi
    
    if [[ -f "${LABRAT_ORIGINAL_BACKUP_DIR}/profile" ]]; then
        cp "${LABRAT_ORIGINAL_BACKUP_DIR}/profile" "$HOME/.profile"
        log_success "Restored original ~/.profile"
        ((restored++))
    fi
    
    if [[ -f "${LABRAT_ORIGINAL_BACKUP_DIR}/bash_profile" ]]; then
        cp "${LABRAT_ORIGINAL_BACKUP_DIR}/bash_profile" "$HOME/.bash_profile"
        log_success "Restored original ~/.bash_profile"
        ((restored++))
    fi
    
    if [[ -f "${LABRAT_ORIGINAL_BACKUP_DIR}/config.fish" ]]; then
        ensure_dir "$HOME/.config/fish"
        cp "${LABRAT_ORIGINAL_BACKUP_DIR}/config.fish" "$HOME/.config/fish/config.fish"
        log_success "Restored original ~/.config/fish/config.fish"
        ((restored++))
    fi
    
    if [[ $restored -gt 0 ]]; then
        log_success "Restored $restored original shell config(s)"
    else
        log_warn "No original backups found to restore"
    fi
    
    return $restored
}

# ============================================================================
# Main Shell Config Generation
# ============================================================================

# Generate the main labrat shell config for bash
# This file sources all module snippets and is sourced from ~/.bashrc
generate_bash_main_config() {
    ensure_shell_dirs
    
    cat > "$LABRAT_BASH_RC" << 'BASH_MAIN'
#!/usr/bin/env bash
#
# LabRat Shell Configuration (Bash)
# Auto-generated by LabRat installer - do not edit directly
#
# This file is sourced from ~/.bashrc and loads all LabRat module integrations
#

# ============================================================================
# PATH Configuration
# ============================================================================

# Add LabRat bin directory to PATH (if not already present)
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ============================================================================
# Module Integrations
# ============================================================================

# Source all bash module snippets
LABRAT_BASH_MODULES="${XDG_CONFIG_HOME:-$HOME/.config}/labrat/modules/bash"
if [[ -d "$LABRAT_BASH_MODULES" ]]; then
    for module_file in "$LABRAT_BASH_MODULES"/*.sh; do
        if [[ -f "$module_file" ]]; then
            # shellcheck source=/dev/null
            source "$module_file"
        fi
    done
    unset module_file
fi
unset LABRAT_BASH_MODULES
BASH_MAIN

    chmod +x "$LABRAT_BASH_RC"
    log_debug "Generated bash main config: $LABRAT_BASH_RC"
}

# Generate the main labrat shell config for zsh
generate_zsh_main_config() {
    ensure_shell_dirs
    
    cat > "$LABRAT_ZSH_RC" << 'ZSH_MAIN'
#!/usr/bin/env zsh
#
# LabRat Shell Configuration (Zsh)
# Auto-generated by LabRat installer - do not edit directly
#
# This file is sourced from ~/.zshrc and loads all LabRat module integrations
#

# ============================================================================
# PATH Configuration
# ============================================================================

# Add LabRat bin directory to PATH (if not already present)
if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# ============================================================================
# Module Integrations
# ============================================================================

# Source all zsh module snippets
LABRAT_ZSH_MODULES="${XDG_CONFIG_HOME:-$HOME/.config}/labrat/modules/zsh"
if [[ -d "$LABRAT_ZSH_MODULES" ]]; then
    for module_file in "$LABRAT_ZSH_MODULES"/*.zsh(N); do
        if [[ -f "$module_file" ]]; then
            source "$module_file"
        fi
    done
    unset module_file
fi
unset LABRAT_ZSH_MODULES
ZSH_MAIN

    chmod +x "$LABRAT_ZSH_RC"
    log_debug "Generated zsh main config: $LABRAT_ZSH_RC"
}

# Generate the main labrat shell config for fish
generate_fish_main_config() {
    ensure_shell_dirs
    
    cat > "$LABRAT_FISH_RC" << 'FISH_MAIN'
#
# LabRat Shell Configuration (Fish)
# Auto-generated by LabRat installer - do not edit directly
#
# This file is sourced from ~/.config/fish/config.fish and loads all LabRat module integrations
#

# ============================================================================
# PATH Configuration
# ============================================================================

# Add LabRat bin directory to PATH (if not already present)
if test -d "$HOME/.local/bin"
    if not contains "$HOME/.local/bin" $PATH
        set -gx PATH "$HOME/.local/bin" $PATH
    end
end

# ============================================================================
# Module Integrations
# ============================================================================

# Source all fish module snippets
set -l labrat_fish_modules "$HOME/.config/labrat/modules/fish"
if test -d "$labrat_fish_modules"
    for module_file in $labrat_fish_modules/*.fish
        if test -f "$module_file"
            source "$module_file"
        end
    end
end
FISH_MAIN

    chmod +x "$LABRAT_FISH_RC"
    log_debug "Generated fish main config: $LABRAT_FISH_RC"
}

# Generate all main shell configs
generate_all_main_configs() {
    generate_bash_main_config
    generate_zsh_main_config
    generate_fish_main_config
    
    # Create legacy symlink for compatibility
    if [[ ! -f "$LABRAT_LEGACY_SHELL_RC" ]]; then
        ln -sf "$LABRAT_BASH_RC" "$LABRAT_LEGACY_SHELL_RC"
    fi
}

# ============================================================================
# Module Registration API
# ============================================================================

# Register a module's shell integration
# Creates per-shell snippet files that are automatically sourced
#
# Usage:
#   register_shell_module "module_name" \
#       --init-bash 'eval "$(tool init bash)"' \
#       --init-zsh 'eval "$(tool init zsh)"' \
#       --init-fish 'tool init fish | source' \
#       --functions-bash 'function toggle() { ... }' \
#       --functions-zsh 'function toggle() { ... }' \
#       --functions-fish 'function toggle ... end'
#
# Or simplified:
#   register_shell_module "module_name" \
#       --init 'eval "$(tool init $SHELL_TYPE)"' \
#       --functions 'function toggle() { ... }'
#
register_shell_module() {
    local module_name="$1"
    shift
    
    if [[ -z "$module_name" ]]; then
        log_error "register_shell_module: module name required"
        return 1
    fi
    
    ensure_shell_dirs
    
    local init_bash="" init_zsh="" init_fish=""
    local funcs_bash="" funcs_zsh="" funcs_fish=""
    local description=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --init-bash)
                init_bash="$2"
                shift 2
                ;;
            --init-zsh)
                init_zsh="$2"
                shift 2
                ;;
            --init-fish)
                init_fish="$2"
                shift 2
                ;;
            --init)
                # Generic init for all shells (bash/zsh compatible)
                init_bash="$2"
                init_zsh="$2"
                shift 2
                ;;
            --functions-bash)
                funcs_bash="$2"
                shift 2
                ;;
            --functions-zsh)
                funcs_zsh="$2"
                shift 2
                ;;
            --functions-fish)
                funcs_fish="$2"
                shift 2
                ;;
            --functions)
                # Generic functions for bash/zsh (usually compatible)
                funcs_bash="$2"
                funcs_zsh="$2"
                shift 2
                ;;
            --description)
                description="$2"
                shift 2
                ;;
            *)
                log_warn "register_shell_module: unknown option '$1'"
                shift
                ;;
        esac
    done
    
    local header_comment="# LabRat module: ${module_name}"
    [[ -n "$description" ]] && header_comment="${header_comment} - ${description}"
    header_comment="${header_comment}
# Auto-generated - do not edit directly"

    # Create bash module snippet
    if [[ -n "$init_bash" ]] || [[ -n "$funcs_bash" ]]; then
        local bash_file="${LABRAT_BASH_MODULES_DIR}/${module_name}.sh"
        {
            echo "#!/usr/bin/env bash"
            echo "$header_comment"
            echo ""
            
            if [[ -n "$init_bash" ]]; then
                echo "# Initialization"
                echo "if command -v ${module_name} &>/dev/null; then"
                echo "    $init_bash"
                echo "fi"
                echo ""
            fi
            
            if [[ -n "$funcs_bash" ]]; then
                echo "# Helper functions"
                echo "$funcs_bash"
            fi
        } > "$bash_file"
        chmod +x "$bash_file"
        log_debug "Created bash module: $bash_file"
    fi
    
    # Create zsh module snippet
    if [[ -n "$init_zsh" ]] || [[ -n "$funcs_zsh" ]]; then
        local zsh_file="${LABRAT_ZSH_MODULES_DIR}/${module_name}.zsh"
        {
            echo "#!/usr/bin/env zsh"
            echo "$header_comment"
            echo ""
            
            if [[ -n "$init_zsh" ]]; then
                echo "# Initialization"
                echo 'if (( $+commands['"${module_name}"'] )); then'
                echo "    $init_zsh"
                echo "fi"
                echo ""
            fi
            
            if [[ -n "$funcs_zsh" ]]; then
                echo "# Helper functions"
                echo "$funcs_zsh"
            fi
        } > "$zsh_file"
        chmod +x "$zsh_file"
        log_debug "Created zsh module: $zsh_file"
    fi
    
    # Create fish module snippet
    if [[ -n "$init_fish" ]] || [[ -n "$funcs_fish" ]]; then
        local fish_file="${LABRAT_FISH_MODULES_DIR}/${module_name}.fish"
        {
            echo "# ${header_comment}"
            echo ""
            
            if [[ -n "$init_fish" ]]; then
                echo "# Initialization"
                echo "if command -v ${module_name} &>/dev/null"
                echo "    $init_fish"
                echo "end"
                echo ""
            fi
            
            if [[ -n "$funcs_fish" ]]; then
                echo "# Helper functions"
                echo "$funcs_fish"
            fi
        } > "$fish_file"
        chmod +x "$fish_file"
        log_debug "Created fish module: $fish_file"
    fi
    
    log_success "Registered shell module: $module_name"
}

# Unregister a module's shell integration
# Removes all per-shell snippet files for the module
unregister_shell_module() {
    local module_name="$1"
    
    if [[ -z "$module_name" ]]; then
        log_error "unregister_shell_module: module name required"
        return 1
    fi
    
    local removed=0
    
    # Remove bash module
    if [[ -f "${LABRAT_BASH_MODULES_DIR}/${module_name}.sh" ]]; then
        rm -f "${LABRAT_BASH_MODULES_DIR}/${module_name}.sh"
        log_debug "Removed bash module: ${module_name}.sh"
        ((removed++))
    fi
    
    # Remove zsh module
    if [[ -f "${LABRAT_ZSH_MODULES_DIR}/${module_name}.zsh" ]]; then
        rm -f "${LABRAT_ZSH_MODULES_DIR}/${module_name}.zsh"
        log_debug "Removed zsh module: ${module_name}.zsh"
        ((removed++))
    fi
    
    # Remove fish module
    if [[ -f "${LABRAT_FISH_MODULES_DIR}/${module_name}.fish" ]]; then
        rm -f "${LABRAT_FISH_MODULES_DIR}/${module_name}.fish"
        log_debug "Removed fish module: ${module_name}.fish"
        ((removed++))
    fi
    
    if [[ $removed -gt 0 ]]; then
        log_success "Unregistered shell module: $module_name"
    else
        log_debug "No shell integration found for module: $module_name"
    fi
    
    return 0
}

# List all registered shell modules
list_shell_modules() {
    local modules=()
    
    # Collect unique module names from all shell directories
    for file in "${LABRAT_BASH_MODULES_DIR}"/*.sh 2>/dev/null; do
        [[ -f "$file" ]] && modules+=("$(basename "$file" .sh)")
    done
    
    for file in "${LABRAT_ZSH_MODULES_DIR}"/*.zsh 2>/dev/null; do
        local name=$(basename "$file" .zsh)
        if [[ ! " ${modules[*]} " =~ " ${name} " ]]; then
            modules+=("$name")
        fi
    done
    
    for file in "${LABRAT_FISH_MODULES_DIR}"/*.fish 2>/dev/null; do
        local name=$(basename "$file" .fish)
        if [[ ! " ${modules[*]} " =~ " ${name} " ]]; then
            modules+=("$name")
        fi
    done
    
    # Sort and print
    printf '%s\n' "${modules[@]}" | sort -u
}

# Check if a module has shell integration registered
is_shell_module_registered() {
    local module_name="$1"
    
    [[ -f "${LABRAT_BASH_MODULES_DIR}/${module_name}.sh" ]] || \
    [[ -f "${LABRAT_ZSH_MODULES_DIR}/${module_name}.zsh" ]] || \
    [[ -f "${LABRAT_FISH_MODULES_DIR}/${module_name}.fish" ]]
}

# ============================================================================
# Shell RC File Management
# ============================================================================

# Add LabRat source line to user's shell config
# This is the hook that loads labrat's shell integration
install_shell_hook() {
    local shell_type="${1:-bash}"
    local shell_rc=""
    local labrat_rc=""
    
    case "$shell_type" in
        bash)
            shell_rc="$HOME/.bashrc"
            labrat_rc="$LABRAT_BASH_RC"
            ;;
        zsh)
            shell_rc="$HOME/.zshrc"
            labrat_rc="$LABRAT_ZSH_RC"
            ;;
        fish)
            shell_rc="$HOME/.config/fish/config.fish"
            labrat_rc="$LABRAT_FISH_RC"
            ensure_dir "$(dirname "$shell_rc")"
            ;;
        *)
            log_error "Unknown shell type: $shell_type"
            return 1
            ;;
    esac
    
    # Create rc file if it doesn't exist
    if [[ ! -f "$shell_rc" ]]; then
        touch "$shell_rc"
        log_info "Created $shell_rc"
    fi
    
    # Check if already hooked
    if grep -qF "# LabRat shell integration" "$shell_rc" 2>/dev/null; then
        log_debug "LabRat hook already present in $shell_rc"
        return 0
    fi
    
    # Add the hook
    local source_cmd
    if [[ "$shell_type" == "fish" ]]; then
        source_cmd="source \"$labrat_rc\"  # LabRat shell integration"
    else
        source_cmd="[[ -f \"$labrat_rc\" ]] && source \"$labrat_rc\"  # LabRat shell integration"
    fi
    
    # For bash, try to insert after interactive check; otherwise prepend
    if [[ "$shell_type" == "bash" ]]; then
        local temp_file=$(mktemp)
        local inserted=false
        
        # Try to insert after "esac" (end of interactive check)
        while IFS= read -r line || [[ -n "$line" ]]; do
            echo "$line" >> "$temp_file"
            if [[ "$line" == "esac" ]] && [[ "$inserted" == "false" ]]; then
                echo "" >> "$temp_file"
                echo "# LabRat: Load shell configuration" >> "$temp_file"
                echo "$source_cmd" >> "$temp_file"
                echo "" >> "$temp_file"
                inserted=true
            fi
        done < "$shell_rc"
        
        # If esac not found, prepend
        if [[ "$inserted" == "false" ]]; then
            {
                echo "# LabRat: Load shell configuration"
                echo "$source_cmd"
                echo ""
                cat "$shell_rc"
            } > "$temp_file"
        fi
        
        mv "$temp_file" "$shell_rc"
    else
        # For zsh and fish, prepend
        local temp_file=$(mktemp)
        {
            echo "# LabRat: Load shell configuration"
            echo "$source_cmd"
            echo ""
            cat "$shell_rc"
        } > "$temp_file"
        mv "$temp_file" "$shell_rc"
    fi
    
    log_success "Installed LabRat hook in $shell_rc"
}

# Remove LabRat hook from user's shell config
remove_shell_hook() {
    local shell_type="${1:-bash}"
    local shell_rc=""
    
    case "$shell_type" in
        bash) shell_rc="$HOME/.bashrc" ;;
        zsh)  shell_rc="$HOME/.zshrc" ;;
        fish) shell_rc="$HOME/.config/fish/config.fish" ;;
        *)    return 1 ;;
    esac
    
    if [[ ! -f "$shell_rc" ]]; then
        return 0
    fi
    
    # Remove labrat-related lines
    local temp_file=$(mktemp)
    grep -v "LabRat shell integration\|LabRat: Load shell configuration" "$shell_rc" > "$temp_file" 2>/dev/null || true
    mv "$temp_file" "$shell_rc"
    
    log_info "Removed LabRat hook from $shell_rc"
}

# ============================================================================
# Migration from Legacy System
# ============================================================================

# Migrate from the old direct-append style to the new modular system
migrate_legacy_shell_integration() {
    log_step "Checking for legacy shell integration..."
    
    local migrated=0
    
    # Check for old-style direct additions in .bashrc
    if grep -q "# .* (added by LabRat)" "$HOME/.bashrc" 2>/dev/null; then
        log_info "Found legacy LabRat entries in .bashrc"
        # We don't auto-remove these, just warn the user
        log_warn "Legacy entries found in ~/.bashrc - these will be superseded by the new modular system"
        log_info "You can manually remove lines marked '(added by LabRat)' after verifying the new system works"
        ((migrated++))
    fi
    
    # Check for old-style direct additions in .zshrc
    if grep -q "# .* (added by LabRat)" "$HOME/.zshrc" 2>/dev/null; then
        log_info "Found legacy LabRat entries in .zshrc"
        log_warn "Legacy entries found in ~/.zshrc - these will be superseded by the new modular system"
        log_info "You can manually remove lines marked '(added by LabRat)' after verifying the new system works"
        ((migrated++))
    fi
    
    # Remove old legacy symlink if it points to old location
    if [[ -L "$LABRAT_LEGACY_SHELL_RC" ]]; then
        local target=$(readlink "$LABRAT_LEGACY_SHELL_RC")
        if [[ "$target" != "$LABRAT_BASH_RC" ]]; then
            rm -f "$LABRAT_LEGACY_SHELL_RC"
            ln -sf "$LABRAT_BASH_RC" "$LABRAT_LEGACY_SHELL_RC"
            log_debug "Updated legacy shellrc.sh symlink"
        fi
    fi
    
    if [[ $migrated -gt 0 ]]; then
        log_info "Migration check complete - legacy entries found but preserved for safety"
    else
        log_debug "No legacy entries found"
    fi
}

# Clean legacy shell integration entries from rc files
# Call this only when user explicitly wants to clean up
clean_legacy_shell_integration() {
    log_step "Cleaning legacy shell integration entries..."
    
    local cleaned=0
    
    for rc_file in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [[ -f "$rc_file" ]] && grep -q "# .* (added by LabRat)" "$rc_file"; then
            local temp_file=$(mktemp)
            grep -v "(added by LabRat)" "$rc_file" > "$temp_file"
            mv "$temp_file" "$rc_file"
            log_success "Cleaned legacy entries from $rc_file"
            ((cleaned++))
        fi
    done
    
    if [[ $cleaned -eq 0 ]]; then
        log_info "No legacy entries to clean"
    fi
}

# ============================================================================
# Full Setup / Teardown
# ============================================================================

# Complete shell integration setup
# Called during labrat installation
setup_shell_integration() {
    log_step "Setting up shell integration..."
    
    # Ensure directories exist
    ensure_shell_dirs
    
    # Backup original configs (one-time)
    backup_original_shell_configs
    
    # Generate main shell configs
    generate_all_main_configs
    
    # Install hooks in user's shell configs
    if [[ -f "$HOME/.bashrc" ]] || [[ "$SHELL" == *"bash"* ]]; then
        install_shell_hook "bash"
    fi
    
    if [[ -f "$HOME/.zshrc" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        install_shell_hook "zsh"
    fi
    
    # Only install fish hook if fish is present
    if command_exists fish && [[ -f "$HOME/.config/fish/config.fish" ]]; then
        install_shell_hook "fish"
    fi
    
    # Check for legacy entries and migrate
    migrate_legacy_shell_integration
    
    # Backup current state
    backup_current_shell_configs
    
    log_success "Shell integration configured!"
    log_info "Config directory: $LABRAT_SHELL_CONFIG_DIR"
    log_info "Module snippets: $LABRAT_SHELL_MODULES_DIR"
}

# Complete uninstall of shell integration
# Removes all labrat shell configs and optionally restores originals
uninstall_shell_integration() {
    log_step "Removing shell integration..."
    
    # Remove hooks from user shell configs
    remove_shell_hook "bash"
    remove_shell_hook "zsh"
    remove_shell_hook "fish"
    
    # Remove all module snippets
    rm -rf "$LABRAT_SHELL_MODULES_DIR"
    
    # Remove main labrat shell configs
    rm -f "$LABRAT_BASH_RC"
    rm -f "$LABRAT_ZSH_RC"
    rm -f "$LABRAT_FISH_RC"
    rm -f "$LABRAT_LEGACY_SHELL_RC"
    
    log_success "Shell integration removed"
}

# Full restore to original state
# Removes all labrat components and restores original shell configs
restore_to_original() {
    log_step "Restoring to original state..."
    
    # Remove shell integration
    uninstall_shell_integration
    
    # Restore original configs
    restore_original_shell_configs
    
    # Remove labrat config directory
    rm -rf "$LABRAT_SHELL_CONFIG_DIR"
    
    log_success "Restored to original pre-LabRat state"
}

# ============================================================================
# Compatibility Wrappers
# ============================================================================

# Legacy function - wraps new API for backward compatibility
# Usage: add_shell_integration "tool_name" "bash_cmd" "zsh_cmd" "fish_cmd" "comment"
add_shell_integration() {
    local tool_name="$1"
    local bash_cmd="${2:-}"
    local zsh_cmd="${3:-$bash_cmd}"
    local fish_cmd="${4:-}"
    local comment="${5:-$tool_name initialization}"
    
    register_shell_module "$tool_name" \
        --init-bash "$bash_cmd" \
        --init-zsh "$zsh_cmd" \
        --init-fish "$fish_cmd" \
        --description "$comment"
}

# Legacy function - wraps new API for backward compatibility
# Usage: add_shell_functions "name" "bash_functions" "zsh_functions" "fish_functions"
add_shell_functions() {
    local name="$1"
    local bash_funcs="${2:-}"
    local zsh_funcs="${3:-$bash_funcs}"
    local fish_funcs="${4:-}"
    
    # Check if module already registered, update it with functions
    if is_shell_module_registered "$name"; then
        # Append to existing files
        [[ -n "$bash_funcs" ]] && echo -e "\n# Additional functions\n$bash_funcs" >> "${LABRAT_BASH_MODULES_DIR}/${name}.sh"
        [[ -n "$zsh_funcs" ]] && echo -e "\n# Additional functions\n$zsh_funcs" >> "${LABRAT_ZSH_MODULES_DIR}/${name}.zsh"
        [[ -n "$fish_funcs" ]] && echo -e "\n# Additional functions\n$fish_funcs" >> "${LABRAT_FISH_MODULES_DIR}/${name}.fish"
    else
        # Create new module with just functions
        register_shell_module "$name" \
            --functions-bash "$bash_funcs" \
            --functions-zsh "$zsh_funcs" \
            --functions-fish "$fish_funcs"
    fi
}

# Legacy function - wraps new API
remove_shell_integration() {
    local tool_name="$1"
    unregister_shell_module "$tool_name"
}

# ============================================================================
# Utility Functions
# ============================================================================

# Show status of shell integration
shell_integration_status() {
    echo ""
    echo -e "${BOLD}LabRat Shell Integration Status${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    # Check config directory
    if [[ -d "$LABRAT_SHELL_CONFIG_DIR" ]]; then
        echo -e "Config directory: ${GREEN}✓${NC} $LABRAT_SHELL_CONFIG_DIR"
    else
        echo -e "Config directory: ${RED}✗${NC} Not found"
    fi
    
    # Check main configs
    for shell in bash zsh fish; do
        local rc_var="LABRAT_${shell^^}_RC"
        local rc_file="${!rc_var}"
        if [[ -f "$rc_file" ]]; then
            echo -e "  ${shell} config: ${GREEN}✓${NC} $(basename "$rc_file")"
        else
            echo -e "  ${shell} config: ${DIM}✗${NC} Not generated"
        fi
    done
    
    echo ""
    
    # Check hooks in user configs
    echo "Shell hooks:"
    for shell in bash zsh; do
        local rc_file="$HOME/.${shell}rc"
        if [[ -f "$rc_file" ]] && grep -q "LabRat shell integration" "$rc_file" 2>/dev/null; then
            echo -e "  ~/.${shell}rc: ${GREEN}✓${NC} Hook installed"
        elif [[ -f "$rc_file" ]]; then
            echo -e "  ~/.${shell}rc: ${YELLOW}○${NC} No hook"
        else
            echo -e "  ~/.${shell}rc: ${DIM}✗${NC} File not found"
        fi
    done
    
    # Fish config
    local fish_rc="$HOME/.config/fish/config.fish"
    if [[ -f "$fish_rc" ]] && grep -q "LabRat shell integration" "$fish_rc" 2>/dev/null; then
        echo -e "  config.fish: ${GREEN}✓${NC} Hook installed"
    elif [[ -f "$fish_rc" ]]; then
        echo -e "  config.fish: ${YELLOW}○${NC} No hook"
    fi
    
    echo ""
    
    # List registered modules
    local modules=($(list_shell_modules))
    if [[ ${#modules[@]} -gt 0 ]]; then
        echo "Registered modules (${#modules[@]}):"
        for module in "${modules[@]}"; do
            local shells=""
            [[ -f "${LABRAT_BASH_MODULES_DIR}/${module}.sh" ]] && shells+="bash "
            [[ -f "${LABRAT_ZSH_MODULES_DIR}/${module}.zsh" ]] && shells+="zsh "
            [[ -f "${LABRAT_FISH_MODULES_DIR}/${module}.fish" ]] && shells+="fish"
            echo -e "  ${CYAN}${module}${NC}: $shells"
        done
    else
        echo -e "Registered modules: ${DIM}None${NC}"
    fi
    
    echo ""
    
    # Check backups
    echo "Backups:"
    if [[ -d "$LABRAT_ORIGINAL_BACKUP_DIR" ]] && [[ -n "$(ls -A "$LABRAT_ORIGINAL_BACKUP_DIR" 2>/dev/null)" ]]; then
        echo -e "  Original: ${GREEN}✓${NC} $LABRAT_ORIGINAL_BACKUP_DIR"
    else
        echo -e "  Original: ${YELLOW}○${NC} Not yet backed up"
    fi
    
    if [[ -d "$LABRAT_CURRENT_BACKUP_DIR" ]] && [[ -n "$(ls -A "$LABRAT_CURRENT_BACKUP_DIR" 2>/dev/null)" ]]; then
        echo -e "  Current:  ${GREEN}✓${NC} $LABRAT_CURRENT_BACKUP_DIR"
    else
        echo -e "  Current:  ${DIM}○${NC} Not yet backed up"
    fi
    
    echo ""
}
