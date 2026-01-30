#!/usr/bin/env bash
#
# LabRat Remote Test Runner
# Run tests on a remote WSL/Linux host via SSH
#
# Usage:
#   ./scripts/test-remote.sh <hostname> [branch]
#   ./scripts/test-remote.sh wsl-client hardening
#

set -uo pipefail

# ============================================================================
# Configuration
# ============================================================================

REMOTE_HOST="${1:-}"
BRANCH="${2:-hardening}"
LABRAT_DIR="~/.labrat"
LABRAT_REPO="https://github.com/amd-marmoody/Labrat.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_header() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_usage() {
    cat << EOF
${BOLD}LabRat Remote Test Runner${NC}

${BOLD}USAGE:${NC}
    $(basename "$0") <hostname> [branch]

${BOLD}ARGUMENTS:${NC}
    hostname    SSH hostname or alias (e.g., wsl-client, 192.168.1.100)
    branch      Git branch to test (default: hardening)

${BOLD}EXAMPLES:${NC}
    $(basename "$0") wsl-client
    $(basename "$0") wsl-client main
    $(basename "$0") user@192.168.1.100 hardening

${BOLD}REQUIREMENTS:${NC}
    - SSH access to remote host
    - Git installed on remote host
    - Docker installed on remote host (for container tests)

${BOLD}ENVIRONMENT VARIABLES:${NC}
    LABRAT_REPO     Repository URL (default: GitHub)
    LABRAT_DIR      Remote installation directory (default: ~/.labrat)

EOF
}

# ============================================================================
# Main Functions
# ============================================================================

check_ssh_connection() {
    log_info "Checking SSH connection to ${REMOTE_HOST}..."
    
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$REMOTE_HOST" exit 2>/dev/null; then
        log_success "SSH connection successful"
        return 0
    else
        log_error "Cannot connect to ${REMOTE_HOST}"
        log_error "Ensure SSH is configured correctly"
        return 1
    fi
}

setup_remote_labrat() {
    log_info "Setting up LabRat on remote host..."
    
    ssh "$REMOTE_HOST" << SETUP_EOF
        set -e
        
        # Check if labrat directory exists
        if [[ -d "$LABRAT_DIR" ]]; then
            echo "LabRat directory exists, updating..."
            cd "$LABRAT_DIR"
            git fetch origin "$BRANCH" 2>/dev/null || true
            git checkout "$BRANCH" 2>/dev/null || true
            git pull origin "$BRANCH" 2>/dev/null || true
        else
            echo "Cloning LabRat repository..."
            git clone -b "$BRANCH" "$LABRAT_REPO" "$LABRAT_DIR"
        fi
        
        # Make scripts executable
        cd "$LABRAT_DIR"
        chmod +x install.sh labrat_bootstrap.sh 2>/dev/null || true
        chmod +x tests/*.sh tests/**/*.sh 2>/dev/null || true
        chmod +x bin/* 2>/dev/null || true
        
        echo "Setup complete"
SETUP_EOF
}

run_remote_tests() {
    local test_type="${1:-all}"
    
    log_header "Running Tests on ${REMOTE_HOST}"
    log_info "Test type: ${test_type}"
    log_info "Branch: ${BRANCH}"
    
    ssh "$REMOTE_HOST" << TEST_EOF
        set -e
        cd "$LABRAT_DIR"
        
        echo ""
        echo "=== System Information ==="
        echo "Host: \$(hostname)"
        echo "OS: \$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 || uname -s)"
        echo "Bash: \$(bash --version | head -1)"
        echo "Docker: \$(docker --version 2>/dev/null || echo 'Not installed')"
        echo ""
        
        case "$test_type" in
            unit)
                echo "=== Running Unit Tests ==="
                make test-unit 2>/dev/null || ./tests/run_tests.sh unit
                ;;
            docker)
                echo "=== Running Docker Tests ==="
                make test-harness 2>/dev/null || {
                    docker build -t labrat-test-harness -f tests/docker/Dockerfile.test-harness .
                    docker run --rm labrat-test-harness ./tests/run_all_tests.sh
                }
                ;;
            all|*)
                echo "=== Running All Tests ==="
                chmod +x ./tests/run_all_tests.sh
                ./tests/run_all_tests.sh
                ;;
        esac
TEST_EOF
}

show_remote_status() {
    log_info "Checking remote LabRat status..."
    
    ssh "$REMOTE_HOST" << STATUS_EOF
        cd "$LABRAT_DIR" 2>/dev/null || exit 1
        
        echo ""
        echo "=== Git Status ==="
        git log --oneline -5
        
        echo ""
        echo "=== Branch ==="
        git branch --show-current
        
        echo ""
        echo "=== Installed Modules ==="
        if [[ -d ~/.local/share/labrat/installed ]]; then
            ls -1 ~/.local/share/labrat/installed 2>/dev/null || echo "None"
        else
            echo "None"
        fi
STATUS_EOF
}

# ============================================================================
# Main
# ============================================================================

main() {
    if [[ -z "$REMOTE_HOST" ]]; then
        print_usage
        exit 1
    fi
    
    log_header "LabRat Remote Test Runner"
    
    # Check SSH connection
    check_ssh_connection || exit 1
    
    # Setup labrat on remote
    setup_remote_labrat || exit 1
    
    # Run tests
    run_remote_tests "${3:-all}"
    
    local exit_code=$?
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_success "Remote tests completed successfully!"
    else
        log_error "Some tests failed (exit code: $exit_code)"
    fi
    
    exit $exit_code
}

main "$@"
