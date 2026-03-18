set nocompatible
set encoding=utf-8

colorscheme koehler
"set guifont=DejaVu\ Sans\ Mono\ 7
set guifont=Terminus\ 8

" `set list` to activate
set showbreak=↪
set listchars=tab:→·,eol:↲,nbsp:␣,trail:·,extends:⟩,precedes:⟨

filetype indent on
syntax on

set nu!
set hlsearch

if has("autocmd")
	autocmd BufEnter *.h set filetype=c

	autocmd filetype c source ~/.vim/c.vim
	autocmd filetype sh source ~/.vim/sh.vim
endif

" , #perl # comments
map ,# :s/^/#/<CR>

" ,/ C/C++/C#/Java // comments
map ,/ :s/^/\/\//<CR>

" ,< HTML comment
map ,< :s/^\(.*\)$/<!-- \1 -->/<CR><Esc>:nohlsearch<CR>

" c++ java style comments
map ,* :s/^\(.*\)$/\/\* \1 \*\//<CR><Esc>:nohlsearch<CR>
