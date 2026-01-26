#!/usr/bin/env bash
#
# LabRat - Manifest System
# Tracks installed modules, versions, and configurations
#
# The manifest provides:
# - Centralized tracking of all installed modules
# - Version information for update checks
# - Shell integration tracking for clean uninstall
# - Installation metadata (dates, files created)
#

# shellcheck source=./common.sh
source "${LABRAT_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/common.sh"

# ============================================================================
# Manifest Configuration
# ============================================================================

LABRAT_MANIFEST_FILE="${LABRAT_DATA_DIR}/manifest.json"
LABRAT_MANIFEST_VERSION="1.0"

# ============================================================================
# JSON Helpers (minimal, no jq dependency)
# ============================================================================

# Simple JSON value extractor (for basic key-value pairs)
# Usage: json_get_value "$json_string" "key"
json_get_value() {
    local json="$1"
    local key="$2"
    
    # Use grep and sed for basic extraction
    echo "$json" | grep -o "\"${key}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)"/\1/' | head -1
}

# Check if jq is available for advanced operations
has_jq() {
    command -v jq &>/dev/null
}

# ============================================================================
# Manifest Initialization
# ============================================================================

# Initialize or load the manifest file
init_manifest() {
    ensure_dir "$(dirname "$LABRAT_MANIFEST_FILE")"
    
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        create_empty_manifest
    fi
}

# Create a new empty manifest
create_empty_manifest() {
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    
    cat > "$LABRAT_MANIFEST_FILE" << EOF
{
  "version": "${LABRAT_MANIFEST_VERSION}",
  "created_at": "${timestamp}",
  "updated_at": "${timestamp}",
  "labrat_version": "dev",
  "modules": {},
  "shell_integration": {
    "hooks_installed": [],
    "original_backups": false
  }
}
EOF
    
    log_debug "Created new manifest: $LABRAT_MANIFEST_FILE"
}

# ============================================================================
# Module Tracking
# ============================================================================

# Add or update a module in the manifest
# Usage: manifest_add_module "module_name" "version" [shell_integration:true/false]
manifest_add_module() {
    local module_name="$1"
    local version="${2:-unknown}"
    local has_shell="${3:-false}"
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    
    init_manifest
    
    if has_jq; then
        # Use jq for proper JSON manipulation
        local tmp_file=$(mktemp)
        jq --arg name "$module_name" \
           --arg ver "$version" \
           --arg ts "$timestamp" \
           --arg shell "$has_shell" \
           '.modules[$name] = {
               "version": $ver,
               "installed_at": $ts,
               "updated_at": $ts,
               "shell_integration": ($shell == "true")
           } | .updated_at = $ts' \
           "$LABRAT_MANIFEST_FILE" > "$tmp_file" && mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    else
        # Fallback: simple text-based tracking
        _manifest_add_module_simple "$module_name" "$version" "$has_shell" "$timestamp"
    fi
    
    log_debug "Manifest: added module $module_name (v$version)"
}

# Simple fallback for manifest_add_module when jq is not available
_manifest_add_module_simple() {
    local module_name="$1"
    local version="$2"
    local has_shell="$3"
    local timestamp="$4"
    
    # Read current manifest
    local manifest=$(cat "$LABRAT_MANIFEST_FILE")
    
    # Check if module already exists
    if echo "$manifest" | grep -q "\"$module_name\":"; then
        # Update existing - simple sed replacement of the module block
        # This is a simplified approach
        local tmp_file=$(mktemp)
        
        # For now, just update the updated_at timestamp
        sed "s/\"updated_at\": *\"[^\"]*\"/\"updated_at\": \"$timestamp\"/" "$LABRAT_MANIFEST_FILE" > "$tmp_file"
        mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    else
        # Add new module - insert before closing brace of modules object
        local module_entry="    \"$module_name\": {
      \"version\": \"$version\",
      \"installed_at\": \"$timestamp\",
      \"updated_at\": \"$timestamp\",
      \"shell_integration\": $has_shell
    }"
        
        local tmp_file=$(mktemp)
        
        # Check if modules object is empty
        if grep -q '"modules": {}' "$LABRAT_MANIFEST_FILE"; then
            # Replace empty modules with new entry
            sed "s/\"modules\": {}/\"modules\": {\n$module_entry\n  }/" "$LABRAT_MANIFEST_FILE" > "$tmp_file"
        else
            # Add to existing modules (insert before last } in modules block)
            # This is tricky without jq, so we use awk
            awk -v entry="$module_entry" '
                /"modules": \{/ { in_modules=1 }
                in_modules && /^  \}/ && !done { print ",\n" entry; done=1 }
                { print }
            ' "$LABRAT_MANIFEST_FILE" > "$tmp_file"
        fi
        
        mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    fi
}

