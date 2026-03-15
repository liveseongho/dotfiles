" ~/.vimrc
" Seongho's dotfiles

" ========== General ==========
set nocompatible
set encoding=utf-8
set fileencoding=utf-8

" ========== UI ==========
syntax on
set number
set relativenumber
set cursorline
set showcmd
set showmatch
set wildmenu
set laststatus=2
set signcolumn=yes
set termguicolors
set background=dark
colorscheme onedark

" ========== Search ==========
set hlsearch
set incsearch
set ignorecase
set smartcase

" ========== Indent ==========
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" ========== Behavior ==========
set backspace=indent,eol,start
set scrolloff=8
set mouse=a
set clipboard=unnamed
set hidden
set noswapfile
set nobackup
set undofile
set undodir=~/.vim/undodir

" ========== Key mappings ==========
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <Esc><Esc> :noh<CR>

" Create undo directory if missing
if !isdirectory(expand("~/.vim/undodir"))
  call mkdir(expand("~/.vim/undodir"), "p")
endif
