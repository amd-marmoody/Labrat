#!/usr/bin/env bash
#
# LabRat Multi-User Test Helpers
# Utilities for testing user isolation in Docker containers
#
# These helpers create containers with multiple users to verify
# that LabRat installations are isolated between users.
#

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="$(dirname "$SCRIPT_DIR")"
LABRAT_ROOT="$(dirname "$TESTS_DIR")"

# Default container settings
ISOLATION_CONTAINER_PREFIX="labrat-isolation-test"
ISOLATION_IMAGE_BASE="ubuntu:22.04"

# Test users
TEST_USER_A="testuser_a"
TEST_USER_B="testuser_b"
TEST_USER_C="testuser_c"
TEST_USER_PASSWORD="password123"

# ============================================================================
# Container Management
# ============================================================================

# Create a multi-user test container
# Usage: create_multi_user_container [container_name]
# Returns: Container name
create_multi_user_container() {
    local container_name="${1:-${ISOLATION_CONTAINER_PREFIX}-$$}"
    
    # Check if Docker is available
    if ! command -v docker &>/dev/null; then
        echo "ERROR: Docker is required for isolation tests" >&2
        return 1
    fi
    
    # Create container
    docker run -d --name "$container_name" \
        --privileged \
        "$ISOLATION_IMAGE_BASE" \
        tail -f /dev/null >/dev/null 2>&1 || {
        echo "ERROR: Failed to create container" >&2
        return 1
    }
    
    # Wait for container to be ready
    sleep 1
    
    # Install required packages
    docker exec "$container_name" bash -c '
        apt-get update -qq >/dev/null 2>&1
        apt-get install -y -qq sudo git curl >/dev/null 2>&1
    ' || {
        echo "ERROR: Failed to install packages in container" >&2
        cleanup_container "$container_name"
        return 1
    }
    
    # Create test users
    docker exec "$container_name" bash -c "
        # Create users with home directories
        useradd -m -s /bin/bash $TEST_USER_A
        useradd -m -s /bin/bash $TEST_USER_B
        useradd -m -s /bin/bash $TEST_USER_C
        
        # Set passwords
        echo '$TEST_USER_A:$TEST_USER_PASSWORD' | chpasswd
        echo '$TEST_USER_B:$TEST_USER_PASSWORD' | chpasswd
        echo '$TEST_USER_C:$TEST_USER_PASSWORD' | chpasswd
        
        # Set home directory permissions (restrictive by default)
        chmod 750 /home/$TEST_USER_A
        chmod 750 /home/$TEST_USER_B
        chmod 750 /home/$TEST_USER_C
    " || {
        echo "ERROR: Failed to create users in container" >&2
        cleanup_container "$container_name"
        return 1
    }
    
    echo "$container_name"
    return 0
}

# Clean up a test container
# Usage: cleanup_container container_name
cleanup_container() {
    local container_name="$1"
    docker rm -f "$container_name" >/dev/null 2>&1 || true
}

# Clean up all isolation test containers
# Usage: cleanup_all_isolation_containers
cleanup_all_isolation_containers() {
    docker ps -a --filter "name=${ISOLATION_CONTAINER_PREFIX}" -q | xargs -r docker rm -f >/dev/null 2>&1 || true
}

# ============================================================================
# Command Execution as Users
# ============================================================================

# Run a command as a specific user in a container
# Usage: run_as_user container_name username command...
run_as_user() {
    local container="$1"
    local user="$2"
    shift 2
    local cmd="$*"
    
    docker exec "$container" su - "$user" -c "$cmd" 2>/dev/null
}

# Run a command and capture both stdout and stderr
# Usage: run_as_user_full container_name username command...
run_as_user_full() {
    local container="$1"
    local user="$2"
    shift 2
    local cmd="$*"
    
    docker exec "$container" su - "$user" -c "$cmd" 2>&1
}

# Check if a command succeeds as a user
# Usage: command_succeeds_as container user command
command_succeeds_as() {
    local container="$1"
    local user="$2"
    shift 2
    local cmd="$*"
    
    docker exec "$container" su - "$user" -c "$cmd" >/dev/null 2>&1
}

# ============================================================================
# LabRat Installation in Container
# ============================================================================

# Copy LabRat source to container
# Usage: copy_labrat_to_container container_name
copy_labrat_to_container() {
    local container="$1"
    
    docker cp "$LABRAT_ROOT" "${container}:/tmp/labrat-source" || {
        echo "ERROR: Failed to copy LabRat to container" >&2
        return 1
    }
    
    docker exec "$container" chmod -R 755 /tmp/labrat-source
    return 0
}

