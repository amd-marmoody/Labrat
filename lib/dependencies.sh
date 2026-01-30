#!/usr/bin/env bash
#
# LabRat - Module Dependency Resolution System
# Handles module dependencies, ordering, and conflict detection
#

# ============================================================================
# Module Dependency Definitions
# ============================================================================

# Declare module dependencies
# Format: MODULE="dependency1 dependency2 ..."
declare -A MODULE_DEPENDENCIES=(
    # Shell modules may depend on starship for prompt
    ["zsh"]=""
    ["starship"]=""
    
    # Editors
    ["neovim"]=""
    ["vim"]=""
    
    # Utils - some have optional dependencies
    ["fzf"]=""  # Core fuzzy finder
    ["bat"]=""  # Standalone
    ["ripgrep"]=""  # Standalone
    ["fd"]=""  # Standalone
    ["eza"]=""  # Standalone (modern ls)
    ["zoxide"]=""  # Standalone (smart cd)
    ["lazygit"]=""  # Standalone
    ["htop"]=""  # Standalone
    ["btop"]=""  # Standalone
    ["fastfetch"]=""  # Standalone
    ["duf"]=""  # Standalone
    ["ncdu"]=""  # Standalone
    
    # Productivity - some integrate with other tools
    ["atuin"]=""  # Shell history
    ["broot"]=""  # File navigator
    ["direnv"]=""  # Per-directory env
    ["just"]=""  # Task runner
    ["mise"]=""  # Runtime manager
    ["thefuck"]=""  # Command correction
    ["tldr"]=""  # Man pages
    
    # Monitoring
    ["glances"]=""
    ["bandwhich"]=""
    ["nethogs"]=""
    ["iotop"]=""
    ["procs"]=""
    
    # Network
    ["mtr"]=""
    ["gping"]=""
    ["dog"]=""
    ["nmap"]=""
    ["trippy"]=""
    
    # Fonts - needed by some tools for icons
    ["nerdfonts"]=""
    
    # Terminal
    ["tmux"]=""
    
    # Security
    ["ssh-keys"]=""
)

# Soft dependencies (optional, installed if main tool is available)
declare -A MODULE_SOFT_DEPENDENCIES=(
    ["fzf"]="fd bat"  # fzf can use fd for file finding and bat for preview
    ["eza"]="nerdfonts"  # eza looks better with icons
    ["starship"]="nerdfonts"  # starship uses icons
    ["lazygit"]="nerdfonts"  # Better with icons
    ["neovim"]="nerdfonts ripgrep fd fzf"  # neovim plugins often use these
)

# Conflicts - modules that should not be installed together
declare -A MODULE_CONFLICTS=(
    # Example: ["tool1"]="tool2"  # tool1 conflicts with tool2
)

# ============================================================================
# Dependency Resolution Functions
# ============================================================================

# Get direct dependencies of a module
get_module_dependencies() {
    local module="$1"
    echo "${MODULE_DEPENDENCIES[$module]:-}"
}

# Get soft dependencies of a module
get_module_soft_dependencies() {
    local module="$1"
    echo "${MODULE_SOFT_DEPENDENCIES[$module]:-}"
}

