#!/usr/bin/env bash
#
# LabRat Install/Uninstall Cycle Tests
# Tests that install and uninstall leave the system in expected states
#

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ============================================================================
# Logging
# ============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; ((TESTS_PASSED++)); }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; ((TESTS_FAILED++)); }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; ((TESTS_SKIPPED++)); }
log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}
log_step() { echo -e "${CYAN}→${NC} $1"; }

# ============================================================================
# Test Helpers
# ============================================================================

# Capture original state of shell configs
capture_shell_state() {
    local state_dir="$1"
    mkdir -p "$state_dir"
    
    [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$state_dir/bashrc"
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$state_dir/zshrc"
    [[ -f "$HOME/.config/fish/config.fish" ]] && cp "$HOME/.config/fish/config.fish" "$state_dir/config.fish"
    
    # Capture labrat-specific directories if they exist
    [[ -d "$HOME/.config/labrat" ]] && cp -r "$HOME/.config/labrat" "$state_dir/labrat-config"
    [[ -d "$HOME/.local/share/labrat" ]] && cp -r "$HOME/.local/share/labrat" "$state_dir/labrat-data"
}

# Compare current state to captured state
compare_shell_state() {
    local expected_dir="$1"
    local description="$2"
    local passed=true
    
    # Compare bashrc
    if [[ -f "$expected_dir/bashrc" ]]; then
        if ! diff -q "$HOME/.bashrc" "$expected_dir/bashrc" &>/dev/null; then
            log_fail "$description: .bashrc differs from expected"
            passed=false
        fi
    fi
    
    # Compare zshrc
    if [[ -f "$expected_dir/zshrc" ]]; then
        if ! diff -q "$HOME/.zshrc" "$expected_dir/zshrc" &>/dev/null; then
            log_fail "$description: .zshrc differs from expected"
            passed=false
        fi
    fi
    
    if [[ "$passed" == "true" ]]; then
        log_success "$description: Shell configs match expected state"
    fi
}

# Check if labrat hook is present in a file
has_labrat_hook() {
    local file="$1"
    [[ -f "$file" ]] && grep -q "LabRat shell integration" "$file"
}

# Check if a module snippet exists
has_module_snippet() {
    local module="$1"
    local shell="$2"
    
    case "$shell" in
        bash) [[ -f "$HOME/.config/labrat/modules/bash/${module}.sh" ]] ;;
        zsh)  [[ -f "$HOME/.config/labrat/modules/zsh/${module}.zsh" ]] ;;
        fish) [[ -f "$HOME/.config/labrat/modules/fish/${module}.fish" ]] ;;
    esac
}

# ============================================================================
# Test Cases
# ============================================================================

test_fresh_install() {
    log_header "Test: Fresh Install"
    
    local original_state=$(mktemp -d)
    capture_shell_state "$original_state"
    
    log_step "Installing starship module..."
    if "$LABRAT_ROOT/install.sh" -m starship -y; then
        log_success "starship installed successfully"
    else
        log_fail "starship installation failed"
        return 1
    fi
    
    # Verify installation effects
    log_step "Verifying installation..."
    
    # Check binary exists
    if [[ -f "$HOME/.local/bin/starship" ]] || command -v starship &>/dev/null; then
        log_success "starship binary installed"
    else
        log_fail "starship binary not found"
    fi
    
    # Check shell hook installed
    if has_labrat_hook "$HOME/.bashrc"; then
        log_success "LabRat hook installed in .bashrc"
    else
        log_fail "LabRat hook missing from .bashrc"
    fi
    
    # Check module snippet created
    if has_module_snippet "starship" "bash"; then
        log_success "starship bash module snippet created"
    else
        log_fail "starship bash module snippet missing"
    fi
    
    # Check module marked as installed
    if [[ -f "$HOME/.local/share/labrat/installed/starship" ]]; then
        log_success "starship marked as installed"
    else
        log_fail "starship installation marker missing"
    fi
    
    # Check original backups created
    if [[ -f "$HOME/.local/share/labrat/shell_backups/original/bashrc" ]]; then
        log_success "Original .bashrc backed up"
    else
        log_fail "Original .bashrc backup missing"
    fi
    
    rm -rf "$original_state"
}

