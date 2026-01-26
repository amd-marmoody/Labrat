#!/usr/bin/env bash
#
# LabRat - Menu Helper Functions
# TUI components for labrat-menu
#

# Source colors if not already loaded
[[ -z "${NC:-}" ]] && source "${LABRAT_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/colors.sh"

# ============================================================================
# Terminal Control
# ============================================================================

# Get terminal dimensions
get_term_width() {
    tput cols 2>/dev/null || echo 80
}

get_term_height() {
    tput lines 2>/dev/null || echo 24
}

# Clear screen
clear_screen() {
    printf '\033[2J\033[H'
}

# Move cursor
move_cursor() {
    local row="$1"
    local col="$2"
    printf '\033[%d;%dH' "$row" "$col"
}

# Hide/show cursor
hide_cursor() {
    printf '\033[?25l'
}

show_cursor() {
    printf '\033[?25h'
}

# ============================================================================
# Box Drawing
# ============================================================================

# Draw a box with title
# Usage: draw_box "Title" width [color]
draw_box_top() {
    local title="$1"
    local width="${2:-70}"
    local color="${3:-$CYAN}"
    
    local title_len=${#title}
    local padding=$(( (width - title_len - 4) / 2 ))
    local padding_right=$(( width - title_len - 4 - padding ))
    
    echo -e "${color}╔$(repeat_char "═" "$width")╗${NC}"
    if [[ -n "$title" ]]; then
        printf "${color}║${NC}%*s${BOLD} %s ${NC}%*s${color}║${NC}\n" "$padding" "" "$title" "$padding_right" ""
        echo -e "${color}╠$(repeat_char "═" "$width")╣${NC}"
    fi
}

draw_box_line() {
    local text="$1"
    local width="${2:-70}"
    local color="${3:-$CYAN}"
    
    # Strip ANSI for length calculation
    local plain_text
    plain_text=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
    local text_len=${#plain_text}
    local padding=$((width - text_len - 2))
    
    if ((padding < 0)); then
        padding=0
        text="${text:0:$((width - 5))}..."
    fi
    
    printf "${color}║${NC} %b%*s${color}║${NC}\n" "$text" "$padding" ""
}

draw_box_separator() {
    local width="${1:-70}"
    local color="${2:-$CYAN}"
    
    echo -e "${color}╠$(repeat_char "═" "$width")╣${NC}"
}

draw_box_bottom() {
    local width="${1:-70}"
    local color="${2:-$CYAN}"
    
    echo -e "${color}╚$(repeat_char "═" "$width")╝${NC}"
}

# Draw a complete box with content array
# Usage: draw_box "Title" width color "${lines[@]}"
draw_box() {
    local title="$1"
    local width="$2"
    local color="$3"
    shift 3
    local lines=("$@")
    
    draw_box_top "$title" "$width" "$color"
    for line in "${lines[@]}"; do
        if [[ "$line" == "---" ]]; then
            draw_box_separator "$width" "$color"
        else
            draw_box_line "$line" "$width" "$color"
        fi
    done
    draw_box_bottom "$width" "$color"
}

# Helper to repeat a character
repeat_char() {
    local char="$1"
    local count="$2"
    local result=""
    for ((i=0; i<count; i++)); do
        result+="$char"
    done
    printf "%s" "$result"
}

# ============================================================================
# Status Indicators
# ============================================================================

# Status dot indicators
status_on() {
    echo -e "${GREEN}●${NC}"
}

status_off() {
    echo -e "${DIM}○${NC}"
}

status_check() {
    echo -e "${GREEN}✓${NC}"
}

status_cross() {
    echo -e "${RED}✗${NC}"
}

status_warn() {
    echo -e "${YELLOW}!${NC}"
}

# Format module status line
format_module_status() {
    local module="$1"
    local is_enabled="$2"
    local description="$3"
    
    local status_icon
    if [[ "$is_enabled" == "true" ]] || [[ "$is_enabled" == "1" ]]; then
        status_icon="$(status_on) ON "
    else
        status_icon="$(status_off) OFF"
    fi
    
    printf "%-14s %s  %s" "$module" "$status_icon" "$description"
}

# ============================================================================
# Menu Selection
# ============================================================================

# Read a single keypress
read_key() {
    local key
    IFS= read -rsn1 key
    
    # Handle escape sequences (arrow keys, etc)
    if [[ "$key" == $'\033' ]]; then
        read -rsn2 -t 0.1 key2
        key+="$key2"
    fi
    
    echo "$key"
}

# Read menu selection with prompt
read_selection() {
    local prompt="${1:-Select: }"
    local input
    
    echo -ne "${COLOR_ACCENT:-$CYAN}>${NC} $prompt"
    read -r input
    echo "$input"
}

# Confirm prompt
confirm_action() {
    local message="${1:-Continue?}"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    echo -ne "$message $prompt: "
    read -r response
    
    case "$response" in
        [yY]|[yY][eE][sS]) return 0 ;;
        [nN]|[nN][oO]) return 1 ;;
        "")
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *) return 1 ;;
    esac
}

# ============================================================================
# fzf Integration
# ============================================================================

# Check if fzf is available
has_fzf() {
    command -v fzf &>/dev/null
}

