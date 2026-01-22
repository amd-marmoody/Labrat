#!/usr/bin/env bash
#
# LabRat Module: neovim
# Hyperextensible Vim-based text editor with modern config
#

# Module metadata
NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
NVIM_RELEASE_URL="https://github.com/neovim/neovim/releases/download"
NVIM_MIN_VERSION="0.9.0"

# ============================================================================
# Installation
# ============================================================================

install_neovim() {
    log_step "Installing neovim..."
    
    local installed_version=""
    local install_method="binary"  # binary, package, appimage
    
    # Determine best installation method
    case "$OS_FAMILY" in
        debian)
            # Ubuntu repos often have outdated neovim
            if [[ "$OS" == "ubuntu" ]]; then
                install_method="binary"
            else
                install_method="package"
            fi
            ;;
        rhel)
            install_method="binary"
            ;;
        *)
            install_method="package"
            ;;
    esac
    
    # Check if already installed with sufficient version
    if command_exists nvim; then
        installed_version=$(nvim --version | head -1 | grep -oP 'v\K[\d.]+')
        log_info "neovim already installed (version: $installed_version)"
        
        if version_gte "$installed_version" "$NVIM_MIN_VERSION"; then
            log_info "Version meets minimum requirement ($NVIM_MIN_VERSION)"
            if ! confirm "Reinstall/update neovim?" "n"; then
                deploy_neovim_config
                mark_module_installed "neovim" "$installed_version"
                return 0
            fi
        else
            log_warn "Version is below minimum ($NVIM_MIN_VERSION), will upgrade"
        fi
    fi
    
    # Install neovim
    case "$install_method" in
        binary)
            install_neovim_binary
            ;;
        appimage)
            install_neovim_appimage
            ;;
        package)
            install_neovim_package
            ;;
    esac
    
    # Get installed version
    installed_version=$(nvim --version | head -1 | grep -oP 'v\K[\d.]+')
    log_info "neovim version: $installed_version"
    
    # Install dependencies for plugins
    install_neovim_deps
    
    # Deploy configuration
    deploy_neovim_config
    
    # Mark as installed
    mark_module_installed "neovim" "$installed_version"
    
    log_success "neovim installed and configured!"
    log_info "Run ${BOLD}nvim${NC} to start and install plugins automatically"
}

# ============================================================================
# Installation Methods
# ============================================================================

install_neovim_package() {
    log_step "Installing neovim from package manager..."
    
    case "$OS_FAMILY" in
        debian)
            # Add neovim PPA for Ubuntu for newer version
            if [[ "$OS" == "ubuntu" ]]; then
                apt_add_repo "ppa:neovim-ppa/unstable"
            fi
            pkg_install neovim
            ;;
        rhel)
            # EPEL has neovim but often outdated
            pkg_install_if_missing epel-release
            pkg_install neovim
            ;;
        arch)
            pkg_install neovim
            ;;
        *)
            pkg_install neovim
            ;;
    esac
}

install_neovim_binary() {
    log_step "Installing neovim from GitHub releases..."
    
    local download_url=""
    local archive_name=""
    local extract_dir="${LABRAT_CACHE_DIR}/neovim"
    
    # Determine download URL based on architecture
    # Use latest release URL format
    case "$ARCH" in
        amd64|x86_64)
            download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
            archive_name="nvim-linux-x86_64"
            ;;
        arm64|aarch64)
            download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
            archive_name="nvim-linux-arm64"
            ;;
        *)
            log_warn "Unsupported architecture for binary install: $ARCH"
            install_neovim_package
            return
            ;;
    esac
    
    # Download and extract
    ensure_dir "$extract_dir"
    download_and_extract "$download_url" "$extract_dir" "Downloading neovim"
    
    # Install to local bin
    local nvim_bin="${extract_dir}/${archive_name}/bin/nvim"
    
    if [[ -f "$nvim_bin" ]]; then
        cp "$nvim_bin" "$LABRAT_BIN_DIR/nvim"
        chmod +x "$LABRAT_BIN_DIR/nvim"
        
        # Also copy runtime files
        local runtime_dir="${extract_dir}/${archive_name}/share/nvim"
        if [[ -d "$runtime_dir" ]]; then
            ensure_dir "$HOME/.local/share"
            rm -rf "$HOME/.local/share/nvim-runtime"
            cp -r "$runtime_dir" "$HOME/.local/share/nvim-runtime"
        fi
        
        log_success "neovim binary installed to $LABRAT_BIN_DIR"
    else
        log_error "Failed to find nvim binary after extraction"
        return 1
    fi
}

install_neovim_appimage() {
    log_step "Installing neovim AppImage..."
    
    local appimage_path="$LABRAT_BIN_DIR/nvim.appimage"
    
    download_file "$NVIM_APPIMAGE_URL" "$appimage_path" "Downloading neovim AppImage"
    
    chmod +x "$appimage_path"
    
    # Create wrapper script
    cat > "$LABRAT_BIN_DIR/nvim" << EOF
#!/bin/bash
exec "$appimage_path" "\$@"
EOF
    chmod +x "$LABRAT_BIN_DIR/nvim"
    
    log_success "neovim AppImage installed"
}

# ============================================================================
# Dependencies
# ============================================================================

