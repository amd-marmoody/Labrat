#!/usr/bin/env bash
#
# LabRat Test Framework
# Provides test utilities, assertions, and reporting
#
# Features:
# - Test suite organization
# - Assertions (equals, contains, file exists, permissions, etc.)
# - Setup/teardown with isolated environments
# - Color-coded output
# - Summary reporting
#

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
LABRAT_ROOT="$(dirname "$TESTS_DIR")"

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# Test State
# ============================================================================

TEST_SUITE_NAME=""
TEST_CASE_NAME=""
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
declare -a TEST_FAILURES=()

# Test environment
TEST_TEMP_DIR=""
TEST_HOME=""

# ============================================================================
# Suite and Test Case Management
# ============================================================================

# Start a new test suite
# Usage: suite "Suite Name"
suite() {
    TEST_SUITE_NAME="$1"
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  Suite: ${TEST_SUITE_NAME}${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Start a new test case
# Usage: test_case "Test description"
test_case() {
    TEST_CASE_NAME="$1"
    echo -n -e "  ├─ ${TEST_CASE_NAME}: "
}

# Mark test as passed
pass() {
    echo -e "${GREEN}PASS${NC}"
    ((TESTS_PASSED++))
}

# Mark test as failed
# Usage: fail "reason"
fail() {
    local reason="${1:-}"
    echo -e "${RED}FAIL${NC}"
    if [[ -n "$reason" ]]; then
        echo -e "       └─ ${DIM}$reason${NC}"
    fi
    ((TESTS_FAILED++))
    TEST_FAILURES+=("${TEST_SUITE_NAME}::${TEST_CASE_NAME}: $reason")
}

# Mark test as skipped
# Usage: skip "reason"
skip() {
    local reason="${1:-}"
    echo -e "${YELLOW}SKIP${NC}"
    if [[ -n "$reason" ]]; then
        echo -e "       └─ ${DIM}$reason${NC}"
    fi
    ((TESTS_SKIPPED++))
}

# ============================================================================
# Assertions
# ============================================================================

# Assert two values are equal
# Usage: assert_equals "expected" "actual" "message"
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        pass
        return 0
    else
        fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

# Assert two values are not equal
# Usage: assert_not_equals "unexpected" "actual" "message"
assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-Values should not be equal}"
    
    if [[ "$unexpected" != "$actual" ]]; then
        pass
        return 0
    else
        fail "$message (got: '$actual')"
        return 1
    fi
}

# Assert a string contains a substring
# Usage: assert_contains "haystack" "needle" "message"
assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should contain substring}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        pass
        return 0
    else
        fail "$message (looking for '$needle')"
        return 1
    fi
}

# Assert a string does not contain a substring
# Usage: assert_not_contains "haystack" "needle" "message"
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String should not contain substring}"
    
    if [[ "$haystack" != *"$needle"* ]]; then
        pass
        return 0
    else
        fail "$message (found '$needle')"
        return 1
    fi
}

# Assert a condition is true
# Usage: assert_true "condition" "message"
assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    if eval "$condition"; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a condition is false
# Usage: assert_false "condition" "message"
assert_false() {
    local condition="$1"
    local message="${2:-Condition should be false}"
    
    if ! eval "$condition"; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a command exists
# Usage: assert_command_exists "command" "message"
assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command '$cmd' should exist}"
    
    if command -v "$cmd" &>/dev/null; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a command does not exist (in PATH)
