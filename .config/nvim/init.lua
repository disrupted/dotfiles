local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()

-- Install packer
local execute = vim.api.nvim_command

local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    execute('!git clone https://github.com/wbthomason/packer.nvim' .. ' ' ..
                install_path)
end

-- Only required if you have packer in your `opt` pack
cmd [[packadd packer.nvim]]
cmd [[autocmd BufWritePost init.lua PackerCompile]]

local use = require('packer').use
require('packer').startup(function()
    use {'wbthomason/packer.nvim', opt = true}
    use 'tpope/vim-sensible'
    use 'tpope/vim-surround'
    use 'disrupted/one-nvim' -- personal tweaked colorscheme
    use {'b3nj5m1n/kommentary', config = require'conf.kommentary'.config()}
    use {
        'nvim-treesitter/nvim-treesitter',
        event = 'BufRead *',
        requires = {
            -- treesitter plugins
            {
                'nvim-treesitter/nvim-treesitter-refactor',
                after = 'nvim-treesitter'
            },
            {
                'nvim-treesitter/nvim-treesitter-textobjects',
                after = 'nvim-treesitter'
            }
        },
        run = ':TSUpdate',
        config = require'conf.treesitter'.config()
    }
    use {
        'neovim/nvim-lspconfig',
        event = {'BufNewFile *', 'BufRead *'},
        setup = require'conf.lsp'.setup(),
        config = require'conf.lsp'.config(),
        requires = {'nvim-lua/lsp-status.nvim'}
    }
    use {
        'nvim-lua/completion-nvim',
        event = 'InsertEnter *',
        setup = require'conf.completion'.setup(),
        config = require'conf.completion'.config(),
        requires = {
            'norcalli/snippets.nvim',
            {'steelsojka/completion-buffers', after = {'completion-nvim'}}, {
                'nvim-treesitter/completion-treesitter',
                after = {'completion-nvim', 'nvim-treesitter'}
            }
        }
    }
    -- use {'hrsh7th/nvim-compe', setup = require'conf.compe'.setup()}
    use {
        'mfussenegger/nvim-dap',
        opt = false,
        requires = {
            'mfussenegger/nvim-dap-python',
            {'theHamsta/nvim-dap-virtual-text', after = 'nvim-treesitter'}
        },
        setup = require'conf.dap'.setup(),
        config = require'conf.dap'.config()
    }
    use {
        'kyazdani42/nvim-tree.lua',
        setup = require'conf.nvim_tree'.setup(),
        requires = {'kyazdani42/nvim-web-devicons'}
    }
    use {
        'nvim-telescope/telescope.nvim',
        setup = require'conf.telescope'.setup(),
        config = require'conf.telescope'.config(),
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
    }
    use {
        'sunjon/telescope-frecency',
        config = function() require'telescope'.load_extension('frecency') end,
        requires = {'tami5/sql.nvim'}
    }
    use {
        'nvim-telescope/telescope-github.nvim',
        config = function() require'telescope'.load_extension('gh') end
    }
    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        config = function() require 'conf.statusline' end,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {
        'romgrk/barbar.nvim',
        config = function() require 'conf.bufferline' end,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {
        'lewis6991/gitsigns.nvim',
        setup = require'conf.gitsigns'.setup(),
        requires = {'nvim-lua/plenary.nvim'}
    }
    use {'windwp/nvim-autopairs', setup = require'nvim-autopairs'.setup()}
    use {'christoomey/vim-tmux-navigator'}
    use 'dstein64/vim-startuptime'

end)

local executable = function(e) return fn.executable(e) > 0 end
local opts_info = vim.api.nvim_get_all_options_info()
local opt = setmetatable({}, {
    __newindex = function(_, key, value)
        vim.o[key] = value
        local scope = opts_info[key].scope
        if scope == "win" then
            vim.wo[key] = value
        elseif scope == "buf" then
            vim.bo[key] = value
        end
    end
})
local function add(value, str, sep)
    sep = sep or ","
    str = str or ""
    value = type(value) == "table" and table.concat(value, sep) or value
    return str ~= "" and table.concat({value, str}, sep) or value
end

-----------------------------------------------------------------------------//
-- Utils {{{1
-----------------------------------------------------------------------------//
vim.o.completeopt = add {"menu", "noinsert", "noselect", "longest"} -- Completion options
vim.o.clipboard = 'unnamedplus'
vim.o.inccommand = 'nosplit'
vim.o.backspace = 'indent,eol,start' -- Change backspace to behave more intuitively

-- if vim.fn.filereadable('/usr/local/bin/python3') then
--     vim.g.python3_host_prog = '/usr/local/bin/python3'
-- end
if vim.fn.filereadable('~/.local/share/virtualenvs/debugpy/bin/python') then
    vim.g.python3_host_prog = '~/.local/share/virtualenvs/debugpy/bin/python'
end

-----------------------------------------------------------------------------//
-- Indentation {{{1
-----------------------------------------------------------------------------//
opt.autoindent = true -- Allow filetype plugins and syntax highlighting
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2 -- Size of an indent
opt.smartindent = true -- Insert indents automatically
opt.tabstop = 2 -- Number of spaces tabs count for
opt.softtabstop = 2
vim.o.shiftround = true -- Round indent
vim.o.joinspaces = false -- No double spaces with join after a dot

-----------------------------------------------------------------------------//
-- Display {{{1
-----------------------------------------------------------------------------//
vim.wo.number = true -- Print line number
vim.wo.relativenumber = true -- Relative line numbers
vim.wo.signcolumn = 'yes'
vim.wo.cursorline = true
opt.wrap = true
opt.linebreak = true -- wrap, but on words, not randomly
-- opt.textwidth = 80
opt.synmaxcol = 1024 -- don't syntax highlight long lines
vim.g.vimsyn_embed = "lPr" -- allow embedded syntax highlighting for lua, python, ruby
vim.o.showcmd = true -- Set show command
vim.o.showmode = false
vim.o.lazyredraw = true
vim.o.emoji = false -- turn off as they are treated as double width characters
vim.o.virtualedit = 'all' -- allow cursor to move past end of line
vim.o.list = true -- invisible chars
vim.o.listchars = add {
    "eol: ", "tab:→ ", "extends:…", "precedes:…", "trail:·", "nbsp:·",
    "space:·"
}
cmd('set list') -- workaround until vim.o mappings are fixed

-----------------------------------------------------------------------------//
-- Title {{{1
-----------------------------------------------------------------------------//
vim.o.titlestring = "❐ %t"
vim.o.titleold = '%{fnamemodify(getcwd(), ":t")}'
vim.o.title = true
vim.o.titlelen = 70

---------------------------------------------------------------------------//
-- Folds {{{1
-----------------------------------------------------------------------------//
vim.o.foldtext = "folds#render()"
vim.o.foldopen = add(vim.o.foldopen, "search")
vim.o.foldlevelstart = 10
opt.foldmethod = "syntax"

-----------------------------------------------------------------------------//
-- Backup {{{1
-----------------------------------------------------------------------------//
vim.o.swapfile = false
vim.o.backup = false
vim.o.writebackup = false
if fn.isdirectory(vim.o.undodir) == 0 then fn.mkdir(vim.o.undodir, "p") end
opt.undofile = true -- Save undo history
vim.o.confirm = true -- prompt to save before destructive actions

-----------------------------------------------------------------------------//
-- Search {{{1
-----------------------------------------------------------------------------//
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.ignorecase = true -- Ignore case
vim.o.smartcase = true -- Don't ignore case with capitals
vim.o.wrapscan = true -- Search wraps at end of file
vim.o.scrolloff = 4 -- Lines of context
-- vim.o.sidescrolloff = 8 -- Columns of context
vim.o.showmatch = true

-- Use faster grep alternatives if possible
if executable("rg") then
    vim.o.grepprg =
        [[rg --hidden --glob "!.git" --no-heading --smart-case --vimgrep --follow $*]]
    vim.o.grepformat = add("%f:%l:%c:%m", vim.o.grepformat)
end
-----------------------------------------------------------------------------//
-- window splitting and buffers {{{1
-----------------------------------------------------------------------------//
vim.o.hidden = true -- Enable modified buffers in background
vim.o.splitbelow = true -- Put new windows below current
vim.o.splitright = true -- Put new windows right of current
vim.o.fillchars = add {
    "vert:│", "fold: ", "diff:", -- alternatives: ⣿ ░
    "msgsep:‾", "foldopen:▾", "foldsep:│", "foldclose:▸"
}

-----------------------------------------------------------------------------//
-- Wild and file globbing stuff in command mode {{{1
-----------------------------------------------------------------------------//
vim.o.wildmenu = true
vim.o.wildmode = "full" -- Shows a menu bar as opposed to an enormous list
vim.o.wildignorecase = true -- Ignore case when completing file names and directories
-- Binary
vim.o.wildignore = add {
    "*.aux,*.out,*.toc", "*.o,*.obj,*.dll,*.jar,*.pyc,*.rbc,*.class",
    "*.ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp",
    "*.avi,*.m4a,*.mp3,*.oga,*.ogg,*.wav,*.webm", "*.eot,*.otf,*.ttf,*.woff",
    "*.doc,*.pdf", "*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz", -- Cache
    ".sass-cache", "*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*.gem",
    -- Temp/System
    "*.*~,*~ ", "*.swp,.lock,.DS_Store,._*,tags.lock"
}
vim.o.wildoptions = "pum"
vim.o.pumblend = 3 -- Make popup window translucent

-----------------------------------------------------------------------------//
-- Timings {{{1
-----------------------------------------------------------------------------//
vim.o.updatetime = 300
vim.o.timeout = true
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 10

-----------------------------------------------------------------------------//
-- Diff {{{1
-----------------------------------------------------------------------------//
-- Use in vertical diff mode, blank lines to keep sides aligned, Ignore whitespace changes
vim.o.diffopt = add({
    "vertical", "iwhite", "hiddenoff", "foldcolumn:0", "context:4",
    "algorithm:histogram", "indent-heuristic"
}, vim.o.diffopt)

-----------------------------------------------------------------------------//
-- Terminal {{{1
-----------------------------------------------------------------------------//
function _G.__split_term_right()
    execute('botright vsplit term://$SHELL')
    execute('setlocal nonumber')
    execute('setlocal norelativenumber')
    execute('startinsert')
end
vim.cmd("command TermRight :call luaeval('_G.__split_term_right()')")
-- Directly go into insert mode when switching to terminal
cmd [[autocmd BufWinEnter,WinEnter term://* startinsert]]

-----------------------------------------------------------------------------//
-- Mouse {{{1
-----------------------------------------------------------------------------//
vim.o.mouse = "a"

-----------------------------------------------------------------------------//
-- Netrw {{{1
-----------------------------------------------------------------------------//
-- Nerdtree like sidepanel
-- absolute width of netrw window
-- vim.g.netrw_winsize = -28
-- do not display info on the top of window
vim.g.netrw_banner = 0

-----------------------------------------------------------------------------//
-- Colorscheme {{{1
-----------------------------------------------------------------------------//
-- order is important here
vim.o.termguicolors = true
cmd 'colorscheme one-nvim'

-----------------------------------------------------------------------------//
-- Mappings {{{1
-----------------------------------------------------------------------------//
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

-- set leader to space
vim.g.mapleader = " "

map('i', '<C-h>', '<C-w>h', {noremap = false})
map('i', '<C-j>', '<C-w>j', {noremap = false})
map('i', '<C-k>', '<C-w>k', {noremap = false})
map('i', '<C-l>', '<C-w>l', {noremap = false})
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Terminal window navigation
map('t', '<C-h>', '<C-\\><C-N><C-w>h')
map('t', '<C-j>', '<C-\\><C-N><C-w>j')
map('t', '<C-k>', '<C-\\><C-N><C-w>k')
map('t', '<C-l>', '<C-\\><C-N><C-w>l')
map('t', '<C-h>', '<C-\\><C-N><C-w>h')
map('t', '<C-j>', '<C-\\><C-N><C-w>j')
map('t', '<C-k>', '<C-\\><C-N><C-w>k')
map('t', '<C-l>', '<C-\\><C-N><C-w>l')
map('t', '<Esc>', '<C-\\><C-N>')

-- Better indenting
map('v', '<', '<gv')
map('v', '>', '>gv')

-- Move selected line / block of text in visual mode
-- shift + k to move up
-- shift + j to move down
map('x', 'K', ":move '<-2<CR>gv-gv")
map('x', 'J', ":move '>+1<CR>gv-gv")

-- ctrl + a: select all
map('n', '<C-a>', '<esc>ggVG<CR>')

-- edit & source init.lua
map('n', ',v', ':e $MYVIMRC<CR>')
map('n', ',s', ':luafile $MYVIMRC<CR>')

-----------------------------------------------------------------------------//
-- }}}1
-----------------------------------------------------------------------------//
