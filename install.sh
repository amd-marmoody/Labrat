#!/usr/bin/env bash
#
# LabRat - Main Installer
# Your trusty environment for every test cage
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

# Module definitions - descriptions for all available modules
declare -A MODULE_DESCRIPTIONS=(
    # Terminal
    ["tmux"]="Terminal multiplexer with themes, plugins, and session management"
    
    # Shell
    ["zsh"]="Z Shell with Oh My Zsh framework and plugins"
    ["starship"]="Cross-shell prompt with customizable themes"
    
    # Editors
    ["neovim"]="Hyperextensible Vim-based text editor with modern configs"
    ["vim"]="Improved Vi editor with LabRat configuration"
    
    # Fonts
    ["nerdfonts"]="Nerd Fonts with icons for terminal and editors"
    
    # Utilities
    ["fzf"]="Fuzzy finder for files, history, and more"
    ["ripgrep"]="Fast regex-based recursive search (rg)"
    ["bat"]="Cat clone with syntax highlighting and git integration"
    ["htop"]="Interactive process viewer and system monitor"
    ["lazygit"]="Simple terminal UI for git commands"
    ["eza"]="Modern replacement for ls with colors and icons"
    ["zoxide"]="Smarter cd command that learns your habits"
    ["fd"]="Fast and user-friendly alternative to find"
    ["fastfetch"]="Fast system information display"
    ["duf"]="Disk usage utility with better formatting"
    ["ncdu"]="NCurses disk usage analyzer"
    
    # Monitoring
    ["btop"]="Resource monitor with CPU, memory, disks, network"
    ["glances"]="Cross-platform system monitoring tool"
    ["bandwhich"]="Terminal bandwidth utilization by process"
    ["nethogs"]="Net top tool grouping bandwidth by process"
    ["iotop"]="I/O monitor showing disk read/write by process"
    ["procs"]="Modern replacement for ps with colors"
    
    # Network
    ["mtr"]="Network diagnostic tool combining ping and traceroute"
    ["gping"]="Ping with a graph visualization"
    ["dog"]="Command-line DNS client (dig alternative)"
    ["nmap"]="Network discovery and security auditing"
    ["trippy"]="Network diagnostic tool with TUI"
    
    # Productivity
    ["atuin"]="Shell history with sync, search, and stats"
    ["broot"]="Interactive directory navigator and file manager"
    ["direnv"]="Environment switcher for the shell"
    ["just"]="Command runner for project-specific tasks"
    ["mise"]="Polyglot runtime manager (asdf alternative)"
    ["thefuck"]="Corrects your previous console command"
    ["tldr"]="Simplified man pages with practical examples"
    
    # Security
    ["ssh-keys"]="SSH key management with agent integration"
)

# Module categories - used for organization and menu display
declare -A MODULE_CATEGORIES=(
    ["terminal"]="tmux"
    ["shell"]="zsh starship"
    ["editors"]="neovim vim"
    ["fonts"]="nerdfonts"
    ["utils"]="fzf ripgrep bat htop lazygit eza zoxide fd fastfetch duf ncdu"
    ["monitoring"]="btop glances bandwhich nethogs iotop procs"
    ["network"]="mtr gping dog nmap trippy"
    ["productivity"]="atuin broot direnv just mise thefuck tldr"
    ["security"]="ssh-keys"
)

