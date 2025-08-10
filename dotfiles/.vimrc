" Vim Configuration File
" Optimized for development with modern features

" === BASIC SETTINGS ===
set nocompatible              " Disable vi compatibility
set encoding=utf-8            " Set encoding
set fileencoding=utf-8        " Set file encoding
set number                    " Show line numbers
" set relativenumber           " Show relative line numbers
set cursorline               " Highlight current line
set showcmd                  " Show command in bottom bar
set wildmenu                 " Visual autocomplete for command menu
set showmatch                " Highlight matching [{()}]
set incsearch                " Search as characters are entered
set hlsearch                 " Highlight matches
set ignorecase               " Ignore case in search
set smartcase                " Smart case sensitivity
set autoindent               " Auto indent
set smartindent              " Smart indent
set expandtab                " Use spaces instead of tabs
set tabstop=4                " Number of visual spaces per TAB
set softtabstop=4            " Number of spaces in tab when editing
set shiftwidth=4             " Number of spaces to use for autoindent
set wrap                     " Wrap lines
set linebreak                " Break lines at word boundaries
set scrolloff=8              " Keep 8 lines visible when scrolling
set sidescrolloff=8          " Keep 8 columns visible when scrolling
set backspace=indent,eol,start " Allow backspace over everything
set clipboard=unnamed        " Use system clipboard
set mouse=a                  " Enable mouse support
set laststatus=2             " Always show status line
set ruler                    " Show cursor position
set splitbelow               " New horizontal splits below
set splitright               " New vertical splits to the right
set hidden                   " Allow buffer switching without saving
set history=1000             " Command history
set undolevels=1000          " Undo history
set title                    " Set terminal title
set visualbell               " Use visual bell instead of beeping
set noerrorbells             " No error bells
set t_vb=                    " No visual bell

" === FILE HANDLING ===
set autoread                 " Reload files changed outside vim
set backup                   " Enable backups
set backupdir=~/.vim/backup  " Backup directory
set directory=~/.vim/swap    " Swap file directory
set undofile                 " Persistent undo
set undodir=~/.vim/undo      " Undo directory

" Create directories if they don't exist
if !isdirectory($HOME."/.vim/backup")
    call mkdir($HOME."/.vim/backup", "p")
endif
if !isdirectory($HOME."/.vim/swap")
    call mkdir($HOME."/.vim/swap", "p")
endif
if !isdirectory($HOME."/.vim/undo")
    call mkdir($HOME."/.vim/undo", "p")
endif

" === COLOR AND SYNTAX ===
syntax enable                " Enable syntax highlighting
filetype plugin indent on   " Enable filetype detection
set background=dark          " Dark background
if has('termguicolors')
    set termguicolors        " True color support
endif

" === KEY MAPPINGS ===
let mapleader = " "          " Set leader key to space

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>

" Clear search highlights
nnoremap <leader>/ :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize windows
nnoremap <leader>= <C-w>=
nnoremap <leader>+ :resize +5<CR>
nnoremap <leader>- :resize -5<CR>
nnoremap <leader>> :vertical resize +5<CR>
nnoremap <leader>< :vertical resize -5<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprev<CR>
nnoremap <leader>bd :bdelete<CR>

" Tab navigation
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprev<CR>
nnoremap <leader>tc :tabclose<CR>
nnoremap <leader>to :tabonly<CR>

" Move lines up/down
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
inoremap <A-j> <Esc>:m .+1<CR>==gi
inoremap <A-k> <Esc>:m .-2<CR>==gi
vnoremap <A-j> :m '>+1<CR>gv=gv
vnoremap <A-k> :m '<-2<CR>gv=gv

" Better indenting in visual mode
vnoremap < <gv
vnoremap > >gv

" === LANGUAGE-SPECIFIC SETTINGS ===
" Python
autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4

" JavaScript/TypeScript
autocmd FileType javascript,typescript setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

" HTML/CSS
autocmd FileType html,css setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

" Rust
autocmd FileType rust setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4

" YAML
autocmd FileType yaml setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2

" Markdown
autocmd FileType markdown setlocal wrap linebreak nolist textwidth=80

" === STATUS LINE ===
set statusline=%f                           " File name
set statusline+=%m                          " Modified flag
set statusline+=%r                          " Read-only flag
set statusline+=%=                          " Right align
set statusline+=[%{&fileformat}]           " File format
set statusline+=[%{&fileencoding}]         " File encoding
set statusline+=[%{&filetype}]             " File type
set statusline+=\ %l/%L                    " Line number / total lines
set statusline+=\ %c                       " Column number
set statusline+=\ %P                       " Percentage through file

" === MISCELLANEOUS ===
" Remove trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Return to last edit position when opening files
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

" Highlight extra whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/

" Enable spell checking for certain file types
autocmd FileType gitcommit,markdown,text setlocal spell

" Auto-reload vimrc when edited
autocmd BufWritePost $MYVIMRC source $MYVIMRC

