local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()

local execute = vim.api.nvim_command

local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    execute('!git clone https://github.com/wbthomason/packer.nvim' .. ' ' ..
                install_path)
end

cmd [[packadd packer.nvim]]
local packer = require 'packer'
local use = packer.use
-- cmd [[autocmd BufWritePost init.lua PackerCompile]]

packer.startup(function()
    use {'wbthomason/packer.nvim', opt = true}
    -- use 'jooize/vim-colemak' -- mapping for the colemak keyboard layout
    use {
        'disrupted/one-nvim', -- personal tweaked colorscheme
        config = function() vim.cmd 'colorscheme one-nvim' end
    }
    use {
        'blackCauldron7/surround.nvim',
        event = {'VimEnter'},
        config = require'conf.surround'.config
    }
    use {
        'b3nj5m1n/kommentary',
        event = {'VimEnter'},
        config = require'conf.kommentary'.config
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        event = {'BufRead', 'BufNewFile'},
        requires = {
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
        setup = require'conf.treesitter'.setup,
        config = require'conf.treesitter'.config
    }
    use {
        'neovim/nvim-lspconfig',
        opt = true,
        event = {'BufRead'},
        setup = require'conf.lsp'.setup,
        config = require'conf.lsp'.config(),
        requires = {'nvim-lua/lsp-status.nvim', opt = true}
    }
    use {
        'L3MON4D3/LuaSnip',
        opt = true,
        event = {'InsertEnter'},
        config = function() require 'conf.snippets' end,
        requires = {'rafamadriz/friendly-snippets', opt = true}
    }
    use {
        'hrsh7th/nvim-compe',
        opt = true,
        event = {'InsertEnter'},
        config = require'conf.compe'.config,
        after = 'LuaSnip'
    }
    use {
        -- Debug Adapter Protocol client
        'mfussenegger/nvim-dap',
        opt = true,
        ft = {'python'},
        requires = {
            {'mfussenegger/nvim-dap-python', opt = true},
            {
                'theHamsta/nvim-dap-virtual-text',
                opt = true,
                after = 'nvim-treesitter'
            }
        },
        setup = require'conf.dap'.setup,
        config = require'conf.dap'.config
    }
    use {
        'kyazdani42/nvim-tree.lua',
        opt = true,
        cmd = {'NvimTreeOpen', 'NvimTreeToggle'},
        setup = require'conf.nvim_tree'.setup,
        config = require'conf.nvim_tree'.config,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {
        'nvim-telescope/telescope.nvim',
        event = {'VimEnter'},
        setup = require'conf.telescope'.setup,
        config = require'conf.telescope'.config,
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
    }
    use {
        'nvim-telescope/telescope-dap.nvim',
        after = {'telescope.nvim', 'nvim-dap'},
        config = function() require'telescope'.load_extension('dap') end
    }
    use {
        'nvim-telescope/telescope-github.nvim',
        after = {'telescope.nvim'},
        config = function() require'telescope'.load_extension('gh') end
    }
    use {
        'glepnir/galaxyline.nvim',
        opt = true,
        branch = 'main',
        event = {'VimEnter'},
        config = function() require 'conf.statusline' end,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {
        'romgrk/barbar.nvim',
        event = {'VimEnter'},
        config = require'conf.bufferline'.config(),
        requires = {'kyazdani42/nvim-web-devicons', opt = true},
        disable = true
    }
    use {
        'lewis6991/gitsigns.nvim',
        event = {'BufReadPre', 'BufNewFile'},
        config = require'conf.gitsigns'.config,
        requires = {'nvim-lua/plenary.nvim'}
    }
    use {
        'TimUntersberger/neogit',
        opt = true,
        cmd = 'Neogit',
        setup = require'conf.neogit'.setup,
        config = require'conf.neogit'.config
    }
    -- use {
    --     'windwp/nvim-autopairs',
    --     event = {'BufRead'},
    --     config = function() require'nvim-autopairs'.setup() end
    -- }
    use {
        'steelsojka/pears.nvim',
        event = {'BufRead'},
        config = require'conf.pears'.config
    }
    use {'kosayoda/nvim-lightbulb', opt = true}
    use {
        'numToStr/Navigator.nvim',
        cond = function() return os.getenv('TMUX') end,
        config = require'conf.navigator'.config
    }
    use {
        'kassio/neoterm',
        cmd = {'Ttoggle'},
        config = require'conf.neoterm'.config
    }
    use {'hkupty/iron.nvim', opt = true} -- REPL
    use {
        'mhinz/vim-sayonara',
        opt = true,
        cmd = 'Sayonara',
        setup = require'conf.sayonara'.setup
    }
    use {
        'phaazon/hop.nvim',
        opt = true,
        cmd = {'HopWord', 'HopChar1', 'HopPattern'},
        setup = require'conf.hop'.setup
    }
    use {
        'lukas-reineke/indent-blankline.nvim',
        opt = true,
        branch = 'lua',
        event = {'BufRead'},
        config = require'conf.indentline'.config
    }
    use {'pylance', opt = true}
    use {'simrat39/rust-tools.nvim', opt = true}
    use {'mfussenegger/nvim-jdtls', opt = true}
    use {'zsugabubus/crazy8.nvim', opt = true, event = {'BufRead'}} -- detect indentation automatically
    use {
        'folke/lsp-trouble.nvim',
        opt = true,
        cmd = 'LspTroubleToggle',
        setup = require'conf.lsp_trouble'.setup,
        config = require'conf.lsp_trouble'.config,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {
        'simrat39/symbols-outline.nvim',
        opt = true,
        cmd = 'SymbolsOutline',
        setup = require'conf.outline'.setup,
        config = require'conf.outline'.config
    }
    use {
        'kevinhwang91/nvim-bqf',
        opt = true,
        event = {'BufWinEnter quickfix'},
        config = require'conf.quickfix'.config
    }
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
vim.o.complete = add {"kspell"}
-- vim.wo.spell = true
vim.o.completeopt = add {"menuone", "noselect"} -- Completion options
vim.o.clipboard = 'unnamedplus'
vim.o.inccommand = 'nosplit'

if fn.filereadable('~/.local/share/virtualenvs/debugpy/bin/python') then
    vim.g.python3_host_prog = '~/.local/share/virtualenvs/debugpy/bin/python'
end

-----------------------------------------------------------------------------//
-- Indentation {{{1
-----------------------------------------------------------------------------//
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 4 -- Size of an indent
opt.smartindent = true -- Insert indents automatically
opt.tabstop = 4 -- Number of spaces tabs count for
opt.softtabstop = 4
vim.o.shiftround = true -- Round indent
vim.o.joinspaces = false -- No double spaces with join after a dot

-----------------------------------------------------------------------------//
-- Display {{{1
-----------------------------------------------------------------------------//
vim.wo.number = true -- Print line number
vim.wo.relativenumber = true -- Relative line numbers
vim.wo.numberwidth = 2
vim.wo.signcolumn = 'auto'
vim.wo.cursorline = true
vim.api.nvim_exec([[
    augroup cursorline_focus
        autocmd!
        autocmd WinEnter * setlocal cursorline
        autocmd WinLeave * setlocal nocursorline
    augroup END
    ]], false)
opt.wrap = true
opt.linebreak = true -- wrap, but on words, not randomly
-- opt.textwidth = 80
opt.synmaxcol = 1024 -- don't syntax highlight long lines
vim.g.vimsyn_embed = "lPr" -- allow embedded syntax highlighting for lua, python, ruby
vim.o.showmode = false
vim.o.lazyredraw = true
vim.o.emoji = false -- turn off as they are treated as double width characters
vim.o.virtualedit = 'all' -- allow cursor to move past end of line
vim.o.list = true -- invisible chars
vim.o.listchars = add {
    "eol: ", "tab:→ ", "extends:…", "precedes:…", "trail:·"
}
cmd('set list') -- workaround until vim.o mappings are fixed
vim.o.shortmess = vim.o.shortmess .. "I" -- disable :intro startup screen

-----------------------------------------------------------------------------//
-- Title {{{1
-----------------------------------------------------------------------------//
vim.o.titlestring = "❐ %t"
vim.o.titleold = '%{fnamemodify(getcwd(), ":t")}'
vim.o.title = true
vim.o.titlelen = 70

-----------------------------------------------------------------------------//
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
opt.undofile = true -- Save undo history
vim.o.confirm = true -- prompt to save before destructive actions

-----------------------------------------------------------------------------//
-- Search {{{1
-----------------------------------------------------------------------------//
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
vim.o.wildmode = "full"
vim.o.wildignorecase = true -- Ignore case when completing file names and directories
-- Binary
vim.o.wildignore = add {
    "*.aux,*.out,*.toc",
    "*.o,*.obj,*.dll,*.jar,*.pyc,__pycache__,*.rbc,*.class", -- media
    "*.ai,*.bmp,*.gif,*.ico,*.jpg,*.jpeg,*.png,*.psd,*.webp",
    "*.avi,*.m4a,*.mp3,*.oga,*.ogg,*.wav,*.webm", "*.eot,*.otf,*.ttf,*.woff",
    "*.doc,*.pdf", -- archives
    "*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz", -- temp/system
    "*.*~,*~ ", "*.swp,.lock,.DS_Store,._*,tags.lock", -- version control
    ".git,.svn"
}
vim.o.wildoptions = "pum"
vim.o.pumblend = 7 -- Make popup window translucent
vim.o.pumheight = 20 -- Limit the amount of autocomplete items shown

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
cmd("command TermRight :call luaeval('_G.__split_term_right()')")
-- Directly go into insert mode when switching to terminal
cmd [[autocmd BufWinEnter,WinEnter term://* startinsert]]
-- cmd [[autocmd BufLeave term://* stopinsert]]
-- Automatically close terminal buffer on process exit
-- cmd [[autocmd TermClose term://* call nvim_input('<CR>')]]
-- cmd [[autocmd TermClose * call feedkeys("i")]]

-----------------------------------------------------------------------------//
-- Mouse {{{1
-----------------------------------------------------------------------------//
vim.o.mouse = "a"

-----------------------------------------------------------------------------//
-- Netrw {{{1
-----------------------------------------------------------------------------//
-- do not display info on the top of window
vim.g.netrw_banner = 0

-----------------------------------------------------------------------------//
-- Colorscheme {{{1
-----------------------------------------------------------------------------//
vim.o.termguicolors = true

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
-- <space><space> switches between buffers
map('n', '<leader><leader>', ':b#<CR>')

-- Sane movement defaults that works on long wrapped lines
map('', 'j', "(v:count ? 'j' : 'gj')", {expr = true})
map('', 'k', "(v:count ? 'k' : 'gk')", {expr = true})

-- Disable arrow keys
map('', '<Up>', '<Nop>')
map('', '<Down>', '<Nop>')
map('', '<Left>', '<Nop>')
map('', '<Right>', '<Nop>')

-- Easier splits navigation
map('n', '<C-j>', '<C-w>j', {noremap = false})
map('n', '<C-k>', '<C-w>k', {noremap = false})
map('n', '<C-h>', '<C-w>h', {noremap = false})
map('n', '<C-l>', '<C-w>l', {noremap = false})

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
map('t', '<C-h>', '<C-\\><C-N><C-w>h', {noremap = false})
map('t', '<C-j>', '<C-\\><C-N><C-w>j', {noremap = false})
map('t', '<C-k>', '<C-\\><C-N><C-w>k', {noremap = false})
map('t', '<C-l>', '<C-\\><C-N><C-w>l', {noremap = false})
map('t', '<C-[><C-[>', '<C-\\><C-N>') -- double ESC to escape terminal

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

-- sensible defaults
map('', 'Y', 'y$')
map('', 'Q', '')

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
-- }}}1
-----------------------------------------------------------------------------//
