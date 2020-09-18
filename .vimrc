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

if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let g:ale_disable_lsp = 1  " before plugins are loaded

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'rakr/vim-one'
Plug 'ryanoasis/vim-devicons'
Plug 'tpope/vim-commentary'
Plug 'dbeniamine/cheat.sh-vim'
Plug 'itchyny/lightline.vim'
Plug 'tpope/vim-surround'
" Indentation based movements
Plug 'jeetsukumaran/vim-indentwise'
" Git
Plug 'mhinz/vim-signify'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-eunuch'
" Plug 'francoiscabrol/ranger.vim'
Plug 'jiangmiao/auto-pairs'
" LSP for nvim 0.5+
" language server : autocomplete, snippets support, goto action, diagnostics
Plug 'neovim/nvim-lsp'
Plug 'nvim-lua/completion-nvim'
Plug 'nvim-lua/lsp-status.nvim'
Plug 'nvim-lua/diagnostic-nvim'
" coc.nvim: LSP
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'kevinoid/vim-jsonc'
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
" Plug 'neomake/neomake'
" Better tabline
" Plug 'mg979/vim-xtabline'
" Plug 'pacha/vem-tabline'
" Plug 'ap/vim-buftabline'
Plug 'mengelbrecht/lightline-bufferline'
" ALE
Plug 'dense-analysis/ale'
Plug 'liuchengxu/vim-which-key'
" find and replace on multiple files
Plug 'brooth/far.vim'
" fast splitting a window into a term
Plug 'smason1995/easy-split-terms'
" Fern file manager
" Plug 'lambdalisue/fern.vim'
" Plug 'lambdalisue/fern-renderer-nerdfont.vim'
" fix for fern
" if has("nvim")
"   Plug 'antoinemadec/FixCursorHold.nvim'
" endif
" LuaTree file explorer
Plug 'kyazdani42/nvim-tree.lua'
Plug 'kyazdani42/nvim-web-devicons' " for file icons
Plug 'lambdalisue/reword.vim'
" Better python syntax highlighting
" Plug 'numirias/semshi', {'do': ':UpdateRemotePlugins'}
" Improved syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter'

" Initialize plugin system
call plug#end()

" Disable strange Vi defaults
set nocompatible
filetype plugin indent on

" set leader key to comma
let mapleader = ","
" ,e reload file in all buffers
map <leader>e :bufdo e!<CR>

" === KEYS ===
" disable arrow keys
noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

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

" move among buffers with CTRL
" map <C-J> :bnext<CR>
" map <C-K> :bprev<CR>
" TAB in general mode will move to text buffer
" nnoremap <silent> <TAB> :bnext<CR>
" SHIFT-TAB will go back
" nnoremap <silent> <S-TAB> :bprev<CR>

" ============

" tabs and spaces handling
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab

" tab length exceptions on some file types
autocmd FileType html setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType htmldjango setlocal shiftwidth=4 tabstop=4 softtabstop=4
autocmd FileType javascript setlocal shiftwidth=4 tabstop=4 softtabstop=4

