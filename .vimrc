"  __   __   __     __    __     ______     ______
" /\ \ / /  /\ \   /\ "-./  \   /\  == \   /\  ___\
" \ \ \'/   \ \ \  \ \ \-./\ \  \ \  __<   \ \ \____
"  \ \__|    \ \_\  \ \_\ \ \_\  \ \_\ \_\  \ \_____\
"   \/_/      \/_/   \/_/  \/_/   \/_/ /_/   \/_____/


if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'rakr/vim-one'
" Plug 'joshdick/onedark.vim'
Plug 'chriskempson/base16-vim'
Plug 'jacoborus/tender.vim'
" Override configs by directory 
Plug 'arielrossanigo/dir-configs-override.vim'
" Better file browser
" Plug 'scrooloose/nerdtree'
Plug 'ryanoasis/vim-devicons'
" Code commenter
Plug 'tpope/vim-commentary'
" Class/module browser
Plug 'majutsushi/tagbar'
" Code and files fuzzy finder
Plug 'ctrlpvim/ctrlp.vim'
" Extension to ctrlp, for fuzzy command finder
Plug 'fisadev/vim-ctrlp-cmdpalette'
" Zen coding
Plug 'mattn/emmet-vim'
" Git integration
Plug 'motemen/git-vim'
" Tab list panel
Plug 'kien/tabman.vim'
Plug 'dbeniamine/cheat.sh-vim'
" Lightline
Plug 'itchyny/lightline.vim'
" Consoles as buffers
Plug 'rosenfeld/conque-term'
" Pending tasks list
Plug 'fisadev/FixedTaskList.vim'
" Surround
Plug 'tpope/vim-surround'
" Autoclose
" Plug 'jiangmiao/auto-pairs'
" Indent text object
" Plug 'michaeljsmith/vim-indent-object'
" Indentation based movements
Plug 'jeetsukumaran/vim-indentwise'
" Python autocompletion, go to definition.
" Plug 'davidhalter/jedi-vim'
" Better autocompletion
Plug 'Shougo/neocomplcache.vim'
" Snippets manager (SnipMate), dependencies, and snippets repo
" Plug 'MarcWeber/vim-addon-mw-utils'
" Plug 'tomtom/tlib_vim'
" Plug 'honza/vim-snippets'
" Plug 'garbas/vim-snipmate'
" Git/mercurial/others diff icons on the side of the file lines
Plug 'mhinz/vim-signify'
" Automatically sort python imports
" Plug 'fisadev/vim-isort'
" Drag visual blocks arround
" Plug 'fisadev/dragvisuals.vim'
" Window chooser
" Plug 't9md/vim-choosewin'
" Python and other languages code checker
Plug 'scrooloose/syntastic'
" Paint css colors with the real color
" Plug 'lilydjwg/colorizer'
" Ack code search (requires ack installed in the system)
" Plug 'mileszs/ack.vim'
Plug 'tpope/vim-eunuch'
Plug 'francoiscabrol/ranger.vim'
" Plug 'rbgrouleff/bclose.vim'
" Plug 'terryma/vim-multiple-cursors'
" Plug 'mg979/vim-visual-multi'
" coc.nvim: autocompletion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" indentline: show vertical lines as indent guides
" Plug 'Yggdroot/indentLine'
" vim-grip: live markdown preview
Plug 'PratikBhusal/vim-grip'
Plug 'christoomey/vim-titlecase'
" easily toggle window zoom
Plug 'troydm/zoomwintab.vim'
" FZF
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Project directory scope for FZF
Plug 'airblade/vim-rooter'
" fugitive git integration
Plug 'tpope/vim-fugitive'
Plug 'neomake/neomake'
" Better tabline
Plug 'mg979/vim-xtabline'
" Plug 'dense-analysis/ale'
filetype plugin on

" set leader key to comma
let mapleader = ","  
" ,e reload file in all buffers
map <leader>e :bufdo e!<CR> 

" === KEYS ===
" ctrl+a: select all text 
map <C-a> <esc>ggVG<CR>