# Preset definitions with verbose descriptions
declare -A PRESET_DESCRIPTIONS=(
    ["full"]="Complete LabRat environment with all tools, themes, and configurations. Includes shell enhancements, editors, monitoring, networking, and productivity tools. Perfect for a new workstation or server you'll use regularly."
    ["developer"]="Modern development environment with smart shell, fuzzy finding, and intelligent navigation. Includes zsh with starship prompt, neovim, fzf for file/history search, ripgrep for code search, bat for syntax-highlighted file viewing, eza for directory listings, and zoxide for quick directory jumping."
    ["devops"]="Server administration toolkit with system monitoring, network diagnostics, and terminal productivity. Includes tmux for session management, btop/htop for system monitoring, mtr/gping for network testing, lazygit for quick git operations, and glances for overview dashboards."
    ["monitoring"]="Real-time system and network monitoring tools. See CPU, memory, disk, and network usage at a glance. Includes btop (resource monitor), htop (process viewer), glances (system overview), iotop (disk I/O), nethogs (network per-process), and bandwhich (bandwidth monitor)."
    ["network"]="Network diagnostic and security tools for troubleshooting connectivity, DNS, and scanning. Includes mtr (traceroute+ping), gping (visual ping), dog (DNS client), nmap (network scanner), and trippy (network TUI)."
    ["productivity"]="Shell productivity enhancements for faster workflows. Includes atuin (searchable shell history with sync), zoxide (smart cd), thefuck (command correction), just (task runner), direnv (per-directory env), mise (runtime manager), broot (file navigator), and tldr (simplified man pages)."
    ["editors"]="Text editors with LabRat configurations. Neovim with modern plugins and keybindings, Vim with sensible defaults and enhancements."
    ["fonts"]="Nerd Fonts installation for proper icon display in terminal, editors, and prompts. Required for full visual experience with starship, eza, and neovim."
)

# Preset module lists
declare -A PRESET_MODULES=(
    ["full"]="tmux zsh starship neovim vim nerdfonts fzf ripgrep bat htop lazygit eza zoxide fd fastfetch duf ncdu btop glances bandwhich nethogs iotop procs mtr gping dog nmap trippy atuin broot direnv just mise thefuck tldr"
    ["developer"]="zsh starship neovim fzf ripgrep bat eza zoxide fd"
    ["devops"]="tmux btop htop glances mtr gping lazygit"
    ["monitoring"]="btop htop glances iotop nethogs bandwhich procs"
    ["network"]="mtr gping dog nmap trippy"
    ["productivity"]="atuin zoxide thefuck just direnv mise broot tldr"
    ["editors"]="neovim vim"
    ["fonts"]="nerdfonts"
)

# ============================================================================
# Argument Parsing
# ============================================================================

print_usage() {
    cat << EOF
${BOLD}LabRat Installer${NC} - Your trusty environment for every test cage

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

${BOLD}PRESETS:${NC}
    full          All tools and configurations
    developer     Shell, editor, fuzzy finding, navigation
    devops        Monitoring, networking, terminal tools
    monitoring    System and network monitoring
    network       Diagnostic and scanning tools
    productivity  Shell enhancements and task automation
    editors       Neovim and Vim with configs
    fonts         Nerd Fonts for icons

${BOLD}ENVIRONMENT VARIABLES:${NC}
    LABRAT_PREFIX       Installation prefix (default: ~/.local)
    LABRAT_CONFIG_DIR   Config directory (default: ~/.config)
    LABRAT_VERBOSE      Enable verbose mode (1 to enable)
    LABRAT_DEBUG        Enable debug mode (1 to enable)

EOF
}