# Install LabRat as a specific user
# Usage: install_labrat_as_user container_name username [modules]
install_labrat_as_user() {
    local container="$1"
    local user="$2"
    local modules="${3:-tmux,fzf,starship}"
    
    # Ensure source is in container
    if ! docker exec "$container" test -d /tmp/labrat-source; then
        copy_labrat_to_container "$container" || return 1
    fi
    
    # Install as user
    run_as_user "$container" "$user" "
        cp -r /tmp/labrat-source ~/.labrat
        cd ~/.labrat
        ./install.sh --modules $modules --yes
    " || {
        echo "ERROR: Failed to install LabRat as $user" >&2
        return 1
    }
    
    return 0
}

# ============================================================================
# File Access Testing
# ============================================================================

# Check if a user can read a file belonging to another user
# Usage: can_user_read_file container owner_user target_user file_path
# file_path is relative to owner's home
# Returns: 0 if CAN read (BAD for isolation), 1 if CANNOT (GOOD)
can_user_read_file() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    local file_path="$4"
    
    local full_path="/home/${owner_user}/${file_path}"
    
    command_succeeds_as "$container" "$target_user" "cat '$full_path'"
}

# Check if a user can list a directory belonging to another user
# Usage: can_user_list_dir container owner_user target_user dir_path
can_user_list_dir() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    local dir_path="$4"
    
    local full_path="/home/${owner_user}/${dir_path}"
    
    command_succeeds_as "$container" "$target_user" "ls '$full_path'"
}

# Check if a user can execute a file belonging to another user
# Usage: can_user_execute container owner_user target_user file_path
can_user_execute() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    local file_path="$4"
    
    local full_path="/home/${owner_user}/${file_path}"
    
    command_succeeds_as "$container" "$target_user" "'$full_path' --help"
}

# Check if a user can write to a location
# Usage: can_user_write container owner_user target_user path
can_user_write() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    local path="$4"
    
    local full_path="/home/${owner_user}/${path}"
    
    command_succeeds_as "$container" "$target_user" "echo test >> '$full_path'"
}

# ============================================================================
# Permission Checking
# ============================================================================

# Get file permissions as user
# Usage: get_file_permissions container user path
get_file_permissions() {
    local container="$1"
    local user="$2"
    local path="$3"
    
    run_as_user "$container" "$user" "stat -c '%a' '$path'" 2>/dev/null
}

# Get file owner
# Usage: get_file_owner container user path
get_file_owner() {
    local container="$1"
    local user="$2"
    local path="$3"
    
    run_as_user "$container" "$user" "stat -c '%U' '$path'" 2>/dev/null
}

# Check if file exists for user
# Usage: file_exists_for_user container user path
file_exists_for_user() {
    local container="$1"
    local user="$2"
    local path="$3"
    
    command_succeeds_as "$container" "$user" "test -f '$path'"
}

# Check if directory exists for user
# Usage: dir_exists_for_user container user path
dir_exists_for_user() {
    local container="$1"
    local user="$2"
    local path="$3"
    
    command_succeeds_as "$container" "$user" "test -d '$path'"
}

# ============================================================================
# Environment Variable Checking
# ============================================================================

# Get environment variable value for user
# Usage: get_env_var container user var_name
get_env_var() {
    local container="$1"
    local user="$2"
    local var_name="$3"
    
    run_as_user "$container" "$user" "echo \$$var_name"
}

# Check if environment variable is set for user
# Usage: is_env_var_set container user var_name
is_env_var_set() {
    local container="$1"
    local user="$2"
    local var_name="$3"
    
    local value
    value=$(get_env_var "$container" "$user" "$var_name")
    [[ -n "$value" ]]
}

# Get PATH for user
# Usage: get_user_path container user
get_user_path() {
    local container="$1"
    local user="$2"
    
    run_as_user "$container" "$user" 'echo $PATH'
}

# Check if path contains directory
# Usage: path_contains container user directory
path_contains() {
    local container="$1"
    local user="$2"
    local directory="$3"
    
    local path
    path=$(get_user_path "$container" "$user")
    [[ "$path" == *"$directory"* ]]
}

# ============================================================================
# Shell Configuration Checking
# ============================================================================

# Get contents of user's bashrc
# Usage: get_bashrc container user
get_bashrc() {
    local container="$1"
    local user="$2"
    
    run_as_user "$container" "$user" 'cat ~/.bashrc 2>/dev/null'
}