" Better indenting/tabbing
vnoremap < <gv
vnoremap > >gv

" Move selected line / block of text in visual mode
" shift + k to move up
" shift + j to move down
xnoremap K :move '<-2<CR>gv-gv
xnoremap J :move '>+1<CR>gv-gv

" Better window navigation
imap <C-h> <C-w>h
imap <C-j> <C-w>j
imap <C-k> <C-w>k
imap <C-l> <C-w>l
nnoremap <C-h> <C-w>h                        
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Terminal window navigation
tnoremap <C-h> <C-\><C-N><C-w>h
tnoremap <C-j> <C-\><C-N><C-w>j
tnoremap <C-k> <C-\><C-N><C-w>k
tnoremap <C-l> <C-\><C-N><C-w>l
inoremap <C-h> <C-\><C-N><C-w>h
inoremap <C-j> <C-\><C-N><C-w>j
inoremap <C-k> <C-\><C-N><C-w>k
inoremap <C-l> <C-\><C-N><C-w>l
tnoremap <Esc> <C-\><C-n>

" Use alt + hjkl to resize windows
nnoremap <silent> <M-j>    :resize -2<CR>
nnoremap <silent> <M-k>    :resize +2<CR>
nnoremap <silent> <M-h>    :vertical resize -2<CR>
nnoremap <silent> <M-l>    :vertical resize +2<CR>
" it works differently on Mac
nnoremap <silent> ∆        :resize -2<CR>
nnoremap <silent> ˚        :resize +2<CR>
nnoremap <silent> ˙        :vertical resize -2<CR>
nnoremap <silent> ¬        :vertical resize +2<CR>

" TAB in general mode will move to text buffer
nnoremap <silent> <TAB> :bnext<CR>
" SHIFT-TAB will go back
nnoremap <silent> <S-TAB> :bprevious<CR>

" ============

if has('python')
  " YAPF formatter for Python
  Plug 'pignacio/vim-yapf-format'
endif

" Plug 'rakr/vim-one'
" Initialize plugin system
call plug#end()

" no vi-compatible
set nocompatible

" allow plugins by file type (required for plugins!)
filetype plugin on
filetype indent on

" tabs and spaces handling
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" tab length exceptions on some file types
autocmd FileType html setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType htmldjango setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType javascript setlocal shiftwidth=4 tabstop=4 softtabstop=4

" ignore these files when completing names and in Ex
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.mkv,*.mp4,*.m4v,*.webm,*.dts*,*.aac,*.mp3,*.flac
" set of file name suffixes that will be given a lower priority when it comes to matching wildcards
set suffixes+=.old

" source $MYVIMRC reloads the saved $MYVIMRC
:nmap <Leader>s :source $MYVIMRC<CR>

" opens $MYVIMRC for editing, or use :tabedit $MYVIMRC
:nmap <Leader>v :e ~/.vimrc<CR>

let s:hidden_all = 0
function! ToggleHiddenAll()
  if s:hidden_all  == 0
    let s:hidden_all = 1
    set noruler
    set laststatus=0
    set noshowcmd
  else
    let s:hidden_all = 0
    set ruler
    set laststatus=2
    set showcmd
  endif
endfunction

nnoremap <leader>h :call ToggleHiddenAll()<CR>

" incremental search
set incsearch
" highlighted search results
set hlsearch
" Yank and paste with the system clipboard
set clipboard=unnamed

syntax on
set hidden                              " Required to keep multiple buffers open multiple buffers
set encoding=utf-8                      " The encoding displayed
set pumheight=10                        " Makes popup menu smaller
set fileencoding=utf-8                  " The encoding written to file
set number                              " Line numbers
set relativenumber
set noruler                             " Hide the cursor position
set cursorline                          " Enable highlighting of the current line
set background=dark                     " tell vim what the background color looks like
set showcmd
set wildmenu
set lazyredraw
set showmatch
set autoindent
set smartindent
set ignorecase
set updatetime=300                      " Faster completion
" keep horizontal cursor position when jumping up/down
set virtualedit=all
set nostartofline
" highlight substitute match incrementally as you're typing
set inccommand=nosplit

