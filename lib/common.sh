#!/usr/bin/env bash
#
# LabRat - Common utilities and shared functions
#

# Ensure colors are loaded
LABRAT_LIB_DIR="${LABRAT_LIB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=./colors.sh
source "${LABRAT_LIB_DIR}/colors.sh"

# ============================================================================
# Global Configuration
# ============================================================================

# Installation prefix (where binaries go)
LABRAT_PREFIX="${LABRAT_PREFIX:-$HOME/.local}"
LABRAT_BIN_DIR="${LABRAT_BIN_DIR:-$LABRAT_PREFIX/bin}"
LABRAT_CONFIG_DIR="${LABRAT_CONFIG_DIR:-$HOME/.config}"
LABRAT_DATA_DIR="${LABRAT_DATA_DIR:-$HOME/.local/share/labrat}"
LABRAT_CACHE_DIR="${LABRAT_CACHE_DIR:-$HOME/.cache/labrat}"

# Logging verbosity
LABRAT_VERBOSE="${LABRAT_VERBOSE:-0}"
LABRAT_DEBUG="${LABRAT_DEBUG:-0}"

# Dry run mode
LABRAT_DRY_RUN="${LABRAT_DRY_RUN:-0}"

# ============================================================================
# Logging Functions
# ============================================================================

log_info() {
    echo -e "${COLOR_INFO}[${SYMBOL_INFO}]${NC} $1"
}

log_success() {
    echo -e "${COLOR_SUCCESS}[${SYMBOL_CHECK}]${NC} $1"
}

log_warn() {
    echo -e "${COLOR_WARN}[${SYMBOL_WARNING}]${NC} $1"
}

log_error() {
    echo -e "${COLOR_ERROR}[${SYMBOL_CROSS}]${NC} $1" >&2
}

log_debug() {
    if [[ "$LABRAT_DEBUG" == "1" ]]; then
        echo -e "${COLOR_DEBUG}[DEBUG]${NC} $1"
    fi
}

log_verbose() {
    if [[ "$LABRAT_VERBOSE" == "1" ]] || [[ "$LABRAT_DEBUG" == "1" ]]; then
        echo -e "${DIM}$1${NC}"
    fi
}

log_step() {
    echo -e "${COLOR_ACCENT}${SYMBOL_ARROW}${NC} $1"
}

log_header() {
    local text="$1"
    local width=65
    local padding=$(( (width - ${#text} - 2) / 2 ))
    
    echo ""
    echo -e "${COLOR_HEADER}${BOLD}${BOX_TOP_LEFT}$(printf '%*s' "$width" | tr ' ' "$BOX_HORIZONTAL")${BOX_TOP_RIGHT}${NC}"
    echo -e "${COLOR_HEADER}${BOLD}${BOX_VERTICAL}$(printf '%*s' "$padding" '')${text}$(printf '%*s' "$((width - padding - ${#text}))" '')${BOX_VERTICAL}${NC}"
    echo -e "${COLOR_HEADER}${BOLD}${BOX_BOTTOM_LEFT}$(printf '%*s' "$width" | tr ' ' "$BOX_HORIZONTAL")${BOX_BOTTOM_RIGHT}${NC}"
    echo ""
}

log_subheader() {
    echo ""
    echo -e "${BOLD}${UNDERLINE}$1${NC}"
    echo ""
}

# ============================================================================
# Utility Functions
# ============================================================================

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_root() {
    [[ "$EUID" -eq 0 ]]
}

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_debug "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# Check if running in a container
is_container() {
    [[ -f /.dockerenv ]] || grep -q 'docker\|lxc\|containerd' /proc/1/cgroup 2>/dev/null
}

# Check if we have sudo access
has_sudo() {
    if is_root; then
        return 0
    fi
    sudo -n true 2>/dev/null
}

# Run command with sudo if needed
run_privileged() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    export OS=""
    export OS_VERSION=""
    export OS_FAMILY=""
    export OS_CODENAME=""
    export ARCH=""
    
    # Detect architecture
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)  ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        armv7l)  ARCH="armv7" ;;
    esac
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
        OS_CODENAME="${VERSION_CODENAME:-}"
        
        case "$OS" in
            ubuntu|debian|linuxmint|pop|elementary|zorin)
                OS_FAMILY="debian"
                ;;
            centos|rhel|fedora|rocky|almalinux|ol|scientific)
                OS_FAMILY="rhel"
                ;;
            alpine)
                OS_FAMILY="alpine"
                ;;
            arch|manjaro|endeavouros|garuda)
                OS_FAMILY="arch"
                ;;
            opensuse*|sles)
                OS_FAMILY="suse"
                ;;
            *)
                OS_FAMILY="unknown"
                ;;
        esac
    else
        log_error "Cannot detect OS: /etc/os-release not found"
        return 1
    fi
    
    log_debug "Detected OS: $OS $OS_VERSION (family: $OS_FAMILY, arch: $ARCH)"
}

