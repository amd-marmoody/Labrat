# LabRat Testing Infrastructure Audit

## Executive Summary

This document provides an in-depth audit of the LabRat CI/CD testing infrastructure, identifying gaps, evaluating test usefulness for real-world scenarios, and proposing improvements.

**Overall Assessment**: The current testing covers basic functionality but **lacks real-world usage simulation**. Most tests verify that binaries run, but don't test the actual workflows users would experience.

---

## Current Test Coverage Analysis

### What We Test Now

| Test Category | Count | Real-World Value | Gap |
|---------------|-------|------------------|-----|
| Unit: Constants | 11 | LOW | Tests library functions, not user-facing |
| Unit: Errors | 14 | MEDIUM | Error handling internal logic |
| Unit: File Ops | 23 | MEDIUM | File operations work |
| Integration: Configuration | 23 | MEDIUM | Config files exist |
| Integration: Functionality | 22 | LOW-MEDIUM | Binary --version works |
| Integration: Module Install | 9 | HIGH | Modules actually install |
| Integration: Theme Switching | 40 | MEDIUM | Theme scripts work in isolation |

### Critical Gap Analysis

#### 1. **Shell Integration Not Tested** 🔴 CRITICAL

**Problem**: We never test that shell integration actually works in a user's shell session.

**What's missing**:
- Does `source ~/.bashrc` after install actually work?
- Are PATH modifications correct?
- Do shell completions load?
- Does the prompt render correctly with starship?
- Do fzf keybindings (Ctrl-R, Ctrl-T) work?

**User Impact**: User installs LabRat, restarts shell, and things are broken.

#### 2. **tmux Session Testing Missing** 🔴 CRITICAL

**Problem**: We test that tmux binary runs but not that:
- tmux.conf loads without errors
- TPM plugins actually work
- Theme rendering is correct
- Key bindings function
- Session save/restore works

**User Impact**: User starts tmux and gets config errors or broken themes.

#### 3. **No End-to-End Workflow Tests** 🔴 CRITICAL

**Problem**: We don't test complete user workflows like:
- Bootstrap → Install → Configure → Use
- Update workflow
- Uninstall and cleanup
- Multi-tool integration (fzf + ripgrep + bat preview)

**User Impact**: Individual pieces work, but combined experience fails.

#### 4. **No Idempotency Testing** 🟡 HIGH

**Problem**: Running `install.sh` twice might break things.

**What's missing**:
- Can we run full install twice without errors?
- Does update mode work correctly?
- Are configs properly merged, not overwritten?

#### 5. **No Network Failure Testing** 🟡 HIGH

**Problem**: All tests assume perfect network connectivity.

**What's missing**:
- What happens when GitHub is unreachable?
- Are there proper timeouts?
- Does fallback to package manager work?

#### 6. **No Upgrade/Migration Testing** 🟡 HIGH

**Problem**: We don't test the upgrade path.

**What's missing**:
- Old version → New version upgrade
- Config migration
- Handling of deprecated settings

#### 7. **Limited Architecture Testing** 🟡 MEDIUM

**Current**: Only x86_64 tested.

**Missing**: arm64, armv7 testing.

---

## Test Usefulness Evaluation

### Tests That ARE Useful

| Test | Why It's Useful |
|------|-----------------|
| `test_module_install.sh` | Verifies install markers, real installation |
| `test_theme_switching.sh` | Theme scripts work, files created |
| `test_ripgrep_search` | Actually tests the tool's core function |
| `test_fzf_basic` | Tests filtering, core fzf behavior |

### Tests That Are NOT Useful (Smoke Tests Only)

| Test | Problem |
|------|---------|
| `test_binary_version()` | Just tests `--version` flag works |
| `test_binary_help()` | Just tests `--help` flag works |
| Most config existence tests | File exists ≠ file works |

### Tests That Are Missing Entirely

| Missing Test | Importance |
|--------------|------------|
| Interactive shell session | CRITICAL |
| tmux session management | CRITICAL |
| fzf interactive keybindings | HIGH |
| atuin history sync | HIGH |
| neovim plugin loading | HIGH |
| zsh plugin loading | HIGH |
| SSH key agent integration | MEDIUM |
| Font rendering (terminal) | LOW (hard to test) |

---

## Proposed Testing Expansion

### Phase 1: Shell Integration Tests (Priority: CRITICAL)

```bash
# tests/integration/test_shell_integration.sh

test_bash_shell_session() {
    # Start a new bash session and verify:
    # 1. PATH is correct
    # 2. LabRat functions are available
    # 3. Aliases work
    # 4. Prompt renders (if starship installed)
    
    docker run --rm labrat-test bash -lc '
        source ~/.bashrc
        
        # Test PATH
        [[ ":$PATH:" == *":$HOME/.local/bin:"* ]] || exit 1
        
        # Test command availability
        command -v fzf || exit 1
        
        # Test starship prompt (if installed)
        if command -v starship; then
            eval "$(starship init bash)"
            [[ "$PS1" != "$" ]] || exit 1
        fi
    '
}

test_fzf_keybindings() {
    # Test Ctrl-R history search works
    docker run --rm labrat-test bash -lc '
        source ~/.bashrc
        
        # Check fzf integration sourced
        type -t __fzf_history__ || exit 1
    '
}
```

### Phase 2: tmux Session Tests (Priority: CRITICAL)

