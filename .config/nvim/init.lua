local cmd = vim.cmd -- to execute Vim commands e.g. cmd('pwd')
local fn = vim.fn -- to call Vim functions e.g. fn.bufnr()

-- Install packer
local execute = vim.api.nvim_command

local install_path = fn.stdpath('data') .. '/site/pack/packer/opt/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    execute('!git clone https://github.com/wbthomason/packer.nvim ' ..
                install_path)
end

-- Only required if you have packer in your `opt` pack
vim.cmd [[packadd packer.nvim]]
vim.cmd [[autocmd BufWritePost init.lua PackerCompile]]

local use = require('packer').use
require('packer').startup(function()
    -- Packer can manage itself as an optional plugin
    use {'wbthomason/packer.nvim', opt = true}
    use 'tpope/vim-sensible'
    use 'tpope/vim-surround'
    use 'disrupted/vim-one' -- personal tweaked colorscheme
    use 'tpope/vim-commentary'
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
    }
    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        config = function() require 'status-line' end,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use 'nvim-treesitter/nvim-treesitter'
    use 'neovim/nvim-lspconfig'
    use 'nvim-lua/lsp-status.nvim'
    use 'nvim-lua/completion-nvim'
    use 'mfussenegger/nvim-dap'
    use 'windwp/nvim-autopairs'
    use 'dstein64/vim-startuptime'
    use {
        'romgrk/barbar.nvim',
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}}

end)

-- local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

-- local function opt(scope, key, value)
--     scopes[scope][key] = value
--     if scope ~= 'o' then scopes['o'][key] = value end
-- end

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

-- Enable break indent
-- vim.o.breakindent = true

