#!/usr/bin/env bash
#
# LabRat - Main Installer
# Your trusty environment for every test cage 🐀
#
# Usage:
#   ./install.sh                    # Interactive mode
#   ./install.sh --all              # Install all modules
#   ./install.sh --modules tmux,fzf # Install specific modules
#   ./install.sh --update           # Update existing installation
#

set -euo pipefail

# ============================================================================
# Script Location and Library Loading
# ============================================================================

LABRAT_ROOT="${LABRAT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
LABRAT_LIB_DIR="${LABRAT_ROOT}/lib"
LABRAT_MODULES_DIR="${LABRAT_ROOT}/modules"
LABRAT_CONFIGS_DIR="${LABRAT_ROOT}/configs"

# shellcheck source=./lib/common.sh
source "${LABRAT_LIB_DIR}/common.sh"
# shellcheck source=./lib/package_manager.sh
source "${LABRAT_LIB_DIR}/package_manager.sh"

# ============================================================================
# Configuration
# ============================================================================

# Default settings
INSTALL_MODE="interactive"  # interactive, all, modules, update
SELECTED_MODULES=()
SKIP_CONFIRMATION=false
UNINSTALL_MODE=false

# Module definitions
declare -A MODULE_DESCRIPTIONS=(
    # Terminal
    ["tmux"]="Terminal multiplexer with themes and plugins"
    
    # Shell
    ["zsh"]="Z Shell with Oh My Zsh framework"
    ["fish"]="Friendly interactive shell"
    ["starship"]="Cross-shell prompt with customization"
    
    # Editors
    ["neovim"]="Hyperextensible Vim-based text editor"
    ["vim"]="Improved Vi editor with configuration"
    
    # Fonts
    ["nerdfonts"]="Install Nerd Fonts for icons"
    
    # Utilities
    ["fzf"]="Fuzzy finder for command-line"
    ["ripgrep"]="Fast regex-based search tool"
    ["bat"]="Cat clone with syntax highlighting"
    ["htop"]="Interactive process viewer"
    ["lazygit"]="Terminal UI for git commands"
    ["eza"]="Modern replacement for ls"
    ["zoxide"]="Smarter cd command"
    ["fd"]="Fast and user-friendly find alternative"
    ["fastfetch"]="Fast system info display (neofetch alternative)"
)

# Module categories for menu
declare -A MODULE_CATEGORIES=(
    ["terminal"]="tmux"
    ["shell"]="zsh fish starship"
    ["editors"]="neovim vim"
    ["fonts"]="nerdfonts"
    ["utils"]="fzf ripgrep bat htop lazygit eza zoxide fd fastfetch"
)

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    cat << EOF
${BOLD}LabRat Installer${NC} - Your trusty environment for every test cage 🐀

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -a, --all               Install all available modules
    -m, --modules LIST      Install specific modules (comma-separated)
    -u, --update            Update existing LabRat installation
    -l, --list              List all available modules
    -y, --yes               Skip confirmation prompts
    -v, --verbose           Enable verbose output
    -d, --debug             Enable debug output
    --prefix PATH           Set installation prefix (default: ~/.local)
    --uninstall MODULE      Uninstall a specific module
    --dry-run               Show what would be done without making changes

${BOLD}EXAMPLES:${NC}
    $(basename "$0")                         # Interactive mode
    $(basename "$0") --all                   # Install everything
    $(basename "$0") -m tmux,fzf,neovim      # Install specific modules
    $(basename "$0") --update                # Update all installed modules
    $(basename "$0") --list                  # Show available modules

${BOLD}ENVIRONMENT VARIABLES:${NC}
    LABRAT_PREFIX       Installation prefix (default: ~/.local)
    LABRAT_CONFIG_DIR   Config directory (default: ~/.config)
    LABRAT_VERBOSE      Enable verbose mode (1 to enable)
    LABRAT_DEBUG        Enable debug mode (1 to enable)

EOF
}

