#!/usr/bin/env bash
#
# LabRat Test Runner
# Run tests in Docker containers or locally
#

# Don't use set -e as we need to track test failures
set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="${SCRIPT_DIR}/docker"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# ============================================================================
# Logging
# ============================================================================

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; }
log_skip() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ============================================================================
# Test Assertions
# ============================================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$expected" == "$actual" ]]; then
        log_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$message (expected: '$expected', got: '$actual')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Assertion failed}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        log_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$message (string does not contain '$needle')"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command '$cmd' should exist}"
    
    if command -v "$cmd" &> /dev/null; then
        log_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File '$file' should exist}"
    
    if [[ -f "$file" ]]; then
        log_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory '$dir' should exist}"
    
    if [[ -d "$dir" ]]; then
        log_success "$message"
        ((TESTS_PASSED++))
        return 0
    else
        log_fail "$message"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Exit code should be $expected}"
    
    assert_equals "$expected" "$actual" "$message"
}

# ============================================================================
# Unit Tests - Library Functions
# ============================================================================

test_lib_colors() {
    log_header "Testing: lib/colors.sh"
    
    # Force colors on for testing
    export LABRAT_FORCE_COLOR=1
    
    # Source in subshell to test, then check results
    local test_result
    test_result=$(bash -c '
        export LABRAT_FORCE_COLOR=1
        source "'"${LABRAT_ROOT}"'/lib/colors.sh"
        
        errors=0
        [[ -n "$RED" ]] || errors=$((errors + 1))
        [[ -n "$GREEN" ]] || errors=$((errors + 1))
        [[ -n "$NC" ]] || errors=$((errors + 1))
        [[ -n "$SYMBOL_CHECK" ]] || errors=$((errors + 1))
        [[ "$COLORS_ENABLED" == "true" ]] || errors=$((errors + 1))
        
        echo "$errors"
    ')
    
    if [[ "$test_result" == "0" ]]; then
        log_success "colors.sh: All color variables defined correctly"
        ((TESTS_PASSED++))
    else
        log_fail "colors.sh: $test_result variables not properly defined"
        ((TESTS_FAILED++))
    fi
}

test_lib_common() {
    log_header "Testing: lib/common.sh"
    
    # Need to source colors first
    source "${LABRAT_ROOT}/lib/colors.sh"
    source "${LABRAT_ROOT}/lib/common.sh"
    
    # Test command_exists
    if command_exists bash; then
        log_success "command_exists: found bash"
        ((TESTS_PASSED++))
    else
        log_fail "command_exists: bash not found"
        ((TESTS_FAILED++))
    fi
    
    if ! command_exists nonexistent_command_xyz; then
        log_success "command_exists: correctly reports missing command"
        ((TESTS_PASSED++))
    else
        log_fail "command_exists: incorrectly found nonexistent command"
        ((TESTS_FAILED++))
    fi
    
    # Test version_compare
    version_compare "1.0.0" "1.0.0"
    assert_equals "0" "$?" "version_compare: 1.0.0 == 1.0.0"
    
    version_compare "2.0.0" "1.0.0"
    assert_equals "1" "$?" "version_compare: 2.0.0 > 1.0.0"
    
    version_compare "1.0.0" "2.0.0"
    assert_equals "2" "$?" "version_compare: 1.0.0 < 2.0.0"
    
    # Test version_gte
    if version_gte "2.0.0" "1.0.0"; then
        log_success "version_gte: 2.0.0 >= 1.0.0"
        ((TESTS_PASSED++))
    else
        log_fail "version_gte: 2.0.0 should be >= 1.0.0"
        ((TESTS_FAILED++))
    fi
    
    # Test ensure_dir
    local test_dir="/tmp/labrat_test_$$"
    ensure_dir "$test_dir"
    assert_dir_exists "$test_dir" "ensure_dir: created directory"
    rm -rf "$test_dir"
    
    # Test OS detection
    detect_os
    [[ -n "$OS" ]] && log_success "detect_os: OS=$OS" && ((TESTS_PASSED++)) || { log_fail "detect_os: OS not set"; ((TESTS_FAILED++)); }
    [[ -n "$OS_FAMILY" ]] && log_success "detect_os: OS_FAMILY=$OS_FAMILY" && ((TESTS_PASSED++)) || { log_fail "detect_os: OS_FAMILY not set"; ((TESTS_FAILED++)); }
    [[ -n "$ARCH" ]] && log_success "detect_os: ARCH=$ARCH" && ((TESTS_PASSED++)) || { log_fail "detect_os: ARCH not set"; ((TESTS_FAILED++)); }
}

test_lib_package_manager() {
    log_header "Testing: lib/package_manager.sh"
    
    source "${LABRAT_ROOT}/lib/package_manager.sh"
    
    # Test package manager detection
    [[ -n "$PKG_MANAGER" ]] && log_success "PKG_MANAGER detected: $PKG_MANAGER" && ((TESTS_PASSED++)) || { log_fail "PKG_MANAGER not detected"; ((TESTS_FAILED++)); }
    
    # Test pkg_name mapping
    local mapped_name=$(pkg_name "build-essential")
    [[ -n "$mapped_name" ]] && log_success "pkg_name: build-essential -> $mapped_name" && ((TESTS_PASSED++)) || { log_fail "pkg_name: mapping failed"; ((TESTS_FAILED++)); }
}

# ============================================================================
# Integration Tests - Module Installation
# ============================================================================

test_module_dry_run() {
    local module="$1"
    log_info "Testing module (dry run): $module"
    
    cd "$LABRAT_ROOT"
    
    if LABRAT_DRY_RUN=1 ./install.sh -m "$module" -y 2>&1 | grep -q "DRY RUN"; then
        log_success "Module $module: dry run works"
        ((TESTS_PASSED++))
    else
        log_fail "Module $module: dry run failed"
        ((TESTS_FAILED++))
    fi
}

test_module_installation() {
    local module="$1"
    log_info "Testing module installation: $module"
    
    cd "$LABRAT_ROOT"
    
    # Install the module
    if ./install.sh -m "$module" -y; then
        log_success "Module $module: installation completed"
        ((TESTS_PASSED++))
        
        # Check if marked as installed
        if [[ -f "$HOME/.local/share/labrat/installed/$module" ]]; then
            log_success "Module $module: marked as installed"
            ((TESTS_PASSED++))
        else
            log_fail "Module $module: not marked as installed"
            ((TESTS_FAILED++))
        fi
        
        # Run module-specific verification
        verify_module_config "$module"
    else
        log_fail "Module $module: installation failed"
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# Configuration Verification Tests
# ============================================================================

verify_module_config() {
    local module="$1"
    
    case "$module" in
        tmux)
            verify_tmux_config
            ;;
        neovim)
            verify_neovim_config
            ;;
        zsh)
            verify_zsh_config
            ;;
        starship)
            verify_starship_config
            ;;
        fzf)
            verify_fzf_config
            ;;
        *)
            verify_binary_installed "$module"
            ;;
    esac
}

