#!/usr/bin/env bash
#
# LabRat - Safe File Operations
# Provides atomic file operations, secure permissions, and rollback support
#
# Features:
# - Atomic writes (temp file + rename)
# - Secure permission handling (set before writing)
# - Backup creation
# - Symlink management
# - Transaction support
#

# Ensure dependencies are loaded
LABRAT_LIB_DIR="${LABRAT_LIB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# shellcheck source=./constants.sh
if [[ -z "${E_SUCCESS:-}" ]]; then
    source "${LABRAT_LIB_DIR}/constants.sh"
fi

# shellcheck source=./errors.sh
if ! declare -f handle_error &>/dev/null; then
    source "${LABRAT_LIB_DIR}/errors.sh"
fi

# ============================================================================
# Directory Operations
# ============================================================================

# Create a directory with proper error handling and permissions
# Usage: ensure_dir "/path/to/dir" [permissions]
# Default permissions: 755 (PERM_CONFIG_DIR)
ensure_dir() {
    local dir="$1"
    local permissions="${2:-$PERM_CONFIG_DIR}"
    
    if [[ -z "$dir" ]]; then
        handle_error $E_INVALID_INPUT "ensure_dir: directory path required"
        return $E_INVALID_INPUT
    fi
    
    if [[ -d "$dir" ]]; then
        # Directory exists, optionally fix permissions
        if [[ -n "$permissions" ]] && [[ "$permissions" != "0" ]]; then
            chmod "$permissions" "$dir" 2>/dev/null || true
        fi
        return 0
    fi
    
    # Create the directory
    if ! mkdir -p "$dir" 2>/dev/null; then
        handle_error $E_PERMISSION "Cannot create directory: $dir"
        return $E_PERMISSION
    fi
    
    # Set permissions
    if [[ -n "$permissions" ]] && [[ "$permissions" != "0" ]]; then
        chmod "$permissions" "$dir" || {
            handle_error $E_PERMISSION "Cannot set permissions on: $dir"
            return $E_PERMISSION
        }
    fi
    
    debug "Created directory: $dir (mode: $permissions)"
    return 0
}

# Create a private directory (700 permissions)
# Usage: ensure_private_dir "/path/to/dir"
ensure_private_dir() {
    local dir="$1"
    ensure_dir "$dir" "$PERM_PRIVATE_DIR"
}

# Recursively ensure a path's parent directories exist
# Usage: ensure_parent_dir "/path/to/file"
ensure_parent_dir() {
    local path="$1"
    local parent_dir
    parent_dir=$(dirname "$path")
    
    if [[ "$parent_dir" != "/" ]] && [[ "$parent_dir" != "." ]]; then
        ensure_dir "$parent_dir"
    fi
}

# ============================================================================
# Secure Temp File Operations
# ============================================================================

# Create a secure temporary file
# Usage: secure_temp [prefix] [dir]
# Returns: Path to temp file (or empty on failure)
secure_temp() {
    local prefix="${1:-labrat}"
    local temp_dir="${2:-${LABRAT_CACHE_DIR:-/tmp}}"
    
    # Ensure temp directory exists with private permissions
    ensure_dir "$temp_dir" "$PERM_PRIVATE_DIR" || return $?
    
    # Create temp file
    local temp_file
    temp_file=$(mktemp -p "$temp_dir" "${prefix}.XXXXXX" 2>/dev/null)
    
    if [[ -z "$temp_file" ]] || [[ ! -f "$temp_file" ]]; then
        handle_error $E_PERMISSION "Cannot create temp file in: $temp_dir"
        return $E_PERMISSION
    fi
    
    # Secure the temp file immediately
    chmod "$PERM_PRIVATE_FILE" "$temp_file"
    
    echo "$temp_file"
    return 0
}