# Check if module has unmet dependencies
check_module_dependencies() {
    local module="$1"
    local deps="${MODULE_DEPENDENCIES[$module]:-}"
    local unmet=()
    
    for dep in $deps; do
        if ! is_module_installed "$dep"; then
            unmet+=("$dep")
        fi
    done
    
    if [[ ${#unmet[@]} -gt 0 ]]; then
        echo "${unmet[*]}"
        return 1
    fi
    
    return 0
}

# Resolve full dependency tree for a module (includes transitive deps)
resolve_dependencies() {
    local module="$1"
    local resolved=()
    local seen=()
    
    _resolve_deps_recursive "$module" resolved seen
    
    # Return in installation order (dependencies first)
    echo "${resolved[*]}"
}

# Recursive helper for dependency resolution
_resolve_deps_recursive() {
    local module="$1"
    local -n _resolved=$2
    local -n _seen=$3
    
    # Check for circular dependencies
    if [[ " ${_seen[*]} " =~ " ${module} " ]]; then
        return 0  # Already being processed
    fi
    
    _seen+=("$module")
    
    # Get dependencies
    local deps="${MODULE_DEPENDENCIES[$module]:-}"
    
    # Resolve each dependency first
    for dep in $deps; do
        if [[ ! " ${_resolved[*]} " =~ " ${dep} " ]]; then
            _resolve_deps_recursive "$dep" _resolved _seen
        fi
    done
    
    # Add this module after its dependencies
    if [[ ! " ${_resolved[*]} " =~ " ${module} " ]]; then
        _resolved+=("$module")
    fi
}

# Get installation order for multiple modules
get_install_order() {
    local modules=("$@")
    local all_resolved=()
    local seen=()
    
    for module in "${modules[@]}"; do
        _resolve_deps_recursive "$module" all_resolved seen
    done
    
    # Remove duplicates while preserving order
    local unique=()
    for m in "${all_resolved[@]}"; do
        if [[ ! " ${unique[*]} " =~ " ${m} " ]]; then
            unique+=("$m")
        fi
    done
    
    echo "${unique[*]}"
}

# ============================================================================
# Conflict Detection
# ============================================================================

# Check if module conflicts with any installed modules
check_module_conflicts() {
    local module="$1"
    local conflicts="${MODULE_CONFLICTS[$module]:-}"
    local found_conflicts=()
    
    for conflict in $conflicts; do
        if is_module_installed "$conflict"; then
            found_conflicts+=("$conflict")
        fi
    done
    
    if [[ ${#found_conflicts[@]} -gt 0 ]]; then
        echo "${found_conflicts[*]}"
        return 1
    fi
    
    return 0
}

# Check for conflicts in a list of modules to install
check_all_conflicts() {
    local modules=("$@")
    local conflicts_found=()
    
    for module in "${modules[@]}"; do
        local conflicts="${MODULE_CONFLICTS[$module]:-}"
        for conflict in $conflicts; do
            if [[ " ${modules[*]} " =~ " ${conflict} " ]]; then
                conflicts_found+=("$module conflicts with $conflict")
            fi
        done
    done
    
    if [[ ${#conflicts_found[@]} -gt 0 ]]; then
        for c in "${conflicts_found[@]}"; do
            log_error "$c"
        done
        return 1
    fi
    
    return 0
}

# ============================================================================
# Soft Dependency Handling
# ============================================================================

# Suggest soft dependencies that would enhance a module
suggest_soft_dependencies() {
    local module="$1"
    local soft_deps="${MODULE_SOFT_DEPENDENCIES[$module]:-}"
    local suggestions=()
    
    for dep in $soft_deps; do
        if ! is_module_installed "$dep" && ! command_exists "$dep"; then
            suggestions+=("$dep")
        fi
    done
    
    if [[ ${#suggestions[@]} -gt 0 ]]; then
        echo "${suggestions[*]}"
    fi
}

# Print soft dependency suggestions for user
show_soft_dependency_suggestions() {
    local module="$1"
    local suggestions=$(suggest_soft_dependencies "$module")
    
    if [[ -n "$suggestions" ]]; then
        log_info "Optional: $module works better with: $suggestions"
    fi
}

# ============================================================================
# Module Information
# ============================================================================

# Show full module information including dependencies
show_module_info() {
    local module="$1"
    
    echo ""
    echo -e "${BOLD}Module: ${CYAN}$module${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..40})${NC}"
    
    # Description
    local desc="${MODULE_DESCRIPTIONS[$module]:-No description}"
    echo -e "Description: $desc"
    
    # Installation status
    if is_module_installed "$module"; then
        local version=$(get_installed_version "$module")
        echo -e "Status: ${GREEN}Installed${NC} (v$version)"
    else
        echo -e "Status: ${DIM}Not installed${NC}"
    fi
    
    # Dependencies
    local deps="${MODULE_DEPENDENCIES[$module]:-}"
    if [[ -n "$deps" ]]; then
        echo -e "Dependencies: $deps"
    fi
    
    # Soft dependencies
    local soft_deps="${MODULE_SOFT_DEPENDENCIES[$module]:-}"
    if [[ -n "$soft_deps" ]]; then
        echo -e "Optional: $soft_deps"
    fi
    
    # Conflicts
    local conflicts="${MODULE_CONFLICTS[$module]:-}"
    if [[ -n "$conflicts" ]]; then
        echo -e "Conflicts: $conflicts"
    fi
    
    echo ""
}

# Show dependency tree for a module
show_dependency_tree() {
    local module="$1"
    local indent="${2:-0}"
    local prefix=""
    
    for ((i=0; i<indent; i++)); do
        prefix+="  "
    done
    
    local status=""
    if is_module_installed "$module"; then
        status="${GREEN}✓${NC}"
    else
        status="${DIM}○${NC}"
    fi
    
    echo -e "${prefix}${status} $module"
    
    local deps="${MODULE_DEPENDENCIES[$module]:-}"
    for dep in $deps; do
        show_dependency_tree "$dep" $((indent + 1))
    done
}

# ============================================================================
# Pre-installation Validation
# ============================================================================

# Validate modules can be installed (check deps, conflicts)
validate_installation() {
    local modules=("$@")
    local errors=0
    
    log_step "Validating module installation..."
    
    # Check for conflicts between selected modules
    if ! check_all_conflicts "${modules[@]}"; then
        ((errors++))
    fi
    
    # For each module, check if dependencies are met or will be met
    local install_set=" ${modules[*]} "
    for module in "${modules[@]}"; do
        local deps="${MODULE_DEPENDENCIES[$module]:-}"
        for dep in $deps; do
            if ! is_module_installed "$dep" && [[ ! "$install_set" =~ " ${dep} " ]]; then
                log_error "$module requires $dep (not installed and not in install list)"
                ((errors++))
            fi
        done
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "All modules validated"
        return 0
    else
        log_error "Validation failed with $errors error(s)"
        return 1
    fi
}

# Auto-add missing dependencies to module list
auto_add_dependencies() {
    local modules=("$@")
    local result=()
    
    # Get install order (includes all dependencies)
    local ordered=$(get_install_order "${modules[@]}")
    
    # Return the full list including auto-added deps
    echo "$ordered"
}

# ============================================================================
# Uninstallation Helpers
# ============================================================================

# Check if module is required by other installed modules
is_module_required() {
    local module="$1"
    local dependents=()
    
    local installed_dir="${LABRAT_DATA_DIR}/installed"
    if [[ ! -d "$installed_dir" ]]; then
        return 1
    fi
    
    # Check all installed modules to see if they depend on this one
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local installed_module=$(basename "$marker")
            local deps="${MODULE_DEPENDENCIES[$installed_module]:-}"
            if [[ " $deps " =~ " $module " ]]; then
                dependents+=("$installed_module")
            fi
        fi
    done
    
    if [[ ${#dependents[@]} -gt 0 ]]; then
        echo "${dependents[*]}"
        return 0
    fi
    
    return 1
}

# Get safe uninstall order (reverse dependency order)
get_uninstall_order() {
    local modules=("$@")
    local install_order=$(get_install_order "${modules[@]}")
    
    # Reverse the order
    local reversed=()
    for m in $install_order; do
        reversed=("$m" "${reversed[@]}")
    done
    
    echo "${reversed[*]}"
}

# Warn about modules that depend on one being uninstalled
warn_dependents() {
    local module="$1"
    local dependents=$(is_module_required "$module")
    
    if [[ -n "$dependents" ]]; then
        log_warn "$module is required by: $dependents"
        log_warn "Uninstalling may break these modules"
        return 0
    fi
    
    return 1
}
