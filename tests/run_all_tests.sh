#!/usr/bin/env bash
#
# LabRat - Run All Tests
# Comprehensive test runner for CI/CD
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0
SUITE_FAILURES=()

# ============================================================================
# Logging
# ============================================================================

log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

log_suite() {
    echo -e "${BLUE}[SUITE]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TOTAL_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TOTAL_FAILED++))
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
    ((TOTAL_SKIPPED++))
}

# ============================================================================
# Test Suite Runners
# ============================================================================

run_unit_tests() {
    log_header "Unit Tests"
    
    local unit_dir="${SCRIPT_DIR}/unit"
    
    if [[ ! -d "$unit_dir" ]]; then
        log_skip "No unit tests directory found"
        return 0
    fi
    
    for test_file in "$unit_dir"/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            local test_name=$(basename "$test_file" .sh)
            log_suite "Running: $test_name"
            
            if bash "$test_file"; then
                log_pass "$test_name"
            else
                log_fail "$test_name"
                SUITE_FAILURES+=("$test_name")
            fi
        fi
    done
}

run_integration_tests() {
    log_header "Integration Tests"
    
    local int_dir="${SCRIPT_DIR}/integration"
    
    if [[ ! -d "$int_dir" ]]; then
        log_skip "No integration tests directory found"
        return 0
    fi
    
    # Run in specific order for best coverage
    local test_order=(
        "test_configuration.sh"
        "test_theme_switching.sh"
        "test_functionality.sh"
        "test_module_install.sh"
    )
    
    for test_file in "${test_order[@]}"; do
        local full_path="$int_dir/$test_file"
        if [[ -f "$full_path" ]]; then
            local test_name=$(basename "$full_path" .sh)
            log_suite "Running: $test_name"
            
            if bash "$full_path"; then
                log_pass "$test_name"
            else
                log_fail "$test_name"
                SUITE_FAILURES+=("$test_name")
            fi
        fi
    done
    
    # Run any additional tests not in the order list
    for test_file in "$int_dir"/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            local base_name=$(basename "$test_file")
            # Skip if already run
            local already_run=false
            for ordered in "${test_order[@]}"; do
                [[ "$base_name" == "$ordered" ]] && already_run=true && break
            done
            [[ "$already_run" == true ]] && continue
            
            local test_name=$(basename "$test_file" .sh)
            log_suite "Running: $test_name"
            
            if bash "$test_file"; then
                log_pass "$test_name"
            else
                log_fail "$test_name"
                SUITE_FAILURES+=("$test_name")
            fi
        fi
    done
}

run_isolation_tests() {
    log_header "Isolation Tests"
    
    local iso_dir="${SCRIPT_DIR}/isolation"
    
    if [[ ! -d "$iso_dir" ]]; then
        log_skip "No isolation tests directory found"
        return 0
    fi
    
    for test_file in "$iso_dir"/test_*.sh; do
        if [[ -f "$test_file" ]]; then
            local test_name=$(basename "$test_file" .sh)
            log_suite "Running: $test_name"
            
            if bash "$test_file"; then
                log_pass "$test_name"
            else
                log_fail "$test_name"
                SUITE_FAILURES+=("$test_name")
            fi
        fi
    done
}

