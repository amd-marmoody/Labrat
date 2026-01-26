#!/usr/bin/env bash
#
# LabRat - Module State Management
# Handles enable/disable state for shell integrations
#

# shellcheck source=./common.sh
source "${LABRAT_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/common.sh"

# ============================================================================
# State Directory Setup
# ============================================================================

LABRAT_STATE_DIR="${LABRAT_CONFIG_DIR}/labrat/state"
LABRAT_STATE_ENABLED_DIR="${LABRAT_STATE_DIR}/enabled"
LABRAT_STATE_DISABLED_DIR="${LABRAT_STATE_DIR}/disabled"

# Ensure state directories exist
ensure_state_dirs() {
    ensure_dir "$LABRAT_STATE_DIR"
    ensure_dir "$LABRAT_STATE_ENABLED_DIR"
    ensure_dir "$LABRAT_STATE_DISABLED_DIR"
}

# ============================================================================
# Module State Functions
# ============================================================================

# Check if a module is enabled (default: enabled if installed)
is_module_enabled() {
    local module="$1"
    
    # If explicitly disabled, return false
    if [[ -f "${LABRAT_STATE_DISABLED_DIR}/${module}" ]]; then
        return 1
    fi
    
    # If installed, it's enabled by default
    if is_module_installed "$module" 2>/dev/null; then
        return 0
    fi
    
    # If explicitly enabled marker exists
    if [[ -f "${LABRAT_STATE_ENABLED_DIR}/${module}" ]]; then
        return 0
    fi
    
    return 1
}

# Enable a module's shell integration
enable_module() {
    local module="$1"
    
    ensure_state_dirs
    
    # Remove from disabled if present
    rm -f "${LABRAT_STATE_DISABLED_DIR}/${module}"
    
    # Add to enabled
    echo "enabled $(date -Iseconds)" > "${LABRAT_STATE_ENABLED_DIR}/${module}"
    
    log_success "Enabled: $module"
    return 0
}

# Disable a module's shell integration
disable_module() {
    local module="$1"
    
    ensure_state_dirs
    
    # Remove from enabled if present
    rm -f "${LABRAT_STATE_ENABLED_DIR}/${module}"
    
    # Add to disabled
    echo "disabled $(date -Iseconds)" > "${LABRAT_STATE_DISABLED_DIR}/${module}"
    
    log_success "Disabled: $module"
    return 0
}

# Toggle a module's state
toggle_module() {
    local module="$1"
    
    if is_module_enabled "$module"; then
        disable_module "$module"
        return 1  # Now disabled
    else
        enable_module "$module"
        return 0  # Now enabled
    fi
}

# Get module state as string
get_module_state() {
    local module="$1"
    
    if is_module_enabled "$module"; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# ============================================================================
# Preference Storage
# ============================================================================

# Save a preference value
save_preference() {
    local key="$1"
    local value="$2"
    
    ensure_state_dirs
    echo "$value" > "${LABRAT_STATE_DIR}/${key}"
}

# Get a preference value
get_preference() {
    local key="$1"
    local default="${2:-}"
    
    if [[ -f "${LABRAT_STATE_DIR}/${key}" ]]; then
        cat "${LABRAT_STATE_DIR}/${key}"
    else
        echo "$default"
    fi
}

# Check if a preference exists
has_preference() {
    local key="$1"
    [[ -f "${LABRAT_STATE_DIR}/${key}" ]]
}

# Delete a preference
delete_preference() {
    local key="$1"
    rm -f "${LABRAT_STATE_DIR}/${key}"
}

# ============================================================================
# Current Theme/Preset Tracking
# ============================================================================

# Get current starship preset
get_current_starship_preset() {
    local preset_marker="${LABRAT_DATA_DIR}/current-starship-preset"
    if [[ -f "$preset_marker" ]]; then
        cat "$preset_marker"
    else
        echo "labrat"  # Default
    fi
}

# Set current starship preset
set_current_starship_preset() {
    local preset="$1"
    echo "$preset" > "${LABRAT_DATA_DIR}/current-starship-preset"
}

# Get current tmux theme
get_current_tmux_theme() {
    if [[ -f "$HOME/.tmux-theme" ]]; then
        cat "$HOME/.tmux-theme"
    else
        echo "catppuccin-mocha"  # Default
    fi
}

# Set current tmux theme (handled by tmux-theme script, but track here too)
set_current_tmux_theme() {
    local theme="$1"
    echo "$theme" > "$HOME/.tmux-theme"
}

# ============================================================================
# Module Metadata (for keybind display)
# ============================================================================

# Module keybind definitions
declare -gA MODULE_KEYBINDS=(
    ["fzf"]="Ctrl+R: history | Ctrl+T: files | Alt+C: cd"
    ["atuin"]="Ctrl+R: history search"
    ["zoxide"]="z <dir>: jump | zi: interactive"
    ["thefuck"]="Esc+Esc: fix last command"
    ["tmux"]="Ctrl+B: prefix | Alt+G: scratchpad"
    ["starship"]="(prompt)"
    ["broot"]="br: file navigator"
    ["lazygit"]="lg: git TUI"
)

# Module descriptions
declare -gA MODULE_DESCRIPTIONS=(
    ["starship"]="Cross-shell prompt"
    ["atuin"]="Shell history with sync"
    ["zoxide"]="Smart directory jumper"
    ["fzf"]="Fuzzy finder"
    ["mise"]="Runtime version manager"
    ["direnv"]="Per-directory environments"
    ["thefuck"]="Command correction"
    ["broot"]="File navigator"
    ["lazygit"]="Git TUI"
)

# Get keybinds for a module
get_module_keybinds() {
    local module="$1"
    echo "${MODULE_KEYBINDS[$module]:-}"
}

# Get description for a module
get_module_description() {
    local module="$1"
    echo "${MODULE_DESCRIPTIONS[$module]:-$module}"
}

# List all modules with shell integration capability
list_toggleable_modules() {
    echo "starship atuin zoxide fzf mise direnv thefuck broot"
}

# ============================================================================
# Startup Summary Settings
# ============================================================================

# Check if startup summary is enabled
is_startup_summary_enabled() {
    local setting
    setting=$(get_preference "startup_summary" "true")
    [[ "$setting" == "true" ]]
}

# Enable startup summary
enable_startup_summary() {
    save_preference "startup_summary" "true"
}

# Disable startup summary
disable_startup_summary() {
    save_preference "startup_summary" "false"
}

# Check if we should show summary (rate limiting - once per session)
should_show_startup_summary() {
    # Check if disabled
    if ! is_startup_summary_enabled; then
        return 1
    fi
    
    # Check environment variable
    if [[ "${LABRAT_QUIET:-}" == "1" ]]; then
        return 1
    fi
    
    # Check if already shown this session
    if [[ "${LABRAT_SUMMARY_SHOWN:-}" == "1" ]]; then
        return 1
    fi
    
    return 0
}

# Mark summary as shown for this session
mark_summary_shown() {
    export LABRAT_SUMMARY_SHOWN=1
}