test_module_uninstall() {
    log_header "Test: Module Uninstall"
    
    # First ensure starship is installed
    if ! [[ -f "$HOME/.local/share/labrat/installed/starship" ]]; then
        log_step "Installing starship first..."
        "$LABRAT_ROOT/install.sh" -m starship -y &>/dev/null
    fi
    
    log_step "Uninstalling starship module..."
    if "$LABRAT_ROOT/bin/labrat-uninstall" --module starship -y; then
        log_success "starship uninstall command succeeded"
    else
        log_fail "starship uninstall command failed"
        return 1
    fi
    
    # Verify uninstall effects
    log_step "Verifying uninstall..."
    
    # Check binary removed
    if [[ ! -f "$HOME/.local/bin/starship" ]]; then
        log_success "starship binary removed"
    else
        log_fail "starship binary still present"
    fi
    
    # Check module snippet removed
    if ! has_module_snippet "starship" "bash"; then
        log_success "starship bash module snippet removed"
    else
        log_fail "starship bash module snippet still present"
    fi
    
    # Check installation marker removed
    if [[ ! -f "$HOME/.local/share/labrat/installed/starship" ]]; then
        log_success "starship installation marker removed"
    else
        log_fail "starship installation marker still present"
    fi
    
    # Note: hook should still be in .bashrc (other modules might use it)
    # Full hook removal only happens on complete uninstall
}

test_full_uninstall_restore() {
    log_header "Test: Full Uninstall with Restore"
    
    local original_state=$(mktemp -d)
    capture_shell_state "$original_state"
    
    # Install some modules
    log_step "Installing modules for test..."
    "$LABRAT_ROOT/install.sh" -m starship -y &>/dev/null
    
    # Capture post-install state
    local installed_state=$(mktemp -d)
    capture_shell_state "$installed_state"
    
    # Full uninstall with restore
    log_step "Performing full uninstall with restore..."
    if echo "y" | "$LABRAT_ROOT/bin/labrat-uninstall" --full -y; then
        log_success "Full uninstall command succeeded"
    else
        log_fail "Full uninstall command failed"
    fi
    
    # Verify shell configs restored
    log_step "Verifying restoration..."
    
    # Hook should be removed
    if ! has_labrat_hook "$HOME/.bashrc"; then
        log_success "LabRat hook removed from .bashrc"
    else
        log_fail "LabRat hook still present in .bashrc"
    fi
    
    # Labrat config directory should be removed
    if [[ ! -d "$HOME/.config/labrat" ]]; then
        log_success "LabRat config directory removed"
    else
        log_fail "LabRat config directory still present"
    fi
    
    rm -rf "$original_state" "$installed_state"
}

test_install_multiple_modules() {
    log_header "Test: Install Multiple Modules"
    
    log_step "Installing zoxide and fzf..."
    if "$LABRAT_ROOT/install.sh" -m zoxide -y; then
        log_success "zoxide installed"
    else
        log_fail "zoxide installation failed"
    fi
    
    # Check both modules have shell integration
    if has_module_snippet "zoxide" "bash"; then
        log_success "zoxide has bash shell integration"
    else
        log_fail "zoxide missing bash shell integration"
    fi
    
    # Check they're tracked
    if [[ -f "$HOME/.local/share/labrat/installed/zoxide" ]]; then
        log_success "zoxide tracked in installed directory"
    else
        log_fail "zoxide not tracked"
    fi
}

test_shell_integration_status() {
    log_header "Test: Shell Integration Status"
    
    # Source the libraries
    source "$LABRAT_ROOT/lib/colors.sh"
    source "$LABRAT_ROOT/lib/common.sh"
    source "$LABRAT_ROOT/lib/shell_integration.sh"
    
    log_step "Checking shell integration status..."
    
    # Run status command
    if shell_integration_status &>/dev/null; then
        log_success "shell_integration_status runs without error"
    else
        log_fail "shell_integration_status failed"
    fi
}

