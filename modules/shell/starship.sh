#!/usr/bin/env bash
#
# LabRat Module: starship
# Cross-shell prompt with customization
#

# Module metadata
STARSHIP_INSTALL_URL="https://starship.rs/install.sh"

# ============================================================================
# Installation
# ============================================================================

install_starship() {
    log_step "Installing starship prompt..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists starship; then
        installed_version=$(starship --version | awk '{print $2}')
        log_info "starship already installed (version: $installed_version)"
        
        if ! confirm "Reinstall/update starship?" "n"; then
            deploy_starship_config
            mark_module_installed "starship" "$installed_version"
            return 0
        fi
    fi
    
    # Install starship
    install_starship_binary
    
    # Get installed version
    installed_version=$(starship --version | awk '{print $2}')
    log_info "starship version: $installed_version"
    
    # Deploy configuration
    deploy_starship_config
    
    # Setup shell integration
    setup_shell_integration
    
    # Mark as installed
    mark_module_installed "starship" "$installed_version"
    
    log_success "starship installed and configured!"
}

# ============================================================================
# Binary Installation
# ============================================================================

install_starship_binary() {
    log_step "Downloading and installing starship..."
    
    local github_repo="starship/starship"
    local release_url="https://api.github.com/repos/${github_repo}/releases/latest"
    local download_url=""
    local arch_pattern=""
    
    # Determine architecture pattern for download URL
    case "$ARCH" in
        amd64|x86_64)
            arch_pattern="x86_64-unknown-linux-gnu"
            ;;
        arm64|aarch64)
            arch_pattern="aarch64-unknown-linux-gnu"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
    
    # Get latest version tag
    local version
    version=$(curl -fsSL "$release_url" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/"tag_name": *"\([^"]*\)"/\1/')
    
    if [[ -n "$version" ]]; then
        # Construct download URL for tarball
        download_url="https://github.com/${github_repo}/releases/download/${version}/starship-${arch_pattern}.tar.gz"
        log_debug "Download URL: $download_url"
    else
        log_error "Could not determine latest starship version"
        return 1
    fi
    
    local extract_dir="${LABRAT_CACHE_DIR}/starship"
    ensure_dir "$extract_dir"
    
    if download_and_extract "$download_url" "$extract_dir" "Downloading starship"; then
        # Copy binary
        if [[ -f "$extract_dir/starship" ]]; then
            cp "$extract_dir/starship" "$LABRAT_BIN_DIR/starship"
            chmod +x "$LABRAT_BIN_DIR/starship"
            log_success "starship installed to $LABRAT_BIN_DIR"
        else
            log_error "Failed to find starship binary after extraction"
            return 1
        fi
    else
        log_error "Failed to download starship"
        return 1
    fi
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_starship_config() {
    local config_source="${LABRAT_CONFIGS_DIR}/starship/starship.toml"
    local config_dir="$HOME/.config"
    local config_target="$config_dir/starship.toml"
    
    log_step "Deploying starship configuration..."
    
    ensure_dir "$config_dir"
    
    # Backup existing config
    if [[ -f "$config_target" ]] && [[ ! -L "$config_target" ]]; then
        backup_file "$config_target"
    fi
    
    # Create symlink or copy config
    if [[ -f "$config_source" ]]; then
        safe_symlink "$config_source" "$config_target"
        log_success "starship config deployed"
    else
        log_warn "Config source not found, creating default config"
        create_default_starship_config "$config_target"
    fi
}

