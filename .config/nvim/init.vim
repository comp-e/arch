set number
set relativenumber
set nohlsearch
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
set mouse=a

call plug#begin('~/.config/nvim/plugged')

Plug 'liuchengxu/space-vim-dark' " Color scheme

Plug 'https://github.com/vim-airline/vim-airline' " Status bar
Plug 'https://github.com/preservim/nerdtree' " NerdTree
Plug 'https://github.com/tpope/vim-commentary' " For Commenting gcc & gc
Plug 'https://github.com/tc50cal/vim-terminal' " Vim Terminal
Plug 'https://github.com/preservim/tagbar' " Tagbar for code navigation
Plug 'https://github.com/neoclide/coc.nvim'  " Auto Completion

let g:NERDTreeDirArrowExpandable="+" " Change nerdtree icons     
let g:NERDTreeDirArrowCollapsible="~" " 

let g:loaded_matchparen=1 " Removes highlighted parentheses

let g:coc_start_at_startup = v:false

nnoremap <C-f> :NERDTreeToggle<CR>
nnoremap <C-n> :TerminalSplit zsh<CR>
nmap <F8> :TagbarToggle<CR>

call plug#end()