# ============================================================================
# Version Comparison
# ============================================================================

# Compare version strings
# Returns: 0 if equal, 1 if $1 > $2, 2 if $1 < $2
version_compare() {
    if [[ "$1" == "$2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    # Fill empty positions with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]:-} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Check if version meets minimum requirement
version_gte() {
    local current="$1"
    local required="$2"
    version_compare "$current" "$required"
    [[ $? -ne 2 ]]
}

# ============================================================================
# Path Management
# ============================================================================

# Add directory to PATH if not already present
add_to_path() {
    local dir="$1"
    local position="${2:-prepend}"  # prepend or append
    
    if [[ ":$PATH:" != *":$dir:"* ]]; then
        if [[ "$position" == "prepend" ]]; then
            export PATH="$dir:$PATH"
        else
            export PATH="$PATH:$dir"
        fi
        log_debug "Added to PATH: $dir"
    fi
}

# Ensure PATH modifications are persistent
persist_path() {
    local dir="$1"
    local shell_rc=""
    
    # Determine shell config file
    case "$SHELL" in
        */zsh)  shell_rc="$HOME/.zshrc" ;;
        */bash) shell_rc="$HOME/.bashrc" ;;
        */fish) shell_rc="$HOME/.config/fish/config.fish" ;;
        *)      shell_rc="$HOME/.profile" ;;
    esac
    
    local path_line="export PATH=\"$dir:\$PATH\""
    
    if [[ -f "$shell_rc" ]] && grep -qF "$dir" "$shell_rc"; then
        log_debug "PATH already configured in $shell_rc"
        return 0
    fi
    
    log_info "Adding $dir to PATH in $shell_rc"
    {
        echo ""
        echo "# Added by LabRat"
        echo "$path_line"
    } >> "$shell_rc"
}

# ============================================================================
# File Operations
# ============================================================================

# Backup a file before modifying
backup_file() {
    local file="$1"
    local backup_dir="${LABRAT_DATA_DIR}/backups"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    ensure_dir "$backup_dir"
    
    local filename=$(basename "$file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${backup_dir}/${filename}.${timestamp}.bak"
    
    cp "$file" "$backup_path"
    log_debug "Backed up $file to $backup_path"
    echo "$backup_path"
}

# Create a symlink with backup
safe_symlink() {
    local source="$1"
    local target="$2"
    
    if [[ -L "$target" ]]; then
        rm "$target"
    elif [[ -f "$target" ]]; then
        backup_file "$target"
        rm "$target"
    fi
    
    ensure_dir "$(dirname "$target")"
    ln -s "$source" "$target"
    log_debug "Created symlink: $target -> $source"
}

# ============================================================================
# Download Utilities
# ============================================================================

# Download a file with progress
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-Downloading}"
    
    log_step "$description"
    log_debug "URL: $url"
    log_debug "Output: $output"
    
    ensure_dir "$(dirname "$output")"
    
    if command_exists curl; then
        if [[ "$LABRAT_VERBOSE" == "1" ]]; then
            curl -fSL "$url" -o "$output"
        else
            curl -fsSL "$url" -o "$output"
        fi
    elif command_exists wget; then
        if [[ "$LABRAT_VERBOSE" == "1" ]]; then
            wget "$url" -O "$output"
        else
            wget -q "$url" -O "$output"
        fi
    else
        log_error "Neither curl nor wget available"
        return 1
    fi
}