install_neovim_deps() {
    log_step "Installing neovim dependencies..."
    
    # Install dependencies for common plugins
    case "$OS_FAMILY" in
        debian)
            pkg_install \
                build-essential \
                cmake \
                git \
                curl \
                unzip \
                python3 \
                python3-pip \
                python3-venv \
                nodejs \
                npm \
                ripgrep \
                fd-find \
                xclip
            ;;
        rhel)
            pkg_install \
                gcc \
                gcc-c++ \
                make \
                cmake \
                git \
                curl \
                unzip \
                python3 \
                python3-pip \
                nodejs \
                npm \
                ripgrep \
                fd-find \
                xclip
            ;;
    esac
    
    # Install pynvim for Python plugins
    if command_exists pip3; then
        pip3 install --user --quiet pynvim
    fi
    
    # Install neovim npm package for Node.js plugins
    if command_exists npm; then
        npm install -g neovim --quiet 2>/dev/null || true
    fi
    
    log_success "Dependencies installed"
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_neovim_config() {
    local config_source="${LABRAT_CONFIGS_DIR}/neovim"
    local config_target="$HOME/.config/nvim"
    
    log_step "Deploying neovim configuration..."
    
    # Backup existing config
    if [[ -d "$config_target" ]] && [[ ! -L "$config_target" ]]; then
        local backup_path=$(backup_file "$config_target")
        mv "$config_target" "${backup_path}.d"
    fi
    
    # Create symlink or deploy config
    if [[ -d "$config_source" ]]; then
        safe_symlink "$config_source" "$config_target"
        log_success "neovim config deployed"
    else
        log_warn "Config source not found, creating default config"
        create_default_neovim_config "$config_target"
    fi
}

create_default_neovim_config() {
    local config_dir="$1"
    
    ensure_dir "$config_dir"
    
    cat > "$config_dir/init.lua" << 'NVIM_CONFIG'
-- ============================================================================
-- LabRat Neovim Configuration
-- Your trusty environment for every test cage 🐀
-- ============================================================================

-- Leader key (set before lazy.nvim)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ----------------------------------------------------------------------------
-- Options
-- ----------------------------------------------------------------------------

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs and indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Line wrapping
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8

-- Backspace
opt.backspace = "indent,eol,start"

-- Clipboard (use system clipboard)
opt.clipboard = "unnamedplus"

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Consider - as part of word
opt.iskeyword:append("-")

-- Disable swap and backup
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.local/share/nvim/undo")

-- Faster completion
opt.updatetime = 250
opt.timeoutlen = 300

-- Better completion experience
opt.completeopt = "menuone,noselect"

-- Show invisible characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Mouse support
opt.mouse = "a"

-- ----------------------------------------------------------------------------
-- Keymaps
-- ----------------------------------------------------------------------------

local keymap = vim.keymap.set

-- Clear search highlighting
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows with arrows
keymap("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })

-- Move lines up/down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Stay in indent mode
keymap("v", "<", "<gv", { desc = "Indent left" })
keymap("v", ">", ">gv", { desc = "Indent right" })

-- Better paste (don't replace clipboard)
keymap("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Buffer navigation
keymap("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
keymap("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- Save file
keymap("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
keymap("i", "<C-s>", "<Esc><cmd>w<CR>a", { desc = "Save file" })

-- Quit
keymap("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
keymap("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all" })

-- ----------------------------------------------------------------------------
-- Plugin Manager (lazy.nvim)
-- ----------------------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- ----------------------------------------------------------------------------
-- Plugins
-- ----------------------------------------------------------------------------

require("lazy").setup({
    -- Colorscheme
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            vim.cmd.colorscheme("catppuccin-mocha")
        end,
    },

    -- Status line
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup({
                options = {
                    theme = "catppuccin",
                    component_separators = "|",
                    section_separators = "",
                },
            })
        end,
    },

    -- File explorer
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = { width = 35 },
                filters = { dotfiles = false },
            })
            vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
        end,
    },

    -- Fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function()
            local telescope = require("telescope")
            telescope.setup({})
            local builtin = require("telescope.builtin")
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
            vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
            vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
            vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
            vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
        end,
    },

    -- Treesitter (syntax highlighting)
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                ensure_installed = {
                    "bash", "c", "cpp", "go", "java", "javascript", "json",
                    "lua", "markdown", "python", "rust", "typescript", "yaml",
                },
                highlight = { enable = true },
                indent = { enable = true },
            })
        end,
    },

    -- Git signs
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "│" },
                    change = { text = "│" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                },
            })
        end,
    },

    -- Auto pairs
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = true,
    },

    -- Comment toggling
    {
        "numToStr/Comment.nvim",
        config = true,
    },

    -- Which key (keybinding hints)
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            require("which-key").setup({})
        end,
    },

    -- Indent guides
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        config = function()
            require("ibl").setup({
                indent = { char = "│" },
            })
        end,
    },

    -- Better UI
    {
        "stevearc/dressing.nvim",
        config = true,
    },
}, {
    -- Lazy.nvim config
    install = {
        colorscheme = { "catppuccin" },
    },
    checker = {
        enabled = true,
        notify = false,
    },
    change_detection = {
        notify = false,
    },
})

-- ----------------------------------------------------------------------------
-- Autocommands
-- ----------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup("LabRat", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
    group = augroup,
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
    group = augroup,
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

-- Return to last edit position
vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})
NVIM_CONFIG

    log_success "Default neovim config created"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_neovim() {
    log_step "Uninstalling neovim configuration..."
    
    # Remove config
    if [[ -L "$HOME/.config/nvim" ]]; then
        rm "$HOME/.config/nvim"
    fi
    
    # Remove binary if installed by us
    if [[ -f "$LABRAT_BIN_DIR/nvim" ]]; then
        rm "$LABRAT_BIN_DIR/nvim"
    fi
    if [[ -f "$LABRAT_BIN_DIR/nvim.appimage" ]]; then
        rm "$LABRAT_BIN_DIR/nvim.appimage"
    fi
    
    # Optionally remove plugin data
    if confirm "Remove neovim plugin data (~/.local/share/nvim)?" "n"; then
        rm -rf "$HOME/.local/share/nvim"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/neovim"
    
    log_success "neovim configuration removed"
}
