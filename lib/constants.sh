#!/usr/bin/env bash
#
# LabRat - Centralized Constants
# Single source of truth for paths, defaults, and configuration values
#
# This file should be sourced by all other library files to ensure consistency.
#

# Source guard - prevent multiple sourcing
[[ -n "${_LABRAT_CONSTANTS_LOADED:-}" ]] && return 0
_LABRAT_CONSTANTS_LOADED=1

# ============================================================================
# Version Information
# ============================================================================

readonly LABRAT_VERSION="1.0.0"
readonly LABRAT_MANIFEST_VERSION="1.0"

# ============================================================================
# Minimum Version Requirements
# ============================================================================

readonly BASH_VERSION_MIN="4.0"
readonly LABRAT_MIN_BASH_VERSION="4.0"  # Alias for test compatibility
readonly TMUX_VERSION_MIN="3.3"
readonly TMUX_VERSION_LATEST="3.5a"

# ============================================================================
# Default Path Configuration
# ============================================================================

# These can be overridden by environment variables before sourcing
readonly LABRAT_DEFAULT_PREFIX="${HOME}/.local"
readonly LABRAT_DEFAULT_BIN_DIR="${LABRAT_DEFAULT_PREFIX}/bin"
readonly LABRAT_DEFAULT_LIB_DIR="${LABRAT_DEFAULT_PREFIX}/lib"
readonly LABRAT_DEFAULT_CONFIG_DIR="${HOME}/.config"
readonly LABRAT_DEFAULT_DATA_DIR="${HOME}/.local/share/labrat"
readonly LABRAT_DEFAULT_CACHE_DIR="${HOME}/.cache/labrat"

# ============================================================================
# File Names
# ============================================================================

readonly LABRAT_MANIFEST_FILENAME="manifest.json"
readonly LABRAT_INSTALLED_DIR_NAME="installed"
readonly LABRAT_BACKUPS_DIR_NAME="backups"
readonly LABRAT_LOGS_DIR_NAME="logs"

# ============================================================================
# Lock Files
# ============================================================================

readonly LABRAT_MANIFEST_LOCK_FILENAME=".manifest.lock"

# ============================================================================
# Theme Preference Files
# ============================================================================

readonly LABRAT_TMUX_THEME_FILENAME=".tmux-theme"
readonly LABRAT_STARSHIP_PRESET_FILENAME="current-starship-preset"
readonly LABRAT_FZF_THEME_FILENAME="fzf_theme"
readonly LABRAT_GLOBAL_THEME_FILENAME="current-theme"

# ============================================================================
# Default Theme Values
# ============================================================================

readonly DEFAULT_TMUX_THEME="catppuccin-mocha"
readonly DEFAULT_STARSHIP_PRESET="labrat"
readonly DEFAULT_FZF_THEME="catppuccin-mocha"
readonly DEFAULT_BAT_THEME="Catppuccin Mocha"  # With space to match .tmTheme filename
readonly DEFAULT_BTOP_THEME="catppuccin_mocha"
readonly DEFAULT_ATUIN_THEME="catppuccin-mocha"

# ============================================================================
# Shell Integration
# ============================================================================

readonly LABRAT_SHELL_CONFIG_DIR_NAME="labrat"
readonly LABRAT_SHELL_MODULES_DIR_NAME="modules"
readonly LABRAT_SHELL_BACKUP_DIR_NAME="shell_backups"

# Shell config filenames
readonly LABRAT_BASH_RC_FILENAME="bashrc.sh"
readonly LABRAT_ZSH_RC_FILENAME="zshrc.sh"
readonly LABRAT_FISH_RC_FILENAME="config.fish"
readonly LABRAT_LEGACY_SHELL_RC_FILENAME="shellrc.sh"

# ============================================================================
# SSH Configuration
# ============================================================================

readonly LABRAT_SSH_DIR_NAME="labrat"
readonly LABRAT_SSH_CONFIG_D_NAME="config.d"

# ============================================================================
# Error Codes
# ============================================================================

readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_MISSING_DEP=2
readonly E_NETWORK=3
readonly E_PERMISSION=4
readonly E_FILE_NOT_FOUND=5
readonly E_INVALID_INPUT=6
readonly E_MODULE_FAILED=7
readonly E_LOCK_FAILED=8
readonly E_CHECKSUM_MISMATCH=9
readonly E_TIMEOUT=10

# ============================================================================
# Module Categories
# ============================================================================

readonly MODULE_CATEGORIES="terminal shell editors fonts utils monitoring network productivity security"

# ============================================================================
# Module Dependency Definitions
# ============================================================================

# Format: "module:dep1,dep2,dep3"
# Dependencies that must be installed before the module
declare -grA MODULE_DEPENDENCIES=(
    ["starship"]=""
    ["tmux"]=""
    ["fzf"]=""
    ["zsh"]=""
    ["neovim"]=""
    ["lazygit"]=""
    ["btop"]=""
    ["atuin"]=""
    ["zoxide"]=""
)

