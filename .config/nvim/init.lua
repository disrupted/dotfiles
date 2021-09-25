local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()
local opt = vim.opt

local execute = vim.api.nvim_command

local install_path = fn.stdpath 'data' .. '/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    execute(
        '!git clone https://github.com/wbthomason/packer.nvim'
            .. ' '
            .. install_path
    )
end

cmd [[packadd packer.nvim]]
local packer = require 'packer'
local use = packer.use
-- cmd [[autocmd BufWritePost init.lua PackerCompile]]

packer.startup(function()
    use { 'wbthomason/packer.nvim', opt = true }
    use {
        'disrupted/one.nvim', -- personal tweaked colorscheme
        config = function()
            vim.cmd 'colorscheme one'
        end,
    }
    use {
        'blackCauldron7/surround.nvim',
        event = { 'BufRead', 'BufNewFile' },
        config = function()
            require('conf.surround').config()
        end,
    }
    use {
        'b3nj5m1n/kommentary',
        event = { 'BufRead', 'BufNewFile' },
        config = function()
            require('conf.kommentary').config()
        end,
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        event = { 'BufRead', 'BufNewFile' },
        requires = {
            {
                'nvim-treesitter/nvim-treesitter-refactor',
                after = 'nvim-treesitter',
            },
            {
                'nvim-treesitter/nvim-treesitter-textobjects',
                after = 'nvim-treesitter',
            },
            {
                'lewis6991/spellsitter.nvim',
                after = 'nvim-treesitter',
                config = function()
                    require('spellsitter').setup {
                        hl = 'SpellBad',
                        captures = {},
                    }
                end,
                disable = true, -- not working for now
            },
        },
        run = ':TSUpdate',
        config = function()
            require('conf.treesitter').config()
        end,
    }
    use {
        'neovim/nvim-lspconfig',
        opt = true,
        event = { 'BufRead' },
        setup = function()
            require('conf.lsp').setup()
        end,
        config = function()
            require('conf.lsp').config()
        end,
        requires = {
            { 'nvim-lua/lsp-status.nvim', opt = true },
        },
    }
    use { 'jose-elias-alvarez/null-ls.nvim', opt = true, module = 'null-ls' }
    use 'folke/lua-dev.nvim'
    use {
        'L3MON4D3/LuaSnip',
        opt = true,
        event = { 'InsertEnter' },
        config = function()
            require 'conf.snippets'
        end,
        requires = { 'rafamadriz/friendly-snippets', opt = true },
    }
    use {
        'hrsh7th/nvim-cmp',
        -- module = 'cmp',
        event = { 'InsertEnter' },
        config = function()
            require('conf.cmp').config()
        end,
        requires = {
            { 'saadparwaiz1/cmp_luasnip', after = 'nvim-cmp' },
            { 'hrsh7th/cmp-nvim-lsp', opt = true },
            { 'hrsh7th/cmp-buffer', after = 'nvim-cmp' },
            { 'hrsh7th/cmp-path', after = 'nvim-cmp' },
            { 'f3fora/cmp-spell', after = 'nvim-cmp' },
        },
        after = 'LuaSnip',
    }
    use {
        'abecodes/tabout.nvim',
        event = { 'InsertEnter' },
        config = function()
            require('conf.tabout').config()
        end,
        wants = { 'nvim-treesitter' },
        after = { 'nvim-cmp' },
    }
    use {
        -- Debug Adapter Protocol client
        'mfussenegger/nvim-dap',
        opt = true,
        -- ft = {
        --     'python',
        --     'javascript',
        --     'typescript',
        --     'javascriptreact',
        --     'typescriptreact',
        -- },
        module = 'dap',
        requires = {
            { 'mfussenegger/nvim-dap-python', opt = true },
            {
                'theHamsta/nvim-dap-virtual-text',
                opt = true,
                after = 'nvim-treesitter',
            },
            { 'David-Kunz/jester', opt = true },
            {
                'rcarriga/nvim-dap-ui',
                opt = true,
            },
        },
        setup = function()
            require('conf.dap').setup()
        end,
        config = function()
            require('conf.dap').config()
        end,
    }
    use {
        'kyazdani42/nvim-tree.lua',
        opt = true,
        cmd = { 'NvimTreeOpen', 'NvimTreeToggle' },
        setup = function()
            require('conf.nvim_tree').setup()
        end,
        config = function()
            require('conf.nvim_tree').config()
        end,
        requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    }
    use {
        'nvim-telescope/telescope.nvim',
        module = 'telescope',
        setup = function()
            require('conf.telescope').setup()
        end,
        config = function()
            require('conf.telescope').config()
        end,
        requires = { { 'nvim-lua/popup.nvim' }, { 'nvim-lua/plenary.nvim' } },
    }
    use {
        'nvim-telescope/telescope-fzf-native.nvim',
        run = 'make',
        after = { 'telescope.nvim' },
        config = function()
            require('telescope').load_extension 'fzf'
        end,
    }
    use {
        'nvim-telescope/telescope-dap.nvim',
        after = { 'telescope.nvim', 'nvim-dap' },
        config = function()
            require('telescope').load_extension 'dap'
        end,
    }
    use {
        'nvim-telescope/telescope-github.nvim',
        after = { 'telescope.nvim' },
        config = function()
            require('telescope').load_extension 'gh'
        end,
    }
    use {
        'NTBBloodbath/galaxyline.nvim',
        opt = true,
        event = { 'VimEnter' },
        config = function()
            require 'conf.statusline'
        end,
        requires = { 'kyazdani42/nvim-web-devicons', opt = true },
        disable = true,
    }
    use {
        'famiu/feline.nvim',
        opt = true,
        -- branch = 'develop',
        tag = 'v0.2',
        event = { 'VimEnter' },
        config = function()
            vim.cmd [[packadd nvim-web-devicons]]
            require 'conf.feline'
        end,
        requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    }
    use {
        'lewis6991/gitsigns.nvim',
        event = { 'BufRead', 'BufNewFile' },
        config = function()
            require('conf.gitsigns').config()
        end,
        requires = { 'nvim-lua/plenary.nvim' },
    }
    use {
        'TimUntersberger/neogit',
        module = 'neogit',
        setup = function()
            require('conf.neogit').setup()
        end,
        config = function()
            require('conf.neogit').config()
        end,
    }
    use {
        'windwp/nvim-autopairs',
        opt = true,
        event = { 'InsertCharPre' },
        after = { 'nvim-cmp', 'nvim-treesitter' },
        config = function()
            require('conf.autopairs').config()
        end,
    }
    use { 'kosayoda/nvim-lightbulb', opt = true, module = 'nvim-lightbulb' }
    use {
        'numToStr/Navigator.nvim',
        module = 'Navigator',
        setup = function()
            require('conf.navigator').setup()
        end,
        config = function()
            require('conf.navigator').config()
        end,
    }
    use {
        'kassio/neoterm',
        cmd = { 'Ttoggle' },
        config = function()
            require('conf.neoterm').config()
        end,
    }
    use { 'hkupty/iron.nvim', opt = true } -- REPL
    use {
        'phaazon/hop.nvim',
        cmd = { 'HopWord', 'HopChar1', 'HopPattern' },
        setup = function()
            require('conf.hop').setup()
        end,
    }
    use {
        'lukas-reineke/indent-blankline.nvim',
        event = { 'BufRead' },
        config = function()
            require('conf.indentline').config()
        end,
    }
    use {
        'disrupted/pylance.nvim',
        run = 'bash ./install.sh',
        opt = true,
    }
    use { 'simrat39/rust-tools.nvim', opt = true }
    use { 'mfussenegger/nvim-jdtls', opt = true }
    -- use { 'zsugabubus/crazy8.nvim', event = { 'BufRead' } } -- detect indentation automatically
    use {
        'folke/trouble.nvim',
        cmd = { 'Trouble', 'TroubleToggle' },
        setup = function()
            require('conf.trouble').setup()
        end,
        config = function()
            require('conf.trouble').config()
        end,
        requires = { 'kyazdani42/nvim-web-devicons', opt = true },
    }
    use {
        'simrat39/symbols-outline.nvim',
        cmd = 'SymbolsOutline',
        setup = function()
            require('conf.outline').setup()
        end,
        config = function()
            require('conf.outline').config()
        end,
    }
    use {
        'folke/persistence.nvim',
        event = 'VimLeavePre',
        module = 'persistence',
        setup = function()
            require('conf.persistence').setup()
        end,
        config = function()
            require('conf.persistence').config()
        end,
    }
    use {
        'kevinhwang91/nvim-bqf',
        opt = true,
        event = { 'BufWinEnter quickfix' },
        config = function()
            require('conf.quickfix').config()
        end,
    }
    use { 'sindrets/diffview.nvim', opt = true, cmd = 'DiffviewOpen' }
    use {
        'michaelb/sniprun',
        run = 'bash ./install.sh',
        cmd = { 'SnipRun', 'SnipInfo' },
    }
    use {
        'NTBBloodbath/rest.nvim',
        opt = true,
        ft = { 'http' },
        config = function()
            require('conf.rest').config()
        end,
        wants = { 'nvim-lua/plenary.nvim' },
    }
    use { 'tversteeg/registers.nvim', opt = true }
    use { 'soywod/himalaya', opt = true, cmd = 'Himalaya' }
    use {
        'folke/todo-comments.nvim',
        cmd = { 'TodoQuickFix', 'TodoTrouble', 'TodoTelescope' },
        config = function()
            require('todo-comments').setup {}
        end,
    }
    use {
        'famiu/bufdelete.nvim',
        cmd = { 'Bdelete', 'Bwipeout' },
        setup = function()
            require('conf.bufdelete').setup()
        end,
    }
    use {
        'kwkarlwang/bufresize.nvim',
        opt = true,
        module = 'bufresize',
        setup = function()
            vim.cmd [[autocmd VimResized * lua require('bufresize').resize()]]
        end,
    }
    use {
        'pwntester/octo.nvim',
        opt = true,
        cmd = 'Octo',
        config = function()
            require('conf.octo').config()
        end,
    }
    use {
        'ThePrimeagen/harpoon',
        opt = true,
        module = 'harpoon',
        setup = function()
            require('conf.harpoon').setup()
        end,
        config = function()
            require('conf.harpoon').config()
        end,
    }
    -- UI component library
    use {
        'MunifTanjim/nui.nvim',
    }
    -- Syntax for Helm chart templates
    use { 'towolf/vim-helm', opt = true, ft = 'helm' }
    use {
        'henriquehbr/nvim-startup.lua',
        config = function()
            require('nvim-startup').setup()
        end,
        disable = true,
    }
    use {
        'AckslD/nvim-neoclip.lua',
        opt = true,
        module = 'neoclip',
        event = { 'TextYankPost' },
        setup = function()
            require('conf.neoclip').setup()
        end,
        config = function()
            require('conf.neoclip').config()
        end,
    }
    use { 'ellisonleao/glow.nvim', opt = true, cmd = 'Glow' }
end)

