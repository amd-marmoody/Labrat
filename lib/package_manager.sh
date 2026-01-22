#!/usr/bin/env bash
#
# LabRat - Package Manager Abstraction
# Provides a unified interface for apt, yum/dnf, and other package managers
#

# Ensure common functions are loaded
LABRAT_LIB_DIR="${LABRAT_LIB_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck source=./common.sh
source "${LABRAT_LIB_DIR}/common.sh"

# ============================================================================
# Package Manager Detection
# ============================================================================

# Detect available package manager
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists yum; then
        echo "yum"
    elif command_exists apk; then
        echo "apk"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

# ============================================================================
# Package Installation
# ============================================================================

# Install system packages
# Usage: pkg_install package1 package2 ...
pkg_install() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages specified for installation"
        return 0
    fi
    
    log_step "Installing packages: ${packages[*]}"
    
    case "$PKG_MANAGER" in
        apt)
            run_privileged apt-get update -qq
            run_privileged apt-get install -y -qq "${packages[@]}"
            ;;
        dnf)
            run_privileged dnf install -y -q "${packages[@]}"
            ;;
        yum)
            run_privileged yum install -y -q "${packages[@]}"
            ;;
        apk)
            run_privileged apk add --quiet "${packages[@]}"
            ;;
        pacman)
            run_privileged pacman -Sy --noconfirm --quiet "${packages[@]}"
            ;;
        zypper)
            run_privileged zypper install -y -q "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "Packages installed successfully"
}

# Install a package only if not already installed
# Usage: pkg_install_if_missing package
pkg_install_if_missing() {
    local package="$1"
    
    if pkg_is_installed "$package"; then
        log_debug "Package already installed: $package"
        return 0
    fi
    
    pkg_install "$package"
}

# ============================================================================
# Package Query
# ============================================================================

# Check if a package is installed
# Usage: pkg_is_installed package
pkg_is_installed() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$package" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
        zypper)
            zypper se -i "$package" >/dev/null 2>&1
            ;;
        *)
            log_warn "Cannot check package status for: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Get installed version of a system package
# Usage: pkg_version package
pkg_version() {
    local package="$1"
    
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | awk '/^ii/{print $3}'
            ;;
        dnf|yum)
            rpm -q --queryformat '%{VERSION}' "$package" 2>/dev/null
            ;;
        apk)
            apk info -v "$package" 2>/dev/null | cut -d'-' -f2
            ;;
        pacman)
            pacman -Qi "$package" 2>/dev/null | awk '/^Version/{print $3}'
            ;;
        zypper)
            zypper info "$package" 2>/dev/null | awk '/^Version/{print $3}'
            ;;
        *)
            echo ""
            ;;
    esac
}

# ============================================================================
# Package Search
# ============================================================================

# Search for packages matching a pattern
# Usage: pkg_search pattern
pkg_search() {
    local pattern="$1"
    
    case "$PKG_MANAGER" in
        apt)
            apt-cache search "$pattern"
            ;;
        dnf)
            dnf search "$pattern"
            ;;
        yum)
            yum search "$pattern"
            ;;
        apk)
            apk search "$pattern"
            ;;
        pacman)
            pacman -Ss "$pattern"
            ;;
        zypper)
            zypper search "$pattern"
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
}

# ============================================================================
# Package Removal
# ============================================================================

# Remove system packages
# Usage: pkg_remove package1 package2 ...
pkg_remove() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages specified for removal"
        return 0
    fi
    
    log_step "Removing packages: ${packages[*]}"
    
    case "$PKG_MANAGER" in
        apt)
            run_privileged apt-get remove -y -qq "${packages[@]}"
            ;;
        dnf)
            run_privileged dnf remove -y -q "${packages[@]}"
            ;;
        yum)
            run_privileged yum remove -y -q "${packages[@]}"
            ;;
        apk)
            run_privileged apk del --quiet "${packages[@]}"
            ;;
        pacman)
            run_privileged pacman -Rs --noconfirm --quiet "${packages[@]}"
            ;;
        zypper)
            run_privileged zypper remove -y -q "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "Packages removed successfully"
}

# ============================================================================
# System Updates
# ============================================================================

# Update package lists
# Usage: pkg_update
pkg_update() {
    log_step "Updating package lists..."
    
    case "$PKG_MANAGER" in
        apt)
            run_privileged apt-get update -qq
            ;;
        dnf)
            run_privileged dnf check-update -q || true
            ;;
        yum)
            run_privileged yum check-update -q || true
            ;;
        apk)
            run_privileged apk update --quiet
            ;;
        pacman)
            run_privileged pacman -Sy --quiet
            ;;
        zypper)
            run_privileged zypper refresh -q
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "Package lists updated"
}

# Upgrade all packages
# Usage: pkg_upgrade
pkg_upgrade() {
    log_step "Upgrading all packages..."
    
    case "$PKG_MANAGER" in
        apt)
            run_privileged apt-get upgrade -y -qq
            ;;
        dnf)
            run_privileged dnf upgrade -y -q
            ;;
        yum)
            run_privileged yum upgrade -y -q
            ;;
        apk)
            run_privileged apk upgrade --quiet
            ;;
        pacman)
            run_privileged pacman -Syu --noconfirm --quiet
            ;;
        zypper)
            run_privileged zypper update -y -q
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "All packages upgraded"
}

# ============================================================================
# Package Name Mapping
# ============================================================================