# Create a secure temporary directory
# Usage: secure_temp_dir [prefix] [parent_dir]
secure_temp_dir() {
    local prefix="${1:-labrat}"
    local temp_dir="${2:-${LABRAT_CACHE_DIR:-/tmp}}"
    
    ensure_dir "$temp_dir" "$PERM_PRIVATE_DIR" || return $?
    
    local result
    result=$(mktemp -d -p "$temp_dir" "${prefix}.XXXXXX" 2>/dev/null)
    
    if [[ -z "$result" ]] || [[ ! -d "$result" ]]; then
        handle_error $E_PERMISSION "Cannot create temp directory in: $temp_dir"
        return $E_PERMISSION
    fi
    
    chmod "$PERM_PRIVATE_DIR" "$result"
    echo "$result"
    return 0
}

# ============================================================================
# Atomic File Operations
# ============================================================================

# Write content to a file atomically (write to temp, then rename)
# This prevents partial writes and ensures other processes see complete file
# Usage: atomic_write "/path/to/file" "content" [permissions]
atomic_write() {
    local target="$1"
    local content="$2"
    local permissions="${3:-$PERM_CONFIG_FILE}"
    
    if [[ -z "$target" ]]; then
        handle_error $E_INVALID_INPUT "atomic_write: target path required"
        return $E_INVALID_INPUT
    fi
    
    local dir
    dir=$(dirname "$target")
    
    # Ensure parent directory exists
    ensure_dir "$dir" || return $?
    
    # Create temp file in same directory (for same filesystem atomic rename)
    local temp_file
    temp_file=$(mktemp -p "$dir" ".tmp.XXXXXX" 2>/dev/null)
    
    if [[ -z "$temp_file" ]] || [[ ! -f "$temp_file" ]]; then
        handle_error $E_PERMISSION "Cannot create temp file in: $dir"
        return $E_PERMISSION
    fi
    
    # SECURITY: Set permissions BEFORE writing content
    if ! chmod "$permissions" "$temp_file" 2>/dev/null; then
        rm -f "$temp_file" 2>/dev/null
        handle_error $E_PERMISSION "Cannot set permissions on temp file"
        return $E_PERMISSION
    fi
    
    # Write content to temp file
    if ! echo "$content" > "$temp_file" 2>/dev/null; then
        rm -f "$temp_file" 2>/dev/null
        handle_error $E_GENERAL "Cannot write content to temp file"
        return $E_GENERAL
    fi
    
    # Sync to disk (optional, for extra safety)
    sync "$temp_file" 2>/dev/null || true
    
    # Atomic rename
    if ! mv "$temp_file" "$target" 2>/dev/null; then
        rm -f "$temp_file" 2>/dev/null
        handle_error $E_PERMISSION "Cannot move temp file to target: $target"
        return $E_PERMISSION
    fi
    
    debug "Atomic write complete: $target (mode: $permissions)"
    return 0
}

# Write content to a file atomically without trailing newline
# Usage: atomic_write_exact "/path/to/file" "content" [permissions]
atomic_write_exact() {
    local target="$1"
    local content="$2"
    local permissions="${3:-$PERM_CONFIG_FILE}"
    
    if [[ -z "$target" ]]; then
        handle_error $E_INVALID_INPUT "atomic_write_exact: target path required"
        return $E_INVALID_INPUT
    fi
    
    local dir
    dir=$(dirname "$target")
    ensure_dir "$dir" || return $?
    
    local temp_file
    temp_file=$(mktemp -p "$dir" ".tmp.XXXXXX" 2>/dev/null) || {
        handle_error $E_PERMISSION "Cannot create temp file in: $dir"
        return $E_PERMISSION
    }
    
    chmod "$permissions" "$temp_file" 2>/dev/null || {
        rm -f "$temp_file"
        handle_error $E_PERMISSION "Cannot set permissions"
        return $E_PERMISSION
    }
    
    printf '%s' "$content" > "$temp_file" 2>/dev/null || {
        rm -f "$temp_file"
        handle_error $E_GENERAL "Cannot write content"
        return $E_GENERAL
    }
    
    mv "$temp_file" "$target" 2>/dev/null || {
        rm -f "$temp_file"
        handle_error $E_PERMISSION "Cannot rename to: $target"
        return $E_PERMISSION
    }
    
    return 0
}

