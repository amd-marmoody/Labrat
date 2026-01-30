# ============================================================================
# LabRat Makefile
# Convenient commands for development and testing
# ============================================================================

.PHONY: help test test-unit test-integration test-docker test-docker-full \
        docker-shell-ubuntu docker-shell-centos clean clean-docker clean-all \
        docker-status lint install verify

# Default target
help:
	@echo ""
	@echo "LabRat Development Commands"
	@echo "============================"
	@echo ""
	@echo "Testing:"
	@echo "  make test              - Run all local tests (unit + integration)"
	@echo "  make test-unit         - Run unit tests only"
	@echo "  make test-integration  - Run integration tests"
	@echo "  make test-docker       - Run tests in Ubuntu container"
	@echo "  make test-docker-full  - Run full tests on Ubuntu + CentOS"
	@echo "  make test-module M=X   - Test specific module (e.g., M=tmux)"
	@echo ""
	@echo "Docker Development:"
	@echo "  make docker-shell-ubuntu  - Interactive Ubuntu shell"
	@echo "  make docker-shell-centos  - Interactive CentOS shell"
	@echo "  make docker-build         - Build all Docker images"
	@echo ""
	@echo "Verification:"
	@echo "  make verify            - Verify installed module configs"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean             - Remove test artifacts"
	@echo "  make clean-docker      - Remove Docker test images"
	@echo "  make clean-all         - Full cleanup (artifacts + images)"
	@echo "  make docker-status     - Show Docker images/containers"
	@echo ""
	@echo "Other:"
	@echo "  make lint              - Check scripts with shellcheck"
	@echo "  make install           - Install locally (interactive)"
	@echo ""

# ============================================================================
# Testing
# ============================================================================

test: test-unit test-integration
	@echo "All tests completed"

test-isolation:
	@echo "Running user isolation tests (requires Docker)..."
	@chmod +x ./tests/isolation/test_user_isolation.sh
	@./tests/isolation/test_user_isolation.sh

test-full: test test-isolation
	@echo "Full test suite (including isolation tests) completed"

test-security: test-isolation
	@echo "Security tests completed"

test-unit:
	@./tests/run_tests.sh unit

test-integration:
	@./tests/run_tests.sh integration

test-docker:
	@./tests/run_tests.sh docker ubuntu

test-docker-centos:
	@./tests/run_tests.sh docker centos

test-docker-full:
	@./tests/run_tests.sh docker-full

test-module:
ifndef M
	@echo "Usage: make test-module M=<module_name>"
	@echo "Example: make test-module M=tmux"
	@exit 1
endif
	@./tests/run_tests.sh module $(M)

# ============================================================================
# Docker Development
# ============================================================================

docker-shell-ubuntu:
	@./tests/run_tests.sh docker-shell ubuntu

docker-shell-centos:
	@./tests/run_tests.sh docker-shell centos

docker-build:
	@echo "Building Ubuntu image..."
	@docker build -t labrat-test-ubuntu -f tests/docker/Dockerfile.ubuntu .
	@echo "Building CentOS image..."
	@docker build -t labrat-test-centos -f tests/docker/Dockerfile.centos .
	@echo "Done!"

# ============================================================================
# Development Tools
# ============================================================================

lint:
	@echo "Running shellcheck..."
	@shellcheck -x install.sh labrat_bootstrap.sh lib/*.sh modules/*/*.sh tests/run_tests.sh || true
	@echo "Lint complete"

clean:
	@echo "Cleaning up test artifacts..."
	@rm -rf /tmp/labrat_test_*
	@echo "Done"

clean-docker:
	@echo "Removing Docker test images..."
	@docker rmi labrat-test-ubuntu 2>/dev/null && echo "  Removed: labrat-test-ubuntu" || echo "  labrat-test-ubuntu not found"
	@docker rmi labrat-test-centos 2>/dev/null && echo "  Removed: labrat-test-centos" || echo "  labrat-test-centos not found"
	@echo "Done"

clean-docker-all:
	@echo "Removing all LabRat Docker images and dangling images..."
	@docker rmi labrat-test-ubuntu labrat-test-centos 2>/dev/null || true
	@docker image prune -f 2>/dev/null || true
	@echo "Done"

clean-all: clean clean-docker
	@echo "Full cleanup complete"

docker-status:
	@echo ""
	@echo "Docker Images:"
	@docker images | grep -E "(REPOSITORY|labrat)" || echo "  No labrat images found"
	@echo ""
	@echo "Docker Containers (running):"
	@docker ps | grep -E "(CONTAINER|labrat)" || echo "  No labrat containers running"
	@echo ""

# ============================================================================
# Installation
# ============================================================================

install:
	@./install.sh

install-all:
	@./install.sh --all --yes

install-quick:
	@./install.sh --modules tmux,fzf,bat,ripgrep --yes

# ============================================================================
# Verification
# ============================================================================

verify:
	@echo "Verifying installed module configurations..."
	@./tests/run_tests.sh verify 2>/dev/null || ./tests/run_tests.sh unit