```bash
# tests/integration/test_tmux_session.sh

test_tmux_config_loads() {
    docker run --rm labrat-test bash -c '
        # Start tmux server with our config
        tmux new-session -d -s test
        
        # Verify no errors
        tmux list-sessions | grep -q "test" || exit 1
        
        # Check prefix key works
        tmux send-keys -t test "C-b" ":" 
        sleep 0.5
        tmux capture-pane -t test -p | grep -q ":" || exit 1
        
        tmux kill-server
    '
}

test_tmux_plugins_installed() {
    docker run --rm labrat-test bash -c '
        # Check TPM is installed
        [[ -d ~/.tmux/plugins/tpm ]] || exit 1
        
        # Check at least one plugin loaded
        ls ~/.tmux/plugins/ | grep -v tpm | head -1
    '
}

test_tmux_theme_renders() {
    docker run --rm labrat-test bash -c '
        tmux new-session -d -s test
        tmux capture-pane -t test -p > /tmp/output
        
        # Status bar should have content
        wc -c < /tmp/output | grep -v "^0$" || exit 1
        
        tmux kill-server
    '
}
```

### Phase 3: End-to-End Workflow Tests (Priority: HIGH)

```bash
# tests/e2e/test_full_workflow.sh

test_bootstrap_to_usage() {
    docker run --rm ubuntu:22.04 bash -c '
        # Simulate user experience
        apt-get update && apt-get install -y curl git
        
        # Bootstrap
        curl -fsSL https://raw.githubusercontent.com/amd-marmoody/Labrat/main/labrat_bootstrap.sh | bash -s -- --modules tmux,fzf --yes
        
        # Verify
        source ~/.bashrc
        command -v tmux || exit 1
        command -v fzf || exit 1
        
        # Test actual usage
        echo "success" | fzf --filter="success" | grep -q "success" || exit 1
    '
}

test_update_workflow() {
    docker run --rm labrat-test bash -c '
        # Install initial
        ./install.sh -m fzf -y
        
        # Get initial version
        version1=$(cat ~/.local/share/labrat/installed/fzf)
        
        # Update
        ./install.sh --update
        
        # Verify still works
        fzf --version
    '
}

test_uninstall_cleanup() {
    docker run --rm labrat-test bash -c '
        ./install.sh -m bat -y
        ./install.sh --uninstall bat
        
        # Verify removed
        ! command -v bat || exit 1
        [[ ! -f ~/.local/share/labrat/installed/bat ]] || exit 1
    '
}
```

### Phase 4: Idempotency Tests (Priority: HIGH)

```bash
# tests/integration/test_idempotency.sh

test_double_install() {
    docker run --rm labrat-test bash -c '
        ./install.sh -m tmux,fzf -y
        ./install.sh -m tmux,fzf -y  # Second time
        
        # Should not error, should not duplicate config
        grep -c "LABRAT" ~/.bashrc | grep -E "^[01]$" || exit 1
    '
}
```

### Phase 5: Failure/Edge Case Tests (Priority: MEDIUM)

```bash
# tests/integration/test_failures.sh

test_offline_install() {
    # Block network, verify graceful failure
}

test_partial_install_recovery() {
    # Kill install mid-way, verify recovery
}

test_corrupted_marker() {
    # Corrupt installed marker, verify handling
}
```

---

## CI/CD Pipeline Improvements

### Current Pipeline Issues

1. **No test stages** - All tests run in parallel, no dependencies
2. **No artifact collection** - Test logs lost on failure
3. **No performance tracking** - No install time monitoring
4. **No coverage reporting** - Don't know what's untested

### Proposed Pipeline Structure

```yaml
jobs:
  # Stage 1: Quick checks (< 1 min)
  lint-and-syntax:
    - shellcheck
    - yaml validation
    
  # Stage 2: Unit tests (< 2 min)  
  unit-tests:
    needs: lint-and-syntax
    - test_constants
    - test_errors
    - test_file_ops
    
  # Stage 3: Integration tests per distro (< 10 min)
  integration:
    needs: unit-tests
    matrix: [ubuntu, debian, fedora, centos, alpine]
    - module install tests
    - configuration tests
    - theme tests
    
  # Stage 4: E2E tests (< 15 min)
  e2e:
    needs: integration
    - bootstrap workflow
    - shell integration
    - tmux sessions
    - multi-tool workflows
    
  # Stage 5: Performance (optional)
  performance:
    needs: e2e
    - install time benchmarks
    - binary size tracking
```

---

## Recommended Action Items

### Immediate (This Sprint)

1. [ ] Add shell integration test - verify `source ~/.bashrc` works
2. [ ] Add tmux session test - verify config loads without errors
3. [ ] Add idempotency test - run install twice
4. [ ] Collect test artifacts on failure

### Short Term (Next 2 Sprints)

5. [ ] Add fzf keybinding tests
6. [ ] Add end-to-end bootstrap test
7. [ ] Add update workflow test
8. [ ] Add arm64 CI runner

### Medium Term (Quarter)

9. [ ] Add neovim plugin load test
10. [ ] Add zsh integration tests
11. [ ] Add network failure simulation
12. [ ] Add performance benchmarking

---

## Metrics to Track

| Metric | Target | Current |
|--------|--------|---------|
| Test coverage (features) | 80% | ~40% |
| Real-world scenario tests | 20+ | 3 |
| Distros tested | 6+ | 4 |
| Architectures tested | 3 | 1 |
| E2E workflows tested | 5+ | 0 |
| Mean install time | <60s | unknown |

---

## Conclusion

The current testing infrastructure provides **basic smoke testing** but does not adequately test the **real-world user experience**. A user following the README could still encounter:

- Broken shell integration after install
- tmux config errors
- Missing completions
- Theme rendering issues
- Update/reinstall problems

**Priority**: Implement shell integration and tmux session tests immediately, as these are the most common user-facing issues.