create_default_starship_config() {
    local config_file="$1"
    
    cat > "$config_file" << 'STARSHIP_CONFIG'
# ============================================================================
# LabRat Starship Configuration
# Your trusty environment for every test cage 🐀
# ============================================================================

# Timeout for commands executed by starship (in milliseconds)
command_timeout = 1000

# Add a blank line before the start of the prompt
add_newline = true

# Main prompt format
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$python\
$nodejs\
$golang\
$rust\
$docker_context\
$kubernetes\
$cmd_duration\
$line_break\
$character"""

# Right prompt format
right_format = """$time"""

# ----------------------------------------------------------------------------
# Prompt Character
# ----------------------------------------------------------------------------

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

# ----------------------------------------------------------------------------
# Directory
# ----------------------------------------------------------------------------

[directory]
truncation_length = 5
truncate_to_repo = true
style = "bold cyan"
format = "[$path]($style)[$read_only]($read_only_style) "
read_only = " 🔒"
home_symbol = "~"

[directory.substitutions]
"Documents" = "󰈙"
"Downloads" = ""
"Music" = ""
"Pictures" = ""
"projects" = ""

# ----------------------------------------------------------------------------
# Username and Hostname
# ----------------------------------------------------------------------------

[username]
show_always = true
style_user = "bold blue"
style_root = "bold red"
format = "[🐀 $user]($style)"

[hostname]
ssh_only = false
style = "bold yellow"
format = "[@$hostname]($style) "
disabled = false

# ----------------------------------------------------------------------------
# Git
# ----------------------------------------------------------------------------

[git_branch]
symbol = " "
style = "bold purple"
format = "[$symbol$branch(:$remote_branch)]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"
conflicted = "="
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
up_to_date = ""
untracked = "?${count}"
stashed = "*${count}"
modified = "!${count}"
staged = "+${count}"
renamed = "»${count}"
deleted = "✘${count}"

[git_commit]
commit_hash_length = 7
style = "bold green"
format = "[\\($hash$tag\\)]($style) "
tag_symbol = " 🏷"

[git_state]
format = '[\($state( $progress_current of $progress_total)\)]($style) '

# ----------------------------------------------------------------------------
# Languages
# ----------------------------------------------------------------------------

[python]
symbol = " "
style = "bold yellow"
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'
python_binary = ["python3", "python"]

[nodejs]
symbol = " "
style = "bold green"
format = "[$symbol($version )]($style)"

[golang]
symbol = " "
style = "bold cyan"
format = "[$symbol($version )]($style)"

[rust]
symbol = "🦀 "
style = "bold red"
format = "[$symbol($version )]($style)"

[java]
symbol = " "
style = "bold red"
format = "[$symbol($version )]($style)"

[ruby]
symbol = " "
style = "bold red"
format = "[$symbol($version )]($style)"

# ----------------------------------------------------------------------------
# Cloud / Containers
# ----------------------------------------------------------------------------

[docker_context]
symbol = " "
style = "bold blue"
format = "[$symbol$context]($style) "
only_with_files = true

[kubernetes]
symbol = "☸ "
style = "bold blue"
format = '[$symbol$context( \($namespace\))]($style) '
disabled = false

[aws]
symbol = "  "
style = "bold yellow"
format = '[$symbol($profile )(\($region\) )]($style)'
disabled = true

# ----------------------------------------------------------------------------
# System / Performance
# ----------------------------------------------------------------------------

[cmd_duration]
min_time = 2000
style = "bold yellow"
format = "[⏱ $duration]($style) "
show_milliseconds = false

[time]
disabled = false
format = '[\[$time\]](dimmed white)'
time_format = "%H:%M"
utc_time_offset = "local"

[memory_usage]
disabled = true
threshold = 75
symbol = "󰍛 "
style = "bold dimmed white"
format = "$symbol[${ram}( | ${swap})]($style) "

[battery]
disabled = true

[[battery.display]]
threshold = 20
style = "bold red"

# ----------------------------------------------------------------------------
# Package Managers
# ----------------------------------------------------------------------------

[package]
symbol = "📦 "
style = "bold 208"
format = "[$symbol$version]($style) "
disabled = true

# ----------------------------------------------------------------------------
# Nerd Font Symbols Preset
# ----------------------------------------------------------------------------

[os]
disabled = true

[os.symbols]
Ubuntu = " "
Debian = " "
CentOS = " "
Fedora = " "
Alpine = " "
Arch = " "
STARSHIP_CONFIG

    log_success "Default starship config created"
}

# ============================================================================
# Shell Integration
# ============================================================================

setup_shell_integration() {
    log_step "Setting up shell integration..."
    
    # Bash integration
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        if ! grep -q 'starship init bash' "$bashrc"; then
            log_info "Adding starship to .bashrc"
            {
                echo ""
                echo "# LabRat PATH setup"
                echo 'export PATH="$HOME/.local/bin:$PATH"'
                echo ""
                echo "# Starship prompt (added by LabRat)"
                echo "# Starship is OFF by default. Run 'starship-on' to enable."
                echo "# Toggle: starship-on / starship-off"
                echo ''
                echo '# Toggle starship prompt on/off'
                echo 'starship-off() {'
                echo '    export STARSHIP_DISABLE=1'
                echo '    unset STARSHIP_SESSION_KEY'
                echo '    PROMPT_COMMAND=""'
                echo '    PS1="\u@\h:\w\$ "'
                echo '    echo "Starship disabled."'
                echo '}'
                echo 'starship-on() {'
                echo '    unset STARSHIP_DISABLE'
                echo '    if command -v starship &>/dev/null; then'
                echo '        eval "$(starship init bash)"'
                echo '        # Reinitialize zoxide after starship (must be last)'
                echo '        command -v zoxide &>/dev/null && eval "$(zoxide init bash)"'
                echo '        echo "Starship enabled."'
                echo '    else'
                echo '        echo "Starship not installed."'
                echo '    fi'
                echo '}'
            } >> "$bashrc"
        fi
    fi
    
    # Zsh integration (usually handled by .zshrc, but add if needed)
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        if ! grep -q 'starship init zsh' "$zshrc"; then
            log_info "Adding starship to .zshrc"
            {
                echo ""
                echo "# Starship prompt (added by LabRat)"
                echo "# Toggle: starship-on / starship-off"
                echo 'if [[ -z "$STARSHIP_DISABLE" ]] && command -v starship &>/dev/null; then'
                echo '    eval "$(starship init zsh)"'
                echo 'fi'
                echo ''
                echo '# Toggle starship prompt on/off'
                echo 'starship-off() { export STARSHIP_DISABLE=1; exec zsh; }'
                echo 'starship-on() { unset STARSHIP_DISABLE; exec zsh; }'
            } >> "$zshrc"
        fi
    fi
    
    # Fish integration
    local fish_config="$HOME/.config/fish/config.fish"
    if [[ -f "$fish_config" ]]; then
        if ! grep -q 'starship init fish' "$fish_config"; then
            log_info "Adding starship to fish config"
            {
                echo ""
                echo "# Starship prompt (added by LabRat)"
                echo 'if not set -q STARSHIP_DISABLE; and command -v starship &>/dev/null'
                echo '    starship init fish | source'
                echo 'end'
                echo ''
                echo '# Toggle starship prompt on/off'
                echo 'function starship-off; set -gx STARSHIP_DISABLE 1; exec fish; end'
                echo 'function starship-on; set -e STARSHIP_DISABLE; exec fish; end'
            } >> "$fish_config"
        fi
    fi
    
    log_success "Shell integration configured"
    log_info "Toggle starship: ${BOLD}starship-on${NC} / ${BOLD}starship-off${NC}"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_starship() {
    log_step "Uninstalling starship..."
    
    # Remove binary
    if [[ -f "$LABRAT_BIN_DIR/starship" ]]; then
        rm "$LABRAT_BIN_DIR/starship"
    fi
    
    # Remove config
    if [[ -L "$HOME/.config/starship.toml" ]]; then
        rm "$HOME/.config/starship.toml"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/starship"
    
    log_success "starship removed"
    log_info "Note: Shell integration lines may need to be manually removed from shell configs"
}
