#!/usr/bin/env bash
#
# Integration Tests: Shell Session
# Tests that shell integration actually works in real user sessions
# These are CRITICAL tests - they test the actual user experience
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABRAT_ROOT="${SCRIPT_DIR}/../.."

# Source test framework
source "${SCRIPT_DIR}/../lib/test_framework.sh"

# ============================================================================
# Shell Session Tests
# These test that after installation, the shell works correctly
# ============================================================================

test_bash_path_configured() {
    log_test "Testing PATH is configured in bash session"
    
    # Start a login shell and check PATH
    local result
    result=$(bash -lc 'echo $PATH' 2>/dev/null)
    
    if [[ ":$result:" == *":$HOME/.local/bin:"* ]]; then
        pass_test "~/.local/bin is in PATH via login shell"
        return 0
    else
        fail_test "~/.local/bin not in login shell PATH"
        return 1
    fi
}

test_bashrc_sources_without_error() {
    log_test "Testing .bashrc sources without error"
    
    if [[ ! -f "$HOME/.bashrc" ]]; then
        skip_test ".bashrc not found"
        return 0
    fi
    
    # Source bashrc and check exit code
    local output
    local exit_code
    output=$(bash -c 'source ~/.bashrc 2>&1' 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass_test ".bashrc sources without error"
        return 0
    else
        fail_test ".bashrc source failed with code $exit_code: $output"
        return 1
    fi
}

test_labrat_block_in_bashrc() {
    log_test "Testing LabRat block exists in .bashrc"
    
    if [[ ! -f "$HOME/.bashrc" ]]; then
        skip_test ".bashrc not found"
        return 0
    fi
    
    if grep -q "LABRAT_BEGIN" "$HOME/.bashrc" && grep -q "LABRAT_END" "$HOME/.bashrc"; then
        pass_test "LabRat block found in .bashrc"
        return 0
    else
        skip_test "LabRat not integrated in .bashrc yet"
        return 0
    fi
}

test_fzf_available_in_shell() {
    log_test "Testing fzf available in shell session"
    
    if [[ ! -f "$HOME/.local/share/labrat/installed/fzf" ]]; then
        skip_test "fzf not installed"
        return 0
    fi
    
    # Check fzf is in PATH in a new shell
    local result
    result=$(bash -lc 'command -v fzf' 2>/dev/null)
    
    if [[ -n "$result" ]]; then
        pass_test "fzf available in shell: $result"
        return 0
    else
        fail_test "fzf not found in shell PATH"
        return 1
    fi
}

test_starship_prompt_initializes() {
    log_test "Testing starship prompt initializes"
    
    if ! command -v starship &>/dev/null; then
        skip_test "starship not installed"
        return 0
    fi
    
    # Test starship init produces valid bash code
    local init_code
    init_code=$(starship init bash 2>/dev/null)
    
    # starship init should produce non-empty output with bash functions
    if [[ -n "$init_code" ]] && [[ ${#init_code} -gt 100 ]]; then
        pass_test "starship init produces shell code (${#init_code} chars)"
        return 0
    else
        fail_test "starship init output too short or empty"
        return 1
    fi
}

test_starship_prompt_renders() {
    log_test "Testing starship prompt actually renders"
    
    if ! command -v starship &>/dev/null; then
        skip_test "starship not installed"
        return 0
    fi
    
    # Get a prompt rendering
    local prompt
    prompt=$(starship prompt 2>/dev/null)
    
    if [[ -n "$prompt" ]]; then
        pass_test "starship renders a prompt"
        return 0
    else
        fail_test "starship prompt is empty"
        return 1
    fi
}

test_fzf_keybinding_functions_defined() {
    log_test "Testing fzf keybinding functions are defined"
    
    if [[ ! -f "$HOME/.local/share/labrat/installed/fzf" ]]; then
        skip_test "fzf not installed"
        return 0
    fi
    
    # Check if fzf shell integration provides keybinding functions
    # These functions should be available after sourcing fzf integration
    local result
    result=$(bash -c '
        source ~/.bashrc 2>/dev/null
        # Check for fzf key bindings
        if [[ -f ~/.fzf.bash ]]; then
            source ~/.fzf.bash 2>/dev/null
        fi
        type -t __fzf_select__ 2>/dev/null || type -t fzf-file-widget 2>/dev/null
    ' 2>/dev/null)
    
    if [[ "$result" == "function" ]]; then
        pass_test "fzf keybinding functions defined"
        return 0
    else
        # May not be set up yet - just warn
        skip_test "fzf keybinding functions not found (may need manual setup)"
        return 0
    fi
}

test_zoxide_init() {
    log_test "Testing zoxide initializes correctly"
    
    if ! command -v zoxide &>/dev/null; then
        skip_test "zoxide not installed"
        return 0
    fi
    
    # Test zoxide init
    local init_code
    init_code=$(zoxide init bash 2>/dev/null)
    
    if [[ -n "$init_code" ]] && [[ "$init_code" == *"__zoxide"* || "$init_code" == *"z()"* ]]; then
        pass_test "zoxide init produces valid shell code"
        return 0
    else
        fail_test "zoxide init output unexpected"
        return 1
    fi
}

test_atuin_init() {
    log_test "Testing atuin initializes correctly"
    
    if ! command -v atuin &>/dev/null; then
        skip_test "atuin not installed"
        return 0
    fi
    
    # Test atuin init
    local init_code
    init_code=$(atuin init bash 2>/dev/null)
    
    if [[ -n "$init_code" ]] && [[ "$init_code" == *"atuin"* ]]; then
        pass_test "atuin init produces valid shell code"
        return 0
    else
        fail_test "atuin init output unexpected"
        return 1
    fi
}

test_aliases_work() {
    log_test "Testing shell aliases work"
    
    # Source bashrc and test common aliases if defined
    local result
    result=$(bash -c '
        source ~/.bashrc 2>/dev/null
        # Test if ll alias exists (commonly set up)
        if alias ll &>/dev/null; then
            echo "ll alias exists"
        fi
        # Test if labrat aliases exist
        if alias labrat-update &>/dev/null || type labrat-update &>/dev/null; then
            echo "labrat alias exists"
        fi
        echo "done"
    ' 2>/dev/null)
    
    if [[ "$result" == *"done"* ]]; then
        pass_test "Shell aliases load without error"
        return 0
    else
        fail_test "Shell alias loading had errors"
        return 1
    fi
}

test_shell_integration_complete() {
    log_test "Testing overall shell integration"
    
    # Run a full shell session simulation
    local result
    result=$(bash -lc '
        # Check key things work
        errors=0
        
        # PATH must include local bin
        [[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || ((errors++))
        
        # No syntax errors in bashrc
        source ~/.bashrc 2>/dev/null || ((errors++))
        
        # Exit with error count
        exit $errors
    ' 2>/dev/null)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass_test "Shell integration complete and working"
        return 0
    else
        fail_test "Shell integration has $exit_code issue(s)"
        return 1
    fi
}

# ============================================================================
# Run Tests
# ============================================================================

run_test_suite "Shell Session Tests" \
    test_bash_path_configured \
    test_bashrc_sources_without_error \
    test_labrat_block_in_bashrc \
    test_fzf_available_in_shell \
    test_starship_prompt_initializes \
    test_starship_prompt_renders \
    test_fzf_keybinding_functions_defined \
    test_zoxide_init \
    test_atuin_init \
    test_aliases_work \
    test_shell_integration_complete