run_shellcheck() {
    log_header "ShellCheck Linting"
    
    local failed=0
    
    # Check main scripts
    for script in "$LABRAT_ROOT"/install.sh "$LABRAT_ROOT"/labrat_bootstrap.sh; do
        if [[ -f "$script" ]]; then
            log_suite "Checking: $(basename "$script")"
            if shellcheck -x "$script" 2>/dev/null; then
                log_pass "$(basename "$script")"
            else
                log_fail "$(basename "$script")"
                ((failed++))
            fi
        fi
    done
    
    # Check lib scripts
    for script in "$LABRAT_ROOT"/lib/*.sh; do
        if [[ -f "$script" ]]; then
            log_suite "Checking: lib/$(basename "$script")"
            if shellcheck -x "$script" 2>/dev/null; then
                log_pass "lib/$(basename "$script")"
            else
                log_fail "lib/$(basename "$script")"
                ((failed++))
            fi
        fi
    done
    
    return $failed
}

run_basic_sanity_checks() {
    log_header "Basic Sanity Checks"
    
    # Check that libraries can be sourced
    log_suite "Testing library loading"
    if bash -c "source '$LABRAT_ROOT/lib/common.sh'" 2>/dev/null; then
        log_pass "Libraries load without errors"
    else
        log_fail "Library loading failed"
        return 1
    fi
    
    # Check install script syntax
    log_suite "Testing install.sh syntax"
    if bash -n "$LABRAT_ROOT/install.sh" 2>/dev/null; then
        log_pass "install.sh syntax OK"
    else
        log_fail "install.sh syntax error"
        return 1
    fi
    
    # Check bootstrap script syntax
    log_suite "Testing labrat_bootstrap.sh syntax"
    if bash -n "$LABRAT_ROOT/labrat_bootstrap.sh" 2>/dev/null; then
        log_pass "labrat_bootstrap.sh syntax OK"
    else
        log_fail "labrat_bootstrap.sh syntax error"
        return 1
    fi
    
    return 0
}

run_quick_install_test() {
    log_header "Quick Install Test"
    
    log_suite "Testing dry-run installation"
    if LABRAT_DRY_RUN=1 "$LABRAT_ROOT/install.sh" -m htop -y >/dev/null 2>&1; then
        log_pass "Dry-run install works"
    else
        log_fail "Dry-run install failed"
        return 1
    fi
    
    return 0
}

install_test_modules() {
    log_header "Installing Test Modules"
    
    # Skip if running on host (not in container) and LABRAT_TESTING not set
    if [[ -z "${LABRAT_TESTING:-}" ]] && [[ ! -f /.dockerenv ]]; then
        log_skip "Skipping module install (not in test container)"
        log_suite "Set LABRAT_TESTING=1 to enable real installation"
        return 0
    fi
    
    # Install core modules needed for testing
    local test_modules="fzf,ripgrep,bat,fd,eza,starship,zoxide"
    
    log_suite "Installing modules: $test_modules"
    
    # Run installation with --yes and capture result
    if "$LABRAT_ROOT/install.sh" -m "$test_modules" -y 2>&1; then
        log_pass "Core modules installed"
    else
        log_fail "Module installation failed"
        return 1
    fi
    
    # Verify PATH includes installed binaries
    export PATH="$HOME/.local/bin:$PATH"
    
    # Check each module was installed
    local failed=0
    for module in fzf rg bat fd eza starship zoxide; do
        if command -v "$module" &>/dev/null; then
            log_pass "$module installed and in PATH"
        else
            log_fail "$module not found after install"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# Results Summary
# ============================================================================

print_summary() {
    log_header "Test Results Summary"
    
    local total=$((TOTAL_PASSED + TOTAL_FAILED + TOTAL_SKIPPED))
    
    echo -e "  ${GREEN}Passed:${NC}  $TOTAL_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TOTAL_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TOTAL_SKIPPED"
    echo -e "  ${BOLD}Total:${NC}   $total"
    echo ""
    
    if [[ ${#SUITE_FAILURES[@]} -gt 0 ]]; then
        echo -e "  ${RED}Failed Suites:${NC}"
        for suite in "${SUITE_FAILURES[@]}"; do
            echo -e "    - $suite"
        done
        echo ""
    fi
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
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
    local start_time=$(date +%s)
    
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║              LabRat Comprehensive Test Suite                 ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Run sanity checks first
    run_basic_sanity_checks || exit 1
    
    # Run unit tests
    run_unit_tests
    
    # Install test modules (before integration tests need them)
    install_test_modules
    
    # Run integration tests
    run_integration_tests
    
    # Run isolation tests (may require Docker)
    run_isolation_tests
    
    # Run quick install test
    run_quick_install_test
    
    # Run shellcheck if available
    if command -v shellcheck &>/dev/null; then
        run_shellcheck || true
    else
        log_skip "ShellCheck not installed"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo -e "${BOLD}Duration:${NC} ${duration}s"
    
    # Print summary and exit with appropriate code
    print_summary
}

main "$@"