list_modules() {
    log_header "Available Modules"
    
    for category in terminal shell editors fonts utils monitoring network productivity security; do
        local modules="${MODULE_CATEGORIES[$category]:-}"
        [[ -z "$modules" ]] && continue
        
        echo -e "${BOLD}${category^^}${NC}"
        echo -e "${DIM}$(printf '%.0s─' {1..50})${NC}"
        
        for module in $modules; do
            local desc="${MODULE_DESCRIPTIONS[$module]:-No description}"
            local status=""
            
            if is_module_installed "$module"; then
                local version=$(get_installed_version "$module")
                status="${GREEN}[installed: ${version}]${NC}"
            else
                status="${DIM}[not installed]${NC}"
            fi
            
            printf "  ${CYAN}%-12s${NC} %-40s %b\n" "$module" "$desc" "$status"
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
    echo -e "    ${DIM}Just a rat in a cage${NC}"
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
    local width=70
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

show_preset_info() {
    local preset="$1"
    local desc="${PRESET_DESCRIPTIONS[$preset]:-No description}"
    local modules="${PRESET_MODULES[$preset]:-}"
    
    echo ""
    echo -e "${BOLD}${preset^^}${NC}"
    echo -e "${DIM}$(repeat_char "─" 60)${NC}"
    echo -e "$desc"
    echo ""
    echo -e "${BOLD}Modules:${NC} ${CYAN}$modules${NC}"
    echo ""
}

interactive_main_menu() {
    clear
    show_banner
    
    local options=(
        "[1] ${BOLD}Full Install${NC}       - Complete environment with all tools"
        "[2] ${BOLD}Developer Suite${NC}    - Shell, editor, fuzzy finding, navigation"
        "[3] ${BOLD}DevOps Essentials${NC}  - Monitoring, networking, terminal tools"
        "[4] ${BOLD}Monitoring Tools${NC}   - btop, htop, glances, nethogs, bandwhich"
        "[5] ${BOLD}Network Utilities${NC}  - mtr, gping, dog, nmap, trippy"
        "[6] ${BOLD}Productivity${NC}       - atuin, zoxide, thefuck, just, tldr"
        "[7] ${BOLD}Editors Only${NC}       - neovim, vim with configs"
        "[8] ${BOLD}Fonts${NC}              - Nerd Fonts for terminal icons"
        "[9] ${BOLD}SSH Keys${NC}           - Manage SSH keys and agent"
        "[0] ${BOLD}Custom Select${NC}      - Choose individual modules"
        ""
        "[u] ${BOLD}Update${NC}             - Update installed modules"
        "[i] ${BOLD}Show Installed${NC}     - List what's installed"
        "[?] ${BOLD}Preset Info${NC}        - Show details about a preset"
        "[q] ${BOLD}Quit${NC}"
    )
    
    draw_menu_box "LabRat Installer" "${options[@]}"
    echo ""
    
    read -rp "$(echo -e "${COLOR_ACCENT}>${NC} Enter selection: ")" choice
    
    case "$choice" in
        1)
            show_preset_info "full"
            read -rp "Install Full Suite? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[full]}"
                PROMPT_SSH_KEYS=true
            else
                interactive_main_menu
                return
            fi
            ;;
        2)
            show_preset_info "developer"
            read -rp "Install Developer Suite? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[developer]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        3)
            show_preset_info "devops"
            read -rp "Install DevOps Essentials? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[devops]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        4)
            show_preset_info "monitoring"
            read -rp "Install Monitoring Tools? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[monitoring]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        5)
            show_preset_info "network"
            read -rp "Install Network Utilities? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[network]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        6)
            show_preset_info "productivity"
            read -rp "Install Productivity Tools? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[productivity]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        7)
            show_preset_info "editors"
            read -rp "Install Editors? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[editors]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        8)
            show_preset_info "fonts"
            read -rp "Install Nerd Fonts? [Y/n]: " confirm
            if [[ ! "$confirm" =~ ^[Nn] ]]; then
                read -ra SELECTED_MODULES <<< "${PRESET_MODULES[fonts]}"
            else
                interactive_main_menu
                return
            fi
            ;;
        9)
            interactive_ssh_keys
            interactive_main_menu
            return
            ;;
        0)
            interactive_custom_select
            ;;
        u|U)
            INSTALL_MODE="update"
            ;;
        i|I)
            show_installed_modules
            read -rp "Press Enter to continue..."
            interactive_main_menu
            return
            ;;
        \?)
            interactive_preset_info
            interactive_main_menu
            return
            ;;
        q|Q)
            log_info "Goodbye!"
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