" Setting vertical line
" set colorcolumn=86

" when scrolling keep cursor 3 lines away from screen border
set scrolloff=3

" mouse scrolling even inside tmux
set mouse=a

if !has('nvim')
  set ttymouse=xterm2
endif

let g:indentLine_char = '│'


" === TERMINAL === "
" exit terminal mode with Esc
tnoremap <Esc> <C-\><C-n>
autocmd BufWinEnter,WinEnter term://* startinsert

" === SPLITS === "
set splitbelow
set splitright
" Easier split navigations
tnoremap <C-h> <C-\><C-N><C-w>h
tnoremap <C-j> <C-\><C-N><C-w>j
tnoremap <C-k> <C-\><C-N><C-w>k
tnoremap <C-l> <C-\><C-N><C-w>l
inoremap <C-h> <C-\><C-N><C-w>h
inoremap <C-j> <C-\><C-N><C-w>j
inoremap <C-k> <C-\><C-N><C-w>k
inoremap <C-l> <C-\><C-N><C-w>l
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
"Max out the height of the current split
" ctrl + w _
"Max out the width of the current split
" ctrl + w |
"Normalize all split sizes, which is very handy when resizing terminal
" ctrl + w =
" Quickly Toggle Window Zoom
map <leader>z :ZoomWinTabToggle<CR>

" === TABS === "
" Go to tab by number
noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt
noremap <leader>0 :tablast<cr>

" === NERDTree === "
nmap <C-n> :NERDTreeToggle<CR>
" automatically close if last buffer
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
let g:NERDTreeQuitOnOpen = 1
let g:NERDTreeAutoDeleteBuffer = 1
" Show hidden files/directories
let g:NERDTreeShowHidden = 1
" Remove bookmarks and help text from NERDTree
let g:NERDTreeMinimalUI = 1
let g:NERDTreeDirArrows = 1
" Custom icons for expandable/expanded directories
" let g:NERDTreeDirArrowExpandable = '⬏'
" let g:NERDTreeDirArrowCollapsible = '⬎'
" Hide certain files and directories from NERDTree
let g:NERDTreeIgnore = ['^\.DS_Store$', '^tags$', '\.git$[[dir]]', '\.idea$[[dir]]', '\.sass-cache$']
" Hide the Nerdtree status line to avoid clutter
let g:NERDTreeStatusline = ''
" after a re-source, fix syntax matching issues (concealing brackets):
if exists('g:loaded_webdevicons')
  call webdevicons#refresh()
endif

" === Syntastic === "
" let g:syntastic_javascript_checkers = [ 'jshint' ]
" let g:syntastic_ocaml_checkers = ['merlin']
" let g:syntastic_python_checkers = ['flake8', 'pylint']
" let g:syntastic_shell_checkers = ['shellcheck']
" let g:syntastic_yaml_checkers = ['yamllint']

" === COC === "
" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=yes
" Use tab for trigger completion with characters ahead and navigate.
" Use command ':verbose imap <tab>' to make sure tab is not mapped by other plugin.
" inoremap <silent><expr> <TAB>
"       \ pumvisible() ? "\<C-n>" :
"       \ <SID>check_back_space() ? "\<TAB>" :
"       \ coc#refresh()
" inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
"Close preview window when completion is done.
autocmd! CompleteDone * if pumvisible() == 0 | pclose | endif
" Use <C-space> to trigger completion.
inoremap <silent><expr> <C-space> coc#refresh()
" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction
" Highlight symbol under cursor on CursorHold
" autocmd CursorHold * silent call CocActionAsync('highlight')
" Remap for rename current word
" nmap <leader>rn <Plug>(coc-rename)
" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Coc-Explorer
nmap <leader>e :CocCommand explorer<CR>
" nmap <leader>f :CocCommand explorer --preset floating<CR>
" when closing all buffers and Coc-Explorer is the last one left auto-close it
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | q | endif

" === FZF === "
" This is the default extra key bindings
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