list_modules() {
    log_header "Available Modules"
    
    for category in terminal shell editors fonts utils; do
        local modules="${MODULE_CATEGORIES[$category]}"
        echo -e "${BOLD}${category^^}${NC}"
        echo -e "${DIM}$(printf '%.0s─' {1..40})${NC}"
        
        for module in $modules; do
            local desc="${MODULE_DESCRIPTIONS[$module]:-No description}"
            local status=""
            
            if is_module_installed "$module"; then
                local version=$(get_installed_version "$module")
                status="${GREEN}[installed: ${version}]${NC}"
            else
                status="${DIM}[not installed]${NC}"
            fi
            
            printf "  ${CYAN}%-12s${NC} %s %b\n" "$module" "$desc" "$status"
        done
        echo ""
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_usage
                exit 0
                ;;
            -a|--all)
                INSTALL_MODE="all"
                shift
                ;;
            -m|--modules)
                INSTALL_MODE="modules"
                IFS=',' read -ra SELECTED_MODULES <<< "$2"
                shift 2
                ;;
            -u|--update)
                INSTALL_MODE="update"
                shift
                ;;
            -l|--list)
                list_modules
                exit 0
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            -v|--verbose)
                LABRAT_VERBOSE=1
                shift
                ;;
            -d|--debug)
                LABRAT_DEBUG=1
                LABRAT_VERBOSE=1
                shift
                ;;
            --prefix)
                LABRAT_PREFIX="$2"
                LABRAT_BIN_DIR="${LABRAT_PREFIX}/bin"
                shift 2
                ;;
            --uninstall)
                UNINSTALL_MODE=true
                SELECTED_MODULES+=("$2")
                shift 2
                ;;
            --dry-run)
                LABRAT_DRY_RUN=1
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Interactive Menu
# ============================================================================

show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    
    ██╗      █████╗ ██████╗ ██████╗  █████╗ ████████╗
    ██║     ██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝
    ██║     ███████║██████╔╝██████╔╝███████║   ██║   
    ██║     ██╔══██║██╔══██╗██╔══██╗██╔══██║   ██║   
    ███████╗██║  ██║██████╔╝██║  ██║██║  ██║   ██║   
    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   
                                                      
EOF
    echo -e "${NC}"
    echo -e "    ${DIM}Your trusty environment for every test cage${NC} ${SYMBOL_RAT}"
    echo ""
}

# Helper to repeat a string n times
repeat_char() {
    local char="$1"
    local count="$2"
    local result=""
    for ((i=0; i<count; i++)); do
        result+="$char"
    done
    printf "%s" "$result"
}

draw_menu_box() {
    local title="$1"
    shift
    local options=("$@")
    local width=60
    local horizontal_line
    horizontal_line=$(repeat_char "═" "$width")
    
    echo -e "${COLOR_HEADER}╔${horizontal_line}╗${NC}"
    printf "${COLOR_HEADER}║${NC}${BOLD}  %-$((width - 2))s${COLOR_HEADER}║${NC}\n" "$title"
    echo -e "${COLOR_HEADER}╠${horizontal_line}╣${NC}"
    
    for opt in "${options[@]}"; do
        # Strip ANSI codes for length calculation
        local plain_opt
        plain_opt=$(echo -e "$opt" | sed 's/\x1b\[[0-9;]*m//g')
        local padding=$((width - 2 - ${#plain_opt}))
        if ((padding < 0)); then padding=0; fi
        printf "${COLOR_HEADER}║${NC}  %b%*s${COLOR_HEADER}║${NC}\n" "$opt" "$padding" ""
    done
    
    echo -e "${COLOR_HEADER}╚${horizontal_line}╝${NC}"
}

interactive_main_menu() {
    clear
    show_banner
    
    local options=(
        "[1] ${BOLD}Full Install${NC}     - Install all tools and configs"
        "[2] ${BOLD}Shell Suite${NC}      - zsh, starship, fzf, zoxide"
        "[3] ${BOLD}Editor Suite${NC}     - neovim, vim with configs"
        "[4] ${BOLD}Terminal Tools${NC}   - tmux, htop, lazygit"
        "[5] ${BOLD}Utilities${NC}        - fzf, ripgrep, bat, eza, fd"
        "[6] ${BOLD}Custom Select${NC}    - Choose individual modules"
        "[7] ${BOLD}Update${NC}           - Update installed modules"
        "[8] ${BOLD}Show Installed${NC}   - List installed modules"
        "[q] ${BOLD}Quit${NC}"
    )
    
    draw_menu_box "LabRat Installer" "${options[@]}"
    echo ""
    
    read -rp "$(echo -e "${COLOR_ACCENT}>${NC} Enter selection: ")" choice
    
    case "$choice" in
        1)
            SELECTED_MODULES=(tmux zsh starship neovim vim fzf ripgrep bat htop lazygit eza zoxide fd fastfetch)
            ;;
        2)
            SELECTED_MODULES=(zsh starship fzf zoxide)
            ;;
        3)
            SELECTED_MODULES=(neovim vim)
            ;;
        4)
            SELECTED_MODULES=(tmux htop lazygit)
            ;;
        5)
            SELECTED_MODULES=(fzf ripgrep bat eza fd)
            ;;
        6)
            interactive_custom_select
            ;;
        7)
            INSTALL_MODE="update"
            ;;
        8)
            show_installed_modules
            read -rp "Press Enter to continue..."
            interactive_main_menu
            return
            ;;
        q|Q)
            log_info "Goodbye! 🐀"
            exit 0
            ;;
        *)
            log_warn "Invalid selection"
            sleep 1
            interactive_main_menu
            return
            ;;
    esac
}