# Some packages have different names on different distros
# This provides a mapping for common packages

declare -A PKG_MAP_DEBIAN=(
    ["build-essential"]="build-essential"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["nodejs"]="nodejs"
    ["golang"]="golang-go"
    ["rust"]="rustc"
    ["ruby"]="ruby-full"
    ["java"]="default-jdk"
    ["cmake"]="cmake"
    ["ninja"]="ninja-build"
    ["ncurses"]="libncurses-dev"
    ["ssl"]="libssl-dev"
    ["curl"]="curl"
    ["wget"]="wget"
    ["git"]="git"
    ["vim"]="vim"
    ["neovim"]="neovim"
    ["tmux"]="tmux"
    ["htop"]="htop"
    ["tree"]="tree"
    ["jq"]="jq"
    ["unzip"]="unzip"
    ["zip"]="zip"
)

declare -A PKG_MAP_RHEL=(
    ["build-essential"]="gcc gcc-c++ make"
    ["python3"]="python3"
    ["python3-pip"]="python3-pip"
    ["nodejs"]="nodejs"
    ["golang"]="golang"
    ["rust"]="rust"
    ["ruby"]="ruby"
    ["java"]="java-11-openjdk-devel"
    ["cmake"]="cmake"
    ["ninja"]="ninja-build"
    ["ncurses"]="ncurses-devel"
    ["ssl"]="openssl-devel"
    ["curl"]="curl"
    ["wget"]="wget"
    ["git"]="git"
    ["vim"]="vim-enhanced"
    ["neovim"]="neovim"
    ["tmux"]="tmux"
    ["htop"]="htop"
    ["tree"]="tree"
    ["jq"]="jq"
    ["unzip"]="unzip"
    ["zip"]="zip"
)

# Get the distro-specific package name
# Usage: pkg_name generic_name
pkg_name() {
    local generic="$1"
    local mapped=""
    
    case "$OS_FAMILY" in
        debian)
            mapped="${PKG_MAP_DEBIAN[$generic]:-}"
            ;;
        rhel)
            mapped="${PKG_MAP_RHEL[$generic]:-}"
            ;;
    esac
    
    # Return mapped name or original if no mapping exists
    echo "${mapped:-$generic}"
}

# Install packages using generic names
# Usage: pkg_install_generic package1 package2 ...
pkg_install_generic() {
    local generic_packages=("$@")
    local actual_packages=()
    
    for pkg in "${generic_packages[@]}"; do
        actual_packages+=("$(pkg_name "$pkg")")
    done
    
    pkg_install "${actual_packages[@]}"
}

# ============================================================================
# Development Dependencies
# ============================================================================

# Install common build tools
install_build_tools() {
    log_subheader "Installing Build Tools"
    
    case "$OS_FAMILY" in
        debian)
            pkg_install build-essential cmake git curl wget
            ;;
        rhel)
            pkg_install gcc gcc-c++ make cmake git curl wget
            # Enable EPEL for additional packages
            if ! pkg_is_installed epel-release; then
                pkg_install epel-release
            fi
            ;;
        alpine)
            pkg_install build-base cmake git curl wget
            ;;
        arch)
            pkg_install base-devel cmake git curl wget
            ;;
    esac
    
    log_success "Build tools installed"
}

# ============================================================================
# Repository Management
# ============================================================================

# Add an APT repository (Debian/Ubuntu only)
# Usage: apt_add_repo "ppa:user/repo" or apt_add_repo "deb http://..."
apt_add_repo() {
    local repo="$1"
    
    if [[ "$PKG_MANAGER" != "apt" ]]; then
        log_warn "apt_add_repo is only for Debian-based systems"
        return 1
    fi
    
    # Install software-properties-common if needed
    if ! command_exists add-apt-repository; then
        pkg_install software-properties-common
    fi
    
    log_step "Adding repository: $repo"
    run_privileged add-apt-repository -y "$repo"
    run_privileged apt-get update -qq
}

# Add a YUM/DNF repository (RHEL-based only)
# Usage: yum_add_repo "repo_url" "repo_name"
yum_add_repo() {
    local repo_url="$1"
    local repo_name="$2"
    
    if [[ "$PKG_MANAGER" != "yum" ]] && [[ "$PKG_MANAGER" != "dnf" ]]; then
        log_warn "yum_add_repo is only for RHEL-based systems"
        return 1
    fi
    
    log_step "Adding repository: $repo_name"
    
    if command_exists dnf; then
        run_privileged dnf config-manager --add-repo "$repo_url"
    else
        run_privileged yum-config-manager --add-repo "$repo_url"
    fi
}

# ============================================================================
# Cleanup
# ============================================================================

# Clean package cache to free space
pkg_clean() {
    log_step "Cleaning package cache..."
    
    case "$PKG_MANAGER" in
        apt)
            run_privileged apt-get autoremove -y -qq
            run_privileged apt-get clean
            ;;
        dnf)
            run_privileged dnf autoremove -y -q
            run_privileged dnf clean all -q
            ;;
        yum)
            run_privileged yum autoremove -y -q
            run_privileged yum clean all -q
            ;;
        apk)
            run_privileged apk cache clean
            ;;
        pacman)
            run_privileged pacman -Sc --noconfirm
            ;;
        zypper)
            run_privileged zypper clean --all
            ;;
    esac
    
    log_success "Package cache cleaned"
}