interactive_preset_info() {
    clear
    show_banner
    
    echo -e "${BOLD}Available Presets:${NC}"
    echo ""
    echo "  [1] full          [2] developer     [3] devops"
    echo "  [4] monitoring    [5] network       [6] productivity"
    echo "  [7] editors       [8] fonts"
    echo ""
    
    read -rp "Select preset to view details (or 'q' to go back): " choice
    
    case "$choice" in
        1) show_preset_info "full" ;;
        2) show_preset_info "developer" ;;
        3) show_preset_info "devops" ;;
        4) show_preset_info "monitoring" ;;
        5) show_preset_info "network" ;;
        6) show_preset_info "productivity" ;;
        7) show_preset_info "editors" ;;
        8) show_preset_info "fonts" ;;
        q|Q) return ;;
        *) log_warn "Invalid selection" ;;
    esac
    
    read -rp "Press Enter to continue..."
}

interactive_ssh_keys() {
    # Check if labrat-ssh is available and run it
    if command -v labrat-ssh &>/dev/null; then
        labrat-ssh
    elif [[ -x "${LABRAT_ROOT}/bin/labrat-ssh" ]]; then
        "${LABRAT_ROOT}/bin/labrat-ssh"
    else
        clear
        show_banner
        
        echo -e "${BOLD}SSH Key Management${NC}"
        echo -e "${DIM}$(repeat_char "─" 50)${NC}"
        echo ""
        echo -e "${YELLOW}labrat-ssh not installed.${NC}"
        echo ""
        read -rp "Install SSH key management module? [Y/n]: " confirm
        if [[ ! "$confirm" =~ ^[Nn] ]]; then
            install_module "ssh-keys"
            echo ""
            echo "Run 'labrat-ssh' to manage your keys."
            read -rp "Press Enter to continue..."
        fi
    fi
}