# Remove a module from the manifest
manifest_remove_module() {
    local module_name="$1"
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        return 0
    fi
    
    if has_jq; then
        local tmp_file=$(mktemp)
        jq --arg name "$module_name" \
           --arg ts "$timestamp" \
           'del(.modules[$name]) | .updated_at = $ts' \
           "$LABRAT_MANIFEST_FILE" > "$tmp_file" && mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    else
        # Fallback: mark as removed in a simple way
        # Without jq, full removal is complex; we'll just note it
        log_debug "Module $module_name removal noted (full cleanup requires jq)"
    fi
    
    log_debug "Manifest: removed module $module_name"
}

# Check if a module is in the manifest
manifest_has_module() {
    local module_name="$1"
    
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        return 1
    fi
    
    if has_jq; then
        jq -e --arg name "$module_name" '.modules[$name] != null' "$LABRAT_MANIFEST_FILE" &>/dev/null
    else
        grep -q "\"$module_name\":" "$LABRAT_MANIFEST_FILE"
    fi
}

# Get module version from manifest
manifest_get_module_version() {
    local module_name="$1"
    
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        echo ""
        return 1
    fi
    
    if has_jq; then
        jq -r --arg name "$module_name" '.modules[$name].version // empty' "$LABRAT_MANIFEST_FILE"
    else
        # Simple grep extraction
        local section=$(grep -A5 "\"$module_name\":" "$LABRAT_MANIFEST_FILE" 2>/dev/null)
        echo "$section" | grep -o '"version": *"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/' | head -1
    fi
}

# List all modules in manifest
manifest_list_modules() {
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        return 0
    fi
    
    if has_jq; then
        jq -r '.modules | keys[]' "$LABRAT_MANIFEST_FILE" 2>/dev/null
    else
        # Simple grep for module names
        grep -oP '"[a-zA-Z0-9_-]+":.*"version"' "$LABRAT_MANIFEST_FILE" | \
            sed 's/"\([^"]*\)".*/\1/' | sort -u
    fi
}

# ============================================================================
# Shell Integration Tracking
# ============================================================================

# Record that shell hooks have been installed
manifest_set_hooks_installed() {
    local shells=("$@")
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    
    init_manifest
    
    if has_jq; then
        local shells_json=$(printf '%s\n' "${shells[@]}" | jq -R . | jq -s .)
        local tmp_file=$(mktemp)
        jq --argjson shells "$shells_json" \
           --arg ts "$timestamp" \
           '.shell_integration.hooks_installed = $shells | .updated_at = $ts' \
           "$LABRAT_MANIFEST_FILE" > "$tmp_file" && mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    fi
}

# Record that original configs have been backed up
manifest_set_backups_done() {
    local timestamp=$(date -Iseconds 2>/dev/null || date +%Y-%m-%dT%H:%M:%S%z)
    
    init_manifest
    
    if has_jq; then
        local tmp_file=$(mktemp)
        jq --arg ts "$timestamp" \
           '.shell_integration.original_backups = true | 
            .shell_integration.backup_date = $ts |
            .updated_at = $ts' \
           "$LABRAT_MANIFEST_FILE" > "$tmp_file" && mv "$tmp_file" "$LABRAT_MANIFEST_FILE"
    fi
}

# ============================================================================
# Manifest Display
# ============================================================================