# Download and extract archive
download_and_extract() {
    local url="$1"
    local extract_dir="$2"
    local description="${3:-Downloading and extracting}"
    
    local temp_file=$(mktemp)
    local archive_type=""
    
    # Detect archive type from URL
    case "$url" in
        *.tar.gz|*.tgz)   archive_type="tar.gz" ;;
        *.tar.xz)         archive_type="tar.xz" ;;
        *.tar.bz2)        archive_type="tar.bz2" ;;
        *.zip)            archive_type="zip" ;;
        *)                archive_type="tar.gz" ;;  # Default assumption
    esac
    
    download_file "$url" "$temp_file" "$description"
    
    ensure_dir "$extract_dir"
    
    case "$archive_type" in
        tar.gz)
            tar -xzf "$temp_file" -C "$extract_dir"
            ;;
        tar.xz)
            tar -xJf "$temp_file" -C "$extract_dir"
            ;;
        tar.bz2)
            tar -xjf "$temp_file" -C "$extract_dir"
            ;;
        zip)
            unzip -q "$temp_file" -d "$extract_dir"
            ;;
    esac
    
    rm -f "$temp_file"
    log_success "Extracted to $extract_dir"
}

# ============================================================================
# GitHub API Utilities
# ============================================================================

# Get latest release version from GitHub
# Usage: get_github_latest_release "owner/repo"
# Returns: version string (e.g., "v1.2.3" or "1.2.3")
get_github_latest_release() {
    local repo="$1"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    local version=""
    
    if command_exists curl; then
        version=$(curl -fsSL "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo "")
    elif command_exists wget; then
        version=$(wget -qO- "$api_url" 2>/dev/null | grep -Po '"tag_name": *"\K[^"]+' || echo "")
    fi
    
    if [[ -z "$version" ]]; then
        log_debug "Failed to get latest release for $repo"
        return 1
    fi
    
    echo "$version"
}

# Get download URL for a specific asset from GitHub release
# Usage: get_github_release_asset "owner/repo" "version" "asset_pattern"
get_github_release_asset() {
    local repo="$1"
    local version="$2"
    local pattern="$3"
    
    local api_url="https://api.github.com/repos/${repo}/releases/tags/${version}"
    local assets_json=""
    
    if command_exists curl; then
        assets_json=$(curl -fsSL "$api_url" 2>/dev/null)
    elif command_exists wget; then
        assets_json=$(wget -qO- "$api_url" 2>/dev/null)
    fi
    
    # Extract browser_download_url matching pattern
    echo "$assets_json" | grep -oP '"browser_download_url":\s*"\K[^"]*'"$pattern"'[^"]*' | head -1
}

# Download GitHub release asset
# Usage: download_github_release "owner/repo" "asset_pattern" "output_file" [version]
download_github_release() {
    local repo="$1"
    local pattern="$2"
    local output="$3"
    local version="${4:-}"
    
    # Get latest version if not specified
    if [[ -z "$version" ]]; then
        version=$(get_github_latest_release "$repo")
        if [[ -z "$version" ]]; then
            log_error "Failed to get latest release for $repo"
            return 1
        fi
    fi
    
    log_debug "Downloading $repo version $version"
    
    # Construct download URL
    # Try direct release download URL first
    local download_url="https://github.com/${repo}/releases/download/${version}/${pattern}"
    
    # If pattern contains wildcards, use API to find exact URL
    if [[ "$pattern" == *"*"* ]] || [[ "$pattern" == *"{"* ]]; then
        download_url=$(get_github_release_asset "$repo" "$version" "$pattern")
    fi
    
    if [[ -z "$download_url" ]]; then
        log_error "Failed to find download URL for $pattern"
        return 1
    fi
    
    download_file "$download_url" "$output" "Downloading $(basename "$output")"
}

# ============================================================================
# Git Utilities
# ============================================================================

# Clone or update a git repository
git_clone_or_update() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-main}"
    
    if [[ -d "$target_dir/.git" ]]; then
        log_step "Updating repository: $(basename "$target_dir")"
        (
            cd "$target_dir"
            git fetch origin "$branch" --quiet
            git reset --hard "origin/$branch" --quiet
        )
    else
        log_step "Cloning repository: $(basename "$target_dir")"
        ensure_dir "$(dirname "$target_dir")"
        git clone --branch "$branch" --depth 1 "$repo_url" "$target_dir" --quiet
    fi
}

