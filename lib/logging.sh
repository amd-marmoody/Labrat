#!/usr/bin/env bash
#
# LabRat - Logging Infrastructure
# Provides persistent logging for troubleshooting and audit trails
#

# ============================================================================
# Configuration
# ============================================================================

LABRAT_LOG_DIR="${LABRAT_LOG_DIR:-${LABRAT_CACHE_DIR:-$HOME/.cache/labrat}/logs}"
LABRAT_LOG_LEVEL="${LABRAT_LOG_LEVEL:-INFO}"
LABRAT_LOG_TO_FILE="${LABRAT_LOG_TO_FILE:-1}"
LABRAT_LOG_MAX_SIZE="${LABRAT_LOG_MAX_SIZE:-10485760}"  # 10MB
LABRAT_LOG_RETENTION_DAYS="${LABRAT_LOG_RETENTION_DAYS:-30}"

# Log level priorities
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# Current log file
_LABRAT_LOG_FILE=""

# ============================================================================
# Log Initialization
# ============================================================================

# Initialize logging system
init_logging() {
    [[ "$LABRAT_LOG_TO_FILE" != "1" ]] && return 0
    
    mkdir -p "$LABRAT_LOG_DIR" 2>/dev/null || {
        echo "Warning: Cannot create log directory: $LABRAT_LOG_DIR" >&2
        LABRAT_LOG_TO_FILE=0
        return 1
    }
    
    # Set permissions on log directory
    chmod 700 "$LABRAT_LOG_DIR" 2>/dev/null || true
    
    # Create today's log file
    local today=$(date +%Y-%m-%d)
    _LABRAT_LOG_FILE="${LABRAT_LOG_DIR}/labrat_${today}.log"
    
    # Rotate if needed
    _rotate_log_if_needed
    
    # Clean old logs
    _cleanup_old_logs &
    
    return 0
}

# ============================================================================
# Log Rotation
# ============================================================================

# Rotate log file if it exceeds max size
_rotate_log_if_needed() {
    [[ ! -f "$_LABRAT_LOG_FILE" ]] && return 0
    
    local size=$(stat -f%z "$_LABRAT_LOG_FILE" 2>/dev/null || stat -c%s "$_LABRAT_LOG_FILE" 2>/dev/null || echo 0)
    
    if [[ "$size" -gt "$LABRAT_LOG_MAX_SIZE" ]]; then
        local timestamp=$(date +%H%M%S)
        mv "$_LABRAT_LOG_FILE" "${_LABRAT_LOG_FILE%.log}_${timestamp}.log"
        _LABRAT_LOG_FILE="${LABRAT_LOG_DIR}/labrat_$(date +%Y-%m-%d).log"
    fi
}

# Remove logs older than retention period
_cleanup_old_logs() {
    find "$LABRAT_LOG_DIR" -name "labrat_*.log" -type f -mtime +${LABRAT_LOG_RETENTION_DAYS} -delete 2>/dev/null || true
}

# ============================================================================
# Core Logging Functions
# ============================================================================

# Internal log writer
# Usage: _write_log LEVEL message
_write_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check log level
    local current_priority="${LOG_LEVELS[$LABRAT_LOG_LEVEL]:-1}"
    local msg_priority="${LOG_LEVELS[$level]:-1}"
    
    [[ "$msg_priority" -lt "$current_priority" ]] && return 0
    
    # Format log entry
    local log_entry="[$timestamp] [$level] $message"
    
    # Write to file if enabled
    if [[ "$LABRAT_LOG_TO_FILE" == "1" && -n "$_LABRAT_LOG_FILE" ]]; then
        echo "$log_entry" >> "$_LABRAT_LOG_FILE" 2>/dev/null
    fi
    
    return 0
}

# Public logging functions
log_to_file() {
    local level="${1:-INFO}"
    shift
    _write_log "$level" "$@"
}

