#!/usr/bin/env bash
#
# LabRat Module: fzf
# Fuzzy finder for command-line
#

# Module metadata
FZF_REPO="https://github.com/junegunn/fzf.git"
FZF_DIR="$HOME/.fzf"

# ============================================================================
# Installation
# ============================================================================

install_fzf() {
    log_step "Installing fzf..."
    
    local installed_version=""
    
    # Clone or update fzf
    if [[ -d "$FZF_DIR" ]]; then
        log_info "fzf directory exists, updating..."
        (cd "$FZF_DIR" && git pull --quiet)
    else
        git_clone_or_update "$FZF_REPO" "$FZF_DIR" "master"
    fi
    
    # Run fzf install script
    log_step "Running fzf installer..."
    "$FZF_DIR/install" --all --no-update-rc --no-bash --no-zsh --no-fish
    
    # Install binary to local bin
    if [[ -f "$FZF_DIR/bin/fzf" ]]; then
        cp "$FZF_DIR/bin/fzf" "$LABRAT_BIN_DIR/"
        cp "$FZF_DIR/bin/fzf-tmux" "$LABRAT_BIN_DIR/" 2>/dev/null || true
    fi
    
    # Get version
    installed_version=$(fzf --version | awk '{print $1}')
    log_info "fzf version: $installed_version"
    
    # Setup shell integration
    setup_fzf_integration
    
    # Mark as installed
    mark_module_installed "fzf" "$installed_version"
    
    log_success "fzf installed and configured!"
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_fzf_integration() {
    log_step "Setting up fzf shell integration..."
    
    # Create fzf config
    local fzf_config="$HOME/.fzf.bash"
    cat > "$fzf_config" << 'FZF_BASH'
# fzf configuration (added by LabRat)

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings (Ctrl+T for files, Alt+C for directories)
# Note: We don't source the default key-bindings.bash because it uses Ctrl+R
# which conflicts with atuin. Instead we define custom bindings.

# Ctrl+T - File search
__fzf_select__() {
  local cmd opts
  cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | cut -b3-"}"
  opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore --reverse ${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}"
  eval "$cmd" | FZF_DEFAULT_OPTS="$opts" fzf -m "$@" | while read -r item; do
    printf '%q ' "$item"
  done
}

fzf-file-widget() {
  local selected="$(__fzf_select__ "$@")"
  READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}$selected${READLINE_LINE:$READLINE_POINT}"
  READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
bind -x '"\C-t": fzf-file-widget'

# Alt+C - Directory search
__fzf_cd__() {
  local cmd opts dir
  cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | cut -b3-"}"
  opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore --reverse ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}"
  dir=$(eval "$cmd" | FZF_DEFAULT_OPTS="$opts" fzf +m) && printf 'cd -- %q' "$dir"
}

fzf-cd-widget() {
  local result
  result="$(__fzf_cd__)"
  if [[ -n "$result" ]]; then
    eval "$result"
  fi
}
bind -x '"\ec": fzf-cd-widget'

# Alt+R - fzf history search (avoids conflict with atuin's Ctrl+R)
# Note: We use Alt+R instead of Ctrl+H because Ctrl+H is often backspace
__fzf_history__() {
  local output opts
  opts="--height ${FZF_TMUX_HEIGHT:-40%} --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort ${FZF_CTRL_R_OPTS-} +m --read0"
  output=$(
    builtin fc -lnr -2147483648 |
      last_hist=$(HISTTIMEFORMAT='' builtin history 1) perl -n -l0 -e 'BEGIN { getc; $/ = "\n\t"; $LAST = shift @ARGV } s/^[ *]//; print if !$seen{$_}++ && $_ ne $LAST' "$last_hist" |
      FZF_DEFAULT_OPTS="$opts" fzf --query "$READLINE_LINE"
  ) || return
  READLINE_LINE=${output#*$'\t'}
  if [[ -z "$READLINE_POINT" ]]; then
    echo "$READLINE_LINE"
  else
    READLINE_POINT=0x7fffffff
  fi
}
bind -x '"\er": __fzf_history__'

# Default options
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd if available for file finding
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview file content using bat
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="
        --preview 'bat --style=numbers --color=always --line-range :500 {}'
        --preview-window 'right:50%:wrap'
    "
fi
FZF_BASH

    # Create zsh version
    local fzf_zsh="$HOME/.fzf.zsh"
    cat > "$fzf_zsh" << 'FZF_ZSH'
# fzf configuration (added by LabRat)

# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
    PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Auto-completion
[[ $- == *i* ]] && source "$HOME/.fzf/shell/completion.zsh" 2> /dev/null

# Key bindings (Ctrl+T for files, Alt+C for directories, Alt+R for history)
# Note: We don't source the default key-bindings.zsh because it uses Ctrl+R
# which conflicts with atuin. Instead we define custom bindings.

# Ctrl+T - File search
fzf-file-widget() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune -o -type f -print -o -type d -print -o -type l -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local item
  eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" fzf -m "$@" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}
zle -N fzf-file-widget
bindkey '^T' fzf-file-widget

# Alt+C - Directory search
fzf-cd-widget() {
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . -mindepth 1 \\( -path '*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' -o -fstype 'proc' \\) -prune -o -type d -print 2> /dev/null | cut -b3-"}"
  setopt localoptions pipefail no_aliases 2> /dev/null
  local dir="$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore ${FZF_DEFAULT_OPTS-} ${FZF_ALT_C_OPTS-}" fzf +m)"
  if [[ -z "$dir" ]]; then
    zle redisplay
    return 0
  fi
  zle push-line
  BUFFER="cd -- ${(q)dir}"
  zle accept-line
  local ret=$?
  unset dir
  zle reset-prompt
  return $ret
}
zle -N fzf-cd-widget
bindkey '\ec' fzf-cd-widget

# Alt+R - fzf history search (avoids conflict with atuin's Ctrl+R)
# Note: We use Alt+R instead of Ctrl+H because Ctrl+H is often backspace
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected="$(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} ${FZF_DEFAULT_OPTS-} -n2..,.. --scheme=history --bind=ctrl-r:toggle-sort ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m" fzf)"
  local ret=$?
  if [ -n "$selected" ]; then
    num=$(awk '{print $1}' <<< "$selected")
    if [[ "$num" =~ ^[1-9][0-9]*$ ]]; then
      zle vi-fetch-history -n $num
    else
      BUFFER="$selected"
    fi
  fi
  zle reset-prompt
  return $ret
}
zle -N fzf-history-widget
bindkey '\er' fzf-history-widget

# Default options
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

# Use fd if available
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Preview with bat
if command -v bat &> /dev/null; then
    export FZF_CTRL_T_OPTS="
        --preview 'bat --style=numbers --color=always --line-range :500 {}'
        --preview-window 'right:50%:wrap'
    "
fi
FZF_ZSH

    # Add to bashrc if needed
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]] && ! grep -q '\.fzf\.bash' "$bashrc"; then
        echo "" >> "$bashrc"
        echo "# fzf (added by LabRat)" >> "$bashrc"
        echo '[ -f ~/.fzf.bash ] && source ~/.fzf.bash' >> "$bashrc"
    fi
    
    log_success "fzf shell integration configured"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_fzf() {
    log_step "Uninstalling fzf..."
    
    # Remove fzf directory
    if confirm "Remove fzf installation (~/.fzf)?" "y"; then
        rm -rf "$FZF_DIR"
    fi
    
    # Remove config files
    rm -f "$HOME/.fzf.bash"
    rm -f "$HOME/.fzf.zsh"
    
    # Remove from PATH
    rm -f "$LABRAT_BIN_DIR/fzf"
    rm -f "$LABRAT_BIN_DIR/fzf-tmux"
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/fzf"
    
    log_success "fzf removed"
}