# Check if bashrc contains string
# Usage: bashrc_contains container user string
bashrc_contains() {
    local container="$1"
    local user="$2"
    local string="$3"
    
    local bashrc
    bashrc=$(get_bashrc "$container" "$user")
    [[ "$bashrc" == *"$string"* ]]
}

# Check if command is available to user (in PATH after shell init)
# Usage: command_available_to container user command_name
command_available_to() {
    local container="$1"
    local user="$2"
    local cmd="$3"
    
    command_succeeds_as "$container" "$user" "command -v '$cmd'"
}

# ============================================================================
# SSH Key Isolation Helpers
# ============================================================================

# Create an SSH key for a user
# Usage: create_ssh_key container user key_name
create_ssh_key() {
    local container="$1"
    local user="$2"
    local key_name="${3:-test_key}"
    
    run_as_user "$container" "$user" "
        mkdir -p ~/.ssh/labrat
        chmod 700 ~/.ssh ~/.ssh/labrat
        ssh-keygen -t ed25519 -f ~/.ssh/labrat/$key_name -N '' -q
    "
}

# Check if another user can access SSH keys
# Usage: can_access_ssh_keys container owner_user target_user
can_access_ssh_keys() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    
    # Try to list SSH directory
    can_user_list_dir "$container" "$owner_user" "$target_user" ".ssh"
}

# ============================================================================
# Process Isolation Helpers
# ============================================================================

# Get environment of a process owned by user
# Usage: can_read_proc_environ container owner_user target_user pid
can_read_proc_environ() {
    local container="$1"
    local owner_user="$2"
    local target_user="$3"
    local pid="$4"
    
    command_succeeds_as "$container" "$target_user" "cat /proc/$pid/environ"
}

# Start a background process as user and return PID
# Usage: start_background_process container user command
start_background_process() {
    local container="$1"
    local user="$2"
    shift 2
    local cmd="$*"
    
    run_as_user "$container" "$user" "$cmd &>/dev/null & echo \$!"
}

# ============================================================================
# Test Assertions (Isolation-Specific)
# ============================================================================

# Source test framework if available
if [[ -f "${SCRIPT_DIR}/test_framework.sh" ]]; then
    source "${SCRIPT_DIR}/test_framework.sh"
fi

# Assert file is not accessible to other user
# Usage: assert_file_isolated container owner target file_path message
assert_file_isolated() {
    local container="$1"
    local owner="$2"
    local target="$3"
    local file_path="$4"
    local message="${5:-File should not be accessible to $target}"
    
    if can_user_read_file "$container" "$owner" "$target" "$file_path"; then
        if declare -f fail &>/dev/null; then
            fail "$message"
        else
            echo "FAIL: $message"
        fi
        return 1
    else
        if declare -f pass &>/dev/null; then
            pass
        else
            echo "PASS: $message"
        fi
        return 0
    fi
}

# Assert directory is not listable by other user
# Usage: assert_dir_isolated container owner target dir_path message
assert_dir_isolated() {
    local container="$1"
    local owner="$2"
    local target="$3"
    local dir_path="$4"
    local message="${5:-Directory should not be accessible to $target}"
    
    if can_user_list_dir "$container" "$owner" "$target" "$dir_path"; then
        if declare -f fail &>/dev/null; then
            fail "$message"
        else
            echo "FAIL: $message"
        fi
        return 1
    else
        if declare -f pass &>/dev/null; then
            pass
        else
            echo "PASS: $message"
        fi
        return 0
    fi
}

# Assert environment variable is not set for user
# Usage: assert_env_not_set container user var_name message
assert_env_not_set() {
    local container="$1"
    local user="$2"
    local var_name="$3"
    local message="${4:-Environment variable $var_name should not be set}"
    
    if is_env_var_set "$container" "$user" "$var_name"; then
        if declare -f fail &>/dev/null; then
            fail "$message"
        else
            echo "FAIL: $message"
        fi
        return 1
    else
        if declare -f pass &>/dev/null; then
            pass
        else
            echo "PASS: $message"
        fi
        return 0
    fi
}

# Assert PATH does not contain another user's directories
# Usage: assert_path_isolated container target_user owner_user message
assert_path_isolated() {
    local container="$1"
    local target_user="$2"
    local owner_user="$3"
    local message="${4:-PATH should not contain $owner_user directories}"
    
    if path_contains "$container" "$target_user" "/home/$owner_user"; then
        if declare -f fail &>/dev/null; then
            fail "$message"
        else
            echo "FAIL: $message"
        fi
        return 1
    else
        if declare -f pass &>/dev/null; then
            pass
        else
            echo "PASS: $message"
        fi
        return 0
    fi
}
