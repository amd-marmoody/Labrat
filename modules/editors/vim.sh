#!/usr/bin/env bash
#
# LabRat Module: vim
# Improved Vi editor with configuration
#

# ============================================================================
# Installation
# ============================================================================

install_vim() {
    log_step "Installing vim..."
    
    local installed_version=""
    
    # Check if already installed
    if command_exists vim; then
        installed_version=$(vim --version | head -1 | grep -oP 'Vi IMproved \K[\d.]+')
        log_info "vim already installed (version: $installed_version)"
    else
        # Install vim
        case "$OS_FAMILY" in
            debian)
                pkg_install vim
                ;;
            rhel)
                pkg_install vim-enhanced
                ;;
            *)
                pkg_install vim
                ;;
        esac
        
        installed_version=$(vim --version | head -1 | grep -oP 'Vi IMproved \K[\d.]+')
    fi
    
    log_info "vim version: $installed_version"
    
    # Deploy configuration
    deploy_vim_config
    
    # Mark as installed
    mark_module_installed "vim" "$installed_version"
    
    log_success "vim installed and configured!"
}

# ============================================================================
# Configuration Deployment
# ============================================================================

deploy_vim_config() {
    local config_source="${LABRAT_CONFIGS_DIR}/vim/.vimrc"
    local config_target="$HOME/.vimrc"
    
    log_step "Deploying vim configuration..."
    
    # Backup existing config
    if [[ -f "$config_target" ]] && [[ ! -L "$config_target" ]]; then
        backup_file "$config_target"
    fi
    
    # Create symlink or copy config
    if [[ -f "$config_source" ]]; then
        safe_symlink "$config_source" "$config_target"
        log_success "vim config deployed"
    else
        log_warn "Config source not found, creating default config"
        create_default_vim_config "$config_target"
    fi
}

create_default_vim_config() {
    local config_file="$1"
    
    cat > "$config_file" << 'VIMRC'
" ============================================================================
" LabRat Vim Configuration
" Your trusty environment for every test cage 🐀
" ============================================================================

" ----------------------------------------------------------------------------
" General Settings
" ----------------------------------------------------------------------------

" Disable vi compatibility
set nocompatible

" Enable syntax highlighting
syntax enable

" Enable file type detection
filetype plugin indent on

" Set encoding
set encoding=utf-8
set fileencoding=utf-8

" Use system clipboard
set clipboard=unnamedplus

" Enable mouse support
set mouse=a

" Disable swap files
set noswapfile
set nobackup
set nowritebackup

" Enable persistent undo
set undofile
set undodir=~/.vim/undo
if !isdirectory(&undodir)
    call mkdir(&undodir, 'p')
endif

" ----------------------------------------------------------------------------
" Display
" ----------------------------------------------------------------------------

" Show line numbers
set number
set relativenumber

" Highlight current line
set cursorline

" Show matching brackets
set showmatch

" Always show status line
set laststatus=2

" Show cursor position
set ruler

" Show command in bottom bar
set showcmd

" Enable wild menu for command completion
set wildmenu
set wildmode=longest:list,full

" Show invisible characters
set list
set listchars=tab:»\ ,trail:·,nbsp:␣

" Scroll offset
set scrolloff=8
set sidescrolloff=8

" Disable line wrapping
set nowrap

" Enable true color support
if has('termguicolors')
    set termguicolors
endif

" ----------------------------------------------------------------------------
" Search
" ----------------------------------------------------------------------------

" Ignore case in search
set ignorecase

" Smart case search
set smartcase

" Highlight search results
set hlsearch

" Incremental search
set incsearch

" ----------------------------------------------------------------------------
" Indentation
" ----------------------------------------------------------------------------

" Use spaces instead of tabs
set expandtab

" Tab width
set tabstop=4
set shiftwidth=4
set softtabstop=4

" Auto indent
set autoindent
set smartindent

" ----------------------------------------------------------------------------
" Splits
" ----------------------------------------------------------------------------

" Open splits to right and below
set splitright
set splitbelow

" ----------------------------------------------------------------------------
" Key Mappings
" ----------------------------------------------------------------------------

" Set leader key to space
let mapleader = " "

" Clear search highlighting
nnoremap <Esc> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize windows with arrows
nnoremap <C-Up> :resize +2<CR>
nnoremap <C-Down> :resize -2<CR>
nnoremap <C-Left> :vertical resize -2<CR>
nnoremap <C-Right> :vertical resize +2<CR>

" Move lines up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Stay in indent mode
vnoremap < <gv
vnoremap > >gv

" Save file
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" Quick quit
nnoremap <leader>q :q<CR>

" Buffer navigation
nnoremap <S-h> :bprevious<CR>
nnoremap <S-l> :bnext<CR>
nnoremap <leader>bd :bdelete<CR>

" Quick splits
nnoremap <leader>\ :vsplit<CR>
nnoremap <leader>- :split<CR>

" File explorer
nnoremap <leader>e :Explore<CR>

" ----------------------------------------------------------------------------
" Autocommands
" ----------------------------------------------------------------------------

" Return to last edit position when opening files
autocmd BufReadPost *
    \ if line("'\"") > 0 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Highlight yanked text
if exists('##TextYankPost')
    autocmd TextYankPost * silent! lua vim.highlight.on_yank()
endif

" ----------------------------------------------------------------------------
" Color Scheme (Basic - works without plugins)
" ----------------------------------------------------------------------------

" Try to use a nice colorscheme if available
silent! colorscheme desert

" Custom highlight modifications
highlight CursorLine cterm=NONE ctermbg=235
highlight LineNr ctermfg=240
highlight CursorLineNr ctermfg=220 ctermbg=235
highlight Visual ctermbg=238
highlight Search ctermfg=0 ctermbg=220
highlight MatchParen ctermbg=238

" Status line colors
highlight StatusLine ctermfg=255 ctermbg=238
highlight StatusLineNC ctermfg=240 ctermbg=235

" ----------------------------------------------------------------------------
" Status Line
" ----------------------------------------------------------------------------

" Custom status line
set statusline=
set statusline+=\ 🐀\ 
set statusline+=%f                           " File name
set statusline+=%m                           " Modified flag
set statusline+=%r                           " Read-only flag
set statusline+=%=                           " Right align
set statusline+=\ %y                         " File type
set statusline+=\ %{&fileencoding?&fileencoding:&encoding}
set statusline+=\ │\ %l:%c                   " Line:Column
set statusline+=\ │\ %p%%\                   " Percentage
VIMRC

    # Create undo directory
    mkdir -p "$HOME/.vim/undo"
    
    log_success "Default vim config created"
}

# ============================================================================
# Uninstallation
# ============================================================================

uninstall_vim() {
    log_step "Uninstalling vim configuration..."
    
    # Remove config
    if [[ -L "$HOME/.vimrc" ]]; then
        rm "$HOME/.vimrc"
    fi
    
    # Remove installed marker
    rm -f "${LABRAT_DATA_DIR}/installed/vim"
    
    log_success "vim configuration removed"
    log_info "Note: vim binary was not removed (use package manager to uninstall)"
}