verify_binary_installed() {
    local module="$1"
    local binary_name="$module"
    
    # Map module names to binary names
    case "$module" in
        ripgrep) binary_name="rg" ;;
        lazygit) binary_name="lazygit" ;;
        neovim) binary_name="nvim" ;;
    esac
    
    if command -v "$binary_name" &> /dev/null || [[ -f "$HOME/.local/bin/$binary_name" ]]; then
        log_success "Module $module: binary '$binary_name' is accessible"
        ((TESTS_PASSED++))
    else
        log_fail "Module $module: binary '$binary_name' not found in PATH"
        ((TESTS_FAILED++))
    fi
}

verify_tmux_config() {
    log_info "Verifying tmux configuration..."
    
    # Check tmux binary
    if command -v tmux &> /dev/null; then
        log_success "tmux: binary installed"
        ((TESTS_PASSED++))
    else
        log_fail "tmux: binary not found"
        ((TESTS_FAILED++))
        return
    fi
    
    # Check tmux.conf exists
    if [[ -f "$HOME/.tmux.conf" ]] || [[ -L "$HOME/.tmux.conf" ]]; then
        log_success "tmux: config file exists"
        ((TESTS_PASSED++))
    else
        log_fail "tmux: config file missing"
        ((TESTS_FAILED++))
    fi
    
    # Check TPM installed
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        log_success "tmux: TPM (plugin manager) installed"
        ((TESTS_PASSED++))
    else
        log_fail "tmux: TPM not installed"
        ((TESTS_FAILED++))
    fi
    
    # Verify prefix key (default is Ctrl-b, can be customized to Ctrl-a)
    if grep -q "^# set -g prefix C-a" "$HOME/.tmux.conf" 2>/dev/null; then
        log_success "tmux: prefix key is default (Ctrl-b)"
        ((TESTS_PASSED++))
    elif grep -q "set -g prefix C-a" "$HOME/.tmux.conf" 2>/dev/null; then
        log_success "tmux: prefix key configured (Ctrl-a)"
        ((TESTS_PASSED++))
    else
        log_success "tmux: prefix key is default (Ctrl-b)"
        ((TESTS_PASSED++))
    fi
    
    # Verify mouse support enabled
    if grep -q "mouse on" "$HOME/.tmux.conf" 2>/dev/null; then
        log_success "tmux: mouse support enabled"
        ((TESTS_PASSED++))
    else
        log_skip "tmux: could not verify mouse setting"
        ((TESTS_SKIPPED++))
    fi
    
    # Verify tmux-resurrect plugin configured
    if grep -q "tmux-resurrect" "$HOME/.tmux.conf" 2>/dev/null; then
        log_success "tmux: resurrect plugin configured"
        ((TESTS_PASSED++))
    else
        log_skip "tmux: resurrect plugin not found"
        ((TESTS_SKIPPED++))
    fi
}