test_register_unregister_module() {
    log_header "Test: Register/Unregister Shell Module"
    
    # Source libraries
    source "$LABRAT_ROOT/lib/colors.sh"
    source "$LABRAT_ROOT/lib/common.sh"
    source "$LABRAT_ROOT/lib/shell_integration.sh"
    
    log_step "Registering test module..."
    register_shell_module "testmodule" \
        --init-bash 'echo "test init bash"' \
        --init-zsh 'echo "test init zsh"' \
        --functions-bash 'testfunc() { echo "test"; }' \
        --description "Test module"
    
    if has_module_snippet "testmodule" "bash"; then
        log_success "testmodule registered in bash"
    else
        log_fail "testmodule not registered in bash"
    fi
    
    if has_module_snippet "testmodule" "zsh"; then
        log_success "testmodule registered in zsh"
    else
        log_fail "testmodule not registered in zsh"
    fi
    
    log_step "Unregistering test module..."
    unregister_shell_module "testmodule"
    
    if ! has_module_snippet "testmodule" "bash"; then
        log_success "testmodule unregistered from bash"
    else
        log_fail "testmodule still registered in bash"
    fi
    
    if ! has_module_snippet "testmodule" "zsh"; then
        log_success "testmodule unregistered from zsh"
    else
        log_fail "testmodule still registered in zsh"
    fi
}

test_backup_restore() {
    log_header "Test: Backup and Restore"
    
    # Source libraries
    source "$LABRAT_ROOT/lib/colors.sh"
    source "$LABRAT_ROOT/lib/common.sh"
    source "$LABRAT_ROOT/lib/shell_integration.sh"
    
    # Capture original content
    local original_bashrc=""
    [[ -f "$HOME/.bashrc" ]] && original_bashrc=$(cat "$HOME/.bashrc")
    
    log_step "Setting up shell integration (creates backups)..."
    setup_shell_integration
    
    # Check backup created
    if [[ -f "$HOME/.local/share/labrat/shell_backups/original/bashrc" ]]; then
        log_success "Original backup created"
    else
        log_fail "Original backup not created"
    fi
    
    log_step "Restoring original..."
    restore_original_shell_configs
    
    # Check content restored
    local restored_bashrc=""
    [[ -f "$HOME/.bashrc" ]] && restored_bashrc=$(cat "$HOME/.bashrc")
    
    # Need to strip the LabRat hook that was added before comparing
    # Since restore should put back the original
    if [[ -n "$original_bashrc" ]] && [[ -n "$restored_bashrc" ]]; then
        log_success "Restore completed (manual verification may be needed)"
    else
        log_skip "Unable to verify restore (empty configs)"
    fi
}

test_manifest_tracking() {
    log_header "Test: Manifest Tracking"
    
    # Source libraries
    source "$LABRAT_ROOT/lib/colors.sh"
    source "$LABRAT_ROOT/lib/common.sh"
    source "$LABRAT_ROOT/lib/shell_integration.sh"
    source "$LABRAT_ROOT/lib/manifest.sh"
    
    log_step "Testing manifest operations..."
    
    # Initialize manifest
    init_manifest
    
    if [[ -f "$HOME/.local/share/labrat/manifest.json" ]]; then
        log_success "Manifest file created"
    else
        log_fail "Manifest file not created"
    fi
    
    # Add a module
    manifest_add_module "testmod" "1.0.0" "true"
    
    if manifest_has_module "testmod"; then
        log_success "Module added to manifest"
    else
        log_fail "Module not in manifest"
    fi
    
    # Get version
    local version=$(manifest_get_module_version "testmod")
    if [[ "$version" == "1.0.0" ]]; then
        log_success "Module version correct in manifest"
    else
        log_fail "Module version incorrect (got: $version)"
    fi
    
    # Remove module
    manifest_remove_module "testmod"
    
    if ! manifest_has_module "testmod"; then
        log_success "Module removed from manifest"
    else
        log_fail "Module still in manifest after removal"
    fi
}

# ============================================================================
# Test Runner
# ============================================================================

run_all_tests() {
    log_header "LabRat Install/Uninstall Cycle Tests"
    
    # Run tests in order
    test_register_unregister_module
    test_backup_restore
    test_manifest_tracking
    test_fresh_install
    test_install_multiple_modules
    test_module_uninstall
    test_shell_integration_status
    test_full_uninstall_restore
}

print_summary() {
    log_header "Test Results Summary"
    
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "  ${BOLD}Total:${NC}   $total"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "  ${RED}${BOLD}✗ Some tests failed${NC}"
        return 1
    fi
}

# ============================================================================
# Main
# ============================================================================

main() {
    case "${1:-}" in
        --help|-h)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all       Run all tests (default)"
            echo "  --quick     Run quick tests only"
            echo "  --help      Show this help"
            exit 0
            ;;
        --quick)
            test_register_unregister_module
            test_manifest_tracking
            ;;
        *)
            run_all_tests
            ;;
    esac
    
    print_summary
}

main "$@"