interactive_custom_select() {
    clear
    show_banner
    
    echo -e "${BOLD}Select modules to install:${NC}"
    echo -e "${DIM}(Enter numbers separated by spaces, or 'a' for all, 'q' to go back)${NC}"
    echo ""
    
    local all_modules=()
    local i=1
    
    for category in terminal shell editors fonts utils; do
        echo -e "${BOLD}${category^^}${NC}"
        local modules="${MODULE_CATEGORIES[$category]}"
        
        for module in $modules; do
            local desc="${MODULE_DESCRIPTIONS[$module]:-}"
            local status=""
            
            if is_module_installed "$module"; then
                status="${GREEN}✓${NC}"
            fi
            
            printf "  [%2d] %-12s %s %b\n" "$i" "$module" "$desc" "$status"
            all_modules+=("$module")
            ((i++))
        done
        echo ""
    done
    
    read -rp "$(echo -e "${COLOR_ACCENT}>${NC} Enter selection: ")" -a selections
    
    if [[ "${selections[0]:-}" == "q" ]]; then
        interactive_main_menu
        return
    fi
    
    if [[ "${selections[0]:-}" == "a" ]]; then
        SELECTED_MODULES=("${all_modules[@]}")
        return
    fi
    
    SELECTED_MODULES=()
    for sel in "${selections[@]}"; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && ((sel >= 1 && sel <= ${#all_modules[@]})); then
            SELECTED_MODULES+=("${all_modules[$((sel-1))]}")
        fi
    done
    
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        log_warn "No valid modules selected"
        sleep 1
        interactive_custom_select
    fi
}

show_installed_modules() {
    log_header "Installed Modules"
    
    local installed_dir="${LABRAT_DATA_DIR}/installed"
    
    if [[ ! -d "$installed_dir" ]] || [[ -z "$(ls -A "$installed_dir" 2>/dev/null)" ]]; then
        log_info "No modules installed yet"
        return
    fi
    
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local module=$(basename "$marker")
            local version=$(cat "$marker")
            local desc="${MODULE_DESCRIPTIONS[$module]:-}"
            printf "  ${GREEN}${SYMBOL_CHECK}${NC} ${CYAN}%-12s${NC} v%-10s %s\n" "$module" "$version" "$desc"
        fi
    done
    echo ""
}

# ============================================================================
# Module Installation
# ============================================================================

install_module() {
    local module="$1"
    local module_script=""
    
    # Find module script
    for category in terminal shell editors fonts utils; do
        local script="${LABRAT_MODULES_DIR}/${category}/${module}.sh"
        if [[ -f "$script" ]]; then
            module_script="$script"
            break
        fi
    done
    
    if [[ -z "$module_script" ]]; then
        log_error "Module not found: $module"
        return 1
    fi
    
    log_subheader "Installing: $module"
    
    # Source and run the module installer
    # shellcheck source=/dev/null
    source "$module_script"
    
    # Each module should define an install_<module> function
    local install_func="install_${module}"
    
    if declare -f "$install_func" > /dev/null; then
        if [[ "$LABRAT_DRY_RUN" == "1" ]]; then
            log_info "[DRY RUN] Would run: $install_func"
        else
            "$install_func"
        fi
    else
        log_error "Module $module does not define $install_func function"
        return 1
    fi
}

update_module() {
    local module="$1"
    
    if ! is_module_installed "$module"; then
        log_warn "Module not installed, skipping update: $module"
        return 0
    fi
    
    log_subheader "Updating: $module"
    install_module "$module"
}

# ============================================================================
# Installation Process
# ============================================================================

confirm_installation() {
    if [[ "$SKIP_CONFIRMATION" == true ]]; then
        return 0
    fi
    
    echo ""
    log_info "The following modules will be installed:"
    echo ""
    
    for module in "${SELECTED_MODULES[@]}"; do
        local desc="${MODULE_DESCRIPTIONS[$module]:-}"
        echo -e "  ${CYAN}${SYMBOL_BULLET}${NC} ${BOLD}$module${NC} - $desc"
    done
    
    echo ""
    log_info "Installation prefix: ${BOLD}$LABRAT_PREFIX${NC}"
    log_info "Config directory: ${BOLD}$LABRAT_CONFIG_DIR${NC}"
    echo ""
    
    confirm "Proceed with installation?" "y"
}

run_installation() {
    log_header "Installing Modules"
    
    local failed_modules=()
    local success_count=0
    
    for module in "${SELECTED_MODULES[@]}"; do
        if install_module "$module"; then
            ((++success_count)) || true
        else
            failed_modules+=("$module")
        fi
    done
    
    echo ""
    log_header "Installation Complete"
    
    log_success "Successfully installed: $success_count module(s)"
    
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        log_warn "Failed to install: ${failed_modules[*]}"
    fi
    
    # Persist PATH if needed
    if [[ ":$PATH:" != *":$LABRAT_BIN_DIR:"* ]]; then
        persist_path "$LABRAT_BIN_DIR"
        log_info "Added ${LABRAT_BIN_DIR} to your PATH"
        log_info "Run: ${BOLD}source ~/.bashrc${NC} (or restart your shell)"
    fi
}

run_update() {
    log_header "Updating Installed Modules"
    
    local installed_dir="${LABRAT_DATA_DIR}/installed"
    
    if [[ ! -d "$installed_dir" ]] || [[ -z "$(ls -A "$installed_dir" 2>/dev/null)" ]]; then
        log_warn "No modules installed to update"
        return 0
    fi
    
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local module=$(basename "$marker")
            update_module "$module"
        fi
    done
    
    log_success "Update complete!"
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    # Parse command-line arguments
    parse_args "$@"
    
    # Handle different modes
    case "$INSTALL_MODE" in
        interactive)
            # Interactive mode shows its own banner
            interactive_main_menu
            if [[ ${#SELECTED_MODULES[@]} -eq 0 ]] && [[ "$INSTALL_MODE" != "update" ]]; then
                log_error "No modules selected"
                exit 1
            fi
            if [[ "$INSTALL_MODE" == "update" ]]; then
                run_update
            else
                confirm_installation && run_installation
            fi
            ;;
        all)
            show_banner
            log_info "System: ${BOLD}$OS $OS_VERSION${NC} ($OS_FAMILY)"
            log_info "Architecture: ${BOLD}$ARCH${NC}"
            log_info "Install prefix: ${BOLD}$LABRAT_PREFIX${NC}"
            echo ""
            SELECTED_MODULES=(tmux zsh starship neovim vim fzf ripgrep bat htop lazygit eza zoxide fd fastfetch)
            confirm_installation && run_installation
            ;;
        modules)
            show_banner
            log_info "System: ${BOLD}$OS $OS_VERSION${NC} ($OS_FAMILY)"
            log_info "Architecture: ${BOLD}$ARCH${NC}"
            log_info "Install prefix: ${BOLD}$LABRAT_PREFIX${NC}"
            echo ""
            if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
                log_error "No modules specified"
                exit 1
            fi
            confirm_installation && run_installation
            ;;
        update)
            show_banner
            log_info "System: ${BOLD}$OS $OS_VERSION${NC} ($OS_FAMILY)"
            log_info "Install prefix: ${BOLD}$LABRAT_PREFIX${NC}"
            echo ""
            run_update
            ;;
    esac
    
    echo ""
    log_info "Thank you for using LabRat! 🐀"
}

# Run main
main "$@"
