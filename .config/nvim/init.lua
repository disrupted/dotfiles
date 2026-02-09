-- vim: foldmethod=marker
local opt = vim.opt
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
        cmd = 'codediff.nvim',
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
                -- TODO: might get replaced by matchwith plugin
                -- 'matchit',
                -- 'matchparen',
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
vim.g.health = { style = 'float' }
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

require('conf.workspace').setup()
-- disable global shada; create separate shadafile for each workspace
-- ensures project-scoped jumplist, marks, etc.
--—@return string?
local shadafile = function()
    if not vim.g.workspace_root then
        return
    end
    return vim.fs.joinpath(
        vim.fn.stdpath 'state', ---@diagnostic disable-line: param-type-mismatch
        'shada',
        vim.g.workspace_root:gsub('/', '_') .. '.shada'
    )
end
vim.o.shadafile = shadafile() or 'NONE'

opt.completeopt = { 'menu', 'menuone', 'noselect' } -- Completion options
opt.clipboard = 'unnamedplus'
opt.inccommand = 'nosplit'

local executable = function(e)
    return vim.fn.executable(e) > 0
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

-- FIXME: disabled because it causes weird side effects, e.g. in opencode.nvim
-- https://github.com/sudo-tee/opencode.nvim/issues/144
-- vim.api.nvim_create_autocmd('VimResized', {
--     desc = 'resize splits when Vim is resized',
--     callback = function()
--         vim.schedule(function()
--             local current_tab = vim.api.nvim_get_current_tabpage()
--             vim.cmd 'tabdo wincmd ='
--             vim.api.nvim_set_current_tabpage(current_tab)
--         end)
--     end,
-- })

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
                pcall(vim.api.nvim_win_close, w, true)
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
opt.laststatus = 3 -- global statusline
opt.cursorline = false -- use autocmd below to only enable it for the focused window
local au_cursorline = vim.api.nvim_create_augroup('cursorline_focus', {})
vim.api.nvim_create_autocmd({ 'InsertLeave', 'WinEnter' }, {
    group = au_cursorline,
    callback = function(args)
        if
            vim.bo[args.buf].buftype == 'terminal'
            or vim.bo[args.buf].filetype == 'opencode'
            or vim.bo[args.buf].filetype == 'opencode_output'
        then
            return
        end
        vim.wo.cursorline = true
    end,
    desc = 'Show cursorline in active window',
})
vim.api.nvim_create_autocmd({ 'InsertEnter', 'WinLeave' }, {
    group = au_cursorline,
    callback = function(args)
        vim.wo.cursorline = false
    end,
    desc = 'Hide cursorline in insert mode and inactive windows',
})
vim.go.tabclose = 'left'
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
opt.title = true
opt.titlelen = 70

