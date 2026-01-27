#!/bin/bash
#
# LabRat Interactive Docker Test Runner
# Builds and runs an interactive container for testing fresh installs
#
# Usage:
#   ./tests/docker-test.sh              # Build and run with local source mounted
#   ./tests/docker-test.sh --remote     # Run without mount (for wget testing)
#   ./tests/docker-test.sh --build      # Force rebuild
#   ./tests/docker-test.sh --zsh        # Start with zsh instead of bash
#   ./tests/docker-test.sh --clean      # Remove test image
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="labrat-test"
DOCKERFILE="$SCRIPT_DIR/docker/Dockerfile.interactive"

# Default settings
MOUNT_SOURCE=true
SHELL_CMD="/bin/bash"
EXTRA_ENV=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}     ${GREEN}LabRat Interactive Test Environment${NC}      ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
}

build_image() {
    echo -e "${YELLOW}Building Docker image...${NC}"
    cd "$LABRAT_DIR"
    docker build -f "$DOCKERFILE" -t "$IMAGE_NAME" .
    echo -e "${GREEN}✓ Image built successfully${NC}"
}

run_container() {
    local shell="${1:-/bin/bash}"
    
    echo -e "${YELLOW}Starting container...${NC}"
    
    local docker_args=(-it --rm --hostname "labrat-test" -e "LABRAT_TEST=1")
    
    if [[ "$MOUNT_SOURCE" == "true" ]]; then
        echo -e "  Mount: ${LABRAT_DIR} → /labrat-src"
        docker_args+=(-v "$LABRAT_DIR:/labrat-src:ro")
    else
        echo -e "  Mount: ${DIM}none (remote wget mode)${NC}"
    fi
    
    # Add any extra env vars
    if [[ -n "$EXTRA_ENV" ]]; then
        for env_var in $EXTRA_ENV; do
            docker_args+=(-e "$env_var")
        done
    fi
    
    echo -e "  Shell: ${shell}"
    echo ""
    
    docker run "${docker_args[@]}" "$IMAGE_NAME" "$shell"
}

run_remote_container() {
    MOUNT_SOURCE=false
    
    # Check for repo/branch arguments
    if [[ -n "${LABRAT_REPO:-}" ]]; then
        EXTRA_ENV="LABRAT_REPO=$LABRAT_REPO"
    fi
    if [[ -n "${LABRAT_BRANCH:-}" ]]; then
        EXTRA_ENV="$EXTRA_ENV LABRAT_BRANCH=$LABRAT_BRANCH"
    fi
    
    run_container "$SHELL_CMD"
}

clean_image() {
    echo -e "${YELLOW}Removing test image...${NC}"
    docker rmi "$IMAGE_NAME" 2>/dev/null || true
    echo -e "${GREEN}✓ Cleaned${NC}"
}

# Main
case "${1:-}" in
    --build|-b)
        print_header
        build_image
        ;;
    --remote|-r)
        print_header
        echo -e "${YELLOW}Remote wget testing mode${NC}"
        echo -e "No local source mounted - use lr-wget commands inside container"
        echo ""
        # Build if image doesn't exist
        if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
            build_image
        fi
        run_remote_container
        ;;
    --zsh|-z)
        print_header
        SHELL_CMD="/usr/bin/zsh"
        # Build if image doesn't exist
        if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
            build_image
        fi
        run_container "$SHELL_CMD"
        ;;
    --clean|-c)
        clean_image
        ;;
    --help|-h)
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  (none)      Build if needed and run with local source mounted"
        echo "  --remote    Run without mount for wget testing from GitHub"
        echo "  --build     Force rebuild the image"
        echo "  --zsh       Run with zsh instead of bash"
        echo "  --clean     Remove the test image"
        echo ""
        echo "Inside the container (local mount mode):"
        echo "  lr-install    - Run install.sh from source"
        echo "  lr-bootstrap  - Run bootstrap script"
        echo "  lr-menu       - Run labrat-menu directly"
        echo ""
        echo "Inside the container (remote wget mode):"
        echo "  lr-wget           - Download and run bootstrap from LABRAT_REPO"
        echo "  lr-test-remote    - Quick test: lr-test-remote <github-user> [branch]"
        echo ""
        echo "Environment variables:"
        echo "  LABRAT_REPO=https://github.com/USER/labrat.git"
        echo "  LABRAT_BRANCH=main"
        ;;
    *)
        print_header
        # Build if image doesn't exist
        if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
            build_image
        fi
        run_container "/bin/bash"
        ;;
esac
