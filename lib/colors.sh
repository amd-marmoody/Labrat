#!/usr/bin/env bash
#
# LabRat - Color and formatting definitions
#

# Only enable colors if we're in an interactive terminal
if [[ -t 1 ]] && [[ -t 2 ]]; then
    COLORS_ENABLED=true
else
    COLORS_ENABLED=false
fi

# Allow forcing colors on/off
if [[ "${LABRAT_FORCE_COLOR:-}" == "1" ]]; then
    COLORS_ENABLED=true
elif [[ "${LABRAT_NO_COLOR:-}" == "1" ]] || [[ "${NO_COLOR:-}" == "1" ]]; then
    COLORS_ENABLED=false
fi

if [[ "$COLORS_ENABLED" == true ]]; then
    # Basic Colors
    BLACK='\033[0;30m'
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[0;37m'
    
    # Aliases
    PURPLE='\033[0;35m'

    # Bright Colors
    BRIGHT_BLACK='\033[0;90m'
    BRIGHT_RED='\033[0;91m'
    BRIGHT_GREEN='\033[0;92m'
    BRIGHT_YELLOW='\033[0;93m'
    BRIGHT_BLUE='\033[0;94m'
    BRIGHT_MAGENTA='\033[0;95m'
    BRIGHT_CYAN='\033[0;96m'
    BRIGHT_WHITE='\033[0;97m'

    # Text Styles
    BOLD='\033[1m'
    DIM='\033[2m'
    ITALIC='\033[3m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    HIDDEN='\033[8m'
    STRIKETHROUGH='\033[9m'

    # Reset
    NC='\033[0m'
    RESET='\033[0m'

    # Background Colors
    BG_BLACK='\033[40m'
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    BG_BLUE='\033[44m'
    BG_MAGENTA='\033[45m'
    BG_CYAN='\033[46m'
    BG_WHITE='\033[47m'
else
    # No colors
    BLACK=''
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    PURPLE=''
    BRIGHT_BLACK=''
    BRIGHT_RED=''
    BRIGHT_GREEN=''
    BRIGHT_YELLOW=''
    BRIGHT_BLUE=''
    BRIGHT_MAGENTA=''
    BRIGHT_CYAN=''
    BRIGHT_WHITE=''
    BOLD=''
    DIM=''
    ITALIC=''
    UNDERLINE=''
    BLINK=''
    REVERSE=''
    HIDDEN=''
    STRIKETHROUGH=''
    NC=''
    RESET=''
    BG_BLACK=''
    BG_RED=''
    BG_GREEN=''
    BG_YELLOW=''
    BG_BLUE=''
    BG_MAGENTA=''
    BG_CYAN=''
    BG_WHITE=''
fi

# ============================================================================
# Semantic Colors (use these in your scripts)
# ============================================================================

COLOR_INFO="$BLUE"
COLOR_SUCCESS="$GREEN"
COLOR_WARN="$YELLOW"
COLOR_ERROR="$RED"
COLOR_DEBUG="$BRIGHT_BLACK"
COLOR_HEADER="$CYAN"
COLOR_ACCENT="$MAGENTA"

# ============================================================================
# Box Drawing Characters
# ============================================================================

BOX_HORIZONTAL="═"
BOX_VERTICAL="║"
BOX_TOP_LEFT="╔"
BOX_TOP_RIGHT="╗"
BOX_BOTTOM_LEFT="╚"
BOX_BOTTOM_RIGHT="╝"
BOX_T_DOWN="╦"
BOX_T_UP="╩"
BOX_T_RIGHT="╠"
BOX_T_LEFT="╣"
BOX_CROSS="╬"

# Light box drawing
BOX_LIGHT_HORIZONTAL="─"
BOX_LIGHT_VERTICAL="│"
BOX_LIGHT_TOP_LEFT="┌"
BOX_LIGHT_TOP_RIGHT="┐"
BOX_LIGHT_BOTTOM_LEFT="└"
BOX_LIGHT_BOTTOM_RIGHT="┘"

# ============================================================================
# Symbols
# ============================================================================

SYMBOL_CHECK="✓"
SYMBOL_CROSS="✗"
SYMBOL_ARROW="→"
SYMBOL_BULLET="•"
SYMBOL_STAR="★"
SYMBOL_WARNING="⚠"
SYMBOL_INFO="ℹ"
SYMBOL_QUESTION="?"
SYMBOL_GEAR="⚙"
SYMBOL_PACKAGE="📦"
SYMBOL_ROCKET="🚀"
SYMBOL_RAT="🐀"
