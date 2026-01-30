#!/usr/bin/env bash
#
# LabRat User Isolation Tests
# Verifies that LabRat installations are isolated between users
#
# These tests run in Docker containers with multiple users to verify:
# - Files are not accessible to other users
# - SSH keys are completely isolated
# - Shell configurations don't leak
# - Environment variables don't leak
# - Binaries are only accessible to the installing user
#
# Usage:
#   ./tests/isolation/test_user_isolation.sh
#
# Requires: Docker
#

set -uo pipefail

# ============================================================================
# Setup
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
LABRAT_ROOT="$(dirname "$TESTS_DIR")"

# Source test libraries
source "${TESTS_DIR}/lib/test_framework.sh"
source "${TESTS_DIR}/lib/multi_user_helpers.sh"

# Global container reference
CONTAINER=""

# ============================================================================
# Test Setup and Teardown
# ============================================================================

setup_suite() {
    echo ""
    echo "Setting up isolation test environment..."
    
    # Check Docker availability
    if ! command -v docker &>/dev/null; then
        echo "ERROR: Docker is required for isolation tests"
        exit 1
    fi
    
    # Create multi-user container
    CONTAINER=$(create_multi_user_container) || {
        echo "ERROR: Failed to create test container"
        exit 1
    }
    
    echo "Container: $CONTAINER"
    
    # Copy LabRat source
    copy_labrat_to_container "$CONTAINER" || {
        echo "ERROR: Failed to copy LabRat to container"
        cleanup_container "$CONTAINER"
        exit 1
    }
    
    # Install LabRat as user A only
    echo "Installing LabRat as $TEST_USER_A..."
    install_labrat_as_user "$CONTAINER" "$TEST_USER_A" "tmux,fzf" || {
        echo "ERROR: Failed to install LabRat as $TEST_USER_A"
        cleanup_container "$CONTAINER"
        exit 1
    }
    
    # Create SSH key for user A
    echo "Creating SSH key for $TEST_USER_A..."
    create_ssh_key "$CONTAINER" "$TEST_USER_A" "github"
    
    echo "Setup complete!"
    echo ""
}

teardown_suite() {
    echo ""
    echo "Cleaning up..."
    if [[ -n "$CONTAINER" ]]; then
        cleanup_container "$CONTAINER"
    fi
    echo "Cleanup complete!"
}

# ============================================================================
# File Visibility Tests
# ============================================================================

run_file_visibility_tests() {
    suite "File Visibility Isolation"
    
    # Test: .labrat directory not accessible
    test_case "LabRat root directory not listable by other users"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".labrat" \
        "User B should not be able to list User A's .labrat directory"
    
    # Test: .local directory structure
    test_case "Local bin directory not listable by other users"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".local/bin" \
        "User B should not be able to list User A's .local/bin"
    
    # Test: Data directory
    test_case "LabRat data directory not accessible"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".local/share/labrat" \
        "User B should not access User A's labrat data"
    
    # Test: Config directory
    test_case "LabRat config directory not accessible"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".config/labrat" \
        "User B should not access User A's labrat config"
    
    # Test: tmux config
    test_case "tmux.conf not readable by other users"
    assert_file_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".tmux.conf" \
        "User B should not read User A's tmux.conf"
}

# ============================================================================
# SSH Key Isolation Tests (CRITICAL)
# ============================================================================

run_ssh_isolation_tests() {
    suite "SSH Key Isolation (CRITICAL)"
    
    # Test: .ssh directory
    test_case "SSH directory not listable by other users"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".ssh" \
        "CRITICAL: User B should not list User A's .ssh directory"
    
    # Test: labrat SSH subdirectory
    test_case "LabRat SSH key directory not accessible"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".ssh/labrat" \
        "CRITICAL: User B should not access User A's LabRat SSH keys"
    
    # Test: Private key not readable
    test_case "Private SSH key not readable by other users"
    assert_file_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".ssh/labrat/github" \
        "CRITICAL: User B must NOT be able to read User A's private SSH key!"
    
    # Test: SSH key permissions
    test_case "Private SSH key has 600 permissions"
    local perms
    perms=$(get_file_permissions "$CONTAINER" "$TEST_USER_A" "/home/$TEST_USER_A/.ssh/labrat/github")
    if [[ "$perms" == "600" ]]; then
        pass
    else
        fail "Private key should be 600, got: $perms"
    fi
    
    # Test: SSH directory permissions
    test_case "SSH directory has 700 permissions"
    perms=$(get_file_permissions "$CONTAINER" "$TEST_USER_A" "/home/$TEST_USER_A/.ssh")
    if [[ "$perms" == "700" ]]; then
        pass
    else
        fail "SSH directory should be 700, got: $perms"
    fi
}

# ============================================================================
# Shell Integration Isolation Tests
# ============================================================================

