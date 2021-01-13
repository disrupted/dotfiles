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
    use 'rakr/vim-one'
    use 'joshdick/onedark.vim'
    -- use 'joshdick/onedark.vim'
    use 'tpope/vim-commentary'
    use {
        'nvim-telescope/telescope.nvim',
        requires = {{'nvim-lua/popup.nvim'}, {'nvim-lua/plenary.nvim'}}
    }
    use {
        'glepnir/galaxyline.nvim',
        branch = 'main',
        -- your statusline
        -- config = function() require'my_statusline' end,
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    -- use {
    --     'hoob3rt/lualine.nvim',
    --     requires = {'kyazdani42/nvim-web-devicons', opt = true}
    -- }
    use 'nvim-treesitter/nvim-treesitter'
    use 'neovim/nvim-lspconfig'
    use 'nvim-lua/lsp-status.nvim'
    use 'nvim-lua/completion-nvim'
    use 'windwp/nvim-autopairs'
    use 'dstein64/vim-startuptime'
    -- use 'akinsho/nvim-bufferline.lua'
    use {
        'romgrk/barbar.nvim',
        requires = {'kyazdani42/nvim-web-devicons', opt = true}
    }
    -- use 'mhinz/vim-signify'
    use {'lewis6991/gitsigns.nvim', requires = {'nvim-lua/plenary.nvim'}}
    -- use 'mhartington/formatter.nvim'

end)

local scopes = {o = vim.o, b = vim.bo, w = vim.wo}

local function opt(scope, key, value)
    scopes[scope][key] = value
    if scope ~= 'o' then scopes['o'][key] = value end
end

local indent = 2
opt('o', 'autoindent', true) -- Allow filetype plugins and syntax highlighting
opt('b', 'expandtab', true) -- Use spaces instead of tabs
opt('b', 'shiftwidth', indent) -- Size of an indent
opt('b', 'smartindent', true) -- Insert indents automatically
opt('b', 'tabstop', indent) -- Number of spaces tabs count for
opt('b', 'softtabstop', indent)
opt('o', 'completeopt', 'menuone,noinsert,noselect') -- Completion options (for deoplete)
opt('o', 'hidden', true) -- Enable modified buffers in background
opt('o', 'ignorecase', true) -- Ignore case
opt('o', 'joinspaces', false) -- No double spaces with join after a dot
opt('o', 'scrolloff', 4) -- Lines of context
opt('o', 'shiftround', true) -- Round indent
opt('o', 'sidescrolloff', 8) -- Columns of context
opt('o', 'smartcase', true) -- Don't ignore case with capitals
opt('o', 'splitbelow', true) -- Put new windows below current
opt('o', 'splitright', true) -- Put new windows right of current
opt('o', 'wildmode', 'list:longest') -- Command-line completion mode
opt('w', 'list', true) -- Show some invisible characters (tabs...)
opt('w', 'number', true) -- Print line number
opt('w', 'relativenumber', true) -- Relative line numbers
opt('w', 'wrap', false)
opt('o', 'updatetime', 250)
opt('w', 'signcolumn', 'yes')
opt('o', 'clipboard', 'unnamed')
opt('o', 'inccommand', 'nosplit')
opt('o', 'backspace', 'indent,eol,start') -- Change backspace to behave more intuitively
opt('w', 'cursorline', true)
opt('o', 'showmatch', true)
opt('o', 'autoread', true)
opt('o', 'virtualedit', 'all')
opt('o', 'lazyredraw', true)

-- Set highlight on search
vim.o.hlsearch = false
vim.o.incsearch = true

-- Do not save when switching buffers
vim.o.hidden = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Enable break indent
vim.o.breakindent = true

-- Set show command
vim.o.showcmd = true

-- Save undo history
vim.o.undofile = true

-- NETRW
-- Nerdtree like sidepanel
-- absolute width of netrw window
-- vim.g.netrw_winsize = -28
-- do not display info on the top of window
vim.g.netrw_banner = 0

-- Set colorscheme (order is important here)
vim.o.termguicolors = true
vim.g.one_allow_italics = 1
cmd 'colorscheme one'
vim.o.fillchars = vim.o.fillchars .. 'vert:│'

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
local nvim_lsp = require('lspconfig')
local lsp_status = require('lsp-status')
lsp_status.register_progress()

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
            .nvim_command [[autocmd BufWritePost <buffer> lua vim.lsp.buf.formatting()]]
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
nvim_lsp.pyls.setup {
    cmd = {"pyls", "--log-file", "/tmp/pyls-log.txt", "--verbose"},
    settings = {
        pyls = {
            configurationSources = {"pycodestyle", "flake8"},
            plugins = {pyls_mypy = {enabled = true}}
        }
    }
}
-- nvim_lsp.vimls.setup {}
-- nvim_lsp.jdtls.setup{}
-- nvim_lsp.jsonls.setup {}
-- nvim_lsp.dockerls.setup {}
-- nvim_lsp.diagnosticls.setup{}
nvim_lsp.yamlls.setup {
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

local black = {formatCommand = "black -", formatStdin = true}
local isort = {
    formatCommand = "isort --stdout --profile black -",
    formatStdin = true
}
local luafmt = {formatCommand = "lua-format -i", formatStdin = true}

nvim_lsp.efm.setup {
    on_attach = on_attach,
    init_options = {documentFormatting = true},
    settings = {
        rootMarkers = {".git/"},
        languages = {python = {black, isort}, lua = {luafmt}}
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

-- Bufferline
-- require'bufferline'.setup{
--   options = {
--     view = "multiwindow",
--     tab_size = 18,
--     enforce_regular_tabs = false,
--     separator_style = "thin",
--     show_buffer_close_icons = false,
--     close_icon = '',
--     always_show_bufferline = false,
--   },
--   highlights = {
--     buffer_selected = {
--           guifg = normal_fg,
--           guibg = normal_bg,
--           gui = "bold"
--     }
--   }
-- }

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

-- GalaxyLine
require('status-line')

-- lualine
-- local lualine = require('lualine')
-- lualine.theme = 'onedark'
-- lualine.status()

-- Signify
vim.g.signify_sign_show_count = 0 -- Don’t show the number of deleted lines.

-- gitsigns
require('gitsigns').setup {
    signs = {
        add = {hl = 'DiffAdd', text = '│', numhl = 'GitSignsAddNr'},
        change = {hl = 'DiffChange', text = '│', numhl = 'GitSignsChangeNr'},
        delete = {hl = 'DiffDelete', text = '_', numhl = 'GitSignsDeleteNr'},
        topdelete = {
            hl = 'DiffDelete',
            text = '‾',
            numhl = 'GitSignsDeleteNr'
        },
        changedelete = {
            hl = 'DiffChange',
            text = '~',
            numhl = 'GitSignsChangeNr'
        }
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
