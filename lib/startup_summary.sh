#!/usr/bin/env bash
#
# LabRat - Shell Startup Summary
# Displays keybinds and SSH keys on shell startup
#

# Source dependencies
LABRAT_LIB_DIR="${LABRAT_LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}"
source "${LABRAT_LIB_DIR}/colors.sh"
source "${LABRAT_LIB_DIR}/state.sh"

# ============================================================================
# SSH Key Detection
# ============================================================================

# Get count of loaded SSH keys
get_loaded_ssh_key_count() {
    if command -v ssh-add &>/dev/null; then
        local count
        count=$(ssh-add -l 2>/dev/null | grep -c "SHA256" || echo 0)
        echo "$count"
    else
        echo "0"
    fi
}

# Get names of loaded SSH keys (from comment field)
get_loaded_ssh_key_names() {
    if command -v ssh-add &>/dev/null; then
        ssh-add -l 2>/dev/null | awk '{print $3}' | xargs -I{} basename {} 2>/dev/null | tr '\n' ', ' | sed 's/, $//'
    fi
}

# Get managed SSH keys from labrat directory
get_managed_ssh_keys() {
    local key_dir="$HOME/.ssh/labrat"
    if [[ -d "$key_dir" ]]; then
        local keys=""
        for key in "$key_dir"/*; do
            if [[ -f "$key" ]] && [[ "$key" != *.pub ]]; then
                local name=$(basename "$key")
                if [[ -n "$keys" ]]; then
                    keys+=", "
                fi
                keys+="$name"
            fi
        done
        echo "$keys"
    fi
}

# ============================================================================
# Active Module Detection
# ============================================================================

# Get list of active modules with their keybinds
get_active_keybinds() {
    local keybinds=""
    
    # Check atuin (owns Ctrl+R for history)
    if command -v atuin &>/dev/null && is_module_enabled "atuin"; then
        keybinds+="Ctrl+R (atuin) "
    fi
    
    # Check fzf (Ctrl+H for history, Ctrl+T for files)
    if command -v fzf &>/dev/null && is_module_enabled "fzf"; then
        keybinds+="• Ctrl+H (fzf history) • Ctrl+T (files) "
    fi
    
    # Check zoxide
    if command -v zoxide &>/dev/null && is_module_enabled "zoxide"; then
        keybinds+="• z <dir> "
    fi
    
    # Check broot
    if command -v broot &>/dev/null && is_module_enabled "broot"; then
        keybinds+="• br (files) "
    fi
    
    # Trim and clean up
    keybinds=$(echo "$keybinds" | sed 's/^• //' | sed 's/ $//')
    
    echo "$keybinds"
}

# Get current prompt type
get_prompt_status() {
    if is_module_enabled "starship" && command -v starship &>/dev/null; then
        local preset=$(get_current_starship_preset)
        echo "starship ($preset)"
    else
        echo "default"
    fi
}

# Get current tmux theme if inside tmux
get_tmux_status() {
    if [[ -n "${TMUX:-}" ]]; then
        local theme=$(get_current_tmux_theme)
        echo "tmux: $theme"
    fi
}

# ============================================================================
# Summary Display Functions
# ============================================================================

# Compact one-line summary
show_compact_summary() {
    local keybinds
    keybinds=$(get_active_keybinds)
    
    local ssh_count
    ssh_count=$(get_loaded_ssh_key_count)
    
    echo -e "${DIM}🐀 Alt+M menu${NC} ${DIM}│${NC} $keybinds ${DIM}│${NC} ${DIM}SSH: ${ssh_count} key(s)${NC}"
}

# Box-style summary (more detailed)
show_boxed_summary() {
    local width=65
    
    # Build status line
    local prompt_status
    prompt_status=$(get_prompt_status)
    
    local keybinds
    keybinds=$(get_active_keybinds)
    
    local ssh_count
    ssh_count=$(get_loaded_ssh_key_count)
    local ssh_names
    ssh_names=$(get_managed_ssh_keys)
    
    # Draw compact box
    echo -e "${DIM}┌$(printf '─%.0s' $(seq 1 $width))┐${NC}"
    
    # Header line
    printf "${DIM}│${NC} ${CYAN}🐀 LabRat${NC} ${DIM}•${NC} ${BOLD}Alt+M${NC} for menu"
    printf "%*s${DIM}│${NC}\n" $((width - 30)) ""
    
    # Separator
    echo -e "${DIM}├$(printf '─%.0s' $(seq 1 $width))┤${NC}"
    
    # Keybinds line
    if [[ -n "$keybinds" ]]; then
        local kb_line="Hotkeys: $keybinds"
        local kb_len=${#kb_line}
        printf "${DIM}│${NC} %s%*s${DIM}│${NC}\n" "$kb_line" $((width - kb_len - 1)) ""
    fi
    
    # SSH line
    local ssh_line
    if [[ "$ssh_count" -gt 0 ]]; then
        if [[ -n "$ssh_names" ]]; then
            ssh_line="SSH: ${ssh_count} key(s) loaded (${ssh_names})"
        else
            ssh_line="SSH: ${ssh_count} key(s) loaded"
        fi
    else
        ssh_line="SSH: no keys loaded"
    fi
    # Truncate if too long
    if [[ ${#ssh_line} -gt $((width - 2)) ]]; then
        ssh_line="${ssh_line:0:$((width - 5))}..."
    fi
    printf "${DIM}│${NC} %s%*s${DIM}│${NC}\n" "$ssh_line" $((width - ${#ssh_line} - 1)) ""
    
    # Bottom
    echo -e "${DIM}└$(printf '─%.0s' $(seq 1 $width))┘${NC}"
}

# Minimal single line
show_minimal_summary() {
    echo -e "${DIM}🐀 LabRat ready • Alt+M for menu${NC}"
}

# ============================================================================
# Main Entry Point
# ============================================================================

# Show startup summary (called from shell rc files)
labrat_startup_summary() {
    # Check if we should show
    if ! should_show_startup_summary; then
        return 0
    fi
    
    # Get display style preference
    local style
    style=$(get_preference "summary_style" "compact")
    
    case "$style" in
        boxed)
            show_boxed_summary
            ;;
        minimal)
            show_minimal_summary
            ;;
        compact|*)
            show_compact_summary
            ;;
    esac
    
    # Mark as shown for this session
    mark_summary_shown
}

# Set summary display style
set_summary_style() {
    local style="$1"
    case "$style" in
        boxed|compact|minimal)
            save_preference "summary_style" "$style"
            echo "Summary style set to: $style"
            ;;
        *)
            echo "Invalid style. Choose: boxed, compact, minimal"
            return 1
            ;;
    esac
}

# ============================================================================
# Alt+M Hotkey Setup
# ============================================================================

# Generate bash hotkey binding
generate_bash_hotkey() {
    cat << 'BASH_HOTKEY'
# LabRat menu hotkey (Alt+M)
if [[ $- == *i* ]]; then
    bind '"\em":"labrat-menu\n"'
fi
BASH_HOTKEY
}

# Generate zsh hotkey binding
generate_zsh_hotkey() {
    cat << 'ZSH_HOTKEY'
# LabRat menu hotkey (Alt+M)
labrat-menu-widget() {
    BUFFER="labrat-menu"
    zle accept-line
}
zle -N labrat-menu-widget
bindkey '\em' labrat-menu-widget
ZSH_HOTKEY
}

# Generate fish hotkey binding
generate_fish_hotkey() {
    cat << 'FISH_HOTKEY'
# LabRat menu hotkey (Alt+M)
bind \em 'commandline -r "labrat-menu"; commandline -f execute'
FISH_HOTKEY
}

# ============================================================================
# Integration Snippet Generation
# ============================================================================

# Generate full startup snippet for bash
generate_bash_startup_snippet() {
    cat << 'BASH_STARTUP'
# LabRat startup summary and hotkey
if command -v labrat-menu &>/dev/null; then
    # Alt+M hotkey
    if [[ $- == *i* ]]; then
        bind '"\em":"labrat-menu\n"'
    fi
fi

# Show startup summary (respects LABRAT_QUIET and session state)
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/labrat/lib/startup_summary.sh" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/labrat/lib/startup_summary.sh"
    labrat_startup_summary
elif type labrat_startup_summary &>/dev/null; then
    labrat_startup_summary
fi
BASH_STARTUP
}

# Generate full startup snippet for zsh
generate_zsh_startup_snippet() {
    cat << 'ZSH_STARTUP'
# LabRat startup summary and hotkey
if (( $+commands[labrat-menu] )); then
    # Alt+M hotkey widget
    labrat-menu-widget() {
        BUFFER="labrat-menu"
        zle accept-line
    }
    zle -N labrat-menu-widget
    bindkey '\em' labrat-menu-widget
fi

# Show startup summary
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/labrat/lib/startup_summary.sh" ]]; then
    source "${XDG_CONFIG_HOME:-$HOME/.config}/labrat/lib/startup_summary.sh"
    labrat_startup_summary
elif (( $+functions[labrat_startup_summary] )); then
    labrat_startup_summary
fi
ZSH_STARTUP
}

# Generate full startup snippet for fish
generate_fish_startup_snippet() {
    cat << 'FISH_STARTUP'
# LabRat startup summary and hotkey
if command -v labrat-menu &>/dev/null
    # Alt+M hotkey
    bind \em 'commandline -r "labrat-menu"; commandline -f execute'
end

# Show startup summary
if test -f "$HOME/.config/labrat/lib/startup_summary.sh"
    # Fish can't source bash, so we call the summary function if available
    if type -q labrat_startup_summary
        labrat_startup_summary
    end
end
FISH_STARTUP
}
