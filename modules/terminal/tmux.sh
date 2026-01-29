#!/usr/bin/env bash
#
# LabRat Module: tmux
# Terminal multiplexer with TPM, themes, and productivity features
#

# Module metadata
TMUX_VERSION_MIN="3.3"
TMUX_VERSION_LATEST="3.5a"
TMUX_TPM_REPO="https://github.com/tmux-plugins/tpm"
TMUX_RELEASES_URL="https://github.com/tmux/tmux/releases/download"

# Available themes with their TPM plugin repos
declare -A TMUX_THEME_PLUGINS=(
    # Catppuccin flavors
    ["catppuccin-mocha"]="catppuccin/tmux"
    ["catppuccin-latte"]="catppuccin/tmux"
    ["catppuccin-frappe"]="catppuccin/tmux"
    ["catppuccin-macchiato"]="catppuccin/tmux"
    # Tokyo Night
    ["tokyo-night"]="janoamaral/tokyo-night-tmux"
    # Dracula
    ["dracula"]="dracula/tmux"
    # Nord
    ["nord"]="nordtheme/tmux"
    # Gruvbox
    ["gruvbox-dark"]="egel/tmux-gruvbox"
    ["gruvbox-light"]="egel/tmux-gruvbox"
    # Rose Pine (new)
    ["rose-pine"]="rose-pine/tmux"
    ["rose-pine-moon"]="rose-pine/tmux"
    ["rose-pine-dawn"]="rose-pine/tmux"
    # tmux-power (new)
    ["power-gold"]="wfxr/tmux-power"
    ["power-everforest"]="wfxr/tmux-power"
    ["power-moon"]="wfxr/tmux-power"
    ["power-coral"]="wfxr/tmux-power"
    ["power-snow"]="wfxr/tmux-power"
    ["power-forest"]="wfxr/tmux-power"
    ["power-violet"]="wfxr/tmux-power"
    ["power-redwine"]="wfxr/tmux-power"
    # Kanagawa (new)
    ["kanagawa-wave"]="Nybkox/tmux-kanagawa"
    ["kanagawa-dragon"]="Nybkox/tmux-kanagawa"
    ["kanagawa-lotus"]="Nybkox/tmux-kanagawa"
    # Solarized (new)
    ["solarized-dark"]="seebi/tmux-colors-solarized"
    ["solarized-light"]="seebi/tmux-colors-solarized"
    ["solarized-256"]="seebi/tmux-colors-solarized"
    # OneDark (new)
    ["onedark"]="odedlaz/tmux-onedark-theme"
    # Minimal (new)
    ["minimal"]="niksingh710/minimal-tmux-status"
)

# Theme descriptions for menu
declare -A TMUX_THEME_DESCRIPTIONS=(
    # Catppuccin
    ["catppuccin-mocha"]="Dark warm theme (default)"
    ["catppuccin-latte"]="Light theme"
    ["catppuccin-frappe"]="Dark muted theme"
    ["catppuccin-macchiato"]="Dark blue theme"
    # Tokyo Night
    ["tokyo-night"]="VS Code inspired dark theme"
    # Dracula
    ["dracula"]="Purple/pink dark theme"
    # Nord
    ["nord"]="Arctic blue-grey theme"
    # Gruvbox
    ["gruvbox-dark"]="Retro warm dark theme"
    ["gruvbox-light"]="Retro warm light theme"
    # Rose Pine
    ["rose-pine"]="Soho vibes dark theme"
    ["rose-pine-moon"]="Soho vibes muted dark"
    ["rose-pine-dawn"]="Soho vibes light theme"
    # tmux-power
    ["power-gold"]="Powerline gold theme"
    ["power-everforest"]="Powerline everforest"
    ["power-moon"]="Powerline moon theme"
    ["power-coral"]="Powerline coral theme"
    ["power-snow"]="Powerline snow (light)"
    ["power-forest"]="Powerline forest theme"
    ["power-violet"]="Powerline violet theme"
    ["power-redwine"]="Powerline redwine theme"
    # Kanagawa
    ["kanagawa-wave"]="Japanese art inspired (wave)"
    ["kanagawa-dragon"]="Japanese art inspired (dragon)"
    ["kanagawa-lotus"]="Japanese art inspired (lotus)"
    # Solarized
    ["solarized-dark"]="Classic Solarized dark"
    ["solarized-light"]="Classic Solarized light"
    ["solarized-256"]="Solarized 256 colors"
    # OneDark
    ["onedark"]="Atom One Dark theme"
    # Minimal
    ["minimal"]="Minimal with prefix indicator"
)

SELECTED_TMUX_THEME="catppuccin-mocha"

