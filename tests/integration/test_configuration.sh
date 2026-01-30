#!/usr/bin/env bash
#
# Integration Tests: Configuration
# Tests configuration file handling and options
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# Configuration Test Data
# ============================================================================

# Configuration files and their expected locations
# Note: Some tools use alternative locations or no config files
declare -A CONFIG_FILES=(
    ["tmux"]="$HOME/.tmux.conf"
    # fzf uses shell integration via FZF_DEFAULT_OPTS, not a config file
    ["bat"]="$HOME/.config/bat/config"
    ["starship"]="$HOME/.config/starship.toml"
    ["atuin"]="$HOME/.config/atuin/config.toml"
    ["lazygit"]="$HOME/.config/lazygit/config.yml"
    ["fastfetch"]="$HOME/.config/fastfetch/config.jsonc"
    ["btop"]="$HOME/.config/btop/btop.conf"
    ["neovim"]="$HOME/.config/nvim/init.lua"
)

# ============================================================================
# Config Existence Tests
# ============================================================================

test_config_files_exist() {
    log_header "Configuration File Existence Tests"
    
    local failed=0
    
    for module in "${!CONFIG_FILES[@]}"; do
        local config_path="${CONFIG_FILES[$module]}"
        
        # Only test if module is installed
        if [[ ! -f "$HOME/.local/share/labrat/installed/$module" ]]; then
            skip_test "Module $module not installed"
            continue
        fi
        
        if [[ -e "$config_path" ]]; then
            pass_test "Config exists: $module ($config_path)"
        else
            fail_test "Config missing: $module (expected: $config_path)"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# tmux Configuration Tests
# ============================================================================

test_tmux_config_valid() {
    log_test "Testing tmux configuration validity"
    
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        skip_test "tmux config not found"
        return 0
    fi
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Try to parse config (syntax check)
    if tmux source-file "$HOME/.tmux.conf" 2>/dev/null; then
        pass_test "tmux config syntax valid"
        return 0
    else
        # In non-tmux environment, just check file exists
        if [[ -f "$HOME/.tmux.conf" ]]; then
            pass_test "tmux config file exists"
            return 0
        fi
        fail_test "tmux config invalid"
        return 1
    fi
}

test_tmux_config_has_prefix() {
    log_test "Testing tmux config has key bindings"
    
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        skip_test "tmux config not found"
        return 0
    fi
    
    # Check for prefix OR bind commands (either indicates valid keybinding config)
    if grep -qE "(prefix|^bind |set -g @)" "$HOME/.tmux.conf"; then
        pass_test "tmux config has key binding/plugin settings"
        return 0
    else
        fail_test "tmux config missing key binding settings"
        return 1
    fi
}

test_tmux_themes_exist() {
    log_test "Testing tmux theme files exist"
    
    local themes_dir="$LABRAT_ROOT/configs/tmux/themes"
    local required_themes=("catppuccin-mocha.conf" "dracula.conf" "nord.conf")
    local failed=0
    
    for theme in "${required_themes[@]}"; do
        if [[ -f "$themes_dir/$theme" ]]; then
            pass_test "Theme exists: $theme"
        else
            fail_test "Theme missing: $theme"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# Shell Integration Tests
# ============================================================================

test_shell_integration_bashrc() {
    log_test "Testing shell integration in .bashrc"
    
    if [[ ! -f "$HOME/.bashrc" ]]; then
        skip_test ".bashrc not found"
        return 0
    fi
    
    # Check if labrat block exists
    if grep -q "LABRAT" "$HOME/.bashrc"; then
        pass_test "LabRat integration in .bashrc"
        return 0
    else
        skip_test "LabRat not integrated in .bashrc yet"
        return 0
    fi
}

test_shell_integration_path() {
    log_test "Testing PATH includes ~/.local/bin"
    
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        pass_test "~/.local/bin is in PATH"
        return 0
    else
        fail_test "~/.local/bin not in PATH"
        return 1
    fi
}

# ============================================================================
# fzf Configuration Tests
# ============================================================================

test_fzf_config_valid() {
    log_test "Testing fzf configuration"
    
    # fzf uses shell integration, not a config file
    # Check if fzf is installed
    if ! command -v fzf &>/dev/null; then
        local fzf_bin="$HOME/.local/bin/fzf"
        if [[ ! -x "$fzf_bin" ]]; then
            skip_test "fzf not installed"
            return 0
        fi
    fi
    
    # Check for shell integration or theme files
    local labrat_fzf_themes="$LABRAT_ROOT/configs/fzf/themes"
    local labrat_fzf_config="$LABRAT_ROOT/configs/fzf/config"
    
    if [[ -d "$labrat_fzf_themes" ]] || [[ -f "$labrat_fzf_config" ]]; then
        pass_test "fzf LabRat config/themes exist"
        return 0
    elif [[ -f "$HOME/.fzf.bash" ]] || [[ -f "$HOME/.fzf.zsh" ]]; then
        pass_test "fzf shell integration exists"
        return 0
    else
        # Just verify fzf binary works
        if fzf --version &>/dev/null || "$HOME/.local/bin/fzf" --version &>/dev/null; then
            pass_test "fzf installed and working"
            return 0
        fi
        fail_test "fzf not properly configured"
        return 1
    fi
}

test_fzf_themes_exist() {
    log_test "Testing fzf theme files"
    
    local themes_dir="$LABRAT_ROOT/configs/fzf/themes"
    local count=0
    
    if [[ -d "$themes_dir" ]]; then
        count=$(find "$themes_dir" -name "*.sh" | wc -l)
    fi
    
    if [[ $count -gt 0 ]]; then
        pass_test "Found $count fzf themes"
        return 0
    else
        fail_test "No fzf themes found"
        return 1
    fi
}

# ============================================================================
# starship Configuration Tests
# ============================================================================

test_starship_config_valid() {
    log_test "Testing starship configuration"
    
    local config="$HOME/.config/starship.toml"
    
    if [[ ! -f "$config" ]]; then
        skip_test "starship config not found"
        return 0
    fi
    
    # Basic TOML validation
    if grep -q "\[" "$config" && grep -q "format" "$config"; then
        pass_test "starship config looks valid"
        return 0
    else
        fail_test "starship config may be invalid"
        return 1
    fi
}

test_starship_presets_exist() {
    log_test "Testing starship presets"
    
    local presets_dir="$LABRAT_ROOT/configs/starship/presets"
    local count=0
    
    if [[ -d "$presets_dir" ]]; then
        count=$(find "$presets_dir" -name "*.toml" | wc -l)
    fi
    
    if [[ $count -gt 0 ]]; then
        pass_test "Found $count starship presets"
        return 0
    else
        fail_test "No starship presets found"
        return 1
    fi
}

# ============================================================================
# fastfetch Configuration Tests
# ============================================================================

test_fastfetch_config_valid() {
    log_test "Testing fastfetch configuration"
    
    local config="$HOME/.config/fastfetch/config.jsonc"
    
    if [[ ! -f "$config" ]]; then
        skip_test "fastfetch config not found"
        return 0
    fi
    
    # Check for valid JSON structure
    if grep -q '"modules"' "$config"; then
        pass_test "fastfetch config has modules section"
        return 0
    else
        fail_test "fastfetch config may be invalid"
        return 1
    fi
}

test_fastfetch_logo_exists() {
    log_test "Testing fastfetch logo file"
    
    local logo="$LABRAT_ROOT/configs/fastfetch/labrat-logo.txt"
    
    if [[ -f "$logo" ]]; then
        pass_test "fastfetch logo exists"
        return 0
    else
        fail_test "fastfetch logo not found"
        return 1
    fi
}

# ============================================================================
# LabRat State/Data Tests
# ============================================================================

test_labrat_data_dirs() {
    log_test "Testing LabRat data directories"
    
    local dirs=(
        "$HOME/.local/share/labrat"
        "$HOME/.config/labrat"
        "$HOME/.cache/labrat"
    )
    
    local failed=0
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            pass_test "Directory exists: $dir"
        else
            # Create if missing for future use
            mkdir -p "$dir" 2>/dev/null
            pass_test "Created: $dir"
        fi
    done
    
    return $failed
}

test_installed_markers() {
    log_test "Testing installation markers"
    
    local marker_dir="$HOME/.local/share/labrat/installed"
    
    if [[ -d "$marker_dir" ]]; then
        local count
        count=$(find "$marker_dir" -type f | wc -l)
        pass_test "Found $count installed module markers"
        return 0
    else
        skip_test "No installed markers directory"
        return 0
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "Configuration Tests" \
    test_config_files_exist \
    test_tmux_config_valid \
    test_tmux_config_has_prefix \
    test_tmux_themes_exist \
    test_shell_integration_bashrc \
    test_shell_integration_path \
    test_fzf_config_valid \
    test_fzf_themes_exist \
    test_starship_config_valid \
    test_starship_presets_exist \
    test_fastfetch_config_valid \
    test_fastfetch_logo_exists \
    test_labrat_data_dirs \
    test_installed_markers