verify_neovim_config() {
    log_info "Verifying neovim configuration..."
    
    # Check nvim binary
    local nvim_path
    nvim_path=$(command -v nvim 2>/dev/null || echo "$HOME/.local/bin/nvim")
    
    if [[ -x "$nvim_path" ]]; then
        log_success "neovim: binary installed"
        ((TESTS_PASSED++))
        
        # Check version
        local version
        version=$("$nvim_path" --version 2>/dev/null | head -1)
        log_info "neovim: $version"
    else
        log_fail "neovim: binary not found"
        ((TESTS_FAILED++))
        return
    fi
    
    # Check config directory
    if [[ -d "$HOME/.config/nvim" ]]; then
        log_success "neovim: config directory exists"
        ((TESTS_PASSED++))
    else
        log_skip "neovim: config directory not found"
        ((TESTS_SKIPPED++))
    fi
}

verify_zsh_config() {
    log_info "Verifying zsh configuration..."
    
    # Check zsh binary
    if command -v zsh &> /dev/null; then
        log_success "zsh: binary installed"
        ((TESTS_PASSED++))
    else
        log_fail "zsh: binary not found"
        ((TESTS_FAILED++))
        return
    fi
    
    # Check Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "zsh: Oh My Zsh installed"
        ((TESTS_PASSED++))
    else
        log_skip "zsh: Oh My Zsh not found"
        ((TESTS_SKIPPED++))
    fi
    
    # Check .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        log_success "zsh: .zshrc exists"
        ((TESTS_PASSED++))
    else
        log_fail "zsh: .zshrc missing"
        ((TESTS_FAILED++))
    fi
}

verify_starship_config() {
    log_info "Verifying starship configuration..."
    
    # Check starship binary
    local starship_path
    starship_path=$(command -v starship 2>/dev/null || echo "$HOME/.local/bin/starship")
    
    if [[ -x "$starship_path" ]]; then
        log_success "starship: binary installed"
        ((TESTS_PASSED++))
    else
        log_fail "starship: binary not found"
        ((TESTS_FAILED++))
        return
    fi
    
    # Check config file
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        log_success "starship: config file exists"
        ((TESTS_PASSED++))
    else
        log_skip "starship: config file not found (using defaults)"
        ((TESTS_SKIPPED++))
    fi
}

verify_fzf_config() {
    log_info "Verifying fzf configuration..."
    
    # Check fzf binary
    local fzf_path
    fzf_path=$(command -v fzf 2>/dev/null || echo "$HOME/.local/bin/fzf")
    
    if [[ -x "$fzf_path" ]]; then
        log_success "fzf: binary installed"
        ((TESTS_PASSED++))
    else
        log_fail "fzf: binary not found"
        ((TESTS_FAILED++))
        return
    fi
    
    # Check fzf directory
    if [[ -d "$HOME/.fzf" ]] || [[ -d "$HOME/.local/share/fzf" ]]; then
        log_success "fzf: installation directory exists"
        ((TESTS_PASSED++))
    else
        log_skip "fzf: installation directory not found"
        ((TESTS_SKIPPED++))
    fi
}

run_config_verification() {
    log_header "Running Configuration Verification Tests"
    
    local installed_dir="$HOME/.local/share/labrat/installed"
    
    if [[ ! -d "$installed_dir" ]] || [[ -z "$(ls -A "$installed_dir" 2>/dev/null)" ]]; then
        log_info "No modules installed to verify"
        return
    fi
    
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local module
            module=$(basename "$marker")
            verify_module_config "$module"
        fi
    done
}

# ============================================================================
# Docker-based Tests
# ============================================================================

docker_build() {
    local distro="$1"
    local dockerfile="${DOCKER_DIR}/Dockerfile.${distro}"
    local image_name="labrat-test-${distro}"
    
    if [[ ! -f "$dockerfile" ]]; then
        log_fail "Dockerfile not found: $dockerfile"
        return 1
    fi
    
    log_info "Building Docker image: $image_name"
    
    if docker build -t "$image_name" -f "$dockerfile" "$LABRAT_ROOT" > /dev/null 2>&1; then
        log_success "Built image: $image_name"
        return 0
    else
        log_fail "Failed to build: $image_name"
        return 1
    fi
}

