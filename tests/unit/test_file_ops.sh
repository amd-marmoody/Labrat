#!/usr/bin/env bash
#
# Unit Tests: lib/file_ops.sh
# Tests atomic file operations, locking, transactions
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# Source the libraries under test
source "${LABRAT_ROOT}/lib/colors.sh"
source "${LABRAT_ROOT}/lib/constants.sh"
source "${LABRAT_ROOT}/lib/errors.sh"
source "${LABRAT_ROOT}/lib/file_ops.sh"

# Test temp directory
TEST_TEMP_DIR=""

setup() {
    TEST_TEMP_DIR=$(mktemp -d -t labrat-test-XXXXXX)
}

teardown() {
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
}

# ============================================================================
# Test Cases
# ============================================================================

test_ensure_dir_creates_directory() {
    setup
    local test_dir="${TEST_TEMP_DIR}/new/nested/dir"
    
    assert_false "[ -d '$test_dir' ]" "Directory should not exist initially"
    
    ensure_dir "$test_dir"
    
    assert_true "[ -d '$test_dir' ]" "Directory should be created"
    teardown
}

test_ensure_dir_with_permissions() {
    setup
    local test_dir="${TEST_TEMP_DIR}/perms_dir"
    
    ensure_dir "$test_dir" 750
    
    assert_true "[ -d '$test_dir' ]" "Directory should be created"
    
    local perms
    perms=$(stat -c "%a" "$test_dir" 2>/dev/null || stat -f "%OLp" "$test_dir" 2>/dev/null)
    assert_equals "750" "$perms" "Directory should have correct permissions"
    teardown
}

test_ensure_private_dir() {
    setup
    local test_dir="${TEST_TEMP_DIR}/private_dir"
    
    ensure_private_dir "$test_dir"
    
    assert_true "[ -d '$test_dir' ]" "Private directory should be created"
    
    local perms
    perms=$(stat -c "%a" "$test_dir" 2>/dev/null || stat -f "%OLp" "$test_dir" 2>/dev/null)
    assert_equals "700" "$perms" "Private directory should have 700 permissions"
    teardown
}

test_atomic_write_creates_file() {
    setup
    local test_file="${TEST_TEMP_DIR}/atomic_test.txt"
    local content="Hello, World!"
    
    atomic_write "$test_file" "$content"
    
    assert_true "[ -f '$test_file' ]" "File should be created"
    assert_equals "$content" "$(cat "$test_file")" "File should have correct content"
    teardown
}

test_atomic_write_with_permissions() {
    setup
    local test_file="${TEST_TEMP_DIR}/atomic_perms.txt"
    local content="Secret data"
    
    atomic_write "$test_file" "$content" 600
    
    local perms
    perms=$(stat -c "%a" "$test_file" 2>/dev/null || stat -f "%OLp" "$test_file" 2>/dev/null)
    assert_equals "600" "$perms" "File should have 600 permissions"
    teardown
}

test_atomic_write_overwrites_safely() {
    setup
    local test_file="${TEST_TEMP_DIR}/overwrite.txt"
    
    echo "Original content" > "$test_file"
    atomic_write "$test_file" "New content"
    
    assert_equals "New content" "$(cat "$test_file")" "File should be overwritten"
    teardown
}

test_safe_copy_basic() {
    setup
    local src="${TEST_TEMP_DIR}/source.txt"
    local dst="${TEST_TEMP_DIR}/dest.txt"
    
    echo "Source content" > "$src"
    
    safe_copy "$src" "$dst"
    
    assert_true "[ -f '$dst' ]" "Destination file should exist"
    assert_equals "Source content" "$(cat "$dst")" "Content should match"
    teardown
}

test_safe_copy_with_permissions() {
    setup
    local src="${TEST_TEMP_DIR}/source.txt"
    local dst="${TEST_TEMP_DIR}/dest_perms.txt"
    
    echo "Executable content" > "$src"
    
    safe_copy "$src" "$dst" 755
    
    local perms
    perms=$(stat -c "%a" "$dst" 2>/dev/null || stat -f "%OLp" "$dst" 2>/dev/null)
    assert_equals "755" "$perms" "Destination should have 755 permissions"
    teardown
}

test_file_locking_basic() {
    setup
    local lock_file="${TEST_TEMP_DIR}/test.lock"
    local result_file="${TEST_TEMP_DIR}/result.txt"
    
    # Test basic lock acquisition
    (
        with_lock "$lock_file" echo "locked" > "$result_file"
    )
    
    assert_equals "locked" "$(cat "$result_file")" "Command should execute under lock"
    assert_false "[ -f '$lock_file' ]" "Lock file should be cleaned up"
    teardown
}

test_transaction_commit() {
    setup
    local test_file="${TEST_TEMP_DIR}/trans.txt"
    
    echo "Original" > "$test_file"
    
    transaction_begin "test_tx"
    transaction_record "file" "$test_file"
    echo "Modified" > "$test_file"
    transaction_commit
    
    assert_equals "Modified" "$(cat "$test_file")" "Changes should persist after commit"
    teardown
}

test_transaction_rollback() {
    setup
    local test_file="${TEST_TEMP_DIR}/rollback.txt"
    
    echo "Original" > "$test_file"
    
    transaction_begin "rollback_tx"
    transaction_record "file" "$test_file"
    echo "Modified" > "$test_file"
    transaction_rollback
    
    assert_equals "Original" "$(cat "$test_file")" "Changes should be reverted after rollback"
    teardown
}

test_validate_path_safe() {
    # Test path validation
    assert_true "validate_path '/home/user/file.txt'" "Normal path should be valid"
    assert_true "validate_path './relative/path'" "Relative path should be valid"
    
    # These should fail
    assert_false "validate_path '/etc/passwd'" "System paths should be rejected"
    assert_false "validate_path '../../../etc/passwd'" "Path traversal should be rejected"
}

test_check_permissions_basic() {
    setup
    local test_file="${TEST_TEMP_DIR}/perms.txt"
    
    echo "test" > "$test_file"
    chmod 644 "$test_file"
    
    assert_true "check_file_permissions '$test_file' 'r'" "Should be readable"
    assert_true "check_file_permissions '$test_file' 'w'" "Should be writable by owner"
    teardown
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "file_ops.sh Unit Tests" \
    test_ensure_dir_creates_directory \
    test_ensure_dir_with_permissions \
    test_ensure_private_dir \
    test_atomic_write_creates_file \
    test_atomic_write_with_permissions \
    test_atomic_write_overwrites_safely \
    test_safe_copy_basic \
    test_safe_copy_with_permissions \
    test_file_locking_basic \
    test_transaction_commit \
    test_transaction_rollback \
    test_validate_path_safe \
    test_check_permissions_basic