# Theme-specific dependencies (packages from package manager)
declare -A TMUX_THEME_DEPS=(
    ["tokyo-night"]="bc jq gawk sed git coreutils"
    ["dracula"]="bc git"
    ["kanagawa-wave"]="bc git"
    ["kanagawa-dragon"]="bc git"
    ["kanagawa-lotus"]="bc git"
    ["catppuccin-mocha"]=""
    ["catppuccin-latte"]=""
    ["catppuccin-frappe"]=""
    ["catppuccin-macchiato"]=""
    ["nord"]=""
    ["gruvbox-dark"]=""
    ["gruvbox-light"]=""
    ["rose-pine"]=""
    ["rose-pine-moon"]=""
    ["rose-pine-dawn"]=""
    ["power-gold"]=""
    ["power-everforest"]=""
    ["power-moon"]=""
    ["power-coral"]=""
    ["power-snow"]=""
    ["power-forest"]=""
    ["power-violet"]=""
    ["power-redwine"]=""
    ["solarized-dark"]=""
    ["solarized-light"]=""
    ["solarized-256"]=""
    ["onedark"]=""
    ["minimal"]=""
)

# Themes that need additional fonts (Noto Sans Symbols 2)
TMUX_THEMES_NEED_SYMBOLS_FONT=(
    "tokyo-night"
)

# Themes that require Nerd Fonts for icons
TMUX_THEMES_REQUIRE_NERDFONTS=(
    "tokyo-night"
    "dracula"
    "catppuccin-mocha"
    "catppuccin-latte"
    "catppuccin-frappe"
    "catppuccin-macchiato"
    "nord"
    "gruvbox-dark"
    "gruvbox-light"
    "rose-pine"
    "rose-pine-moon"
    "rose-pine-dawn"
    "power-gold"
    "power-everforest"
    "power-moon"
    "power-coral"
    "power-snow"
    "power-forest"
    "power-violet"
    "power-redwine"
    "kanagawa-wave"
    "kanagawa-dragon"
    "kanagawa-lotus"
    "onedark"
    "minimal"
)

# ============================================================================
# Installation
# ============================================================================

# Install tmux build dependencies
install_tmux_build_deps() {
    log_step "Installing tmux build dependencies..."
    
    case "$OS_FAMILY" in
        debian)
            pkg_install libevent-dev libncurses-dev build-essential bison pkg-config
            ;;
        rhel)
            pkg_install libevent-devel ncurses-devel make gcc bison
            ;;
        arch)
            pkg_install base-devel libevent ncurses
            ;;
        alpine)
            pkg_install libevent-dev ncurses-dev build-base bison
            ;;
        *)
            log_warn "Unknown OS family, attempting common package names"
            pkg_install libevent-dev ncurses-dev build-essential bison
            ;;
    esac
}

# Build tmux from source
build_tmux_from_source() {
    local version="${1:-$TMUX_VERSION_LATEST}"
    local cache_dir="${LABRAT_CACHE_DIR:-$HOME/.cache/labrat}/tmux"
    local tarball="${cache_dir}/tmux-${version}.tar.gz"
    local src_dir="${cache_dir}/tmux-${version}"
    local install_prefix="/usr/local"
    
    log_step "Building tmux ${version} from source..."
    
    # Install build dependencies
    install_tmux_build_deps
    
    # Create cache directory
    mkdir -p "$cache_dir"
    
    # Download source tarball
    local download_url="${TMUX_RELEASES_URL}/${version}/tmux-${version}.tar.gz"
    log_info "Downloading tmux ${version}..."
    
    if ! curl -fsSL -o "$tarball" "$download_url" 2>/dev/null; then
        log_error "Failed to download tmux ${version} from ${download_url}"
        return 1
    fi
    
    # Extract tarball
    log_info "Extracting source..."
    rm -rf "$src_dir"
    tar xzf "$tarball" -C "$cache_dir"
    
    if [[ ! -d "$src_dir" ]]; then
        log_error "Failed to extract tmux source"
        return 1
    fi
    
    # Build and install
    log_info "Configuring..."
    (
        cd "$src_dir" || exit 1
        ./configure --prefix="$install_prefix" >/dev/null 2>&1 || {
            log_error "Configure failed"
            exit 1
        }
        
        log_info "Compiling (this may take a minute)..."
        make -j"$(nproc)" >/dev/null 2>&1 || {
            log_error "Make failed"
            exit 1
        }
        
        log_info "Installing to ${install_prefix}..."
        sudo make install >/dev/null 2>&1 || {
            log_error "Make install failed (may need sudo)"
            exit 1
        }
    ) || return 1
    
    # Verify installation
    local installed_path
    installed_path=$(command -v tmux)
    local installed_version
    installed_version=$(tmux -V 2>/dev/null | grep -oP '[\d.]+[a-z]?' | head -1)
    
    if [[ "$installed_version" == "$version" ]] || [[ "$installed_version" == "${version%a}" ]]; then
        log_success "tmux ${installed_version} installed to ${installed_path}"
    else
        log_warn "Version mismatch: expected ${version}, got ${installed_version}"
    fi
    
    # Cleanup
    rm -rf "$src_dir" "$tarball"
    
    return 0
}

