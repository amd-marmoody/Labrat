#!/usr/bin/env bash
#
# Integration Tests: Theme Switching
# Tests theme switching for all themed modules
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# Theme Data
# ============================================================================

# tmux themes (must match tmux-theme script's THEME_PLUGINS keys)
TMUX_THEMES=(
    "catppuccin-mocha"
    "catppuccin-latte"
    "dracula"
    "nord"
    "tokyo-night"
    "gruvbox-dark"
    "onedark"
    "minimal"
)

# fzf themes
FZF_THEMES=(
    "catppuccin-mocha"
    "catppuccin-latte"
    "catppuccin-frappe"
    "catppuccin-macchiato"
    "gruvbox-dark"
    "gruvbox-light"
    "tokyo-night"
    "nord"
    "dracula"
)

# atuin themes
ATUIN_THEMES=(
    "catppuccin-mocha"
    "catppuccin-latte"
    "catppuccin-frappe"
    "catppuccin-macchiato"
    "gruvbox-dark"
    "gruvbox-light"
)

# starship presets
STARSHIP_PRESETS=(
    "labrat"
    "minimal"
    "pure"
    "pastel-powerline"
    "tokyo-night"
    "gruvbox-rainbow"
    "plain-text"
    "nerd-font-symbols"
)

# ============================================================================
# tmux Theme Tests
# ============================================================================

