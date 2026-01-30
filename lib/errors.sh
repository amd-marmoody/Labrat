#!/usr/bin/env bash
#
# LabRat - Error Handling Framework
# Provides standardized error handling, context tracking, and error propagation
#
# Features:
# - Error code constants (imported from constants.sh)
# - Error context stack for nested operations
# - Unified error handler with logging
# - Safe command execution wrappers
# - Dependency checking
#

# Ensure constants are loaded
LABRAT_LIB_DIR="${LABRAT_LIB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# shellcheck source=./constants.sh
if [[ -z "${E_SUCCESS:-}" ]]; then
    source "${LABRAT_LIB_DIR}/constants.sh"
fi

# ============================================================================
# Error Context Stack
# ============================================================================

# Stack to track nested operation contexts (for meaningful error messages)
declare -a _LABRAT_ERROR_CONTEXT_STACK=()

# Push a new context onto the error stack
# Usage: push_error_context "Installing tmux"
push_error_context() {
    local context="$1"
    _LABRAT_ERROR_CONTEXT_STACK+=("$context")
}

# Pop the current context from the error stack
pop_error_context() {
    if [[ ${#_LABRAT_ERROR_CONTEXT_STACK[@]} -gt 0 ]]; then
        unset '_LABRAT_ERROR_CONTEXT_STACK[-1]'
    fi
}

# Get the current error context
get_error_context() {
    if [[ ${#_LABRAT_ERROR_CONTEXT_STACK[@]} -gt 0 ]]; then
        echo "${_LABRAT_ERROR_CONTEXT_STACK[-1]}"
    else
        echo "main"
    fi
}

# Get full context path (for deeply nested operations)
get_full_error_context() {
    local IFS=" > "
    echo "${_LABRAT_ERROR_CONTEXT_STACK[*]:-main}"
}

# Clear all error contexts (for fresh start)
clear_error_context() {
    _LABRAT_ERROR_CONTEXT_STACK=()
}

# ============================================================================
# Error Code to Message Mapping
# ============================================================================

# Get human-readable message for error code
error_code_message() {
    local code="$1"
    
    case "$code" in
        $E_SUCCESS)          echo "Success" ;;
        $E_GENERAL)          echo "General error" ;;
        $E_MISSING_DEP)      echo "Missing dependency" ;;
        $E_NETWORK)          echo "Network error" ;;
        $E_PERMISSION)       echo "Permission denied" ;;
        $E_FILE_NOT_FOUND)   echo "File not found" ;;
        $E_INVALID_INPUT)    echo "Invalid input" ;;
        $E_MODULE_FAILED)    echo "Module installation failed" ;;
        $E_LOCK_FAILED)      echo "Could not acquire lock" ;;
        $E_CHECKSUM_MISMATCH) echo "Checksum verification failed" ;;
        $E_TIMEOUT)          echo "Operation timed out" ;;
        *)                   echo "Unknown error (code: $code)" ;;
    esac
}

# ============================================================================
# Unified Error Handler
# ============================================================================

