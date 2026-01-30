#!/usr/bin/env bash
#
# Integration Tests: Module Functionality
# Tests that installed modules work correctly
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# Binary Tests - Check binaries run and respond to basic commands
# ============================================================================

test_binary_version() {
    local binary="$1"
    local flag="${2:---version}"
    
    if ! command -v "$binary" &>/dev/null; then
        skip_test "$binary not in PATH"
        return 0
    fi
    
    if $binary $flag &>/dev/null; then
        pass_test "$binary $flag works"
        return 0
    else
        fail_test "$binary $flag failed"
        return 1
    fi
}

test_binary_help() {
    local binary="$1"
    
    if ! command -v "$binary" &>/dev/null; then
        skip_test "$binary not in PATH"
        return 0
    fi
    
    if $binary --help &>/dev/null; then
        pass_test "$binary --help works"
        return 0
    else
        fail_test "$binary --help failed"
        return 1
    fi
}

# ============================================================================
# Core Utility Tests
# ============================================================================

test_ripgrep_search() {
    log_test "Testing ripgrep functionality"
    
    if ! command -v rg &>/dev/null; then
        skip_test "ripgrep not installed"
        return 0
    fi
    
    # Create temp file to search
    local tmpfile=$(mktemp)
    echo "LabRat test string" > "$tmpfile"
    
    if rg "LabRat" "$tmpfile" &>/dev/null; then
        pass_test "ripgrep search works"
        rm -f "$tmpfile"
        return 0
    else
        fail_test "ripgrep search failed"
        rm -f "$tmpfile"
        return 1
    fi
}

test_bat_file_display() {
    log_test "Testing bat file display"
    
    if ! command -v bat &>/dev/null; then
        skip_test "bat not installed"
        return 0
    fi
    
    # Create temp file
    local tmpfile=$(mktemp --suffix=.sh)
    echo '#!/bin/bash' > "$tmpfile"
    echo 'echo "Hello"' >> "$tmpfile"
    
    if bat --plain "$tmpfile" &>/dev/null; then
        pass_test "bat file display works"
        rm -f "$tmpfile"
        return 0
    else
        fail_test "bat file display failed"
        rm -f "$tmpfile"
        return 1
    fi
}

test_fd_find() {
    log_test "Testing fd find"
    
    if ! command -v fd &>/dev/null; then
        skip_test "fd not installed"
        return 0
    fi
    
    # Find in labrat directory
    if fd --max-depth 2 "install" "$LABRAT_ROOT" &>/dev/null; then
        pass_test "fd find works"
        return 0
    else
        fail_test "fd find failed"
        return 1
    fi
}

test_fzf_basic() {
    log_test "Testing fzf basic operation"
    
    if ! command -v fzf &>/dev/null; then
        skip_test "fzf not installed"
        return 0
    fi
    
    # Test fzf with input (non-interactive)
    if echo -e "one\ntwo\nthree" | fzf --filter="two" &>/dev/null; then
        pass_test "fzf filter works"
        return 0
    else
        fail_test "fzf filter failed"
        return 1
    fi
}

test_eza_list() {
    log_test "Testing eza list"
    
    if ! command -v eza &>/dev/null; then
        skip_test "eza not installed"
        return 0
    fi
    
    if eza -la "$LABRAT_ROOT" &>/dev/null; then
        pass_test "eza listing works"
        return 0
    else
        fail_test "eza listing failed"
        return 1
    fi
}

test_zoxide_init() {
    log_test "Testing zoxide initialization"
    
    if ! command -v zoxide &>/dev/null; then
        skip_test "zoxide not installed"
        return 0
    fi
    
    if zoxide init bash &>/dev/null; then
        pass_test "zoxide init works"
        return 0
    else
        fail_test "zoxide init failed"
        return 1
    fi
}

# ============================================================================
# Editor Tests
# ============================================================================

test_neovim_headless() {
    log_test "Testing neovim headless"
    
    if ! command -v nvim &>/dev/null; then
        skip_test "neovim not installed"
        return 0
    fi
    
    if nvim --headless -c 'qall' &>/dev/null; then
        pass_test "neovim runs headless"
        return 0
    else
        fail_test "neovim headless failed"
        return 1
    fi
}

test_vim_version() {
    log_test "Testing vim"
    
    if ! command -v vim &>/dev/null; then
        skip_test "vim not installed"
        return 0
    fi
    
    if vim --version | head -1 &>/dev/null; then
        pass_test "vim runs"
        return 0
    else
        fail_test "vim failed"
        return 1
    fi
}

# ============================================================================
# Shell Enhancement Tests
# ============================================================================

