set nocompatible
set encoding=utf-8

"set guifont=DejaVu\ Sans\ Mono\ 7
set guifont=Terminus\ 8

" theme

set termguicolors

if has("autocmd")
	augroup MyColours
		autocmd!
		autocmd ColorScheme * highlight Normal ctermbg=16 guibg=#000000
		" tab, nbsp, trail, extends, and precedes
		autocmd ColorScheme * highlight SpecialKey ctermfg=239 guifg=#4e4e4e
		" eol and showbreak
		autocmd ColorScheme * highlight NonText ctermfg=239 guifg=#4e4e4e

		" Muted StatusLine: Grey-blue with white text
		autocmd ColorScheme * highlight StatusLine ctermbg=24 ctermfg=15 guibg=#005f87 guifg=#ffffff
		autocmd ColorScheme * highlight StatusLineNC ctermbg=235 ctermfg=244 guibg=#262626 guifg=#808080

		" Muted line numbers
		autocmd ColorScheme * highlight LineNr ctermfg=244 guifg=#808080
		autocmd ColorScheme * highlight CursorLineNr ctermfg=15 guifg=#ffffff gui=bold

		" Muted comments
		autocmd ColorScheme * highlight Comment ctermfg=243 guifg=#767676 gui=italic
	augroup END
endif

set background=dark
colorscheme torte

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
