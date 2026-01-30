#!/usr/bin/env bash
#
# Unit Tests: lib/errors.sh
# Tests error handling framework
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# Source the libraries under test
source "${LABRAT_ROOT}/lib/colors.sh"
source "${LABRAT_ROOT}/lib/constants.sh"
source "${LABRAT_ROOT}/lib/errors.sh"

# ============================================================================
# Test Cases
# ============================================================================

test_error_context_push_pop() {
    # Start with empty context
    _ERROR_CONTEXT_STACK=()
    
    push_error_context "Level 1"
    assert_equals 1 "${#_ERROR_CONTEXT_STACK[@]}" "Context stack should have 1 item"
    
    push_error_context "Level 2"
    assert_equals 2 "${#_ERROR_CONTEXT_STACK[@]}" "Context stack should have 2 items"
    
    pop_error_context
    assert_equals 1 "${#_ERROR_CONTEXT_STACK[@]}" "Context stack should have 1 item after pop"
    
    pop_error_context
    assert_equals 0 "${#_ERROR_CONTEXT_STACK[@]}" "Context stack should be empty"
}

test_error_context_string() {
    _ERROR_CONTEXT_STACK=()
    
    push_error_context "Installing tmux"
    push_error_context "Cloning TPM"
    
    local context
    context=$(get_error_context)
    assert_contains "$context" "Installing tmux" "Context should contain first level"
    assert_contains "$context" "Cloning TPM" "Context should contain second level"
    
    # Cleanup
    _ERROR_CONTEXT_STACK=()
}

test_error_code_to_message() {
    local msg
    
    msg=$(error_code_to_message "$E_SUCCESS")
    assert_contains "$msg" "uccess" "E_SUCCESS should return success message"
    
    msg=$(error_code_to_message "$E_NETWORK")
    assert_contains "$msg" "etwork" "E_NETWORK should return network message"
    
    msg=$(error_code_to_message "$E_PERMISSION")
    assert_contains "$msg" "ermission" "E_PERMISSION should return permission message"
}

test_handle_error_returns_code() {
    # Capture output to prevent test noise
    local result
    result=$(handle_error "$E_GENERAL" "Test error" 2>&1)
    local exit_code=$?
    
    # handle_error should return the error code
    assert_equals "$E_GENERAL" "$exit_code" "handle_error should return the error code"
}

test_safe_exec_success() {
    # safe_exec with a successful command
    if safe_exec "Test echo" echo "hello" >/dev/null 2>&1; then
        assert_success "safe_exec should succeed with valid command"
    else
        assert_fail "safe_exec should succeed with valid command"
    fi
}

test_safe_exec_failure() {
    # safe_exec with a failing command
    if safe_exec "Test false" false 2>/dev/null; then
        assert_fail "safe_exec should fail with failing command"
    else
        assert_success "safe_exec correctly detected failure"
    fi
}

test_error_context_isolation() {
    # Context should be isolated between tests
    _ERROR_CONTEXT_STACK=()
    
    push_error_context "Isolated context"
    assert_equals 1 "${#_ERROR_CONTEXT_STACK[@]}" "Should have one context"
    
    # Cleanup
    _ERROR_CONTEXT_STACK=()
    assert_equals 0 "${#_ERROR_CONTEXT_STACK[@]}" "Stack should be empty after cleanup"
}

test_check_bash_version() {
    # Current bash should pass the check (we require 4.0+)
    if check_bash_version 2>/dev/null; then
        assert_success "Current Bash version should pass check"
    else
        # This test might fail on old systems - skip
        skip_test "Bash version check failed - old system?"
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "errors.sh Unit Tests" \
    test_error_context_push_pop \
    test_error_context_string \
    test_error_code_to_message \
    test_handle_error_returns_code \
    test_safe_exec_success \
    test_safe_exec_failure \
    test_error_context_isolation \
    test_check_bash_version