test_starship_init() {
    log_test "Testing starship initialization"
    
    if ! command -v starship &>/dev/null; then
        skip_test "starship not installed"
        return 0
    fi
    
    if starship init bash &>/dev/null; then
        pass_test "starship init works"
        return 0
    else
        fail_test "starship init failed"
        return 1
    fi
}

test_atuin_init() {
    log_test "Testing atuin initialization"
    
    if ! command -v atuin &>/dev/null; then
        skip_test "atuin not installed"
        return 0
    fi
    
    if atuin init bash &>/dev/null; then
        pass_test "atuin init works"
        return 0
    else
        fail_test "atuin init failed"
        return 1
    fi
}

test_direnv_allow() {
    log_test "Testing direnv"
    
    if ! command -v direnv &>/dev/null; then
        skip_test "direnv not installed"
        return 0
    fi
    
    if direnv version &>/dev/null; then
        pass_test "direnv runs"
        return 0
    else
        fail_test "direnv failed"
        return 1
    fi
}

# ============================================================================
# Monitoring Tools Tests
# ============================================================================

test_htop_version() {
    test_binary_version "htop" "--version"
}

test_btop_version() {
    test_binary_version "btop" "--version"
}

test_procs_list() {
    log_test "Testing procs"
    
    if ! command -v procs &>/dev/null; then
        skip_test "procs not installed"
        return 0
    fi
    
    if procs --no-header 2>/dev/null | head -5 &>/dev/null; then
        pass_test "procs listing works"
        return 0
    else
        fail_test "procs listing failed"
        return 1
    fi
}

# ============================================================================
# Productivity Tools Tests
# ============================================================================

test_just_version() {
    test_binary_version "just" "--version"
}

test_tldr_test() {
    log_test "Testing tldr"
    
    if ! command -v tldr &>/dev/null; then
        skip_test "tldr not installed"
        return 0
    fi
    
    # Test with a common command
    if tldr ls 2>/dev/null | head -5 &>/dev/null; then
        pass_test "tldr works"
        return 0
    else
        # May need to update database first
        skip_test "tldr may need cache update"
        return 0
    fi
}

test_broot_version() {
    test_binary_version "broot" "--version"
}

# ============================================================================
# Network Tools Tests
# ============================================================================

test_gping_version() {
    test_binary_version "gping" "--version"
}

test_dog_version() {
    test_binary_version "dog" "--version"
}

# ============================================================================
# LabRat Tools Tests
# ============================================================================

test_labrat_menu() {
    log_test "Testing labrat-menu"
    
    local menu="$LABRAT_ROOT/bin/labrat-menu"
    
    if [[ -x "$menu" ]]; then
        # Test --help
        if "$menu" --help &>/dev/null; then
            pass_test "labrat-menu --help works"
            return 0
        else
            fail_test "labrat-menu --help failed"
            return 1
        fi
    else
        skip_test "labrat-menu not found"
        return 0
    fi
}

test_labrat_ssh() {
    log_test "Testing labrat-ssh"
    
    local ssh_tool="$LABRAT_ROOT/bin/labrat-ssh"
    
    if [[ -x "$ssh_tool" ]]; then
        # Test --help or help command
        if "$ssh_tool" help &>/dev/null || "$ssh_tool" --help &>/dev/null; then
            pass_test "labrat-ssh help works"
            return 0
        else
            fail_test "labrat-ssh help failed"
            return 1
        fi
    else
        skip_test "labrat-ssh not found"
        return 0
    fi
}

test_labrat_uninstall() {
    log_test "Testing labrat-uninstall"
    
    local uninstall="$LABRAT_ROOT/bin/labrat-uninstall"
    
    if [[ -x "$uninstall" ]]; then
        # Test --help
        if "$uninstall" --help &>/dev/null; then
            pass_test "labrat-uninstall --help works"
            return 0
        else
            fail_test "labrat-uninstall --help failed"
            return 1
        fi
    else
        skip_test "labrat-uninstall not found"
        return 0
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "Functionality Tests" \
    test_ripgrep_search \
    test_bat_file_display \
    test_fd_find \
    test_fzf_basic \
    test_eza_list \
    test_zoxide_init \
    test_neovim_headless \
    test_vim_version \
    test_starship_init \
    test_atuin_init \
    test_direnv_allow \
    test_htop_version \
    test_btop_version \
    test_procs_list \
    test_just_version \
    test_tldr_test \
    test_broot_version \
    test_gping_version \
    test_dog_version \
    test_labrat_menu \
    test_labrat_ssh \
    test_labrat_uninstall