# ============================================================================
# Safe Copy Operations
# ============================================================================

# Copy a file with proper error handling and optional permission setting
# Usage: safe_copy "/source" "/target" [permissions]
safe_copy() {
    local source="$1"
    local target="$2"
    local permissions="${3:-}"
    
    # Validate source
    if [[ ! -f "$source" ]]; then
        handle_error $E_FILE_NOT_FOUND "Source file not found: $source"
        return $E_FILE_NOT_FOUND
    fi
    
    if [[ ! -r "$source" ]]; then
        handle_error $E_PERMISSION "Source file not readable: $source"
        return $E_PERMISSION
    fi
    
    # Ensure target directory exists
    ensure_parent_dir "$target" || return $?
    
    # Use install command if permissions specified (sets perms atomically)
    if [[ -n "$permissions" ]]; then
        if ! install -m "$permissions" "$source" "$target" 2>/dev/null; then
            handle_error $E_PERMISSION "Cannot copy $source to $target with mode $permissions"
            return $E_PERMISSION
        fi
    else
        # Preserve permissions from source
        if ! cp -p "$source" "$target" 2>/dev/null; then
            handle_error $E_PERMISSION "Cannot copy $source to $target"
            return $E_PERMISSION
        fi
    fi
    
    debug "Copied: $source -> $target"
    return 0
}

# Copy a file to a location with private (600) permissions
# Usage: safe_copy_private "/source" "/target"
safe_copy_private() {
    local source="$1"
    local target="$2"
    safe_copy "$source" "$target" "$PERM_PRIVATE_FILE"
}

# Copy a file to a location making it executable (755)
# Usage: safe_copy_script "/source" "/target"
safe_copy_script() {
    local source="$1"
    local target="$2"
    safe_copy "$source" "$target" "$PERM_SCRIPT"
}

# ============================================================================
# Backup Operations
# ============================================================================

# Create a backup of a file before modifying it
# Usage: backup_file "/path/to/file" [backup_dir]
# Returns: Path to backup file
backup_file() {
    local file="$1"
    local backup_dir="${2:-$(get_backups_dir)}"
    
    if [[ ! -f "$file" ]]; then
        # Nothing to backup
        return 0
    fi
    
    ensure_dir "$backup_dir" "$PERM_PRIVATE_DIR" || return $?
    
    local basename
    basename=$(basename "$file")
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${backup_dir}/${basename}.${timestamp}.bak"
    
    if ! cp -p "$file" "$backup_path" 2>/dev/null; then
        handle_error $E_PERMISSION "Cannot create backup: $backup_path"
        return $E_PERMISSION
    fi
    
    debug "Created backup: $backup_path"
    echo "$backup_path"
    return 0
}

# Restore a file from backup
# Usage: restore_backup "/path/to/backup" "/path/to/target"
restore_backup() {
    local backup="$1"
    local target="$2"
    
    if [[ ! -f "$backup" ]]; then
        handle_error $E_FILE_NOT_FOUND "Backup file not found: $backup"
        return $E_FILE_NOT_FOUND
    fi
    
    if ! cp -p "$backup" "$target" 2>/dev/null; then
        handle_error $E_PERMISSION "Cannot restore from backup"
        return $E_PERMISSION
    fi
    
    debug "Restored from backup: $backup -> $target"
    return 0
}

# ============================================================================
# Symlink Operations
# ============================================================================

