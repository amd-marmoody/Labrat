#!/usr/bin/env bash
#
# Unit Tests: lib/constants.sh
# Tests all constant definitions
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# Source the library under test
source "${LABRAT_ROOT}/lib/colors.sh"
source "${LABRAT_ROOT}/lib/constants.sh"

# ============================================================================
# Test Cases
# ============================================================================

test_permission_constants_defined() {
    assert_not_empty "$PERM_PRIVATE_FILE" "PERM_PRIVATE_FILE should be defined"
    assert_not_empty "$PERM_PRIVATE_DIR" "PERM_PRIVATE_DIR should be defined"
    assert_not_empty "$PERM_SCRIPT" "PERM_SCRIPT should be defined"
    assert_not_empty "$PERM_CONFIG_FILE" "PERM_CONFIG_FILE should be defined"
}

test_permission_values_valid() {
    assert_equals "600" "$PERM_PRIVATE_FILE" "PERM_PRIVATE_FILE should be 600"
    assert_equals "700" "$PERM_PRIVATE_DIR" "PERM_PRIVATE_DIR should be 700"
    assert_equals "755" "$PERM_SCRIPT" "PERM_SCRIPT should be 755"
    assert_equals "644" "$PERM_CONFIG_FILE" "PERM_CONFIG_FILE should be 644"
}

test_error_codes_defined() {
    assert_equals "0" "$E_SUCCESS" "E_SUCCESS should be 0"
    assert_equals "1" "$E_GENERAL" "E_GENERAL should be 1"
    assert_equals "2" "$E_MISSING_DEP" "E_MISSING_DEP should be 2"
    assert_equals "3" "$E_NETWORK" "E_NETWORK should be 3"
    assert_equals "4" "$E_PERMISSION" "E_PERMISSION should be 4"
    assert_equals "5" "$E_FILE_NOT_FOUND" "E_FILE_NOT_FOUND should be 5"
}

test_path_defaults_defined() {
    assert_not_empty "$LABRAT_DEFAULT_PREFIX" "LABRAT_DEFAULT_PREFIX should be defined"
    assert_contains "$LABRAT_DEFAULT_PREFIX" ".local" "Default prefix should contain .local"
}

test_bash_version_constant() {
    assert_not_empty "$LABRAT_MIN_BASH_VERSION" "LABRAT_MIN_BASH_VERSION should be defined"
}

test_shell_config_permissions() {
    assert_not_empty "${SHELL_CONFIG_PERM:-}" "SHELL_CONFIG_PERM should be defined"
    assert_not_empty "${SHELL_SCRIPT_PERM:-}" "SHELL_SCRIPT_PERM should be defined"
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "constants.sh Unit Tests" \
    test_permission_constants_defined \
    test_permission_values_valid \
    test_error_codes_defined \
    test_path_defaults_defined \
    test_bash_version_constant \
    test_shell_config_permissions