log_debug_file() { _write_log "DEBUG" "$@"; }
log_info_file() { _write_log "INFO" "$@"; }
log_warn_file() { _write_log "WARN" "$@"; }
log_error_file() { _write_log "ERROR" "$@"; }
log_fatal_file() { _write_log "FATAL" "$@"; }

# ============================================================================
# Installation Logging
# ============================================================================

# Log module installation start
log_install_start() {
    local module="$1"
    _write_log "INFO" "=== Starting installation: $module ==="
}

# Log module installation end
log_install_end() {
    local module="$1"
    local status="$2"  # success or failure
    local duration="${3:-unknown}"
    _write_log "INFO" "=== Completed installation: $module (status: $status, duration: ${duration}s) ==="
}

# Log installation step
log_install_step() {
    local module="$1"
    local step="$2"
    _write_log "INFO" "[$module] $step"
}

# ============================================================================
# Error Logging
# ============================================================================

# Log error with context
log_error_context() {
    local context="$1"
    local error="$2"
    local details="${3:-}"
    
    _write_log "ERROR" "Context: $context"
    _write_log "ERROR" "Error: $error"
    [[ -n "$details" ]] && _write_log "ERROR" "Details: $details"
}

# Log command execution failure
log_command_failure() {
    local command="$1"
    local exit_code="$2"
    local output="${3:-}"
    
    _write_log "ERROR" "Command failed: $command (exit code: $exit_code)"
    [[ -n "$output" ]] && _write_log "ERROR" "Output: $output"
}

# ============================================================================
# Log Viewing
# ============================================================================

# Show recent log entries
show_recent_logs() {
    local lines="${1:-50}"
    local level="${2:-}"
    
    if [[ ! -f "$_LABRAT_LOG_FILE" ]]; then
        echo "No log file found"
        return 1
    fi
    
    if [[ -n "$level" ]]; then
        grep "\\[$level\\]" "$_LABRAT_LOG_FILE" | tail -n "$lines"
    else
        tail -n "$lines" "$_LABRAT_LOG_FILE"
    fi
}

# Show logs for today
show_today_logs() {
    local level="${1:-}"
    local today=$(date +%Y-%m-%d)
    local log_file="${LABRAT_LOG_DIR}/labrat_${today}.log"
    
    if [[ ! -f "$log_file" ]]; then
        echo "No logs for today"
        return 1
    fi
    
    if [[ -n "$level" ]]; then
        grep "\\[$level\\]" "$log_file"
    else
        cat "$log_file"
    fi
}

# Get log file path
get_log_path() {
    echo "$_LABRAT_LOG_FILE"
}

# List all log files
list_log_files() {
    if [[ -d "$LABRAT_LOG_DIR" ]]; then
        ls -la "$LABRAT_LOG_DIR"/labrat_*.log 2>/dev/null || echo "No log files found"
    else
        echo "Log directory does not exist"
    fi
}

# ============================================================================
# Integration with Console Logging
# ============================================================================

# Enhanced log functions that write to both console and file
# These wrap the existing common.sh functions

if declare -f log_info &>/dev/null; then
    _original_log_info=$(declare -f log_info)
    log_info() {
        # Call original
        echo -e "${COLOR_INFO:-}[${SYMBOL_INFO:-ℹ}]${NC:-} $1"
        # Also write to file
        _write_log "INFO" "$1"
    }
fi

if declare -f log_error &>/dev/null; then
    _original_log_error=$(declare -f log_error)
    log_error() {
        # Call original
        echo -e "${COLOR_ERROR:-}[${SYMBOL_CROSS:-✗}]${NC:-} $1" >&2
        # Also write to file
        _write_log "ERROR" "$1"
    }
fi

if declare -f log_warn &>/dev/null; then
    _original_log_warn=$(declare -f log_warn)
    log_warn() {
        # Call original
        echo -e "${COLOR_WARN:-}[${SYMBOL_WARNING:-⚠}]${NC:-} $1"
        # Also write to file
        _write_log "WARN" "$1"
    }
fi

# ============================================================================
# Auto-initialize
# ============================================================================

# Initialize logging when sourced
init_logging