# Create a symlink safely (removing existing file if necessary)
# Usage: safe_symlink "/source" "/target"
safe_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ -z "$source" ]] || [[ -z "$target" ]]; then
        handle_error $E_INVALID_INPUT "safe_symlink: source and target required"
        return $E_INVALID_INPUT
    fi
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        handle_error $E_FILE_NOT_FOUND "Symlink source not found: $source"
        return $E_FILE_NOT_FOUND
    fi
    
    # Ensure parent directory exists
    ensure_parent_dir "$target" || return $?
    
    # Remove existing target (file, symlink, or directory)
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
            handle_error $E_GENERAL "Cannot replace directory with symlink: $target"
            return $E_GENERAL
        fi
        rm -f "$target" 2>/dev/null || {
            handle_error $E_PERMISSION "Cannot remove existing file: $target"
            return $E_PERMISSION
        }
    fi
    
    # Create symlink
    if ! ln -s "$source" "$target" 2>/dev/null; then
        handle_error $E_PERMISSION "Cannot create symlink: $target -> $source"
        return $E_PERMISSION
    fi
    
    debug "Created symlink: $target -> $source"
    return 0
}

# ============================================================================
# File Locking
# ============================================================================

# Acquire a file lock (blocking with timeout)
# Usage: acquire_lock "/path/to/lockfile" [timeout_seconds]
# Returns: 0 on success, E_LOCK_FAILED on timeout
# Note: Sets LABRAT_LOCK_FD for use with release_lock
LABRAT_LOCK_FD=""

acquire_lock() {
    local lockfile="$1"
    local timeout="${2:-$LOCK_TIMEOUT}"
    
    # Ensure lock file directory exists
    ensure_parent_dir "$lockfile" || return $?
    
    # Open lock file for writing (creates if not exists)
    exec 200>"$lockfile" || {
        handle_error $E_LOCK_FAILED "Cannot open lock file: $lockfile"
        return $E_LOCK_FAILED
    }
    
    LABRAT_LOCK_FD=200
    
    # Try to acquire exclusive lock with timeout
    if ! flock -w "$timeout" 200; then
        handle_error $E_LOCK_FAILED "Cannot acquire lock (timeout after ${timeout}s): $lockfile"
        exec 200>&- 2>/dev/null
        LABRAT_LOCK_FD=""
        return $E_LOCK_FAILED
    fi
    
    debug "Acquired lock: $lockfile"
    return 0
}

# Release a file lock
# Usage: release_lock
release_lock() {
    if [[ -n "$LABRAT_LOCK_FD" ]]; then
        flock -u "$LABRAT_LOCK_FD" 2>/dev/null || true
        eval "exec ${LABRAT_LOCK_FD}>&-" 2>/dev/null || true
        LABRAT_LOCK_FD=""
        debug "Released lock"
    fi
}

# Execute a command while holding a lock
# Usage: with_lock "/path/to/lockfile" command arg1 arg2 ...
with_lock() {
    local lockfile="$1"
    shift
    local cmd=("$@")
    
    acquire_lock "$lockfile" || return $?
    
    # Run command, capturing exit code
    local exit_code
    "${cmd[@]}"
    exit_code=$?
    
    release_lock
    
    return $exit_code
}

# ============================================================================
# Transaction Support
# ============================================================================

# Transaction state
_LABRAT_TRANSACTION_ACTIVE=false
_LABRAT_TRANSACTION_NAME=""
declare -a _LABRAT_TRANSACTION_CHANGES=()
declare -a _LABRAT_TRANSACTION_BACKUPS=()

# Start a new transaction
# Usage: transaction_begin "operation_name"
transaction_begin() {
    local name="${1:-unnamed}"
    
    if [[ "$_LABRAT_TRANSACTION_ACTIVE" == "true" ]]; then
        verbose "Transaction already active, committing first"
        transaction_commit
    fi
    
    _LABRAT_TRANSACTION_ACTIVE=true
    _LABRAT_TRANSACTION_NAME="$name"
    _LABRAT_TRANSACTION_CHANGES=()
    _LABRAT_TRANSACTION_BACKUPS=()
    
    debug "Transaction started: $name"
}

# Record a file change in the current transaction
# Usage: transaction_record "type" "/path/to/file" [original_path]
# Types: file, dir, symlink, marker
transaction_record() {
    local type="$1"
    local path="$2"
    local original="${3:-}"
    
    if [[ "$_LABRAT_TRANSACTION_ACTIVE" != "true" ]]; then
        return 0  # No active transaction, nothing to record
    fi
    
    _LABRAT_TRANSACTION_CHANGES+=("${type}:${path}")
    
    # Create backup of original if it exists
    if [[ -n "$original" ]] && [[ -f "$original" ]]; then
        local backup
        backup=$(backup_file "$original")
        if [[ -n "$backup" ]]; then
            _LABRAT_TRANSACTION_BACKUPS+=("${path}:${backup}")
        fi
    fi
}