# Show manifest summary
manifest_show() {
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        log_info "No manifest found - LabRat not installed or using legacy system"
        return 0
    fi
    
    echo ""
    echo -e "${BOLD}LabRat Installation Manifest${NC}"
    echo -e "${DIM}$(printf '%.0s─' {1..50})${NC}"
    echo ""
    
    if has_jq; then
        local version=$(jq -r '.version' "$LABRAT_MANIFEST_FILE")
        local created=$(jq -r '.created_at' "$LABRAT_MANIFEST_FILE")
        local updated=$(jq -r '.updated_at' "$LABRAT_MANIFEST_FILE")
        local module_count=$(jq '.modules | length' "$LABRAT_MANIFEST_FILE")
        
        echo -e "Manifest version: ${CYAN}$version${NC}"
        echo -e "Created: ${DIM}$created${NC}"
        echo -e "Last updated: ${DIM}$updated${NC}"
        echo ""
        echo -e "Installed modules: ${BOLD}$module_count${NC}"
        echo ""
        
        if [[ "$module_count" -gt 0 ]]; then
            echo -e "${BOLD}Modules:${NC}"
            jq -r '.modules | to_entries[] | "  \(.key): v\(.value.version)"' "$LABRAT_MANIFEST_FILE"
        fi
        
        echo ""
        
        # Shell integration status
        local hooks=$(jq -r '.shell_integration.hooks_installed | join(", ")' "$LABRAT_MANIFEST_FILE" 2>/dev/null)
        local backups=$(jq -r '.shell_integration.original_backups' "$LABRAT_MANIFEST_FILE" 2>/dev/null)
        
        echo -e "${BOLD}Shell Integration:${NC}"
        echo -e "  Hooks installed: ${hooks:-none}"
        echo -e "  Original backups: ${backups:-false}"
    else
        echo -e "${YELLOW}Note: Install 'jq' for detailed manifest display${NC}"
        echo ""
        echo "Manifest file: $LABRAT_MANIFEST_FILE"
        echo ""
        echo "Installed modules:"
        manifest_list_modules | while read -r module; do
            local version=$(manifest_get_module_version "$module")
            echo "  $module: v$version"
        done
    fi
    
    echo ""
}

# Export manifest as JSON (for backup/transfer)
manifest_export() {
    if [[ -f "$LABRAT_MANIFEST_FILE" ]]; then
        cat "$LABRAT_MANIFEST_FILE"
    else
        echo "{}"
    fi
}

# ============================================================================
# Manifest Cleanup
# ============================================================================

# Clear the manifest (for full uninstall)
manifest_clear() {
    rm -f "$LABRAT_MANIFEST_FILE"
    log_debug "Manifest cleared"
}

# Verify manifest integrity
manifest_verify() {
    if [[ ! -f "$LABRAT_MANIFEST_FILE" ]]; then
        log_warn "Manifest file not found"
        return 1
    fi
    
    if has_jq; then
        if jq empty "$LABRAT_MANIFEST_FILE" 2>/dev/null; then
            log_debug "Manifest JSON is valid"
            return 0
        else
            log_error "Manifest JSON is invalid"
            return 1
        fi
    else
        # Basic check - file exists and has content
        if [[ -s "$LABRAT_MANIFEST_FILE" ]]; then
            return 0
        else
            return 1
        fi
    fi
}

# ============================================================================
# Integration with Module System
# ============================================================================

# Enhanced mark_module_installed that also updates manifest
# This wraps the original function from common.sh
_original_mark_module_installed=$(declare -f mark_module_installed)

mark_module_installed() {
    local module="$1"
    local version="${2:-unknown}"
    local marker_dir="${LABRAT_DATA_DIR}/installed"
    
    # Original behavior: create marker file
    ensure_dir "$marker_dir"
    echo "$version" > "${marker_dir}/${module}"
    log_debug "Marked $module as installed (version: $version)"
    
    # New behavior: also update manifest
    local has_shell="false"
    if is_shell_module_registered "$module" 2>/dev/null; then
        has_shell="true"
    fi
    manifest_add_module "$module" "$version" "$has_shell"
}

# Enhanced unmark function
unmark_module_installed() {
    local module="$1"
    local marker_file="${LABRAT_DATA_DIR}/installed/${module}"
    
    # Remove marker file
    rm -f "$marker_file"
    
    # Update manifest
    manifest_remove_module "$module"
    
    log_debug "Unmarked $module as installed"
}