" Enable per-command history.
" CTRL-N and CTRL-P will be automatically bound to next-history and
" previous-history instead of down and up. If you don't like the change,
" explicitly bind the keys to down and up in your $FZF_DEFAULT_OPTS.
let g:fzf_history_dir = '~/.local/share/fzf-history'

map <C-f> :Files<CR>
map <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>t :Tags<CR>
nnoremap <leader>m :Marks<CR>


let g:fzf_tags_command = 'ctags -R'
" Border color
let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8,'yoffset':0.5,'xoffset': 0.5, 'highlight': 'Todo', 'border': 'sharp' } }

let $FZF_DEFAULT_OPTS = '--layout=reverse --info=inline'
let $FZF_DEFAULT_COMMAND="rg --files --hidden"


" Customize fzf colors to match your color scheme
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'border':  ['fg', 'Ignore'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
  \ 'header':  ['fg', 'Comment'] }

"Get Files
command! -bang -nargs=? -complete=dir Files
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'options': ['--layout=reverse', '--info=inline']}), <bang>0)


" Get text in files with Rg
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always --smart-case '.shellescape(<q-args>), 1,
  \   fzf#vim#with_preview(), <bang>0)

" Ripgrep advanced
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

" Git grep
command! -bang -nargs=* GGrep
  \ call fzf#vim#grep(
  \   'git grep --line-number '.shellescape(<q-args>), 0,
  \   fzf#vim#with_preview({'dir': systemlist('git rev-parse --show-toplevel')[0]}), <bang>0)

" === Tabline === "
let g:xtabline_settings = {}

let g:xtabline_settings.enable_mappings = 0

let g:xtabline_settings.tabline_modes = ['buffers', 'tabs']

let g:xtabline_settings.enable_persistance = 0

" let g:xtabline_settings.last_open_first = 1
let g:xtabline_lazy = 1

let g:xtabline_settings.show_right_corner = 0

let g:xtabline_settings.indicators = {
      \ 'modified': '+',
      \ 'pinned': '[📌]',
      \}
      " \ 'modified': '●',

let g:xtabline_settings.icons = {
      \'pin': '📌',
      \'star': '*',
      \'book': '📖',
      \'lock': '🔒',
      \'hammer': '🔨',
      \'tick': '✔',
      \'cross': '✖',
      \'warning': '⚠',
      \'menu': '☰',
      \'apple': '🍎',
      \'linux': '🐧',
      \'windows': '⌘',
      \'git': '',
      \'palette': '🎨',
      \'lens': '🔍',
      \'flag': '🏁',
      \}

" === Prettier === "
" noremap <C-I> :CocCommand prettier.formatFile<CR>
command! -nargs=0 Prettier :CocCommand prettier.formatFile

" ALE
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
" let g:ale_lint_on_text_changed = 'never'  " only lint on save

" titlecase
let g:titlecase_map_keys = 0  " remove default keymapping which interferes with tabs
nmap <leader>ct <Plug>Titlecase
vmap <leader>ct <Plug>Titlecase
nmap <leader>cT <Plug>TitlecaseLine

"  appearance
set noshowmode  " disables -- INSERT -- mode display underneath lightline
let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'cocstatus', 'readonly', 'filename', 'modified' ] ],
      \   'right': [ [ 'percent' ],
      \              [           ],
      \              [ 'fileformat', 'fileencoding', 'filetype' ] ]
      \ },
      \ 'component_function': {
      \   'fileformat': 'LightlineFileformat',
      \   'filetype': 'LightlineFiletype',
    	\   'cocstatus': 'coc#status',
      \ },
      \ }

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
endfunction

" Use autocmd to force lightline update.
autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()

let g:one_allow_italics = 1
let g:onedark_terminal_italic = 1

set background=dark
" set t_Co=256
" set t_ut=
colorscheme one
call one#highlight('Normal', '', '24282c', 'none') " dark

" let g:VM_maps = {}
" let g:VM_maps['Find Under']         = '<C-d>'           " replace C-n
" let g:VM_maps['Find Subword Under'] = '<C-d>'           " replace visual C-n
" let g:VM_mouse_mappings = 1