# Commit the current transaction (discard rollback data)
# Usage: transaction_commit
transaction_commit() {
    if [[ "$_LABRAT_TRANSACTION_ACTIVE" != "true" ]]; then
        return 0
    fi
    
    debug "Transaction committed: $_LABRAT_TRANSACTION_NAME (${#_LABRAT_TRANSACTION_CHANGES[@]} changes)"
    
    _LABRAT_TRANSACTION_ACTIVE=false
    _LABRAT_TRANSACTION_NAME=""
    _LABRAT_TRANSACTION_CHANGES=()
    _LABRAT_TRANSACTION_BACKUPS=()
}

# Rollback the current transaction
# Usage: transaction_rollback
transaction_rollback() {
    if [[ "$_LABRAT_TRANSACTION_ACTIVE" != "true" ]]; then
        return 0
    fi
    
    verbose "Rolling back transaction: $_LABRAT_TRANSACTION_NAME"
    
    # Restore backups first
    local entry
    for entry in "${_LABRAT_TRANSACTION_BACKUPS[@]}"; do
        local path="${entry%%:*}"
        local backup="${entry#*:}"
        if [[ -f "$backup" ]]; then
            mv "$backup" "$path" 2>/dev/null || true
            debug "Restored: $path from $backup"
        fi
    done
    
    # Remove created files/directories
    for entry in "${_LABRAT_TRANSACTION_CHANGES[@]}"; do
        local type="${entry%%:*}"
        local path="${entry#*:}"
        case "$type" in
            file|symlink|marker)
                rm -f "$path" 2>/dev/null || true
                ;;
            dir)
                rmdir "$path" 2>/dev/null || true
                ;;
        esac
    done
    
    _LABRAT_TRANSACTION_ACTIVE=false
    _LABRAT_TRANSACTION_NAME=""
    _LABRAT_TRANSACTION_CHANGES=()
    _LABRAT_TRANSACTION_BACKUPS=()
    
    verbose "Rollback complete"
}

# Check if a transaction is active
is_transaction_active() {
    [[ "$_LABRAT_TRANSACTION_ACTIVE" == "true" ]]
}

# ============================================================================
# File Verification
# ============================================================================

# Calculate SHA256 checksum of a file
# Usage: file_sha256 "/path/to/file"
file_sha256() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if command -v sha256sum &>/dev/null; then
        sha256sum "$file" | cut -d' ' -f1
    elif command -v shasum &>/dev/null; then
        shasum -a 256 "$file" | cut -d' ' -f1
    else
        handle_error $E_MISSING_DEP "No SHA256 tool available"
        return $E_MISSING_DEP
    fi
}

# Verify file checksum
# Usage: verify_checksum "/path/to/file" "expected_sha256"
verify_checksum() {
    local file="$1"
    local expected="$2"
    
    local actual
    actual=$(file_sha256 "$file") || return $?
    
    if [[ "$actual" != "$expected" ]]; then
        handle_error $E_CHECKSUM_MISMATCH "Checksum mismatch for $file (expected: $expected, got: $actual)"
        return $E_CHECKSUM_MISMATCH
    fi
    
    debug "Checksum verified: $file"
    return 0
}

# ============================================================================
# Cleanup Operations
# ============================================================================

# Remove old files matching a pattern
# Usage: cleanup_old_files "/path/to/dir" "*.bak" 7
# Args: directory, pattern, days_old
cleanup_old_files() {
    local dir="$1"
    local pattern="${2:-*}"
    local days="${3:-$LOG_RETENTION_DAYS}"
    
    if [[ ! -d "$dir" ]]; then
        return 0
    fi
    
    find "$dir" -maxdepth 1 -name "$pattern" -type f -mtime +"$days" -delete 2>/dev/null || true
    debug "Cleaned up files older than ${days} days in: $dir"
}

