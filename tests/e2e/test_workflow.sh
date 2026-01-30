#!/usr/bin/env bash
#
# End-to-End Workflow Tests
# Tests complete user workflows from install to usage
# These simulate the REAL user experience
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${LABRAT_ROOT}/tests/lib/test_framework.sh"

# ============================================================================
# E2E Workflow Tests
# These test complete user journeys
# ============================================================================

test_idempotent_install() {
    log_test "Testing install is idempotent (can run twice)"
    
    local module="htop"  # Simple module for testing
    
    # First install
    "${LABRAT_ROOT}/install.sh" -m "$module" -y >/dev/null 2>&1 || {
        fail_test "First install failed"
        return 1
    }
    
    # Get state after first install
    local marker1=""
    if [[ -f "$HOME/.local/share/labrat/installed/$module" ]]; then
        marker1=$(cat "$HOME/.local/share/labrat/installed/$module")
    fi
    
    # Second install (should not error)
    if "${LABRAT_ROOT}/install.sh" -m "$module" -y >/dev/null 2>&1; then
        # Verify marker still exists and is valid
        if [[ -f "$HOME/.local/share/labrat/installed/$module" ]]; then
            pass_test "Install is idempotent"
            return 0
        else
            fail_test "Marker file missing after second install"
            return 1
        fi
    else
        fail_test "Second install failed"
        return 1
    fi
}

test_install_then_use() {
    log_test "Testing install → use workflow"
    
    # Install fzf if not already
    if [[ ! -f "$HOME/.local/share/labrat/installed/fzf" ]]; then
        "${LABRAT_ROOT}/install.sh" -m fzf -y >/dev/null 2>&1 || {
            skip_test "Could not install fzf"
            return 0
        }
    fi
    
    # Use it
    local result
    result=$(echo -e "one\ntwo\nthree" | "$HOME/.local/bin/fzf" --filter="two" 2>/dev/null)
    
    if [[ "$result" == *"two"* ]]; then
        pass_test "Install → use workflow works for fzf"
        return 0
    else
        fail_test "fzf not working after install"
        return 1
    fi
}

