let mapleader =" " 

" SAVING
nmap <A-w> :w<CR>
nmap <Leader>qt :q!<CR>
nmap <Leader>w :w<CR>
nmap <Leader>quit :qa!<CR>

" CHANGE BUFFER
nmap <Leader>pv :Ex<CR>
nmap <Leader>h :help 
nmap <Leader>t :term<CR><C-w>5-
nmap <Leader>b <C-6>
nmap <Leader>n <C-w>
nmap <C-b> <C-6>

" TERMINAL
" tmap <S-Esc> <C-\><C-n>:q!<CR>
tmap <S-Tab> <C-\><C-n>:q!<CR>
tmap <Esc> <C-\><C-n>

" SELECTION
nmap <C-a> GVgg
nmap <Leader>s GVgg:s/
vmap <Leader>s :s/

" NEW LINE
nmap o o<Esc>
nmap O O<Esc>
nmap <BS> O<Esc>

" SHIFT UP
nmap <A-k> :m-2<CR>
vmap <A-k> :m-2<CR>gv=gv
vmap K :m-2<CR>gv=gv

" SHIFT DOWN
nmap <A-j> :m+<CR>
vmap <A-j> :m'>+<CR>gv=gv
vmap J :m'>+<CR>gv=gv

" TAB
nmap <Tab> >>

" SHIFT TAB
imap <S-Tab> <C-d>
nmap <S-Tab> <<

" SCROLLING
nmap L $
nmap H ^
nmap J mzJ`z
nmap <C-d> <C-d>zz
nmap <C-u> <C-u>zz

" SEARCHING
nmap n nzzzv
nmap N Nzzzv
nmap * *zzzv
nmap # #zzzv

" MOVING
nmap gg msgg
nmap G msG
nmap : ms:
nmap <A-b> `s
nmap <C-b> mr`s
nmap <A-n> `r
nmap <C-n> `r
nmap <leader>g `

set guicursor="i-ci-ve-c:ver25,r-cr:hor20"

set nu
set relativenumber

set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab

set smartindent

set wrap

set swapfile

set undofile

set hlsearch
set incsearch

set termguicolors

set scrolloff=4
set signcolumn=no
set isfname+=@,-

set updatetime=50

set clipboard=unnamed

colorscheme codedark

set foldlevelstart=99
set foldmethod=indent