# ============================================================================
# User Interaction
# ============================================================================

# Prompt for yes/no confirmation
# Respects SKIP_CONFIRMATION and non-interactive mode
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    # Skip confirmation in non-interactive mode or when -y flag is used
    if [[ "${SKIP_CONFIRMATION:-false}" == "true" ]] || [[ ! -t 0 ]]; then
        log_debug "Auto-confirming with default: $default"
        if [[ "$default" == "y" ]]; then
            return 0
        else
            return 1
        fi
    fi
    
    local yn_prompt
    if [[ "$default" == "y" ]]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi
    
    while true; do
        read -rp "$(echo -e "${COLOR_ACCENT}?${NC} ${prompt} ${yn_prompt} ")" response
        response=${response:-$default}
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo])     return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Prompt for input with default value
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local result
    
    if [[ -n "$default" ]]; then
        read -rp "$(echo -e "${COLOR_ACCENT}?${NC} ${prompt} [${default}]: ")" result
        result=${result:-$default}
    else
        read -rp "$(echo -e "${COLOR_ACCENT}?${NC} ${prompt}: ")" result
    fi
    
    echo "$result"
}

# Select from a list of options
select_option() {
    local prompt="$1"
    shift
    local options=("$@")
    
    echo -e "${COLOR_ACCENT}?${NC} ${prompt}"
    
    local i=1
    for opt in "${options[@]}"; do
        echo -e "  ${BOLD}$i)${NC} $opt"
        ((i++))
    done
    
    local selection
    while true; do
        read -rp "$(echo -e "${COLOR_ACCENT}>${NC} Enter selection [1-${#options[@]}]: ")" selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#options[@]})); then
            echo "${options[$((selection-1))]}"
            return 0
        fi
        
        log_warn "Invalid selection. Please enter a number between 1 and ${#options[@]}"
    done
}

# ============================================================================
# Module Management
# ============================================================================

# Check if a module is installed
is_module_installed() {
    local module="$1"
    local marker_file="${LABRAT_DATA_DIR}/installed/${module}"
    [[ -f "$marker_file" ]]
}

# Mark a module as installed
mark_module_installed() {
    local module="$1"
    local version="${2:-unknown}"
    local marker_dir="${LABRAT_DATA_DIR}/installed"
    
    ensure_dir "$marker_dir"
    echo "$version" > "${marker_dir}/${module}"
    log_debug "Marked $module as installed (version: $version)"
}

# Get installed version of a module
get_installed_version() {
    local module="$1"
    local marker_file="${LABRAT_DATA_DIR}/installed/${module}"
    
    if [[ -f "$marker_file" ]]; then
        cat "$marker_file"
    else
        echo ""
    fi
}

# ============================================================================
# Initialization
# ============================================================================

# Initialize LabRat directories
init_labrat_dirs() {
    ensure_dir "$LABRAT_PREFIX"
    ensure_dir "$LABRAT_BIN_DIR"
    ensure_dir "$LABRAT_CONFIG_DIR"
    ensure_dir "$LABRAT_DATA_DIR"
    ensure_dir "$LABRAT_CACHE_DIR"
    
    # Ensure bin directory is in PATH
    add_to_path "$LABRAT_BIN_DIR"
}

# Run initialization if this script is sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Being sourced
    detect_os
    init_labrat_dirs
fi
