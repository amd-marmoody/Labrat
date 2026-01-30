# LabRat Module Development Guide

This guide explains how to create new modules for LabRat using the hardened library infrastructure.

## Table of Contents

1. [Module Structure](#module-structure)
2. [Module Template](#module-template)
3. [Using the New Libraries](#using-the-new-libraries)
4. [Best Practices](#best-practices)
5. [Testing Modules](#testing-modules)

---

## Module Structure

Modules are shell scripts in the `modules/<category>/` directory. Categories include:
- `terminal/` - Terminal multiplexers (tmux)
- `shell/` - Shell enhancements (zsh, starship)
- `editors/` - Text editors (neovim, vim)
- `utils/` - Utility tools (fzf, bat, ripgrep)
- `monitoring/` - System monitoring (btop, htop)
- `network/` - Network tools (mtr, gping)
- `productivity/` - Productivity tools (atuin, zoxide)
- `security/` - Security tools (ssh-keys)
- `fonts/` - Font installers (nerdfonts)

Each module must implement:
- `install_<module>()` - Main installation function
- `uninstall_<module>()` - Cleanup function (optional but recommended)

---

## Module Template

Use this template for new modules:

```bash
#!/usr/bin/env bash
#
# LabRat Module: <tool_name>
# <Brief description of what the tool does>
#
# Dependencies: <list any hard dependencies>
# Soft Dependencies: <list optional enhancements>
#

# ============================================================================
# Module Metadata
# ============================================================================

readonly TOOL_NAME="<tool_name>"
readonly TOOL_REPO="<owner>/<repo>"
readonly TOOL_DESCRIPTION="<description>"
readonly TOOL_BINARY="<binary_name>"

# ============================================================================
# Installation
# ============================================================================

install_<tool_name>() {
    # Use error context for meaningful error messages
    push_error_context "Installing $TOOL_NAME"
    
    # Log to persistent log file
    log_install_start "$TOOL_NAME"
    local start_time=$(date +%s)
    
    log_step "Installing $TOOL_NAME..."
    
    # -------------------------------------------------------------------------
    # Step 1: Check if already installed
    # -------------------------------------------------------------------------
    if command_exists "$TOOL_BINARY"; then
        local current_version=$("$TOOL_BINARY" --version 2>/dev/null | head -1)
        log_info "$TOOL_NAME already installed: $current_version"
        # Still continue to update config if needed
    fi
    
    # -------------------------------------------------------------------------
    # Step 2: Determine installation method
    # -------------------------------------------------------------------------
    local install_method=""
    local installed_version=""
    
    # Try package manager first (faster, gets updates)
    if pkg_available "$TOOL_BINARY"; then
        install_method="package"
    else
        install_method="binary"
    fi
    
    log_debug "Installation method: $install_method"
    
    # -------------------------------------------------------------------------
    # Step 3: Install the tool
    # -------------------------------------------------------------------------
    case "$install_method" in
        package)
            log_step "Installing $TOOL_NAME via package manager..."
            if ! safe_exec "Installing $TOOL_NAME package" pkg_install "$TOOL_BINARY"; then
                log_warn "Package install failed, falling back to binary"
                install_method="binary"
            fi
            ;;
    esac
    
    if [[ "$install_method" == "binary" ]]; then
        log_step "Installing $TOOL_NAME from GitHub release..."
        if ! install_<tool_name>_binary; then
            log_install_end "$TOOL_NAME" "failure" $(($(date +%s) - start_time))
            pop_error_context
            return 1
        fi
    fi
    
    # -------------------------------------------------------------------------
    # Step 4: Get installed version
    # -------------------------------------------------------------------------
    if command_exists "$TOOL_BINARY"; then
        installed_version=$("$TOOL_BINARY" --version 2>/dev/null | head -1)
    fi
    
    # -------------------------------------------------------------------------
    # Step 5: Deploy configuration (using atomic operations)
    # -------------------------------------------------------------------------
    if ! deploy_<tool_name>_config; then
        log_warn "Configuration deployment failed, but binary is installed"
    fi
    
    # -------------------------------------------------------------------------
    # Step 6: Setup shell integration
    # -------------------------------------------------------------------------
    setup_<tool_name>_shell_integration
    
    # -------------------------------------------------------------------------
    # Step 7: Suggest soft dependencies
    # -------------------------------------------------------------------------
    show_soft_dependency_suggestions "$TOOL_NAME"
    
    # -------------------------------------------------------------------------
    # Step 8: Mark as installed
    # -------------------------------------------------------------------------
    mark_module_installed "$TOOL_NAME" "$installed_version"
    
    local duration=$(($(date +%s) - start_time))
    log_install_end "$TOOL_NAME" "success" "$duration"
    pop_error_context
    
    log_success "$TOOL_NAME installed successfully!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_<tool_name>_binary() {
    push_error_context "Binary installation"
    
    # Get latest version
    local version=$(get_github_latest_release "$TOOL_REPO")
    if [[ -z "$version" ]]; then
        handle_error $E_NETWORK "Failed to get latest version from GitHub"
        pop_error_context
        return 1
    fi
    
    log_info "Latest version: $version"
    
    # Construct download URL based on architecture
    local arch_suffix=""
    case "$ARCH" in
        amd64)  arch_suffix="x86_64" ;;
        arm64)  arch_suffix="aarch64" ;;
        *)
            handle_error $E_INVALID_INPUT "Unsupported architecture: $ARCH"
            pop_error_context
            return 1
            ;;
    esac
    
    local os_suffix="unknown-linux-musl"
    local archive_name="${TOOL_BINARY}-${version}-${arch_suffix}-${os_suffix}.tar.gz"
    local download_url="https://github.com/${TOOL_REPO}/releases/download/${version}/${archive_name}"
    
    # Download to temp directory
    local temp_dir=$(mktemp -d)
    local archive_path="${temp_dir}/${archive_name}"
    
    if ! download_file "$download_url" "$archive_path" "Downloading $TOOL_NAME $version"; then
        rm -rf "$temp_dir"
        pop_error_context
        return 1
    fi
    
    # Extract and install
    tar -xzf "$archive_path" -C "$temp_dir"
    
    # Find and copy binary (use atomic copy)
    local binary_path=$(find "$temp_dir" -name "$TOOL_BINARY" -type f | head -1)
    if [[ -n "$binary_path" ]]; then
        safe_copy "$binary_path" "$LABRAT_BIN_DIR/$TOOL_BINARY" "$PERM_SCRIPT"
        log_success "Installed $TOOL_BINARY to $LABRAT_BIN_DIR/"
    else
        handle_error $E_FILE_NOT_FOUND "Binary not found in archive"
        rm -rf "$temp_dir"
        pop_error_context
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    pop_error_context
    return 0
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_<tool_name>_config() {
    log_step "Deploying $TOOL_NAME configuration..."
    push_error_context "Config deployment"
    
    local config_dir="$LABRAT_CONFIG_DIR/$TOOL_BINARY"
    
    # Create config directory with proper permissions
    ensure_dir "$config_dir"
    
    # Source config from labrat configs
    local source_config="${LABRAT_CONFIGS_DIR}/${TOOL_BINARY}/config"
    local target_config="${config_dir}/config"
    
    if [[ -f "$source_config" ]]; then
        # Use atomic write for config files
        if ! safe_copy "$source_config" "$target_config" "$PERM_CONFIG_FILE"; then
            handle_error $E_PERMISSION "Failed to deploy config"
            pop_error_context
            return 1
        fi
    fi
    
    # Deploy theme files if present
    local themes_source="${LABRAT_CONFIGS_DIR}/${TOOL_BINARY}/themes"
    local themes_target="${config_dir}/themes"
    
    if [[ -d "$themes_source" ]]; then
        ensure_dir "$themes_target"
        for theme_file in "$themes_source"/*; do
            if [[ -f "$theme_file" ]]; then
                safe_copy "$theme_file" "$themes_target/$(basename "$theme_file")"
            fi
        done
    fi
    
    pop_error_context
    log_success "Configuration deployed to $config_dir"
    return 0
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_<tool_name>_shell_integration() {
    log_step "Setting up $TOOL_NAME shell integration..."
    
    # Use the register_shell_module API
    register_shell_module "$TOOL_BINARY" \
        --init-bash 'eval "$('$TOOL_BINARY' init bash)"' \
        --init-zsh 'eval "$('$TOOL_BINARY' init zsh)"' \
        --init-fish $TOOL_BINARY' init fish | source' \
        --description "$TOOL_DESCRIPTION shell integration"
    
    log_success "Shell integration configured"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_<tool_name>() {
    log_step "Uninstalling $TOOL_NAME..."
    push_error_context "Uninstalling $TOOL_NAME"
    
    # Check if other modules depend on this one
    if warn_dependents "$TOOL_NAME"; then
        if ! confirm "Continue with uninstall?" "n"; then
            log_info "Uninstall cancelled"
            pop_error_context
            return 0
        fi
    fi
    
    # Remove binary
    rm -f "$LABRAT_BIN_DIR/$TOOL_BINARY"
    
    # Remove configuration
    rm -rf "$LABRAT_CONFIG_DIR/$TOOL_BINARY"
    
    # Remove shell integration
    unregister_shell_module "$TOOL_BINARY"
    
    # Remove state files
    rm -f "$LABRAT_STATE_DIR/${TOOL_NAME}_*"
    
    # Remove installed marker
    rm -f "$LABRAT_DATA_DIR/installed/$TOOL_NAME"
    
    pop_error_context
    log_success "$TOOL_NAME uninstalled"
}
```

---

## Using the New Libraries

### Error Handling (lib/errors.sh)

```bash
# Push context before operations
push_error_context "Installing tmux plugins"

# Handle errors with specific codes
if ! command_exists git; then
    handle_error $E_MISSING_DEP "git is required"
    pop_error_context
    return 1
fi

# Safe execution with automatic error handling
if ! safe_exec "Cloning repository" git clone "$repo" "$dir"; then
    # Already logged, just return
    pop_error_context
    return 1
fi

# Always pop context when done
pop_error_context
```

### File Operations (lib/file_ops.sh)

```bash
# Create directories with proper permissions
ensure_dir "$config_dir" 755
ensure_private_dir "$ssh_dir"  # Creates with 700

# Atomic file writes (safe for concurrent access)
atomic_write "$config_file" "$content" 644

# Safe copy with permission preservation
safe_copy "$source" "$target" 755

# File locking for shared resources
with_lock "/tmp/labrat-manifest.lock" update_manifest "$module"

# Transactions for multi-file operations
transaction_begin "module_install"
transaction_record "file" "$config_file"
transaction_record "file" "$binary_file"

if ! some_operation; then
    transaction_rollback  # Restores all recorded files
    return 1
fi

transaction_commit
```

### Logging (lib/logging.sh)

```bash
# Log installation events (persisted to ~/.cache/labrat/logs/)
log_install_start "module_name"
log_install_step "module_name" "Downloading binary..."
log_install_end "module_name" "success" "$duration_seconds"

# Log errors with context
log_error_context "tmux installation" "TPM clone failed" "Network timeout"
log_command_failure "git clone $repo" "$exit_code" "$output"
```

### Dependencies (lib/dependencies.sh)

```bash
# Check if dependencies are met
if unmet=$(check_module_dependencies "$module"); then
    log_error "Missing dependencies: $unmet"
    return 1
fi

# Get installation order for multiple modules
install_order=$(get_install_order tmux fzf bat)
for module in $install_order; do
    install_module "$module"
done

# Show soft dependency suggestions
show_soft_dependency_suggestions "neovim"
# Output: "Optional: neovim works better with: nerdfonts ripgrep fd fzf"
```

---

## Best Practices

### 1. Always Use Error Context

```bash
install_foo() {
    push_error_context "Installing foo"
    # ... installation code ...
    pop_error_context
}
```

### 2. Use Atomic Operations for Config Files

```bash
# Don't do this:
echo "$content" > "$config"
chmod 600 "$config"

# Do this instead:
atomic_write "$config" "$content" 600
```

### 3. Check Return Values

```bash
# Every command that can fail should be checked
if ! download_file "$url" "$output"; then
    handle_error $E_NETWORK "Download failed"
    return 1
fi
```

### 4. Provide Uninstall Functions

```bash
# Every install function should have a corresponding uninstall
uninstall_foo() {
    rm -f "$LABRAT_BIN_DIR/foo"
    unregister_shell_module "foo"
    rm -f "$LABRAT_DATA_DIR/installed/foo"
}
```

### 5. Use Shell Integration API

```bash
# Use register_shell_module instead of direct bashrc manipulation
register_shell_module "tool" \
    --init 'eval "$(tool init bash)"' \
    --description "Tool initialization"
```

### 6. Log Important Events

```bash
log_install_start "$module"
# ... do work ...
log_install_end "$module" "success" "$duration"
```

---

## Testing Modules

### Manual Testing

```bash
# Install your module
./install.sh -m yourmodule -v

# Check it works
yourmodule --version

# Check shell integration
source ~/.bashrc
# Verify any aliases/functions work

# Test uninstall
./install.sh --uninstall yourmodule
```

### Automated Testing

Add tests to `tests/modules/test_yourmodule.sh`:

```bash
#!/usr/bin/env bash

source "$(dirname "$0")/../lib/test_framework.sh"

test_yourmodule_install() {
    # Run installation
    ./install.sh -m yourmodule -y
    
    # Verify binary exists
    assert_command_exists "yourmodule" "Binary should be installed"
    
    # Verify config exists
    assert_file_exists "$HOME/.config/yourmodule/config"
    
    # Verify shell integration
    assert_file_contains "$HOME/.config/labrat/modules/bash/yourmodule.sh" "yourmodule"
}

test_yourmodule_uninstall() {
    ./install.sh --uninstall yourmodule
    
    assert_file_not_exists "$HOME/.local/bin/yourmodule"
    assert_file_not_exists "$HOME/.config/labrat/modules/bash/yourmodule.sh"
}

run_test_suite "yourmodule"
```

Run tests:
```bash
make test-module M=yourmodule
```

---

## Error Codes Reference

| Code | Constant | Meaning |
|------|----------|---------|
| 0 | `E_SUCCESS` | Success |
| 1 | `E_GENERAL` | General failure |
| 2 | `E_MISSING_DEP` | Missing dependency |
| 3 | `E_NETWORK` | Network error |
| 4 | `E_PERMISSION` | Permission denied |
| 5 | `E_FILE_NOT_FOUND` | File not found |
| 6 | `E_INVALID_INPUT` | Invalid input |
| 7 | `E_MODULE_FAILED` | Module installation failed |
| 8 | `E_LOCK_FAILED` | Failed to acquire lock |
| 9 | `E_CHECKSUM_MISMATCH` | Checksum verification failed |
| 10 | `E_TIMEOUT` | Operation timed out |

---

## Quick Reference

```bash
# Libraries to source (automatically loaded via common.sh)
source "$LABRAT_LIB_DIR/common.sh"  # Loads all libraries

# Key functions:
push_error_context "context"
pop_error_context
handle_error $E_CODE "message"
safe_exec "description" command args

ensure_dir "$path" 755
ensure_private_dir "$path"
atomic_write "$file" "$content" 644
safe_copy "$src" "$dst" 755
with_lock "$lockfile" command

log_install_start "$module"
log_install_end "$module" "success" "$duration"
log_error_context "context" "error" "details"

register_shell_module "$name" --init "command" --description "desc"
unregister_shell_module "$name"

check_module_dependencies "$module"
show_soft_dependency_suggestions "$module"
warn_dependents "$module"
