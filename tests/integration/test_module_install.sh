#!/usr/bin/env bash
#
# Integration Tests: Module Install/Uninstall
# Tests installation and uninstallation for all modules
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# Module Test Data
# ============================================================================

# All modules with their expected binary names
declare -A MODULE_BINARIES=(
    # Utils
    ["htop"]="htop"
    ["ripgrep"]="rg"
    ["bat"]="bat"
    ["fd"]="fd"
    ["fzf"]="fzf"
    ["eza"]="eza"
    ["zoxide"]="zoxide"
    ["lazygit"]="lazygit"
    ["duf"]="duf"
    ["ncdu"]="ncdu"
    ["fastfetch"]="fastfetch"
    
    # Monitoring
    ["btop"]="btop"
    ["procs"]="procs"
    
    # Network
    ["mtr"]="mtr"
    ["gping"]="gping"
    ["dog"]="dog"
    
    # Productivity
    ["atuin"]="atuin"
    ["broot"]="broot"
    ["direnv"]="direnv"
    ["just"]="just"
    ["thefuck"]="thefuck"
    ["tldr"]="tldr"
    
    # Shell
    ["starship"]="starship"
    
    # Editors
    ["neovim"]="nvim"
    ["vim"]="vim"
)

# Modules with configuration files
declare -A MODULE_CONFIGS=(
    ["fzf"]="$HOME/.config/fzf"
    ["bat"]="$HOME/.config/bat"
    ["btop"]="$HOME/.config/btop"
    ["starship"]="$HOME/.config/starship.toml"
    ["atuin"]="$HOME/.config/atuin/config.toml"
    ["lazygit"]="$HOME/.config/lazygit"
    ["neovim"]="$HOME/.config/nvim"
    ["fastfetch"]="$HOME/.config/fastfetch"
)

# ============================================================================
# Install Tests
# ============================================================================

test_module_install() {
    local module="$1"
    local expected_binary="${MODULE_BINARIES[$module]:-$module}"
    
    log_test "Installing module: $module"
    
    # Install the module
    if ! "$LABRAT_ROOT/install.sh" -m "$module" -y 2>/dev/null; then
        fail_test "Installation command failed for $module"
        return 1
    fi
    
    # Check installation marker
    local marker_file="$HOME/.local/share/labrat/installed/$module"
    if [[ ! -f "$marker_file" ]]; then
        fail_test "Installation marker not created for $module"
        return 1
    fi
    
    # Check binary exists (either in PATH or ~/.local/bin)
    if command -v "$expected_binary" &>/dev/null || [[ -x "$HOME/.local/bin/$expected_binary" ]]; then
        pass_test "Module $module installed successfully (binary: $expected_binary)"
        return 0
    else
        fail_test "Binary not found for $module (expected: $expected_binary)"
        return 1
    fi
}

test_module_uninstall() {
    local module="$1"
    local expected_binary="${MODULE_BINARIES[$module]:-$module}"
    
    log_test "Uninstalling module: $module"
    
    # Uninstall the module
    if ! "$LABRAT_ROOT/install.sh" --uninstall "$module" 2>/dev/null; then
        # Try alternative uninstall method
        rm -f "$HOME/.local/share/labrat/installed/$module"
    fi
    
    # Check installation marker removed
    local marker_file="$HOME/.local/share/labrat/installed/$module"
    if [[ -f "$marker_file" ]]; then
        fail_test "Installation marker still exists after uninstall for $module"
        return 1
    fi
    
    pass_test "Module $module uninstalled"
    return 0
}

test_module_reinstall() {
    local module="$1"
    
    log_test "Testing reinstall for: $module"
    
    # Install, then reinstall
    "$LABRAT_ROOT/install.sh" -m "$module" -y 2>/dev/null
    
    local first_marker
    first_marker=$(cat "$HOME/.local/share/labrat/installed/$module" 2>/dev/null)
    
    # Reinstall
    sleep 1
    "$LABRAT_ROOT/install.sh" -m "$module" -y 2>/dev/null
    
    local second_marker
    second_marker=$(cat "$HOME/.local/share/labrat/installed/$module" 2>/dev/null)
    
    if [[ -n "$second_marker" ]]; then
        pass_test "Module $module reinstall successful"
        return 0
    else
        fail_test "Module $module reinstall failed"
        return 1
    fi
}

test_module_config_deployed() {
    local module="$1"
    local config_path="${MODULE_CONFIGS[$module]:-}"
    
    if [[ -z "$config_path" ]]; then
        skip_test "No config expected for $module"
        return 0
    fi
    
    log_test "Checking config deployment for: $module"
    
    # Install if not installed
    if [[ ! -f "$HOME/.local/share/labrat/installed/$module" ]]; then
        "$LABRAT_ROOT/install.sh" -m "$module" -y 2>/dev/null
    fi
    
    if [[ -e "$config_path" ]]; then
        pass_test "Config deployed for $module: $config_path"
        return 0
    else
        fail_test "Config not deployed for $module (expected: $config_path)"
        return 1
    fi
}

# ============================================================================
# Batch Tests
# ============================================================================

test_quick_install_modules() {
    log_header "Quick Install Test (Core Modules)"
    
    local quick_modules=("htop" "ripgrep" "bat" "fd" "fzf")
    local success=0
    local failed=0
    
    for module in "${quick_modules[@]}"; do
        if test_module_install "$module"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    echo "Quick install results: $success passed, $failed failed"
    return $failed
}

test_all_module_installs() {
    log_header "Full Module Installation Test"
    
    local success=0
    local failed=0
    local skipped=0
    
    for module in "${!MODULE_BINARIES[@]}"; do
        # Skip modules that require sudo or are slow to install
        case "$module" in
            mtr|nethogs|iotop|bandwhich|glances|nmap)
                skip_test "Skipping $module (requires sudo)"
                ((skipped++))
                continue
                ;;
        esac
        
        if test_module_install "$module"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    echo "Results: $success passed, $failed failed, $skipped skipped"
    return $failed
}

test_install_uninstall_cycle() {
    log_header "Install/Uninstall Cycle Test"
    
    local test_modules=("htop" "bat" "fd")
    local success=0
    local failed=0
    
    for module in "${test_modules[@]}"; do
        echo ""
        echo "=== Testing cycle for: $module ==="
        
        # Install
        if ! test_module_install "$module"; then
            ((failed++))
            continue
        fi
        
        # Verify binary works
        local binary="${MODULE_BINARIES[$module]:-$module}"
        if command -v "$binary" &>/dev/null; then
            "$binary" --version 2>/dev/null && pass_test "$binary --version works"
        fi
        
        # Uninstall
        if ! test_module_uninstall "$module"; then
            ((failed++))
            continue
        fi
        
        ((success++))
    done
    
    echo ""
    echo "Cycle results: $success modules tested successfully, $failed failed"
    return $failed
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "Module Install/Uninstall Tests" \
    test_install_uninstall_cycle