# Check if installed tmux version meets minimum
check_tmux_version() {
    local min_version="${1:-$TMUX_VERSION_MIN}"
    
    if ! command_exists tmux; then
        return 1
    fi
    
    local current_version
    current_version=$(tmux -V 2>/dev/null | grep -oP '[\d.]+' | head -1)
    
    # Simple version comparison (works for major.minor format)
    local current_major current_minor min_major min_minor
    current_major="${current_version%%.*}"
    current_minor="${current_version#*.}"
    current_minor="${current_minor%%.*}"
    min_major="${min_version%%.*}"
    min_minor="${min_version#*.}"
    min_minor="${min_minor%%.*}"
    
    if (( current_major > min_major )); then
        return 0
    elif (( current_major == min_major && current_minor >= min_minor )); then
        return 0
    else
        return 1
    fi
}

install_tmux() {
    log_step "Installing tmux..."
    
    local needs_build=false
    local current_version=""
    
    # Check if tmux is installed and meets version requirement
    if command_exists tmux; then
        current_version=$(tmux -V 2>/dev/null | grep -oP '[\d.]+[a-z]?' | head -1)
        log_info "Found tmux ${current_version}"
        
        if check_tmux_version "$TMUX_VERSION_MIN"; then
            log_info "tmux ${current_version} meets minimum requirement (${TMUX_VERSION_MIN}+)"
        else
            log_warn "tmux ${current_version} is below minimum ${TMUX_VERSION_MIN}"
            log_info "Upgrading to tmux ${TMUX_VERSION_LATEST} for latest features (fzf --tmux, etc.)"
            needs_build=true
        fi
    else
        log_info "tmux not found, building from source..."
        needs_build=true
    fi
    
    # Build from source if needed
    if [[ "$needs_build" == "true" ]]; then
        if ! build_tmux_from_source "$TMUX_VERSION_LATEST"; then
            log_error "Failed to build tmux from source"
            log_info "Falling back to package manager..."
            case "$OS_FAMILY" in
                debian) pkg_install tmux ;;
                rhel) pkg_install tmux ;;
                *) pkg_install tmux ;;
            esac
        fi
    fi
    
    # Get installed version
    local installed_version
    installed_version=$(tmux -V 2>/dev/null | grep -oP '[\d.]+[a-z]?' | head -1)
    log_info "tmux version: $installed_version"
    
    # Install TPM (Tmux Plugin Manager)
    install_tpm
    
    # Select theme (interactive or use default)
    select_tmux_theme
    
    # Generate and deploy theme-specific configuration
    generate_and_deploy_tmux_config
    
    # Install tmux-theme script
    install_tmux_theme_script
    
    # Install Nerd Fonts for theme icons
    ensure_nerdfonts_installed
    
    # Install Noto Sans Symbols 2 if needed (for tokyo-night segmented digits)
    for theme_need_symbols in "${TMUX_THEMES_NEED_SYMBOLS_FONT[@]}"; do
        if [[ "$SELECTED_TMUX_THEME" == "$theme_need_symbols" ]]; then
            install_noto_symbols_font
            break
        fi
    done
    
    # Install theme-specific dependencies
    install_theme_dependencies "$SELECTED_TMUX_THEME"
    
    # Check optional tools
    install_optional_theme_tools "$SELECTED_TMUX_THEME"
    
    # Install TPM plugins including the theme
    install_tpm_plugins
    
    # Mark as installed
    mark_module_installed "tmux" "$installed_version"
    
    log_success "tmux installed and configured!"
    log_info "Theme: ${BOLD}$SELECTED_TMUX_THEME${NC}"
    log_info "Use ${BOLD}tmux-theme --list${NC} to see available themes"
    log_info "Use ${BOLD}tmux-theme <name>${NC} to switch themes"
}

# ============================================================================
# Theme Selection
# ============================================================================