docker_test() {
    local distro="$1"
    local test_cmd="${2:-./tests/run_tests.sh --unit}"
    local image_name="labrat-test-${distro}"
    
    log_header "Running tests in Docker: $distro"
    
    # Build the image
    if ! docker_build "$distro"; then
        return 1
    fi
    
    # Run tests in container
    log_info "Running tests in container..."
    
    if docker run --rm "$image_name" bash -c "$test_cmd"; then
        log_success "Tests passed in $distro"
        return 0
    else
        log_fail "Tests failed in $distro"
        return 1
    fi
}

docker_interactive() {
    local distro="${1:-ubuntu}"
    local image_name="labrat-test-${distro}"
    
    log_info "Starting interactive shell in $distro container..."
    
    docker_build "$distro" || return 1
    
    docker run -it --rm \
        -v "${LABRAT_ROOT}:/home/testuser/.labrat" \
        "$image_name" \
        /bin/bash
}

docker_test_module() {
    local distro="$1"
    local module="$2"
    local image_name="labrat-test-${distro}"
    
    log_info "Testing module '$module' in $distro..."
    
    docker_build "$distro" || return 1
    
    if docker run --rm "$image_name" bash -c "./install.sh -m $module -y"; then
        log_success "Module $module: installed successfully on $distro"
        ((TESTS_PASSED++))
    else
        log_fail "Module $module: installation failed on $distro"
        ((TESTS_FAILED++))
    fi
}

# ============================================================================
# Test Suites
# ============================================================================

run_unit_tests() {
    log_header "Running Unit Tests"
    
    test_lib_colors
    test_lib_common
    test_lib_package_manager
}

run_integration_tests() {
    log_header "Running Integration Tests"
    
    # Test dry run for each module
    for module in htop ripgrep bat fd; do
        test_module_dry_run "$module"
    done
}

run_docker_tests() {
    local distros=("ubuntu" "centos")
    
    for distro in "${distros[@]}"; do
        docker_test "$distro" "./tests/run_tests.sh --unit"
    done
}

run_full_docker_tests() {
    local distros=("ubuntu" "centos")
    local modules=("htop" "ripgrep" "bat" "fzf")
    
    for distro in "${distros[@]}"; do
        log_header "Full tests on $distro"
        
        for module in "${modules[@]}"; do
            docker_test_module "$distro" "$module"
        done
    done
}

# ============================================================================
# Results Summary
# ============================================================================

print_summary() {
    log_header "Test Results Summary"
    
    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    
    echo -e "  ${GREEN}Passed:${NC}  $TESTS_PASSED"
    echo -e "  ${RED}Failed:${NC}  $TESTS_FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $TESTS_SKIPPED"
    echo -e "  ${BOLD}Total:${NC}   $total"
    echo ""
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "  ${GREEN}${BOLD}✓ All tests passed!${NC}"
        return 0
    else
        echo -e "  ${RED}${BOLD}✗ Some tests failed${NC}"
        return 1
    fi
}

# ============================================================================
# Usage
# ============================================================================

print_usage() {
    cat << EOF
${BOLD}LabRat Test Runner${NC}

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS] [COMMAND]

${BOLD}COMMANDS:${NC}
    unit                Run unit tests locally
    integration         Run integration tests locally
    docker [DISTRO]     Run tests in Docker container
    docker-full         Run full test suite in all containers
    docker-shell [DISTRO]  Start interactive shell in container
    module MODULE       Test a specific module installation
    all                 Run all local tests

${BOLD}OPTIONS:${NC}
    -h, --help          Show this help message
    --unit              Run only unit tests
    --integration       Run only integration tests
    --docker            Run tests in Docker
    --verbose           Verbose output

${BOLD}EXAMPLES:${NC}
    $(basename "$0") unit                    # Run unit tests
    $(basename "$0") docker ubuntu           # Test in Ubuntu container
    $(basename "$0") docker-shell centos     # Interactive CentOS shell
    $(basename "$0") module tmux             # Test tmux module
    $(basename "$0") all                     # Run all tests

EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    local command="${1:-}"
    shift || true
    
    case "$command" in
        unit|--unit)
            run_unit_tests
            ;;
        integration|--integration)
            run_integration_tests
            ;;
        docker)
            local distro="${1:-ubuntu}"
            docker_test "$distro"
            ;;
        docker-full)
            run_full_docker_tests
            ;;
        docker-shell)
            local distro="${1:-ubuntu}"
            docker_interactive "$distro"
            exit 0
            ;;
        module)
            local module="${1:-}"
            if [[ -z "$module" ]]; then
                log_fail "Please specify a module to test"
                exit 1
            fi
            test_module_installation "$module"
            ;;
        verify)
            run_config_verification
            ;;
        all)
            run_unit_tests
            run_integration_tests
            ;;
        -h|--help|help)
            print_usage
            exit 0
            ;;
        "")
            run_unit_tests
            ;;
        *)
            log_fail "Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac
    
    print_summary
}

main "$@"