# Usage: assert_command_not_exists "command" "message"
assert_command_not_exists() {
    local cmd="$1"
    local message="${2:-Command '$cmd' should not exist}"
    
    if ! command -v "$cmd" &>/dev/null; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a file exists
# Usage: assert_file_exists "/path/to/file" "message"
assert_file_exists() {
    local file="$1"
    local message="${2:-File '$file' should exist}"
    
    if [[ -f "$file" ]]; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a file does not exist
# Usage: assert_file_not_exists "/path/to/file" "message"
assert_file_not_exists() {
    local file="$1"
    local message="${2:-File '$file' should not exist}"
    
    if [[ ! -f "$file" ]]; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a directory exists
# Usage: assert_dir_exists "/path/to/dir" "message"
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory '$dir' should exist}"
    
    if [[ -d "$dir" ]]; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a directory does not exist
# Usage: assert_dir_not_exists "/path/to/dir" "message"
assert_dir_not_exists() {
    local dir="$1"
    local message="${2:-Directory '$dir' should not exist}"
    
    if [[ ! -d "$dir" ]]; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert file has specific permissions
# Usage: assert_file_permissions "/path/to/file" "600" "message"
assert_file_permissions() {
    local file="$1"
    local expected="$2"
    local message="${3:-File should have permissions $expected}"
    
    if [[ ! -e "$file" ]]; then
        fail "$message (file does not exist)"
        return 1
    fi
    
    local actual
    actual=$(stat -c "%a" "$file" 2>/dev/null)
    
    if [[ "$actual" == "$expected" ]]; then
        pass
        return 0
    else
        fail "$message (got: $actual)"
        return 1
    fi
}

# Assert a command succeeds
# Usage: assert_command_succeeds "command" "message"
assert_command_succeeds() {
    local cmd="$1"
    local message="${2:-Command should succeed}"
    
    if eval "$cmd" &>/dev/null; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert a command fails
# Usage: assert_command_fails "command" "message"
assert_command_fails() {
    local cmd="$1"
    local message="${2:-Command should fail}"
    
    if ! eval "$cmd" &>/dev/null; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert command output contains text
# Usage: assert_output_contains "command" "expected" "message"
assert_output_contains() {
    local cmd="$1"
    local expected="$2"
    local message="${3:-Output should contain '$expected'}"
    
    local output
    output=$(eval "$cmd" 2>&1)
    
    if [[ "$output" == *"$expected"* ]]; then
        pass
        return 0
    else
        fail "$message"
        return 1
    fi
}

# Assert command output does not contain text
# Usage: assert_output_not_contains "command" "unexpected" "message"
assert_output_not_contains() {
    local cmd="$1"
    local unexpected="$2"
    local message="${3:-Output should not contain '$unexpected'}"
    
    local output
    output=$(eval "$cmd" 2>&1)
    
    if [[ "$output" != *"$unexpected"* ]]; then
        pass
        return 0
    else
        fail "$message (found in output)"
        return 1
    fi
}

# Assert exit code
# Usage: assert_exit_code 0 "message"
# Note: Call immediately after the command you want to check
assert_exit_code() {
    local expected="$1"
    local actual="$?"
    local message="${2:-Exit code should be $expected}"
    
    if [[ "$actual" == "$expected" ]]; then
        pass
        return 0
    else
        fail "$message (got: $actual)"
        return 1
    fi
}

# Assert file is not readable by others (only owner)
# Usage: assert_file_private "/path/to/file" "message"
assert_file_private() {
    local file="$1"
    local message="${2:-File should be private (not readable by others)}"
    
    if [[ ! -e "$file" ]]; then
        fail "$message (file does not exist)"
        return 1
    fi
    
    local perms
    perms=$(stat -c "%a" "$file" 2>/dev/null)
    
    # Check that group and other permissions are 0
    local group_other="${perms:1:2}"
    if [[ "$group_other" == "00" ]]; then
        pass
        return 0
    else
        fail "$message (permissions: $perms)"
        return 1
    fi
}

# Assert directory is not accessible by others
# Usage: assert_dir_private "/path/to/dir" "message"
assert_dir_private() {
    local dir="$1"
    local message="${2:-Directory should be private}"
    
    if [[ ! -d "$dir" ]]; then
        fail "$message (directory does not exist)"
        return 1
    fi
    
    local perms
    perms=$(stat -c "%a" "$dir" 2>/dev/null)
    
    # For directories, 700 means only owner can access
    if [[ "$perms" == "700" ]]; then
        pass
        return 0
    else
        fail "$message (permissions: $perms)"
        return 1
    fi
}

# ============================================================================
# Test Environment Setup/Teardown
# ============================================================================

# Set up an isolated test environment
# Creates temp directory with isolated HOME
setup() {
    TEST_TEMP_DIR=$(mktemp -d -t labrat_test.XXXXXX)
    TEST_HOME="${TEST_TEMP_DIR}/home"
    mkdir -p "$TEST_HOME"
    
    # Save original HOME
    ORIGINAL_HOME="$HOME"
    
    # Export isolated environment
    export HOME="$TEST_HOME"
    export LABRAT_DATA_DIR="${TEST_TEMP_DIR}/data"
    export LABRAT_CACHE_DIR="${TEST_TEMP_DIR}/cache"
    export LABRAT_CONFIG_DIR="${TEST_HOME}/.config"
    
    mkdir -p "$LABRAT_DATA_DIR" "$LABRAT_CACHE_DIR" "$LABRAT_CONFIG_DIR"
}

# Tear down test environment
teardown() {
    # Restore original HOME
    if [[ -n "${ORIGINAL_HOME:-}" ]]; then
        export HOME="$ORIGINAL_HOME"
    fi
    
    # Clean up temp directory
    if [[ -n "$TEST_TEMP_DIR" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
    
    TEST_TEMP_DIR=""
    TEST_HOME=""
}

# Run a test function in isolation
# Usage: run_isolated test_function_name
run_isolated() {
    local test_func="$1"
    
    (
        setup
        "$test_func"
        local result=$?
        teardown
        exit $result
    )
}

# ============================================================================
# Test Discovery and Running
# ============================================================================

# Run all test functions in a file that start with "test_"
# Usage: run_all_tests
run_all_tests() {
    local funcs
    funcs=$(declare -F | grep -E "declare -f test_" | sed 's/declare -f //')
    
    for func in $funcs; do
        test_case "${func#test_}"
        if "$func"; then
            : # pass was called in assertion
        fi
    done
}

# Run a specific test file
# Usage: run_test_file "/path/to/test_file.sh"
run_test_file() {
    local test_file="$1"
    
    if [[ ! -f "$test_file" ]]; then
        echo -e "${RED}Test file not found: $test_file${NC}"
        return 1
    fi
    
    # Source the test file
    source "$test_file"
    
    # Run all tests
    run_all_tests
}

# ============================================================================
# Summary Reporting
# ============================================================================

# Print test summary
print_summary() {
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    
    echo ""
    echo -e "${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Test Summary${NC}"
    echo -e "${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "  ${BOLD}Total:${NC}   $total"
    echo ""
    
    if [[ ${#TEST_FAILURES[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}Failures:${NC}"
        for failure in "${TEST_FAILURES[@]}"; do
            echo -e "  ${RED}✗${NC} $failure"
        done
        echo ""
    fi
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "  ${RED}${BOLD}✗ Some tests failed${NC}"
        return 1
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Create a test file with content
# Usage: create_test_file "/path/to/file" "content"
create_test_file() {
    local path="$1"
    local content="${2:-}"
    
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
}

# Create a test directory
# Usage: create_test_dir "/path/to/dir" [permissions]
create_test_dir() {
    local path="$1"
    local perms="${2:-755}"
    
    mkdir -p "$path"
    chmod "$perms" "$path"
}

# Wait for a condition (polling)
# Usage: wait_for "condition" [timeout_seconds] [poll_interval]
wait_for() {
    local condition="$1"
    local timeout="${2:-10}"
    local interval="${3:-1}"
    
    local elapsed=0
    while ! eval "$condition" 2>/dev/null; do
        sleep "$interval"
        ((elapsed += interval))
        if ((elapsed >= timeout)); then
            return 1
        fi
    done
    return 0
}

# Check if running in Docker
is_docker() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Skip test if condition is true
# Usage: skip_if "is_root" "Skipping: requires non-root"
skip_if() {
    local condition="$1"
    local reason="$2"
    
    if eval "$condition"; then
        skip "$reason"
        return 0
    fi
    return 1
}

# Skip test unless condition is true
# Usage: skip_unless "is_docker" "Skipping: requires Docker"
skip_unless() {
    local condition="$1"
    local reason="$2"
    
    if ! eval "$condition"; then
        skip "$reason"
        return 0
    fi
    return 1
}