test_tmux_theme_list() {
    log_test "Testing tmux-theme --list"
    
    if [[ ! -x "$LABRAT_ROOT/bin/tmux-theme" ]]; then
        skip_test "tmux-theme not found"
        return 0
    fi
    
    local output
    output=$("$LABRAT_ROOT/bin/tmux-theme" --list 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        pass_test "tmux-theme --list works"
        return 0
    else
        fail_test "tmux-theme --list returned no output"
        return 1
    fi
}

test_tmux_theme_switching() {
    log_test "Testing tmux theme switching"
    
    if [[ ! -x "$LABRAT_ROOT/bin/tmux-theme" ]]; then
        skip_test "tmux-theme not found"
        return 0
    fi
    
    # Check if tmux module is installed (theme file exists)
    local data_dir="${LABRAT_DATA_DIR:-$HOME/.local/share/labrat}"
    if [[ ! -f "$data_dir/installed/tmux" ]] && [[ ! -f "$HOME/.tmux.conf" ]]; then
        skip_test "tmux module not installed (skipping theme switching)"
        return 0
    fi
    
    local failed=0
    
    for theme in "${TMUX_THEMES[@]}"; do
        if "$LABRAT_ROOT/bin/tmux-theme" "$theme" 2>/dev/null; then
            pass_test "tmux theme: $theme"
        else
            fail_test "tmux theme failed: $theme"
            ((failed++))
        fi
    done
    
    return $failed
}

test_tmux_theme_persistence() {
    log_test "Testing tmux theme persistence"
    
    # tmux-theme stores theme in ~/.tmux-theme (not ~/.config/labrat/tmux_theme)
    local theme_file="$HOME/.tmux-theme"
    
    if [[ ! -x "$LABRAT_ROOT/bin/tmux-theme" ]]; then
        skip_test "tmux-theme not found"
        return 0
    fi
    
    # Set a theme
    "$LABRAT_ROOT/bin/tmux-theme" dracula 2>/dev/null
    
    if [[ -f "$theme_file" ]]; then
        local saved
        saved=$(cat "$theme_file")
        if [[ "$saved" == "dracula" ]]; then
            pass_test "Theme persisted correctly"
            return 0
        else
            fail_test "Theme file contains wrong value: $saved"
            return 1
        fi
    else
        fail_test "Theme file not created"
        return 1
    fi
}

# ============================================================================
# fzf Theme Tests
# ============================================================================

test_fzf_theme_list() {
    log_test "Testing fzf-theme --list"
    
    if [[ ! -x "$LABRAT_ROOT/bin/fzf-theme" ]]; then
        skip_test "fzf-theme not found"
        return 0
    fi
    
    local output
    output=$("$LABRAT_ROOT/bin/fzf-theme" --list 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        pass_test "fzf-theme --list works"
        return 0
    else
        fail_test "fzf-theme --list returned no output"
        return 1
    fi
}

test_fzf_theme_switching() {
    log_test "Testing fzf theme switching"
    
    if [[ ! -x "$LABRAT_ROOT/bin/fzf-theme" ]]; then
        skip_test "fzf-theme not found"
        return 0
    fi
    
    local failed=0
    
    for theme in "${FZF_THEMES[@]}"; do
        if "$LABRAT_ROOT/bin/fzf-theme" "$theme" 2>/dev/null; then
            pass_test "fzf theme: $theme"
        else
            fail_test "fzf theme failed: $theme"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# atuin Theme Tests
# ============================================================================

test_atuin_theme_list() {
    log_test "Testing atuin-theme --list"
    
    if [[ ! -x "$LABRAT_ROOT/bin/atuin-theme" ]]; then
        skip_test "atuin-theme not found"
        return 0
    fi
    
    local output
    output=$("$LABRAT_ROOT/bin/atuin-theme" --list 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        pass_test "atuin-theme --list works"
        return 0
    else
        fail_test "atuin-theme --list returned no output"
        return 1
    fi
}

test_atuin_theme_switching() {
    log_test "Testing atuin theme switching"
    
    if [[ ! -x "$LABRAT_ROOT/bin/atuin-theme" ]]; then
        skip_test "atuin-theme not found"
        return 0
    fi
    
    local failed=0
    
    for theme in "${ATUIN_THEMES[@]}"; do
        if "$LABRAT_ROOT/bin/atuin-theme" "$theme" 2>/dev/null; then
            pass_test "atuin theme: $theme"
        else
            fail_test "atuin theme failed: $theme"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# starship Preset Tests
# ============================================================================

test_starship_preset_list() {
    log_test "Testing starship-preset --list"
    
    if [[ ! -x "$LABRAT_ROOT/bin/starship-preset" ]]; then
        skip_test "starship-preset not found"
        return 0
    fi
    
    local output
    output=$("$LABRAT_ROOT/bin/starship-preset" --list 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        pass_test "starship-preset --list works"
        return 0
    else
        fail_test "starship-preset --list returned no output"
        return 1
    fi
}

test_starship_preset_switching() {
    log_test "Testing starship preset switching"
    
    if [[ ! -x "$LABRAT_ROOT/bin/starship-preset" ]]; then
        skip_test "starship-preset not found"
        return 0
    fi
    
    local failed=0
    
    for preset in "${STARSHIP_PRESETS[@]}"; do
        if "$LABRAT_ROOT/bin/starship-preset" "$preset" 2>/dev/null; then
            pass_test "starship preset: $preset"
        else
            fail_test "starship preset failed: $preset"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# labrat-theme Global Theme Tests
# ============================================================================

test_labrat_theme_list() {
    log_test "Testing labrat-theme --list"
    
    if [[ ! -x "$LABRAT_ROOT/bin/labrat-theme" ]]; then
        skip_test "labrat-theme not found"
        return 0
    fi
    
    local output
    output=$("$LABRAT_ROOT/bin/labrat-theme" --list 2>/dev/null)
    
    if [[ -n "$output" ]]; then
        pass_test "labrat-theme --list works"
        return 0
    else
        fail_test "labrat-theme --list returned no output"
        return 1
    fi
}

test_labrat_theme_global() {
    log_test "Testing labrat-theme global switching"
    
    if [[ ! -x "$LABRAT_ROOT/bin/labrat-theme" ]]; then
        skip_test "labrat-theme not found"
        return 0
    fi
    
    local themes=("catppuccin-mocha" "dracula" "nord")
    local failed=0
    
    for theme in "${themes[@]}"; do
        if "$LABRAT_ROOT/bin/labrat-theme" "$theme" 2>/dev/null; then
            pass_test "labrat-theme global: $theme"
        else
            fail_test "labrat-theme global failed: $theme"
            ((failed++))
        fi
    done
    
    return $failed
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "Theme Switching Tests" \
    test_tmux_theme_list \
    test_tmux_theme_switching \
    test_tmux_theme_persistence \
    test_fzf_theme_list \
    test_fzf_theme_switching \
    test_atuin_theme_list \
    test_atuin_theme_switching \
    test_starship_preset_list \
    test_starship_preset_switching \
    test_labrat_theme_list \
    test_labrat_theme_global