select_tmux_theme() {
    log_step "Selecting tmux theme..."
    
    # Check command line option or environment variable
    if [[ -n "${LABRAT_TMUX_THEME:-}" ]]; then
        if is_valid_theme "$LABRAT_TMUX_THEME"; then
            SELECTED_TMUX_THEME="$LABRAT_TMUX_THEME"
            echo "$SELECTED_TMUX_THEME" > "$HOME/.tmux-theme"
            log_info "Using preset theme: $SELECTED_TMUX_THEME"
            return 0
        else
            log_warn "Invalid theme: $LABRAT_TMUX_THEME, using default"
        fi
    fi
    
    # Check existing preference
    if [[ -f "$HOME/.tmux-theme" ]]; then
        local existing_theme
        existing_theme=$(cat "$HOME/.tmux-theme")
        if is_valid_theme "$existing_theme"; then
            SELECTED_TMUX_THEME="$existing_theme"
            log_info "Using existing theme preference: $SELECTED_TMUX_THEME"
            return 0
        fi
    fi
    
    # Interactive selection if not in auto mode
    if [[ "${SKIP_CONFIRMATION:-false}" != "true" ]] && [[ -t 0 ]]; then
        echo ""
        echo -e "${BOLD}Available tmux themes (popular selection):${NC}"
        echo ""
        
        # Popular themes shown during install
        local themes=(
            "catppuccin-mocha"
            "catppuccin-latte"
            "tokyo-night"
            "dracula"
            "nord"
            "gruvbox-dark"
            "rose-pine"
            "kanagawa-wave"
            "power-gold"
            "onedark"
            "minimal"
        )
        local i=1
        for theme in "${themes[@]}"; do
            local desc="${TMUX_THEME_DESCRIPTIONS[$theme]:-}"
            printf "  %2d) %-22s %s\n" "$i" "$theme" "$desc"
            ((i++)) || true
        done
        echo ""
        echo -e "  ${DIM}(More themes available via: tmux-theme --list)${NC}"
        echo ""
        
        read -rp "Select theme [1-${#themes[@]}] (default: 1 - catppuccin-mocha): " choice
        
        if [[ -n "$choice" ]] && [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#themes[@]} )); then
            SELECTED_TMUX_THEME="${themes[$((choice-1))]}"
        else
            SELECTED_TMUX_THEME="catppuccin-mocha"
        fi
    fi
    
    echo "$SELECTED_TMUX_THEME" > "$HOME/.tmux-theme"
    log_info "Selected theme: $SELECTED_TMUX_THEME"
}

is_valid_theme() {
    local theme="$1"
    [[ -n "${TMUX_THEME_PLUGINS[$theme]:-}" ]]
}

# ============================================================================
# TPM Installation
# ============================================================================

install_tpm() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"
    
    log_step "Installing TPM (Tmux Plugin Manager)..."
    
    if [[ -d "$tpm_dir" ]]; then
        log_info "TPM already installed, updating..."
        (cd "$tpm_dir" && git pull --quiet) || true
    else
        git_clone_or_update "$TMUX_TPM_REPO" "$tpm_dir" "master"
    fi
    
    log_success "TPM installed at $tpm_dir"
}

install_tpm_plugins() {
    log_step "Installing TPM plugins (including theme)..."
    
    local tpm_install_script="$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"
    
    if [[ -x "$tpm_install_script" ]]; then
        # Run TPM install in background-friendly way
        "$tpm_install_script" 2>/dev/null || true
        log_success "TPM plugins installed"
    else
        log_warn "TPM install script not found - press Prefix + I in tmux to install plugins"
    fi
}

# ============================================================================
# Theme Dependencies
# ============================================================================

install_theme_dependencies() {
    local theme="$1"
    local deps="${TMUX_THEME_DEPS[$theme]:-}"
    
    if [[ -z "$deps" ]]; then
        log_verbose "No additional dependencies for $theme theme"
        return 0
    fi
    
    log_step "Installing dependencies for $theme theme..."
    
    # Install common dependencies
    for dep in $deps; do
        case "$dep" in
            bc)
                if ! command_exists bc; then
                    pkg_install bc
                fi
                ;;
            jq)
                if ! command_exists jq; then
                    pkg_install jq
                fi
                ;;
            gawk)
                if ! command_exists gawk; then
                    pkg_install gawk
                fi
                ;;
            playerctl)
                if ! command_exists playerctl; then
                    case "$OS_FAMILY" in
                        debian)
                            pkg_install playerctl
                            ;;
                        rhel)
                            # playerctl might not be in default repos
                            log_warn "playerctl not available in default repos - music widget may not work"
                            ;;
                        *)
                            pkg_install playerctl 2>/dev/null || log_warn "playerctl not available"
                            ;;
                    esac
                fi
                ;;
        esac
    done
    
    # Theme-specific additional setup
    case "$theme" in
        tokyo-night)
            log_info "Tokyo Night theme dependencies installed"
            log_info "For full features, ensure you have: Nerd Fonts v3+, bc, jq"
            log_info "Optional: gh (GitHub CLI) or glab (GitLab CLI) for git widgets"
            ;;
        dracula)
            log_info "Dracula theme dependencies installed"
            ;;
    esac
}

# ============================================================================
# Nerd Fonts Installation
# ============================================================================