" ignore these files when completing names and in Ex
set wildignore+=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam,*.mkv,*.mp4,*.m4v,*.webm,*.dts*,*.aac,*.mp3,*.flac,**/node_modules/**
" set of file name suffixes that will be given a lower priority when it comes to matching wildcards
set suffixes+=.old,.bkp

" source $MYVIMRC reloads the saved $MYVIMRC
:nmap <leader>s :source $MYVIMRC<CR>

" opens $MYVIMRC for editing, or use :tabedit $MYVIMRC
:nmap <leader>v :e ~/.vimrc<CR>

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

" === sane defaults / QoL changes === "
syntax on
set hidden                              " Required to keep multiple buffers open multiple buffers
set encoding=utf-8                      " Force utf-8 for the encoding displayed
set pumheight=10                        " Makes popup menu smaller
set fileencoding=utf-8                  " The encoding written to file
set incsearch                           " incremental search
set hlsearch                            " highlighted search results
set clipboard=unnamed                   " Yank and paste with the system clipboard
" set showtabline=2                       " Always display tabline at top
set number                              " Line numbers
set relativenumber
set noruler                             " Hide the cursor position
set cursorline                          " Enable highlighting of the current line
set showcmd
set wildmenu
set lazyredraw                          " Only redraw when needed
set showmatch                           " Highlight matching [{()}]
set autoindent                          " Autoindent when starting new line
set smartindent
set smarttab                            " Use 'shiftwidth' when using <Tab> in front of a line
set ignorecase
set complete+=kspell
set spelllang=en,cjk
" set spell
" set completeopt+=menuone,preview  " ,longest
set updatetime=300                      " Faster completion
set autoread                            " Reload unchanged files automatically
set virtualedit=all                     " Keep horizontal cursor position when jumping up/down
set nostartofline                       " Do not jump to first character with page commands.
set noswapfile                          " Disable swap to prevent annoying messages
set nomodeline                          " Don't parse modelines because of vulnerability
set title                               " Set window title by default
set shortmess+=I                        " Don't display startup intro message
" highlight substitute match incrementally as you're typing
set inccommand=nosplit
" when entering a buffer, set path to the directory of the file
" autocmd BufEnter * lcd %:p:h  " TODO need to investigate how to make this
" work with terminal buffers

" Setting vertical line
" set colorcolumn=86

" when scrolling keep cursor 3 lines away from screen border
set scrolloff=3

" mouse scrolling even inside tmux
set mouse=a

if !has('nvim')
  set ttymouse=xterm2
endif

" === Extras === "
" Delete comment character when joining commented lines
if v:version > 703 || v:version == 703 && has("patch541")
  set formatoptions+=j
endif

" Use Ctrl-/ to clear the highlighting of hlsearch
if maparg('<C-/>', 'n') ==# ''
  nnoremap <silent> <C-/> :nohlsearch<C-R>=has('diff')?'<Bar>diffupdate':''<CR><CR><C-L>
endif


let g:indentLine_char = '│'

" === Search & Replace === "
" Press * to search for the term under the cursor or a visual selection and
" then press this key below to replace all instances of it in the current file.
nnoremap <leader>r :%s///g<Left><Left>
" nnoremap <leader>rc :%s///gc<Left><Left><Left>

" The same as above but instead of acting on the whole file it will be
" restricted to the previously visually selected range. You can do that by
" pressing *, visually selecting the range you want it to apply to and then
" press this key below to replace all instances of it in the current selection.
xnoremap <leader>r :s///g<Left><Left>
" xnoremap <leader>rc :s///gc<Left><Left><Left>


" Keep flags when repeating last substitute command.
nnoremap & :&&<CR>
xnoremap & :&&<CR>

let g:python3_host_program = $HOME."~/work/python/environments/venv/bin/python"

" === TERMINAL === "
" exit terminal mode with Esc
tnoremap <Esc> <C-\><C-n>
autocmd BufWinEnter,WinEnter term://* startinsert

augroup TerminalConfig
   " au! " Clear old autocommands
  autocmd TermOpen * setlocal nonumber norelativenumber
augroup END

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
"Normalize all split sizes, very handy when resizing terminal
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


" === PLUGIN CONFIGS === "
" === nvim-tree file explorer === "
nnoremap <C-e> :LuaTreeToggle<CR>

let g:lua_tree_ignore = [ '.git', 'node_modules', '.cache' ] "empty by default
let g:lua_tree_auto_open = 1 "0 by default, opens the tree when typing `nvim $DIR` or `nvim`
let g:lua_tree_auto_close = 1 "0 by default, closes the tree when it's the last window
let g:lua_tree_follow = 1 "0 by default, this option allows the cursor to be updated when entering a buffer
let g:lua_tree_indent_markers = 1 "0 by default, this option shows indent markers when folders are open
let g:lua_tree_git_hl = 1 "0 by default, will enable file highlight for git attributes (can be used without the icons).

let g:lua_tree_icons = {
    \ 'default': '',
    \ 'symlink': '',
    \ 'git': {
    \   'unstaged': "✗",
    \   'staged': "✓",
    \   'unmerged': "",
    \   'renamed': "➜",
    \   'untracked': "★"
    \   },
    \ 'folder': {
    \   'default': "",
    \   'open': ""
    \   }
    \ }

" === fern file explorer === "
" Disable netrw.
let g:loaded_netrw  = 1
let g:loaded_netrwPlugin = 1
let g:loaded_netrwSettings = 1
let g:loaded_netrwFileHandlers = 1

" Enable file type icons
let g:fern#renderer = "nerdfont"

augroup my-fern-hijack
  autocmd!
  autocmd BufEnter * ++nested call s:hijack_directory()
augroup END

function! s:hijack_directory() abort
  let path = expand('%:p')
  if !isdirectory(path)
    return
  endif
  bwipeout %
  execute printf('Fern %s', fnameescape(path))
endfunction

" Custom settings and mappings.
let g:fern#disable_default_mappings = 1

noremap <silent> <Leader>f :Fern . -drawer -reveal=% -toggle -width=35<CR><C-w>=

function! FernInit() abort
  nmap <buffer><expr>
        \ <Plug>(fern-my-open-expand-collapse)
        \ fern#smart#leaf(
        \   "\<Plug>(fern-action-open:select)",
        \   "\<Plug>(fern-action-expand)",
        \   "\<Plug>(fern-action-collapse)",
        \ )
  nmap <buffer> <CR> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> <2-LeftMouse> <Plug>(fern-my-open-expand-collapse)
  nmap <buffer> n <Plug>(fern-action-new-path)
  nmap <buffer> d <Plug>(fern-action-remove)
  nmap <buffer> m <Plug>(fern-action-move)
  nmap <buffer> M <Plug>(fern-action-rename)
  nmap <buffer> h <Plug>(fern-action-hidden-toggle)
  nmap <buffer> r <Plug>(fern-action-reload)
  nmap <buffer> k <Plug>(fern-action-mark-toggle)
  nmap <buffer> b <Plug>(fern-action-open:split)
  nmap <buffer> v <Plug>(fern-action-open:vsplit)
  nmap <buffer><nowait> < <Plug>(fern-action-leave)
  nmap <buffer><nowait> > <Plug>(fern-action-enter)
endfunction

augroup FernGroup
  autocmd!
  autocmd FileType fern call FernInit()
augroup END

" === Auto-Pairs === "
" disable for vim/smali files as it messes up comments
au Filetype smali let b:AutoPairs={'(':')', '{':'}',"'":"'",'"':'"', '`':'`'}

" === Which Key === "
" Map leader to which_key
nnoremap <silent> <leader> :silent WhichKey '<Space>'<CR>
vnoremap <silent> <leader> :silent <c-u> :silent WhichKeyVisual '<Space>'<CR>

" Create map to add keys to
let g:which_key_map =  {}
" Define a separator
let g:which_key_sep = '→'
" set timeoutlen=500

" disable floating window
let g:which_key_use_floating_win = 0

" Colors
highlight default link WhichKey          Operator
highlight default link WhichKeySeperator Background
highlight default link WhichKeyGroup     Identifier
highlight default link WhichKeyDesc      Function

" Hide status line
autocmd! FileType which_key
autocmd  FileType which_key set laststatus=0 noshowmode noruler
  \| autocmd BufLeave <buffer> set laststatus=2 noshowmode ruler

" Single mappings
let g:which_key_map['/'] = [ '<Plug>NERDCommenterToggle'  , 'comment' ]
let g:which_key_map['e'] = [ ':CocCommand explorer'       , 'explorer' ]
let g:which_key_map['f'] = [ ':Files'                     , 'search files' ]
let g:which_key_map['h'] = [ '<C-W>s'                     , 'split below']
let g:which_key_map['r'] = [ ':Ranger'                    , 'ranger' ]
let g:which_key_map['S'] = [ ':Rg'                        , 'search text' ]
let g:which_key_map['v'] = [ '<C-W>v'                     , 'split right']
let g:which_key_map['z'] = [ 'Zoom'                       , 'zoom' ]

" s is for search
let g:which_key_map.s = {
      \ 'name' : '+search' ,
      \ '/' : [':History/'     , 'history'],
      \ ';' : [':Commands'     , 'commands'],
      \ 'a' : [':Ag'           , 'text Ag'],
      \ 'b' : [':BLines'       , 'current buffer'],
      \ 'B' : [':Buffers'      , 'open buffers'],
      \ 'c' : [':Commits'      , 'commits'],
      \ 'C' : [':BCommits'     , 'buffer commits'],
      \ 'f' : [':Files'        , 'files'],
      \ 'g' : [':GFiles'       , 'git files'],
      \ 'G' : [':GFiles?'      , 'modified git files'],
      \ 'h' : [':History'      , 'file history'],
      \ 'H' : [':History:'     , 'command history'],
      \ 'l' : [':Lines'        , 'lines'] ,
      \ 'm' : [':Marks'        , 'marks'] ,
      \ 'M' : [':Maps'         , 'normal maps'] ,
      \ 'p' : [':Helptags'     , 'help tags'] ,
      \ 'P' : [':Tags'         , 'project tags'],
      \ 's' : [':Snippets'     , 'snippets'],
      \ 'S' : [':Colors'       , 'color schemes'],
      \ 't' : [':Rg'           , 'text Rg'],
      \ 'T' : [':BTags'        , 'buffer tags'],
      \ 'w' : [':Windows'      , 'search windows'],
      \ 'y' : [':Filetypes'    , 'file types'],
      \ 'z' : [':FZF'          , 'FZF'],
      \ }

" Register which key map
call which_key#register('<Space>', "g:which_key_map")


" === Git integration === "
" === Signify === "
" Change these if you want
" let g:signify_sign_add               = '+'
" let g:signify_sign_delete            = '_'
" let g:signify_sign_delete_first_line = '‾'
" let g:signify_sign_change            = '~'

let g:signify_sign_show_count = 0  " Don’t show the number of deleted lines.

" Jump though hunks
nmap <leader>gj <plug>(signify-next-hunk)
nmap <leader>gk <plug>(signify-prev-hunk)
nmap <leader>gJ 9999<leader>gJ
nmap <leader>gK 9999<leader>gk

" If you like colors instead
" highlight SignifySignAdd                  ctermbg=green                guibg=#00ff00
" highlight SignifySignDelete ctermfg=black ctermbg=red    guifg=#ffffff guibg=#ff0000
" highlight SignifySignChange ctermfg=black ctermbg=yellow guifg=#000000 guibg=#ff

" Update Git signs every time the text is changed
" autocmd User SignifySetup
"             \ execute 'autocmd! signify' |
"             \ autocmd signify TextChanged,TextChangedI * call sy#start()

" === FuGITive === "
nmap <leader>gh :diffget //3<CR>
nmap <leader>gu :diffget //2<CR>
nmap <leader>gs :G<CR>


" === LSP === "
lua <<EOF
local lsp_status = require('lsp-status')
lsp_status.register_progress()

local nvim_lsp = require'nvim_lsp'

-- define language servers
nvim_lsp.pyls.setup{
    cmd = {"pyls", "--log-file", "/tmp/pyls-log.txt", "--verbose"},
    on_attach=require'diagnostic'.on_attach,
    settings = {
      pyls = {
        configurationSources = { "pycodestyle", "flake8", "mypy" }
      }
    }
}
nvim_lsp.vimls.setup{on_attach=require'diagnostic'.on_attach}
nvim_lsp.jdtls.setup{}
nvim_lsp.jsonls.setup{}
nvim_lsp.dockerls.setup{}
nvim_lsp.diagnosticls.setup{}
nvim_lsp.yamlls.setup{
  settings = {
    yaml = {
      customTags = {
        "!secret",
        "!include_dir_named",
        "!include_dir_list",
        "!include_dir_merge_named",
        "!include_dir_merge_list"
      }
    }
  }
}
EOF

let g:diagnostic_enable_underline = 1
let g:diagnostic_enable_virtual_text = 1
let g:diagnostic_trimmed_virtual_text = '40'
let g:diagnostic_virtual_text_prefix = ''

call sign_define("LspDiagnosticsErrorSign", {"text" : "◉", "texthl" : "LspDiagnosticsError"})
call sign_define("LspDiagnosticsWarningSign", {"text" : "•", "texthl" : "LspDiagnosticsWarning"}) " ⚬
call sign_define("LspDiagnosticsInformationSign", {"text" : "•", "texthl" : "LspDiagnosticsInformation"})
call sign_define("LspDiagnosticsHintSign", {"text" : "H", "texthl" : "LspDiagnosticsHint"})

function! SetLSPHighlights()
  highlight LspDiagnosticsError ctermfg=red guifg=#ff0000 guibg=NONE guisp=NONE gui=NONE
  " highlight LspDiagnosticsWarning ctermfg=yellow guifg=#ffff00 guibg=NONE guisp=NONE gui=NONE
endfunction

autocmd ColorScheme * call SetLSPHighlights()

" === completion === "
" Use completion-nvim in every buffer
autocmd BufEnter * lua require'completion'.on_attach()
" Use <Tab> and <S-Tab> to navigate through popup menu
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
" Set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect

" === COC === "
" don't give |ins-completion-menu| messages.
set shortmess+=c
" always show signcolumns
set signcolumn=number  " or =number to merge signcolumn and linenumbers
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
" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current
" position. Coc only does snippet and additional edit on confirm.
" <cr> could be remapped by other vim plugin, try `:verbose imap <CR>`.
if exists('*complete_info')
  inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"
else
  inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
endif
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
" xmap <leader>f  <Plug>(coc-format-selected)
" nmap <leader>f  <Plug>(coc-format-selected)

" Symbol renaming.
nmap <leader>rn <Plug>(coc-rename)

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list.
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Apply AutoFix to problem on the current line.
nmap <leader>qf  <Plug>(coc-fix-current)

" Coc-Explorer
" nmap <C-e> :CocCommand explorer<CR>
" nmap <leader>f :CocCommand explorer --preset floating<CR>
" when closing all buffers and Coc-Explorer is the last one left auto-close it
autocmd BufEnter * if (winnr("$") == 1 && &filetype == 'coc-explorer') | q | endif

" === Treesitter === "
lua <<EOF
require'nvim-treesitter.configs'.setup {
  ensure_installed = "all",     -- one of "all", "language", or a list of languages
  highlight = {
    enable = true,              -- false will disable the whole extension
  },
}
EOF

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
" let g:fzf_layout = {'up':'~90%', 'window': { 'width': 0.8, 'height': 0.8,'yoffset':0.5,'xoffset': 0.5, 'highlight': 'Todo', 'border': 'sharp' } }

let $FZF_DEFAULT_OPTS = '--layout=reverse' " --info=inline
let $FZF_DEFAULT_COMMAND="rg --files --ignore --hidden -g '!{.git/*,node_modules/*}' -g '!{*.png,*.jpg,*.jpeg}'"


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

" hide annoying GUI elements when running FZF
if has('nvim') || has('gui_running')
  autocmd! FileType fzf tnoremap <buffer> <esc> <c-c>
  autocmd  FileType fzf set laststatus=0 | autocmd WinLeave <buffer> set laststatus=2
endif

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

" === ALE === "
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
" let g:ale_sign_error = '✘'
" let g:ale_sign_warning = '⚠'
let g:ale_lint_on_text_changed = 'never'  " only lint on save
let g:ale_fix_on_save = 1
" let g:ale_completion_autoimport = 1
let g:ale_list_window_size = 5  " Show 5 lines of errors (default: 10)
let g:ale_linters_explicit = 1  " Only run linters named in ale_linters settings.
let g:ale_fixers = {
      \ '*': ['remove_trailing_lines', 'trim_whitespace'],
      \ }

" === Titlecase === "
let g:titlecase_map_keys = 0  " remove default keymapping which interferes with tabs
nmap <leader>ct <Plug>Titlecase
vmap <leader>ct <Plug>Titlecase
nmap <leader>cT <Plug>TitlecaseLine

" === Lightline === "
set noshowmode  " disables -- INSERT -- mode display underneath lightline

let g:lightline#bufferline#min_buffer_count = 2
let g:lightline#bufferline#show_number  = 0
let g:lightline#bufferline#enable_devicons = 1         " Show fileicons
let g:lightline#bufferline#shorten_path = 0
" let g:lightline#bufferline#filename_modifier = ':t'  " Hide path and show only filename
let g:lightline#bufferline#unnamed      = '[No Name]'

let g:lightline = {
      \ 'colorscheme': 'one',
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'readonly', 'filename_with_icon', 'status_diagnostic' ] ],
      \   'right': [ [ 'percent' ],
      \              [ 'gitbranch' ],
      \              [ 'gitchanges' ] ]
      \ },
      \ 'tabline': {
      \   'left': [ ['buffers'] ],
      \   'right': [ ]
      \ },
      \ 'component_expand': {
      \   'buffers': 'lightline#bufferline#buffers'
      \ },
      \ 'component_type': {
      \   'buffers': 'tabsel'
      \ },
      \ 'component_function': {
      \   'mode': 'LightlineMode',
      \   'fileformat': 'LightlineFileformat',
      \   'filetype': 'LightlineFiletype',
      \   'cocstatus': 'coc#status',
      \   'currentfunction': 'CocCurrentFunction',
      \   'gitbranch': 'FugitiveHead',
      \   'gitchanges': 'GitSignifyStats',
      \   'status_diagnostic': 'StatusDiagnostic',
      \   'filename_with_icon': 'FileNameWithIcon',
      \ },
      \ }

function! LightlineMode()
  return expand('%:t') =~# '^__Tagbar__' ? 'Tagbar':
        \ expand('%:t') ==# 'ControlP' ? 'CtrlP' :
        \ &filetype =~# '\v(help|vimfiler|unite|LuaTree)' ? '' :
        \ lightline#mode()
endfunction

function! LightlineFilename()
  let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  let modified = &modified ? ' +' : ''
  return filename . modified
endfunction

function! FileNameWithIcon() abort
  let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
  let modified = &modified ? ' +' : ''
  let icon = winwidth(0) > 70 ? WebDevIconsGetFileTypeSymbol() . ' ' : ''
  " let icon = winwidth(0) > 70 ? luaeval("require'nvim-web-devicons'.get_icon(filename)") . ' ' : ''
  return icon . filename . modified
endfunction

function! LightlineFileformat()
  return winwidth(0) > 70 ? &fileformat : ''
endfunction

function! LightlineFiletype()
  return winwidth(0) > 70 ? (&filetype !=# '' ? &filetype : 'no ft') : ''
endfunction

function! CocCurrentFunction()
  return get(b:, 'coc_current_function', '')
endfunction

function! GitSignifyStats()
  if &filetype =~# '\v(help|vimfiler|unite|LuaTree)'
    return ''
  endif
  let [added, modified, removed] = sy#repo#get_stats()
  if added == -1  " this means signify does not recognize diffs.
    return ''
  endif
  return printf('+%d ~%d -%d', added, modified, removed)
endfunction

" function! StatusDiagnostic() abort
"   let info = get(b:, 'coc_diagnostic_info', {})

"   if get(info, 'error', 0)
"     return ""
"   endif

"   if get(info, 'warning', 0)
"     return info['warning'] . ""
"   endif

"   return ""
" endfunction

function! StatusDiagnostic() abort
  if &filetype =~# '\v(help|vimfiler|unite|LuaTree)' || &buftype ==# "terminal"
    return ''
  endif
  let info = luaeval("require('lsp-status').diagnostics()")

  if get(info, 'errors', 0)
    return ""
  endif

  if get(info, 'warnings', 0)
    return info['warnings'] . " "
  endif

  return ""
endfunction

" function! LspStatus() abort
"   if luaeval('#vim.lsp.buf_get_clients() > 0')
"     return luaeval("require('lsp-status').status()")
"   endif

"   return ''
" endfunction

" Use autocmd to force lightline update.
autocmd User CocStatusChange,CocDiagnosticChange call lightline#update()


" === Appearance === "
let g:one_allow_italics = 1
let g:onedark_terminal_italic = 1

set background=dark
" Allow color schemes to do bright colors without forcing bold.
if &t_Co == 8 && $TERM !~# '^linux'
  set t_Co=16
endif
" set t_Co=256
" set t_ut=
colorscheme one
call one#highlight('Normal', '', '24282c', 'none') " dark
highlight clear SignColumn " set SignColumn/Gutter to dark background color