-----------------------------------------------------------------------------//
-- Folds {{{1
-----------------------------------------------------------------------------//
opt.foldtext = 'folds#render()'
opt.foldopen:append { 'search' }
opt.foldlevelstart = 10
opt.foldmethod = 'marker' -- or 'syntax'

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
    desc = 'Exit insert mode when switching from terminal',
})
vim.api.nvim_create_autocmd('TermClose', {
    pattern = 'term://*' .. vim.o.shell, -- only for default shell, otherwise breaks overseer
    callback = function(args)
        if vim.v.event.status == 0 and vim.api.nvim_buf_is_valid(args.buf) then -- only close on exit code 0
            vim.api.nvim_buf_delete(args.buf, { force = true })
        end
    end,
    desc = 'Close terminal buffer on process exit',
})

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
-- disable suspend
vim.keymap.set({ 'n', 'i', 'v', 'x', 's', 'o', 'c', 't' }, '<C-z>', '<Nop>')

-- <space><space> switches between buffers
-- vim.keymap.set('n', '<Leader><Leader>', ':b#<CR>')

-- Disable hjkl (get used to sneak)
-- vim.keymap.set('n', 'j', '<Nop>')
-- vim.keymap.set('n', 'k', '<Nop>')
-- vim.keymap.set('n', 'h', '<Nop>')
-- vim.keymap.set('n', 'l', '<Nop>')

-- disable increment / decrement
vim.keymap.set({ 'n', 'x' }, '<C-a>', '<Nop>')
vim.keymap.set('x', '<C-x>', '<Nop>') -- normal mode mapped to bufdelete

-- Sane movement defaults that works on long wrapped lines
local expr = { expr = true, noremap = false, silent = false }
vim.keymap.set('n', 'j', '(v:count ? \'j\' : \'gj\')', expr)
vim.keymap.set('n', 'k', '(v:count ? \'k\' : \'gk\')', expr)

-- Easier splits navigation
local remap = { remap = true, silent = false }
vim.keymap.set('n', '<C-j>', '<C-w>j', remap)
vim.keymap.set('n', '<C-k>', '<C-w>k', remap)
vim.keymap.set('n', '<C-h>', '<C-w>h', remap)
vim.keymap.set('n', '<C-l>', '<C-w>l', remap)

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

vim.keymap.set({ 'i', 'c' }, '<M-BS>', '<C-w>', { desc = 'Delete word' })

-- Better indenting
vim.keymap.set('v', '<', '<gv')
vim.keymap.set('v', '>', '>gv')

-- Move selected line / block of text in visual mode
-- shift + k to move up
-- shift + j to move down
vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv')
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv')

-- ctrl + a: select all
-- vim.keymap.set('n', '<C-a>', '<esc>ggVG<CR>')

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

vim.keymap.set('n', '<C-6>', '<C-^>', { desc = 'Alternate buffer' })

-- sensible defaults
vim.keymap.set('', 'Q', '') -- disable
vim.keymap.set('n', 'x', '"_x') -- delete char without yank
vim.keymap.set('x', 'x', '"_x') -- delete visual selection without yank

-- paste and adjust indentation
-- vim.keymap.set('n', 'p', ']p')
-- vim.keymap.set('n', 'P', ']P')
-- paste in visual mode and keep available
vim.keymap.set('x', 'p', [['pgv"'.v:register.'y`>']], expr)
vim.keymap.set('x', 'P', [['Pgv"'.v:register.'y`>']], expr)
-- select last inserted text
vim.keymap.set('n', 'gV', [['`[' . strpart(getregtype(), 0, 1) . '`]']], expr)

-- TODO: only enable when nvim is launched as difftool
--[[ vim.api.nvim_create_autocmd('OptionSet', {
    pattern = 'diff',
    callback = function(args)
        vim.keymap.set(
            'n',
            '<LocalLeader>1',
            ':diffget //1<CR>',
            { buffer = args.buf, desc = 'Choose LOCAL' }
        )
        vim.keymap.set(
            'n',
            '<LocalLeader>2',
            ':diffLocalLeaderget //2<CR>',
            { buffer = args.buf, desc = 'Choose OURS' }
        )
        vim.keymap.set(
            'n',
            '<LocalLeader>3',
            ':diffLocalLeaderget //3<CR>',
            { buffer = args.buf, desc = 'Choose THEIRS' }
        )
    end,
    desc = 'Configure vimdiff as mergetool',
}) ]]

-- quickfix navigation
vim.keymap.set('n', ']q', ':cnext<CR>', { desc = 'Next QuickFix entry' })
vim.keymap.set('n', '[q', ':cprevious<CR>', { desc = 'Prev QuickFix entry' })

--  ctrl + / nohighlight
vim.keymap.set('n', '<C-_>', ':noh<CR>')

-- cycle tabs
vim.keymap.set('n', '<esc>', '<esc>') -- distinguish <C-[> from <esc>
vim.keymap.set('n', '<C-]>', '<cmd>tabnext<CR>', { desc = 'Next tabpage' })
vim.keymap.set('n', '<C-[>', '<cmd>tabprevious<CR>', { desc = 'Prev tabpage' })

-----------------------------------------------------------------------------//
-- Commands {{{1
-----------------------------------------------------------------------------//

command('Cclear', 'cexpr []', { desc = 'clear QuickFix list' })
command('TabDir', 'tcd %:p:h', {
    desc = 'change working directory of current tab to the directory of the currently open file',
})

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//
-- HACK: workaround for libuv issue, exit code 134
-- vim.api.nvim_create_autocmd({ 'VimLeave' }, {
--     callback = function()
--         vim.cmd 'sleep 10m'
--     end,
-- })

---@param mode string
---@param key string
local function keymap_exists(mode, key)
    local mappings = vim.api.nvim_get_keymap(mode)

    local lhs_mappings = vim.tbl_map(function(mapping)
        return mapping.lhs
    end, mappings)

    return vim.tbl_contains(lhs_mappings, key)
end

-- remove some default keymaps
local nmaps_to_delete = { 'grr', 'gra', 'grn', 'gri', 'grt' }
for _, nmap in ipairs(nmaps_to_delete) do
    if keymap_exists('n', nmap) then
        vim.keymap.del('n', nmap)
    end
end