ensure_nerdfonts_installed() {
    local fonts_dir="$HOME/.local/share/fonts/NerdFonts"
    
    # Check if Nerd Fonts are already installed
    if [[ -d "$fonts_dir" ]] && [[ -n "$(ls -A "$fonts_dir" 2>/dev/null)" ]]; then
        log_info "Nerd Fonts already installed"
        return 0
    fi
    
    log_step "Installing Nerd Fonts (required for theme icons)..."
    
    local font_name="JetBrainsMono"
    local version="v3.1.1"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${font_name}.zip"
    local cache_dir="${LABRAT_CACHE_DIR:-$HOME/.cache/labrat}/fonts"
    local zip_file="${cache_dir}/${font_name}.zip"
    
    # Create directories
    mkdir -p "$fonts_dir" "$cache_dir"
    
    # Download font
    log_info "Downloading ${font_name} Nerd Font..."
    if curl -fsSL -o "$zip_file" "$download_url" 2>/dev/null; then
        log_info "Extracting font files..."
        
        # Ensure unzip is available
        if ! command_exists unzip; then
            pkg_install unzip
        fi
        
        # Extract TTF files
        unzip -o -q "$zip_file" -d "$fonts_dir" '*.ttf' 2>/dev/null || true
        
        # Cleanup
        rm -f "$zip_file"
        
        # Update font cache
        if command_exists fc-cache; then
            fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
        fi
        
        local font_count
        font_count=$(ls "$fonts_dir"/*.ttf 2>/dev/null | wc -l)
        log_success "Installed $font_count font files"
        log_info "Configure your terminal to use: ${BOLD}JetBrainsMono Nerd Font${NC}"
    else
        log_warn "Failed to download Nerd Fonts - icons may not display correctly"
        log_info "Install manually with: labrat -m nerdfonts"
    fi
}

install_noto_symbols_font() {
    local fonts_dir="$HOME/.local/share/fonts"
    
    # Check if already installed via package or locally
    if fc-list | grep -qi "Noto Sans Symbols 2" 2>/dev/null; then
        log_info "Noto Sans Symbols 2 already installed"
        return 0
    fi
    
    log_step "Installing Noto Sans Symbols 2 (for segmented digits)..."
    
    # Try package manager first
    case "$OS_FAMILY" in
        debian)
            if pkg_install fonts-noto-core 2>/dev/null; then
                log_success "Noto fonts installed via package manager"
                return 0
            fi
            ;;
        rhel)
            if pkg_install google-noto-sans-symbols2-fonts 2>/dev/null; then
                log_success "Noto fonts installed via package manager"
                return 0
            fi
            ;;
        arch)
            if pkg_install noto-fonts 2>/dev/null; then
                log_success "Noto fonts installed via package manager"
                return 0
            fi
            ;;
    esac
    
    # Fallback: download directly from Google Fonts
    local download_url="https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSansSymbols2/NotoSansSymbols2-Regular.ttf"
    local font_file="$fonts_dir/NotoSansSymbols2-Regular.ttf"
    
    mkdir -p "$fonts_dir"
    
    if curl -fsSL -o "$font_file" "$download_url" 2>/dev/null; then
        fc-cache -f "$fonts_dir" 2>/dev/null || true
        log_success "Noto Sans Symbols 2 installed"
    else
        log_warn "Could not install Noto Sans Symbols 2 - segmented digits may not display correctly"
    fi
}

install_optional_theme_tools() {
    local theme="$1"
    
    case "$theme" in
        tokyo-night)
            log_step "Checking optional tools for Tokyo Night..."
            
            # GitHub CLI (optional for git widget)
            if ! command_exists gh; then
                log_info "Optional: gh (GitHub CLI) not installed - git widget will use basic info"
                log_info "  Install with: https://cli.github.com/"
            else
                log_info "GitHub CLI (gh) available for git widget"
            fi
            
            # playerctl for music (optional)
            if ! command_exists playerctl; then
                log_info "Optional: playerctl not installed - music widget disabled"
                case "$OS_FAMILY" in
                    debian)
                        log_info "  Install with: sudo apt install playerctl"
                        ;;
                esac
            else
                log_info "playerctl available for music widget"
            fi
            ;;
    esac
}

# ============================================================================
# Configuration Generation
# ============================================================================

generate_and_deploy_tmux_config() {
    local config_target="$HOME/.tmux.conf"
    
    log_step "Generating tmux configuration with theme: $SELECTED_TMUX_THEME"
    
    # Backup existing config
    if [[ -f "$config_target" ]] && [[ ! -L "$config_target" ]]; then
        backup_file "$config_target"
    fi
    
    # Generate config with selected theme
    generate_tmux_config "$config_target" "$SELECTED_TMUX_THEME"
    
    log_success "tmux config deployed with $SELECTED_TMUX_THEME theme"
}

generate_tmux_config() {
    local config_file="$1"
    local theme="$2"
    
    # Get theme plugin
    local theme_plugin="${TMUX_THEME_PLUGINS[$theme]}"
    
    # Generate theme-specific settings
    local theme_settings
    theme_settings=$(generate_theme_settings "$theme")
    
    cat > "$config_file" << TMUX_CONFIG
# ============================================================================
# LabRat tmux Configuration
# Your trusty environment for every test cage 🐀
# Theme: $theme
# Generated by LabRat installer
# ============================================================================

# ----------------------------------------------------------------------------
# General Settings
# ----------------------------------------------------------------------------

set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 50000
set -g display-time 4000
set -g status-interval 5
set -g focus-events on
set -s escape-time 10
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
setw -g aggressive-resize on
set -g status-position bottom
set -g status-left-length 100
set -g status-right-length 150

# ----------------------------------------------------------------------------
# Key Bindings
# ----------------------------------------------------------------------------

bind r source-file ~/.tmux.conf \; display-message "Config reloaded!"
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Alt + arrow keys to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Pane resizing
bind -r C-h resize-pane -L 5
bind -r C-j resize-pane -D 5
bind -r C-k resize-pane -U 5
bind -r C-l resize-pane -R 5

# Quick window switching
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5
bind -n M-6 select-window -t 6
bind -n M-7 select-window -t 7
bind -n M-8 select-window -t 8
bind -n M-9 select-window -t 9

# Scratchpad popup (tmux 3.2+)
bind -n M-g display-popup -E -w 80% -h 80% "tmux new-session -A -s scratch"
bind -n M-t display-popup -E -w 80% -h 80%

# Session management
bind S command-prompt -p "New session name:" "new-session -s '%%'"
bind K confirm-before -p "Kill session #S? (y/n)" kill-session

# Theme switcher
bind T run-shell "~/.local/bin/tmux-theme"

# ----------------------------------------------------------------------------
# Copy Mode (Vi-style)
# ----------------------------------------------------------------------------

setw -g mode-keys vi
bind [ copy-mode
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
bind -T copy-mode-vi r send-keys -X rectangle-toggle
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i 2>/dev/null || xsel -ib"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard -i 2>/dev/null || xsel -ib"
bind p paste-buffer

# ----------------------------------------------------------------------------
# Plugins (managed by TPM)
# ----------------------------------------------------------------------------

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'tmux-plugins/tmux-yank'
# NOTE: tmux-pain-control removed - caused backspace issues (^H mapped to pane switching)

# Plugin settings
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
set -g @yank_selection_mouse 'clipboard'

# ----------------------------------------------------------------------------
# Theme: $theme
# ----------------------------------------------------------------------------

set -g @plugin '$theme_plugin'
$theme_settings

# ----------------------------------------------------------------------------
# Initialize TPM (keep at bottom)
# ----------------------------------------------------------------------------

run '~/.tmux/plugins/tpm/tpm'
TMUX_CONFIG

    log_verbose "Generated tmux config with $theme theme"
}

generate_theme_settings() {
    local theme="$1"
    
    case "$theme" in
        catppuccin-mocha|catppuccin-latte|catppuccin-frappe|catppuccin-macchiato)
            local flavor="${theme#catppuccin-}"
            cat << EOF
# Catppuccin Theme Configuration
# Flavors: latte, frappe, macchiato, mocha
set -g @catppuccin_flavor "$flavor"

# Window styling: basic, rounded, slanted, custom, none
set -g @catppuccin_window_status_style "rounded"
set -g @catppuccin_window_number_position "left"
set -g @catppuccin_window_text " #W"
set -g @catppuccin_window_number "#I"
set -g @catppuccin_window_current_text " #W"
set -g @catppuccin_window_current_number "#I"

# Window flags: none, icon, or text
set -g @catppuccin_window_flags "icon"
set -g @catppuccin_window_flags_icon_last " 󰖰"
set -g @catppuccin_window_flags_icon_current " 󰖯"
set -g @catppuccin_window_flags_icon_zoom " 󰁌"
set -g @catppuccin_window_flags_icon_mark " 󰃀"

# Pane styling
set -g @catppuccin_pane_status_enabled "no"
set -g @catppuccin_pane_border_status "off"

# Status line styling
set -g @catppuccin_status_left_separator ""
set -g @catppuccin_status_middle_separator ""
set -g @catppuccin_status_right_separator "█"
set -g @catppuccin_status_connect_separator "yes"
set -g @catppuccin_status_fill "icon"
EOF
            ;;
        tokyo-night)
            cat << EOF
# Tokyo Night Theme Configuration
# Theme variant: night (default), storm, day
set -g @tokyo-night-tmux_theme night
set -g @tokyo-night-tmux_transparent 0

# Number styles: digital, hsquare, dsquare, roman, super, sub
set -g @tokyo-night-tmux_window_id_style digital
set -g @tokyo-night-tmux_pane_id_style hsquare
set -g @tokyo-night-tmux_zoom_id_style dsquare

# Window icons
set -g @tokyo-night-tmux_terminal_icon 
set -g @tokyo-night-tmux_active_terminal_icon 
set -g @tokyo-night-tmux_window_tidy_icons 0

# Date/Time Widget
set -g @tokyo-night-tmux_show_datetime 1
set -g @tokyo-night-tmux_date_format MYD
set -g @tokyo-night-tmux_time_format 24H

# Path Widget
set -g @tokyo-night-tmux_show_path 1
set -g @tokyo-night-tmux_path_format relative

# Git Widget (requires gh or glab CLI)
set -g @tokyo-night-tmux_show_git 1

# Battery Widget
set -g @tokyo-night-tmux_show_battery_widget 1
set -g @tokyo-night-tmux_battery_name "BAT1"
set -g @tokyo-night-tmux_battery_low_threshold 21

# Netspeed Widget (disabled by default - resource intensive)
set -g @tokyo-night-tmux_show_netspeed 0
set -g @tokyo-night-tmux_netspeed_iface "auto"
set -g @tokyo-night-tmux_netspeed_showip 0
set -g @tokyo-night-tmux_netspeed_refresh 1

# Music Widget (disabled by default - requires playerctl/cmus)
set -g @tokyo-night-tmux_show_music 0
EOF
            ;;
        dracula)
            cat << EOF
# Dracula Theme Configuration
# Plugins: battery, cpu-usage, git, gpu-usage, ram-usage, network, weather, time, etc.
set -g @dracula-plugins "git battery cpu-usage ram-usage time"

# Status bar options
set -g @dracula-show-powerline true
set -g @dracula-show-flags true
set -g @dracula-show-left-icon session
set -g @dracula-border-contrast true
set -g @dracula-show-empty-plugins false

# Powerline customization
set -g @dracula-show-edge-icons true
set -g @dracula-show-left-sep 
set -g @dracula-show-right-sep 

# Time widget
set -g @dracula-military-time true
set -g @dracula-show-timezone false
set -g @dracula-day-month true

# Git widget
set -g @dracula-git-show-current-symbol ✓
set -g @dracula-git-show-diff-symbol !
set -g @dracula-git-no-repo-message ""
set -g @dracula-git-no-untracked-files true

# Battery widget
set -g @dracula-battery-label "🔋"

# CPU widget
set -g @dracula-cpu-usage-label "CPU"
set -g @dracula-cpu-display-load true

# RAM widget  
set -g @dracula-ram-usage-label "RAM"

# Refresh rate
set -g @dracula-refresh-rate 5
EOF
            ;;
        nord)
            cat << EOF
# Nord Theme Configuration
# Arctic, bluish color scheme with clean aesthetics

# Show/hide status content (0 to hide, default shows)
set -g @nord_tmux_show_status_content 1

# Use non-patched fonts (1 = no Nerd Fonts needed)
set -g @nord_tmux_no_patched_font 0

# Custom date format (default: %Y-%m-%d)
set -g @nord_tmux_date_format "%Y-%m-%d"
EOF
            ;;
        gruvbox-dark|gruvbox-light)
            local variant="${theme#gruvbox-}"
            cat << EOF
# Gruvbox Theme Configuration
# Variants: dark, dark256, light, light256
set -g @tmux-gruvbox "$variant"

# Transparent statusbar (true/false)
set -g @tmux-gruvbox-statusbar-alpha 'false'

# Left status: session name by default
set -g @tmux-gruvbox-left-status-a '#S'

# Right status sections (x=date, y=time, z=hostname)
set -g @tmux-gruvbox-right-status-x '%Y-%m-%d'
set -g @tmux-gruvbox-right-status-y '%H:%M'
set -g @tmux-gruvbox-right-status-z '#h'
EOF
            ;;
        rose-pine|rose-pine-moon|rose-pine-dawn)
            local variant="${theme#rose-pine}"
            variant="${variant#-}"
            [[ -z "$variant" ]] && variant="main"
            cat << EOF
# Rose Pine Theme Configuration
# Variants: main, moon, dawn
set -g @rose_pine_variant '$variant'

# Status modules
set -g @rose_pine_host 'on'
set -g @rose_pine_user 'on'
set -g @rose_pine_directory 'on'
set -g @rose_pine_date_time '%H:%M'

# Transparent background (for terminal transparency)
set -g @rose_pine_bar_bg_disable 'off'

# Window options
set -g @rose_pine_only_windows 'off'
set -g @rose_pine_disable_active_window_menu 'off'
set -g @rose_pine_show_current_program 'off'
set -g @rose_pine_show_pane_directory 'on'

# Separators (Nerd Font icons)
set -g @rose_pine_left_separator ' > '
set -g @rose_pine_right_separator ' < '
set -g @rose_pine_field_separator ' | '

# Icons (Nerd Font)
set -g @rose_pine_session_icon ''
set -g @rose_pine_current_window_icon ''
set -g @rose_pine_folder_icon ''
set -g @rose_pine_username_icon ''
set -g @rose_pine_hostname_icon '󰒋'
set -g @rose_pine_date_time_icon '󰃰'
EOF
            ;;
        power-gold|power-everforest|power-moon|power-coral|power-snow|power-forest|power-violet|power-redwine)
            local variant="${theme#power-}"
            cat << EOF
# tmux-power Theme Configuration
# Themes: gold, everforest, moon, coral, snow, forest, violet, redwine
set -g @tmux_power_theme '$variant'

# Date/time format (strftime)
set -g @tmux_power_date_format '%Y-%m-%d'
set -g @tmux_power_time_format '%H:%M'

# Icons (Nerd Font)
set -g @tmux_power_date_icon ' '
set -g @tmux_power_time_icon ' '
set -g @tmux_power_user_icon ' '
set -g @tmux_power_session_icon ' '
set -g @tmux_power_right_arrow_icon ''
set -g @tmux_power_left_arrow_icon ''

# Component toggles
set -g @tmux_power_show_user true
set -g @tmux_power_show_host true
set -g @tmux_power_show_session true

# Plugin support (optional)
# set -g @tmux_power_show_upload_speed true
# set -g @tmux_power_show_download_speed true
# set -g @tmux_power_prefix_highlight_pos 'LR'
EOF
            ;;
        kanagawa-wave|kanagawa-dragon|kanagawa-lotus)
            local variant="${theme#kanagawa-}"
            cat << EOF
# Kanagawa Theme Configuration (Dracula fork)
# Themes: wave, dragon, lotus
set -g @kanagawa-theme '$variant'

# Plugins (same as Dracula)
set -g @kanagawa-plugins "git battery cpu-usage ram-usage time"

# Status bar options
set -g @kanagawa-show-powerline true
set -g @kanagawa-show-flags true
set -g @kanagawa-show-left-icon session
set -g @kanagawa-border-contrast true

# Preserve terminal background/foreground
set -g @kanagawa-ignore-window-colors false

# Time widget
set -g @kanagawa-military-time true
set -g @kanagawa-day-month true

# Git widget
set -g @kanagawa-git-show-current-symbol ✓
set -g @kanagawa-git-show-diff-symbol !
set -g @kanagawa-git-no-repo-message ""

# Refresh rate
set -g @kanagawa-refresh-rate 5
EOF
            ;;
        solarized-dark|solarized-light|solarized-256)
            local variant="${theme#solarized-}"
            cat << EOF
# Solarized Theme Configuration
# Variants: dark, light, 256, base16
set -g @colors-solarized '$variant'
EOF
            ;;
        onedark)
            cat << EOF
# OneDark Theme Configuration
# Atom One Dark inspired theme

# Custom widgets (shows on right side)
set -g @onedark_widgets ""

# Time format (strftime)
set -g @onedark_time_format "%H:%M"

# Date format (strftime)  
set -g @onedark_date_format "%Y-%m-%d"
EOF
            ;;
        minimal)
            cat << EOF
# Minimal Theme Configuration
# Clean theme with prefix indicator

# Colors
set -g @minimal-tmux-fg "#000000"
set -g @minimal-tmux-bg "#698DDA"

# Status position and alignment
set -g @minimal-tmux-status "bottom"
set -g @minimal-tmux-justify "centre"

# Prefix indicator
set -g @minimal-tmux-indicator true
set -g @minimal-tmux-indicator-str "  tmux  "

# Enable left/right sections
set -g @minimal-tmux-right true
set -g @minimal-tmux-left true

# Arrow style (rounded or edged)
set -g @minimal-tmux-use-arrow true
set -g @minimal-tmux-right-arrow ""
set -g @minimal-tmux-left-arrow ""

# Expanded/zoom icon
set -g @minimal-tmux-expanded-icon "󰊓 "
set -g @minimal-tmux-show-expanded-icon-for-all-tabs true
EOF
            ;;
        *)
            echo "# Unknown theme, using defaults"
            ;;
    esac
}

# ============================================================================
# Theme Script Installation
# ============================================================================

install_tmux_theme_script() {
    log_step "Installing tmux-theme script..."
    
    local script_source="${LABRAT_ROOT}/bin/tmux-theme"
    local script_target="$LABRAT_BIN_DIR/tmux-theme"
    
    if [[ -f "$script_source" ]]; then
        cp "$script_source" "$script_target"
        chmod +x "$script_target"
        log_success "tmux-theme installed to $script_target"
    else
        log_warn "tmux-theme script not found in source"
    fi
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_tmux() {
    log_step "Uninstalling tmux configuration..."
    
    # Remove config
    rm -f "$HOME/.tmux.conf"
    rm -f "$HOME/.tmux-theme"
    
    # Remove tmux-theme script
    rm -f "$LABRAT_BIN_DIR/tmux-theme"
    
    # Optionally remove TPM and plugins
    if confirm "Remove TPM and all tmux plugins?" "n"; then
        rm -rf "$HOME/.tmux/plugins"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/tmux"
    
    log_success "tmux configuration removed"
    log_info "Note: tmux binary was not removed (use package manager to uninstall)"
}