test_update_workflow() {
    log_test "Testing update workflow"
    
    # This tests the --update flag
    local output
    output=$("${LABRAT_ROOT}/install.sh" --update 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass_test "Update workflow completes without error"
        return 0
    else
        # Update with no modules installed is OK
        if [[ "$output" == *"No modules"* ]]; then
            pass_test "Update correctly reports no modules to update"
            return 0
        fi
        fail_test "Update workflow failed"
        return 1
    fi
}

test_uninstall_workflow() {
    log_test "Testing uninstall workflow"
    
    # Install a module first
    local module="htop"
    "${LABRAT_ROOT}/install.sh" -m "$module" -y >/dev/null 2>&1
    
    if [[ ! -f "$HOME/.local/share/labrat/installed/$module" ]]; then
        skip_test "Could not install test module"
        return 0
    fi
    
    # Uninstall it
    if "${LABRAT_ROOT}/install.sh" --uninstall "$module" >/dev/null 2>&1; then
        # Verify marker is gone
        if [[ ! -f "$HOME/.local/share/labrat/installed/$module" ]]; then
            pass_test "Uninstall removes marker"
            return 0
        else
            fail_test "Marker still exists after uninstall"
            return 1
        fi
    else
        fail_test "Uninstall command failed"
        return 1
    fi
}

test_multi_module_install() {
    log_test "Testing multiple module installation"
    
    # Install multiple modules at once
    if "${LABRAT_ROOT}/install.sh" -m htop,bat -y >/dev/null 2>&1; then
        # Check both are installed
        local htop_ok=false
        local bat_ok=false
        
        [[ -f "$HOME/.local/share/labrat/installed/htop" ]] && htop_ok=true
        [[ -f "$HOME/.local/share/labrat/installed/bat" ]] && bat_ok=true
        
        if $htop_ok && $bat_ok; then
            pass_test "Multiple modules installed successfully"
            return 0
        else
            fail_test "Not all modules installed: htop=$htop_ok, bat=$bat_ok"
            return 1
        fi
    else
        fail_test "Multi-module install failed"
        return 1
    fi
}

test_tools_work_together() {
    log_test "Testing multi-tool integration (fzf + ripgrep + bat)"
    
    # Check if all tools are available
    local fzf_ok=false
    local rg_ok=false
    local bat_ok=false
    
    command -v fzf &>/dev/null && fzf_ok=true
    command -v rg &>/dev/null && rg_ok=true
    command -v bat &>/dev/null && bat_ok=true
    
    if ! $fzf_ok || ! $rg_ok || ! $bat_ok; then
        skip_test "Not all tools installed (fzf=$fzf_ok, rg=$rg_ok, bat=$bat_ok)"
        return 0
    fi
    
    # Create a test file
    local tmpfile
    tmpfile=$(mktemp --suffix=.txt)
    echo "LABRAT_INTEGRATION_TEST" > "$tmpfile"
    
    # Test: rg finds the string, pipe to fzf filter
    local result
    result=$(rg "LABRAT" "$tmpfile" 2>/dev/null | fzf --filter="INTEGRATION" 2>/dev/null)
    
    rm -f "$tmpfile"
    
    if [[ "$result" == *"INTEGRATION"* ]]; then
        pass_test "Multi-tool pipeline works (rg | fzf)"
        return 0
    else
        fail_test "Multi-tool pipeline failed"
        return 1
    fi
}

test_shell_integration_after_install() {
    log_test "Testing shell works after install"
    
    # Run a complete shell session test
    local result
    result=$(bash -lc '
        # Check PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo "PATH_FAIL"
            exit 1
        fi
        
        # Check can source bashrc
        if [[ -f ~/.bashrc ]]; then
            source ~/.bashrc 2>/dev/null || {
                echo "BASHRC_FAIL"
                exit 1
            }
        fi
        
        echo "SUCCESS"
    ' 2>/dev/null)
    
    if [[ "$result" == *"SUCCESS"* ]]; then
        pass_test "Shell integration works after install"
        return 0
    elif [[ "$result" == *"PATH_FAIL"* ]]; then
        fail_test "PATH not configured after install"
        return 1
    elif [[ "$result" == *"BASHRC_FAIL"* ]]; then
        fail_test "bashrc fails to source after install"
        return 1
    else
        fail_test "Shell integration test failed"
        return 1
    fi
}

test_status_command() {
    log_test "Testing --status command"
    
    local output
    output=$("${LABRAT_ROOT}/install.sh" --list 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ -n "$output" ]]; then
        pass_test "--list shows available modules"
        return 0
    else
        fail_test "--list command failed"
        return 1
    fi
}

test_help_command() {
    log_test "Testing --help command"
    
    local output
    output=$("${LABRAT_ROOT}/install.sh" --help 2>&1)
    
    if [[ "$output" == *"USAGE"* ]] || [[ "$output" == *"OPTIONS"* ]]; then
        pass_test "--help shows usage information"
        return 0
    else
        fail_test "--help output unexpected"
        return 1
    fi
}

test_dry_run() {
    log_test "Testing --dry-run mode"
    
    local marker_before=""
    [[ -f "$HOME/.local/share/labrat/installed/htop" ]] && marker_before="exists"
    
    # Uninstall first if it exists
    rm -f "$HOME/.local/share/labrat/installed/htop"
    
    # Run with dry-run
    "${LABRAT_ROOT}/install.sh" -m htop --dry-run -y >/dev/null 2>&1
    
    # Verify nothing was installed
    if [[ -f "$HOME/.local/share/labrat/installed/htop" ]]; then
        fail_test "dry-run actually installed the module"
        return 1
    else
        pass_test "dry-run does not modify system"
        return 0
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "E2E Workflow Tests" \
    test_idempotent_install \
    test_install_then_use \
    test_update_workflow \
    test_uninstall_workflow \
    test_multi_module_install \
    test_tools_work_together \
    test_shell_integration_after_install \
    test_status_command \
    test_help_command \
    test_dry_run
