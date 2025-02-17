-- vim: foldmethod=marker
local cmd, fn, opt = vim.cmd, vim.fn, vim.opt
local command = vim.api.nvim_create_user_command

require 'conf.filetype'
require 'conf.diagnostics'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
    vim.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }, { text = true }):wait()
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = ' ' -- set leader to space
vim.g.maplocalleader = ','

require('lazy').setup {
    spec = {
        { import = 'plugins' },
    },
    install = { colorscheme = { 'one' } },
    checker = { enabled = true },
    diff = {
        cmd = 'diffview.nvim',
    },
    performance = {
        rtp = {
            disabled_plugins = {
                '2html_plugin',
                'tohtml',
                'getscript',
                'getscriptPlugin',
                'gzip',
                'logipat',
                'netrw',
                'netrwPlugin',
                'netrwSettings',
                'netrwFileHandlers',
                'matchit',
                'matchparen',
                'tar',
                'tarPlugin',
                'rrhelper',
                'spellfile_plugin',
                'vimball',
                'vimballPlugin',
                'zip',
                'zipPlugin',
                'tutor',
                'rplugin',
                'syntax',
                'synmenu',
                'optwin',
                'compiler',
                'bugreport',
                'python_provider',
                'ruby_provider',
                'perl_provider',
            },
        },
    },
}
require 'conf.lsp'
vim.o.exrc = true
-----------------------------------------------------------------------------//
-- Utils {{{1
-----------------------------------------------------------------------------//
opt.sessionoptions = {
    'blank',
    'buffers',
    'curdir',
    'folds',
    'tabpages',
    'terminal',
    'winsize',
    'winpos',
}
opt.completeopt = { 'menu', 'menuone', 'noselect' } -- Completion options
opt.clipboard = 'unnamedplus'
opt.inccommand = 'nosplit'

local executable = function(e)
    return fn.executable(e) > 0
end

-- Restore cursor on opening buffer
-- Automatically opens fold (if needed) and centers the view
-- original from https://github.com/fmadriessen/.dotfiles/blob/07d679e31e1cb9bc02545135411ffb127f506c59/xdg_config/nvim/lua/config/autocmds.lua
local ignore_filetype = { 'gitcommit', 'gitrebase' }
local ignore_buftype = { 'quickfix', 'nofile', 'help' }
vim.api.nvim_create_autocmd('BufReadPost', {
    desc = 'Restore cursor to last known position',
    group = vim.api.nvim_create_augroup('restore_cursor', { clear = true }),
    callback = function()
        if vim.tbl_contains(ignore_filetype, vim.bo.filetype) then
            return
        end

        if vim.tbl_contains(ignore_buftype, vim.bo.buftype) then
            return
        end

        local row, col = unpack(vim.api.nvim_buf_get_mark(0, '"'))
        if row > 0 and row <= vim.api.nvim_buf_line_count(0) then
            vim.api.nvim_win_set_cursor(0, { row, col })

            if vim.api.nvim_eval 'foldclosed(\'.\')' ~= -1 then
                vim.api.nvim_input 'zv'
            end
        end
    end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank {
            higroup = 'Search',
            timeout = 250,
            on_visual = true,
        }
    end,
    desc = 'highlight yanked text briefly',
})

vim.api.nvim_create_autocmd('VimResized', {
    command = 'tabdo horizontal wincmd =',
    desc = 'resize splits when Vim is resized',
})

vim.api.nvim_create_autocmd('QuitPre', {
    callback = function()
        local invalid_wins = {}
        local wins = vim.api.nvim_list_wins()
        for _, w in ipairs(wins) do
            local buf = vim.api.nvim_win_get_buf(w)

            if
                vim.tbl_contains({ 'nofile', 'quickfix' }, vim.bo[buf].buftype)
                or vim.api.nvim_win_get_config(w).relative ~= '' -- floating window
            then
                table.insert(invalid_wins, w)
            end
        end
        if #invalid_wins == #wins - 1 then
            -- Should quit, so we close all invalid windows.
            for _, w in ipairs(invalid_wins) do
                vim.api.nvim_win_close(w, true)
            end
        end
    end,
    desc = 'Close accessory windows on quit',
})

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
opt.number = true -- line numbers
opt.relativenumber = false -- relative line numbers
opt.numberwidth = 2
opt.signcolumn = 'auto:1-2' -- 'auto:1-2', 'yes:1'
opt.cursorline = true
opt.laststatus = 3 -- global statusline
vim.api.nvim_create_augroup('cursorline_focus', {})
vim.api.nvim_create_autocmd({ 'InsertLeave', 'WinEnter' }, {
    group = 'cursorline_focus',
    callback = function()
        vim.wo.cursorline = true
    end,
})
vim.api.nvim_create_autocmd({ 'InsertEnter', 'WinLeave' }, {
    group = 'cursorline_focus',
    callback = function()
        vim.wo.cursorline = false
    end,
})
opt.wrap = true
opt.linebreak = true -- wrap, but on words, not randomly
-- opt.textwidth = 80
-- vim.cmd.syntax 'off' -- disable legacy syntax highlighting
opt.synmaxcol = 1024 -- don't syntax highlight long lines
vim.g.vimsyn_embed = 'lPr' -- allow embedded syntax highlighting for lua, python, ruby
vim.g.no_plugin_maps = 1
opt.showmode = false
opt.emoji = false -- turn off as they are treated as double width characters
opt.virtualedit = 'onemore' -- allow cursor to move past end of line in visual block mode, needed for my custom paste mapping
opt.list = true -- show invisible characters
opt.listchars = {
    eol = ' ', -- ¬↴
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
opt.foldmethod = 'marker' -- or 'syntax'
opt.foldexpr = 'nvim_treesitter#foldexpr()'

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
-- opt.splitkeep = 'screen'
opt.fillchars = {
    vert = '│',
    fold = ' ',
    diff = '╱', -- alternatives: ⣿ ░
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
opt.updatetime = 100
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
command(
    'Term',
    'botright vsplit term://$SHELL',
    { desc = 'Open a terminal split on the right' }
)

vim.api.nvim_create_autocmd('TermOpen', {
    callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.cursorline = false
    end,
    desc = 'Terminal visual tweaks',
})
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter', 'WinEnter' }, {
    pattern = 'term://*',
    callback = function()
        vim.api.nvim_command 'startinsert'
    end,
    desc = 'Enter insert mode when switching to terminal',
})
vim.api.nvim_create_autocmd('BufLeave', {
    pattern = 'term://*',
    callback = function()
        vim.api.nvim_command 'stopinsert'
    end,
    desc = 'Close terminal buffer on process exit',
})

-- autocmd TermClose term://* call nvim_input('<CR>')
-- autocmd TermClose * call feedkeys("i")

-----------------------------------------------------------------------------//
-- Mouse {{{1
-----------------------------------------------------------------------------//
opt.mouse = 'a'
opt.mousemodel = 'extend'

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
-- Mappings {{{1
-----------------------------------------------------------------------------//
-- <space><space> switches between buffers
-- vim.keymap.set('n', '<leader><leader>', ':b#<CR>')

-- Disable hjkl (get used to sneak)
-- vim.keymap.set('n', 'j', '<Nop>')
-- vim.keymap.set('n', 'k', '<Nop>')
-- vim.keymap.set('n', 'h', '<Nop>')
-- vim.keymap.set('n', 'l', '<Nop>')

-- Sane movement defaults that works on long wrapped lines
local expr = { expr = true, noremap = false, silent = false }
vim.keymap.set('n', 'j', '(v:count ? \'j\' : \'gj\')', expr)
vim.keymap.set('n', 'k', '(v:count ? \'k\' : \'gk\')', expr)
vim.keymap.set('', '<Down>', '(v:count ? \'j\' : \'gj\')', expr)
vim.keymap.set('', '<Up>', '(v:count ? \'k\' : \'gk\')', expr)

-- Easier splits navigation
local remap = { remap = true, silent = false }
vim.keymap.set('n', '<C-j>', '<C-w>j', remap)
vim.keymap.set('n', '<C-k>', '<C-w>k', remap)
vim.keymap.set('n', '<C-h>', '<C-w>h', remap)
vim.keymap.set('n', '<C-l>', '<C-w>l', remap)

-- Use alt + hjkl to resize windows
vim.keymap.set('n', '<M-j>', '<cmd>resize -2<CR>')
vim.keymap.set('n', '<M-k>', '<cmd>resize +2<CR>')
vim.keymap.set('n', '<M-h>', '<cmd>vertical resize -2<CR>')
vim.keymap.set('n', '<M-l>', '<cmd>vertical resize +2<CR>')
-- it works differently on Mac
vim.keymap.set('n', '∆', '<cmd>resize -2<CR>')
vim.keymap.set('n', '˚', '<cmd>resize +2<CR>')
vim.keymap.set('n', '˙', '<cmd>vertical resize -2<CR>')
vim.keymap.set('n', '¬', '<cmd>vertical resize +2<CR>')

-- Terminal window navigation
vim.keymap.set('t', '<C-h>', '<C-\\><C-N><C-w>h', remap)
vim.keymap.set('t', '<C-j>', '<C-\\><C-N><C-w>j', remap)
vim.keymap.set('t', '<C-k>', '<C-\\><C-N><C-w>k', remap)
vim.keymap.set('t', '<C-l>', '<C-\\><C-N><C-w>l', remap)
vim.keymap.set('t', '<C-[><C-[>', '<C-\\><C-N>') -- double ESC to escape terminal

-- more intuitive wildmenu navigation
-- vim.keymap.set('c', '<Up>', [[wildmenumode() ? "\<Left>" : "\<Up>"]], expr)
-- vim.keymap.set('c', '<Down>', [[wildmenumode() ? "\<Right>" : "\<Down>"]], expr)
-- vim.keymap.set('c', '<Left>', [[wildmenumode() ? "\<Up>" : "\<Left>"]], expr)
-- vim.keymap.set(
--     'c',
--     '<Right>',
--     [[wildmenumode() ? " \<BS>\<C-Z>" : "\<Right>"]],
--     expr
-- )

-- command mode
vim.keymap.set('c', '<C-j>', '<Down>')
vim.keymap.set('c', '<C-k>', '<Up>')
vim.keymap.set('c', '<C-a>', '<Home>')
vim.keymap.set('c', '<C-e>', '<End>')

-- insert mode
vim.keymap.set('i', '<C-j>', '<Down>')
vim.keymap.set('i', '<C-k>', '<Up>')
vim.keymap.set('i', '<C-h>', '<Left>')
vim.keymap.set('i', '<C-l>', '<Right>')

-- Better indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Move selected line / block of text in visual mode
-- shift + k to move up
-- shift + j to move down
vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv')
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv')

-- ctrl + a: select all
vim.keymap.set('n', '<C-a>', '<esc>ggVG<CR>')

-- navigate paragraphs without altering jumplist
local silent = { silent = true }
vim.keymap.set(
    'n',
    '}',
    ':<C-u>execute "keepjumps norm! " . v:count1 . "}"<CR>',
    silent
)
vim.keymap.set(
    'n',
    '{',
    ':<C-u>execute "keepjumps norm! " . v:count1 . "{"<CR>',
    silent
)

-- alternate file
vim.keymap.set('n', '<C-6>', '<C-^>')

-- sensible defaults
vim.keymap.set('', 'Q', '') -- disable
vim.keymap.set('n', 'x', '"_x') -- delete char without yank
vim.keymap.set('x', 'x', '"_x') -- delete visual selection without yank

-- paste in visual mode and keep available
vim.keymap.set('x', 'p', [['pgv"'.v:register.'y`>']], expr)
vim.keymap.set('x', 'P', [['Pgv"'.v:register.'y`>']], expr)
-- select last inserted text
vim.keymap.set('n', 'gV', [['`[' . strpart(getregtype(), 0, 1) . '`]']], expr)

-- edit & source init.lua
-- vim.keymap.set('n', '<leader>v', ':e $MYVIMRC<CR>')
-- vim.keymap.set('n', '<leader>s', ':luafile $MYVIMRC<CR>')

-- Vimdiff as mergetool
vim.keymap.set('n', '<leader>1', ':diffget //1<CR>')
vim.keymap.set('n', '<leader>2', ':diffget //2<CR>')
vim.keymap.set('n', '<leader>3', ':diffget //3<CR>')

-- quickfix navigation
vim.keymap.set('n', ']q', ':cnext<CR>')
vim.keymap.set('n', '[q', ':cprevious<CR>')

--  ctrl + / nohighlight
vim.keymap.set('n', '<C-_>', ':noh<CR>')

-- cycle tabs
vim.keymap.set('n', ']]', '<cmd>tabnext<CR>')
vim.keymap.set('n', '[[', '<cmd>tabprevious<CR>')

-----------------------------------------------------------------------------//
-- Commands {{{1
-----------------------------------------------------------------------------//

command('Cclear', 'cexpr []', { desc = 'clear QuickFix list' })
command('TabDir', 'tcd %:p:h', {
    desc = 'change working directory of current tab to the directory of the currently open file',
})

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
-- HACK: workaround for libuv issue, exit code 134
-- vim.api.nvim_create_autocmd({ 'VimLeave' }, {
--     callback = function()
--         vim.cmd 'sleep 10m'
--     end,
-- })

local function keymap_exists(mode, key)
    local mappings = vim.api.nvim_get_keymap(mode)

    local lhs_mappings = vim.tbl_map(function(mapping)
        return mapping.lhs
    end, mappings)

    return vim.tbl_contains(lhs_mappings, key)
end

-- remove some default keymaps
if keymap_exists('n', 'grr') then
    vim.keymap.del('n', 'grr')
end
if keymap_exists('n', 'gra') then
    vim.keymap.del('n', 'gra')
end
if keymap_exists('n', 'grn') then
    vim.keymap.del('n', 'grn')
end