-----------------------------------------------------------------------------//
-- Utils {{{1
-----------------------------------------------------------------------------//
vim.o.completeopt = add {"menu", "noinsert", "noselect", "longest"} -- Completion options
vim.o.clipboard = 'unnamedplus'
vim.o.inccommand = 'nosplit'
vim.o.backspace = 'indent,eol,start' -- Change backspace to behave more intuitively

if vim.fn.filereadable('/usr/local/bin/python3') then
    vim.g.python3_host_prog = '/usr/local/bin/python3'
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
opt.textwidth = 80
opt.synmaxcol = 1024 -- don't syntax highlight long lines
vim.g.vimsyn_embed = "lPr" -- allow embedded syntax highlighting for lua, python, ruby
vim.o.showcmd = true -- Set show command
vim.o.showmode = false
vim.o.lazyredraw = true
vim.o.emoji = false -- turn off as they are treated as double width characters
-- vim.o.virtualedit = 'all'
vim.o.virtualedit = "block" -- allow cursor to move where there is no text in visual block mode
vim.o.list = true -- invisible chars
vim.o.listchars = add {
    "eol: ", "tab:→ ", "extends:…", "precedes:…", "trail:·", "nbsp:·",
    "space:·"
}

-----------------------------------------------------------------------------//
-- Title {{{1
-----------------------------------------------------------------------------//
-- vim.o.titlestring = " ❐ %t %r %m"
-- vim.o.titleold = '%{fnamemodify(getcwd(), ":t")}'
-- vim.o.title = true
-- vim.o.titlelen = 70

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
vim.g.one_allow_italics = 1
cmd 'colorscheme one'

--- COLORS ---
local hl = function(group, options)
    local bg = options.bg == nil and '' or 'guibg=' .. options.bg
    local fg = options.fg == nil and '' or 'guifg=' .. options.fg
    local gui = options.gui == nil and '' or 'gui=' .. options.gui

    vim.cmd(string.format('hi %s %s %s %s', group, bg, fg, gui))
end

vim.cmd("highlight clear SignColumn")
vim.cmd [[call one#highlight('Normal', '', '24282c', 'none')]]
-- local one_highlight = vim.fn["one#highlight"]
-- one_highlight("Normal", "", "000000", "none")
-- one_highlight("VertSplit", "2c323c", "bg", "")

--- MAPPINGS ---
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend('force', options, opts) end
    vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

vim.g.mapleader = ","

map('i', '<C-h>', '<C-w>h', {noremap = false})
map('i', '<C-j>', '<C-w>j', {noremap = false})
map('i', '<C-k>', '<C-w>k', {noremap = false})
map('i', '<C-l>', '<C-w>l', {noremap = false})
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

map('v', '<', '<gv')
map('v', '>', '>gv')

-- Move selected line / block of text in visual mode
-- shift + k to move up
-- shift + j to move down
map('x', 'K', ":move '<-2<CR>gv-gv")
map('x', 'J', ":move '>+1<CR>gv-gv")

-- Use <Tab> and <S-Tab> to navigate through popup menu
vim.api.nvim_buf_set_keymap(0, 'i', '<tab>', "<Plug>(completion_smart_tab)",
                            {noremap = false, silent = true})
vim.api.nvim_buf_set_keymap(0, 'i', '<s-tab>', "<Plug>(completion_smart_s_tab)",
                            {noremap = false, silent = true})
-- vim.api.nvim_set_keymap('i', '<Tab>', 'pumvisible() ? "\\<C-n>" : "\\<Tab>"',
--                         {expr = true})
-- vim.api.nvim_set_keymap('i', '<S-Tab>', 'pumvisible() ? "\\<C-p>" : "\\<Tab>"',
--                         {expr = true})

map('n', '<leader>b', "<cmd>lua require('telescope.builtin').buffers()<CR>")
map('n', '<C-f>', "<cmd>lua require('telescope.builtin').find_files()<CR>")
map('n', '<leader>g', "<cmd>lua require('telescope.builtin').live_grep()<CR>")
map('n', '<leader>h', "<cmd>lua require('telescope.builtin').help_tags()<CR>")

--- PLUGINS ---
-- autopairs
require('nvim-autopairs').setup()

-- TreeSitter
require'nvim-treesitter.configs'.setup {
    ensure_installed = "maintained", -- one of "all", "maintained" (parsers with maintainers), or a list of languages
    highlight = {enable = true},
    indent = {enable = true}
}

-- LSP
local lspconfig = require 'lspconfig'
local lsp_status = require 'lsp-status'
lsp_status.register_progress()
-- client log level
vim.lsp.set_log_level('info')

-- vim.g.completion_enable_auto_popup = true
-- vim.g.completion_enable_snippet = "UltiSnips"
vim.g.completion_matching_strategy_list = {"exact", "substring"} -- {"exact", "substring", "fuzzy", "all"}
vim.g.completion_sorting = "none"
-- vim.g.completion_auto_change_source = 1
vim.g.completion_matching_smart_case = 1
vim.g.completion_chain_complete_list = {
    default = {
        {complete_items = {"lsp"}}, {complete_items = {"snippet"}},
        {complete_items = {"path"}}, {mode = "<c-n>"}, {mode = "dict"}
    }
}
vim.g.completion_enable_auto_paren = 1
vim.g.completion_customize_lsp_label = {
    Function = " [function]",
    Method = " [method]",
    Reference = " [refrence]",
    Enum = " [enum]",
    Field = "ﰠ [field]",
    Keyword = " [key]",
    Variable = " [variable]",
    Folder = " [folder]",
    Snippet = " [snippet]",
    Operator = " [operator]",
    Module = " [module]",
    Text = "ﮜ[text]",
    Class = " [class]",
    Interface = " [interface]"
}

local on_attach = function(client, bufnr)
    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local function buf_set_option(...)
        vim.api.nvim_buf_set_option(bufnr, ...)
    end

    buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- Mappings.
    local opts = {noremap = true, silent = true}
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>',
                   opts)
    buf_set_keymap('n', '<space>wa',
                   '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr',
                   '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl',
                   '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>',
                   opts)
    buf_set_keymap('n', '<space>D',
                   '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e',
                   '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>',
                   opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>',
                   opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>',
                   opts)
    buf_set_keymap('n', '<space>q',
                   '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    vim.o.shortmess = vim.o.shortmess .. "c"

    -- Set some keybinds conditional on server capabilities
    if client.resolved_capabilities.document_formatting then
        buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>",
                       opts)
    elseif client.resolved_capabilities.document_range_formatting then
        buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>",
                       opts)
    end

    -- Format on save
    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_command [[augroup Format]]
        vim.api.nvim_command [[autocmd! * <buffer>]]
        vim.api
            .nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync(nil, 1000)]]
        vim.api.nvim_command [[augroup END]]
    end

    -- Set autocommands conditional on server_capabilities
    if client.resolved_capabilities.document_highlight then
        require('lspconfig').util.nvim_multiline_command [[
      :hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
      :hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
      :hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
      augroup lsp_document_highlight
        autocmd!
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]]
    end

    print("LSP Attached.")
end

-- Handle formatting in a smarter way
-- If the buffer has been edited before formatting has completed, do not try to 
-- apply the changes
-- vim.lsp.handlers['textDocument/formatting'] =
--     function(err, _, result, _, bufnr)
--         if err ~= nil or result == nil then return end

--         -- If the buffer hasn't been modified before the formatting has finished, 
--         -- update the buffer
--         if not vim.api.nvim_buf_get_option(bufnr, 'modified') then
--             local view = vim.fn.winsaveview()
--             vim.lsp.util.apply_text_edits(result, bufnr)
--             vim.fn.winrestview(view)
--             if bufnr == vim.api.nvim_get_current_buf() then
--                 vim.api.nvim_command('noautocmd :update')

--                 -- Trigger post-formatting autocommand which can be used to refresh 
--                 -- gitgutter
--                 vim.api.nvim_command(
--                     'silent doautocmd <nomodeline> User FormatterPost')
--             end
--         end
--     end

-- define language servers
lspconfig.pyls.setup {
    on_attach = require'completion'.on_attach,
    cmd = {"pyls", "--log-file", "/tmp/pyls.log", "--verbose"},
    settings = {
        pyls = {
            configurationSources = {"pycodestyle", "flake8"},
            plugins = {pyls_mypy = {enabled = true}}
        }
    }
}
-- lspconfig.vimls.setup {}
-- lspconfig.jdtls.setup{}
-- lspconfig.jsonls.setup {}
-- lspconfig.dockerls.setup {}
lspconfig.yamlls.setup {
    settings = {
        yaml = {
            customTags = {
                "!secret", "!include_dir_named", "!include_dir_list",
                "!include_dir_merge_named", "!include_dir_merge_list",
                "!lambda", "!input"
            }
        }
    }
}

-- EFM Universal Language Server
local efm_config = os.getenv('HOME') .. '/.config/efm-langserver/config.yaml'
local log_dir = "/tmp/"
local black = require "efm/black"
local isort = require "efm/isort"
local lua_format = require "efm/lua-format"
local prettier = require "efm/prettier"

lspconfig.efm.setup {
    cmd = {"efm-langserver", "-c", efm_config, "-logfile", log_dir .. "efm.log"},
    on_attach = on_attach,
    -- Fallback to .bashrc as a project root to enable LSP on loose files
    root_dir = lspconfig.util.root_pattern("package.json", ".git/", ".zshrc"),
    init_options = {documentFormatting = true},
    settings = {
        rootMarkers = {"package.json", ".git/", ".zshrc"},
        languages = {
            python = {isort, black},
            lua = {lua_format},
            yaml = {prettier},
            json = {prettier},
            markdown = {prettier},
            javascript = {prettier},
            typescript = {prettier},
            typescriptreact = {prettier}
        }
    }
}

vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        signs = true,
        virtual_text = {spacing = 4, prefix = ''},
        -- delay update
        update_in_insert = true
    })

vim.fn.sign_define("LspDiagnosticsSignError",
                   {text = "◉", texthl = "LspDiagnosticsError"})
vim.fn.sign_define("LspDiagnosticsSignWarning",
                   {text = "•", texthl = "LspDiagnosticsWarning"})
vim.fn.sign_define("LspDiagnosticsSignInformation",
                   {text = "•", texthl = "LspDiagnosticsInformation"})
vim.fn.sign_define("LspDiagnosticsSignHint",
                   {text = "H", texthl = "LspDiagnosticsHint"})

-- DAP
-- TODO: nvim-dap-python

-- barbar
vim.g.bufferline = {
    -- Enable/disable animations
    animation = false,

    auto_hide = true,

    -- Enable/disable icons
    -- if set to 'numbers', will show buffer index in the tabline
    -- if set to 'both', will show buffer index and icons in the tabline
    icons = true,
    icon_separator_active = '',
    icon_separator_inactive = '',
    icon_close_tab = '',
    icon_close_tab_modified = ' ',

    -- Enable/disable close button
    closable = false,

    -- Enables/disable clickable tabs
    --  - left-click: go to buffer
    --  - middle-click: delete buffer
    clickable = true,

    -- If set, the letters for each buffer in buffer-pick mode will be
    -- assigned based on their name. Otherwise or in case all letters are
    -- already assigned, the behavior is to assign letters in order of
    -- usability (see order below)
    semantic_letters = true,

    -- Sets the maximum padding width with which to surround each tab
    maximum_padding = 2
}

-- gitsigns
require('gitsigns').setup {
    signs = {
        add = {hl = 'DiffAdd', text = '+', numhl = 'GitSignsAddNr'},
        change = {hl = 'DiffChange', text = '~', numhl = 'GitSignsChangeNr'},
        delete = {
            hl = 'DiffDelete',
            text = '_',
            show_count = true,
            numhl = 'GitSignsDeleteNr'
        },
        topdelete = {
            hl = 'DiffDelete',
            text = '‾',
            show_count = true,
            numhl = 'GitSignsDeleteNr'
        },
        changedelete = {
            hl = 'DiffChange',
            text = '~',
            show_count = true,
            numhl = 'GitSignsChangeNr'
        }
    },
    count_chars = {
        [1] = '',
        [2] = '₂',
        [3] = '₃',
        [4] = '₄',
        [5] = '₅',
        [6] = '₆',
        [7] = '₇',
        [8] = '₈',
        [9] = '₉',
        ['+'] = '₊'
    },
    numhl = false,
    keymaps = {
        -- Default keymap options
        noremap = true,
        buffer = true,

        ['n ]c'] = {
            expr = true,
            "&diff ? ']c' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'"
        },
        ['n [c'] = {
            expr = true,
            "&diff ? '[c' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'"
        },

        ['n <leader>hs'] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
        ['n <leader>hu'] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
        ['n <leader>hr'] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
        ['n <leader>hp'] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
        ['n <leader>hb'] = '<cmd>lua require"gitsigns".blame_line()<CR>'
    },
    watch_index = {interval = 1000},
    sign_priority = 6,
    status_formatter = nil -- Use default
}