run_shell_isolation_tests() {
    suite "Shell Integration Isolation"
    
    # Test: User B's shell doesn't have LabRat
    test_case "User B shell doesn't load LabRat (LABRAT_ROOT unset)"
    assert_env_not_set "$CONTAINER" "$TEST_USER_B" "LABRAT_ROOT" \
        "User B should not have LABRAT_ROOT set"
    
    # Test: User B's PATH doesn't include User A's directories
    test_case "User B PATH doesn't include User A's directories"
    assert_path_isolated "$CONTAINER" "$TEST_USER_B" "$TEST_USER_A" \
        "User B's PATH should not contain User A's home directory"
    
    # Test: User B's bashrc doesn't have LabRat references
    test_case "User B's bashrc has no LabRat references"
    if bashrc_contains "$CONTAINER" "$TEST_USER_B" "labrat"; then
        fail "User B's bashrc should not mention labrat"
    else
        pass
    fi
    
    # Test: User B doesn't have labrat-menu command
    test_case "labrat-menu not available to User B"
    if command_available_to "$CONTAINER" "$TEST_USER_B" "labrat-menu"; then
        fail "User B should not have labrat-menu in PATH"
    else
        pass
    fi
    
    # Test: User B doesn't have tmux-theme command
    test_case "tmux-theme not available to User B"
    if command_available_to "$CONTAINER" "$TEST_USER_B" "tmux-theme"; then
        fail "User B should not have tmux-theme in PATH"
    else
        pass
    fi
}

# ============================================================================
# Binary Visibility Tests
# ============================================================================

run_binary_isolation_tests() {
    suite "Binary Isolation"
    
    # Test: Cannot execute User A's binaries
    test_case "User B cannot execute User A's labrat-menu"
    if can_user_execute "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".local/bin/labrat-menu"; then
        fail "User B should not be able to execute User A's labrat-menu"
    else
        pass
    fi
    
    # Test: User A's fzf not in User B's PATH
    test_case "fzf from User A not accessible to User B"
    if command_available_to "$CONTAINER" "$TEST_USER_B" "fzf"; then
        # Check if it's from user A's installation
        local fzf_path
        fzf_path=$(run_as_user "$CONTAINER" "$TEST_USER_B" "which fzf 2>/dev/null" || true)
        if [[ "$fzf_path" == *"$TEST_USER_A"* ]]; then
            fail "User B can access User A's fzf installation"
        else
            pass  # System fzf is fine
        fi
    else
        pass
    fi
}

# ============================================================================
# Environment Variable Isolation Tests
# ============================================================================

run_env_isolation_tests() {
    suite "Environment Variable Isolation"
    
    # List of LabRat environment variables
    local env_vars=(
        "LABRAT_ROOT"
        "LABRAT_PREFIX"
        "LABRAT_CONFIG_DIR"
        "LABRAT_DATA_DIR"
        "LABRAT_CACHE_DIR"
        "LABRAT_BIN_DIR"
    )
    
    for var in "${env_vars[@]}"; do
        test_case "Environment variable $var not set for User B"
        assert_env_not_set "$CONTAINER" "$TEST_USER_B" "$var" \
            "User B should not have $var set"
    done
    
    # Test third user as well
    test_case "Environment variable LABRAT_ROOT not set for User C"
    assert_env_not_set "$CONTAINER" "$TEST_USER_C" "LABRAT_ROOT" \
        "User C should not have LABRAT_ROOT set"
}

# ============================================================================
# Installed Module Marker Isolation
# ============================================================================

run_marker_isolation_tests() {
    suite "Installation Marker Isolation"
    
    # Test: Cannot read installation markers
    test_case "Installation markers not readable by other users"
    assert_dir_isolated "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".local/share/labrat/installed" \
        "User B should not be able to access installation markers"
    
    # Test: Cannot see what modules are installed
    test_case "Module list not visible to other users"
    local markers
    markers=$(run_as_user_full "$CONTAINER" "$TEST_USER_B" "ls /home/$TEST_USER_A/.local/share/labrat/installed/ 2>&1")
    if [[ "$markers" == *"Permission denied"* ]] || [[ "$markers" == *"cannot access"* ]]; then
        pass
    else
        fail "User B can see User A's installed modules"
    fi
}

# ============================================================================
# Write Protection Tests
# ============================================================================

run_write_protection_tests() {
    suite "Write Protection"
    
    # Test: Cannot write to User A's labrat directory
    test_case "User B cannot write to User A's labrat directory"
    if can_user_write "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".labrat/malicious.sh"; then
        fail "CRITICAL: User B can write to User A's labrat directory!"
    else
        pass
    fi
    
    # Test: Cannot write to User A's config
    test_case "User B cannot write to User A's config directory"
    if can_user_write "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".config/labrat/malicious"; then
        fail "User B can write to User A's config directory"
    else
        pass
    fi
    
    # Test: Cannot modify User A's tmux.conf
    test_case "User B cannot modify User A's tmux.conf"
    if can_user_write "$CONTAINER" "$TEST_USER_A" "$TEST_USER_B" ".tmux.conf"; then
        fail "User B can modify User A's tmux.conf"
    else
        pass
    fi
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           LabRat User Isolation Test Suite                       ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Setup
    setup_suite
    
    # Run all test suites
    run_file_visibility_tests
    run_ssh_isolation_tests
    run_shell_isolation_tests
    run_binary_isolation_tests
    run_env_isolation_tests
    run_marker_isolation_tests
    run_write_protection_tests
    
    # Print summary
    print_summary
    local result=$?
    
    # Teardown
    teardown_suite
    
    exit $result
}

# Handle cleanup on script exit
trap 'teardown_suite' EXIT

# Run tests
main "$@"