# Recommended but not required dependencies
declare -grA MODULE_RECOMMENDS=(
    ["starship"]="nerdfonts"
    ["fzf"]="fd,bat,ripgrep"
    ["tmux"]="nerdfonts"
    ["neovim"]="nerdfonts,ripgrep,fd"
    ["lazygit"]=""
    ["zsh"]="starship"
    ["eza"]="nerdfonts"
)

# ============================================================================
# Network Configuration
# ============================================================================

readonly GITHUB_API_URL="https://api.github.com"
readonly LABRAT_DEFAULT_REPO="https://github.com/amd-marmoody/Labrat.git"
readonly LABRAT_DEFAULT_BRANCH="main"

# Download timeout in seconds
readonly DOWNLOAD_TIMEOUT=60
readonly LOCK_TIMEOUT=10

# ============================================================================
# File Permissions
# ============================================================================

# Permission constants (octal)
readonly PERM_PRIVATE_FILE=600       # Owner read/write only
readonly PERM_PRIVATE_DIR=700        # Owner read/write/execute only
readonly PERM_SCRIPT=755             # Owner all, others read/execute
readonly PERM_CONFIG_FILE=644        # Owner read/write, others read
readonly PERM_CONFIG_DIR=755         # Owner all, others read/execute

# SSH-specific permissions
readonly PERM_SSH_DIR=700
readonly PERM_SSH_PRIVATE_KEY=600
readonly PERM_SSH_PUBLIC_KEY=644
readonly PERM_SSH_CONFIG=600

# Aliases for test compatibility
readonly SHELL_CONFIG_PERM=644
readonly SHELL_SCRIPT_PERM=755

# ============================================================================
# Logging Configuration
# ============================================================================

readonly LOG_RETENTION_DAYS=7
readonly LOG_MAX_SIZE_MB=10

# ============================================================================
# Helper Functions
# ============================================================================

# Get a full path with user expansion
# Usage: expand_path "~/.config/labrat"
expand_path() {
    local path="$1"
    # Expand tilde
    path="${path/#\~/$HOME}"
    echo "$path"
}

# Get the effective value of a variable with fallback to default
# Usage: get_config_value "LABRAT_PREFIX" "$LABRAT_DEFAULT_PREFIX"
get_config_value() {
    local var_name="$1"
    local default_value="$2"
    local current_value="${!var_name:-}"
    
    echo "${current_value:-$default_value}"
}

# ============================================================================
# Derived Paths (computed from configuration)
# These functions compute paths based on current configuration
# ============================================================================

# Get the manifest file path
get_manifest_path() {
    local data_dir="${LABRAT_DATA_DIR:-$LABRAT_DEFAULT_DATA_DIR}"
    echo "${data_dir}/${LABRAT_MANIFEST_FILENAME}"
}

# Get the installed modules directory
get_installed_dir() {
    local data_dir="${LABRAT_DATA_DIR:-$LABRAT_DEFAULT_DATA_DIR}"
    echo "${data_dir}/${LABRAT_INSTALLED_DIR_NAME}"
}

# Get the backups directory
get_backups_dir() {
    local data_dir="${LABRAT_DATA_DIR:-$LABRAT_DEFAULT_DATA_DIR}"
    echo "${data_dir}/${LABRAT_BACKUPS_DIR_NAME}"
}

# Get the logs directory
get_logs_dir() {
    local cache_dir="${LABRAT_CACHE_DIR:-$LABRAT_DEFAULT_CACHE_DIR}"
    echo "${cache_dir}/${LABRAT_LOGS_DIR_NAME}"
}

# Get the shell config directory
get_shell_config_dir() {
    local config_dir="${LABRAT_CONFIG_DIR:-$LABRAT_DEFAULT_CONFIG_DIR}"
    echo "${config_dir}/${LABRAT_SHELL_CONFIG_DIR_NAME}"
}

# Get tmux theme file path
get_tmux_theme_path() {
    echo "${HOME}/${LABRAT_TMUX_THEME_FILENAME}"
}

# Get starship preset file path
get_starship_preset_path() {
    local data_dir="${LABRAT_DATA_DIR:-$LABRAT_DEFAULT_DATA_DIR}"
    echo "${data_dir}/${LABRAT_STARSHIP_PRESET_FILENAME}"
}

# Get SSH labrat directory
get_ssh_labrat_dir() {
    echo "${HOME}/.ssh/${LABRAT_SSH_DIR_NAME}"
}

# Get SSH config.d directory
get_ssh_config_d_dir() {
    echo "${HOME}/.ssh/${LABRAT_SSH_CONFIG_D_NAME}"
}