# Run fzf with LabRat styling
run_fzf() {
    local header="${1:-Select an option}"
    shift
    local options=("$@")
    
    if ! has_fzf; then
        echo "Error: fzf is required for this feature" >&2
        return 1
    fi
    
    printf '%s\n' "${options[@]}" | fzf \
        --header="$header" \
        --height=40% \
        --layout=reverse \
        --border=rounded \
        --prompt="❯ " \
        --pointer="▸" \
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8" \
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc" \
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
}

# fzf with preview
run_fzf_preview() {
    local header="$1"
    local preview_cmd="$2"
    shift 2
    local options=("$@")
    
    if ! has_fzf; then
        echo "Error: fzf is required for this feature" >&2
        return 1
    fi
    
    printf '%s\n' "${options[@]}" | fzf \
        --header="$header" \
        --height=60% \
        --layout=reverse \
        --border=rounded \
        --prompt="❯ " \
        --pointer="▸" \
        --preview="$preview_cmd" \
        --preview-window=right:50%:wrap \
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8" \
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc" \
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
}

# ============================================================================
# Numbered Menu (fallback when fzf not available)
# ============================================================================

# Display numbered menu and get selection
# Usage: numbered_menu "Title" "${options[@]}"
# Returns selected option via stdout
numbered_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    echo ""
    echo -e "${BOLD}$title${NC}"
    echo -e "${DIM}$(repeat_char "─" 50)${NC}"
    echo ""
    
    local i=1
    for opt in "${options[@]}"; do
        printf "  ${CYAN}[%2d]${NC} %s\n" "$i" "$opt"
        ((i++))
    done
    echo ""
    
    local selection
    read -rp "$(echo -e "${COLOR_ACCENT:-$CYAN}>${NC} Enter number: ")" selection
    
    if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#options[@]})); then
        echo "${options[$((selection-1))]}"
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Shell Reload Prompt
# ============================================================================

# Prompt to reload shell
prompt_shell_reload() {
    local message="${1:-Changes require shell reload to take effect.}"
    
    echo ""
    echo -e "${YELLOW}$message${NC}"
    echo ""
    
    if confirm_action "Reload shell now?" "n"; then
        echo "Reloading shell..."
        exec "$SHELL"
    else
        echo -e "${DIM}Run 'exec \$SHELL' to apply changes later.${NC}"
    fi
}

# Check if shell reload is needed and prompt
maybe_reload_shell() {
    local needs_reload="$1"
    
    if [[ "$needs_reload" == "true" ]]; then
        prompt_shell_reload
    fi
}

# ============================================================================
# Progress and Spinners
# ============================================================================

# Simple spinner for async operations
spinner() {
    local pid="$1"
    local message="${2:-Working...}"
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    echo -n "$message "
    
    while kill -0 "$pid" 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf "\r$message ${spinstr:$i:1}"
            sleep 0.1
        done
    done
    
    printf "\r$message done!  \n"
}

# Progress bar
progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-40}"
    
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" "$percent"
}

# ============================================================================
# Banners and Headers
# ============================================================================

# LabRat ASCII banner (compact)
show_labrat_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ╦  ╔═╗╔╗ ╦═╗╔═╗╔╦╗
    ║  ╠═╣╠╩╗╠╦╝╠═╣ ║ 
    ╩═╝╩ ╩╚═╝╩╚═╩ ╩ ╩ 
EOF
    echo -e "${NC}"
}

# Menu header
show_menu_header() {
    local subtitle="${1:-Shell Configuration}"
    
    clear_screen
    echo -e "${CYAN}${BOLD}"
    echo "  🐀 LabRat Menu"
    echo -e "${NC}${DIM}  $subtitle${NC}"
    echo ""
}

# ============================================================================
# Utility Functions
# ============================================================================

# Truncate string with ellipsis
truncate_string() {
    local str="$1"
    local max_len="$2"
    
    if [[ ${#str} -gt $max_len ]]; then
        echo "${str:0:$((max_len-3))}..."
    else
        echo "$str"
    fi
}

# Pad string to length
pad_string() {
    local str="$1"
    local len="$2"
    local align="${3:-left}"
    
    local str_len=${#str}
    local padding=$((len - str_len))
    
    if ((padding <= 0)); then
        echo "$str"
        return
    fi
    
    case "$align" in
        left)
            printf "%-${len}s" "$str"
            ;;
        right)
            printf "%${len}s" "$str"
            ;;
        center)
            local left_pad=$((padding / 2))
            local right_pad=$((padding - left_pad))
            printf "%*s%s%*s" "$left_pad" "" "$str" "$right_pad" ""
            ;;
    esac
}

# Wait for any key
wait_for_key() {
    local message="${1:-Press any key to continue...}"
    echo -e "${DIM}$message${NC}"
    read -rsn1
}

# Pause with countdown
pause_countdown() {
    local seconds="${1:-3}"
    local message="${2:-Continuing in}"
    
    for ((i=seconds; i>0; i--)); do
        printf "\r%s %d... " "$message" "$i"
        sleep 1
    done
    printf "\r%*s\r" "$((${#message} + 10))" ""
}
