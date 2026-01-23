#!/usr/bin/env bash
#
# LabRat Module: nerdfonts
# Install Nerd Fonts for icons and symbols
#

# Module metadata
NERDFONTS_VERSION="v3.1.1"
NERDFONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/download"

# Available fonts
NERDFONTS_OPTIONS=(
    "JetBrainsMono"
    "FiraCode"
    "Hack"
    "CascadiaCode"
    "UbuntuMono"
    "SourceCodePro"
)

# ============================================================================
# Installation
# ============================================================================

install_nerdfonts() {
    log_step "Installing Nerd Fonts..."
    
    local font_name="${LABRAT_NERD_FONT:-JetBrainsMono}"
    
    # Interactive font selection
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]] && [[ -t 0 ]]; then
        font_name=$(select_nerd_font)
    fi
    
    # Install the font
    install_font "$font_name"
    
    # Update font cache
    update_font_cache
    
    # Mark as installed
    mark_module_installed "nerdfonts" "$font_name"
    
    log_success "Nerd Font installed: $font_name"
    log_info "You may need to configure your terminal to use the new font"
}

# ============================================================================
# Font Selection
# ============================================================================

select_nerd_font() {
    # Print menu to stderr so it doesn't get captured
    echo "" >&2
    echo -e "${BOLD}Available Nerd Fonts:${NC}" >&2
    echo "" >&2
    
    local i=1
    for font in "${NERDFONTS_OPTIONS[@]}"; do
        echo "  $i) $font" >&2
        ((i++)) || true
    done
    echo "" >&2
    
    read -p "Select font [1-${#NERDFONTS_OPTIONS[@]}] (default: 1 - JetBrainsMono): " choice
    
    if [[ -n "$choice" ]] && [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#NERDFONTS_OPTIONS[@]} )); then
        echo "${NERDFONTS_OPTIONS[$((choice-1))]}"
    else
        echo "JetBrainsMono"
    fi
}

# ============================================================================
# Font Installation
# ============================================================================

install_font() {
    local font_name="$1"
    local fonts_dir="$HOME/.local/share/fonts/NerdFonts"
    local download_url="${NERDFONTS_BASE_URL}/${NERDFONTS_VERSION}/${font_name}.zip"
    local temp_dir="${LABRAT_CACHE_DIR}/fonts"
    local zip_file="${temp_dir}/${font_name}.zip"
    
    log_step "Downloading $font_name Nerd Font..."
    
    # Create directories
    ensure_dir "$fonts_dir"
    ensure_dir "$temp_dir"
    
    # Download font archive
    if ! download_file "$download_url" "$zip_file" "Downloading $font_name"; then
        log_error "Failed to download $font_name"
        return 1
    fi
    
    log_step "Extracting font files..."
    
    # Extract to fonts directory
    if command_exists unzip; then
        unzip -o -q "$zip_file" -d "$fonts_dir" '*.ttf' '*.otf' 2>/dev/null || true
    else
        log_error "unzip not found. Installing..."
        pkg_install unzip
        unzip -o -q "$zip_file" -d "$fonts_dir" '*.ttf' '*.otf' 2>/dev/null || true
    fi
    
    # Cleanup
    rm -f "$zip_file"
    
    log_success "Font files installed to $fonts_dir"
}

# ============================================================================
# Font Cache
# ============================================================================

update_font_cache() {
    log_step "Updating font cache..."
    
    if command_exists fc-cache; then
        fc-cache -f -v "$HOME/.local/share/fonts" 2>/dev/null || true
        log_success "Font cache updated"
    else
        log_warn "fc-cache not found, font cache not updated"
        log_info "Install fontconfig package to enable font cache"
    fi
}

# ============================================================================
# List Installed Fonts
# ============================================================================

list_installed_nerdfonts() {
    local fonts_dir="$HOME/.local/share/fonts/NerdFonts"
    
    if [[ -d "$fonts_dir" ]]; then
        echo -e "${BOLD}Installed Nerd Fonts:${NC}"
        ls -1 "$fonts_dir" | grep -E '\.(ttf|otf)$' | sed 's/\.[^.]*$//' | sort -u
    else
        echo "No Nerd Fonts installed"
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_nerdfonts() {
    log_step "Uninstalling Nerd Fonts..."
    
    local fonts_dir="$HOME/.local/share/fonts/NerdFonts"
    
    if [[ -d "$fonts_dir" ]]; then
        rm -rf "$fonts_dir"
        update_font_cache
        log_success "Nerd Fonts removed"
    else
        log_info "No Nerd Fonts directory found"
    fi
    
    rm -f "${LABRAT_DATA_DIR}/installed/nerdfonts"
}