# Clean up LabRat temp files
cleanup_temp_files() {
    local temp_dir="${LABRAT_CACHE_DIR:-/tmp}"
    find "$temp_dir" -maxdepth 1 -name "labrat.*" -type f -mtime +1 -delete 2>/dev/null || true
    find "$temp_dir" -maxdepth 1 -name ".tmp.*" -type f -mtime +1 -delete 2>/dev/null || true
}

# ============================================================================
# Path Validation
# ============================================================================

# Validate that a path is safe and doesn't contain dangerous patterns
# Usage: validate_path "/path/to/check"
# Returns: 0 if valid, E_INVALID_INPUT if dangerous
validate_path() {
    local path="$1"
    
    if [[ -z "$path" ]]; then
        handle_error $E_INVALID_INPUT "validate_path: empty path"
        return $E_INVALID_INPUT
    fi
    
    # Check for dangerous shell metacharacters
    # Note: Bash cannot store null bytes in variables, so we skip that check
    if [[ "$path" =~ [\;\|\&\$\`\<\>] ]]; then
        handle_error $E_INVALID_INPUT "validate_path: dangerous characters in path"
        return $E_INVALID_INPUT
    fi
    
    # Check for command substitution patterns
    if [[ "$path" == *'$('* ]] || [[ "$path" == *'`'* ]]; then
        handle_error $E_INVALID_INPUT "validate_path: command substitution in path"
        return $E_INVALID_INPUT
    fi
    
    return 0
}

# ============================================================================
# Permission Checking
# ============================================================================

# Check file permissions match expected value
# Usage: check_file_permissions "/path/to/file" "600"
# Returns: 0 if match, 1 if mismatch or error
check_file_permissions() {
    local file="$1"
    local expected="$2"
    
    if [[ -z "$file" ]]; then
        handle_error $E_INVALID_INPUT "check_file_permissions: file path required"
        return $E_INVALID_INPUT
    fi
    
    if [[ -z "$expected" ]]; then
        handle_error $E_INVALID_INPUT "check_file_permissions: expected permissions required"
        return $E_INVALID_INPUT
    fi
    
    if [[ ! -e "$file" ]]; then
        handle_error $E_FILE_NOT_FOUND "check_file_permissions: file not found: $file"
        return $E_FILE_NOT_FOUND
    fi
    
    # Get current permissions
    local actual
    if command -v stat &>/dev/null; then
        # Linux stat
        actual=$(stat -c '%a' "$file" 2>/dev/null)
        if [[ -z "$actual" ]]; then
            # macOS stat
            actual=$(stat -f '%Lp' "$file" 2>/dev/null)
        fi
    fi
    
    if [[ -z "$actual" ]]; then
        handle_error $E_GENERAL "check_file_permissions: cannot determine permissions"
        return $E_GENERAL
    fi
    
    # Normalize both values (remove leading zeros)
    expected="${expected#0}"
    expected="${expected#0}"
    actual="${actual#0}"
    actual="${actual#0}"
    
    if [[ "$actual" != "$expected" ]]; then
        verbose "Permission mismatch: $file (expected: $expected, got: $actual)"
        return 1
    fi
    
    return 0
}

# Check if file has secure permissions (not world-readable/writable)
# Usage: check_secure_permissions "/path/to/file"
# Returns: 0 if secure, 1 if insecure
check_secure_permissions() {
    local file="$1"
    
    if [[ ! -e "$file" ]]; then
        return 0  # Non-existent file is "secure"
    fi
    
    local perms
    perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null)
    
    if [[ -z "$perms" ]]; then
        return 1
    fi
    
    # Check world permissions (last digit)
    local world_perms="${perms: -1}"
    if [[ "$world_perms" != "0" ]]; then
        verbose "File has world permissions: $file (mode: $perms)"
        return 1
    fi
    
    return 0
}
