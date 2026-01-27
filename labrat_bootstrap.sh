#!/usr/bin/env bash
#
# LabRat Bootstrap Script
# Your trusty environment for every test cage 🐀
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/labrat/main/labrat_bootstrap.sh | bash
#   curl -fsSL ... | bash -s -- --modules tmux,fzf --prefix ~/.local
#
# This script:
#   1. Detects OS and ensures minimum requirements
#   2. Clones or downloads the LabRat repository
#   3. Hands off to the main installer
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

LABRAT_REPO="${LABRAT_REPO:-https://github.com/YOUR_USER/labrat.git}"
LABRAT_BRANCH="${LABRAT_BRANCH:-main}"
LABRAT_DIR="${LABRAT_DIR:-$HOME/.labrat}"

# Colors (basic - full colors loaded after clone)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[LabRat]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[LabRat]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[LabRat]${NC} $1"
}

log_error() {
    echo -e "${RED}[LabRat]${NC} $1" >&2
}

log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# OS Detection
# ============================================================================

detect_os() {
    OS=""
    OS_VERSION=""
    OS_FAMILY=""
    
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        OS="${ID:-unknown}"
        OS_VERSION="${VERSION_ID:-unknown}"
        
        case "$OS" in
            ubuntu|debian|linuxmint|pop)
                OS_FAMILY="debian"
                ;;
            centos|rhel|fedora|rocky|almalinux|ol)
                OS_FAMILY="rhel"
                ;;
            alpine)
                OS_FAMILY="alpine"
                ;;
            arch|manjaro)
                OS_FAMILY="arch"
                ;;
            *)
                OS_FAMILY="unknown"
                ;;
        esac
    else
        log_error "Cannot detect OS: /etc/os-release not found"
        exit 1
    fi
    
    log_info "Detected OS: ${BOLD}$OS $OS_VERSION${NC} (family: $OS_FAMILY)"
}

# ============================================================================
# Prerequisite Installation
# ============================================================================

install_prerequisites() {
    log_header "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in git curl; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "All prerequisites are installed"
        return 0
    fi
    
    log_info "Installing missing prerequisites: ${missing_deps[*]}"
    
    case "$OS_FAMILY" in
        debian)
            sudo apt-get update -qq
            sudo apt-get install -y -qq "${missing_deps[@]}"
            ;;
        rhel)
            if command_exists dnf; then
                sudo dnf install -y -q "${missing_deps[@]}"
            else
                sudo yum install -y -q "${missing_deps[@]}"
            fi
            ;;
        alpine)
            sudo apk add --quiet "${missing_deps[@]}"
            ;;
        arch)
            sudo pacman -Sy --noconfirm --quiet "${missing_deps[@]}"
            ;;
        *)
            log_error "Unsupported OS family: $OS_FAMILY"
            log_error "Please manually install: ${missing_deps[*]}"
            exit 1
            ;;
    esac
    
    log_success "Prerequisites installed successfully"
}

# ============================================================================
# Repository Setup
# ============================================================================

setup_repository() {
    log_header "Setting Up LabRat"
    
    if [[ -d "$LABRAT_DIR" ]]; then
        log_info "LabRat directory exists, updating..."
        cd "$LABRAT_DIR"
        
        if [[ -d ".git" ]]; then
            git fetch origin "$LABRAT_BRANCH" --quiet
            git reset --hard "origin/$LABRAT_BRANCH" --quiet
            log_success "Updated to latest version"
        else
            log_warn "Directory exists but is not a git repo, removing and re-cloning..."
            cd "$HOME"
            rm -rf "$LABRAT_DIR"
            git clone --branch "$LABRAT_BRANCH" --depth 1 "$LABRAT_REPO" "$LABRAT_DIR" --quiet
            log_success "Repository cloned successfully"
        fi
    else
        log_info "Cloning LabRat repository..."
        git clone --branch "$LABRAT_BRANCH" --depth 1 "$LABRAT_REPO" "$LABRAT_DIR" --quiet
        log_success "Repository cloned successfully"
    fi
    
    cd "$LABRAT_DIR"
}

# ============================================================================
# Offline Mode (Download without git)
# ============================================================================

download_without_git() {
    log_header "Setting Up LabRat (Offline Mode)"
    
    local archive_url="${LABRAT_REPO%.git}/archive/refs/heads/${LABRAT_BRANCH}.tar.gz"
    local temp_archive="/tmp/labrat-$$.tar.gz"
    
    log_info "Downloading LabRat archive..."
    
    if command_exists curl; then
        curl -fsSL "$archive_url" -o "$temp_archive"
    elif command_exists wget; then
        wget -q "$archive_url" -O "$temp_archive"
    else
        log_error "Neither curl nor wget available for download"
        exit 1
    fi
    
    log_info "Extracting archive..."
    mkdir -p "$LABRAT_DIR"
    tar -xzf "$temp_archive" -C "$LABRAT_DIR" --strip-components=1
    rm -f "$temp_archive"
    
    cd "$LABRAT_DIR"
    log_success "LabRat downloaded and extracted"
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    log_header "🐀 LabRat Bootstrap"
    log_info "Your trusty environment for every test cage"
    echo ""
    
    # Detect operating system
    detect_os
    
    # Check if we can install prerequisites (might need sudo)
    install_prerequisites
    
    # Clone or update the repository
    if command_exists git; then
        setup_repository
    else
        download_without_git
    fi
    
    # Make installer executable
    chmod +x "$LABRAT_DIR/install.sh"
    
    # Hand off to main installer with any passed arguments
    log_header "Launching LabRat Installer"
    
    # Check if stdin is a terminal (not a pipe)
    # When piping (wget ... | bash), stdin is consumed by the pipe
    # In that case, we need to either:
    #   1. Run non-interactively with --all -y
    #   2. Redirect stdin from /dev/tty for interactive input
    if [[ ! -t 0 ]]; then
        # stdin is not a terminal (likely piped)
        if [[ -e /dev/tty ]]; then
            # /dev/tty exists, we can redirect stdin for interactive use
            log_info "Piped install detected, reconnecting to terminal for interactive mode..."
            exec "$LABRAT_DIR/install.sh" "$@" < /dev/tty
        else
            # No tty available (e.g., cron, non-interactive container)
            # Default to full install with auto-confirm
            log_warn "Non-interactive environment detected"
            log_info "Running with --all --yes for unattended install"
            log_info "Use 'install.sh' directly for interactive mode"
            exec "$LABRAT_DIR/install.sh" --all --yes "$@"
        fi
    else
        # Normal interactive invocation
        exec "$LABRAT_DIR/install.sh" "$@"
    fi
}

# Run main with all script arguments
main "$@"