local executable = function(e)
    return fn.executable(e) > 0
end

-----------------------------------------------------------------------------//
-- Utils {{{1
-----------------------------------------------------------------------------//
opt.complete:prepend { 'kspell' }
-- opt.spell = true
opt.completeopt = { 'menuone', 'noselect' } -- Completion options
opt.clipboard = 'unnamedplus'
opt.inccommand = 'nosplit'

if fn.filereadable '~/.local/share/virtualenvs/debugpy/bin/python' then
    vim.g.python3_host_prog = '~/.local/share/virtualenvs/debugpy/bin/python'
end

-- nonumber for commits
cmd [[
    autocmd BufReadPost * if &ft =~ "commit" | setlocal nonumber norelativenumber | endif
]]

-- highlight yanked text briefly
cmd [[autocmd TextYankPost * silent! lua vim.highlight.on_yank {higroup="Search", timeout=250, on_visual=false}]]

-- resize splits when Vim is resized
-- cmd [[autocmd VimResized * wincmd =]]

-- Trim trailing whitespace and trailing blank lines on save
function _G.trim_trailing_whitespace()
    local current_view = fn.winsaveview()
    cmd [[keeppatterns %s/\s\+$//e]]
    fn.winrestview(current_view)
end
cmd [[command! TrimWhitespace lua trim_trailing_whitespace()]]

function _G.trim_trailing_lines()
    local last_line = vim.api.nvim_buf_line_count(0)
    local last_nonblank_line = fn.prevnonblank(last_line)
    if last_line > 0 and last_nonblank_line ~= last_line then
        vim.api.nvim_buf_set_lines(0, last_nonblank_line, -1, true, {})
    end
end
cmd [[command! TrimTrailingLines lua trim_trailing_lines()]]

function _G.trim()
    if not vim.o.binary and vim.o.filetype ~= 'diff' then
        trim_trailing_lines()
        trim_trailing_whitespace()
    end
end
cmd [[
    augroup trim_on_save
        autocmd! * <buffer>
        autocmd BufWritePre <buffer> lua trim()
    augroup END
]]

function _G.inspect(args)
    print(vim.inspect(args))
end

-----------------------------------------------------------------------------//
-- Indentation {{{1
-----------------------------------------------------------------------------//
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 4 -- Size of an indent
opt.smartindent = true -- Insert indents automatically
opt.tabstop = 4 -- Number of spaces tabs count for
opt.softtabstop = 4
opt.shiftround = true -- Round indent
opt.joinspaces = false -- No double spaces with join after a dot

-----------------------------------------------------------------------------//
-- Display {{{1
-----------------------------------------------------------------------------//
opt.number = true -- Print line number
opt.relativenumber = true -- Relative line numbers
opt.numberwidth = 2
opt.signcolumn = 'yes:1' -- 'auto:1-2'
opt.cursorline = true
cmd [[
    augroup cursorline_focus
        autocmd!
        autocmd WinEnter * if (&bt == '') | setlocal cursorline
        autocmd WinLeave * if (&bt == '') | setlocal nocursorline
    augroup END
    ]]
opt.wrap = true
opt.linebreak = true -- wrap, but on words, not randomly
-- opt.textwidth = 80
opt.synmaxcol = 1024 -- don't syntax highlight long lines
vim.g.vimsyn_embed = 'lPr' -- allow embedded syntax highlighting for lua, python, ruby
opt.showmode = false
opt.lazyredraw = true
opt.emoji = false -- turn off as they are treated as double width characters
opt.virtualedit = 'onemore' -- allow cursor to move past end of line in visual block mode, needed for my custom paste mapping
opt.list = true -- show invisible characters
opt.listchars = {
    eol = ' ',
    tab = '→ ',
    extends = '…',
    precedes = '…',
    trail = '·',
}
opt.shortmess:append 'I' -- disable :intro startup screen

-----------------------------------------------------------------------------//
-- Title {{{1
-----------------------------------------------------------------------------//
opt.titlestring = '❐ %t'
opt.titleold = '%{fnamemodify(getcwd(), ":t")}'
opt.title = true
opt.titlelen = 70

-----------------------------------------------------------------------------//
-- Folds {{{1
-----------------------------------------------------------------------------//
opt.foldtext = 'folds#render()'
opt.foldopen:append { 'search' }
opt.foldlevelstart = 10
opt.foldmethod = 'syntax'
-- opt.foldmethod = 'expr'
-- opt.foldexpr='nvim_treesitter#foldexpr()'

-----------------------------------------------------------------------------//
-- Backup {{{1
-----------------------------------------------------------------------------//
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true -- Save undo history
opt.confirm = true -- prompt to save before destructive actions

-----------------------------------------------------------------------------//
-- Search {{{1
-----------------------------------------------------------------------------//
opt.ignorecase = true -- Ignore case
opt.smartcase = true -- Don't ignore case with capitals
opt.wrapscan = true -- Search wraps at end of file
opt.scrolloff = 4 -- Lines of context
-- opt.sidescrolloff = 8 -- Columns of context
opt.showmatch = true

-- Use faster grep alternatives if possible
if executable 'rg' then
    opt.grepprg =
        [[rg --hidden --glob "!.git" --no-heading --smart-case --vimgrep --follow $*]]
    opt.grepformat:prepend { '%f:%l:%c:%m' }
end

-----------------------------------------------------------------------------//
-- Motions & Text Objects {{{1
-----------------------------------------------------------------------------//
opt.iskeyword:prepend { '-' } -- treat dash separated words as a word textobject

-----------------------------------------------------------------------------//
-- window splitting and buffers {{{1
-----------------------------------------------------------------------------//
opt.hidden = true -- Enable modified buffers in background
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.fillchars = {
    vert = '│',
    fold = ' ',
    diff = '-', -- alternatives: ⣿ ░
    msgsep = '‾',
    foldopen = '▾',
    foldsep = '│',
    foldclose = '▸',
}

-----------------------------------------------------------------------------//
-- Wild and file globbing stuff in command mode {{{1
-----------------------------------------------------------------------------//
opt.wildignorecase = true -- Ignore case when completing file names and directories
opt.wildcharm = 26 -- equals set wildcharm=<C-Z>, used in the mapping section

-- Binary
opt.wildignore = {
    '*.aux,*.out,*.toc',
    '*.o,*.obj,*.dll,*.jar,*.pyc,__pycache__,*.rbc,*.class',
    -- media
    '*.ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp',
    '*.avi,*.m4a,*.mp3,*.oga,*.ogg,*.wav,*.webm',
    '*.eot,*.otf,*.ttf,*.woff',
    '*.doc,*.pdf',
    -- archives
    '*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz',
    -- temp/system
    '*.*~,*~ ',
    '*.swp,.lock,.DS_Store,._*,tags.lock',
    -- version control
    '.git,.svn',
}
opt.wildoptions = 'pum'
opt.pumblend = 7 -- Make popup window translucent
opt.pumheight = 20 -- Limit the amount of autocomplete items shown

-----------------------------------------------------------------------------//
-- Timings {{{1
-----------------------------------------------------------------------------//
opt.updatetime = 300
opt.timeout = true
opt.timeoutlen = 1000
opt.ttimeoutlen = 10

-----------------------------------------------------------------------------//
-- Diff {{{1
-----------------------------------------------------------------------------//
-- Use in vertical diff mode, blank lines to keep sides aligned, Ignore whitespace changes
opt.diffopt:prepend {
    'vertical',
    'iwhite',
    'hiddenoff',
    'foldcolumn:0',
    'context:4',
    'algorithm:histogram',
    'indent-heuristic',
}

-----------------------------------------------------------------------------//
-- Terminal {{{1
-----------------------------------------------------------------------------//
-- Open a terminal pane on the right using :Term
cmd [[command Term :botright vsplit term://$SHELL]]

-- Terminal visual tweaks
-- Enter insert mode when switching to terminal
-- Close terminal buffer on process exit
cmd [[
    autocmd TermOpen * setlocal listchars= nonumber norelativenumber nocursorline
    autocmd TermOpen * startinsert
    autocmd BufEnter,BufWinEnter,WinEnter term://* startinsert
    autocmd BufLeave term://* stopinsert
    autocmd TermClose term://* call nvim_input('<CR>')
    autocmd TermClose * call feedkeys("i")
]]

-----------------------------------------------------------------------------//
-- Mouse {{{1
-----------------------------------------------------------------------------//
opt.mouse = 'a'

-----------------------------------------------------------------------------//
-- Netrw {{{1
-----------------------------------------------------------------------------//
-- do not display info on the top of window
vim.g.netrw_banner = 0

-----------------------------------------------------------------------------//
-- Colorscheme {{{1
-----------------------------------------------------------------------------//
opt.termguicolors = true

-----------------------------------------------------------------------------//
-- Providers {{{1
-----------------------------------------------------------------------------//
-- disable some builtin providers we don't use
vim.tbl_map(function(p)
    vim.g['loaded_' .. p] = vim.endswith(p, 'provider') and 0 or 1
end, {
    '2html_plugin',
    'gzip',
    'matchit',
    'netrw',
    'netrwPlugin',
    'python_provider',
    'ruby_provider',
    'perl_provider',
    'tar',
    'tarPlugin',
    'vimball',
    'vimballPlugin',
    'zip',
    'zipPlugin',
})

-----------------------------------------------------------------------------//
-- Mappings {{{1
-----------------------------------------------------------------------------//
local map = require('utils').map

-- set leader to space
vim.g.mapleader = ' '
-- <space><space> switches between buffers
map('n', '<leader><leader>', ':b#<CR>')

-- Sane movement defaults that works on long wrapped lines
map('', 'j', '(v:count ? \'j\' : \'gj\')', { expr = true })
map('', 'k', '(v:count ? \'k\' : \'gk\')', { expr = true })
map('', '<Down>', '(v:count ? \'j\' : \'gj\')', { expr = true })
map('', '<Up>', '(v:count ? \'k\' : \'gk\')', { expr = true })

-- Easier splits navigation
map('n', '<C-j>', '<C-w>j', { noremap = false })
map('n', '<C-k>', '<C-w>k', { noremap = false })
map('n', '<C-h>', '<C-w>h', { noremap = false })
map('n', '<C-l>', '<C-w>l', { noremap = false })

-- Use alt + hjkl to resize windows
map('n', '<M-j>', '<cmd>resize -2<CR>')
map('n', '<M-k>', '<cmd>resize +2<CR>')
map('n', '<M-h>', '<cmd>vertical resize -2<CR>')
map('n', '<M-l>', '<cmd>vertical resize +2<CR>')
-- it works differently on Mac
map('n', '∆', '<cmd>resize -2<CR>')
map('n', '˚', '<cmd>resize +2<CR>')
map('n', '˙', '<cmd>vertical resize -2<CR>')
map('n', '¬', '<cmd>vertical resize +2<CR>')

-- Terminal window navigation
map('t', '<C-h>', '<C-\\><C-N><C-w>h', { noremap = false })
map('t', '<C-j>', '<C-\\><C-N><C-w>j', { noremap = false })
map('t', '<C-k>', '<C-\\><C-N><C-w>k', { noremap = false })
map('t', '<C-l>', '<C-\\><C-N><C-w>l', { noremap = false })
map('t', '<C-[><C-[>', '<C-\\><C-N>') -- double ESC to escape terminal

-- more intuitive wildmenu navigation
map('c', '<Up>', [[wildmenumode() ? "\<Left>" : "\<Up>"]], { expr = true })
map('c', '<Down>', [[wildmenumode() ? "\<Right>" : "\<Down>"]], {
    expr = true,
})
map('c', '<Left>', [[wildmenumode() ? "\<Up>" : "\<Left>"]], { expr = true })
map(
    'c',
    '<Right>',
    [[wildmenumode() ? " \<BS>\<C-Z>" : "\<Right>"]],
    { expr = true }
)

-- command mode
map('c', '<C-a>', '<Home>')
map('c', '<C-e>', '<End>')

-- insert mode
map('i', '<C-j>', '<Down>')
map('i', '<C-k>', '<Up>')
map('i', '<C-h>', '<Left>')
map('i', '<C-l>', '<Right>')

-- Better indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Move selected line / block of text in visual mode
-- shift + k to move up
-- shift + j to move down
map('x', 'K', ':move \'<-2<CR>gv-gv')
map('x', 'J', ':move \'>+1<CR>gv-gv')

-- ctrl + a: select all
map('n', '<C-a>', '<esc>ggVG<CR>')

-- sensible defaults
map('', 'Q', '') -- disable
map('n', 'x', '"_x') -- delete char without yank
map('x', 'x', '"_x') -- delete visual selection without yank

-- paste in visual mode and keep available
map('x', 'p', '"_dP')
-- map('x', 'P', '"_dP')

-- edit & source init.lua
map('n', ',v', ':e $MYVIMRC<CR>')
map('n', ',s', ':luafile $MYVIMRC<CR>')

-- Vimdiff as mergetool
map('n', '<leader>1', ':diffget //1<CR>')
map('n', '<leader>2', ':diffget //2<CR>')
map('n', '<leader>3', ':diffget //3<CR>')

-- quickfix navigation
map('n', ']q', ':cnext<CR>')
map('n', '[q', ':cprevious<CR>')

--  ctrl + /: nohighlight
map('n', '<C-_>', ':noh<CR>')

-----------------------------------------------------------------------------//
-- TabLine {{{1
-----------------------------------------------------------------------------//
-- I tend to have a lot of open buffers and bufferlines add too much
-- clutter imo
-- only using custom tabline (for actual tabs) for now mostly to hide the X to close
-- at some point I'd like to write a more powerful tabline in Lua

cmd [[
    :set tabline=%!TabLine()

    function TabLine()
    let s = ''
    " loop through each tab page
    for i in range(tabpagenr('$'))
        if i + 1 == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif
        " set the tab page number
        let s .= '%' . (i + 1) . 'T '
        " set page number string
        let s .= i + 1 . ''
        " get buffer names and statuses
        let n = ''  " temp str for buf names
        let buflist = tabpagebuflist(i + 1)
        " loop through each buffer in a tab
        for b in buflist
        endfor
        let n .= fnamemodify(bufname(buflist[tabpagewinnr(i + 1) - 1]), ':t')
        let n = substitute(n, ', $', '', '')
        " add modified label
        if i + 1 == tabpagenr()
            let s .= ' %#TabLineSel#'
        else
            let s .= ' %#TabLine#'
        endif
        " add buffer names
        if n == ''
            let s .= '[No Name]'
        else
            let s .= n
        endif
        " switch to no underlining and add final space
        let s .= ' '
    endfor
    let s .= '%#TabLineFill#%T'
    return s
    endfunction
]]

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//
