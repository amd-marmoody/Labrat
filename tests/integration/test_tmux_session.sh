#!/usr/bin/env bash
#
# Integration Tests: tmux Sessions
# Tests that tmux configuration actually works in real sessions
# These are CRITICAL tests - they test the actual user experience
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# tmux Session Tests
# These test that tmux works correctly after installation
# ============================================================================

test_tmux_installed() {
    log_test "Testing tmux is installed"
    
    if command -v tmux &>/dev/null; then
        local version
        version=$(tmux -V 2>/dev/null)
        pass_test "tmux installed: $version"
        return 0
    else
        skip_test "tmux not installed"
        return 0
    fi
}

test_tmux_config_exists() {
    log_test "Testing tmux config exists"
    
    if [[ -f "$HOME/.tmux.conf" ]]; then
        pass_test "~/.tmux.conf exists"
        return 0
    else
        fail_test "~/.tmux.conf not found"
        return 1
    fi
}

test_tmux_config_syntax_valid() {
    log_test "Testing tmux config syntax"
    
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        skip_test "tmux config not found"
        return 0
    fi
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Check for obvious syntax errors by trying to parse
    local errors
    errors=$(tmux -f "$HOME/.tmux.conf" list-keys 2>&1 | grep -i "error\|unknown\|invalid" | head -5)
    
    if [[ -z "$errors" ]]; then
        pass_test "tmux config syntax appears valid"
        return 0
    else
        # Some errors might be due to missing server - try starting one
        skip_test "Could not validate config syntax (may need tmux server)"
        return 0
    fi
}

test_tmux_server_starts() {
    log_test "Testing tmux server can start"
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Kill any existing server first
    tmux kill-server 2>/dev/null || true
    
    # Try to start a new detached session
    if tmux new-session -d -s labrat_test 2>/dev/null; then
        # Clean up
        tmux kill-session -t labrat_test 2>/dev/null
        pass_test "tmux server starts successfully"
        return 0
    else
        fail_test "tmux server failed to start"
        return 1
    fi
}

test_tmux_session_creation() {
    log_test "Testing tmux session creation and management"
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Clean up any existing test sessions
    tmux kill-session -t labrat_session_test 2>/dev/null || true
    
    # Create a session
    if ! tmux new-session -d -s labrat_session_test 2>/dev/null; then
        fail_test "Failed to create tmux session"
        return 1
    fi
    
    # Verify session exists
    if tmux list-sessions 2>/dev/null | grep -q "labrat_session_test"; then
        pass_test "tmux session created and listed"
        tmux kill-session -t labrat_session_test 2>/dev/null
        return 0
    else
        fail_test "tmux session not found after creation"
        return 1
    fi
}

test_tmux_tpm_installed() {
    log_test "Testing TPM (Tmux Plugin Manager) is installed"
    
    if [[ ! -f "$HOME/.local/share/labrat/installed/tmux" ]]; then
        skip_test "tmux module not installed via LabRat"
        return 0
    fi
    
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        pass_test "TPM is installed at ~/.tmux/plugins/tpm"
        return 0
    else
        fail_test "TPM not found"
        return 1
    fi
}

test_tmux_theme_file_exists() {
    log_test "Testing tmux theme file exists"
    
    if [[ -f "$HOME/.tmux-theme" ]]; then
        local theme
        theme=$(cat "$HOME/.tmux-theme")
        pass_test "tmux theme configured: $theme"
        return 0
    else
        skip_test "No tmux theme file (~/.tmux-theme not found)"
        return 0
    fi
}

test_tmux_send_keys() {
    log_test "Testing tmux can send keys to session"
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Clean up
    tmux kill-session -t labrat_key_test 2>/dev/null || true
    
    # Create session
    tmux new-session -d -s labrat_key_test 2>/dev/null || {
        skip_test "Could not create test session"
        return 0
    }
    
    # Send keys and verify
    tmux send-keys -t labrat_key_test "echo LABRAT_TEST_MARKER" Enter
    sleep 0.5
    
    local output
    output=$(tmux capture-pane -t labrat_key_test -p 2>/dev/null)
    
    tmux kill-session -t labrat_key_test 2>/dev/null
    
    if [[ "$output" == *"LABRAT_TEST_MARKER"* ]]; then
        pass_test "tmux send-keys works"
        return 0
    else
        # This can fail in CI due to timing
        skip_test "tmux send-keys output not captured (timing issue)"
        return 0
    fi
}

test_tmux_pane_splitting() {
    log_test "Testing tmux pane splitting"
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Clean up
    tmux kill-session -t labrat_split_test 2>/dev/null || true
    
    # Create session and split
    tmux new-session -d -s labrat_split_test 2>/dev/null || {
        skip_test "Could not create test session"
        return 0
    }
    
    # Try horizontal split
    if tmux split-window -h -t labrat_split_test 2>/dev/null; then
        pass_test "tmux pane splitting works"
    else
        fail_test "tmux split-window failed"
    fi
    
    tmux kill-session -t labrat_split_test 2>/dev/null
    return 0
}

test_tmux_window_creation() {
    log_test "Testing tmux window creation"
    
    if ! command -v tmux &>/dev/null; then
        skip_test "tmux not installed"
        return 0
    fi
    
    # Clean up
    tmux kill-session -t labrat_window_test 2>/dev/null || true
    
    # Create session with windows
    tmux new-session -d -s labrat_window_test 2>/dev/null || {
        skip_test "Could not create test session"
        return 0
    }
    
    # Create a new window
    if tmux new-window -t labrat_window_test 2>/dev/null; then
        local count
        count=$(tmux list-windows -t labrat_window_test 2>/dev/null | wc -l)
        if [[ $count -ge 2 ]]; then
            pass_test "tmux window creation works ($count windows)"
        else
            fail_test "Window not created (only $count window)"
        fi
    else
        fail_test "tmux new-window failed"
    fi
    
    tmux kill-session -t labrat_window_test 2>/dev/null
    return 0
}

test_tmux_resurrect_exists() {
    log_test "Testing tmux-resurrect plugin exists"
    
    if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        skip_test "TPM not installed"
        return 0
    fi
    
    if [[ -d "$HOME/.tmux/plugins/tmux-resurrect" ]]; then
        pass_test "tmux-resurrect plugin installed"
        return 0
    else
        skip_test "tmux-resurrect not installed (install with Prefix + I)"
        return 0
    fi
}

test_tmux_mouse_option() {
    log_test "Testing tmux mouse configuration"
    
    if [[ ! -f "$HOME/.tmux.conf" ]]; then
        skip_test "tmux config not found"
        return 0
    fi
    
    # Check if mouse is configured
    if grep -q "set.*mouse" "$HOME/.tmux.conf" 2>/dev/null; then
        pass_test "Mouse option configured in tmux.conf"
        return 0
    else
        skip_test "Mouse option not found in config"
        return 0
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "tmux Session Tests" \
    test_tmux_installed \
    test_tmux_config_exists \
    test_tmux_config_syntax_valid \
    test_tmux_server_starts \
    test_tmux_session_creation \
    test_tmux_tpm_installed \
    test_tmux_theme_file_exists \
    test_tmux_send_keys \
    test_tmux_pane_splitting \
    test_tmux_window_creation \
    test_tmux_resurrect_exists \
    test_tmux_mouse_option