interactive_custom_select() {
    clear
    show_banner
    
    echo -e "${BOLD}Select modules to install:${NC}"
    echo -e "${DIM}(Enter numbers separated by spaces, or 'a' for all, 'q' to go back)${NC}"
    echo ""
    
    local all_modules=()
    local i=1
    
    for category in terminal shell editors fonts utils monitoring network productivity security; do
        local modules="${MODULE_CATEGORIES[$category]:-}"
        [[ -z "$modules" ]] && continue
        
        echo -e "${BOLD}${category^^}${NC}"
        
        for module in $modules; do
            local desc="${MODULE_DESCRIPTIONS[$module]:-}"
            # Truncate description for display
            if [[ ${#desc} -gt 40 ]]; then
                desc="${desc:0:37}..."
            fi
            local status=""
            
            if is_module_installed "$module"; then
                status="${GREEN}[ok]${NC}"
            fi
            
            printf "  [%2d] %-12s %-40s %b\n" "$i" "$module" "$desc" "$status"
            all_modules+=("$module")
            ((i++)) || true
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
    
    local count=0
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local module=$(basename "$marker")
            # Only read first line of version file (some have multi-line content)
            local version
            version=$(head -n1 "$marker" | tr -d '\n')
            local desc="${MODULE_DESCRIPTIONS[$module]:-}"
            printf "  ${GREEN}${SYMBOL_CHECK}${NC} ${CYAN}%-12s${NC} v%-10s %s\n" "$module" "$version" "$desc"
            ((count++)) || true
        fi
    done
    
    echo ""
    echo -e "Total: ${BOLD}${count}${NC} module(s) installed"
    echo ""
}

# ============================================================================
# Module Installation
# ============================================================================

install_module() {
    local module="$1"
    local module_script=""
    
    # Find module script in all categories
    for category in terminal shell editors fonts utils monitoring network productivity security; do
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
    # Handle hyphenated names by converting to underscores
    local func_name="${module//-/_}"
    local install_func="install_${func_name}"
    
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
    local installed_modules=()
    
    for module in "${SELECTED_MODULES[@]}"; do
        if install_module "$module"; then
            ((++success_count)) || true
            installed_modules+=("$module")
        else
            failed_modules+=("$module")
        fi
    done
    
    # Handle SSH key prompt for full install
    if [[ "${PROMPT_SSH_KEYS:-}" == "true" ]]; then
        echo ""
        read -rp "Would you like to configure SSH keys now? [Y/n]: " confirm
        if [[ ! "$confirm" =~ ^[Nn] ]]; then
            interactive_ssh_keys
        fi
    fi
    
    # Show post-install summary
    show_post_install_summary "$success_count" "${installed_modules[*]}" "${failed_modules[*]}"
}

show_post_install_summary() {
    local success_count="$1"
    local installed="$2"
    local failed="$3"
    
    echo ""
    local width=66
    local horizontal_line
    horizontal_line=$(repeat_char "═" "$width")
    
    echo -e "${GREEN}╔${horizontal_line}╗${NC}"
    printf "${GREEN}║${NC}  ${BOLD}%-$((width - 4))s${NC}  ${GREEN}║${NC}\n" "Installation Complete!"
    echo -e "${GREEN}╠${horizontal_line}╣${NC}"
    
    # Installed count
    printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "Installed: ${success_count} module(s)"
    
    # Shell integration note
    if [[ "$installed" == *"zsh"* ]] || [[ "$installed" == *"starship"* ]]; then
        printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "Shell integration: configured"
    fi
    
    # SSH keys note
    if [[ "$installed" == *"ssh-keys"* ]] || [[ "${PROMPT_SSH_KEYS:-}" == "true" ]]; then
        local key_count=0
        if [[ -d "$HOME/.ssh/labrat" ]]; then
            key_count=$(find "$HOME/.ssh/labrat" -type f ! -name "*.pub" 2>/dev/null | wc -l)
        fi
        printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "SSH keys: ${key_count} key(s) managed"
    fi
    
    # Failed modules
    if [[ -n "$failed" ]]; then
        printf "${GREEN}║${NC}  ${YELLOW}%-$((width - 4))s${NC}  ${GREEN}║${NC}\n" "Failed: $failed"
    fi
    
    echo -e "${GREEN}╠${horizontal_line}╣${NC}"
    
    # Documentation links
    printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" ""
    printf "${GREEN}║${NC}  ${BOLD}%-$((width - 4))s${NC}  ${GREEN}║${NC}\n" "Documentation:"
    printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "  LabRat README:  https://github.com/amd-marmoody/Labrat#readme"
    
    if [[ "$installed" == *"tmux"* ]]; then
        printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "  tmux config:    labrat/configs/tmux/README.md"
    fi
    
    if [[ "$installed" == *"ssh-keys"* ]] || command -v labrat-ssh &>/dev/null; then
        printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" "  SSH keys:       labrat-ssh help"
    fi
    
    printf "${GREEN}║${NC}  %-$((width - 4))s  ${GREEN}║${NC}\n" ""
    
    echo -e "${GREEN}╠${horizontal_line}╣${NC}"
    
    # Next steps
    printf "${GREEN}║${NC}  ${BOLD}%-$((width - 4))s${NC}  ${GREEN}║${NC}\n" "Next step: source ~/.bashrc (or restart your shell)"
    
    echo -e "${GREEN}╚${horizontal_line}╝${NC}"
    echo ""
}

run_update() {
    log_header "Updating Installed Modules"
    
    local installed_dir="${LABRAT_DATA_DIR}/installed"
    
    if [[ ! -d "$installed_dir" ]] || [[ -z "$(ls -A "$installed_dir" 2>/dev/null)" ]]; then
        log_warn "No modules installed to update"
        return 0
    fi
    
    local updated=0
    for marker in "$installed_dir"/*; do
        if [[ -f "$marker" ]]; then
            local module=$(basename "$marker")
            update_module "$module"
            ((updated++)) || true
        fi
    done
    
    echo ""
    log_success "Updated $updated module(s)!"
    echo ""
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
            read -ra SELECTED_MODULES <<< "${PRESET_MODULES[full]}"
            PROMPT_SSH_KEYS=true
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
    log_info "Thank you for using LabRat!"
}

# Run main
main "$@"