# Handle an error with context and logging
# Usage: handle_error $exit_code "Description of what failed"
# Returns: The same exit code passed in
handle_error() {
    local exit_code="${1:-1}"
    local message="${2:-Unknown error occurred}"
    local context
    context=$(get_error_context)
    local full_context
    full_context=$(get_full_error_context)
    
    # Get error type description
    local error_type
    error_type=$(error_code_message "$exit_code")
    
    # Format error message
    local formatted_message="[$context] $message"
    
    # Log to stderr with color if available
    if [[ -n "${COLOR_ERROR:-}" ]]; then
        echo -e "${COLOR_ERROR}[ERROR]${NC:-} ${formatted_message}" >&2
    else
        echo "[ERROR] ${formatted_message}" >&2
    fi
    
    # Log to file if logging is enabled
    if [[ -n "${LABRAT_LOG_FILE:-}" ]] && [[ -w "$(dirname "${LABRAT_LOG_FILE}")" ]]; then
        local timestamp
        timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
        echo "${timestamp} ERROR [${full_context}] ${message} (${error_type}, code: ${exit_code})" >> "${LABRAT_LOG_FILE}"
    fi
    
    # Debug: show stack trace if debug mode is on
    if [[ "${LABRAT_DEBUG:-0}" == "1" ]]; then
        echo "  Stack trace:" >&2
        local i
        for ((i = ${#FUNCNAME[@]} - 1; i >= 0; i--)); do
            echo "    ${BASH_SOURCE[$i]:-unknown}:${BASH_LINENO[$i-1]:-0} ${FUNCNAME[$i]:-main}()" >&2
        done
    fi
    
    return "$exit_code"
}

# ============================================================================
# Safe Command Execution
# ============================================================================

# Execute a command safely with error handling
# Usage: safe_exec "Description" command arg1 arg2 ...
# Returns: Command exit code, with proper error handling on failure
safe_exec() {
    local description="$1"
    shift
    local cmd=("$@")
    
    # Log what we're doing in debug mode
    if [[ "${LABRAT_DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] Executing: ${cmd[*]}" >&2
    fi
    
    # Execute and capture output
    local output
    local exit_code
    
    output=$("${cmd[@]}" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        handle_error $exit_code "$description failed: $output"
        return $exit_code
    fi
    
    # Output the command output if verbose
    if [[ -n "$output" ]] && [[ "${LABRAT_VERBOSE:-0}" == "1" ]]; then
        echo "$output"
    fi
    
    return 0
}

# Execute a command with timeout
# Usage: safe_exec_timeout $seconds "Description" command arg1 arg2 ...
safe_exec_timeout() {
    local timeout_seconds="$1"
    local description="$2"
    shift 2
    local cmd=("$@")
    
    if command -v timeout &>/dev/null; then
        timeout "$timeout_seconds" "${cmd[@]}"
        local exit_code=$?
        
        if [[ $exit_code -eq 124 ]]; then
            handle_error $E_TIMEOUT "$description timed out after ${timeout_seconds}s"
            return $E_TIMEOUT
        elif [[ $exit_code -ne 0 ]]; then
            handle_error $exit_code "$description failed"
            return $exit_code
        fi
    else
        # No timeout command available, run directly
        "${cmd[@]}"
    fi
}

# ============================================================================
# Dependency Checking
# ============================================================================

# Check if a command exists
# Usage: command_exists curl
command_exists() {
    command -v "$1" &>/dev/null
}

# Require a command to exist, with helpful error message
# Usage: require_command curl "Required for downloading files"
# Usage: require_command jq  # Uses command name as package hint
require_command() {
    local cmd="$1"
    local hint="${2:-}"
    local package="${3:-$cmd}"
    
    if ! command_exists "$cmd"; then
        local message="Required command not found: $cmd"
        if [[ -n "$hint" ]]; then
            message="$message ($hint)"
        fi
        message="$message. Install with: ${package}"
        
        handle_error $E_MISSING_DEP "$message"
        return $E_MISSING_DEP
    fi
    return 0
}

# Require multiple commands
# Usage: require_commands curl git jq
require_commands() {
    local missing=()
    local cmd
    
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        handle_error $E_MISSING_DEP "Required commands not found: ${missing[*]}"
        return $E_MISSING_DEP
    fi
    return 0
}

# Check bash version meets minimum
# Usage: require_bash_version "4.0"
require_bash_version() {
    local required="${1:-$BASH_VERSION_MIN}"
    local current="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
    
    # Simple version comparison
    local req_major req_minor cur_major cur_minor
    req_major="${required%%.*}"
    req_minor="${required#*.}"
    req_minor="${req_minor%%.*}"
    cur_major="${BASH_VERSINFO[0]}"
    cur_minor="${BASH_VERSINFO[1]}"
    
    if (( cur_major < req_major )) || \
       (( cur_major == req_major && cur_minor < req_minor )); then
        handle_error $E_MISSING_DEP "Bash ${required}+ required, found ${current}"
        return $E_MISSING_DEP
    fi
    return 0
}

# ============================================================================
# Input Validation
# ============================================================================

# Validate that a variable is not empty
# Usage: require_var "VARIABLE_NAME" "$variable_value" "Description"
require_var() {
    local var_name="$1"
    local var_value="$2"
    local description="${3:-$var_name}"
    
    if [[ -z "$var_value" ]]; then
        handle_error $E_INVALID_INPUT "Required value missing: $description"
        return $E_INVALID_INPUT
    fi
    return 0
}

# Validate that a path exists
# Usage: require_path "/path/to/file" "Description"
require_path() {
    local path="$1"
    local description="${2:-$path}"
    
    if [[ ! -e "$path" ]]; then
        handle_error $E_FILE_NOT_FOUND "Path not found: $description ($path)"
        return $E_FILE_NOT_FOUND
    fi
    return 0
}

# Validate that a file exists and is readable
# Usage: require_file "/path/to/file" "Description"
require_file() {
    local file="$1"
    local description="${2:-$file}"
    
    if [[ ! -f "$file" ]]; then
        handle_error $E_FILE_NOT_FOUND "File not found: $description ($file)"
        return $E_FILE_NOT_FOUND
    fi
    
    if [[ ! -r "$file" ]]; then
        handle_error $E_PERMISSION "File not readable: $description ($file)"
        return $E_PERMISSION
    fi
    return 0
}

# Validate that a directory exists and is accessible
# Usage: require_dir "/path/to/dir" "Description"
require_dir() {
    local dir="$1"
    local description="${2:-$dir}"
    
    if [[ ! -d "$dir" ]]; then
        handle_error $E_FILE_NOT_FOUND "Directory not found: $description ($dir)"
        return $E_FILE_NOT_FOUND
    fi
    
    if [[ ! -r "$dir" ]] || [[ ! -x "$dir" ]]; then
        handle_error $E_PERMISSION "Directory not accessible: $description ($dir)"
        return $E_PERMISSION
    fi
    return 0
}

# ============================================================================
# Error Recovery Helpers
# ============================================================================

# Try a command, with fallback on failure
# Usage: try_or_fallback "primary_cmd arg1" "fallback_cmd arg1" "Description"
try_or_fallback() {
    local primary="$1"
    local fallback="$2"
    local description="${3:-Operation}"
    
    if eval "$primary" 2>/dev/null; then
        return 0
    fi
    
    if [[ "${LABRAT_VERBOSE:-0}" == "1" ]]; then
        echo "[INFO] $description: primary failed, trying fallback" >&2
    fi
    
    if eval "$fallback" 2>/dev/null; then
        return 0
    fi
    
    handle_error $E_GENERAL "$description: both primary and fallback failed"
    return $E_GENERAL
}

# Retry a command up to N times
# Usage: retry 3 1 "Description" command arg1 arg2 ...
# Args: max_attempts delay_seconds description command...
retry() {
    local max_attempts="$1"
    local delay="$2"
    local description="$3"
    shift 3
    local cmd=("$@")
    
    local attempt=1
    while (( attempt <= max_attempts )); do
        if "${cmd[@]}" 2>/dev/null; then
            return 0
        fi
        
        if (( attempt < max_attempts )); then
            if [[ "${LABRAT_VERBOSE:-0}" == "1" ]]; then
                echo "[INFO] $description: attempt $attempt failed, retrying in ${delay}s..." >&2
            fi
            sleep "$delay"
        fi
        ((attempt++))
    done
    
    handle_error $E_GENERAL "$description: failed after $max_attempts attempts"
    return $E_GENERAL
}

# ============================================================================
# Cleanup Registration
# ============================================================================

# Registered cleanup functions
declare -a _LABRAT_CLEANUP_FUNCTIONS=()

# Register a cleanup function to run on exit/error
# Usage: register_cleanup "cleanup_function_name"
register_cleanup() {
    local func="$1"
    _LABRAT_CLEANUP_FUNCTIONS+=("$func")
}

# Run all registered cleanup functions
run_cleanups() {
    local func
    for func in "${_LABRAT_CLEANUP_FUNCTIONS[@]}"; do
        if declare -f "$func" &>/dev/null; then
            "$func" 2>/dev/null || true
        fi
    done
}

# Setup exit trap for cleanup
_setup_cleanup_trap() {
    trap 'run_cleanups' EXIT
}

# ============================================================================
# Debug Helpers
# ============================================================================

# Print debug message if debug mode is enabled
debug() {
    if [[ "${LABRAT_DEBUG:-0}" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Print verbose message if verbose mode is enabled
verbose() {
    if [[ "${LABRAT_VERBOSE:-0}" == "1" ]] || [[ "${LABRAT_DEBUG:-0}" == "1" ]]; then
        echo "[INFO] $*" >&2
    fi
}

# Assert a condition (for testing/development)
# Usage: assert "[[ -f /tmp/test ]]" "File should exist"
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        handle_error $E_GENERAL "ASSERTION FAILED: $message (condition: $condition)"
        return 1
    fi
    return 0
}
